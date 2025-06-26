#!/bin/bash

TOKEN=$(cat /vagrant/provision/tokens/manager.token)
IP=$(cat /vagrant/provision/tokens/ip.txt)

docker swarm join --token $TOKEN $IP:2377