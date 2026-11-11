DOCKER_COMPOSE = docker compose -f docker-compose.yml
BUNDLE_FLAGS=

ifdef DEPLOYMENT
  BUNDLE_FLAGS = --without test development
endif

DOCKER_COMPOSE += -f docker-compose.development.yml
DOCKER_COMPOSE_NO2FA = $(DOCKER_COMPOSE) -f docker-compose-no2fa.yml

.DEFAULT_GOAL := help

.PHONY: build database serve serve-no2fa shell test prebuilt-test test-parallel test-parallel-setup lint autocorrect autocorrect-erb autocorrect-ruby local-yarn-update stop help

help:
	@echo "Available targets:"
	@echo ""
	@echo "  build               Build Docker image"
	@echo "  database            Setup database (create, migrate, seed)"
	@echo "  prebuilt-test       Run test suite with test database"
	@echo "  test-parallel      Run test suite in parallel"
	@echo "  test-parallel-setup Setup parallel test databases"
	@echo "  serve               Start development server"
	@echo "  serve-no2fa         Start development server without 2FA"
	@echo "  shell               Open shell in running container"
	@echo "  test                Run test suite"
	@echo "  lint                Run all linters (check only)"
	@echo "  autocorrect         Fix Ruby and ERB formatting issues"
	@echo "  autocorrect-erb     Fix ERB formatting issues (explicit)"
	@echo "  autocorrect-ruby    Fix Ruby formatting issues (explicit)"
	@echo "  local-yarn-update   Update yarn dependencies"
	@echo "  stop                Stop and remove all containers"
	@echo "  help                Show this help message"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Examples:"
	@echo "  make test            Run tests"
	@echo "  make test-parallel   Run tests in parallel"
	@echo "  make lint            Run linters"
	@echo "  make serve           Start development server"
	@echo "  make database        Setup database"
	@echo "  make stop            Stop all containers"
	@echo ""

stop:
	$(DOCKER_COMPOSE) down -v
	$(DOCKER_COMPOSE) rm -fsv

database:
	$(DOCKER_COMPOSE) run --rm app ./bin/rails db:create db:schema:load db:migrate db:seed

build:
	$(DOCKER_COMPOSE) build

serve: stop database build
	$(DOCKER_COMPOSE) up -d app

serve-no2fa: stop database build
	$(DOCKER_COMPOSE_NO2FA) up -d app

shell: serve
	$(DOCKER_COMPOSE) exec app bash

test: stop build test-parallel-setup test-parallel

test-parallel:
	$(DOCKER_COMPOSE) exec app sh -c 'RACK_ENV=test RUBYLIB=spec bundle exec parallel_rspec spec/'

# test-parallel-setup
#
# `parallel:create` builds one test DB per *container* CPU, so the schema-load
# loops must use the same count. N_WORKERS is derived from the container (has
# `nproc` on both Linux and macOS); the host fallback only runs if that fails.
test-parallel-setup:
	$(DOCKER_COMPOSE) up -d
	@N_WORKERS=$$(docker compose -f docker-compose.yml -f docker-compose.development.yml exec app sh -c 'nproc' 2>/dev/null); \
	[ -n "$$N_WORKERS" ] || N_WORKERS=$$(sysctl -n hw.physicalcpu 2>/dev/null || nproc 2>/dev/null); \
	[ -n "$$N_WORKERS" ] || N_WORKERS=9; \
	echo ">> test-parallel-setup: aligned workers = $$N_WORKERS"; \
	$(DOCKER_COMPOSE) exec app sh -c "RACK_ENV=test PARALLEL_WORKERS=$$N_WORKERS bundle exec rake parallel:drop"; \
	$(DOCKER_COMPOSE) exec app sh -c "RACK_ENV=test PARALLEL_WORKERS=$$N_WORKERS bundle exec rake parallel:create"; \
	$(DOCKER_COMPOSE) exec app sh -c "export RACK_ENV=test; export N_WORKERS=$$N_WORKERS; for i in \$$(seq 1 \$$N_WORKERS); do ( [ \$$i -eq 1 ] && ./bin/rails db:schema:load || TEST_ENV_NUMBER=\$$i ./bin/rails db:schema:load ) & done; wait"; \
	$(DOCKER_COMPOSE) exec wifi_user_db sh -c "export MYSQL_PWD=root; export N_WORKERS=$$N_WORKERS; for i in \$$(seq 1 \$$N_WORKERS); do ( DB=wifi_user_govwifi; [ \$$i -gt 1 ] && DB=wifi_user_govwifi\$$i; mysql -u root -e \"DROP DATABASE IF EXISTS \$$DB; CREATE DATABASE \$$DB;\"; mysql -u root \$$DB < /docker-entrypoint-initdb.d/wifi_user_schema.sql ) & done; wait"

prebuilt-test:
	$(DOCKER_COMPOSE) run -e RACK_ENV=test --rm app ./bin/rails db:create db:schema:load
	$(DOCKER_COMPOSE) run -e RACK_ENV=test -e COVERAGE=true --rm app bundle exec rspec --format documentation

lint: build
	$(DOCKER_COMPOSE) run --no-deps --rm app bundle exec rubocop && \
	$(DOCKER_COMPOSE) run --no-deps --rm app bundle exec erb_lint --lint-all && \
	$(DOCKER_COMPOSE) run --no-deps --rm app node ./node_modules/stylelint/bin/stylelint.mjs "**/*.scss" && \
	$(DOCKER_COMPOSE) run --no-deps --rm app node ./node_modules/prettier/bin/prettier.cjs --check "**/*.{json,md,scss,yaml,yml}"

autocorrect: autocorrect-ruby autocorrect-erb

autocorrect-ruby: build
	$(DOCKER_COMPOSE) run --rm --no-deps app bundle exec rubocop --autocorrect

autocorrect-erb: build
	$(DOCKER_COMPOSE) run --rm --no-deps app bundle exec erb_lint --lint-all --autocorrect

local-yarn-update:
	rm -rf node_modules
	rm yarn.lock
	yarn install
