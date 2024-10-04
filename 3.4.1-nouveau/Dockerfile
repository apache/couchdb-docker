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

FROM debian:bookworm-slim

LABEL maintainer="CouchDB Developers dev@couchdb.apache.org"

# Add CouchDB user account to make sure the IDs are assigned consistently
RUN groupadd -g 5984 -r nouveau && useradd -u 5984 -d /opt/nouveau -g nouveau nouveau

# be sure GPG and apt-transport-https are available and functional
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        dirmngr \
        gnupg \
     ; \
    rm -rf /var/lib/apt/lists/*

# Nouveau wants a JRE/JDK
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        openjdk-17-jre-headless \
     ; \
    rm -rf /var/lib/apt/lists/*

# grab tini for signal handling and zombie reaping
# see https://github.com/apache/couchdb-docker/pull/28#discussion_r141112407
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends tini; \
    rm -rf /var/lib/apt/lists/*; \
    tini --version

# http://docs.couchdb.org/en/latest/install/unix.html#installing-the-apache-couchdb-packages
# gpg: rsa8192 205-01-19 The Apache Software Foundation (Package repository signing key) <root@apache.org>

ENV GPG_COUCH_KEY 390EF70BB1EA12B2773962950EE62FB37A00258D

RUN set -eux; \
   apt-get update; \
   apt-get install -y curl; \
   export GNUPGHOME="$(mktemp -d)"; \
   curl -fL -o keys.asc https://couchdb.apache.org/repo/keys.asc; \
   gpg --batch --import keys.asc; \
   gpg --batch --export "${GPG_COUCH_KEY}" > /usr/share/keyrings/couchdb-archive-keyring.gpg; \
   command -v gpgconf && gpgconf --kill all || :; \
   rm -rf "$GNUPGHOME"; \
   apt-key list; \
   apt purge -y --autoremove curl; \
   rm -rf /var/lib/apt/lists/*

RUN . /etc/os-release; \
   echo "deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couchdb-deb/ bookworm main" | \
       tee /etc/apt/sources.list.d/couchdb.list >/dev/null

# https://github.com/apache/couchdb-pkg/blob/master/debian/README.Debian
RUN set -eux; \
    apt-get update; \
    \
    echo "couchdb-nouveau couchdb-nouveau/enable select false" | debconf-set-selections; \
    DEBIAN_FRONTEND=noninteractive COUCHDB_NOUVEAU_ENABLE=1 apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages --no-install-recommends \
            couchdb-nouveau=3.4.1~bookworm; \
    rm -rf /var/lib/apt/lists/*; \
    chown -R nouveau:nouveau /opt/nouveau

COPY --chown=nouveau:nouveau nouveau.yaml /opt/nouveau/etc/nouveau.yaml

VOLUME /opt/nouveau/data

# 5987: Nouveau App
# 5988: Nouveau Admin
EXPOSE 5987 5988

# TODO: re-add tini
CMD ["/usr/bin/java", "-server", "-Djava.awt.headless=true", "-Xmx2g", "-jar", "/opt/nouveau/lib/nouveau-1.0-SNAPSHOT.jar", "server", "/opt/nouveau/etc/nouveau.yaml"]
