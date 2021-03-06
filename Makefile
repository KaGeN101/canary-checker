
default: build
NAME:=canary-checker

ifeq ($(TAG),)
TAG := $(shell git describe --tags --exclude "*-g*" )
endif

ifeq ($(VERSION),)
VERSION := v$(TAG) built $(shell date)
endif

.PHONY: setup
setup:
	which github-release 2>&1 > /dev/null || go get github.com/aktau/github-release

.PHONY: linux
linux:
	GOOS=linux go build -o ./.bin/$(NAME) -ldflags "-X \"main.version=$(VERSION)\""  main.go

.PHONY: darwin
darwin:
	GOOS=darwin go build -o ./.bin/$(NAME)_osx -ldflags "-X \"main.version=$(VERSION)\""  main.go

.PHONY: compress
compress:
	# upx 3.95 has issues compressing darwin binaries - https://github.com/upx/upx/issues/301
	which upx 2>&1 >  /dev/null  || (sudo apt-get update && sudo apt-get install -y xz-utils && wget -nv -O upx.tar.xz https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz; tar xf upx.tar.xz; mv upx-3.96-amd64_linux/upx /usr/bin )
	upx -5 ./.bin/$(NAME) ./.bin/$(NAME)_osx

.PHONY: install
install:
	cp ./.bin/$(NAME) /usr/local/bin/

.PHONY: image
image:
	docker build -t $(NAME) --build-arg VERSION="$(VERSION)" -f Dockerfile .

.PHONY: serve-docs
serve-docs:
	docker run --rm -it -p 8000:8000 -v $(PWD):/docs -w /docs squidfunk/mkdocs-material

.PHONY: build-api-docs
build-api-docs:
	go run main.go docs api  pkg/api.go  > docs/reference.md
	mkdir -p docs/cli
	go run main.go docs cli "docs/cli"

.PHONY: build-docs
build-docs:
	which mkdocs 2>&1 > /dev/null || pip install mkdocs mkdocs-material
	mkdocs build -d build/docs

.PHONY: deploy-docs
deploy-docs:
	which netlify 2>&1 > /dev/null || sudo npm install -g netlify-cli
	netlify deploy --site cfe8c6b7-79b7-4a88-9e13-ff792126717f --prod --dir build/docs

