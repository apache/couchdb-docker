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

# This shell script builds all the supported architectures for
# a single version, pushes them to Docker Hub, then creates the
# manifest.

# Usage: ./build-manifest.sh <VERSION>

# With help from https://lobradov.github.io/Building-docker-multiarch-images/

set -e

for arch in amd64 arm64v8 ppc64le; do
  ./build.sh $1 ${arch}
  docker push apache/couchdb:${arch}-$1
done

docker manifest create apache/couchdb:$1 \
    apache/couchdb:amd64-$1 \
    apache/couchdb:arm64v8-$1 \
    apache/couchdb:ppc64le-$1

docker manifest annotate apache/couchdb:$1 \
    apache/couchdb:arm64v8-$1 --os linux --arch arm64 --variant armv8

docker manifest annotate apache/couchdb:$1 \
    apache/couchdb:ppc64le-$1 --os linux --arch ppc64le

docker manifest push apache/couchdb:$1

docker manifest inspect apache/couchdb:$1
