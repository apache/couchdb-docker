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

FROM debian:wheezy

MAINTAINER Clemens Stolle klaemo@fastmail.fm

ENV COUCHDB_VERSION developer-preview-2.0

RUN groupadd -r couchdb && useradd -d /usr/src/couchdb -g couchdb couchdb

# download dependencies
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends build-essential libmozjs185-dev \
    libnspr4 libnspr4-0d libnspr4-dev libcurl4-openssl-dev libicu-dev \
    openssl curl ca-certificates git pkg-config \
    apt-transport-https python wget

RUN wget http://packages.erlang-solutions.com/site/esl/esl-erlang/FLAVOUR_3_general/esl-erlang_17.0-1~debian~wheezy_amd64.deb
RUN apt-get install -y --no-install-recommends libwxgtk2.8 default-jdk
RUN apt-get install -y --no-install-recommends procps
RUN wget http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb
RUN dpkg -i libssl0.9.8_0.9.8o-4squeeze14_amd64.deb

RUN dpkg -i esl-erlang_17.0-1~debian~wheezy_amd64.deb

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
