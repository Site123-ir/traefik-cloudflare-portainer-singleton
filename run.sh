#!/bin/bash
if [ ! -f .env ]
then
  export $(cat .env | xargs)
fi

if docker-compose -v > /dev/null 2>&1 &
then
    echo "using docker compose v2 : docker compose up -d"
    docker compose up -d
    disown
else
    echo "using docker-compose v1 : docker-compose up -d"
    docker-compose up -d
    disown
fi