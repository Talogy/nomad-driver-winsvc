BINARY_NAME ?= winsvc-driver.exe
DIST_DIR    ?= dist
GO          ?= go
CGO_ENABLED ?= 0

# Best-effort build metadata (safe on Windows)
GIT_SHA    := nogit
BUILD_TIME := unknown

LDFLAGS := -s -w -X main.gitSHA=$(GIT_SHA) -X main.buildTime=$(BUILD_TIME)

.PHONY: clean build

all: clean build

info:
	@echo GO=$(GO)
	@$(GO) version
	@$(GO) env

default: build

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf $(DIST_DIR)/$(BINARY_NAME)

build:
	go build -o $(DIST_DIR)/$(BINARY_NAME) .
