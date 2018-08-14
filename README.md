# with_advisory_lock

Adds advisory locking (mutexes) to ActiveRecord 4.2, 5.1, and 5.2, with ruby
2.5, 2.4 and 2.3, when used with
[MySQL](https://dev.mysql.com/doc/refman/8.0/en/miscellaneous-functions.html#function_get-lock)
or
[PostgreSQL](https://www.postgresql.org/docs/current/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS).
SQLite resorts to file locking.

[![Build Status](https://api.travis-ci.org/ClosureTree/with_advisory_lock.svg?branch=master)](https://travis-ci.org/ClosureTree/with_advisory_lock)
[![Gem Version](https://badge.fury.io/rb/with_advisory_lock.svg)](https://badge.fury.io/rb/with_advisory_lock)

## What's an "Advisory Lock"?

An advisory lock is a [mutex](https://en.wikipedia.org/wiki/Mutual_exclusion)
used to ensure no two processes run some process at the same time. When the
advisory lock is powered by your database server, as long as it isn't SQLite,
your mutex spans hosts.

## Usage

This gem automatically includes the `WithAdvisoryLock` module in all of your
ActiveRecord models. Here's an example of how to use it where `User` is an
ActiveRecord model, and `lock_name` is some string:

```ruby
User.with_advisory_lock(lock_name) do
  do_something_that_needs_locking
end
```

### What happens

1. The thread will wait indefinitely until the lock is acquired.
2. While inside the block, you will exclusively own the advisory lock.
3. The lock will be released after your block ends, even if an exception is raised in the block.

### Lock wait timeouts

`with_advisory_lock` takes an options hash as the second parameter. The
`timeout_seconds` option defaults to `nil`, which means wait indefinitely for
the lock.

A value of zero will try the lock only once. If the lock is acquired, the block
will be yielded to. If the lock is currently being held, the block will not be
called.

Note that if a non-nil value is provided for `timeout_seconds`, the block will
not be invoked if the lock cannot be acquired within that time-frame.

For backwards compatability, the timeout value can be specified directly as the
second parameter.

### Shared locks

The `shared` option defaults to `false` which means an exclusive lock will be
obtained. Setting `shared` to `true` will allow locks to be obtained by multiple
actors as long as they are all shared locks.

Note: MySQL does not support shared locks.

### Transaction-level locks

PostgreSQL supports transaction-level locks which remain held until the
transaction completes. You can enable this by setting the `transaction` option
to `true`.

Note: transaction-level locks will not be reflected by `.current_advisory_lock`
when the block has returned.

### Return values

The return value of `with_advisory_lock_result` is a `WithAdvisoryLock::Result`
instance, which has a `lock_was_acquired?` method and a `result` accessor
method, which is the returned value of the given block. If your block may
validly return false, you should use this method.

The return value of `with_advisory_lock` will be the result of the yielded
block, if the lock was able to be acquired and the block yielded, or `false`, if
you provided a timeout_seconds value and the lock was not able to be acquired in
time.

### Testing for the current lock status

If you needed to check if the advisory lock is currently being held, you can
call `Tag.advisory_lock_exists?("foo")`, but realize the lock can be acquired
between the time you test for the lock, and the time you try to acquire the
lock.

If you want to see if the current Thread is holding a lock, you can call
`Tag.current_advisory_lock` which will return the name of the current lock. If
no lock is currently held, `.current_advisory_lock` returns `nil`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'with_advisory_lock'
```

And then execute:

    $ bundle

## Lock Types

First off, know that there are **lots** of different kinds of locks available to
you. **Pick the finest-grain lock that ensures correctness.** If you choose a
lock that is too coarse, you are unnecessarily blocking other processes.

### Advisory locks

These are named mutexes that are inherently "application level"—it is up to the
application to acquire, run a critical code section, and release the advisory
lock.

### Row-level locks

Whether [optimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html)
or [pessimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html),
row-level locks prevent concurrent modification to a given model.

**If you're building a
[CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
application, this will be your most commonly used lock.**

### Table-level locks

Provided through something like the
[monogamy](https://github.com/ClosureTree/monogamy) gem, these prevent
concurrent access to **any instance of a model**. Their coarseness means they
aren't going to be commonly applicable, and they can be a source of
[deadlocks](http://en.wikipedia.org/wiki/Deadlock).

## FAQ

### Transactions and Advisory Locks

Advisory locks with MySQL and PostgreSQL ignore database transaction boundaries.

You will want to wrap your block within a transaction to ensure consistency.

### MySQL < 5.7.5 doesn't support nesting

With MySQL < 5.7.5, if you ask for a _different_ advisory lock within
a `with_advisory_lock` block, you will be releasing the parent lock (!!!). A
`NestedAdvisoryLockError`will be raised in this case. If you ask for the same
lock name, `with_advisory_lock` won't ask for the lock again, and the block
given will be yielded to.

This is not an issue in MySQL >= 5.7.5, and no error will be raised for nested
lock usage. You can override this by passing `force_nested_lock_support: true`
or `force_nested_lock_support: false` to the `with_advisory_lock` options.

### Is clustered MySQL supported?

[No.](https://github.com/ClosureTree/with_advisory_lock/issues/16)

### There are many `lock-*` files in my project directory after test runs

This is expected if you aren't using MySQL or Postgresql for your tests.
See [issue 3](https://github.com/ClosureTree/with_advisory_lock/issues/3).

SQLite doesn't have advisory locks, so we resort to file locking, which will
only work if the `FLOCK_DIR` is set consistently for all ruby processes.

In your `spec_helper.rb` or `minitest_helper.rb`, add a `before` and `after` block:

```ruby
before do
  ENV['FLOCK_DIR'] = Dir.mktmpdir
end

after do
  FileUtils.remove_entry_secure ENV['FLOCK_DIR']
end
```

## Changelog

### 4.0.0

- Drop support for unsupported versions of activerecord
- Drop support for unsupported versions of ruby

### 3.2.0

- [Joshua Flanagan](https://github.com/joshuaflanagan) [added a SQL comment to the lock query for PostgreSQL](https://github.com/ClosureTree/with_advisory_lock/pull/28). Thanks!
- [Fernando Luizão](https://github.com/fernandoluizao) found a spurious requirement for `thread_safe`. Thanks for the [fix](https://github.com/ClosureTree/with_advisory_lock/pull/27)!

### 3.1.1

- [Joel Turkel](https://github.com/jturkel) added `require 'active_support'` (it was required, but relied on downstream gems to pull in active_support before pulling in with_advisory_lock). Thanks!

### 3.1.0

- [Jason Weathered](https://github.com/jasoncodes) Added new shared and transaction-level lock options ([Pull request 21](https://github.com/ClosureTree/with_advisory_lock/pull/21)). Thanks!
- Added ActiveRecord 5.0 to build matrix. Dropped 3.2, 4.0, and 4.1 (which no longer get security updates: http://rubyonrails.org/security/)
- Replaced ruby 1.9 and 2.0 (both EOL) with ruby 2.2 and 2.3 (see https://www.ruby-lang.org/en/downloads/)

### 3.0.0

- Added jruby/PostgreSQL support for Rails 4.x
- Reworked threaded tests to allow jruby tests to pass

#### API changes

- `yield_with_lock_and_timeout` and `yield_with_lock` now return instances of
  `WithAdvisoryLock::Result`, so blocks that return `false` are not misinterpreted
  as a failure to lock. As this changes the interface (albeit internal methods), the major version
  number was incremented.
- `with_advisory_lock_result` was introduced, which clarifies whether the lock was acquired
  versus the yielded block returned false.

### 2.0.0

- Lock timeouts of 0 now attempt the lock once, as per suggested by
  [Jon Leighton](https://github.com/jonleighton) and implemented by
  [Abdelkader Boudih](https://github.com/seuros). Thanks to both of you!
- [Pull request 11](https://github.com/ClosureTree/with_advisory_lock/pull/11)
  fixed a downstream issue with jruby support! Thanks, [Aaron Todd](https://github.com/ozzyaaron)!
- Added Travis tests for jruby
- Dropped support for Rails 3.0, 3.1, and Ruby 1.8.7, as they are no longer
  receiving security patches. See http://rubyonrails.org/security/ for more information.
  This required the major version bump.
- Refactored `advisory_lock_exists?` to use existing functionality
- Fixed sqlite's implementation so parallel tests could be run against it

### 1.0.0

- Releasing 1.0.0. The interface will be stable.
- Added `advisory_lock_exists?`. Thanks, [Sean Devine](https://github.com/barelyknown), for the
  great pull request!
- Added Travis test for Rails 4.1

### 0.0.10

- Explicitly added MIT licensing to the gemspec.

### 0.0.9

- Merged in Postgis Adapter Support to address [issue 7](https://github.com/ClosureTree/with_advisory_lock/issues/7)
  Thanks for the pull request, [Abdelkader Boudih](https://github.com/seuros)!
- The database switching code had to be duplicated by [Closure Tree](https://github.com/ClosureTree/closure_tree),
  so I extracted a new `WithAdvisoryLock::DatabaseAdapterSupport` one-trick pony.
- Builds were failing on Travis, so I introduced a global lock prefix that can be set with the
  `WITH_ADVISORY_LOCK_PREFIX` environment variable. I'm not going to advertise this feature yet.
  It's a secret. Only you and I know, now. _shhh_

### 0.0.8

- Addressed [issue 5](https://github.com/ClosureTree/with_advisory_lock/issues/5) by
  using a deterministic hash for Postgresql + MRI >= 1.9.
  Thanks for the pull request, [Joel Turkel](https://github.com/jturkel)!
- Addressed [issue 2](https://github.com/ClosureTree/with_advisory_lock/issues/2) by
  using a cache-busting query for MySQL and Postgres to deal with AR value caching bug.
  Thanks for the pull request, [Jaime Giraldo](https://github.com/sposmen)!
- Addressed [issue 4](https://github.com/ClosureTree/with_advisory_lock/issues/4) by
  adding support for `em-postgresql-adapter`.
  Thanks, [lestercsp](https://github.com/lestercsp)!

(Hey, github—your notifications are WAY too easy to ignore!)

### 0.0.7

- Added Travis tests for Rails 3.0, 3.1, 3.2, and 4.0
- Fixed MySQL bug with select_value returning a string instead of an integer when using AR 3.0.x

### 0.0.6

- Only require ActiveRecord >= 3.0.x
- Fixed MySQL error reporting

### 0.0.5

- Asking for the currently acquired advisory lock doesn't re-ask for the lock now.
- Introduced NestedAdvisoryLockError when asking for different, nested advisory locksMySQL

### 0.0.4

- Moved require into on_load, which should speed loading when AR doesn't have to spin up

### 0.0.3

- Fought with ActiveRecord 3.0.x and 3.1.x. You don't want them if you use threads—they fail
  predictably.

### 0.0.2

- Added warning log message for nested MySQL lock calls
- Randomized lock wait time, which can help ameliorate lock contention

### 0.0.1

- First whack
