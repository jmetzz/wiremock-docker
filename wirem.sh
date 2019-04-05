#!/usr/bin/env bash

. util.sh

IMAGE_NAME=jmetzz/wiremock
CURRENT_VERSION=$(cat Dockerfile | grep "ENV WIREMOCK_VERSION" | cut -d ' ' -f 3)
IMAGE_TAG=${IMAGE_NAME}:${CURRENT_VERSION}

EXECUTION_OUTPUT=/dev/stdout

usage() {
cat << EOF
Usage: $0 COMMAND [-v]
       $0 [ -h | --help ]

Wiremock Docker image project

Commands:
  build             Build the docker image
  run               Spin up the container

Args:
  -q                quiet mode
  -y                force yes
EOF
exit
}

function error {
    echo "$2" >&2
    usage
    exit $1
}

_build() {
  TAG=$1

  title "Build Wiremock Docker image ${TAG}"

  docker build -t ${TAG} . > ${EXECUTION_OUTPUT}
  assert_bash_ok $?
}

build() {
  _build ${IMAGE_TAG}
  docker tag ${IMAGE_TAG} ${IMAGE_NAME}
}

run(){
    IMAGE_ID=$(docker images -q ${IMAGE_TAG})
    [[ -z $IMAGE_ID ]] && build
    docker run -it --rm -u $(id -u):$(id -g) -v $(pwd)/stubs:/home/wiremock -p 8080:8080 ${IMAGE_TAG}
}


while getopts ":hq" opt; do
    case "${opt}" in
        q)
            EXECUTION_OUTPUT=/dev/null
            ;;
        h)
            usage
            exit
            ;;
        :)
            error 2 "Option -$OPTARG requires an argument."
            ;;
        \?)
            error 1 "Invalid option: -$OPTARG"
            ;;
    esac
done
shift $((OPTIND-1))

remaining_arguments=( "$@" )
[[ ${#remaining_arguments[*]} -ne 1 ]] && error 3 "Unknown task"


# process
case $1 in
    build|test)
        $@
        smoke_report
        ;;
    run)
        $@
        ;;
    *)
        usage
        ;;
esac
