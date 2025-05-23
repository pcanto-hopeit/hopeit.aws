SRC = $(wildcard src/*.py)

.PHONY: dev clean-env clean-plugins update-examples-api test-plugins lint-plugins format-plugins test-apps check-apps format-apps test lint dist-plugin publish-plugin-pypi publish-plugin-pypi-test


env:
	uv venv --seed --python 3.12
	uv sync --dev

clean-env:
	rm -rf .venv
	rm -rf .pytest_cache
	rm -rf .ruff_cache
	rm uv.lock

dev: env
	uv pip install -r pyproject.toml	
	uv pip install -U --no-deps -e ./plugins/aws/s3	

ci-deps:
	uv venv --seed --python $(PYTHONVERSION)
	uv sync --dev
	uv pip install -r pyproject.toml

format-module:
	uv  run --no-sync ruff format $(MODULEFOLDER)/src/ $(MODULEFOLDER)/test/
	uv  run --no-sync ruff check $(MODULEFOLDER)/src/ $(MODULEFOLDER)/test/ --fix

format:
	make MODULEFOLDER=apps/examples/aws-example format-module
	make MODULEFOLDER=plugins/aws/s3 format-module

lint-plugin:
	uv  run --no-sync ruff format --check $(PLUGINFOLDER)src/ $(PLUGINFOLDER)test/
	uv  run --no-sync ruff check $(PLUGINFOLDER)src/ $(PLUGINFOLDER)test/
	MYPYPATH=$(PLUGINFOLDER)src/ uv  run --no-sync mypy --namespace-packages -p hopeit
	MYPYPATH=$(PLUGINFOLDER)src:$(PLUGINFOLDER)test uv  run --no-sync mypy --namespace-packages $(PLUGINFOLDER)test

lint-plugins:		
	make PLUGINFOLDER=plugins/aws/s3/ lint-plugin

lint-app:
	uv  run --no-sync ruff format $(APPFOLDER)/src/ $(APPFOLDER)/test/ --check
	uv  run --no-sync ruff check $(APPFOLDER)/src/ $(APPFOLDER)/test/
	MYPYPATH=$(APPFOLDER)/src/ uv  run --no-sync mypy -p ${PACKAGE}

lint-apps:
	make APPFOLDER=apps/examples/aws-example PACKAGE=aws_example lint-app
	
lint: lint-plugins lint-apps

test-plugin:
	PYTHONPATH=$(PLUGINFOLDER)src uv  run --no-sync pytest -v --cov --cov-fail-under=85 --cov-report=term $(PLUGINFOLDER)src/ $(PLUGINFOLDER)test/

test-plugins:
	make PLUGINFOLDER=plugins/aws/s3/ test-plugin

test-app:
	PYTHONPATH=$(APPFOLDER)/src/ && uv  run --no-sync pytest -v --cov --cov-fail-under=90 --cov-report=term $(APPFOLDER)/src/ $(APPFOLDER)/test/

test-apps:
	make APPFOLDER=apps/examples/aws-example test-app

test: test-plugins test-apps

update-examples-api:
	bash apps/examples/aws-example/api/create_openapi_file.sh

dist-plugin: clean-dist-plugin
	uv --project=$(PLUGINFOLDER) build

clean-dist-plugin:
	rm -rf $(PLUGINFOLDER)dist

publish-plugin-pypi:
	uv publish -u=__token__ -p=$(PYPI_API_TOKEN) $(PLUGINFOLDER)dist/*

publish-plugin-pypi-test:
	uv publish -u=__token__ -p=$(TEST_PYPI_API_TOKEN) --publish-url=https://test.pypi.org/legacy/ $(PLUGINFOLDER)dist/*
