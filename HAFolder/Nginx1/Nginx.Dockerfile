FROM ubuntu:14.04

RUN apt update 
# RUN apt install iproute2 -y 
# RUN apt-get install net-tools  
RUN apt install nginx -y
# RUN apt install curl -y
COPY ./index.html /usr/share/nginx/html/index.html
# RUN ip=$(ifconfig eth0 | perl -ne 'print $1 if /inet\s.*?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b/')
# RUN echo "this is $ip server" >> /usr/share/nginx/html/index.html
CMD [ "/usr/sbin/nginx", "-g", "daemon off;"]
# ENTRYPOINT 'export IP=$(ifconfig eth0 | perl -ne 'print $1 if /inet\s.*?(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b/')'