.PHONY: test

test:
	docker compose up -d
	sleep 2
	bundle
	DATABASE_URL_PG=postgres://with_advisory:with_advisory_pass@localhost:5433/with_advisory_lock_test DATABASE_URL_MYSQL=mysql2://with_advisory:with_advisory_pass@0.0.0.0:3366/with_advisory_lock_test bin/rails test
