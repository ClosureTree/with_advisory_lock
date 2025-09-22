## Changelog

## [7.0.2](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v7.0.1...with_advisory_lock/v7.0.2) (2025-09-20)


### Bug Fixes

* Replace connection.select_value with connection.query_value ([#131](https://github.com/ClosureTree/with_advisory_lock/issues/131)) ([dc01977](https://github.com/ClosureTree/with_advisory_lock/commit/dc01977e5e3a120843b19a5e6befd538c6e36516))

## [7.0.1](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v7.0.0...with_advisory_lock/v7.0.1) (2025-07-21)


### Bug Fixes

* handle ActiveRecord's release_advisory_lock signature for Rails 7.2+ ([#127](https://github.com/ClosureTree/with_advisory_lock/issues/127)) ([94253ca](https://github.com/ClosureTree/with_advisory_lock/commit/94253ca2af7f684a3c99645765853546c3da8e02)), closes [#126](https://github.com/ClosureTree/with_advisory_lock/issues/126)

## [7.0.0](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v6.0.0...with_advisory_lock/v7.0.0) (2025-07-05)


### ⚠ BREAKING CHANGES

* require Rails 7.2+ as minimum version

### Features

* fire Ruby from its second job checking locks and let PostgreSQL do what it's paid for ([#124](https://github.com/ClosureTree/with_advisory_lock/issues/124)) ([f7f8dbc](https://github.com/ClosureTree/with_advisory_lock/commit/f7f8dbcd69842a358d0d70227bcc52ba3183c098))
* handle connection disconnection gracefully ([1944e98](https://github.com/ClosureTree/with_advisory_lock/commit/1944e98877917e234bfe597f9358c0b74643a045))
* handle connection disconnection gracefully ([77046a9](https://github.com/ClosureTree/with_advisory_lock/commit/77046a94c7504f77a59fae6fbcd75e73ed41bf23))
* implement MySQL native timeout support ([#123](https://github.com/ClosureTree/with_advisory_lock/issues/123)) ([387dedd](https://github.com/ClosureTree/with_advisory_lock/commit/387dedd133c897f7a3da13ed2ebbd9223b81317d))
* require Rails 7.2+ as minimum version ([d4e7826](https://github.com/ClosureTree/with_advisory_lock/commit/d4e7826ddc216c103cd666674068cb7f512fc32d))
* validate transaction-level locks require active transaction ([#122](https://github.com/ClosureTree/with_advisory_lock/issues/122)) ([e4bc6c1](https://github.com/ClosureTree/with_advisory_lock/commit/e4bc6c10666e02c560f18629df0106c39bb85e19))

## [6.0.0](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v5.3.0...with_advisory_lock/v6.0.0) (2025-05-28)


### ⚠ BREAKING CHANGES

* Remove private APIs (Base, DatabaseAdapterSupport). Add full mixed adapter support for PostgreSQL/MySQL in same app. Add JRuby compatibility.
* drop support for sqlite3
* drop legacy version of ruby/rails ([#113](https://github.com/ClosureTree/with_advisory_lock/issues/113))

### Features

* drop legacy version of ruby/rails ([#113](https://github.com/ClosureTree/with_advisory_lock/issues/113)) ([26fd427](https://github.com/ClosureTree/with_advisory_lock/commit/26fd4278f9fa155974e6f86df7cd92dd2b7d9154))
* drop support for sqlite3 ([26fd427](https://github.com/ClosureTree/with_advisory_lock/commit/26fd4278f9fa155974e6f86df7cd92dd2b7d9154))
* move to rails dummy app to test multidb setup ([#115](https://github.com/ClosureTree/with_advisory_lock/issues/115)) ([71a3431](https://github.com/ClosureTree/with_advisory_lock/commit/71a34316b365a0f3be0e8a046db14289e69efc9c))
* support of multidb  ([#116](https://github.com/ClosureTree/with_advisory_lock/issues/116)) ([935e7e5](https://github.com/ClosureTree/with_advisory_lock/commit/935e7e5fb05dad2eba034745d2ef49e11c163f7d))

## [5.3.0](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v5.2.0...with_advisory_lock/v5.3.0) (2025-04-25)


### Features

* add #current_advisory_locks method ([#111](https://github.com/ClosureTree/with_advisory_lock/issues/111)) ([ccbd3b2](https://github.com/ClosureTree/with_advisory_lock/commit/ccbd3b23465f7fa1fc3800334159986c31d5c351))

## [5.2.0](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v5.1.0...with_advisory_lock/v5.2.0) (2025-04-24)


### Features

* use current connnection instead of the one in ActiveRecord::Base ([#90](https://github.com/ClosureTree/with_advisory_lock/issues/90)) ([c28a172](https://github.com/ClosureTree/with_advisory_lock/commit/c28a172a5a64594448b6090501fc0b8cbace06f6))


### Bug Fixes

* Removed MySQL unused lock variable and broaden SQLite detection. ([#94](https://github.com/ClosureTree/with_advisory_lock/issues/94)) ([f818a18](https://github.com/ClosureTree/with_advisory_lock/commit/f818a181dde6711c8439c4cbf67c4525a09d346e))

## [5.1.0](https://github.com/ClosureTree/with_advisory_lock/compare/with_advisory_lock/v5.0.1...with_advisory_lock/v5.1.0) (2024-01-21)


### Features

* use zeitwerk loader instead of ActiveSupport::Autoload ([b5082fd](https://github.com/ClosureTree/with_advisory_lock/commit/b5082fddacacacff48139f5bf509601a37945a0e))

## 5.0.1 (2024-01-21)


### Features

* add release workflow ([5d32520](https://github.com/ClosureTree/with_advisory_lock/commit/5d325201c82974991381a9fbc4d1714c9739dc4f))
* add ruby 3.1 test/support ([#60](https://github.com/ClosureTree/with_advisory_lock/issues/60)) ([514f042](https://github.com/ClosureTree/with_advisory_lock/commit/514f0420d957ef30911a00d54685385bec5867c3))
* Add testing for activerecord 7.1 and support for trilogy adapter ([#77](https://github.com/ClosureTree/with_advisory_lock/issues/77)) ([69c23fe](https://github.com/ClosureTree/with_advisory_lock/commit/69c23fe09887fc5d97ac7b0194825c21efe244a5))
* add truffleruby support ([#62](https://github.com/ClosureTree/with_advisory_lock/issues/62)) ([ec34bd4](https://github.com/ClosureTree/with_advisory_lock/commit/ec34bd448e3505e5df631daaf47bb83f2f5316dc))


### Bug Fixes

* User may sometimes pass in non-strings, such as integers ([#55](https://github.com/ClosureTree/with_advisory_lock/issues/55)) ([9885597](https://github.com/ClosureTree/with_advisory_lock/commit/988559747363ef00958fcf782317e76c40ffa2a3))

### 5.0.0
- Drop support for EOL rubies and activerecord (ruby below 2.7 and activerecord below 6.1).
- Allow lock name to be integer
- Jruby support
- Truffleruby support
- Add `with_advisory_lock!`, which raises an error if the lock acquisition fails
- Add `disable_query_cache` option to `with_advisory_lock`
- Drop support for mysql < 5.7.5

### 4.6.0

- Support for ActiveRecord 6
- Add Support for nested locks in MySQL

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
