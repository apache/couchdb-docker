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
* exposes database and log files as [volumes](http://docs.docker.io/en/latest/use/working_with_volumes/)
  * easy to upgrade/fork
  * ability to access the data from other containers for backups, log handling etc
* runs everything as user `couchdb` (security ftw!)
* keeps couchdb running with `mon` (reliability ftw!)

## Build

You can make your changes to couchdbs config in local.ini.
It will be added to the container.

```bash
cd /path/to/klaemo/docker-couchdb
[sudo] docker build -t "$NAME" .
```

or use it as a base image for your own config