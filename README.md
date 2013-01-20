# with_advisory_lock [![Build Status](https://api.travis-ci.org/mceachen/with_advisory_lock.png?branch=master)](https://travis-ci.org/mceachen/with_advisory_lock)

Adds advisory locking to ActiveRecord 3.x.
[MySQL](http://dev.mysql.com/doc/refman/5.0/en/miscellaneous-functions.html#function_get-lock)
and [PostgreSQL](http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS)
are supported natively. SQLite resorts to file locking (which won't span hosts, of course!).

## What's an "Advisory Lock"?

An advisory lock is a [mutex](http://en.wikipedia.org/wiki/Mutual_exclusion) used to ensure no two
processes run some process at the same time. When the advisory lock is powered by your database
server, as long as it isn't SQLite, your mutex spans hosts.

Advisory locks ignore database transaction boundaries.

### When to use

If you want to prevent duplicate inserts, and there isn't a row or valid SELECT to lock against,
you need a [shared mutex](http://en.wikipedia.org/wiki/Mutual_exclusion), either though
a [table-level lock](https://github.com/mceachen/monogamy), or through an advisory lock.

When possible, use [optimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html)
or [pessimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html) row locking
instead.

## Usage

```ruby
Tag.with_advisory_lock(lock_name) do
  do_something_that_needs_locking
end
```

### What happens

1. The thread will wait indefinitely until the lock is acquired.
2. While inside the block, you will exclusively own the advisory lock.
3. The lock will be released after your block ends, even if an exception is raised in the block.

### Lock wait timeouts

The second parameter for ```with_advisory_lock``` is ```timeout_seconds```, and defaults to ```nil```,
which means wait indefinitely for the lock.

If a non-nil value is provided, the block may not be invoked.

The return value of ```with_advisory_lock``` will be the result of the yielded block,
if the lock was able to be acquired and the block yielded, or ```false```, if you provided
a timeout_seconds value and the lock was not able to be acquired in time.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'with_advisory_lock'
```

And then execute:

    $ bundle

## Changelog

### 0.0.1

* First whack
