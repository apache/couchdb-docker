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

ARG CLOUSEAU_VERSION=2.17.0

FROM registry.access.redhat.com/ubi8/ubi-minimal as builder

ARG CLOUSEAU_VERSION

WORKDIR /usr/src

# Fetch and extract clouseau
RUN set -xe; \
    microdnf update -y && rm -rf /var/cache/yum && \
    microdnf install -y unzip wget && \
    wget https://github.com/cloudant-labs/clouseau/releases/download/${CLOUSEAU_VERSION}/clouseau-${CLOUSEAU_VERSION}-dist.zip && \
    unzip clouseau-2.17.0-dist.zip && \ 
    microdnf clean all; \
    rm -rf /var/cache/yum

FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG RELEASE
ARG BUILD_DATE
ARG CLOUSEAU_VERSION

LABEL maintainer="CouchDB Developers dev@couchdb.apache.org" \
      name="Apache CouchDB" \
      version="3.1.2" \
      summary="Apache CouchDB based on Red Hat UBI" \
      description="Red Hat OpenShift-compatible container that runs Apache CouchDB" \
      release=${RELEASE}  \
      usage="https://github.com/apache/couchdb-docker" \
      build-date=${BUILD_DATE} \
      io.k8s.display-name="Apache CouchDB" \
      io.k8s.description="Red Hat OpenShift-compatible container that runs Apache CouchDB" \
      io.openshift.tags="database couchdb apache rhel8" \
      io.openshift.expose-services="5984/http,4369/epmd,9100/erlang" \
      io.openshift.min-memory="1Gi" \
      io.openshift.min-cpu="1"

COPY imeyer_runit.repo /etc/yum.repos.d/imeyer_runit.repo
COPY couchdb.repo /etc/yum.repos.d/couchdb.repo

ENV COUCHDB_VERSION=3.1.2 \
    CLOUSEAU_VERSION=${CLOUSEAU_VERSION} \
    JAVA_MAJOR_VERSION=8 \
    JAVA_HOME=/usr/lib/jvm/jre-1.8.0 \
    CLASSPATH=${APP_ROOT}/lib/*

# Add CouchDB user account to make sure the IDs are assigned consistently
# CouchDB user added to root group for OpenShift support
RUN set -ex; \
# be sure GPG and apt-transport-https are available and functional
    microdnf update -y && rm -rf /var/cache/yum; \
    microdnf install -y \
            java-1.8.0-openjdk-headless \
            ca-certificates \
            gnupg \
            findutils \
            shadow-utils; \
# Add CouchDB User and Group (group required by rpm)
    useradd -u 5984 -d /opt/couchdb -g root couchdb; \
    groupadd -g 5984 couchdb; \
# Install runit
    microdnf update --disableplugin=subscription-manager -y && rm -rf /var/cache/yum; \
    microdnf install --enablerepo=imeyer_runit -y runit; \
# Clean up
    microdnf clean all; \
    rm -rf /var/cache/yum

# Install CouchDB
RUN set -xe; \
    microdnf update --disableplugin=subscription-manager -y && rm -rf /var/cache/yum; \
    microdnf install --enablerepo=couchdb -y couchdb-${COUCHDB_VERSION}; \
    microdnf clean all; \
    rm -rf /var/cache/yum; \
# remove defaults that force writing logs to file
    rm /opt/couchdb/etc/default.d/10-filelog.ini; \
# Check we own everything in /opt/couchdb. Matches the command in dockerfile_entrypoint.sh
    find /opt/couchdb \! \( -user couchdb -group 0 \) -exec chown -f couchdb:0 '{}' +; \
# Setup directories and permissions for config. Technically these could be 555 and 444 respectively
# but we keep them as 775 and 664 for consistency with the dockerfile_entrypoint.
    find /opt/couchdb/etc -type d ! -perm 0755 -exec chmod -f 0755 '{}' +; \
    find /opt/couchdb/etc -type f ! -perm 0644 -exec chmod -f 0644 '{}' +; \
# Setup directories and permissions for data.
    chmod 777 /opt/couchdb/data

# Copy Clouseau jar and set directory permissions
COPY resources/clouseau/clouseau.ini resources/clouseau/log4j.properties /opt/couchdb-search/etc/
COPY --from=builder /usr/src/clouseau-${CLOUSEAU_VERSION}/*.jar /opt/couchdb-search/lib/

RUN install -d -m 0755 -o couchdb -g 0 -p /opt/couchdb-search/etc /opt/couchdb-search/lib /opt/couchdb/data/search_indexes && \
    find -L /opt/couchdb-search \! \( -user couchdb -group 0 \) -exec chown -f couchdb:0 '{}' +; \
	find -L /opt/couchdb-search -type d ! -perm 0755 -exec chmod -f 0755 '{}' +; \
    find -L /opt/couchdb-search -type f ! -perm 0644 -exec chmod -f 0644 '{}' +;

# Add the License
COPY licenses /licenses

# Add configuration
COPY --chown=couchdb:0 resources/10-docker-default.ini /opt/couchdb/etc/default.d/
COPY --chown=couchdb:0 resources/vm.args /opt/couchdb/etc/
COPY --chown=couchdb:0 resources/docker-entrypoint.sh /usr/local/bin
COPY --chown=couchdb:0 resources/run /etc/service/couchdb/
COPY --chown=couchdb:0 resources/run_clouseau /etc/service/couchdb-search/run

# set permissions on runit scripts
RUN chmod -R 777 /etc/service/couchdb; \
    chmod -R 777 /etc/service/couchdb-search; \
    chmod 777 /usr/local/bin/docker-entrypoint.sh; \
# symlink to root folder
    ln -s usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
VOLUME /opt/couchdb/data

# 5984: Main CouchDB endpoint
# 4369: Erlang portmap daemon (epmd)
# 9100: CouchDB cluster communication port
EXPOSE 5984 4369 9100
CMD ["/opt/couchdb/bin/couchdb"]
