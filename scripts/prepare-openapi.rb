#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "pathname"
require "yaml"

class OpenapiPreparer
  REPOSITORY_URL = "https://github.com/doe-iri/iri-facility-api-docs"
  PUBLIC_ROOT = "https://iri.science/api/v2"
  SOURCE_PATH = "specification-v2/openapi/all_spec_v2.yaml"
  REQUIRED_KEYS = %w[info paths components].freeze

  def initialize(source_root, output_root)
    @source_root = Pathname(source_root).expand_path
    @output_root = Pathname(output_root).expand_path
  end

  def run
    abort "OpenAPI source checkout does not exist: #{@source_root}" unless @source_root.directory?

    source_path = @source_root.join(SOURCE_PATH)
    abort "OpenAPI source file does not exist: #{source_path}" unless source_path.file?

    commit = source_commit
    dirty = source_dirty?
    if dirty && ENV["ALLOW_DIRTY_REGISTRY"] != "1"
      abort "OpenAPI source checkout has uncommitted changes; commit them or set ALLOW_DIRTY_REGISTRY=1 for a local preview"
    end

    yaml_bytes = source_path.binread
    yaml_text = yaml_bytes.dup.force_encoding(Encoding::UTF_8)
    abort "OpenAPI source is not valid UTF-8: #{source_path}" unless yaml_text.valid_encoding?

    document = parse_yaml(yaml_text, source_path)
    validate_document(document, source_path)
    json = "#{JSON.pretty_generate(document)}\n"

    FileUtils.mkdir_p(@output_root)
    @output_root.join("openapi.yaml").binwrite(yaml_bytes)
    @output_root.join("openapi.json").write(json)
    @output_root.join("openapi-metadata.json").write(
      "#{JSON.pretty_generate(metadata(commit, dirty, yaml_bytes, json, document))}\n"
    )

    puts "Published OpenAPI #{document.fetch('openapi')} from #{commit} at /api/v2/openapi.{yaml,json}."
  end

  private

  def source_commit
    stdout, stderr, status = Open3.capture3("git", "-C", @source_root.to_s, "rev-parse", "HEAD")
    abort "Cannot determine OpenAPI source commit: #{stderr.strip}" unless status.success?

    stdout.strip
  end

  def source_dirty?
    stdout, stderr, status = Open3.capture3(
      "git", "-C", @source_root.to_s, "status", "--porcelain", "--untracked-files=normal"
    )
    abort "Cannot inspect OpenAPI source checkout: #{stderr.strip}" unless status.success?

    !stdout.empty?
  end

  def parse_yaml(text, source_path)
    YAML.safe_load(text, aliases: true)
  rescue Psych::Exception => e
    abort "Cannot parse OpenAPI source #{source_path}: #{e.message}"
  end

  def validate_document(document, source_path)
    abort "OpenAPI source must contain a top-level mapping: #{source_path}" unless document.is_a?(Hash)

    version = document["openapi"]
    unless version.is_a?(String) && version.match?(/\A3\.1(?:\.|\z)/)
      abort "OpenAPI source must declare an OpenAPI 3.1 version: #{source_path}"
    end

    missing = REQUIRED_KEYS.reject { |key| document[key].is_a?(Hash) }
    return if missing.empty?

    abort "OpenAPI source is missing mapping(s): #{missing.join(', ')}"
  end

  def metadata(commit, dirty, yaml_bytes, json, document)
    {
      "repository" => REPOSITORY_URL,
      "source" => SOURCE_PATH,
      "source_commit" => commit,
      "source_dirty" => dirty,
      "openapi" => document.fetch("openapi"),
      "representations" => {
        "yaml" => representation("#{PUBLIC_ROOT}/openapi.yaml", yaml_bytes),
        "json" => representation("#{PUBLIC_ROOT}/openapi.json", json)
      }
    }
  end

  def representation(url, content)
    {
      "url" => url,
      "sha256" => Digest::SHA256.hexdigest(content),
      "bytes" => content.bytesize
    }
  end
end

if ARGV.empty? || ARGV.length > 2
  warn "Usage: ruby scripts/prepare-openapi.rb SOURCE_CHECKOUT [OUTPUT_DIRECTORY]"
  exit 64
end

OpenapiPreparer.new(ARGV[0], ARGV[1] || "_site/api/v2").run
