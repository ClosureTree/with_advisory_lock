#!/bin/sh -e
export BUNDLE_GEMFILE DB

for BUNDLE_GEMFILE in ci/Gemfile.rails-4.1.x ci/Gemfile.rails-3.2.x ; do
  for DB in sqlite mysql postgresql
  do
    echo $DB $BUNDLE_GEMFILE `ruby -v`
    bundle exec rake
  done
done
