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

# Install instructions from https://cwiki.apache.org/confluence/display/COUCHDB/Debian

ENV COUCHDB_VERSION 1.6.1

RUN groupadd -r couchdb && useradd -d /var/lib/couchdb -g couchdb couchdb

# download dependencies, compile and install couchdb
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    erlang-dev \
    erlang-nox \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-1.0 \
    libmozjs185-dev \
    libnspr4 \
    libnspr4-0d \
    libnspr4-dev \
 && curl -sSL http://apache.openmirror.de/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz -o couchdb.tar.gz \
 && curl -sSL https://www.apache.org/dist/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz.asc -o couchdb.tar.gz.asc \
 && curl -sSL https://www.apache.org/dist/couchdb/KEYS -o KEYS \
 && gpg --import KEYS && gpg --verify couchdb.tar.gz.asc \
 && mkdir -p /usr/src/couchdb \
 && tar -xzf couchdb.tar.gz -C /usr/src/couchdb --strip-components=1 \
 && cd /usr/src/couchdb \
 && ./configure --with-js-lib=/usr/lib --with-js-include=/usr/include/mozjs \
 && make && make install \
 && apt-get purge -y \
    binutils \
    build-essential \
    cpp \
    libcurl4-openssl-dev \
    libicu-dev \
    libnspr4-dev \
    make \
    perl \
 && apt-get autoremove -y \
 && apt-get install -y libicu52 --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* /usr/src/couchdb /couchdb.tar.gz* /KEYS

# grab gosu for easy step-down from root, set correct permissions, expose couchdb to the outside
# and disable logging to disk
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
  && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
  && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu \
  && chown -R couchdb:couchdb \
    /usr/local/lib/couchdb /usr/local/etc/couchdb \
    /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb \
  && chmod -R g+rw \
    /usr/local/lib/couchdb /usr/local/etc/couchdb \
    /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb \
  && mkdir -p /var/lib/couchdb \
  && sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i /usr/local/etc/couchdb/default.ini \
  && sed -e 's/\/usr\/local\/var\/log\/couchdb\/couch.log$/\/dev\/null/' -i /usr/local/etc/couchdb/default.ini

COPY ./docker-entrypoint.sh /

# Define mountable directories.
VOLUME ["/usr/local/var/lib/couchdb"]

EXPOSE 5984
WORKDIR /var/lib/couchdb

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["couchdb"]
