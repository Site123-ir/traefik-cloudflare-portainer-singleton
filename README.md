# TRAEFIK PORTAINER CF_COMPANION SERVER STACK

## What is used
### Traefik
Traefik is a leading modern reverse proxy and load balancer that makes deploying microservices / multiple websites easier.
https://containo.us/traefik/

#### What is this?
This tool (TRAEFIK) is used to provide docker based reverse proxy to provide easier deployment of apps and less complicated configs required.
Cloudflare companion is also used to automaticaly create DNS records on cloudflare for endpoints created in docker via traefik

### Portainer
Portainer is a lightweight management UI which allows to easily manage different Docker environments (Docker hosts or Swarm clusters). Portainer is meant to be as simple to deploy as it is to use. It consists of a single container that can run on any Docker engine (can be deployed as Linux container or a Windows native container, supports other platforms too). Portainer allows to manage all Docker resources (containers, images, volumes, networks and more) ! It is compatible with the standalone Docker engine and with Docker Swarm mode.
https://github.com/portainer/portainer

# What is needed to run this?
DockerCE should be installed along side docker-compose cli or docker compose (v2)

# Preparing to run
## .env file
Proper values for environmental variables are required in .env file followed by the example given in .env.example
Script (`init.sh`) would do a pretty neat job on initializing the server with a setup like procedure, asking email address, domain name, api keys, etc, and putting them in to the .env file just like the example (`.env.example`)

### Create traefik basic auth user and password for traefik dashboard
Create the password with `echo $(htpasswd -nb user password) | sed -e s/\\$/\\$\\$/g`. Replace `user` and `password` with your desired values.
Put the password directly in `docker-compose.yml` file.

Again the init.sh file can also do this, mean while you can use the command above to generate new password set too.

`init.sh` do so by replacing template litterals on docker-compose.yml and traefik.yml files, replacing ${TARGETDOMAIN} with the domain you provide during installation, ${CONFIGEMAIL}, and ${USERPASS} with the generated appropriate values depending on your inputs

# How to run this?
## First run - INIT
Run `./init.sh`.
This will ask you to remove any `acme.json` file in `configs` folder if there is any, and create an empty file, and/or give it proper file permission by doing `chmod 600 ./configs/acme.json`.
From now on, there is no need to do the init part in case there is no config change, which I doubt there will ever be.

## Running it
Run `./run.sh`.
But to know what it does:
Use `docker-compose up -d` to run this container in a seamless daemonized way. `-d` is detach option, which releases your terminal/bash after the container is ran.
There is another tool available on this server named portainer which is gonna be used to make it easier to manage the maintenance of this docker based web server.

## Recreating it
Run `./recreate.sh`.
This will recreate the containers, rerunning them, and applying any changes in `traefik.yml` and `config.yml`.

## Stoping it
Run `./stop.sh`.

## Destroying it
Run `./destroy.sh`.

# How do I know what's happening inside the container?
Run `./logs.sh`.
But to know:
You can use `docker-compose logs -f` to view a tailed log. 

# Do I need to run this on every server reboot?
No, with the settings being set insdie this docker-compose.yml file (`restart: unless-stopped`), unless you willingly stop this container, it will restart on every system reboot, or app/system crash.

# How do I access the dashboard?
This very compose file (`./docker-compose.yml`) also exposes traefik dashboard to `https://monitor.example.com`

# Holy Moly, SSL out of the Box?
The SSL (https) is handled via a free SSL generator, and is automatically renewed when required. The SSL is now configured as a wildcard for the domain `example.com` and its absolutely free and secure.