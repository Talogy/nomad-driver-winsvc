BINARY_NAME ?= winsvc-driver
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

clean:
	if exist "$(DIST_DIR)" rmdir /s /q "$(DIST_DIR)"

build:
	go build -o ${PLUGIN_BINARY} .


PLUGIN_BINARY=bin/winsvc-driver.exe
export GO111MODULE=on

default: build

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf ${PLUGIN_BINARY}

build:
	mkdir -p bin
	go build -o ${PLUGIN_BINARY} .
