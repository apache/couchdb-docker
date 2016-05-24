YADC [![Build Status](https://travis-ci.org/klaemo/docker-couchdb.svg?branch=master)](https://travis-ci.org/klaemo/docker-couchdb)
===

Yet Another Dockerized CouchDB.
Put the couch in a docker container and ship it anywhere.

If you're looking for a CouchDB with SSL support you can check out [klaemo/couchdb-ssl](https://index.docker.io/u/klaemo/couchdb-ssl/)

- Version (stable): `CouchDB 1.6.1`, `Erlang 17.3`
- Version (dev): `CouchDB 2.0 master`, `Erlang 17.3`

## Available tags

- `1`, `1.6`, `1.6.1`, `latest`: CouchDB 1.6.1
- `1-couchperuser`, `1.6-couchperuser`, `1.6.1-couchperuser`: CouchDB 1.6.1 with couchperuser plugin
- `2.0-dev`: CouchDB 2.0 master (development version)
- `2.0-dev-docs`: CouchDB 2.0 master (development version) with documentation

## Features

* built on top of the solid and small `debian:jessie` base image
* exposes CouchDB on port `5984` of the container
* runs everything as user `couchdb` (security ftw!)
* docker volume for data

## Run (stable)

Available as a trusted build on Docker Hub as [klaemo/couchdb](https://hub.docker.com/r/klaemo/couchdb/)

```bash
[sudo] docker pull klaemo/couchdb:latest

# expose it to the world on port 5984
[sudo] docker run -d -p 5984:5984 --name couchdb klaemo/couchdb

curl http://localhost:5984
```

...or with mounted volume for the data

```bash
# expose it to the world on port 5984 and use your current directory as the CouchDB Database directory
[sudo] docker run -d -p 5984:5984 -v $(pwd):/usr/local/var/lib/couchdb --name couchdb klaemo/couchdb
```

If you want to provide your own config, you can either mount a directory at `/usr/local/etc/couchdb`
or extend the image and `COPY` your `config.ini` (see [Build you own](#build-your-own)).

### with couchperuser plugin

This build includes the `couchperuser` plugin.
`couchperuser` is a CouchDB plugin daemon that creates per-user databases [github.com/etrepum/couchperuser](https://github.com/etrepum/couchperuser).

```
[sudo] docker run -d -p 5984:5984 --name couchdb klaemo/couchdb:1.6.1-couchperuser
```

## Run (dev)

Available on the docker registry as [klaemo/couchdb:2.0-dev](https://index.docker.io/u/klaemo/couchdb/)

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

## Feedback, Issues, Contributing

**Please use Github issues for any questions, bugs, feature requests. :)**
I don't get notified about comments on Docker Hub, so I might respond really late...or not at all.

## Contributors

- [@joeybaker](https://github.com/joeybaker)
