# iri-science.github.io site

The site publishes the DOE-IRI profile and link-relation registries from the
authoritative `doe-iri/iri-facility-api-docs` repository at `/profiles/` and
`/rels/`. Generated registry pages are build artifacts and are not committed.
Each canonical identifier returns HTML and advertises a raw Markdown alternate
at the same path with a `.md` suffix. `/registry-manifest.json` maps every
identifier to both representations and records the imported source commit.

To build the complete site from sibling checkouts:

```sh
bundle install
ruby scripts/prepare-registry.rb ../iri-facility-api-docs generated-registry
bundle exec jekyll build
bundle exec htmlproofer _site --disable-external --checks Links,Scripts --allow-missing-href
ruby scripts/validate-registry-build.rb ../iri-facility-api-docs _site
```

The build records the exact imported registry commit in
`/registry-import.json`. GitHub Actions validates pull requests and deploys the
complete site after changes reach `main` or a deployment is started manually.
The registry checkout must be clean so its recorded commit describes the
published content exactly; set `ALLOW_DIRTY_REGISTRY=1` only for local previews.
Before the first deployment, a repository administrator must select GitHub
Actions as the Pages publishing source.
