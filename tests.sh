#!/bin/sh -e
export BUNDLE_GEMFILE DB

for BUNDLE_GEMFILE in gemfiles/*.gemfile ; do
  for DB in mysql postgresql sqlite
  do
    echo $DB $BUNDLE_GEMFILE `ruby -v`
    bundle exec rake
  done
done
