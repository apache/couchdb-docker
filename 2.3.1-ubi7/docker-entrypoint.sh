#!/bin/bash
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

set -e

# first arg is `-something` or `+something`
if [ "${1#-}" != "$1" ] || [ "${1#+}" != "$1" ]; then
	set -- /opt/couchdb/bin/couchdb "$@"
fi

# first arg is the bare word `couchdb`
if [ "$1" = 'couchdb' ]; then
	shift
	set -- /opt/couchdb/bin/couchdb "$@"
fi

if [ "$1" = '/opt/couchdb/bin/couchdb' ]; then
	# Check that we own everything in /opt/couchdb and fix if necessary. We also
	# add the `-f` flag in all the following invocations because there may be
	# cases where some of these ownership and permissions issues are non-fatal
	# (e.g. a config file owned by root with o+r is actually fine), and we don't
	# to be too aggressive about crashing here ...
	find /opt/couchdb \! \( -user couchdb -group couchdb \) -exec chown -f couchdb:couchdb '{}' +

	# Ensure that data files have the correct permissions. We were previously
	# preventing any access to these files outside of couchdb:couchdb, but it
	# turns out that CouchDB itself does not set such restrictive permissions
	# when it creates the files. The approach taken here ensures that the
	# contents of the datadir have the same permissions as they had when they
	# were initially created. This should minimize any startup delay.
	find /opt/couchdb/data -type d ! -perm 0755 -exec chmod -f 0755 '{}' +
	find /opt/couchdb/data -type f ! -perm 0644 -exec chmod -f 0644 '{}' +

	# Do the same thing for configuration files and directories. Technically
	# CouchDB only needs read access to the configuration files as all online
	# changes will be applied to the "docker.ini" file below, but we set 644
	# for the sake of consistency.
	find /opt/couchdb/etc -type d ! -perm 0755 -exec chmod -f 0755 '{}' +
	find /opt/couchdb/etc -type f ! -perm 0644 -exec chmod -f 0644 '{}' +

	if [ ! -z "$NODENAME" ] && ! grep "couchdb@" /opt/couchdb/etc/vm.args; then
		echo "-name couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
	fi

	# Ensure that CouchDB will write custom settings in this file
	touch /opt/couchdb/etc/local.d/docker.ini

	if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
		# Create admin only if not already present
		if ! grep -Pzoqr "\[admins\]\n$COUCHDB_USER =" /opt/couchdb/etc/local.d/*.ini; then
			printf "\n[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" >> /opt/couchdb/etc/local.d/docker.ini
		fi
	fi

	if [ "$COUCHDB_SECRET" ]; then
		# Set secret only if not already present
		if ! grep -Pzoqr "\[couch_httpd_auth\]\nsecret =" /opt/couchdb/etc/local.d/*.ini; then
			printf "\n[couch_httpd_auth]\nsecret = %s\n" "$COUCHDB_SECRET" >> /opt/couchdb/etc/local.d/docker.ini
		fi
	fi

	chown -f couchdb:couchdb /opt/couchdb/etc/local.d/docker.ini || true

	# if we don't find an [admins] section followed by a non-comment, display a warning
        if ! grep -Pzoqr '\[admins\]\n[^;]\w+' /opt/couchdb/etc/default.d/*.ini /opt/couchdb/etc/local.d/*.ini; then
		# The - option suppresses leading tabs but *not* spaces. :)
		cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: CouchDB is running in Admin Party mode.
			         This will allow anyone with access to the
			         CouchDB port to access your database. In
			         Docker's default configuration, this is
			         effectively any other container on the same
			         system.
			         Use "-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password"
			         to set it in "docker run".
			****************************************************
		EOWARN
	fi


	exec gosu couchdb "$@"
fi

exec "$@"
