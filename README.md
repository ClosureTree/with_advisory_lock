# with_advisory_lock

Adds advisory locking (mutexes) to ActiveRecord 7.2+, with ruby 3.3+, jruby or truffleruby, when used with
[MySQL](https://dev.mysql.com/doc/refman/8.0/en/miscellaneous-functions.html#function_get-lock)
or
[PostgreSQL](https://www.postgresql.org/docs/current/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS).

**Note:** SQLite support has been removed. For single-node SQLite deployments,
consider using a Ruby mutex instead. Support for MySQL 5.7 has also been
dropped; please use MySQL 8 or PostgreSQL.

[![Gem Version](https://badge.fury.io/rb/with_advisory_lock.svg)](https://badge.fury.io/rb/with_advisory_lock)
[![CI](https://github.com/ClosureTree/with_advisory_lock/actions/workflows/ci.yml/badge.svg)](https://github.com/ClosureTree/with_advisory_lock/actions/workflows/ci.yml)

## What's an "Advisory Lock"?

An advisory lock is a [mutex](https://en.wikipedia.org/wiki/Mutual_exclusion)
used to ensure no two processes run some process at the same time. When the
advisory lock is powered by your database server,
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

> **Note**
> 
> If a non-nil value is provided for `timeout_seconds`, the block will
*not* be invoked if the lock cannot be acquired within that time-frame. In this case, `with_advisory_lock` will return `false`, while `with_advisory_lock!` will raise a `WithAdvisoryLock::FailedToAcquireLock` error.

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

`with_advisory_lock!` is similar to `with_advisory_lock`, but raises a `WithAdvisoryLock::FailedToAcquireLock` error if the lock was not able to be acquired in time. 

### Testing for the current lock status

If you needed to check if the advisory lock is currently being held, you can
call `Tag.advisory_lock_exists?("foo")`, but realize the lock can be acquired
between the time you test for the lock, and the time you try to acquire the
lock.

If you want to see if the current Thread is holding a lock, you can call
`Tag.current_advisory_lock` which will return the name of the current lock. If
no lock is currently held, `.current_advisory_lock` returns `nil`.

### ActiveRecord Query Cache

You can optionally pass `disable_query_cache: true` to the options hash of
`with_advisory_lock` in order to disable ActiveRecord's query cache. This can
prevent problems when you query the database from within the lock and it returns
stale results. More info on why this can be a problem can be
[found here](https://github.com/ClosureTree/with_advisory_lock/issues/52)

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
application, this will be 2.4, 2.5 and your most commonly used lock.**

### Table-level locks

Provided through something like the
[monogamy](https://github.com/ClosureTree/monogamy) gem, these prevent
concurrent access to **any instance of a model**. Their coarseness means they
aren't going to be commonly applicable, and they can be a source of
[deadlocks](http://en.wikipedia.org/wiki/Deadlock).

## Running Tests

To setup the project and run the whole test suite:

1. Have Docker running
2. `echo -e "DB_USER=with_advisory\nDB_PASSWORD=with_advisory_pass\nDB_NAME=with_advisory_lock_test\nDATABASE_URL_PG=postgres://\$DB_USER:\$DB_PASSWORD@localhost:5433/\$DB_NAME\nDATABASE_URL_MYSQL=mysql2://\$DB_USER:\$DB_PASSWORD@127.0.0.1:3366/\$DB_NAME" > .env`
3. `make`

Alternatively to `make`, run `bin/rails test` to skip database and dependency setup.

## FAQ

### Transactions and Advisory Locks

Advisory locks with MySQL and PostgreSQL ignore database transaction boundaries.

You will want to wrap your block within a transaction to ensure consistency.

### Is clustered MySQL supported?

[No.](https://github.com/ClosureTree/with_advisory_lock/issues/16)

