FROM debian:wheezy

MAINTAINER Clemens Stolle klaemo@fastmail.fm

# Install instructions from https://cwiki.apache.org/confluence/display/COUCHDB/Debian

ENV COUCHDB_VERSION 1.6.0

RUN useradd -d /var/lib/couchdb couchdb

# download dependencies
RUN apt-get update -y && apt-get install -y lsb-release wget \
  && echo "deb http://binaries.erlang-solutions.com/debian `lsb_release -cs` contrib" \
  | tee /etc/apt/sources.list.d/erlang-solutions.list \
  && wget -O - http://binaries.erlang-solutions.com/debian/erlang_solutions.asc \
  | apt-key add - \
  && echo "deb http://packages.cloudant.com/debian `lsb_release -cs` main" \
  | tee /etc/apt/sources.list.d/cloudant.list \
  && wget http://packages.cloudant.com/KEYS -O - | apt-key add - \
  && apt-get update -y \
  && apt-get install -y erlang-nox erlang-dev build-essential \
  libmozjs185-cloudant libmozjs185-cloudant-dev \
  libnspr4 libnspr4-0d libnspr4-dev libcurl4-openssl-dev curl libicu-dev \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# download and verify the source
RUN curl -L http://apache.openmirror.de/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz -o couchdb.tar.gz \
  && curl -L http://www.apache.org/dist/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz.asc -o couchdb.tar.gz.asc \
  && curl -L http://www.apache.org/dist/couchdb/KEYS -o KEYS \
  && gpg --import KEYS \
  && gpg --verify couchdb.tar.gz.asc \
  && mkdir -p /usr/src/couchdb \
  && tar -xzf couchdb.tar.gz -C /usr/src/couchdb --strip-components=1

# build couchdb
RUN cd /usr/src/couchdb \
  && ./configure --with-js-lib=/usr/lib --with-js-include=/usr/include/mozjs \
  && make && make install

RUN curl -o /usr/local/bin/gosu -SkL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
  && chmod +x /usr/local/bin/gosu

# cleanup (libicu48 gets autoremoved, but we actually need it)
RUN apt-get purge -y erlang-dev build-essential libmozjs185-cloudant-dev libnspr4-dev libcurl4-openssl-dev libicu-dev lsb-release wget \
  && apt-get autoremove -y \
  && apt-get update && apt-get install -y libicu48 --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && rm -r /usr/src/couchdb \
  && rm couchdb.tar.gz* KEYS

# permissions
RUN chown -R couchdb:couchdb \
  /usr/local/lib/couchdb /usr/local/etc/couchdb \
  /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb \
  && chmod -R g+rw \
  /usr/local/lib/couchdb /usr/local/etc/couchdb \
  /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb 

# Expose to the outside
RUN sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i /usr/local/etc/couchdb/default.ini

ADD ./docker-entrypoint.sh /entrypoint.sh

# Define mountable directories.
VOLUME ["/usr/local/var/log/couchdb", "/usr/local/var/lib/couchdb", "/usr/local/etc/couchdb"]

EXPOSE 5984
WORKDIR /var/lib/couchdb

ENTRYPOINT ["/entrypoint.sh"]
CMD ["couchdb"]
