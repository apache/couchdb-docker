FROM ubuntu:12.04

MAINTAINER Clemens Stolle clemens.stolle@gmail.com

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y wget build-essential \
 erlang-dev erlang-manpages erlang-base-hipe erlang-eunit erlang-nox erlang-xmerl erlang-inets \
 libmozjs185-dev libicu-dev libcurl4-gnutls-dev libtool

# install supervisor (which has no package on 12.04) to manage our processes
# the supervisor config file is more likely to change and is therefore added as a later step

RUN apt-get -y install python-setuptools
RUN easy_install supervisor
RUN mkdir -p /var/log/supervisor