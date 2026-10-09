SHELL := /usr/bin/env bash

.PHONY: help build validate test-static test-contract test-local-all test-coverage \
	smoke up down dev-up dev-down logs bom test-logs-clean test-clean-all \
	docs-build docs-serve docs-up docs-down docs-clean

IMAGE ?= productive-k3s-console:dev
AUTH_MODE ?= oidc

ifeq ($(AUTH_MODE),oidc)
DEFAULT_COMPOSE_ENV := .env
COMPOSE_FILES := -f docker-compose.yml
COMPOSE_SERVICES :=
else ifeq ($(AUTH_MODE),disabled)
DEFAULT_COMPOSE_ENV := .env.example
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_SERVICES := console
else
$(error AUTH_MODE must be 'oidc' or 'disabled', got '$(AUTH_MODE)')
endif

COMPOSE_ENV ?= $(DEFAULT_COMPOSE_ENV)
COMPOSE := docker compose --env-file "$(COMPOSE_ENV)" $(COMPOSE_FILES)

help:
	@printf '%s\n' \
		'Productive K3S Console' \
		'' \
		'Targets:' \
		'  make build           Build the locked Console image' \
		'  make validate        Validate Compose, materials, and repository contracts' \
		'  make test-local-all  Run all non-live local checks' \
		'  make test-coverage   Enforce shell test coverage threshold' \
		'  make smoke           Build and run the explicit container smoke test' \
		'  make docs-build      Build the documentation with strict checks' \
		'  make docs-up         Start the tracked docs server in background' \
		'  make docs-down       Stop and clean the tracked docs server' \
		'  make up              Start authenticated Console using .env' \
		'  make up AUTH_MODE=disabled  Start localhost-only Console without OIDC' \
		'  make down [AUTH_MODE=disabled]  Stop the selected Compose mode' \
		'  make dev-up          Alias for make up AUTH_MODE=disabled' \
		'  make dev-down        Alias for make down AUTH_MODE=disabled' \
		'  make test-logs-clean Remove repository-local test output'

build:
	IMAGE="$(IMAGE)" bash scripts/build.sh

validate:
	bash scripts/validate.sh

test-static:
	bash tests/test-static.sh

test-contract:
	bash tests/test-contract.sh

test-local-all:
	bash tests/run-local-all.sh

test-coverage:
	bash tests/test-coverage.sh

smoke:
	IMAGE="$(IMAGE)" bash scripts/smoke.sh

up:
	$(COMPOSE) up -d --build $(COMPOSE_SERVICES)

down:
	$(COMPOSE) down

dev-up:
	$(MAKE) up AUTH_MODE=disabled COMPOSE_ENV=.env.example

dev-down:
	$(MAKE) down AUTH_MODE=disabled COMPOSE_ENV=.env.example

logs:
	$(COMPOSE) logs -f $(COMPOSE_SERVICES)

bom:
	bash scripts/render-bom.sh

test-logs-clean:
	bash scripts/clean.sh --logs-only

test-clean-all:
	bash scripts/clean.sh

docs-build:
	$(MAKE) -C docs docs-build

docs-serve:
	$(MAKE) -C docs docs-serve

docs-up:
	$(MAKE) -C docs docs-up

docs-down:
	$(MAKE) -C docs docs-down

docs-clean:
	$(MAKE) -C docs docs-clean
