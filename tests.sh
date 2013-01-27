#!/bin/sh -ex
export BUNDLE_GEMFILE RMI DB

for RMI in 1.8.7-p370 1.9.3-p327
do
  rbenv local $RMI
  (gem list | grep bundler) || gem install bundler
  (gem list | grep rake) || gem install rake
  rbenv rehash || true

  for BUNDLE_GEMFILE in ci/Gemfile.activerecord-3.0.x ci/Gemfile.activerecord-3.1.x ci/Gemfile.activerecord-3.2.x
  do
    bundle --quiet
    for DB in sqlite3 mysql pg
    do
      echo $DB $BUNDLE_GEMFILE `ruby -v`
      bundle exec rake
    done
  done
done