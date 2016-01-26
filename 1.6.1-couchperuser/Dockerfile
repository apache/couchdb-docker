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

FROM klaemo/couchdb:1.6.1

MAINTAINER Clemens Stolle klaemo@apache.org

RUN apt-get update && apt-get install -y rebar build-essential \
 && mkdir -p /usr/local/lib/couchdb/plugins/couchperuser \
 && cd /usr/local/lib/couchdb/plugins/couchperuser \
 && curl -L https://github.com/etrepum/couchperuser/archive/1.1.0.tar.gz | tar -xz --strip-components=1 \
 && make \
 && apt-get purge -y rebar build-essential \
 && apt-get autoremove -y
