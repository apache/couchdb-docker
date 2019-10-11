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

# Usage: ./build.sh <VERSION> <ARCH>

# Inspired by https://github.com/jessfraz/irssi/blob/master/.travis.yml

set -e

TARGET=$1
ARCH=${2:-amd64}

if [ -n "${ARCH:-}" ]; then
  from="$(awk '$1 == toupper("FROM") { print $2 }' $TARGET/Dockerfile)"
  docker pull "$ARCH/$from"
  docker tag "$ARCH/$from" "$from"
fi

docker build -t apache/couchdb:$ARCH-$TARGET $TARGET
