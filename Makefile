SHELL := /bin/bash
MAX_LINE_LENGTH := 119
POETRY_VERSION := $(shell poetry --version 2>/dev/null)

help: ## List all commands
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9 -_]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check-poetry:
	@if [[ "${POETRY_VERSION}" == *"Poetry"* ]] ; \
	then \
		echo "Found ${POETRY_VERSION}, ok." ; \
	else \
		echo 'Please install poetry first, with e.g.:' ; \
		echo 'make install-poetry' ; \
		exit 1 ; \
	fi

install-poetry: ## install or update poetry via pip
	pip3 install -U poetry

install: check-poetry ## install via poetry
	poetry install

update: check-poetry ## Update the dependencies as according to the pyproject.toml file
	poetry update

lint: ## Run code formatters and linter
	poetry run flynt --fail-on-change --line-length=${MAX_LINE_LENGTH} huey_monitor huey_monitor_tests
	poetry run isort --check-only .
	poetry run flake8 huey_monitor huey_monitor_tests

fix-code-style: ## Fix code formatting
	poetry run flynt --line_length=${MAX_LINE_LENGTH} huey_monitor huey_monitor_tests
	poetry run autopep8 --aggressive --aggressive --in-place --recursive huey_monitor huey_monitor_tests
	poetry run isort .

tox-listenvs: check-poetry ## List all tox test environments
	poetry run tox --listenvs

tox: check-poetry ## Run pytest via tox with all environments
	poetry run tox

pytest: check-poetry ## Run pytest
	poetry run pytest

pytest-ci: check-poetry ## Run pytest with CI settings
	poetry run pytest -c pytest-ci.ini

publish: ## Release new version to PyPi
	poetry run publish

makemessages: ## Make and compile locales message files
	./manage.sh makemessages --all --no-location --no-obsolete --ignore=htmlcov --ignore=".tox*" --ignore=volumes
	./manage.sh compilemessages --ignore=htmlcov --ignore=".tox*" --ignore=volumes

clean: ## Remove created files from the test project (e.g.: SQlite, static files)
	git clean -dfX huey_monitor_tests_tests/

###################################################################################################
# docker

build: ## Update/Build docker services
	$(MAKE) update
	./compose.sh pull
	./compose.sh build --pull

up: build ## Start docker containers
	./compose.sh up -d
	$(MAKE) logs

down: ## Stop all containers
	./compose.sh down

shell_django: ## go into a interactive bash shell in Django container
	./compose.sh exec django /bin/bash

shell_huey1: ## go into a interactive bash shell in Huey worker container 1
	./compose.sh exec huey1 /bin/bash

shell_huey2:  ## go into a interactive bash shell in Huey worker container 2
	./compose.sh exec huey2 /bin/bash

shell_huey3:  ## go into a interactive bash shell in Huey worker container 3
	./compose.sh exec huey3 /bin/bash

logs: ## Display and follow docker logs
	./compose.sh logs --tail=500 --follow

reload_django: ## Reload the Django dev server
	./compose.sh exec django /django/docker/utils/kill_python.sh
	./compose.sh logs --tail=500 --follow django

reload_huey: ## Reload the Huey worker
	./compose.sh exec huey1 /django/docker/utils/kill_python.sh
	./compose.sh exec huey2 /django/docker/utils/kill_python.sh
	./compose.sh exec huey3 /django/docker/utils/kill_python.sh
	./compose.sh logs --tail=500 --follow huey1 huey2 huey3

restart: down up  ## Restart the containers

fire_test_tasks:  ## Call "fire_test_tasks" manage command to create some Huey Tasks
	./compose.sh exec django /django/manage.sh fire_test_tasks

fire_parallel_processing_task:  ## Just fire "parallel processing" Huey Task
	./compose.sh exec django /django/manage.sh fire_parallel_processing_task

delete_all_tasks_data:  ## Delete all Task/Signal database enties
	./compose.sh exec django /django/manage.sh delete_all_tasks_data

.PHONY: help install lint fix pytest publish