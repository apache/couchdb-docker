# Semi-official Apache CouchDB Docker images [![Build Status](https://travis-ci.org/apache/couchdb-docker.svg?branch=master)](https://travis-ci.org/apache/couchdb-docker)

Put the couch in a docker container and ship it anywhere.

If you're looking for a CouchDB with SSL support you can check out [klaemo/couchdb-ssl](https://index.docker.io/u/klaemo/couchdb-ssl/)

- Version (stable): `CouchDB 1.7.0`, `Erlang 17.3`
- Version (stable): `CouchDB 2.1.1`, `Erlang 17.3`

## Available tags

- `1.7.0`: CouchDB 1.7.0
- `1.7.0-couchperuser`: CouchDB 1.7.0 with couchperuser plugin
- `latest`, `2.1.1`: CouchDB 2.1.1 single node (capable of running in a cluster)

## Features

* built on top of the solid and small `debian:jessie` base image
* exposes CouchDB on port `5984` of the container
* runs everything as user `couchdb` (security ftw!)
* docker volume for data

## Run (latest/2.1.1)

Available on the docker registry as [apache/couchdb:latest](https://hub.docker.com/r/apache/couchdb/).
This is a build of the CouchDB 2.1 release. A data volume
is exposed on `/opt/couchdb/data`, and the node's port is exposed on `5984`.

Please note that CouchDB no longer autocreates system tables for you, so you will
have to create `_global_changes`, `_metadata`, `_replicator` and `_users` manually (the admin interface has a "Setup" menu that does this for you).
The node will also start in [admin party mode](http://guide.couchdb.org/draft/security.html#party)!

```bash
# expose it to the world on port 5984 and use your current directory as the CouchDB Database directory
[sudo] docker run -p 5984:5984 -v $(pwd):/opt/couchdb/data apache/couchdb
18:54:48.780 [info] Application lager started on node nonode@nohost
18:54:48.780 [info] Application couch_log_lager started on node nonode@nohost
18:54:48.780 [info] Application couch_mrview started on node nonode@nohost
18:54:48.780 [info] Application couch_plugins started on node nonode@nohost
[...]
```

Note that you can also use the NODENAME environment variable to set the name of the CouchDB node inside the container.
Once running, you can visit the new admin interface at `http://dockerhost:5984/_utils/`

Note also that port 5986 is not exposed, as this can present *significant* security risks. We recommend either connecting to the node directly to access this port, via `docker exec -it <instance> /bin/bash` and accessing port 5986, or use of `--expose 5986` when launching the container, but **ONLY** if you do not expose this port publicly.

## Run (1.7.0)

Available as an official image on Docker Hub as [apache/couchdb:1.7.0](https://hub.docker.com/r/apache/couchdb/)

```bash
[sudo] docker pull apache/couchdb:1.7.0

# expose it to the world on port 5984
[sudo] docker run -d -p 5984:5984 --name couchdb apache/couchdb:1.7.0

curl http://localhost:5984
```

...or with mounted volume for the data

```bash
# expose it to the world on port 5984 and use your current directory as the CouchDB Database directory
[sudo] docker run -d -p 5984:5984 -v $(pwd):/usr/local/var/lib/couchdb --name couchdb apache/couchdb:1.7.0
```

If you want to provide your own config, you can either mount a directory at `/usr/local/etc/couchdb`
or extend the image and `COPY` your `config.ini` (see [Build you own](#build-your-own)).

If you need (or want) to run couchdb in `net=host` mode, you can customize the port and bind address using environment variables:

 - `COUCHDB_HTTP_BIND_ADDRESS` (default: `0.0.0.0`)
 - `COUCHDB_HTTP_PORT` (default: `5984`)

### with couchperuser plugin

This build includes the `couchperuser` plugin.
`couchperuser` is a CouchDB plugin daemon that creates per-user databases [github.com/etrepum/couchperuser](https://github.com/etrepum/couchperuser).

```
[sudo] docker run -d -p 5984:5984 --name couchdb apache/couchdb:1.7.0-couchperuser
```

### In a developer cluster

This build demonstrates the CouchDB clustering features by creating a local
cluster of a default three nodes inside the container, with a proxy in front.
This is great for testing clustering in your local environment.

You will need to build Docker images from the `dev` directory in this
repository; [Apache Software Foundation policy][4] prevents us from publishing
non-release builds for wide distribution.

```bash
# expose the cluster to the world
[sudo] docker run -it -p 5984:5984 <image-hash>

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
**Note:** By default the cluster will be exposed on port `5984`, because it uses haproxy
(passes `--with-haproxy` to `dev/run`) internally.

...but you can pass arguments to the binary

```bash
docker run -it <image-hash> --admin=foo:bar
```
**Note:** This will overwrite the default `--with-haproxy` flag. The cluster **won't** be exposed on
port `5984` anymore. The individual nodes listen on `15984`, `25984`, ...`x5984`. If you wish to expose
the cluster on `5984`, pass `--with-haproxy` explicitly.

Examples:
```bash
# display the available options of the couchdb startup script
docker run --rm <image-hash> --help

# Enable admin party 🎉 and expose the cluster on port 5984
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

COPY local.ini /usr/local/etc/couchdb/local.d/
```

and then build and run

```
[sudo] docker build -t you/awesome-couchdb .
[sudo] docker run -d -p 5984:5984 -v ~/couchdb:/usr/local/var/lib/couchdb you/awesome-couchdb
```

For the `2.1` image, configuration is stored at `/opt/couchdb/etc/`.

## Feedback, Issues, Contributing

General feedback is welcome at our [user][1] or [developer][2] mailing lists.

Apache CouchDB has a [CONTRIBUTING][3] file with details on how to get started
with issue reporting or contributing to the upkeep of this project. In short,
use GitHub Issues, do not report anything on Docker's website.

## Contributors

- [@klaemo](https://github.com/klaemo)
- [@joeybaker](https://github.com/joeybaker)

[1]: http://mail-archives.apache.org/mod_mbox/couchdb-user/
[2]: http://mail-archives.apache.org/mod_mbox/couchdb-dev/
[3]: https://github.com/apache/couchdb/blob/master/CONTRIBUTING.md
[4]: http://www.apache.org/dev/release-distribution.html#unreleased
