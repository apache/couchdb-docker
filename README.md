# Semi-official Apache CouchDB Docker images [![Build Status](https://travis-ci.org/apache/couchdb-docker.svg?branch=master)](https://travis-ci.org/apache/couchdb-docker)

Put the couch in a docker container and ship it anywhere.

- Version (stable): `CouchDB 2.2.0`, `Erlang 19.2.1`

## Available tags

- `latest`, `2.2.0`: CouchDB 2.2.0 single node (capable of running in a cluster)

## Features

* built on top of the solid and small `debian:stretch` base image
* exposes CouchDB on port `5984` of the container
* runs everything as user `couchdb` (security ftw!)
* docker volume for data

## Run

Available on the docker registry as [apache/couchdb:latest](https://hub.docker.com/r/apache/couchdb/).

By default, CouchDB's HTTP interface is exposed on port `5984`. Once running, you can visit the new admin interface at `http://<dockerhost>:5984/_utils/`

CouchDB uses `/opt/couchdb/data` to store its data, and is exposed as a volume.

Here is an example launch line for a single-node CouchDB with an admin username and password of `admin` and `password`, exposed to the world on port `5984`:

```bash
$ docker run -p 5984:5984 --volume ~/data:/opt/couchdb/data --volume ~/etc/local.d:/opt/couchdb/etc/local.d --env COUCHDB_USER=admin --env COUCHDB_PASSWORD=password apache/couchdb:2.1.1
18:54:48.780 [info] Application lager started on node nonode@nohost
18:54:48.780 [info] Application couch_log_lager started on node nonode@nohost
18:54:48.780 [info] Application couch_mrview started on node nonode@nohost
18:54:48.780 [info] Application couch_plugins started on node nonode@nohost
```
### Detailed configuration

CouchDB uses `/opt/couchdb/etc/local.d` to store its configuration. It is highly recommended to bind map this to an external directory, to persist the configuration across restarts.

CouchDB also uses `/opt/couchdb/etc/vm.args` to store Erlang runtime-specific changes. Changing these values is less common. If you need to change the epmd port, for instance, you will want to bind mount this file as well. (Note: files cannot be bind-mounted on Windows hosts.)

In addition, a few environment variables are provided to set very common parameters:

* `COUCHDB_USER` and `COUCHDB_PASSWORD` will create an ini-file based local admin user with the given username and password in the file `/opt/couchdb/etc/local.d/docker.ini`.
* `COUCHDB_SECRET` will set the CouchDB shared cluster secret value, in the file `/opt/couchdb/etc/local.d/docker.ini`.
* `NODENAME` will set the name of the CouchDB node inside the container to `couchdb@${NODENAME}`, in the file `/opt/couchdb/etc/vm.args`. This is used for clustering purposes and can be ignored for single-node setups.
* Erlang Environment Variables like `ELR_FLAGS` will be used by Erlang itself. For a complete list have a look [here](http://erlang.org/doc/man/erl.html#environment-variables)

If other configuration settings are desired, externally mount `/opt/couchdb/etc` and provide `.ini` configuration files under the `/opt/couchdb/etc/local.d` directory.

For a CouchDB cluster you need to provide the `NODENAME` setting as well as the erlang cookie. Settings to Erlang can be made with the environment variable `ERL_FLAGS`, e.g. `ERL_FLAGS=-setcookie "brumbrum"`. Further information can be found [here](http://docs.couchdb.org/en/stable/cluster/setup.html).

### Important notes

Please note that CouchDB no longer autocreates system databases for you. This is intentional; multi-node CouchDB deployments must be joined into a cluster before creating these databases.

You must create `_global_changes`, `_metadata`, `_replicator` and `_users` after the cluster has been fully configured. (The Fauxton UI has a "Setup" wizard that does this for you.)

The node will also start in [admin party mode](http://guide.couchdb.org/draft/security.html#party)!

Note also that port 5986 is not exposed, as this can present *significant* security risks. We recommend either connecting to the node directly to access this port, via `docker exec -it <instance> /bin/bash` and accessing port 5986, or use of `--expose 5986` when launching the container, but **ONLY** if you do not expose this port publicly. Port 5986 is scheduled to be removed with the 3.x release series.

## Development images

This repository provides definitions to run the very latest (`master` branch)
CouchDB code:

* `dev` runs a single node off of the `master` branch, similar to the other
  officially released images.
* `dev-cluster` demonstrates the CouchDB clustering features by creating a
  local cluster of a default three nodes inside the container, with a proxy in
  front.  This is great for testing clustering in your local environment.

You will need to build Docker images from the `dev` directory in this
repository; [Apache Software Foundation policy][4] prevents us from publishing
non-release builds for wide distribution.

When launching the `dev-cluster` container, here is what you will see:

```bash
# expose the cluster to the world
$ docker run -it -p 5984:5984 <image-hash>

[ * ] Setup environment ... ok
[ * ] Ensure CouchDB is built ... ok
[ * ] Prepare configuration files ... ok
[ * ] Start node node1 ... ok
[ * ] Start node node2 ... ok
[ * ] Start node node3 ... ok
[ * ] Check node at http://127.0.0.1:15984/ ... ok
[ * ] Check node at http://127.0.0.1:25984/ ... ok
[ * ] Check node at http://127.0.0.1:35984/ ... ok
[ * ] Running cluster setup ... ok
[ * ] Developers cluster is set up at http://127.0.0.1:15984.
Admin username: root
Password: 37l7YDQJ
Time to hack! ...
```
**Note:** By default the cluster will be exposed on port `5984`, because it uses haproxy (passes `--with-haproxy` to `dev/run`) internally.

You can pass arguments to the binary:

```bash
docker run -it <image-hash> --admin=foo:bar
```

**Note:** This will overwrite the default `--with-haproxy` flag. The cluster **won't** be exposed on
port `5984` anymore. The individual nodes listen on `15984`, `25984`, ...`x5984`. If you wish to expose
the cluster on `5984`, pass `--with-haproxy` explicitly.

More examples:
```bash
# display the available options of the couchdb startup script
docker run --rm <image-hash> --help

# Enable admin party and expose the cluster on port 5984
docker run -it -p 5984:5984 <image-hash> --with-admin-party-please --with-haproxy

# Start two nodes (without proxy) exposed on port 15984 and 25984
docker run -it -p 15984:15984 -p 25984:25984 <image-hash> -n 2
```

## Build your own

You can use `apache/couchdb` as the base image for your own couchdb instance.
You might want to provide your own version of the following files:

* `local.ini` for your custom CouchDB config

Example Dockerfile:

```
FROM apache/couchdb:latest

COPY 99-local.ini /opt/couchdb/etc/local.d
```

and then build and run

```
[sudo] docker build -t you/awesome-couchdb .
[sudo] docker run -d -p 5984:5984 -v ~/couchdb:/usr/local/var/lib/couchdb you/awesome-couchdb
```

## Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project. In short,
use GitHub Issues, do not report anything on Docker's website.

## Contributors

- [@klaemo](https://github.com/klaemo)
- [@joeybaker](https://github.com/joeybaker)
- [@tianon](https://github.com/tianon)

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md
[4]: http://www.apache.org/dev/release-distribution.html#unreleased
