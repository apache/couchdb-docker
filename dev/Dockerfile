# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

# Base layer containing dependencies needed at runtime. This layer will be
# cached after the initial build.
FROM debian:buster as runtime

MAINTAINER CouchDB Developers dev@couchdb.apache.org

# Add CouchDB user account
RUN groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb

RUN apt-get update -y && apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        dirmngr \
        gnupg \
        libicu63 \
        libssl1.1 \
        openssl \
    && apt-get update -y && apt-get install -y --no-install-recommends libmozjs-60-0 \
    && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root and tini for signal handling
# see https://github.com/apache/couchdb-docker/pull/28#discussion_r141112407
ENV GOSU_VERSION 1.10
ENV TINI_VERSION 0.16.1
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gosu tini; \
    rm -rf /var/lib/apt/lists/*; \
    gosu nobody true; \
    tini --version

# Dependencies only needed during build time. This layer will also be cached
FROM runtime AS build_dependencies

RUN set -eux; \
    apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    libmozjs-60-dev \
    erlang-nox \
    erlang-reltool \
    erlang-dev \
    erlang-dialyzer \
    git \
    libcurl4-openssl-dev \
    libicu-dev \
    python3 \
    libpython3-dev \
    python3-pip \
    python3-sphinx \
    python3-setuptools \
    wget

RUN set -eux; \
    pip3 install --upgrade \
    sphinx_rtd_theme \
    nose \
    requests \
    hypothesis

RUN set -eux; \
    wget https://www.foundationdb.org/downloads/6.3.9/ubuntu/installers/foundationdb-clients_6.3.9-1_amd64.deb; \
    wget https://www.foundationdb.org/downloads/6.3.9/ubuntu/installers/foundationdb-server_6.3.9-1_amd64.deb; \
    dpkg -i ./foundationdb*deb; \
    pkill -f fdb || true; pkill -f foundation || true; \
    rm -rf ./foundationdb*deb

# Node is special
RUN set -eux; \
    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -; \
    echo 'deb https://deb.nodesource.com/node_10.x buster main' > /etc/apt/sources.list.d/nodesource.list; \
    echo 'deb-src https://deb.nodesource.com/node_10.x buster main' >> /etc/apt/sources.list.d/nodesource.list; \
    apt-get update -y && apt-get install -y nodejs; \
    npm install -g grunt-cli

# Clone CouchDB source code including all dependencies
ARG clone_url=https://github.com/apache/couchdb.git
RUN git clone $clone_url /usr/src/couchdb
WORKDIR /usr/src/couchdb
RUN ./configure

# This layer performs the actual build of a relocatable, self-contained
# release of CouchDB. It pulls down the latest changes from the remote
# origin (because the layer above will be cached) and switches to the
# branch specified in the build_arg (defaults to main)
FROM build_dependencies AS build

ARG checkout_branch=main
ARG configure_options
ARG spidermonkey_version=60

WORKDIR /usr/src/couchdb/
RUN git fetch origin \
    && git checkout $checkout_branch \
    && ./configure $configure_options --spidermonkey-version $spidermonkey_version\
    && make release

# This results in a single layer image (or at least skips the build stuff?)
FROM runtime
COPY --from=build /usr/src/couchdb/rel/couchdb /opt/couchdb

# Add configuration
COPY local.ini /opt/couchdb/etc/default.d/
COPY vm.args /opt/couchdb/etc/
COPY docker-entrypoint.sh /

# Setup directories and permissions
RUN find /opt/couchdb \! \( -user couchdb -group couchdb \) -exec chown -f couchdb:couchdb '{}' +

WORKDIR /opt/couchdb
EXPOSE 5984 4369 9100
VOLUME ["/opt/couchdb/data"]

ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
CMD ["/opt/couchdb/bin/couchdb"]
