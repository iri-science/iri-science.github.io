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

Images are optional. To add one later, place it under `images/news/` and add
these front-matter fields to the article:

```yaml
image: 2026-sc26-demos.jpg
image_alt: Describe what the image shows.
image_caption: Optional caption.
image_credit: Photographer or organization.
```

The image appears on the homepage card and article page. Articles without an
image render without an image element or reserved image space. For wide tables,
wrap the Markdown table in a `<div class="news-table-scroll" markdown="1">`
with an accessible label and `tabindex="0"` so it can scroll on small screens.
