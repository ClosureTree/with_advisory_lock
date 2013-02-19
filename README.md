# with_advisory_lock [![Build Status](https://api.travis-ci.org/mceachen/with_advisory_lock.png?branch=master)](https://travis-ci.org/mceachen/with_advisory_lock)

Adds advisory locking to ActiveRecord 3.2.x.
[MySQL](http://dev.mysql.com/doc/refman/5.0/en/miscellaneous-functions.html#function_get-lock)
and [PostgreSQL](http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS)
are supported natively. SQLite resorts to file locking (which won't span hosts, of course!).

## What's an "Advisory Lock"?

An advisory lock is a [mutex](http://en.wikipedia.org/wiki/Mutual_exclusion) used to ensure no two
processes run some process at the same time. When the advisory lock is powered by your database
server, as long as it isn't SQLite, your mutex spans hosts.

## Usage

Where ```User``` is an ActiveRecord model, and ```lock_name``` is some string:

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

The second parameter for ```with_advisory_lock``` is ```timeout_seconds```, and defaults to ```nil```,
which means wait indefinitely for the lock.

If a non-nil value is provided, the block may not be invoked.

The return value of ```with_advisory_lock``` will be the result of the yielded block,
if the lock was able to be acquired and the block yielded, or ```false```, if you provided
a timeout_seconds value and the lock was not able to be acquired in time.

### Transactions and Advisory Locks

Advisory locks with MySQL and PostgreSQL ignore database transaction boundaries.

You will want to wrap your block within a transaction to ensure consistency.

### MySQL doesn't support nesting

With MySQL (at least <= v5.5), if you ask for a *different* advisory lock within a ```with_advisory_lock``` block,
you will be releasing the parent lock (!!!). A ```NestedAdvisoryLockError```will be raised
in this case. If you ask for the same lock name, ```with_advisory_lock``` won't ask for the
lock again, and the block given will be yielded to.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'with_advisory_lock'
```

And then execute:

    $ bundle

## Lock Types

First off, know that there are **lots** of different kinds of locks available to you. **Pick the
finest-grain lock that ensures correctness.** If you choose a lock that is too coarse, you are
unnecessarily blocking other processes.

### Advisory locks
These are named mutexes that are inherently "application level"—it is up to the application
to acquire, run a critical code section, and release the advisory lock.

### Row-level locks
Whether [optimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html)
or [pessimistic](http://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html),
row-level locks prevent concurrent modification to a given model.

**If you're building a
[CRUD](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete) application, this will be your
most commonly used lock.**

### Table-level locks

Provided through something like the [monogamy](https://github.com/mceachen/monogamy)
gem, these prevent concurrent access to **any instance of a model**. Their coarseness means they
aren't going to be commonly applicable, and they can be a source of
[deadlocks](http://en.wikipedia.org/wiki/Deadlock).

## Changelog

### 0.0.6

* Only require ActiveRecord >= 3.0.x
* Fixed MySQL error reporting

### 0.0.5

* Asking for the currently acquired advisory lock doesn't re-ask for the lock now.
* Introduced NestedAdvisoryLockError when asking for different, nested advisory locksMySQL

### 0.0.4

* Moved require into on_load, which should speed loading when AR doesn't have to spin up

### 0.0.3

* Fought with ActiveRecord 3.0.x and 3.1.x. You don't want them if you use threads—they fail
  predictably.

### 0.0.2

* Added warning log message for nested MySQL lock calls
* Randomized lock wait time, which can help ameliorate lock contention

### 0.0.1

* First whack
