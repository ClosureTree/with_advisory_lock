#!/bin/sh -e
export BUNDLE_GEMFILE RMI DB

for RMI in ree-1.8.7-2011.03 1.9.3-p327 ; do
  for BUNDLE_GEMFILE in ci/Gemfile.rails-3.0.x ci/Gemfile.rails-3.1.x ci/Gemfile.rails-3.2.x ; do
    rbenv local $RMI
    bundle --quiet
    for DB in sqlite mysql postgresql
    do
      echo $DB $BUNDLE_GEMFILE `ruby -v`
      bundle exec rake
    done
  done
done
