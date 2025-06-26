
# Project B: Cloud Computing and Virtualization - High Availability PostgreSQL

This repository contains Project B of the Cloud Computing and Virtualization course for the MEI-IoT program, featuring a **High Availability PostgreSQL** configuration with automatic failover capabilities.

## Project Overview

The project implements a robust Docker Swarm environment with **High Availability PostgreSQL** using Primary/Secondary replication and **HAProxy** for automatic failover. The setup ensures zero-downtime database operations and includes comprehensive monitoring and testing capabilities.

## High Availability Features

- **PostgreSQL Primary/Secondary Replication** with automatic failover
- **HAProxy Load Balancer** for database connection management
- **Docker Swarm cluster** with multiple nodes for service resilience
- **Automatic failover testing** with recovery procedures
- **Real-time monitoring** and health checks
- **Zero-downtime deployment** strategies

## Core Application Features

- **Docker Swarm cluster** with multiple nodes
- **PHP web application** with PostgreSQL session management
- **WebSocket communication** for real-time chat
- **High Availability PostgreSQL** with Primary/Secondary setup
- **Redis** for pub/sub messaging and caching
- **Cloudinary integration** for image upload and management
- **Load balancing** with multiple replicas
- **HAProxy** for database connection pooling and failover

## Getting Started

### Prerequisites

Make sure you have the following installed on your system:
- Vagrant
- VirtualBox or any other Vagrant-supported provider

## High Availability Deployment

### Automated Deployment

For quick deployment with High Availability setup, use the provided deployment script:

```sh
# SSH into the manager VM
vagrant ssh manager01

# Run the HA deployment script
cd /vagrant
./deploy-ha.sh
```

This script will:
- Clean previous deployments and volumes
- Deploy the full HA stack with PostgreSQL Primary/Secondary
- Configure HAProxy for automatic failover
- Set up all necessary databases and tables
- Provide deployment status and verification

### Manual Deployment Steps

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

4. **Deploy the High Availability Docker stack:**
   ```sh
   docker stack deploy -c /vagrant/stack.yml my_stack
   ```
   This command deploys the Docker stack with High Availability PostgreSQL configuration defined in the `stack.yml` file.

### Quick Status Check

Use the quick verification script to check all services:

```sh
cd /vagrant
./quick-test.sh
```

This will verify:
- Docker Swarm status
- All service health (PostgreSQL Primary/Secondary, HAProxy, PHP, Redis, WebSocket)
- Application accessibility
- HAProxy statistics and failover status

### Accessing the Applications

After deployment, the following services will be accessible:

- **Web Application (High Availability):**
  Accessible at any of the IP addresses of the swarm VMs on port 80:
  ```
  http://10.10.20.11
  ```

- **HAProxy Statistics Dashboard:**
  Monitor PostgreSQL failover status and database health:
  ```
  http://10.10.20.11:8404/stats
  ```
  - Username: `admin`
  - Password: `admin123`

- **PostgreSQL Database (via HAProxy):**
  Direct database access through the load balancer:
  ```
  Host: 10.10.20.11
  Port: 5432
  Database: cnv_project
  Username: cnv_user
  Password: cnv_password
  ```

- **WebSocket Server:**
  Real-time communication endpoint:
  ```
  ws://10.10.20.11:8888
  ```

- **Redis Cache:**
  Caching and pub/sub service:
  ```
  Host: 10.10.20.11
  Port: 6379
  ```

## High Availability Testing

### Failover Testing

Test the automatic failover capability:

```sh
# Simulate Primary database failure
docker service scale my_stack_postgres-primary=0

# Check HAProxy stats to see failover to Secondary
curl http://10.10.20.11:8404/stats

# Verify application continues working
curl http://10.10.20.11/db.php

# Restore Primary database
docker service scale my_stack_postgres-primary=1
```

### Database Replication Status

Check replication status:

```sh
# Check Primary status
docker exec $(docker ps --filter 'name=postgres-primary' --format '{{.ID}}') \
  psql -U cnv_user -d cnv_project -c "SELECT * FROM pg_stat_replication;"

# Check Secondary status  
docker exec $(docker ps --filter 'name=postgres-secondary' --format '{{.ID}}') \
  psql -U cnv_user -d cnv_project -c "SELECT * FROM pg_stat_wal_receiver;"
```

## Application Features

- **Home**: Server information and deployment details with HA status
- **Sessions**: Session management with PostgreSQL HA storage and custom session handler
- **Files**: Image upload/download using Cloudinary cloud storage
- **Database**: CRUD operations on High Availability PostgreSQL with automatic failover
- **WebSockets**: Real-time chat functionality with Redis pub/sub
- **About**: Project information and HA architecture details

## High Availability Architecture

### Database Layer
- **PostgreSQL Primary**: Main database server with read/write operations
- **PostgreSQL Secondary**: Streaming replication slave for failover
- **HAProxy**: Load balancer with health checks and automatic failover
- **Persistent Volumes**: Separate data persistence for Primary and Secondary

### Application Layer
- **PHP Application**: 3 replicas with session affinity
- **Custom Session Handler**: PostgreSQL-based session storage for HA
- **Redis**: Pub/sub messaging and caching with persistence
- **WebSocket Server**: 3 replicas for real-time communication

### Monitoring & Management
- **HAProxy Stats**: Real-time monitoring of database health and failover status
- **Docker Swarm**: Service orchestration with health checks and auto-restart
- **Automated Scripts**: Deployment, testing, and monitoring utilities

## Database Schema

The application uses the following tables in PostgreSQL:

```sql
-- Messages for the application
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- PHP session storage
CREATE TABLE php_sessions (
    sess_id VARCHAR(128) PRIMARY KEY,
    sess_data TEXT,
    sess_time INTEGER NOT NULL
);

-- General session tracking
CREATE TABLE sessions (
    id VARCHAR(128) PRIMARY KEY,
    data TEXT,
    last_access TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- File upload metadata
CREATE TABLE uploads (
    id SERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Troubleshooting

### Common Issues

1. **PostgreSQL Connection Issues**
   ```sh
   # Check HAProxy status
   docker service logs my_stack_postgres-ha
   
   # Check Primary database
   docker service logs my_stack_postgres-primary
   
   # Check Secondary database
   docker service logs my_stack_postgres-secondary
   ```

2. **Application Errors**
   ```sh
   # Check PHP application logs
   docker service logs my_stack_php-app
   
   # Verify database tables exist
   docker exec $(docker ps --filter 'name=postgres-primary' --format '{{.ID}}') \
     psql -U cnv_user -d cnv_project -c '\dt'
   ```

3. **Service Recovery**
   ```sh
   # Restart specific service
   docker service update --force my_stack_postgres-primary
   
   # Full stack restart
   docker stack rm my_stack
   sleep 30
   docker stack deploy -c /vagrant/stack.yml my_stack
   ```

## Performance Optimization

- **Connection Pooling**: HAProxy manages PostgreSQL connections efficiently
- **Read Replicas**: Secondary database can be configured for read-only queries
- **Redis Caching**: Implemented for session data and application caching
- **Load Balancing**: Multiple replicas for PHP and WebSocket services
- **Persistent Volumes**: Optimized storage for database performance

## Cloud Integration

This project uses **Cloudinary** for cloud-based image storage, providing:
- Automatic image optimization
- Secure upload/download
- Dynamic image transformations
- Global CDN delivery

## Project Files Structure

```
├── stack.yml                          # Docker Swarm stack configuration with HA PostgreSQL
├── deploy-ha.sh                       # Automated HA deployment script
├── quick-test.sh                      # Service verification and health check script
├── haproxy-config/
│   └── haproxy.cfg                    # HAProxy configuration for PostgreSQL failover
├── postgres-config/
│   └── primary/
│       ├── 01-replication.sql         # PostgreSQL replication setup
│       └── 02-create-tables.sql       # Database schema and initial data
├── app/
│   ├── public_html/
│   │   ├── pgSqlSessionHandler.php    # Custom PostgreSQL session handler
│   │   ├── db.php                     # Database operations with HA support
│   │   ├── sessions.php               # Session management page
│   │   └── ...                        # Other application files
│   └── ...
├── provision/                         # VM provisioning scripts
└── ws-js/                            # WebSocket server implementation
```

## Contributing

1. Fork the repository
2. Create a feature branch for HA improvements
3. Test failover scenarios thoroughly
4. Submit a pull request with performance metrics

## License

This project is part of the MEI-IoT Cloud Computing and Virtualization course.

## Conclusion

This High Availability setup provides a robust, production-ready environment with:

- **Zero-downtime database operations** through PostgreSQL Primary/Secondary replication
- **Automatic failover** via HAProxy with health monitoring
- **Scalable application architecture** using Docker Swarm
- **Comprehensive monitoring** and testing capabilities
- **Production-grade configuration** suitable for enterprise deployments

The implementation demonstrates advanced cloud computing concepts including database replication, load balancing, container orchestration, and high availability patterns essential for modern distributed systems.

Feel free to explore the HA features, test failover scenarios, and monitor the system performance through the provided dashboards and utilities.
