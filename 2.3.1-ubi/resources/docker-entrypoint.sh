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

# This function will populate the admin user in the docker.ini file using the first argument, the second argument is the password.
function set_admin_credentials {
  adminUser="$1"
  adminPassword="$2"
  # Create admin only if not already present
  if ! grep -Pzoqr "\[admins\]\n$adminUser =" /opt/couchdb/etc/local.d/*.ini /opt/couchdb/etc/local.ini; then
    printf "\n[admins]\n%s = %s\n" "$adminUser" "$adminPassword" >> /opt/couchdb/etc/local.d/docker.ini
  fi
}

# This function populates the chttpd_auth secret in the docker.ini file using the first argument.
function set_http_secret {
  chttpSecret="$1"
  if ! grep -Pzoqr "\[chttpd_auth\]\nsecret =" /opt/couchdb/etc/local.d/*.ini /opt/couchdb/etc/local.ini; then
    printf "\n[chttpd_auth]\nsecret = %s\n" "$chttpSecret" >> /opt/couchdb/etc/local.d/docker.ini
  fi
}

if [ "$1" = '/opt/couchdb/bin/couchdb' ]; then
	# this is where runtime configuration changes will be written.
	# we need to explicitly touch it here in case /opt/couchdb/etc has
	# been mounted as an external volume, in which case it won't exist.
	# If running as the couchdb user (i.e. container starts as root),
	# write permissions will be granted below.
	touch /opt/couchdb/etc/local.d/docker.ini

	# if user is root, assume running under the couchdb user (default)
	# and ensure it is able to access files and directories that may be mounted externally
	if [ "$(id -u)" = '0' ]; then
		# Check that we own everything in /opt/couchdb and fix if necessary. We also
		# add the `-f` flag in all the following invocations because there may be
		# cases where some of these ownership and permissions issues are non-fatal
		# (e.g. a config file owned by root with o+r is actually fine), and we don't
		# to be too aggressive about crashing here ...
		find /opt/couchdb \! \( -user couchdb -group 0 \) -exec chown -f couchdb:0 '{}' +

		# Ensure that data files have the correct permissions. We were previously
		# preventing any access to these files outside of couchdb:couchdb, but it
		# turns out that CouchDB itself does not set such restrictive permissions
		# when it creates the files. The approach taken here ensures that the
		# contents of the datadir have the same permissions as they had when they
		# were initially created. This should minimize any startup delay.
		find /opt/couchdb/data -type d ! -perm 0775 -exec chmod -f 0775 '{}' +
		find /opt/couchdb/data -type f ! -perm 0664 -exec chmod -f 0664 '{}' +

		# Do the same thing for configuration files and directories. Technically
		# CouchDB only needs read access to the configuration files, except "docker.ini" 
		# (created above) as that is where all online changes will be writted. 
		# But we set 664 for the sake of consistency.
		find /opt/couchdb/etc -type d ! -perm 0775 -exec chmod -f 0775 '{}' +
		find /opt/couchdb/etc -type f ! -perm 0664 -exec chmod -f 0664 '{}' +
	fi

	if [ ! -z "$NODENAME" ] && ! grep "couchdb@" /opt/couchdb/etc/vm.args; then
		echo "-name couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
	fi

	if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
    set_admin_credentials "$COUCHDB_USER" "$COUCHDB_PASSWORD"
  elif [ "$COUCHDB_USER_FILE" ] && [ "$COUCHDB_PASSWORD_FILE" ]; then
    if [ -f "$COUCHDB_USER_FILE" ] && [ -f "$COUCHDB_PASSWORD_FILE" ]; then
      adminUser=$(<"$COUCHDB_USER_FILE")
      adminPassword=$(<"$COUCHDB_PASSWORD_FILE")
      set_admin_credentials "$adminUser" "$adminPassword"
    else
      echo "ERROR: COUCHDB_USER_FILE or COUCHDB_PASSWORD_FILE does not exist." >&2
      exit 1
    fi
	fi

	if [ "$COUCHDB_SECRET" ]; then
		# Set secret only if not already present
		set_http_secret "$COUCHDB_SECRET"
  elif [ "$COUCHDB_SECRET_FILE" ]; then
    if [ -f "$COUCHDB_SECRET_FILE" ]; then
      chttpSecret=$(<"$COUCHDB_SECRET_FILE")
      set_http_secret "$chttpSecret"
    else
      echo "ERROR: COUCHDB_SECRET_FILE does not exist." >&2
      exit 1
    fi
	fi

	if [ "$(id -u)" = '0' ]; then
		chown -f couchdb:0 /opt/couchdb/etc/local.d/docker.ini || true
	fi

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

	if [ "$(id -u)" = '0' ]; then
		cat > /etc/service/couchdb/run <<-EOF
			#!/bin/sh
			export HOME=/opt/couchdb
			exec 2>&1
			exec chpst -u couchdb env ERL_FLAGS="$ERL_FLAGS" $@
		EOF
	else
		cat > /etc/service/couchdb/run <<-EOF
			#!/bin/sh
			export HOME=/opt/couchdb
			exec 2>&1
			exec chpst env ERL_FLAGS="$ERL_FLAGS" $@
		EOF
	fi

	exec /sbin/runsvdir-start
fi

exec "$@"
