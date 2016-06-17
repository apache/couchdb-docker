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

FROM debian:jessie

MAINTAINER Clemens Stolle klaemo@apache.org

# Pin to an arbitrary commit for a deterministic build
# Once CouchDB has an actual 2.0 tag, we can use that
ENV COUCHDB_VERSION 1b38ccd

# Download dependencies
RUN apt-get update -y -qq \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    erlang-dev \
    erlang-nox \
    erlang-reltool \
    git \
    haproxy \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-dev \
    openssl \
    python \
 && curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list \
 && echo 'deb-src https://deb.nodesource.com/node_4.x jessie main' >> /etc/apt/sources.list.d/nodesource.list \
 && apt-get update -y -qq \
 && apt-get install -y nodejs \
 && npm install -g grunt-cli \
 # Acquire CouchDB source code
 && cd /usr/src \
 && git clone --depth 1 https://git-wip-us.apache.org/repos/asf/couchdb.git \
 && cd couchdb \
 && git checkout $COUCHDB_VERSION \
 # Build the release and install into /opt
 && ./configure --disable-docs \
 && make build \
 && mv /usr/src/couchdb/rel/couchdb /opt/ \
 # Cleanup build detritus
 && apt-get purge -y \
    binutils \
    build-essential \
    cpp \
    erlang-dev \
    git \
    libicu-dev \
    make \
    nodejs \
    perl \
 && apt-get autoremove -y && apt-get clean \
 && apt-get install -y libicu52 --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* /usr/lib/node_modules /usr/src/couchdb

# Add configuration
COPY local.ini /opt/couchdb/etc/
COPY vm.args /opt/couchdb/etc/

# Add CouchDB user account
RUN groupadd -r couchdb \
 && useradd -d /opt/couchdb -g couchdb couchdb

# Setup directory permissions
RUN mkdir -p /opt/couchdb/data \
 && chown -R couchdb:couchdb /opt/couchdb/

USER couchdb
WORKDIR /opt/couchdb
EXPOSE 5984 4369 9100
VOLUME ["/opt/couchdb/data"]

ENTRYPOINT ["/opt/couchdb/bin/couchdb"]
