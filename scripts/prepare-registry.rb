#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "pathname"
require "uri"

class RegistryPreparer
  REPOSITORY_URL = "https://github.com/doe-iri/iri-facility-api-docs"
  GENERATED_MARKER = ".iri-registry-generated"
  IMPORT_ROOTS = {
    "registry/profiles" => "/profiles/",
    "registry/relations" => "/rels/"
  }.freeze

  Page = Struct.new(:source, :permalink, :title, :content, :kind, keyword_init: true)

  def initialize(source_root, output_root)
    @source_root = Pathname(source_root).expand_path
    @output_root = Pathname(output_root).expand_path
    @unresolved = []
  end

  def run
    validate_roots!
    @commit = registry_commit
    @dirty = registry_dirty?
    if @dirty && ENV["ALLOW_DIRTY_REGISTRY"] != "1"
      abort "Registry checkout has uncommitted changes; commit them or set ALLOW_DIRTY_REGISTRY=1 for a local preview"
    end
    warn "Warning: importing uncommitted registry changes for a local preview" if @dirty
    source_files = imported_source_files
    permalink_by_source = source_files.to_h { |path| [relative(path), permalink_for(relative(path))] }

    pages = source_files.map do |path|
      source = relative(path)
      content = rewrite_document(path, permalink_by_source)
      Page.new(
        source: source,
        permalink: permalink_by_source.fetch(source),
        title: document_title(content, source),
        content: content,
        kind: source.start_with?("registry/profiles/") ? "profile" : "relation"
      )
    end

    abort_unresolved!
    intermediate_pages = build_intermediate_pages(pages)
    prepare_output!
    (pages + intermediate_pages).each { |page| write_page(page) }
    write_metadata(pages, intermediate_pages)

    puts "Prepared #{pages.count { |page| page.kind == 'profile' }} profiles, " \
         "#{pages.count { |page| page.kind == 'relation' }} relations, and " \
         "#{intermediate_pages.length} intermediate indexes from #{@commit}."
  end

  private

  def validate_roots!
    unless @source_root.join("registry/profiles/README.md").file? &&
           @source_root.join("registry/relations/README.md").file?
      abort "Registry checkout must contain registry/profiles and registry/relations"
    end

    if @output_root == Pathname("/") || @output_root == @source_root ||
       @source_root.to_s.start_with?("#{@output_root}/")
      abort "Unsafe generated output path: #{@output_root}"
    end
  end

  def registry_commit
    stdout, stderr, status = Open3.capture3("git", "-C", @source_root.to_s, "rev-parse", "HEAD")
    abort "Cannot determine registry commit: #{stderr.strip}" unless status.success?

    commit = stdout.strip
    abort "Invalid registry commit: #{commit}" unless commit.match?(/\A[0-9a-f]{40}\z/)

    commit
  end

  def registry_dirty?
    stdout, stderr, status = Open3.capture3(
      "git", "-C", @source_root.to_s, "status", "--porcelain", "--untracked-files=normal"
    )
    abort "Cannot inspect registry checkout: #{stderr.strip}" unless status.success?

    !stdout.empty?
  end

  def imported_source_files
    IMPORT_ROOTS.keys.flat_map do |root|
      Dir.glob(@source_root.join(root, "**/*.md")).map { |path| Pathname(path) }
    end.reject { |path| path.basename.to_s == "AGENTS.md" }.sort
  end

  def relative(path)
    path.relative_path_from(@source_root).to_s
  end

  def permalink_for(source)
    if source == "registry/profiles/README.md"
      "/profiles/"
    elsif source.start_with?("registry/profiles/")
      "/profiles/#{source.delete_prefix('registry/profiles/').delete_suffix('.md')}/"
    elsif source == "registry/relations/README.md"
      "/rels/"
    elsif source.start_with?("registry/relations/")
      "/rels/#{source.delete_prefix('registry/relations/').delete_suffix('.md')}/"
    else
      raise "Not an imported registry source: #{source}"
    end
  end

  def rewrite_document(source_path, permalink_by_source)
    in_fence = false
    output = []
    prose = []
    prose_start = 1

    source_path.readlines.each.with_index(1) do |line, line_number|
      if line.match?(/^\s*(```|~~~)/)
        output << rewrite_prose(prose.join, source_path, prose_start, permalink_by_source) unless prose.empty?
        prose.clear
        in_fence = !in_fence
        output << line
      elsif in_fence
        output << line
      else
        prose_start = line_number if prose.empty?
        prose << line
      end
    end
    output << rewrite_prose(prose.join, source_path, prose_start, permalink_by_source) unless prose.empty?
    output.join
  end

  def rewrite_prose(text, source_path, starting_line, permalink_by_source)
    rewritten = text.gsub(/(!?\[[^\]]*\]\()([^)\s]+)([^)]*\))/) do
      match = Regexp.last_match
      line_number = starting_line + text[0...match.begin(2)].count("\n")
      "#{match[1]}#{rewrite_target(match[2], source_path, line_number, permalink_by_source)}#{match[3]}"
    end

    rewritten.gsub(/^(\s*\[[^\]]+\]:\s*)(\S+)/) do
      match = Regexp.last_match
      line_number = starting_line + rewritten[0...match.begin(2)].count("\n")
      "#{match[1]}#{rewrite_target(match[2], source_path, line_number, permalink_by_source)}"
    end
  end

  def rewrite_target(target, source_path, line_number, permalink_by_source)
    return target if target.empty? || target.start_with?("#", "/")
    return target if target.match?(/\A[a-z][a-z0-9+.-]*:/i)

    path_with_query, fragment = target.split("#", 2)
    path, query = path_with_query.split("?", 2)
    resolved = source_path.dirname.join(URI::DEFAULT_PARSER.unescape(path)).cleanpath
    suffix = "#{query ? "?#{query}" : ''}#{fragment ? "##{fragment}" : ''}"

    unless inside_source_root?(resolved) && resolved.exist?
      @unresolved << "#{relative(source_path)}:#{line_number}: #{target}"
      return target
    end

    resolved_source = relative(resolved)
    published = permalink_by_source[resolved_source]
    return "#{published}#{suffix}" if published

    imported_directory = published_directory(resolved_source)
    return "#{imported_directory}#{suffix}" if imported_directory

    escaped = resolved_source.split("/").map { |part| URI::DEFAULT_PARSER.escape(part) }.join("/")
    github_kind = resolved.directory? ? "tree" : "blob"
    "#{REPOSITORY_URL}/#{github_kind}/#{@commit}/#{escaped}#{suffix}"
  end

  def inside_source_root?(path)
    path == @source_root || path.to_s.start_with?("#{@source_root}/")
  end

  def published_directory(source)
    IMPORT_ROOTS.each do |root, published_root|
      return published_root if source == root
      return "#{published_root}#{source.delete_prefix("#{root}/").delete_suffix('/')}/" if source.start_with?("#{root}/")
    end
    nil
  end

  def abort_unresolved!
    return if @unresolved.empty?

    warn "Unresolved registry source links:"
    @unresolved.uniq.sort.each { |entry| warn "  #{entry}" }
    abort "Registry preparation stopped because source links are unresolved"
  end

  def document_title(content, source)
    heading = content.each_line.find { |line| line.match?(/^#\s+\S/) }
    return heading.sub(/^#\s+/, "").strip.gsub("`", "") if heading

    File.basename(source, ".md").split("-").map(&:capitalize).join(" ")
  end

  def build_intermediate_pages(pages)
    actual_by_permalink = pages.to_h { |page| [page.permalink, page] }
    directories = pages.each_with_object([]) do |page, result|
      next unless page.permalink.start_with?("/profiles/")

      segments = page.permalink.split("/").reject(&:empty?)
      result.concat((2...segments.length).map { |length| "/#{segments.first(length).join('/')}/" })
    end.uniq.sort

    directories.reject { |permalink| actual_by_permalink.key?(permalink) }.map do |permalink|
      Page.new(
        source: nil,
        permalink: permalink,
        title: intermediate_title(permalink),
        content: intermediate_content(permalink, pages, directories, actual_by_permalink),
        kind: "index"
      )
    end
  end

  def intermediate_title(permalink)
    segments = permalink.split("/").reject(&:empty?).drop(1)
    return "Resource Definition Profiles" if segments == ["resource-definition"]

    label = segments.last.split("-").map(&:capitalize).join(" ")
    segments.include?("resource-definition") ? "#{label} Resource Definition Profiles" : "#{label} Profiles"
  end

  def intermediate_content(permalink, pages, directories, actual_by_permalink)
    children = []
    pages.each do |page|
      remainder = page.permalink.delete_prefix(permalink)
      children << [page.permalink, page.title] if remainder != page.permalink && remainder.count("/") == 1
    end
    directories.each do |directory|
      remainder = directory.delete_prefix(permalink)
      if remainder != directory && remainder.count("/") == 1 && !actual_by_permalink.key?(directory)
        children << [directory, intermediate_title(directory)]
      end
    end

    lines = ["# #{intermediate_title(permalink)}", "", "Published profiles in this section:", ""]
    children.uniq.sort_by(&:first).each { |url, title| lines << "- [#{title}](#{url})" }
    "#{lines.join("\n")}\n"
  end

  def prepare_output!
    if @output_root.exist?
      marker = @output_root.join(GENERATED_MARKER)
      abort "Refusing to replace unmarked output directory: #{@output_root}" unless marker.file?

      FileUtils.rm_rf(@output_root)
    end
    FileUtils.mkdir_p(@output_root)
    @output_root.join(GENERATED_MARKER).write("generated by scripts/prepare-registry.rb\n")
  end

  def write_page(page)
    relative_output = page.permalink.delete_prefix("/").delete_suffix("/")
    relative_output = page.kind == "index" ? "indexes/#{relative_output}" : "imported/#{relative_output}"
    path = @output_root.join("#{relative_output}.md")
    FileUtils.mkdir_p(path.dirname)

    front_matter = {
      "layout" => "registry",
      "title" => page.title,
      "permalink" => page.permalink,
      "registry_source" => page.source,
      "registry_commit" => @commit,
      "registry_dirty" => @dirty
    }.compact
    yaml = front_matter.map { |key, value| "#{key}: #{value.to_json}" }.join("\n")
    path.write("---\n#{yaml}\n---\n\n#{page.content}")
  end

  def write_metadata(pages, intermediate_pages)
    manifest = {
      "registry_commit" => @commit,
      "registry_dirty" => @dirty,
      "repository" => REPOSITORY_URL,
      "pages" => pages.map do |page|
        { "source" => page.source, "permalink" => page.permalink, "title" => page.title, "kind" => page.kind }
      end,
      "indexes" => intermediate_pages.map { |page| { "permalink" => page.permalink, "title" => page.title } }
    }
    write_json_page("registry-manifest.json", "/registry-manifest.json", manifest)
    write_json_page(
      "registry-import.json",
      "/registry-import.json",
      { "repository" => REPOSITORY_URL, "commit" => @commit, "dirty" => @dirty }
    )
  end

  def write_json_page(filename, permalink, value)
    content = "---\nlayout: null\npermalink: #{permalink.to_json}\n---\n#{JSON.pretty_generate(value)}\n"
    @output_root.join(filename).write(content)
  end
end

if ARGV.empty? || ARGV.length > 2
  warn "Usage: ruby scripts/prepare-registry.rb REGISTRY_CHECKOUT [OUTPUT_DIRECTORY]"
  exit 64
end

RegistryPreparer.new(ARGV[0], ARGV[1] || "generated-registry").run
