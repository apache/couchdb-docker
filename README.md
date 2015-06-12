YADC
===

Yet Another Dockerized CouchDB.
Put the couch in a docker container and ship it anywhere.

If you're looking for a CouchDB with SSL support you can check out [klaemo/couchdb-ssl](https://index.docker.io/u/klaemo/couchdb-ssl/)

- Version (stable): `CouchDB 1.6.1`, `Erlang 17.4`
- Version (dev): `CouchDB 2.0 developer preview`, `Erlang 17.0`

## Run (stable)

Available in the docker index as [klaemo/couchdb](https://index.docker.io/u/klaemo/couchdb/)

```bash
[sudo] docker pull klaemo/couchdb:latest

# expose it to the world on port 5984
[sudo] docker run -d -p 5984:5984 --name couchdb klaemo/couchdb

curl http://localhost:5984
```

## Run (stable with mounted Volume)

```bash
[sudo] docker pull klaemo/couchdb:latest

# expose it to the world on port 5984 and use your current directory as the CouchDB Database directory
[sudo] docker run -d -p 5984:5984 -v $(pwd):/usr/local/var/lib/couchdb --name couchdb klaemo/couchdb

curl http://localhost:5984
```

## Features

* built on top of the solid and small `debian:wheezy` base image
* exposes CouchDB on port `5984` of the container
* runs everything as user `couchdb` (security ftw!)
* docker volumes for data and logs

The previous version of this image used to come with a process manager to keep
CouchDB running. As of Docker 1.2 you can use the `--restart` flag to accomplish this.

## Run (dev)

Available on the docker registry as [klaemo/couchdb:2.0-dev](https://index.docker.io/u/klaemo/couchdb/)

```bash
# expose the cluster to the world
[sudo] docker run -i -t -p 15984:15984 -p 25984:25984 -p 35984:35984 --name couchdb klaemo/couchdb:2.0-dev

curl http://localhost:15984
curl http://localhost:25984
curl http://localhost:35984
```

...or you can pass arguments to the binary

```bash
docker run -i -t klaemo/couchdb:2.0-dev --admin=foo:bar
```

## Build your own

You can use `klaemo/couchdb` as the base image for your own couchdb instance.
You might want to provide your own version of the following files:

* `local.ini` for CouchDB

Example Dockerfile:

```
FROM klaemo/couchdb

COPY local.ini /usr/local/etc/couchdb/
```

and then build and run

```
[sudo] docker build -t you/awesome-couchdb .
[sudo] docker run -d -p 5984:5984 -v ~/couchdb:/usr/local/var/lib/couchdb you/awesome-couchdb
```

## Contributing

Please use Github issues for any questions, bugs, feature requests. :)

## Contributors

- [@joeybaker](https://github.com/joeybaker)
