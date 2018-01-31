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

MAINTAINER CouchDB Developers dev@couchdb.apache.org

ENV COUCHDB_VERSION master

RUN groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb

# download dependencies
RUN apt-get update -y -qq && apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    default-jdk \
    erlang-dev \
    erlang-nox \
    git \
    haproxy \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs185-dev \
    libwxgtk3.0 \
    openssl \
    pkg-config \
    python \
    python-sphinx \
    texinfo \
    texlive-base \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-latex-extra \
 && curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo 'deb https://deb.nodesource.com/node_6.x jessie main' > /etc/apt/sources.list.d/nodesource.list \
 && echo 'deb-src https://deb.nodesource.com/node_6.x jessie main' >> /etc/apt/sources.list.d/nodesource.list \
 && apt-get update -y -qq && apt-get install -y nodejs \
 && npm install -g grunt-cli \
 && cd /usr/src && git clone https://gitbox.apache.org/repos/asf/couchdb.git \
 && cd couchdb && git checkout $COUCHDB_VERSION \
 && cd /usr/src/couchdb && ./configure && make \
 && apt-get purge -y \
    binutils \
    build-essential \
    cpp \
    default-jdk \
    git \
    libcurl4-openssl-dev \
    libicu-dev \
    libwxgtk3.0 \
    make \
    nodejs \
    perl \
    pkg-config \
    texinfo \
    texlive-base \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-latex-extra \
 && apt-get autoremove -y \
 && apt-get install -y libicu52 --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* /usr/lib/node_modules src/fauxton/node_modules src/**/.git .git

# permissions
RUN chmod +x /usr/src/couchdb/dev/run && chown -R couchdb:couchdb /usr/src/couchdb

USER couchdb
EXPOSE 5984 15984 25984 35984 15986 25986 35986
WORKDIR /usr/src/couchdb

ENTRYPOINT ["/usr/src/couchdb/dev/run"]
CMD ["--with-haproxy"]
