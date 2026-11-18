#!/usr/bin/env ruby
# Validate shared accessibility contracts in the rendered Jekyll site.
require "nokogiri"
require "pathname"
require "uri"
require "yaml"

site = Pathname.new(ARGV.fetch(0, "_site")).expand_path
pages = site.glob("**/*.html")
abort "No rendered HTML pages found in #{site}" if pages.empty?
errors = []
checked_navigation_links = {}

pages.each do |path|
  document = Nokogiri::HTML(path.read)
  failures = []
  failures << "expected one main landmark" unless document.css("main").length == 1
  failures << "expected one h1" unless document.css("h1").length == 1
  failures << "missing page language" if document.at_css("html")&.[]("lang").to_s.empty?
  failures << "missing page title" if document.at_css("title")&.text.to_s.strip.empty?

  viewport = document.at_css('meta[name="viewport"]')&.[]("content").to_s
  if viewport.empty? || viewport.match?(/maximum-scale\s*=\s*1(?:\D|$)|user-scalable\s*=\s*(?:no|0)/i)
    failures << "viewport must permit zoom"
  end

  target = document.at_css('main[id="main-content"][tabindex="-1"]')
  skip = document.at_css('a[href="#main-content"]')
  failures << "missing usable skip link" unless skip && target
  failures << "missing named primary navigation" unless document.at_css('nav[aria-label="Primary"]')

  base_path = document.at_css(".site-brand")&.[]("href").to_s.delete_suffix("/")
  document.css('nav[aria-label="Primary"] a[href]').each do |link|
    href = link["href"]
    next if checked_navigation_links[href]
    checked_navigation_links[href] = true
    uri = URI.parse(href)
    next if uri.scheme || uri.host || !uri.path.start_with?("/")

    relative_path = URI::DEFAULT_PARSER.unescape(uri.path).delete_prefix(base_path).delete_prefix("/")
    destination = site.join(relative_path)
    unless destination.file? || destination.join("index.html").file?
      failures << "navigation link has no directly served file or index: #{href}"
    end
  end

  document.css("img").each do |image|
    failures << "image missing alt: #{image['src']}" unless image.key?("alt")
    unless image["width"].to_i.positive? && image["height"].to_i.positive?
      failures << "image missing dimensions: #{image['src']}"
    end
  end

  document.css("button[aria-controls]").each do |button|
    id = button["aria-controls"]
    failures << "navigation control must be type=button" unless button["type"] == "button"
    failures << "missing controlled element: #{id}" unless document.at_xpath("//*[@id=#{id.inspect}]")
    failures << "navigation control has no name" if button.text.strip.empty?
  end

  document.css(".table-scroll").each do |wrapper|
    caption = document.at_xpath("//*[@id=#{wrapper['aria-labelledby'].to_s.inspect}]")
    unless wrapper["tabindex"] == "0" && wrapper["role"] == "region" && caption
      failures << "schedule table needs a named, keyboard-scrollable wrapper"
    end
    if wrapper.css("thead th").any? { |cell| cell["scope"] != "col" }
      failures << "schedule table needs scoped column headers"
    end
  end

  failures.each { |failure| errors << "#{path.relative_path_from(site)}: #{failure}" }
end

landing_routes = %w[iri-2-0 implementations in-practice developers community news events]
homepage = Nokogiri::HTML(site.join("index.html").read)
landing_routes.each do |route|
  output = site.join(route, "index.html")
  unless output.file?
    errors << "missing landing route: /#{route}/"
    next
  end
  document = Nokogiri::HTML(output.read)
  errors << "#{route}: missing page description" if document.at_css('meta[name="description"]')&.[]("content").to_s.strip.empty?
  errors << "#{route}: missing canonical link" unless document.at_css('link[rel="canonical"]')
  unless homepage.css("nav a[href]").any? { |link| URI.parse(link["href"]).path.end_with?("/#{route}/") }
    errors << "landing route missing from primary navigation: /#{route}/"
  end
end

data = YAML.safe_load(Pathname(__dir__).join("../_data/implementations.yml").read)
implementations = data.select { |entry| entry["implementing"] }
ids = implementations.map { |entry| entry.fetch("id") }
errors << "implementation IDs must be unique" unless ids.uniq == ids
required_ids = %w[alcf olcf nersc esnet pnnl slac nrp fermilab]
errors << "maintainer implementation roster is incomplete" unless (required_ids - ids).empty?

status_slugs = {
  "Ready" => "ready",
  "Partial" => "partial",
  "In progress" => "in-progress",
  "Onboarding" => "onboarding",
  "Not yet" => "not-yet"
}.freeze

versions_by_implementation = implementations.to_h do |implementation|
  id = implementation.fetch("id")
  versions = implementation["api_versions"] || []
  unless versions.is_a?(Array)
    errors << "#{id}: api_versions must be a list"
    versions = []
  end

  normalized_versions = versions.each_with_index.map do |version_entry, version_index|
    unless version_entry.is_a?(Hash)
      errors << "#{id}: api_versions[#{version_index}] must be an object"
      next { "version" => "", "targets" => [] }
    end

    version = version_entry["version"].to_s.strip
    targets = version_entry["targets"] || []
    unless targets.is_a?(Array) && !targets.empty?
      errors << "#{id}: api_versions[#{version_index}].targets must be a nonempty list"
      targets = []
    end

    normalized_targets = targets.each_with_index.map do |target, target_index|
      unless target.is_a?(Hash)
        errors << "#{id}: api_versions[#{version_index}].targets[#{target_index}] must be an object"
        next { "label" => "", "status" => "", "status_slug" => "", "url" => nil }
      end

      label = target["label"].to_s.strip
      status = target["status"].to_s.strip
      status_slug = status_slugs[status]
      errors << "#{id}: #{version} target #{target_index} has an unsupported status" unless status_slug
      if targets.length > 1 && label.empty?
        errors << "#{id}: #{version} targets require labels when multiple endpoints are shown"
      end

      raw_url = target["url"].to_s.strip
      url = raw_url.empty? ? nil : raw_url
      if status == "Not yet" && url
        errors << "#{id}: #{version} target #{target_index} must not link a Not yet status"
      end
      if url
        begin
          uri = URI.parse(url)
          valid_url = uri.is_a?(URI::HTTPS) && !uri.host.to_s.empty?
        rescue URI::InvalidURIError
          valid_url = false
        end
        errors << "#{id}: #{version} target #{target_index} must use an absolute HTTPS URL" unless valid_url
      end

      {
        "label" => label,
        "status" => status,
        "status_slug" => status_slug.to_s,
        "url" => url
      }
    end

    { "version" => version, "targets" => normalized_targets }
  end

  actual_versions = normalized_versions.map { |version_entry| version_entry.fetch("version") }
  errors << "#{id}: api_versions must contain v1 then v2" unless actual_versions == %w[v1 v2]
  [id, normalized_versions]
end

%w[index.html implementations/index.html].each do |name|
  next unless site.join(name).file?
  document = Nokogiri::HTML(site.join(name).read)
  rendered_ids = document.css("[data-implementation-id]").map { |entry| entry["data-implementation-id"] }
  errors << "#{name}: roster does not match implementation data" unless rendered_ids.sort == ids.sort
  implementations.each do |implementation|
    id = implementation.fetch("id")
    card = document.at_css(%([data-implementation-id="#{id}"]))
    unless card
      errors << "#{name}: missing implementation card for #{id}"
      next
    end

    if name.start_with?("implementations/") && !document.at_css("#implementation-#{implementation['id']}")
      errors << "#{name}: missing stable anchor for #{implementation['id']}"
    end

    unless card.css(".iri-api-link, .ti-server").empty?
      errors << "#{name}: #{id} still renders the retired generic server API link"
    end

    expected_versions = versions_by_implementation.fetch(id)
    rendered_rows = card.css(".iri-api-version-row")
    rendered_version_names = rendered_rows.map { |row| row["data-api-version"].to_s }
    expected_version_names = expected_versions.map { |version_entry| version_entry.fetch("version") }
    unless rendered_version_names == expected_version_names
      errors << "#{name}: #{id} API version rows do not match implementation data"
    end

    expected_versions.each_with_index do |version_entry, version_index|
      row = rendered_rows[version_index]
      next unless row

      version = version_entry.fetch("version")
      targets = version_entry.fetch("targets")
      primary_url = targets.first&.fetch("url")
      version_labels = row.css(".iri-api-version-label")
      unless version_labels.length == 1
        errors << "#{name}: #{id} #{version} must render exactly one version label"
      end
      version_label = version_labels.first
      if version_label.nil?
        errors << "#{name}: #{id} #{version} is missing its version label"
      else
        label_text = version_label.text.gsub(/\s+/, " ").strip
        errors << "#{name}: #{id} #{version} has the wrong version label" unless label_text == "IRI #{version}"
        if primary_url
          unless version_label.name == "a" && version_label["href"] == primary_url
            errors << "#{name}: #{id} #{version} label does not link to its primary API"
          end
        elsif version_label.name == "a" || version_label.key?("href")
          errors << "#{name}: #{id} #{version} label must not link without an API URL"
        end
      end

      rendered_statuses = row.css(".iri-api-status")
      unless rendered_statuses.length == targets.length
        errors << "#{name}: #{id} #{version} status count does not match implementation data"
      end
      targets.each_with_index do |target, target_index|
        status = rendered_statuses[target_index]
        next unless status

        expected_text = [target.fetch("label"), target.fetch("status")].reject(&:empty?).join(" · ")
        rendered_text = status.text.gsub(/\s+/, " ").strip
        unless rendered_text == expected_text
          errors << "#{name}: #{id} #{version} target #{target_index} has the wrong status text"
        end

        expected_class = "iri-api-status-#{target.fetch('status_slug')}"
        unless status["class"].to_s.split.include?(expected_class)
          errors << "#{name}: #{id} #{version} target #{target_index} has the wrong status class"
        end

        target_url = target.fetch("url")
        if target_url
          unless status.name == "a" && status["href"] == target_url
            errors << "#{name}: #{id} #{version} target #{target_index} does not link to its API"
          end
        elsif status.name == "a" || status.key?("href")
          errors << "#{name}: #{id} #{version} target #{target_index} must not link without an API URL"
        end
      end
    end

    implementation.fetch("evidence", []).each do |evidence|
      note = evidence["note"].to_s
      errors << "#{name}: internal implementation evidence is visible" unless note.empty? || !document.text.include?(note)
    end
  end
end
errors << "homepage must show three news items" unless homepage.css(".news-card").length == 3
errors << "homepage must show two events" unless homepage.css(".iri-event-card").length == 2

abort errors.join("\n") unless errors.empty?
puts "Validated shared landmarks, navigation, zoom, images, and schedule tables in #{pages.length} pages."
puts "Validated seven landing routes, curated homepage listings, and the shared implementation roster with API version statuses."
