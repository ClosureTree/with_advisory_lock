#!/bin/sh -e
export BUNDLE_GEMFILE RMI DB

for RMI in 1.8.7-p370 1.9.3-p327
do
  rbenv local $RMI
  bundle --quiet
  for DB in sqlite mysql postgresql
  do
    echo $DB $BUNDLE_GEMFILE `ruby -v`
    bundle exec rake
  done
done