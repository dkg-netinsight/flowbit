# Build output knobs (override via env/CLI).
EXTENSION     ?= 
DIST_DIR      ?= dist/
GOOS          ?= linux
GOARCH        ?= $(shell go env GOARCH)
BUILDINFOSDET ?= 

NAME          := flowbit
DOCKER_IMAGE  ?= ghcr.io/dkg-netinsight/$(NAME)
VERSION       ?= $(shell git describe --abbrev --long HEAD)
ABBREV        ?= $(shell git rev-parse --short HEAD)
COMMIT        ?= $(shell git rev-parse HEAD)
TAG           ?= $(shell git describe --tags --abbrev=0 HEAD)
VERSION_PKG   ?= $(shell echo $(VERSION) | sed 's/^v//g')
LICENSE       := BSD-3-Clause
URL           := https://github.com/dkg-netinsight/flowbit
DESCRIPTION   := FlowBit: NETINSIGHT ingestor
DATE          :=  $(shell date +%FT%T%z)
BUILDINFOS    ?=  ($(DATE)$(BUILDINFOSDET))
LDFLAGS       ?= '-X main.version=$(VERSION) -X main.buildinfos=$(BUILDINFOS)'
MAINTAINER    := dimple9292.dkg@gmail.com
DOCKER_BIN    ?= docker
DOCKER_CMD    ?= buildx build
DOCKER_SUFFIX ?= 
DOCKER_IMAGE_PREFIXES ?= $(DOCKER_IMAGE)
DOCKER_TAGS ?= $(foreach image,$(DOCKER_IMAGE_PREFIXES),$(image):$(ABBREV)$(DOCKER_SUFFIX))
DOCKER_TAG_ARGS := $(foreach tag,$(DOCKER_TAGS),-t $(tag))
DOCKER_MANIFEST_TAG ?= $(ABBREV)

OUTPUT := $(DIST_DIR)flowbit-$(VERSION_PKG)-$(GOOS)-$(GOARCH)$(EXTENSION)

# fpm expects x86_64 for amd64, but use GOARCH otherwise.
FPM_ARCH ?= $(GOARCH)
ifeq ($(GOARCH),amd64)
FPM_ARCH = x86_64
endif

.PHONY: proto
# Generate Go protobuf bindings.
proto:
	@echo generating protobuf
	protoc --go_opt=paths=source_relative --go_out=. pb/*.proto
	protoc --go_opt=paths=source_relative --go_out=. cmd/enricher/pb/*.proto

.PHONY: vet
# Run Go static analysis on the main package.
vet:
	go vet cmd/flowbit/main.go

.PHONY: test
# Run Go test suite.
test:
	go test -v ./...

.PHONY: test-race
test-race:
	go test -race ./...

.PHONY: test-cover
test-cover:
	go test -cover ./...

.PHONY: staticcheck
staticcheck:
	staticcheck ./...

.PHONY: lint
lint:
	golangci-lint run

.PHONY: check
check: vet test lint staticcheck

.PHONY: prepare
# Ensure dist directory exists.
prepare:
	mkdir -p $(DIST_DIR)

.PHONY: clean
clean:
	rm -rf $(DIST_DIR)

.PHONY: build
# Build the flowbit binary.
build: prepare
	CGO_ENABLED=0 go build -trimpath -ldflags $(LDFLAGS) -o $(OUTPUT) cmd/flowbit/main.go

.PHONY: print-output
print-output:
	@echo $(OUTPUT)

.PHONY: docker
# Build docker image for the current version.
docker:
	$(DOCKER_BIN) $(DOCKER_CMD) \
        --build-arg LDFLAGS=$(LDFLAGS) \
        --build-arg CREATED="$(DATE)" \
        --build-arg MAINTAINER="$(MAINTAINER)" \
        --build-arg URL="$(URL)" \
        --build-arg NAME="$(NAME)" \
        --build-arg DESCRIPTION="$(DESCRIPTION)" \
        --build-arg LICENSE="$(LICENSE)" \
        --build-arg VERSION="$(VERSION)" \
        --build-arg REV="$(COMMIT)" \
        $(DOCKER_TAG_ARGS) .

.PHONY: push-docker
# Push docker image tagged with the current abbrev.
push-docker:
	@for tag in $(DOCKER_TAGS); do \
		$(DOCKER_BIN) push $$tag; \
	done

.PHONY: docker-manifest
# Create and push multi-arch manifest for abbrev and latest tags.
docker-manifest:
	$(DOCKER_BIN) buildx imagetools create \
	    -t $(DOCKER_IMAGE):$(DOCKER_MANIFEST_TAG) \
	    $(DOCKER_IMAGE):$(ABBREV)-amd64 \
	    $(DOCKER_IMAGE):$(ABBREV)-arm64

.PHONY: package-deb
package-deb: build
	$(call run_fpm,deb)

.PHONY: package-rpm
package-rpm: build
	$(call run_fpm,rpm)

.PHONY: package
package: package-deb package-rpm

FPM_COMMON_FLAGS := -s dir -n $(NAME) -v $(VERSION_PKG) \
	--maintainer "$(MAINTAINER)" \
	--description "$(DESCRIPTION)" \
	--url "$(URL)" \
	--architecture $(FPM_ARCH) \
	--license "$(LICENSE)" \
	--package $(DIST_DIR)
FPM_INPUTS := \
	$(OUTPUT)=/usr/sbin/flowbit \
	package/flowbit.service=/lib/systemd/system/flowbit.service \
	package/flowbit.env=/etc/default/flowbit

define run_fpm
	fpm -t $(1) $(FPM_COMMON_FLAGS) $(FPM_INPUTS)
endef
