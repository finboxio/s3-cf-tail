SHELL := /bin/bash

DOCKER_USER=finboxio
DOCKER_IMAGE=s3-cf-tail

GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT := $(shell git rev-parse HEAD)
GIT_REPO := $(shell git remote -v | grep origin | grep "(fetch)" | awk '{ print $$2 }')
GIT_DIRTY := $(shell git status --porcelain | wc -l)
GIT_DIRTY := $(shell if [[ "$(GIT_DIRTY)" -gt "0" ]]; then echo "yes"; else echo "no"; fi)

VERSION := $(shell git describe --abbrev=0)
VERSION_DIRTY := $(shell git log --pretty=format:%h $(VERSION)..HEAD | wc -w | tr -d ' ')

BUILD_COMMIT := $(shell if [[ "$(GIT_DIRTY)" == "yes" ]]; then echo $(GIT_COMMIT)+dev; else echo $(GIT_COMMIT); fi)
BUILD_COMMIT := $(shell echo $(BUILD_COMMIT) | cut -c1-12)
BUILD_VERSION := $(shell if [[ "$(VERSION_DIRTY)" -gt "0" ]]; then echo "$(VERSION)-$(BUILD_COMMIT)"; else echo $(VERSION); fi)
BUILD_VERSION := $(shell if [[ "$(VERSION_DIRTY)" -gt "0" ]] || [[ "$(GIT_DIRTY)" == "yes" ]]; then echo "$(BUILD_VERSION)-dev"; else echo $(BUILD_VERSION); fi)
BUILD_VERSION := $(shell if [[ "$(GIT_BRANCH)" != "master" ]]; then echo $(GIT_BRANCH)-$(BUILD_VERSION) | tr '/' '-'; else echo $(BUILD_VERSION); fi)

DOCKER_IMAGE := $(shell if [[ "$(DOCKER_REGISTRY)" ]]; then echo $(DOCKER_REGISTRY)/$(DOCKER_USER)/$(DOCKER_IMAGE); else echo $(DOCKER_USER)/$(DOCKER_IMAGE); fi)
DOCKER_VERSION := $(shell echo "$(DOCKER_IMAGE):$(BUILD_VERSION)")
DOCKER_LATEST := $(shell if [[ "$(VERSION_DIRTY)" -gt "0" ]] || [[ "$(GIT_DIRTY)" == "yes" ]]; then echo "$(DOCKER_IMAGE):dev"; else echo $(DOCKER_IMAGE):latest; fi)

LOCAL_COMPOSE := $(shell [ -f "docker-compose.local.yml" ] && echo "-f docker-compose.local.yml")
COMPOSE_FILES := $(shell echo "-f docker-compose.yml -f docker-compose.test.yml $(LOCAL_COMPOSE)")

DOCKER_BUILD_ARGS := $(shell echo "--build-arg LR_NPM_TOKEN=${LR_NPM_TOKEN} --target=production")

info:
	@echo "git branch: 			$(GIT_BRANCH)"
	@echo "git commit:      $(GIT_COMMIT)"
	@echo "git repo:        $(GIT_REPO)"
	@echo "git dirty:       $(GIT_DIRTY)"
	@echo "version:         $(VERSION)"
	@echo "commits since:   $(VERSION_DIRTY)"
	@echo "build commit:    $(BUILD_COMMIT)"
	@echo "build version:   $(BUILD_VERSION)"
	@echo "docker images:   $(DOCKER_VERSION)"
	@echo "                 $(DOCKER_LATEST)"

docker.build:
	@docker build $(DOCKER_BUILD_ARGS) -t $(DOCKER_VERSION) -t $(DOCKER_LATEST) .

docker.push: docker.build
	@docker push $(DOCKER_VERSION)
	@docker push $(DOCKER_LATEST)