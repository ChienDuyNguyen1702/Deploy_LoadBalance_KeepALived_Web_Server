# Deploy_LoadBalance_KeepALived_Web_Server
Deploy WebServer using HAProxy, Nginx, and keepalived as microservice in Docker-compose 
![demo model](/demo.png)


# Docker-compose's configuration 
<b>Network</b>  
Fisrt off all, a network named "habackendserver" is created for all containers  
And each container have a specific IP address as picture

```Dockerfile
networks:
  habackendnetwork:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: "192.168.13.0/24"
          gateway: "192.168.13.1"
```
<b>Client container</b>  
Client image needs to be installed curl to get content from server  
client.Dockerfile would be liked:
```Dockerfile
FROM ubuntu:latest
WORKDIR /
RUN apt-get update 
RUN apt install curl -y
```
<b>Load balancer</b>  
HAProxy image needs to be installed haproxy and keepalived services  
a file named `haproxy.conf` would be script like this:  
```console
global
  # stats socket /var/run/api.sock user haproxy group haproxy mode 660 level admin expose-fd listeners
  # log stdout format raw local0 info
  daemon

defaults
  mode http
  timeout client 10s
  timeout connect 5s
  timeout server 10s
  timeout http-request 10s
  log global

frontend myfrontend
  bind *:80
  default_backend webservers

backend webservers
  balance roundrobin
  server s1 192.168.13.212:80 check
  server s2 192.168.13.216:80 check
```
And `keepalived.cfg` file for the HAMaster :  
```console
vrrp_script check_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}
vrrp_instance VI_01 {
    state MASTER
    interface eth0
    mcast_src_id 192.168.13.214
    virtual_router_id 1
    priority 100
    virtual_ipaddress {
        192.168.13.213
    }
    track_script {
        check_haproxy
    }
}
```
and  `keepalived.cfg` for the HABackup :  
```console
vrrp_script check_haproxy {
    script "killall -0 haproxy"
    interval 2
    weight 2
}
vrrp_instance VI_01 {
    state BACKUP
    interface eth0
    mcast_src_id 192.168.13.222
    virtual_router_id 1
    priority 99
    virtual_ipaddress {
        192.168.13.213
    }
    track_script {
        check_haproxy
    }
}
```
The differences `keepalived.cfg` file between HAMaster and HABackup is state and priority and mcast_src_id  
To explain some line in file: https://keepalived.readthedocs.io/en/latest/introduction.html  
    
We need to copy HAproxy and Keepalived configuration file into the right folder inside the container with the right path folder  
After those step, the HAProxy.Dockerfile would look liked this:
```Dockerfile
FROM ubuntu:latest
WORKDIR /
RUN apt-get update 
RUN apt-get install haproxy -y
RUN apt-get install keepalived -y
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY ./keepalived.conf /etc/keepalived/keepalived.conf
# CMD []
ENTRYPOINT service haproxy start && service keepalived start && /bin/bash && sh -c echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
```

<b>Web server</b>
Web server image needs to be install nginx services  
After that, we need to configure the `index.html` file in nginx configure folder `/usr/share/nginx/html/`, easy line:  
`This is content from Nginx with ip : ` insert the IP address of each container

```Dockerfile
FROM ubuntu:latest
RUN apt update 
RUN apt install nginx -y
COPY ./index.html /usr/share/nginx/html/index.html
CMD [ "/usr/sbin/nginx", "-g", "daemon off;"]
```
  
# Docker-compose.yml
All of these thing above is the prerequited thing to the `docker-compose.yml`  
(please check ip, exposed port, container_name, or some needed thing)
```docker-compose
version: '2.4'
#services 
services:
  hamaster:
    container_name: hamaster
    build:
      context: ./HAFolder/HAMaster
      dockerfile: HAProxy.Dockerfile
    restart: always
    networks:
      habackendnetwork:
        ipv4_address: "192.168.13.214"
    ports:
      - 8081:80
    stdin_open: true
    tty: true
    cap_add:
      - NET_ADMIN
  habackup:
    container_name: habackup
    build:
      context: ./HAFolder/HASub
      dockerfile: HAProxy.Dockerfile
    restart: always
    networks:
      habackendnetwork:
        ipv4_address: "192.168.13.222"

    ports:
      - 8080:80
    stdin_open: true
    tty: true
    cap_add:
      - NET_ADMIN
  nginx1:
    container_name: nginx1
    build:
      context: ./HAFolder/Nginx1
      dockerfile: Nginx.Dockerfile
    networks:
      habackendnetwork:
        ipv4_address: "192.168.13.212"
  nginx2:
    container_name: nginx2
    build:
      context: ./HAFolder/Nginx2
      dockerfile: Nginx.Dockerfile
    networks:
      habackendnetwork:
        ipv4_address: "192.168.13.216"
  client:
    container_name: client
    build:
      context: ./HAFolder/Client
      dockerfile: client.Dockerfile
    networks:
      habackendnetwork:
        ipv4_address: "192.168.13.210"
    stdin_open: true
    tty: true
    cap_add:
      - NET_ADMIN
#volume
volumes:
  HAVolume:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: './HAFolder'
#network
networks:
  habackendnetwork:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: "192.168.13.0/24"
          gateway: "192.168.13.1"
```
Now run `docker-compose up --build` to build the compose  
Attach to `client` container, using curl command to get the content of Webserver for a several times to check HAproxy is Load Balancing  


Now we see HAproxy is working well  
Down the HAMaster with docker command line `docker stop hamaster` in order to down the MASTER state, active VRRP in keepalived services  
check `docker ps -a`  
Continue attach to `client` container, using curl command to get the content of Webserver  

Now we see it keepalived is working too.

# Summary
This likes an small exercise to understand a little about docker-compose, nginx, haproxy, keepalive, and some interactive of Linux  
Thank you for reading !  

