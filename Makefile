BUNDLE_FLAGS = --build-arg BUNDLE_INSTALL_CMD='bundle install --jobs 20 --retry 5'
DOCKER_COMPOSE = docker-compose -f docker-compose.yml

ifdef DEPLOYMENT
	BUNDLE_FLAGS = --build-arg BUNDLE_INSTALL_CMD='bundle install --without test'
endif

ifndef JENKINS_URL
  DOCKER_COMPOSE += -f docker-compose.development.yml
endif

DOCKER_BUILD_CMD = $(DOCKER_COMPOSE) build $(BUNDLE_FLAGS)

build:
	$(MAKE) stop
	$(DOCKER_BUILD_CMD)

serve: build
	$(DOCKER_COMPOSE) up -d govuk-fake-registers db rr_db
	./mysql/bin/wait_for_mysql
	./mysql/bin/wait_for_rr_db
	$(DOCKER_COMPOSE) run --rm app ./bin/rails db:create db:schema:load db:seed
	$(DOCKER_COMPOSE) up -d app

lint:
	$(MAKE) build
	$(DOCKER_COMPOSE) run --rm app bundle exec govuk-lint-ruby app lib spec Gemfile*

test:
	$(MAKE) build
	$(DOCKER_COMPOSE) up -d db rr_db
	./mysql/bin/wait_for_mysql
	./mysql/bin/wait_for_rr_db
	$(DOCKER_COMPOSE) run -e RACK_ENV=test --rm app ./bin/rails db:create db:schema:load db:migrate
	$(DOCKER_COMPOSE) run --rm app bundle exec rspec

shell: serve
	$(DOCKER_COMPOSE) exec app bash

stop:
	$(DOCKER_COMPOSE) down -v

.PHONY: build lint serve shell stop test
