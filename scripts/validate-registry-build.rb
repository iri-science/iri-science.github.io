#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "pathname"

source_root = Pathname(ARGV[0] || "_registry-source").expand_path
site_root = Pathname(ARGV[1] || "_site").expand_path

def abort_validation(message)
  warn "Registry build validation failed: #{message}"
  exit 1
end

manifest_path = site_root.join("registry-manifest.json")
import_path = site_root.join("registry-import.json")
abort_validation("registry-manifest.json is missing") unless manifest_path.file?
abort_validation("registry-import.json is missing") unless import_path.file?

manifest = JSON.parse(manifest_path.read)
import = JSON.parse(import_path.read)
stdout, stderr, status = Open3.capture3("git", "-C", source_root.to_s, "rev-parse", "HEAD")
abort_validation("cannot determine source commit: #{stderr.strip}") unless status.success?
source_commit = stdout.strip
abort_validation("manifest commit does not match source checkout") unless manifest["registry_commit"] == source_commit
abort_validation("import record does not match source checkout") unless import["commit"] == source_commit
if import["dirty"] && ENV["ALLOW_DIRTY_REGISTRY"] != "1"
  abort_validation("build imported uncommitted registry changes")
end

expected_sources = %w[registry/profiles registry/relations].flat_map do |root|
  Dir.glob(source_root.join(root, "**/*.md")).map { |path| Pathname(path) }
end.reject { |path| path.basename.to_s == "AGENTS.md" }.map do |path|
  path.relative_path_from(source_root).to_s
end.sort

manifest_sources = manifest.fetch("pages").map { |page| page.fetch("source") }.sort
abort_validation("manifest does not contain every registry source page") unless manifest_sources == expected_sources

manifest.fetch("pages").each do |page|
  permalink = page.fetch("permalink")
  output = site_root.join(permalink.delete_prefix("/"), "index.html")
  abort_validation("missing rendered page for #{permalink}") unless output.file?
end

manifest.fetch("indexes").each do |page|
  permalink = page.fetch("permalink")
  output = site_root.join(permalink.delete_prefix("/"), "index.html")
  abort_validation("missing rendered intermediate index for #{permalink}") unless output.file?
end

abort_validation("the retired /relations/ publication path was generated") if site_root.join("relations").exist?

Dir.glob(site_root.join("**/*.html")).each do |html_path|
  html = File.read(html_path)
  next unless html.match?(/href=["']\/relations(?:\/|["'])/)

  abort_validation("rendered navigation references the retired /relations/ path in #{html_path}")
end

{
  "/profiles/" => manifest.fetch("pages").select { |page| page.fetch("kind") == "profile" },
  "/rels/" => manifest.fetch("pages").select { |page| page.fetch("kind") == "relation" }
}.each do |index_permalink, pages|
  html = site_root.join(index_permalink.delete_prefix("/"), "index.html").read
  pages.each do |page|
    next if page.fetch("permalink") == index_permalink

    escaped = Regexp.escape(page.fetch("permalink"))
    abort_validation("#{index_permalink} does not link to #{page.fetch('permalink')}") unless html.match?(/href=["']#{escaped}["']/)
  end
end

puts "Validated #{manifest_sources.length} imported registry pages and #{manifest.fetch('indexes').length} intermediate indexes."
