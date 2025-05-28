.PHONY: test

test: setup-db
	bin/rails test

setup-db:
	docker compose up -d
	sleep 2
	bundle
	bin/setup_test_db
