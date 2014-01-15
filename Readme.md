YADC
===

Yet Another Dockerized CouchDB.
Put the couch in a docker container and ship it anywhere.

Version: `CouchDB 1.5.0`

## Run

Available in the docker index as [klaemo/couchdb](https://index.docker.io/u/klaemo/couchdb/)

```bash
[sudo] docker pull klaemo/couchdb

# expose it to the world on port 5984
[sudo] docker run -d -p 5984:5984 -name couchdb klaemo/couchdb
```

## Features

* exposes couchdb on port `5984` of the container
* exposes database and config files as [volumes](http://docs.docker.io/en/latest/use/working_with_volumes/)
  * easy to upgrade/fork
  * fast
* keeps couchdb running with `mon` (crashed couch gets restarted automatically)

## TODO

* don't run couch es root once docker fixes permissions for volumes

## Build

You can make your changes to couchdbs config in local.ini.
It will be added to the container.

```bash
cd /path/to/klaemo/docker-couchdb
[sudo] docker build -t "$NAME" .
```
