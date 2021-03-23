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
FROM debian:buster

MAINTAINER CouchDB Developers dev@couchdb.apache.org

# Add CouchDB user account
RUN groupadd -r couchdb && useradd -d /opt/couchdb -g couchdb couchdb

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dirmngr \
    gnupg \
    haproxy \
    libicu63 \
    libmozjs-60-0 \
    openssl && \
  rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root and tini for signal handling
# see https://github.com/apache/couchdb-docker/pull/28#discussion_r141112407
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gosu tini; \
    rm -rf /var/lib/apt/lists/*; \
    gosu nobody true; \
    tini --version

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    erlang-nox \
    erlang-reltool \
    erlang-dev \
    git \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs-60-dev \
    python3 \
    libpython3-dev \
    python3-pip \
    python3-sphinx \
    python3-setuptools

RUN pip3 install --upgrade \
    sphinx_rtd_theme \
    nose \
    requests \
    hypothesis

# Node is special
RUN set -ex; \
    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -; \
    echo 'deb https://deb.nodesource.com/node_10.x buster main' > /etc/apt/sources.list.d/nodesource.list; \
    echo 'deb-src https://deb.nodesource.com/node_10.x buster main' >> /etc/apt/sources.list.d/nodesource.list; \
    apt-get update -y && apt-get install -y nodejs; \
    npm install -g grunt-cli


# Clone CouchDB source code including all dependencies
ARG clone_url=https://gitbox.apache.org/repos/asf/couchdb.git
RUN git clone $clone_url /usr/src/couchdb
WORKDIR /usr/src/couchdb
RUN ./configure -c --spidermonkey-version 60

ARG checkout_branch=main
ARG configure_options="-c --spidermonkey-version 60"

WORKDIR /usr/src/couchdb/
RUN git fetch origin \
    && git checkout $checkout_branch \
    && ./configure $configure_options \
    && make all

# Setup directories and permissions
RUN chown -R couchdb:couchdb /usr/src/couchdb

WORKDIR /opt/couchdb
EXPOSE 5984 15984 25984 35984
VOLUME ["/usr/src/couchdb/dev/lib"]

ENTRYPOINT ["tini", "--", "/usr/src/couchdb/dev/run"]
CMD ["--with-haproxy"]
