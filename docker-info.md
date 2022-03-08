docker info
docker image ls
docker image pull hello-world
docker container run hello-world
docker contianer run -d --name test <image name or id>

docker container ls / docker ps -> lists running contianers
docker ps -a
docker container start <container id>
docker logs <container name> or <container id>
docker container rm -f <container id>

docker container run -d --name webserver httpd
docker exec -it webserver sh
docker container inspect webserver

----------------------------------------------------------------------------------------------------------------------------------------------------------
docker volume ls
docker volume create first_volume
docker volume inspect first_volume
docker container run -it --rm -v first_volume:/test ubuntu bash
docker volume rm first_volume

Networks:
bridge
host
none
docker network ls
docker container run -dit --rm --name con1 ubuntu bash
docker container run -dit --rm --name con2 ubuntu bash
docker network inspect bridge
docker attach con1
  apt update -y && apt install -y net-tools iputils-ping
  Ctrl p , q
docker network disconnect bridge con1

docker container run --rm --network host --name con3 -it ubuntu bash

User defined network bridge
docker network create first_network
  docker container run -dit --rm --name web --network first_network busybox sh
  docker container run -dit --rm --name database --network first_network busybox sh
docker attach web

docker network create --driver=bridge --subnet=10.10.0.0/16 --ip-range=10.10.10.0/24 --gateway=10.10.10.10 second_network

docker container run -d --name webserver --network first_network -p 5000:80 nginx
docker container inspect webserver
docker container run --rm -it --name test_container --network second_network centos sh

  
  