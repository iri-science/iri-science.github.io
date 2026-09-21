# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"

class PrepareRegistryTest < Minitest::Test
  SCRIPT = Pathname(__dir__).join("../scripts/prepare-registry.rb").expand_path

  def setup
    @temporary_directory = Pathname(Dir.mktmpdir("prepare-registry-test"))
    @source = @temporary_directory.join("source")
    @output = @temporary_directory.join("output")

    write("registry/profiles/README.md", <<~MARKDOWN)
      # Profiles

      [Resource
      profile](status/resource.md)
      [Relation](../relations/example.md)
      [RFC](../../rfc/example.md)

      ```text
      [Example only](../relations/example.md)
      ```
    MARKDOWN
    write("registry/profiles/status/resource.md", "# Resource Profile\n")
    write("registry/profiles/AGENTS.md", "Do not publish this file.\n")
    write("registry/relations/README.md", "# Relations\n\n[Example](example.md)\n")
    write("registry/relations/example.md", "# Example Relation\n\n[Resource](../profiles/status/resource.md)\n")
    write("registry/relations/AGENTS.md", "Do not publish this file.\n")
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

    assert_includes profile_index, "](/profiles/status/resource/)"
    assert_includes profile_index, "](/rels/example/)"
    assert_includes profile_index, "https://github.com/doe-iri/iri-facility-api-docs/blob/#{commit}/rfc/example.md"
    assert_includes profile_index, "[Example only](../relations/example.md)"
    assert_includes relation, "](/profiles/status/resource/)"
    assert @output.join("indexes/profiles/status.md").file?

    manifest_text = @output.join("registry-manifest.json").read.sub(/\A---.*?---\n/m, "")
    sources = JSON.parse(manifest_text).fetch("pages").map { |page| page.fetch("source") }
    refute sources.any? { |source| source.end_with?("AGENTS.md") }
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
