#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "pathname"

source_root = Pathname(ARGV[0] || "_registry-source").expand_path
site_root = Pathname(ARGV[1] || "_site").expand_path
public_site_url = "https://iri.science"

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

all_manifest_pages = manifest.fetch("pages") + manifest.fetch("indexes")
all_manifest_pages.each do |page|
  permalink = page.fetch("permalink")
  identifier = "#{public_site_url}#{permalink.delete_suffix('/')}"
  markdown_url = "#{identifier}.md"
  abort_validation("incorrect identifier for #{permalink}") unless page.fetch("identifier") == identifier
  abort_validation("incorrect HTML URL for #{permalink}") unless page.fetch("html") == identifier
  abort_validation("incorrect Markdown URL for #{permalink}") unless page.fetch("markdown") == markdown_url
  abort_validation("incorrect source commit for #{permalink}") unless page.fetch("source_commit") == source_commit

  output = site_root.join(permalink.delete_prefix("/"), "index.html")
  abort_validation("missing rendered page for #{permalink}") unless output.file?
  html = output.read
  canonical = %(<link rel="canonical" href="#{identifier}">)
  alternate = %(<link rel="alternate" type="text/markdown" href="#{markdown_url}">)
  abort_validation("missing canonical link for #{permalink}") unless html.include?(canonical)
  abort_validation("missing Markdown alternate link for #{permalink}") unless html.include?(alternate)

  markdown_output = site_root.join("#{permalink.delete_prefix('/').delete_suffix('/')}.md")
  abort_validation("missing Markdown alternate for #{permalink}") unless markdown_output.file?
  markdown = markdown_output.read
  abort_validation("Markdown alternate was rendered as HTML for #{permalink}") if markdown.include?("<!DOCTYPE html>")
  abort_validation("Markdown alternate has no top-level heading for #{permalink}") unless markdown.match?(/^#\s+\S/)
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
