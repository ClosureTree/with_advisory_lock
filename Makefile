.PHONY: test-pg test-mysql

test-pg:
	docker compose up -d pg
	sleep 10 # give some time for the service to start
	DATABASE_URL=postgres://with_advisory:with_advisory_pass@localhost/with_advisory_lock_test appraisal rake test

test-mysql:
	docker compose up -d mysql
	sleep 10 # give some time for the service to start
	DATABASE_URL=mysql2://with_advisory:with_advisory_pass@0.0.0.0:3306/with_advisory_lock_test appraisal rake test


test: test-pg test-mysql
