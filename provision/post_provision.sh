#!/bin/bash

docker stack deploy -c /vagrant/stack.yml my_stack

docker service ls
