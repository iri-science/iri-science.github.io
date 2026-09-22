# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"
require "yaml"

class PrepareOpenapiTest < Minitest::Test
  ROOT = Pathname(__dir__).join("..").expand_path
  SCRIPT = ROOT.join("scripts/prepare-openapi.rb")
  VALIDATOR = ROOT.join("scripts/validate-openapi-build.rb")
  SOURCE_PATH = "specification-v2/openapi/all_spec_v2.yaml"

  def setup
    @temporary_directory = Pathname(Dir.mktmpdir("prepare-openapi-test"))
    @source = @temporary_directory.join("source")
    @output = @temporary_directory.join("output")
    write_source(valid_openapi)

    run_command("git", "init", "--quiet", @source.to_s)
    run_command("git", "-C", @source.to_s, "config", "user.email", "test@example.org")
    run_command("git", "-C", @source.to_s, "config", "user.name", "Test User")
    commit("fixture")
  end

  def teardown
    FileUtils.remove_entry(@temporary_directory) if @temporary_directory.exist?
  end

  def test_copies_yaml_and_generates_equivalent_json_with_metadata
    stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)
    assert status.success?, "#{stdout}\n#{stderr}"

    yaml = @output.join("openapi.yaml")
    json = @output.join("openapi.json")
    metadata = JSON.parse(@output.join("openapi-metadata.json").read)
    commit_hash = run_command("git", "-C", @source.to_s, "rev-parse", "HEAD").strip

    assert_equal @source.join(SOURCE_PATH).binread, yaml.binread
    assert_equal YAML.safe_load(yaml.read), JSON.parse(json.read)
    assert_equal "#/components/schemas/Resource", JSON.parse(json.read).dig("paths", "/resources", "get", "responses", "200", "content", "application/json", "schema", "$ref")
    assert_equal commit_hash, metadata.fetch("source_commit")
    assert_equal "https://iri.science/api/v2/openapi.yaml", metadata.dig("representations", "yaml", "url")
    assert_equal "https://iri.science/api/v2/openapi.json", metadata.dig("representations", "json", "url")
  end

  def test_rejects_malformed_yaml
    write_source("openapi: [\n")
    commit("malformed")

    _stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)
    refute status.success?
    assert_includes stderr, "Cannot parse OpenAPI source"
    refute @output.exist?
  end

  def test_rejects_missing_source
    FileUtils.rm(@source.join(SOURCE_PATH))
    commit("remove source")

    _stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)
    refute status.success?
    assert_includes stderr, "OpenAPI source file does not exist"
    refute @output.exist?
  end

  def test_rejects_dirty_source_checkout
    write_source(valid_openapi.sub("Fixture", "Changed"))

    _stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, @output.to_s)
    refute status.success?
    assert_includes stderr, "OpenAPI source checkout has uncommitted changes"
    refute @output.exist?
  end

  def test_validator_detects_a_semantically_different_json_representation
    site = @temporary_directory.join("site")
    output = site.join("api/v2")
    _stdout, stderr, status = Open3.capture3("ruby", SCRIPT.to_s, @source.to_s, output.to_s)
    assert status.success?, stderr
    site.join("index.html").write(<<~HTML)
      <nav>IRI API Resources
        <a href="/profiles/">Profiles</a>
        <a href="/rels/">Link Relations</a>
        <a href="/api/v2/openapi.yaml">OpenAPI YAML</a>
        <a href="/api/v2/openapi.json">OpenAPI JSON</a>
        <a href="/registry-manifest.json">Registry Manifest</a>
      </nav>
    HTML

    _stdout, stderr, status = Open3.capture3("ruby", VALIDATOR.to_s, @source.to_s, site.to_s)
    assert status.success?, stderr

    json_path = output.join("openapi.json")
    document = JSON.parse(json_path.read)
    document.fetch("info")["title"] = "Tampered"
    json_path.write("#{JSON.pretty_generate(document)}\n")

    _stdout, stderr, status = Open3.capture3("ruby", VALIDATOR.to_s, @source.to_s, site.to_s)
    refute status.success?
    assert_includes stderr, "published JSON is not equivalent to the source"
  end

  def test_navigation_groups_iri_api_resources
    menu = ROOT.join("_includes/menu.html").read
    dropdown = menu.match(/IRI API Resources.*?<div class="dropdown-menu"[^>]*>(.*?)<\/div>\s*<\/li>/m)

    refute_nil dropdown
    %w[/profiles/ /rels/ /api/v2/openapi.yaml /api/v2/openapi.json /registry-manifest.json].each do |href|
      assert_includes dropdown[1], %(href="#{href}")
    end
    refute_match(/<li class="nav-item">\s*<a class="nav-link" href="\/(?:profiles|rels)\//m, menu)
  end

  private

  def valid_openapi
    <<~YAML
      openapi: 3.1.0
      info:
        title: Fixture
        version: 2.0.0
      paths:
        /resources:
          get:
            responses:
              '200':
                description: Resource
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/Resource'
      components:
        schemas:
          Resource:
            type: object
    YAML
  end

  def write_source(content)
    path = @source.join(SOURCE_PATH)
    FileUtils.mkdir_p(path.dirname)
    path.write(content)
  end

  def commit(message)
    run_command("git", "-C", @source.to_s, "add", "-A")
    run_command("git", "-C", @source.to_s, "commit", "--quiet", "-m", message)
  end

  def run_command(*command)
    stdout, stderr, status = Open3.capture3(*command)
    raise "#{command.join(' ')} failed: #{stderr}" unless status.success?

    stdout
  end
end
