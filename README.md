# iri-science.github.io site

The site publishes the DOE-IRI profile and link-relation registries from the
authoritative `doe-iri/iri-facility-api-docs` repository at `/profiles/` and
`/rels/`. Generated registry pages are build artifacts and are not committed.
Each canonical identifier returns HTML and advertises a raw Markdown alternate
at the same path with a `.md` suffix. `/registry-manifest.json` maps every
identifier to both representations and records the imported source commit.
The IRI Facility API v2 OpenAPI document is published directly from
`specification-v2/openapi/all_spec_v2.yaml` as both
[`/api/v2/openapi.yaml`](https://iri.science/api/v2/openapi.yaml) and
[`/api/v2/openapi.json`](https://iri.science/api/v2/openapi.json). Publication metadata, including
the source commit and representation hashes, is available at
[`/api/v2/openapi-metadata.json`](https://iri.science/api/v2/openapi-metadata.json). These
resources are grouped with the Facility API Documentation, Profiles, and Link
Relations in the site's **IRI API Resources** navigation menu.

To build the complete site from sibling checkouts:

```sh
bundle install
ruby test/prepare_registry_test.rb
ruby test/prepare_openapi_test.rb
ruby scripts/prepare-registry.rb ../iri-facility-api-docs generated-registry
bundle exec jekyll build
ruby scripts/prepare-openapi.rb ../iri-facility-api-docs _site/api/v2
bundle exec htmlproofer _site --disable-external --checks Links,Scripts --allow-missing-href
bundle exec ruby scripts/validate-site-build.rb _site
ruby scripts/validate-registry-build.rb ../iri-facility-api-docs _site
ruby scripts/validate-openapi-build.rb ../iri-facility-api-docs _site
```

The build records the exact imported registry commit in
`/registry-import.json`, while `/api/v2/openapi-metadata.json` records OpenAPI
provenance and hashes. GitHub Actions validates pull requests and deploys the
complete site after changes reach `main`, on its daily schedule, or when a
deployment is started manually.
The registry checkout must be clean so its recorded commit describes the
published content exactly; set `ALLOW_DIRTY_REGISTRY=1` only for local previews.
Before the first deployment, a repository administrator must select GitHub
Actions as the Pages publishing source.

## News articles

Add articles as Markdown documents under `_news/` using `layout: article`.
Set `title`, `headline` (the short homepage label), `date` (publication date),
`author`, `summary`, `category: News`, and a stable `/news/.../` `permalink` in
the YAML front matter. The homepage lists articles by publication date, newest
first, and uses `summary` for each card. The same summary supplies the article's
page description. Start the body with the introductory text; the layout renders
the title and byline.

Images are optional. Set `image` to a site-root path beginning with `/` to use
an existing asset, or use a filename for an image under `images/news/`. Add
descriptive alternative text and, when available, a caption and credit:

```yaml
image: 2026-sc26-demos.jpg
image_alt: Describe what the image shows.
image_caption: Optional caption.
image_credit: Photographer or organization.
```

For example, `image: /images/sc26_hor_color_white.png` uses the image at that
path. Both path forms respect the configured site `baseurl`. Set
`image_fit: contain` to show the whole image within the homepage card's 16:9
frame instead of cropping it. Set `image_background: dark` for a dark, padded
background on both the card and article image, useful for white logo lettering.
Article images always retain their natural aspect ratio.
Record the intrinsic width and height of new or replaced local images in
`_data/image_dimensions.json`; the homepage and article templates use these
dimensions to reserve space before the images load.

The image appears on the homepage card and article page. Articles without an
image render without an image element or reserved image space. For wide tables,
wrap the Markdown table in a `<div class="news-table-scroll" markdown="1">`
with an accessible label and `tabindex="0"` so it can scroll on small screens.

## Navigation

The shared navigation uses a single hamburger Menu button at every screen size.
Its native HTML popover supports Escape and outside-click dismissal; a small
JavaScript module expands nested groups, with ordinary Tab navigation for links.
CSS anchor positioning aligns the panel with the button, with a fixed-position
fallback. Browsers without Popover support display the complete navigation in
the page. With JavaScript disabled, native Popover browsers retain the Menu
button with all nested links.
Bootstrap supplies layout styles; its JavaScript, jQuery, and Slick are not
loaded.
Navigation links must resolve to an emitted file or a directory containing
`index.html`; the rendered validator does not assume URL rewriting.
The shared head appends the same build timestamp to local stylesheets and the
navigation script. Rebuilding changes these URLs so cached navigation code
cannot run against newly rendered markup after an update.


## Landing pages and curated content

The homepage and permanent entry points retain server-rendered Jekyll/Liquid
content. New landing pages use `layout: page`, `content_page: true`, a unique
`summary`, and an explicit trailing-slash `permalink`; the layout supplies the
single H1, so their body headings begin at H2. Ordinary pages receive canonical
links automatically. Registry canonical identifiers and Markdown alternates
retain their separate handling.

- `_data/implementations.yml` drives the homepage roster and `/implementations/`.
  Keep a unique, stable `id`, the public organization name and full name,
  `implementing` status, and supporting maintenance evidence. Preserve IDs when
  editing names so directory anchors remain stable. Only include official public
  websites; do not infer API endpoints from organization websites.
- Optional API versions, capabilities, deployment stage, documentation, and
  version availability require supporting evidence. Store v1/v2 availability in
  `api_versions`, with one or more `targets` containing a slide status, optional
  environment `label`, and an absolute HTTPS `url` when that version has a
  public API root. Omit the URL for unavailable versions so their status remains
  noninteractive. Internal evidence notes are not rendered. Add or correct an
  implementation through a repository change or Contact Us.
- `_data/iri_features.yml` contains the four homepage benefit statements and
  their links into the IRI 2.0 overview.
- `_data/case_studies.yml` supplies the homepage cards and `/in-practice/`.
  Record the integration problem, documented result, original story, and a
  checked reusable-artifact link. Keep the original articles, dates, and credits.

The homepage shows the latest three news items and two events. `/news/` and
`/events/` retain complete reverse-chronological listings. Event listings do not
infer whether an event is upcoming. Keep existing `.html` page destinations
and collection permalinks stable when editing navigation. The `IRI API
Resources` label and its publication links are validated compatibility contracts.

`css/site-content.css` scopes the refreshed hero, card grids, directory, and
call-to-action groups. Keep content and navigation available without JavaScript;
no runtime fetch populates the roster. Run the full build sequence above after
updates; the rendered validator also checks the seven landing routes and roster
consistency between the homepage, directory, and data file.
