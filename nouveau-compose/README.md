standard `docker-compose.yml`.

```shell
mkdir -p ./config/couchdb
```

**./config/couchdb/config.ini**
```ini
[couchdb]
single_node=true

[nouveau]
enable = true
url = http://couchdb-nouveau:5987
```

**docker-compose.yml**
*This yaml expose 5984 to the host network, if you already using the 5984 change it on the yaml
```yaml
services:
  couchdb:
    image: couchdb:3.4
    restart: unless-stopped
    ports:
      - 5984:5984
    environment:
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD=admin
    depends_on:
      - couchdb-nouveau
    volumes:
      - couchdb:/opt/couchdb/data
      - ./config/couchdb/config.ini:/opt/couchdb/etc/local.d/config.ini
    healthcheck:
      test: ["CMD-SHELL", "curl --fail -s http://couchdb:5984/_up"]
      interval: 30s
      timeout: 5s
      retries: 5

  couchdb-nouveau:
    image: couchdb:3.4-nouveau
#    ports:
#      - "5987:5987"
#      - "5988:5988"
```

```shell
docker-compose up
```

Check it http://127.0.0.1:5984

The _trick_ is the `./config/couchdb/config.ini` defines the `couchdb-nouveau` to be running on docker network service named `couchdb-nouveau`. So the port (5987) mapped to the nouveau container.

