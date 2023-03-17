# Semi-official Apache CouchDB Docker images

## Available tags

There may be more tags available, but these tags should always exist:

- `latest`: Always the latest version
- `3`: The very latest CouchDB 3.x single node release (capable of running in a cluster)
- `2`: The very latest CouchDB 2.x single node release (capable of running in a cluster)

As of this writing, the latest numbered tags available are:
- `3.3.1`
- `3.3.0`
- `3.2.2`
- `3.2.1`
- `3.2.0`
- `3.1.2`
- `2.3.1`

# How to use this image

The most up-to-date instructions on using this image are always available at https://github.com/apache/couchdb-docker/blob/master/README.md .

## Start a CouchDB instance

Starting a CouchDB instance is simple:

```console
$ docker run -d --name my-couchdb -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password %%IMAGE%%:tag
```

where `my-couchdb` is the name you want to assign to your container, and `tag` is the tag specifying the CouchDB version you want. See the list above for relevant tags.

**As of CouchDB 3.0, an admin user and password is required for CouchDB startup.** Specify these on the command line as shown, or overlay your own ini file with a pre-defined admin user (see below).

## Connect to CouchDB from an application in another Docker container

This image exposes the standard CouchDB port `5984`, so standard container linking will make it automatically available to the linked containers. Start your application container like this in order to link it to the CouchDB container:

```console
$ docker run --name my-couchdb-app --link my-%%REPO%%:%%REPO%% -d app-that-uses-couchdb
```

## Exposing CouchDB to the outside world

If you want to expose the port to the outside world, run

```console
$ docker run -p 5984:5984 -d %%IMAGE%%
```

If you intend to network this CouchDB instance with others in a cluster, you will need to map additional ports; see the [official CouchDB documentation](http://docs.couchdb.org/en/stable/setup/cluster.html) for details.

## Make a cluster

Start your multiple CouchDB instances, then follow the Setup Wizard in the [official CouchDB documentation](http://docs.couchdb.org/en/stable/setup/cluster.html) to complete the process.

For a CouchDB cluster you need to provide the `NODENAME` setting as well as the
Erlang distribution cookie. The current version of this image allows the Erlang
cookie to be set directly using the `COUCHDB_ERLANG_COOKIE` environment
variable. The contents of that environment variable will be written to
`/opt/couchdb/.erlang.cookie` with the proper permissions. Previously one would
need to provide the `-setcookie` flag in the environment variable `ERL_FLAGS`,
e.g. `ERL_FLAGS=-setcookie "brumbrum"`.

By default, this image exposes the `epmd` port `4369` and the Erlang cluster communication port `9100` (i.e. `inet_dist_listen_min` and `inet_dist_listen_max` are both 9100).
Further information can be found [here](http://docs.couchdb.org/en/stable/cluster/setup.html).

There is also a [Kubernetes helm chart](https://github.com/helm/charts/tree/master/incubator/couchdb) available.

## Container shell access, `remsh`, and viewing logs

The `docker exec` command allows you to run commands inside a Docker container. The following command line will give you a bash shell inside your `%%REPO%%` container:

```console
$ docker exec -it my-%%REPO%% bash
```

If you need direct access to the Erlang runtime:

```console
$ docker exec -it my-%%REPO%% /opt/couchdb/bin/remsh
```

The CouchDB log is available through Docker's container log:

```console
$ docker logs my-%%REPO%%
```

## Configuring CouchDB

The best way to provide configuration to the `%%REPO%%` image is to provide a custom `ini` file to CouchDB, preferably stored in the `/opt/couchdb/etc/local.d/` directory. There are many ways to provide this file to the container (via short `Dockerfile` with `FROM` + `COPY`, via [Docker Configs](https://docs.docker.com/engine/swarm/configs/), via runtime bind-mount, etc), the details of which are left as an exercise for the reader.

Keep in mind that run-time reconfiguration of CouchDB will overwrite the [last file in the configuration chain](http://docs.couchdb.org/en/stable/config/intro.html#configuration-files), and that this Docker container creates the `/opt/couchdb/etc/local.d/docker.ini` file at startup.

CouchDB also uses `/opt/couchdb/etc/vm.args` to store Erlang runtime-specific changes. Changing these values is less common. If you need to change the epmd port, for instance, you will want to bind mount this file as well. (Note: files cannot be bind-mounted on Windows hosts.)

In addition, a few environment variables are provided to set very common parameters:

* `COUCHDB_USER` and `COUCHDB_PASSWORD` will create an ini-file based local admin user with the given username and password in the file `/opt/couchdb/etc/local.d/docker.ini`.
* `COUCHDB_SECRET` will set the CouchDB shared cluster secret value, in the file `/opt/couchdb/etc/local.d/docker.ini`.
* `NODENAME` will set the name of the CouchDB node inside the container to `couchdb@${NODENAME}`, in the file `/opt/couchdb/etc/vm.args`. This is used for clustering purposes and can be ignored for single-node setups.
* Erlang Environment Variables like `ERL_FLAGS` will be used by Erlang itself. For a complete list have a look [here](http://erlang.org/doc/man/erl.html#environment-variables)


# Caveats

## Where to Store Data

Important note: There are several ways to store data used by applications that run in Docker containers. We encourage users of the `%%REPO%%` images to familiarize themselves with the options available, including:

-	Let Docker manage the storage of your database data [by writing the database files to disk on the host system using its own internal volume management](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
-	Create a data directory on the host system (outside the container) and [mount this to a directory visible from inside the container](https://docs.docker.com/engine/tutorials/dockervolumes/#mount-a-host-directory-as-a-data-volume). This places the database files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists, and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

The Docker documentation is a good starting point for understanding the different storage options and variations, and there are multiple blogs and forum postings that discuss and give advice in this area. We will simply show the basic procedure here for the latter option above:

1. Create a data directory on a suitable volume on your host system, e.g. `/home/couchdb/data`.
2. Start your `%%REPO%%` container like this:

```bash
$ docker run --name some-%%REPO%% -v /home/couchdb/data:/opt/couchdb/data -d %%IMAGE%%:tag
```

The `-v /home/couchdb/data:/opt/couchdb/data` part of the command mounts the `/home/couchdb/data` directory from the underlying host system as `/opt/couchdb/data` inside the container, where CouchDB by default will write its data files.

## No system databases until the installation is finalized

Please note that CouchDB no longer autocreates system databases for you, as it is not known at startup time if this is a single-node or clustered CouchDB installation. In a cluster, the databases must only be created once all nodes have been joined together.

If you use the [Cluster Setup Wizard](http://docs.couchdb.org/en/stable/setup/cluster.html#the-cluster-setup-wizard) or the [Cluster Setup API](http://docs.couchdb.org/en/stable/setup/cluster.html#the-cluster-setup-api), these databases will be created for you when you complete the process.

If you choose not to use the Cluster Setup wizard or API, you will have to create `_global_changes`, `_replicator` and `_users` manually.

## Administrator user

**CouchDB 3.0+ requires an admin user to start!**

You can use the two environment variables `COUCHDB_USER` and `COUCHDB_PASSWORD` to set up an admin user:

```console
$ docker run -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password -d %%IMAGE%%
```

Note that if you are setting up a clustered CouchDB, you will want to pre-hash this password and use the identical hashed text across all nodes to ensure sessions work correctly when a load balancer is placed in front of the cluster. Hashing can be accomplished by running the container with the `/opt/couchdb/etc/local.d` directory mounted as a volume, allowing CouchDB to hash the password you set, then copying out the hashed version and using this value in the future.

## Using a persistent CouchDB configuration file

The CouchDB configuration is specified in `.ini` files in `/opt/couchdb/etc`. Take a look at the [CouchDB configuration documentation](http://docs.couchdb.org/en/stable/config/index.html) to learn more about CouchDB's configuration structure.

If you want to use a customized CouchDB configuration, you can create your configuration file in a directory on the host machine and then mount that directory as `/opt/couchdb/etc/local.d` inside the `%%REPO%%` container.

```console
$ docker run --name my-couchdb -v /home/couchdb/etc:/opt/couchdb/etc/local.d -d %%IMAGE%%
```

The `-v /home/couchdb/etc:/opt/couchdb/etc/local.d` part of the command mounts the `/home/couchdb/etc` directory from the underlying host system as `/opt/couchdb/etc/local.d` inside the container, where CouchDB by default will write its dynamic configuration files.

You can also use `couchdb` as the base image for your own couchdb instance and provide your own version of the `local.ini` config file:

Example Dockerfile:

```dockerfile
FROM %%IMAGE%%

COPY local.ini /opt/couchdb/etc/
```

and then build and run

```console
$ docker build -t you/awesome-couchdb .
$ docker run -d -p 5984:5984 you/awesome-couchdb
```

Remember that, with this approach, any newly written changes will still appear in the `/opt/couchdb/etc/local.d` directory, so it is still recommended to map this to a host path for persistence.

## Logging

By default containers run from this image only log to `stdout`. You can enable logging to file in the [configuration](http://docs.couchdb.org/en/2.1.0/config/logging.html).

For example in `local.ini`:

```ini
[log]
writer = file
file = /opt/couchdb/log/couch.log
```

It is recommended to then mount this path to a directory on the host, as CouchDB logging can be quite voluminous.

## Running under a custom UID

By default, CouchDB will run as the `couchdb` user with UID 5984. Running under a different UID is supported, so long as any volume mounts have appropriate read/write permissions. For example, assuming user `myuser` has write access to `/home/couchdb/data`, the following command will run CouchDB as that user:

```
docker run --name my-couchdb --user myuser -v /home/couchdb/data:/opt/couchdb/data %%IMAGE%%:tag
```


-----

# Development images

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

**Note:** This will overwrite the default `--with-haproxy` flag. The cluster **won't** be exposed on port `5984` anymore. The individual nodes listen on `15984`, `25984`, ...`x5984`. If you wish to expose the cluster on `5984`, pass `--with-haproxy` explicitly.

More examples for the `dev` image only:
```bash
# display the available options of the couchdb startup script
docker run --rm <image-hash> --help

# Start two nodes (without proxy) exposed on port 15984 and 25984
docker run -it -p 15984:15984 -p 25984:25984 <image-hash> -n 2
```

# Image building for CouchDB release managers

Check out the `build.sh` script in the apache/couchdb-docker GitHub repository,
which can build images for any version, even in a cross-platform way.

Also, read the next section to ensure you push all of the tags necessary.

# Image uploading for CouchDB release managers

Taking a hypothetical example of CouchDB 2.9.7, here's all of the tags you'd want:

```bash
docker build -t apache/couchdb:2.9.7 2.9.7
docker tag apache/couchdb:2.9.7 apache/couchdb:latest
docker tag apache/couchdb:2.9.7 apache/couchdb:2.9
docker tag apache/couchdb:2.9.7 apache/couchdb:2
docker login
docker push apache/couchdb:2.9.7
docker push apache/couchdb:2.9
docker push apache/couchdb:2
docker push apache/couchdb:latest
```

Obviously don't create/push the `latest` or `2` tags if this is a maintenance
branch superceded by a newer one.

The `build.sh` utility can help you do this quickly, see its usage help for
more details.

To see full build logs, export `PROGRESS_NO_TRUNC=1` and use `--progress
plain` as an option to `docker build`.

To rebuild all Dockerfile steps without caching (so you can inspect the
build log e.g.), use the `--no-cache` option of `docker build`.

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
