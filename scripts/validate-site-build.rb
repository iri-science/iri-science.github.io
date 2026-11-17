#!/usr/bin/env ruby
# Validate shared accessibility contracts in the rendered Jekyll site.
require "nokogiri"
require "pathname"
require "uri"

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

abort errors.join("\n") unless errors.empty?
puts "Validated shared landmarks, navigation, zoom, images, and schedule tables in #{pages.length} pages."
