# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"

module RegistryPreparationTests
  SCRIPT = Pathname(__dir__).join("../scripts/prepare-registry.rb").expand_path

  def setup
    @temporary_directory = Pathname(Dir.mktmpdir("prepare-registry-test"))
    @source = @temporary_directory.join("source")
    @output = @temporary_directory.join("output")

    write("registry/profiles/README.md", <<~MARKDOWN)
      # Profiles

      [Resource
      profile](status/resource.md)
      [Relation](../#{relation_directory}/example.md)
      [RFC](../../rfc/example.md)

      ```text
      [Example only](../#{relation_directory}/example.md)
      ```
    MARKDOWN
    write("registry/profiles/status/resource.md", "# Resource Profile\n")
    write("registry/profiles/AGENTS.md", "Do not publish this file.\n")
    write("registry/#{relation_directory}/README.md", "# Relations\n\n[Example](example.md)\n")
    write("registry/#{relation_directory}/example.md", "# Example Relation\n\n[Resource](../profiles/status/resource.md)\n")
    write("registry/#{relation_directory}/AGENTS.md", "Do not publish this file.\n")
    write("rfc/example.md", "# RFC\n")

    run_command("git", "init", "--quiet", @source.to_s)
    run_command("git", "-C", @source.to_s, "config", "user.email", "test@example.org")
    run_command("git", "-C", @source.to_s, "config", "user.name", "Test User")
    run_command("git", "-C", @source.to_s, "add", ".")
    run_command("git", "-C", @source.to_s, "commit", "--quiet", "-m", "fixture")
  end

  def teardown
    FileUtils.remove_entry(@temporary_directory) if @temporary_directory.exist?
  end

  def test_generates_pages_and_rewrites_only_published_document_links
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)
    assert status.success?, "#{stdout}\n#{stderr}"

    commit = run_command("git", "-C", @source.to_s, "rev-parse", "HEAD").strip
    profile_index = @output.join("imported/profiles.md").read
    relation = @output.join("imported/rels/example.md").read
    resource_markdown = @output.join("alternates/profiles/status/resource.txt").read

    assert_includes profile_index, "](/profiles/status/resource/)"
    assert_includes profile_index, "](/rels/example/)"
    assert_includes profile_index, "https://github.com/doe-iri/iri-facility-api-docs/blob/#{commit}/rfc/example.md"
    assert_includes profile_index, "[Example only](../#{relation_directory}/example.md)"
    assert_includes relation, "](/profiles/status/resource/)"
    assert_includes profile_index, 'registry_identifier: "https://iri.science/profiles"'
    assert_includes profile_index, 'registry_markdown_url: "https://iri.science/profiles.md"'
    assert_includes resource_markdown, 'permalink: "/profiles/status/resource.md"'
    assert_includes resource_markdown, "# Resource Profile"
    assert @output.join("indexes/profiles/status.md").file?
    assert @output.join("alternates/profiles/status.txt").file?

    manifest_text = @output.join("registry-manifest.json").read.sub(/\A---.*?---\n/m, "")
    manifest = JSON.parse(manifest_text)
    sources = manifest.fetch("pages").map { |page| page.fetch("source") }
    assert_equal ["registry/profiles/README.md", "registry/profiles/status/resource.md",
                  "registry/#{relation_directory}/README.md", "registry/#{relation_directory}/example.md"].sort,
                 sources.sort
    relation_page = manifest.fetch("pages").find { |page| page.fetch("source") == "registry/#{relation_directory}/example.md" }
    assert_equal "https://iri.science/rels/example", relation_page.fetch("identifier")
    assert_equal "https://iri.science/rels/example.md", relation_page.fetch("markdown")
    assert_equal "/rels/example/", relation_page.fetch("permalink")
    refute sources.any? { |source| source.end_with?("AGENTS.md") }
    resource = manifest.fetch("pages").find do |page|
      page.fetch("source") == "registry/profiles/status/resource.md"
    end
    assert_equal "https://iri.science/profiles/status/resource", resource.fetch("identifier")
    assert_equal "https://iri.science/profiles/status/resource", resource.fetch("html")
    assert_equal "https://iri.science/profiles/status/resource.md", resource.fetch("markdown")
  end

  def test_stops_and_reports_unresolved_source_links
    write("registry/profiles/broken.md", "# Broken\n\n[Missing](missing.md)\n")
    run_command("git", "-C", @source.to_s, "add", ".")
    run_command("git", "-C", @source.to_s, "commit", "--quiet", "-m", "add broken link")
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)

    refute status.success?, stdout
    assert_includes stderr, "registry/profiles/broken.md:3: missing.md"
    refute @output.exist?
  end

  def test_rejects_a_dirty_registry_checkout_by_default
    write("registry/profiles/uncommitted.md", "# Uncommitted\n")
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)

    refute status.success?, stdout
    assert_includes stderr, "Registry checkout has uncommitted changes"
    refute @output.exist?
  end

  def test_rejects_ambiguous_relation_directories
    other_directory = relation_directory == "rels" ? "relations" : "rels"
    FileUtils.mkdir_p(@source.join("registry", other_directory))
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)

    refute status.success?, stdout
    assert_includes stderr, "exactly one relation directory"
    refute @output.exist?
  end

  def test_rejects_a_missing_relation_directory
    FileUtils.remove_entry(@source.join("registry", relation_directory))
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)

    refute status.success?, stdout
    assert_includes stderr, "exactly one relation directory"
    refute @output.exist?
  end

  def test_requires_the_relation_index
    @source.join("registry", relation_directory, "README.md").delete
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)

    refute status.success?, stdout
    assert_includes stderr, "#{relation_directory}/README.md"
    refute @output.exist?
  end

  private

  def write(relative_path, content)
    path = @source.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    path.write(content)
  end

  def run_command(*command)
    stdout, stderr, status = Open3.capture3(*command)
    raise "#{command.join(' ')} failed: #{stderr}" unless status.success?

    stdout
  end
end

class PrepareRegistryTest < Minitest::Test
  include RegistryPreparationTests

  def relation_directory
    "rels"
  end
end

class PrepareLegacyRegistryTest < Minitest::Test
  include RegistryPreparationTests

  def relation_directory
    "relations"
  end
end
