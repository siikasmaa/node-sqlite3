#!/usr/bin/env bash

source ~/.nvm/nvm.sh

set -e -u

function build() {
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
  mkdir tmp
  pushd tmp
  curl -L -o qemu-arm-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/v3.1.0-3/qemu-arm-static.tar.gz
  tar xzf qemu-arm-static.tar.gz
  popd
  travis_wait docker run --rm -v "$(pwd)":/build -v "$(pwd)"/tmp/qemu-arm-static:/usr/bin/qemu-arm-static arm32v7/node:${NODE_VERSION} bash -c $docker_script
}

docker_script="cd /build && npm install --unsafe-perm --build-from-source"

if [[ ${PUBLISHABLE:-false} == true ]] && [[ ${COMMIT_MESSAGE} =~ "[publish binary]" ]]; then
  docker_script+=" && node-pre-gyp package testpackage publish info --target_arch=armv7l"
fi



build
make clean

# now test building against shared sqlite
export NODE_SQLITE3_JSON1=no
if [[ $(uname -s) == 'Darwin' ]]; then
  brew update
  brew install sqlite
  npm install --build-from-source --sqlite=$(brew --prefix) --clang=1
else
  npm install --build-from-source --sqlite=/usr --clang=1
fi
electron_test
export NODE_SQLITE3_JSON1=yes
