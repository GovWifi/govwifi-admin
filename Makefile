DOCKER_COMPOSE = docker compose -f docker-compose.yml
BUNDLE_FLAGS=

ifdef DEPLOYMENT
  BUNDLE_FLAGS = --without test development
endif

DOCKER_COMPOSE += -f docker-compose.development.yml
DOCKER_COMPOSE_NO2FA = $(DOCKER_COMPOSE) -f docker-compose-no2fa.yml


DOCKER_BUILD_CMD = BUNDLE_INSTALL_FLAGS="$(BUNDLE_FLAGS)" $(DOCKER_COMPOSE) build

build:
	$(DOCKER_COMPOSE) build

prebuild:
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up --no-start

database:
	$(DOCKER_COMPOSE) run --rm app ./bin/rails db:create db:schema:load db:migrate db:seed

serve: stop database build
	$(DOCKER_COMPOSE) up -d app

serve-no2fa: stop database build
	$(DOCKER_COMPOSE_NO2FA) up -d app

lint: lint-ruby lint-erb lint-scss lint-prettier
lint-ruby: build
	$(DOCKER_COMPOSE) run  --no-deps --rm app bundle exec rubocop
lint-erb: build
	$(DOCKER_COMPOSE) run  --no-deps --rm app bundle exec erb_lint --lint-all
lint-scss: build
	$(DOCKER_COMPOSE) run  --no-deps --rm app node ./node_modules/stylelint/bin/stylelint.mjs "**/*.scss"
lint-prettier: build
	$(DOCKER_COMPOSE) run  --no-deps --rm app node ./node_modules/prettier/bin/prettier.cjs --check "**/*.{json,md,scss,yaml,yml}"

autocorrect: autocorrect-erb
autocorrect-erb: build
	$(DOCKER_COMPOSE) run --rm --no-deps app bundle exec erb_lint --lint-all --autocorrect

test: stop build prebuilt-test

prebuilt-test:
	$(DOCKER_COMPOSE) run -e RACK_ENV=test --rm app ./bin/rails db:create db:schema:load
	$(DOCKER_COMPOSE) run -e RACK_ENV=test -e COVERAGE=true --rm app bundle exec rspec

shell: serve
	$(DOCKER_COMPOSE) exec app bash

stop:
	$(DOCKER_COMPOSE) down -v
	$(DOCKER_COMPOSE) rm -fsv

.PHONY: build lint serve shell stop test

vsctest:
	RACK_ENV=test ./bin/rails db:drop db:create db:schema:load
	bundle exec rspec

vscrefreshdb:
	./bin/rails db:drop db:create db:schema:load db:seed

vscdbg:
	BYPASS_2FA=true bundle exec rdbg -n --open=vscode -c -- bin/rails s -b 0.0.0.0

vscdbg-mfa:
	bundle exec rdbg -n --open=vscode -c -- bin/rails s -b 0.0.0.0

vscrubylint:
	bundle exec rubocop

vsclint: vscrubylint vscprettier
	bundle exec erblint --lint-all
	node ./node_modules/stylelint/bin/stylelint.mjs "**/*.scss"

vscprettier:
	node ./node_modules/prettier/bin/prettier.cjs --check "**/*.{json,md,scss,yaml,yml}"

vscprettier-write:
	node ./node_modules/prettier/bin/prettier.cjs --write "**/*.{json,md,scss,yaml,yml}"
