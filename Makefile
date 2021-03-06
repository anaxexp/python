-include env_make

PYTHON_VER ?= 3.7.0
PYTHON_VER_MINOR := $(shell echo "${PYTHON_VER}" | grep -oE '^[0-9]+\.[0-9]+')

REPO = anaxexp/python
NAME = python-$(PYTHON_VER_MINOR)

ANAXEXP_USER_ID ?= 1000
ANAXEXP_GROUP_ID ?= 1000

BASE_IMAGE_TAG = $(PYTHON_VER)

ifeq ($(TAG),)
    ifneq ($(PYTHON_DEBUG),)
        TAG ?= $(PYTHON_VER_MINOR)-debug
    else ifneq ($(PYTHON_DEV),)
    	TAG ?= $(PYTHON_VER_MINOR)-dev
    else
        TAG ?= $(PYTHON_VER_MINOR)
    endif
endif

ifneq ($(PYTHON_DEV),)
    NAME := $(NAME)-dev
endif

ifneq ($(PYTHON_DEBUG),)
    NAME := $(NAME)-debug
    BASE_IMAGE_TAG := $(BASE_IMAGE_TAG)-debug
    PYTHON_DEV := 1
endif

ifneq ($(STABILITY_TAG),)
    ifneq ($(TAG),latest)
        override TAG := $(TAG)-$(STABILITY_TAG)
    endif
endif

.PHONY: build test push shell run start stop logs clean release

default: build

build:
	docker build -t $(REPO):$(TAG) \
		--build-arg BASE_IMAGE_TAG=$(BASE_IMAGE_TAG) \
		--build-arg PYTHON_DEV=$(PYTHON_DEV) \
		--build-arg ANAXEXP_USER_ID=$(ANAXEXP_USER_ID) \
		--build-arg ANAXEXP_GROUP_ID=$(ANAXEXP_GROUP_ID) \
		./

test:
	cd ./tests && IMAGE=$(REPO):$(TAG) ./run.sh

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

release: build push
