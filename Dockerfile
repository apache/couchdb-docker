FROM klaemo/couchdb-base

MAINTAINER Clemens Stolle clemens.stolle@gmail.com

# Get the source
RUN cd /opt && \
 wget http://apache.openmirror.de/couchdb/source/1.5.0/apache-couchdb-1.5.0.tar.gz && \
 tar xzf /opt/apache-couchdb-1.5.0.tar.gz

# build couchdb
RUN cd /opt/apache-couchdb-* && ./configure && make && make install

# install github.com/visionmedia/mon v1.2.3
RUN (mkdir /tmp/mon && cd /tmp/mon && curl -L# https://github.com/visionmedia/mon/archive/1.2.3.tar.gz | tar zx --strip 1 && make install)

# cleanup
RUN apt-get remove -y build-essential wget curl && \
 apt-get autoremove -y && apt-get clean -y && \
 rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /opt/apache-couchdb-*

ADD ./opt /opt

# Configuration
RUN sed -e 's/^bind_address = .*$/bind_address = 0.0.0.0/' -i /usr/local/etc/couchdb/default.ini
RUN /opt/couchdb-config

CMD ["/opt/start_couch"]
EXPOSE 5984