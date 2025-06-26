#!/bin/bash

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y docker.io

systemctl enable docker
systemctl start docker

sudo docker build -f /vagrant/php-apache -t php_app /vagrant/
sudo docker build -f /vagrant/server-ws-js -t server_ws_js /vagrant/