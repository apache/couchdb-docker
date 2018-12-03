# Semi-official Apache CouchDB Docker images [![Build Status](https://travis-ci.org/apache/couchdb-docker.svg?branch=master)](https://travis-ci.org/apache/couchdb-docker)

- Version (stable): `CouchDB 2.2.0`, `Erlang 19.3.5`

## Available tags

- `latest`, `2.2.0`: CouchDB 2.2.0 single node (capable of running in a cluster)

## Features

* built on top of the solid and small `debian:stretch-slim` base image
* exposes CouchDB on port `5984` of the container
* runs everything as user `couchdb` (security ftw!)
* docker volumes for data and config

## Run

Available on the docker registry as [apache/couchdb:latest](https://hub.docker.com/r/apache/couchdb/).

By default, CouchDB's HTTP interface is exposed on port `5984`. Once running, you can visit the new admin interface at `http://<dockerhost>:5984/_utils/`

CouchDB uses `/opt/couchdb/data` to store its data, and is exposed as a volume.

CouchDB uses `/opt/couchdb/etc/local.d` to store its configuration files, and is exposed as a volume.

Here is an example launch line for a single-node CouchDB with an admin username and password of `admin` and `password`, exposed to the world on port `5984`:

```bash
$ docker run -p 5984:5984 --volume ~/data:/opt/couchdb/data --volume ~/etc/local.d:/opt/couchdb/etc/local.d --env COUCHDB_USER=admin --env COUCHDB_PASSWORD=password apache/couchdb:2.2.0
[info] 2018-12-03T23:13:27.817076Z nonode@nohost <0.9.0> -------- Application couch_log started on node nonode@nohost
[info] 2018-12-03T23:13:27.826886Z nonode@nohost <0.9.0> -------- Application folsom started on node nonode@nohost
[info] 2018-12-03T23:13:27.902074Z nonode@nohost <0.9.0> -------- Application couch_stats started on node nonode@nohost
[info] 2018-12-03T23:13:27.902263Z nonode@nohost <0.9.0> -------- Application khash started on node nonode@nohost
[info] 2018-12-03T23:13:27.915398Z nonode@nohost <0.9.0> -------- Application couch_event started on node nonode@nohost
[info] 2018-12-03T23:13:27.915545Z nonode@nohost <0.9.0> -------- Application hyper started on node nonode@nohost
[info] 2018-12-03T23:13:27.926134Z nonode@nohost <0.9.0> -------- Application ibrowse started on node nonode@nohost
[info] 2018-12-03T23:13:27.937730Z nonode@nohost <0.9.0> -------- Application ioq started on node nonode@nohost
[info] 2018-12-03T23:13:27.937887Z nonode@nohost <0.9.0> -------- Application mochiweb started on node nonode@nohost
[info] 2018-12-03T23:13:27.953558Z nonode@nohost <0.198.0> -------- Apache CouchDB 2.2.0 is starting.

[info] 2018-12-03T23:13:27.953626Z nonode@nohost <0.199.0> -------- Starting couch_sup
[notice] 2018-12-03T23:13:28.038617Z nonode@nohost <0.86.0> -------- config: [features] pluggable-storage-engines set to true for reason nil
[notice] 2018-12-03T23:13:28.054010Z nonode@nohost <0.86.0> -------- config: [admins] admin set to -pbkdf2-6cc5b71480085c5b31429d1374cff8de7ec1df3a,7d366ab9d34caf8903f4f11cdaf5e65c,10 for reason nil
[notice] 2018-12-03T23:13:28.098765Z nonode@nohost <0.86.0> -------- config: [couchdb] uuid set to bf7d73c802f7dbf9bb0cfd668dd94504 for reason nil
[info] 2018-12-03T23:13:28.348952Z nonode@nohost <0.198.0> -------- Apache CouchDB has started. Time to relax.
```
### Detailed configuration

CouchDB uses `/opt/couchdb/etc/local.d` to store its configuration. It is highly recommended to use a volume or bind mount for this path to persist the configuration across restarts.

CouchDB also uses `/opt/couchdb/etc/vm.args` to store Erlang runtime-specific changes. Changing these values is less common. If you need to change the epmd port, for instance, you will want to bind mount this file as well. (Note: files cannot be bind-mounted on Windows hosts.)

In addition, a few environment variables are provided to set very common parameters:

* `COUCHDB_USER` and `COUCHDB_PASSWORD` will create an ini-file based local admin user with the given username and password in the file `/opt/couchdb/etc/local.d/docker.ini`.
* `COUCHDB_SECRET` will set the CouchDB shared cluster secret value, in the file `/opt/couchdb/etc/local.d/docker.ini`.
* `NODENAME` will set the name of the CouchDB node inside the container to `couchdb@${NODENAME}`, in the file `/opt/couchdb/etc/vm.args`. This is used for clustering purposes and can be ignored for single-node setups.
* Erlang Environment Variables like `ERL_FLAGS` will be used by Erlang itself. For a complete list have a look [here](http://erlang.org/doc/man/erl.html#environment-variables)

If other configuration settings are desired, externally mount the entire `/opt/couchdb/etc` path and provide `.ini` configuration files under the `/opt/couchdb/etc/local.d` directory. *Note that this will prevent you from getting important updates to the `default.ini` file when upgrading your CouchDB version. You have been warned.*

For a CouchDB cluster you need to provide the `NODENAME` setting as well as the erlang cookie. Settings to Erlang can be made with the environment variable `ERL_FLAGS`, e.g. `ERL_FLAGS=-setcookie "brumbrum"`. Further information can be found [here](http://docs.couchdb.org/en/stable/cluster/setup.html).

### Important notes

Please note that CouchDB no longer autocreates system databases for you. This is intentional; multi-node CouchDB deployments must be joined into a cluster before creating these databases.

You must create `_global_changes`, `_metadata`, `_replicator` and `_users` after the cluster has been fully configured. (The Fauxton UI has a "Setup" wizard that does this for you.)

The node will also start in [admin party mode](http://guide.couchdb.org/draft/security.html#party)!

Note also that port 5986 is not exposed, as this can present **significant** security risks. We recommend either connecting to the node directly to access this port, via `docker exec -it <instance> /bin/bash` and accessing port 5986, or use of `--expose 5986` when launching the container, but **ONLY** if you do not expose this port publicly. Port 5986 is scheduled to be removed in CouchDB 3.0.

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

## Non-Apache CouchDB Development Team Contributors

- [@klaemo](https://github.com/klaemo)
- [@joeybaker](https://github.com/joeybaker)
- [@tianon](https://github.com/tianon)

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md
[4]: http://www.apache.org/dev/release-distribution.html#unreleased
