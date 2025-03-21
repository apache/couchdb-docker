#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing,
#   software distributed under the License is distributed on an
#   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#   KIND, either express or implied.  See the License for the
#   specific language governing permissions and limitations
#   under the License.

# This shell script makes it easier to build multi-platform
# architecture Docker containers on an x86_64 host.
#
# For more reading:
#   https://github.com/moby/buildkit/issues/1943
#   https://github.com/tonistiigi/binfmt
#   https://github.com/multiarch/qemu-user-static
#   https://lobradov.github.io/Building-docker-multiarch-images/
#   https://github.com/jessfraz/irssi/blob/master/.travis.yml
#   https://engineering.docker.com/2019/04/multi-arch-images/
#   https://github.com/docker/buildx

set -e

BUILDX_PLATFORMS="linux/amd64,linux/arm64/v8,linux/s390x"
# Temporarily disable ppc64le because https://github.com/apache/couchdb-pkg/commit/365d07ce43d9d6d9c3377dd08dc8fc5f656a11bf

clean() {
  echo $#
  if [ $# -eq 0 ]
  then
    regex="*"
  elif [ $# -eq 1 ]
  then
    regex=$1
  else
    usage
  fi

  docker images --filter=reference="apache/couchdb:${regex}" | tr -s ' ' | cut -d ' ' -f 2 | while read tag
  do
    if [ ${tag} ] && [ ${tag} = "TAG" ]
    then
      continue
    fi
    docker rmi apache/couchdb:$tag
  done
}

# Builds all platforms for a specific version and pushes to the registry
buildx() {
  if [ $2 ]
  then
    tag_as=$2
  else
    tag_as=$1
  fi

  echo "Starting buildx build at $(date)..."
  docker buildx build --platform ${BUILDX_PLATFORMS} --tag apache/couchdb:$tag_as --push $1
  echo ""

  echo "Starting buildx nouveau build at $(date)..."
  docker buildx build --platform ${BUILDX_PLATFORMS} --tag apache/couchdb:${tag_as}-nouveau --push $1-nouveau
  echo ""
}

usage() {
  cat << EOF
$0 <command> <-f> <-n> [OPTIONS]

General commands:
  clean                  Removes ALL local apache/couchdb images (!!)
  clean <regex>          Removes ALL local images with matching tags.

\`docker buildx\` commands:
  buildx #.#.#           Builds *and pushes* all platforms for supplied
                         version, using docker buildx. Built images must
                         be retrieved with \`docker pull\` for local use.

  buildx #.#.# as <tag>
                         Builds and pushes all platforms for supplied
                         version, using docker buildx, tagging the
                         manifest with the supplied <tag>.

Example workflow:
  $0 clean *2.9.7*
  $0 buildx 2.9.7
  $0 buildx 2.9.7 as 2.9
  $0 buildx 2.9.7 as 2
  $0 buildx 2.9.7 as latest
  docker manifest inspect apache/couchdb:2.9.7
  docker pull <--platform linux/other-arch> apache/couchdb:2.9.7 (for testing)

EOF
exit 0
}

# #######################

# handle -f/-n anywhere they appear on the CLI
POSITIONAL=()
while [[ $# -gt 0 ]]
do
  # otherwise, we WILL match a regex against top-level directories!
  set -f
  key="$1"
  case $key in
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
  set +f
done
# re-set all other arguments into argc
set -- "${POSITIONAL[@]}" # restore positional parameters

case "$1" in
  clean)
    # removes local images for a given version (and optionally platform)
    shift
    set -f
    clean $*
    set +f
    ;;
  buildx)
    # builds and pushes using docker buildx
    shift
    if [ $# -ne 1 -a $# -ne 3 ]
    then
      usage
    fi
    if [ $# -eq 1 ]
    then
      buildx $1
    elif [ $2 = "as" ]
    then
      buildx $1 $3
    else
      usage
    fi
    ;;
  usage)
    usage
    ;;
  *)
    usage
    ;;
esac
