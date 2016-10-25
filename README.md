YADC [![Build Status](https://travis-ci.org/klaemo/docker-couchdb.svg?branch=master)](https://travis-ci.org/klaemo/docker-couchdb)
===

Yet Another Dockerized CouchDB.
Put the couch in a docker container and ship it anywhere.

If you're looking for a CouchDB with SSL support you can check out [klaemo/couchdb-ssl](https://index.docker.io/u/klaemo/couchdb-ssl/)

- Version (stable): `CouchDB 1.6.1`, `Erlang 17.3`
- Version (stable): `CouchDB 2.0.0`, `Erlang 17.3`

## Available tags

- `1`, `1.6`, `1.6.1`: CouchDB 1.6.1
- `1-couchperuser`, `1.6-couchperuser`, `1.6.1-couchperuser`: CouchDB 1.6.1 with couchperuser plugin
- `2.0-dev`: CouchDB 2.0 RC.1 (release vote) with preconfigured dev cluster
- `latest`, `2.0.0`: CouchDB 2.0 single node
- `2.0-dev-docs`: CouchDB 2.0 master (development version) with preconfigured dev cluster and documentation

## Features

* built on top of the solid and small `debian:jessie` base image
* exposes CouchDB on port `5984` of the container
* runs everything as user `couchdb` (security ftw!)
* docker volume for data

## Run (stable)

Available as an official image on Docker Hub as [couchdb](https://hub.docker.com/_/couchdb/)

```bash
[sudo] docker pull klaemo/couchdb:latest

# expose it to the world on port 5984
[sudo] docker run -d -p 5984:5984 --name couchdb couchdb

curl http://localhost:5984
```

...or with mounted volume for the data

```bash
# expose it to the world on port 5984 and use your current directory as the CouchDB Database directory
[sudo] docker run -d -p 5984:5984 -v $(pwd):/usr/local/var/lib/couchdb --name couchdb couchdb
```

If you want to provide your own config, you can either mount a directory at `/usr/local/etc/couchdb`
or extend the image and `COPY` your `config.ini` (see [Build you own](#build-your-own)).

### with couchperuser plugin

This build includes the `couchperuser` plugin.
`couchperuser` is a CouchDB plugin daemon that creates per-user databases [github.com/etrepum/couchperuser](https://github.com/etrepum/couchperuser).

```
[sudo] docker run -d -p 5984:5984 --name couchdb couchdb:1.6.1-couchperuser
```

## Run (dev)

Available on the docker registry as [klaemo/couchdb:latest](https://index.docker.io/u/klaemo/couchdb/).
This is a developer preview of the upcoming CouchDB 2.0 release. A data volume
is exposed on `/opt/couchdb/data`, and the node's port is exposed on `5984`.

Please note that CouchDB no longer autocreates system tables for you, so you will
have to create `_global_changes`, `_metadata`, `_replicator` and `_users` manually.
The node will also start in [admin party mode](http://guide.couchdb.org/draft/security.html#party)!

```bash
# expose it to the world on port 5984 and use your current directory as the CouchDB Database directory
[sudo] docker run -p 5984:5984 -v $(pwd):/opt/couchdb/data klaemo/couchdb:2.0-single
18:54:48.780 [info] Application lager started on node nonode@nohost
18:54:48.780 [info] Application couch_log_lager started on node nonode@nohost
18:54:48.780 [info] Application couch_mrview started on node nonode@nohost
18:54:48.780 [info] Application couch_plugins started on node nonode@nohost
[...]
```

Once running, you can visit the new admin interface at `http://dockerhost:5984/_utils/`

### In a developer cluster

Available on the docker registry as [klaemo/couchdb:2.0-dev](https://index.docker.io/u/klaemo/couchdb/).
This build demonstrates the CouchDB clustering features by creating a local
cluster of a default three nodes inside the container, with a proxy in front.
This is great for testing clustering in your local environment.

```bash
# expose the cluster to the world
[sudo] docker run -it -p 5984:5984 klaemo/couchdb:2.0-dev

[ * ] Setup environment ... ok
[ * ] Ensure CouchDB is built ... ok
[ * ] Prepare configuration files ... ok
[ * ] Start node node1 ... ok
[ * ] Start node node2 ... ok
[ * ] Start node node3 ... ok
[ * ] Check node at http://127.0.0.1:15984/ ... failed: [Errno socket error] [Errno 111] Connection refused
[ * ] Check node at http://127.0.0.1:25984/ ... ok
[ * ] Check node at http://127.0.0.1:35984/ ... ok
[ * ] Check node at http://127.0.0.1:15984/ ... ok
[ * ] Running cluster setup ... ok
[ * ] Developers cluster is set up at http://127.0.0.1:15984.
Admin username: root
Password: 37l7YDQJ
Time to hack! ...
```
**Note:** By default the cluster will be exposed on port `5984`, because it uses haproxy
(passes `--with-haproxy` to `dev/run`) internally.

...but you can pass arguments to the binary

```bash
docker run -it klaemo/couchdb:2.0-dev --admin=foo:bar
```
**Note:** This will overwrite the default `--with-haproxy` flag. The cluster **won't** be exposed on
port `5984` anymore. The individual nodes listen on `15984`, `25984`, ...`x5984`. If you wish to expose
the cluster on `5984`, pass `--with-haproxy` explicitly.

Examples:
```bash
# display the available options of the couchdb startup script
docker run --rm klaemo/couchdb:2.0-dev --help

# Enable admin party 🎉 and expose the cluster on port 5984
docker run -it -p 5984:5984 klaemo/couchdb:2.0-dev --with-admin-party-please --with-haproxy

# Start two nodes (without proxy) exposed on port 15984 and 25984
docker run -it -p 15984:15984 -p 25984:25984 klaemo/couchdb:2.0-dev -n 2
```

## Build your own

You can use `klaemo/couchdb` as the base image for your own couchdb instance.
You might want to provide your own version of the following files:

* `local.ini` for your custom CouchDB config

Example Dockerfile:

```
FROM klaemo/couchdb:latest

COPY local.ini /usr/local/etc/couchdb/
```

and then build and run

```
[sudo] docker build -t you/awesome-couchdb .
[sudo] docker run -d -p 5984:5984 -v ~/couchdb:/usr/local/var/lib/couchdb you/awesome-couchdb
```

For the `2.0-single` image, configuration is stored at `/opt/couchdb/etc/`.

## Feedback, Issues, Contributing

**Please use Github issues for any questions, bugs, feature requests. :)**
I don't get notified about comments on Docker Hub, so I might respond really late...or not at all.

## Contributors

- [@joeybaker](https://github.com/joeybaker)
