#!/bin/bash
if docker-compose -v > /dev/null 2>&1 &
then
    echo "using docker compose v2 : docker compose stop"
    docker compose stop
    disown
else
    echo "using docker-compose v1 : docker-compose stop"
    docker-compose stop
    disown
fi