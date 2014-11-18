YADC
===

Yet Another Dockerized CouchDB.
Put the couch in a docker container and ship it anywhere.

Version: `CouchDB 2.0 developer preview`

## Run

Available on the docker registry as [klaemo/couchdb:2.0-dev](https://index.docker.io/u/klaemo/couchdb/)

```bash
# expose the cluster to the world
[sudo] docker run -d -p 15984:15984 -p 25984:25984 -p 35984:35984 --name couchdb klaemo/couchdb:2.0-dev

curl http://localhost:15984
curl http://localhost:25984
curl http://localhost:35984
```

...or you can pass arguments to the binary

```bash
docker run klaemo/couchdb:2.0-dev --admin=foo:bar
```
