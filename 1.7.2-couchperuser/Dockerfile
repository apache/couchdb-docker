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

FROM apache/couchdb:1.7.2

MAINTAINER CouchDB Developers dev@couchdb.apache.org

ENV COUCHPERUSER_SHA 5d28db3272eea9619d4391b33aae6030f0319ecc54aa2a2f2b6c6a8d448f03f2
RUN apt-get update && apt-get install -y rebar make \
 && mkdir -p /usr/local/lib/couchdb/plugins/couchperuser \
 && cd /usr/local/lib/couchdb/plugins \
 && curl -L -o couchperuser.tar.gz https://github.com/etrepum/couchperuser/archive/1.1.0.tar.gz \
 && echo "$COUCHPERUSER_SHA *couchperuser.tar.gz" | sha256sum -c - \
 && tar -xzf couchperuser.tar.gz -C couchperuser --strip-components=1 \
 && rm couchperuser.tar.gz \
 && cd couchperuser \
 && make \
 && apt-get purge -y --auto-remove rebar make
