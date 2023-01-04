FROM ubuntu:16.04
WORKDIR /HAFolder/
RUN apt-get update 
# RUN apt-get install net-tools  
RUN apt-get install haproxy -y
RUN apt-get install keepalived -y
# RUN apt install curl -y
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY ./keepalived.conf /etc/keepalived/keepalived.conf
# CMD []
ENTRYPOINT service haproxy start && service keepalived start && /bin/bash && echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf