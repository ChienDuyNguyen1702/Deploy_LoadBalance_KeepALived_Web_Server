FROM ubuntu:16.04
WORKDIR /
RUN apt-get update 
RUN apt install curl -y