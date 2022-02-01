# Customizable Makefile help to build C/C++ projects in a docker container.

PROJECT_NAME?=cppthreadpool

PROJECT_DOCKER_REPO?=${PROJECT_NAME}/
PROJECT_DOCKER_IMAGE?=${PROJECT_NAME}
PROJECT_DOCKER_IMAGE_VERSION?=latest
PROJECT_DOCKER_CONTAINER?=${PROJECT_DOCKER_IMAGE}
PROJECT_DOCKERFILE?=Dockerfile

PROJECT_CONTAINER_SHELL?=/bin/bash
PROJECT_TARGET_SOURCE_PATH?=/${PROJECT_NAME}
PROJECT_BUILD_DIR?=build
PROJECT_CTEST_TIMEOUT?=5000
PROJECT_CMAKE_CXX_FLAGS_RELEASE?='-O3 -g'
PROJECT_CONTAINER_CC?=clang
PROJECT_CONTAINER_CXX?=clang++
PROJECT_CMAKE_BUILD_TYPE?=Release
PROJECT_CMAKE_BUILD_TESTING?=TRUE
PROJECT_TEST_CORE_DIR?=${PROJECT_TARGET_SOURCE_PATH}/${PROJECT_BUILD_DIR}/cores
PROJECT_CMAKE_FLAGS?=

PROJECT_ADDITIONAL_RUN_PARAMS?=

BASIC_RUN_PARAMS?=-it --init --rm --privileged=true \
					  --memory-swap=-1 \
					  --ulimit core=-1 \
					  --name="${PROJECT_DOCKER_CONTAINER}" \
					  --workdir=${PROJECT_TARGET_SOURCE_PATH} \
					  --mount type=bind,source=${CURDIR},target=${PROJECT_TARGET_SOURCE_PATH} \
					  ${PROJECT_ADDITIONAL_RUN_PARAMS} \
					  ${PROJECT_DOCKER_IMAGE}:${PROJECT_DOCKER_IMAGE_VERSION}

IF_CONTAINER_RUNS=$(shell docker container inspect -f '{{.State.Running}}' ${PROJECT_DOCKER_CONTAINER} 2>/dev/null)

.DEFAULT_GOAL:=build

.PHONY: help
help: ## The Makefile helps to build project in a docker container
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: gen_cmake
gen_cmake: ## Generate cmake files, used internally
	docker run ${BASIC_RUN_PARAMS} \
		${PROJECT_CONTAINER_SHELL} -c \
		"mkdir -p ${PROJECT_TARGET_SOURCE_PATH}/${PROJECT_BUILD_DIR} && \
		cd ${PROJECT_BUILD_DIR} && \
		CC=${PROJECT_CONTAINER_CC} CXX=${PROJECT_CONTAINER_CXX} \
		cmake ${PROJECT_CMAKE_FLAGS} .."
	@echo
	@echo "CMake finished."

.PHONY: build
build: gen_cmake ## Build project source. In order to build a specific target run: make TARGET=<target name>.
	docker run ${BASIC_RUN_PARAMS} \
		${PROJECT_CONTAINER_SHELL} -c \
		"cd ${PROJECT_BUILD_DIR} && \
		make -j $$(nproc) ${TARGET}"
	@echo
	@echo "Build finished. The binaries are in ${CURDIR}/${PROJECT_BUILD_DIR}"

.PHONY: test
test: ## Run all tests
	docker run ${BASIC_RUN_PARAMS} \
		${PROJECT_CONTAINER_SHELL} -c \
		"mkdir -p ${PROJECT_TEST_CORE_DIR} && \
		cd ${PROJECT_BUILD_DIR} && \
		ctest --timeout ${PROJECT_CTEST_TIMEOUT} --output-on-failure"

.PHONY: clean
clean: ## Clean project build directory
	docker run ${BASIC_RUN_PARAMS} \
		${PROJECT_CONTAINER_SHELL} -c \
		"rm -rf ${PROJECT_BUILD_DIR}"

.PHONY: login
login: ## Login to the container. Note: if the container is already running, login into existing one
	@if [ "${IF_CONTAINER_RUNS}" != "true" ]; then \
		docker run ${BASIC_RUN_PARAMS} \
			${PROJECT_CONTAINER_SHELL};exit 0; \
	else \
		docker exec -it ${PROJECT_DOCKER_CONTAINER} \
			${PROJECT_CONTAINER_SHELL};exit 0; \
	fi

.PHONY: build-docker-image
build-docker-image: ## Build the image.
	docker build --rm --no-cache=true -t ${PROJECT_DOCKER_REPO}${PROJECT_DOCKER_IMAGE}:latest \
		-f ./${PROJECT_DOCKERFILE} .
	@echo
	@echo "Build finished. Docker image name: \"${PROJECT_DOCKER_REPO}${PROJECT_DOCKER_IMAGE}:latest\"."
	@echo "Before you push it to Docker Hub, please tag it(PROJECT_DOCKER_IMAGE_VERSION + 1)."
	@echo "If you want the image to be the default, please update the following variables:"
	@echo "${CURDIR}/Makefile: PROJECT_DOCKER_IMAGE_VERSION"
