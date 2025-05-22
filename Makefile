.PHONY: test

test:
	docker compose up -d
	sleep 10 # give some time for the service to start
	DATABASE_URL_PG=postgres://with_advisory:with_advisory_pass@localhost/with_advisory_lock_test bundle exec rake test
	DATABASE_URL_MYSQL=mysql2://with_advisory:with_advisory_pass@0.0.0.0:3306/with_advisory_lock_test bundle exec rake test
