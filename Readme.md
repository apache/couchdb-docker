YADC
===

Yet Another Dockerized CouchDB.
Put the couch in a docker container and ship it anywhere.

## Build

You can make your changes to couchdbs config in local.ini.
It will be added to the container.

```bash
cd /path/to/klaemo/docker-couchdb
[sudo] docker build -t "$NAME" .
```

## Run

todo

## Further info

* exposed on port 5984 of the container
* exposes database and config files as [volumes](http://docs.docker.io/en/latest/use/working_with_volumes/)
  * makes it easy to upgrade/fork
