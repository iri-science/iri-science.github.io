#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "pathname"
require "yaml"

SOURCE_PATH = "specification-v2/openapi/all_spec_v2.yaml"
PUBLIC_ROOT = "https://iri.science/api/v2"
REPOSITORY_URL = "https://github.com/doe-iri/iri-facility-api-docs"
REQUIRED_KEYS = %w[info paths components].freeze

def abort_validation(message)
  warn "OpenAPI build validation failed: #{message}"
  exit 1
end

def parse_yaml(text, label)
  YAML.safe_load(text, aliases: true)
rescue Psych::Exception => e
  abort_validation("cannot parse #{label}: #{e.message}")
end

def parse_json(text, label)
  JSON.parse(text)
rescue JSON::ParserError => e
  abort_validation("cannot parse #{label}: #{e.message}")
end

source_root = Pathname(ARGV[0] || "_registry-source").expand_path
site_root = Pathname(ARGV[1] || "_site").expand_path
source_path = source_root.join(SOURCE_PATH)
yaml_path = site_root.join("api/v2/openapi.yaml")
json_path = site_root.join("api/v2/openapi.json")
metadata_path = site_root.join("api/v2/openapi-metadata.json")

abort_validation("source file is missing") unless source_path.file?
abort_validation("published YAML is missing") unless yaml_path.file?
abort_validation("published JSON is missing") unless json_path.file?
abort_validation("publication metadata is missing") unless metadata_path.file?

source_bytes = source_path.binread
yaml_bytes = yaml_path.binread
json_text = json_path.read
abort_validation("published YAML differs from the authoritative source") unless yaml_bytes == source_bytes

source_document = parse_yaml(source_bytes, "authoritative YAML")
published_yaml = parse_yaml(yaml_bytes, "published YAML")
published_json = parse_json(json_text, "published JSON")
metadata = parse_json(metadata_path.read, "publication metadata")

abort_validation("published YAML is not equivalent to the source") unless published_yaml == source_document
abort_validation("published JSON is not equivalent to the source") unless published_json == source_document

version = source_document["openapi"]
unless version.is_a?(String) && version.match?(/\A3\.1(?:\.|\z)/)
  abort_validation("document is not OpenAPI 3.1")
end
REQUIRED_KEYS.each do |key|
  abort_validation("#{key} is not a top-level mapping") unless source_document[key].is_a?(Hash)
end

stdout, stderr, status = Open3.capture3("git", "-C", source_root.to_s, "rev-parse", "HEAD")
abort_validation("cannot determine source commit: #{stderr.strip}") unless status.success?
source_commit = stdout.strip
stdout, stderr, status = Open3.capture3(
  "git", "-C", source_root.to_s, "status", "--porcelain", "--untracked-files=normal"
)
abort_validation("cannot inspect source checkout: #{stderr.strip}") unless status.success?
source_dirty = !stdout.empty?
if source_dirty && ENV["ALLOW_DIRTY_REGISTRY"] != "1"
  abort_validation("build imported uncommitted OpenAPI changes")
end

abort_validation("metadata repository is incorrect") unless metadata["repository"] == REPOSITORY_URL
abort_validation("metadata source path is incorrect") unless metadata["source"] == SOURCE_PATH
abort_validation("metadata source commit is incorrect") unless metadata["source_commit"] == source_commit
abort_validation("metadata dirty state is incorrect") unless metadata["source_dirty"] == source_dirty
abort_validation("metadata OpenAPI version is incorrect") unless metadata["openapi"] == version

{
  "yaml" => [yaml_bytes, "#{PUBLIC_ROOT}/openapi.yaml"],
  "json" => [json_text, "#{PUBLIC_ROOT}/openapi.json"]
}.each do |format, (content, url)|
  representation = metadata.fetch("representations").fetch(format)
  abort_validation("#{format} metadata URL is incorrect") unless representation["url"] == url
  unless representation["sha256"] == Digest::SHA256.hexdigest(content)
    abort_validation("#{format} metadata SHA-256 is incorrect")
  end
  abort_validation("#{format} metadata byte count is incorrect") unless representation["bytes"] == content.bytesize
end

homepage_path = site_root.join("index.html")
abort_validation("rendered homepage is missing") unless homepage_path.file?
homepage = homepage_path.read
abort_validation("IRI API Resources dropdown is missing") unless homepage.include?("IRI API Resources")

[
  "/profiles/",
  "/rels/",
  "/api/v2/openapi.yaml",
  "/api/v2/openapi.json",
  "/registry-manifest.json"
].each do |href|
  pattern = /href=["']#{Regexp.escape(href)}["']/
  abort_validation("IRI API Resources dropdown does not link to #{href}") unless homepage.match?(pattern)
end

puts "Validated OpenAPI #{version} YAML, JSON, metadata, and IRI API Resources navigation."
