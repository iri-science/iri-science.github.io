docker run --rm -it \
  -p 4000:4000 \
  -v "$PWD":/site \
  -w /site \
  ruby:3.3 \
  bash -lc 'bundle config set path vendor/docker-bundle && bundle install && bundle exec jekyll serve --host 0.0.0.0 --livereload --force_polling'
