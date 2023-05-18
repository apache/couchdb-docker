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

PROMPT="Are you sure (y/n)? "
QEMU="YES"
PLATFORMS="amd64 arm64v8 ppc64le s390x"
BUILDX_PLATFORMS="linux/amd64,linux/arm64/v8,linux/ppc64le,linux/s390x"

prompt() {
  if [ -z "${PROMPT}" ]
  then
    return
  fi
  if [ "$1" ]
  then
    echo "$1"
  fi
  read -p "${PROMPT}"
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    return
  else
    exit 0
  fi
}

update_qemu() {
  # necessary locally after every reboot, not sure why....update related maybe?
  # basically harmless to run everytime, except for elevated privs necessary.
  # disable with -n flag
  # NOTE multiarch/qemu-user-static broken as of Jan 2021
  # docker rmi multiarch/qemu-user-static >/dev/null 2>&1 || true
  # docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  # docker rmi multiarch/qemu-user-static
  # use tonistiigi/binfmt instead.
  echo "Uninstalling all qemu emulators..."
  for plat in $(docker run --privileged tonistiigi/binfmt | jq -c '.emulators[] | select(. | contains("qemu"))'); do
    plat="${plat//\"}"
    docker run --privileged tonistiigi/binfmt --uninstall $plat >/dev/null 2>&1
  done

  echo "Reinstalling all qemu emulators with latest version..."
  docker run --privileged --rm tonistiigi/binfmt --install all

  echo "Proving all emulators work..."
  docker run --rm arm32v7/alpine uname -a
  docker run --rm arm64v8/alpine uname -a
  docker run --rm s390x/alpine uname -a
  docker run --rm tonistiigi/debian:riscv uname -a
}

clean() {
  echo $#
  if [ $# -eq 0 ]
  then
    regex="*"
    ADD_PROMPT="This will remove *ALL* local apache/couchdb Docker images!"
  elif [ $# -eq 1 ]
  then
    regex=$1
    ADD_PROMPT="This will remove *ALL* apache/couchdb images matching regex '${1}' !"
  else
    usage
  fi
  prompt "${ADD_PROMPT}"

  docker images --filter=reference="apache/couchdb:${regex}" | tr -s ' ' | cut -d ' ' -f 2 | while read tag
  do
    if [ ${tag} ] && [ ${tag} = "TAG" ]
    then
      continue
    fi
    docker rmi apache/couchdb:$tag
  done
}

# Builds a specific version
build() {
  VERSION=$1
  ARCH=${2:-amd64}
  FROMIMG="$(awk '$1 == toupper("FROM") { print $2; exit; }' $VERSION/Dockerfile)"
  echo ${FROMIMG}
  CURRARCH="$(docker run --rm -t ${FROMIMG} uname -m | sed -e 's/[[:space:]]*$//')"
  if [ "${CURRARCH}" == "x86_64" ]
  then
    CURRARCH="amd64"
  fi

  if [ "${CURRARCH}" != "${ARCH}" ]
  then
    if [[ "${FROMIMG}" == *"redhat.com"* ]]
    then
      echo "Script does not handle multiarch for ubi images. Please fix me!"
      exit 1
    fi
    docker rmi ${FROMIMG}
    docker pull "${ARCH}/${FROMIMG}"
    docker tag "${ARCH}/${FROMIMG}" "${FROMIMG}"
  fi
  docker build -t apache/couchdb:${ARCH}-${VERSION} ${VERSION}
  echo "CouchDB ${VERSION} for ${ARCH} built as apache/couchdb:${ARCH}-${VERSION}."
}

# Builds all platforms for a specific version, local only
# We can't do this with docker buildx, see https://github.com/docker/buildx/issues/166#issuecomment-562729523
build-all() {
  VERSION=$1
  for ARCH in ${PLATFORMS}; do
    echo "Starting ${ARCH} at $(date)..."
    build $1 ${ARCH}
    echo ""
  done
}

# Push locally built versions using above technique
push() {
  if [ $2 ]
  then
    tag_as=$2
  else
    tag_as=$1
  fi
  docker manifest create apache/couchdb:$tag_as \
    apache/couchdb:amd64-$1 \
    apache/couchdb:arm64v8-$1 \
    apache/couchdb:ppc64le-$1 \
    apache/couchdb:s390x-$1

  docker manifest annotate apache/couchdb:$tag_as \
    apache/couchdb:arm64v8-$1 --os linux --arch arm64 --variant v8

  docker manifest annotate apache/couchdb:$tag_as \
    apache/couchdb:ppc64le-$1 --os linux --arch ppc64le
  
  docker manifest annotate apache/couchdb:$tag_as \
    apache/couchdb:s390x-$1 --os linux --arch s390x

  docker manifest push --purge apache/couchdb:$tag_as

  docker manifest inspect apache/couchdb:$tag_as
}

# Builds all platforms for a specific version and pushes to the registry
buildx() {
  if [ $2 ]
  then
    tag_as=$2
  else
    tag_as=$1
  fi
  docker buildx rm apache-couchdb >/dev/null 2>&1 || true


  echo "Creating the buildx environment..."
  docker buildx create --name apache-couchdb --driver docker-container --use
  docker buildx use apache-couchdb
  docker buildx inspect --bootstrap

  echo "Starting buildx build at $(date)..."
  docker buildx build --platform ${BUILDX_PLATFORMS} --tag apache/couchdb:$tag_as --push $1
  echo ""
}

usage() {
  cat << EOF
$0 <command> <-f> <-n> [OPTIONS]

Options:
  -f                     Skip confirmation prompt.
  -n                     Do not install QEMU and binfmt_misc
                         (build commands only)

General commands:
  clean                  Removes ALL local apache/couchdb images (!!)
  clean <regex>          Removes ALL local images with matching tags.

\`docker build\` commands:
  version #.#.# [all]    Builds all platforms for supplied version
                         Each platform is tagged <arch>-<version>.

  version #.#.# <arch>   Builds only the specified version and arch.

  push #.#.# [as <tag>]  Pushes locally-built versions as a multi-arch
                         manifest. If \`as <tag>\` is specified,
                         pushes the manifest using that tag instead.

Example workflow:
  $0 clean *2.9.7*
  $0 version 2.9.7 all
  <test, then>
  $0 push 2.9.7
  $0 push 2.9.7 as 2.9
  $0 push 2.9.7 as 2
  $0 push 2.9.7 as latest

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


NOTE: Requires Docker 19.03+ with experimental features enabled.
      Add { "experimental" : "true" } to /etc/docker/daemon.json, then
      add { "experimental": "enabled" } to ~/.docker/config.json, then
      restart the Docker daemon.

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
    -f|--force)
      unset PROMPT
      shift
      ;;
    -n|--no-qemu)
      unset QEMU
      shift
      ;;
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
  version)
    # builds a specific version using docker build
    # validate/reinstall QEMU
    if [ ${QEMU} ]
    then
      update_qemu
    fi
    shift
    if [ $# -lt 1 -o $# -gt 3 ]
    then
      usage
    fi
    # version #.#.# all
    if [ "$2" = "all" ]
    then
      # build all the platforms and test them locally
      build-all $1
    else
      # build a specific platform locally
      build $1 $2
    fi
    ;;
  push)
    # pushes already built local versions as manifest
    shift
    if [ $# -ne 1 -a $# -ne 3 ]
    then
      usage
    fi
    if [ $# -eq 1 ]
    then
      push $1
    elif [ $2 = "as" ]
    then
      push $1 $3
    else
      usage
    fi
    ;;
  buildx)
    # builds and pushes using docker buildx
    shift
    if [ $# -ne 1 -a $# -ne 3 ]
    then
      usage
    fi
    if [ ${QEMU} ]
    then
      update_qemu
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
