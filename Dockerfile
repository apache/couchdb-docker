FROM ubuntu:precise

MAINTAINER Clemens Stolle clemens.stolle@gmail.com

RUN echo "deb http://ftp.halifax.rwth-aachen.de/ubuntu precise main universe" > /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y wget build-essential
RUN apt-get install -y erlang-dev erlang-manpages erlang-base-hipe erlang-eunit erlang-nox erlang-xmerl erlang-inets
RUN apt-get install -y libmozjs185-dev libicu-dev libcurl4-gnutls-dev libtool

# Get the source
RUN cd /usr/local/src && wget http://apache.openmirror.de/couchdb/source/1.5.0/apache-couchdb-1.5.0.tar.gz
RUN cd /usr/local/src && tar xzf /usr/local/src/apache-couchdb-1.5.0.tar.gz

RUN cd /usr/local/src/apache-couchdb-1.5.0 && ./configure && make && make install

RUN apt-get remove -y build-essential wget && apt-get autoremove -y && apt-get clean -y
RUN rm -rf /usr/local/src/apache-couchdb-*

# Configuration
ADD couchdb-config /usr/local/
ADD local.ini /usr/local/etc/couchdb/
RUN chmod +x /usr/local/couchdb-config && ./usr/local/couchdb-config
RUN sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i /usr/local/etc/couchdb/default.ini

# Install CouchDB as a service
RUN update-rc.d couchdb defaults

CMD ["couchdb", "-r 5", "-p /usr/local/var/run/couchdb/couchdb.pid"]
# USER couchdb

# Use volume dir for database files and config
VOLUME ["/usr/local/var/lib/couchdb", "/usr/local/etc/couchdb"]

EXPOSE 5984
