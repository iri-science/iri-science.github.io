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

The shared navigation uses native HTML popovers and a small JavaScript module.
It switches to an inline layout when the links fit, including after font or
window size changes. Nested links use ordinary Tab navigation. Browsers without
CSS anchor positioning use measured dropdown positions; browsers without
Popover support display the complete navigation in the page. With JavaScript
disabled, native Popover browsers retain a Menu button with all nested links.
Bootstrap supplies layout styles; its JavaScript, jQuery, and Slick are not
loaded.
Navigation links must resolve to an emitted file or a directory containing
`index.html`; the rendered validator does not assume URL rewriting.
