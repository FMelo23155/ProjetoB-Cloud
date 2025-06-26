#!/bin/bash

sudo docker swarm init --advertise-addr $1

sudo echo $1 > /vagrant/provision/tokens/ip.txt

sudo docker swarm join-token worker -q > /vagrant/provision/tokens/worker.token
sudo docker swarm join-token manager -q > /vagrant/provision/tokens/manager.token

curl -L https://downloads.portainer.io/ce2-19/portainer-agent-stack.yml -o portainer-agent-stack.yml

docker stack deploy -c portainer-agent-stack.yml portainer