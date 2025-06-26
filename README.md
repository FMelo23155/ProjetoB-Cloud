
# Project B: Cloud Computing and Virtualization

This repository contains Project B of the Cloud Computing and Virtualization course for the MEI-IoT program.

## Project Overview

The project involves setting up a Docker Swarm environment using Vagrant. The application includes image upload functionality using **Cloudinary** for cloud storage. After provisioning the virtual machines (VMs), several services will be accessible via specified IP addresses and ports.

## Features

- **Docker Swarm cluster** with multiple nodes
- **PHP web application** with session management
- **WebSocket communication** for real-time chat
- **PostgreSQL database** for data persistence
- **Redis** for pub/sub messaging and caching
- **Cloudinary integration** for image upload and management
- **Load balancing** with multiple replicas

## Getting Started

### Prerequisites

Make sure you have the following installed on your system:
- Vagrant
- VirtualBox or any other Vagrant-supported provider

### Instructions

1. **Navigate to the project directory:**
   Open a command line interface (CLI) and navigate to the directory where this project is located.

2. **Run Vagrant to create the VMs:**
   ```sh
   vagrant up
   ```
   This command will start and provision the VMs needed for the Docker Swarm. During this process, the swarm will be initialized and the worker nodes will be added to the swarm.

3. **SSH into the manager VM:**
   ```sh
   vagrant ssh manager01
   ```
   This command will allow you to access the manager VM of the swarm and run necessary commands within this VM.

4. **Deploy the Docker stack:**
   ```sh
   docker stack deploy -c /vagrant/stack.yml my_stack
   ```
   This command deploys the Docker stack defined in the `stack.yml` file. All necessary images for this stack are created during the VM provisioning.

### Accessing the Web Applications

After running the above commands, the following services will be accessible:

- **Web Application:**
  Accessible at any of the IP addresses of the swarm VMs on port 80. Example:
  ```
  http://10.10.20.11
  ```

- **Portainer (Docker Management UI):**
  Accessible at any of the IP addresses of the swarm VMs on port 9000. Example:
  ```
  http://10.10.20.11:9000
  ```

## Application Features

- **Home**: Server information and deployment details
- **Sessions**: Session management with PostgreSQL storage
- **Files**: Image upload/download using Cloudinary cloud storage
- **Database**: CRUD operations on PostgreSQL database
- **WebSockets**: Real-time chat functionality
- **About**: Project information

## Cloud Integration

This project uses **Cloudinary** for cloud-based image storage, providing:
- Automatic image optimization
- Secure upload/download
- Dynamic image transformations
- Global CDN delivery

## Conclusion

This setup ensures a robust environment for managing and monitoring a Docker Swarm cluster, leveraging Vagrant for VM provisioning, Docker for container orchestration, and Cloudinary for cloud storage services.

Feel free to explore the provided interfaces and manage the services as required for your project needs.
