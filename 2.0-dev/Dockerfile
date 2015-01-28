FROM debian:wheezy

MAINTAINER Clemens Stolle klaemo@fastmail.fm

ENV COUCHDB_VERSION developer-preview-2.0

RUN groupadd -r couchdb && useradd -d /usr/src/couchdb -g couchdb couchdb

# download dependencies
RUN echo 'deb http://http.debian.net/debian wheezy-backports main' > /etc/apt/sources.list.d/backports.list \
  && apt-get update -y \
  && apt-get install -y --no-install-recommends build-essential libmozjs185-dev \
    libnspr4 libnspr4-0d libnspr4-dev libcurl4-openssl-dev libicu-dev \
    openssl curl ca-certificates git pkg-config \
    apt-transport-https python \
  && apt-get install -y -t wheezy-backports erlang-base-hipe erlang-dev \
    erlang-manpages erlang-dialyzer erlang-eunit erlang-nox

RUN git clone https://github.com/rebar/rebar /usr/src/rebar \
 && (cd /usr/src/rebar ; make && mv rebar /usr/local/bin/)

 RUN cd /usr/src \
   && git clone https://git-wip-us.apache.org/repos/asf/couchdb.git \
   && cd couchdb \
   && git checkout developer-preview-2.0

RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
  && echo 'deb https://deb.nodesource.com/node wheezy main' > /etc/apt/sources.list.d/nodesource.list \
  && echo 'deb-src https://deb.nodesource.com/node wheezy main' >> /etc/apt/sources.list.d/nodesource.list \
  && apt-get update -y && apt-get install -y nodejs

RUN cd /usr/src/couchdb \
  && npm install -g npm \
  && npm install -g grunt-cli \
  && ./configure && make

# permissions
RUN rm -rf /usr/src/couchdb/dev/run
COPY ./run.py /usr/src/couchdb/dev/run
RUN chmod +x /usr/src/couchdb/dev/run
RUN chown -R couchdb:couchdb /usr/src/couchdb

USER couchdb

# Expose to the outside
RUN sed -i'' 's/bind_address = 127.0.0.1/bind_address = 0.0.0.0/' /usr/src/couchdb/rel/overlay/etc/default.ini

EXPOSE 15984 25984 35984
WORKDIR /usr/src/couchdb

ENTRYPOINT ["/usr/src/couchdb/dev/run"]
