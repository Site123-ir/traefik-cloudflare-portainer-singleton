#!/bin/bash

ENVFILE=$PWD/.env
ENVEXIST="FALSE"
ENVNOTEMPTY="FALSE"
CERTFILE=$PWD/configs/acme.json
CERTFILEEXISTS="FALSE"
CERTFILENOTEMPTY="FALSE"
CONFIGFILE=$PWD/configs/traefik.yml
COMPOSEFILE=$PWD/docker-compose.yml

strEnv="Env!"
strCert="Cert!"

function check_if_server_is_initialized_before {
    echo "Checking for previous initialization of server, (./config/acme.json)"
    check_if_file_exists_and_is_not_empty $strCert;
    if [ $CERTFILEEXISTS == "TRUE" ]; then
        echo "Found previous initialization of server, (./config/acme.json)"
        if [ $CERTFILEEXISTS == "TRUE" ]; then
            echo "File $CERTFILE exists and is not empty. Do you want to continue with server initialization?"
            echo "This action would result in removing the previous obtained certificates."
            confirm_delete_file $strCert;
        else
            echo "File $CERTFILE exists but is empty. Initializing Server."
            chmod 600 $CERTFILE;
            start_server;
        fi
    else
        echo "File $CERTFILE does not exist. Proceeding with server initialization."
        create_file $CERTFILE;
        start_server;
    fi
}


function check_if_file_exists_and_is_not_empty {
    if [ $1 == $strCert ]; then
        TARGET=$CERTFILE
    else
        TARGET=$ENVFILE
    fi
    if [ -f $TARGET ]
    then
        if [ -s $TARGET ]
        then
            if [ $1 == $strCert ]
            then
                CERTFILEEXISTS="TRUE"
                CERTFILENOTEMPTY="TRUE"
            else 
                ENVEXIST="TRUE"
                ENVNOTEMPTY="TRUE"
            fi
        else
            if [ $1 == $strCert ]
            then
                CERTFILEEXISTS="TRUE"
                CERTFILENOTEMPTY="FALSE"
            else 
                ENVEXIST="TRUE"
                ENVNOTEMPTY="FALSE"
            fi
        fi
    else
        if [ $1 == $strCert ]
        then
            CERTFILEEXISTS="FALSE"
            CERTFILENOTEMPTY="FALSE"
        else 
            ENVEXIST="FALSE"
            ENVNOTEMPTY="FALSE"
        fi
    fi
}

function delete_file {
    if [ $1 == $strCert ]; then
        if [ -f $CERTFILE ]
        then
            rm $CERTFILE
            echo "Deleted previouse file $CERTFILE"
            create_file $CERTFILE;
            start_server;
        else
            create_file $CERTFILE;
            start_server;
        fi
    else
        if [ -f $ENVFILE ]
        then
            rm $ENVFILE
            echo "Deleted previouse file $ENVFILE"
            create_file $ENVFILE;
            input_env_vars;
        else
            create_file $ENVFILE;
            input_env_vars;
        fi
    fi
}

function confirm_delete_file {
    if [ $1 == $strCert ]; then
        select yn in "Yes" "No"; do
            case $yn in
            Yes ) delete_file $CERTFILE; break;;
            No ) start_server; break;;
            esac
        done
    else
        select yn in "Yes" "No"; do
            case $yn in
            Yes ) delete_file $ENVFILE; break;;
            No ) import_env_vars; break;;
            esac
        done
    fi
}

function create_file {
  echo "Creating new file $1"
  touch $1;
  chmod 600 $1;
}

function start_server {
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
}

function set_target_domains {
    sed -i 's#\${TARGETDOMAIN}#'"$1"'#' $CONFIGFILE
    sed -i 's#\${TARGETDOMAIN}#'"$1"'#' $COMPOSEFILE
}

function set_config_emails {
    EMAILTOFIND="\${CONFIGEMAIL}"
    EMAILTOREPLACEWITH="$1"
    sed -i 's#\${CONFIGEMAIL}#'"$1"'#' $CONFIGFILE
}

function set_pass_words {
    USERPASSTOFIND="\${USERPASS}"
    TEMPPASS=$(htpasswd -nb $1 $2)
    echo "TEMPPASS"
    echo $TEMPPASS
    USER_PASS=$(sed -e s/\\$/\\$\\$/g <<< $TEMPPASS)
    # USER_PASS=$(echo `$TEMPPASS | sed -i -e s/\\$/\\$\\$/g`)
    echo "USER_PASS"
    echo $USER_PASS
    sed -i 's#\${USERPASS}#'"$USER_PASS"'#' $COMPOSEFILE
}

function input_env_vars {
    echo "Please enter the following environment variables:"
    echo "Your email address (used for letsencrypt and Cloudflare API)"
    read CONFIG_EMAIL
    set_config_emails $CONFIG_EMAIL;
    echo "Your target domain name"
    read TARGET_DOMAIN
    set_target_domains $TARGET_DOMAIN;
    echo "Your target domain ZONE_ID on Cloudflare"
    read TARGET_ZONE_ID
    echo "Enter username for traefik dashboard (https://monitor.$TARGET_DOMAIN)"
    read TRAEFIK_USERNAME
    echo "Enter password for traefik dashboard (https://monitor.$TARGET_DOMAIN)"
    read TRAEFIK_PASSWORD
    set_pass_words $TRAEFIK_USERNAME $TRAEFIK_PASSWORD;
    echo "Cloudflare API KEY"
    read CF_API_KEY
    echo "Cloudflare TOKEN"
    read CF_TOKEN
    exec 3<> $ENVFILE
        echo "CF_API_EMAIL=" >&3
        echo "CF_EMAIL=" >&3
        echo "CONFIG_EMAIL=$CONFIG_EMAIL" >&3
        echo "CF_API_KEY=$CF_API_KEY" >&3
        echo "CF_TOKEN=$CF_TOKEN" >&3
        echo "CLOUDFLARE_DNS_API_TOKEN=$CF_TOKEN" >&3
        echo "TRAEFIK_VERSION=2" >&3
        echo "TARGET_DOMAIN=site123.ir" >&3
        echo "DOMAIN1=$TARGET_DOMAIN" >&3
        echo "DOMAIN1_ZONE_ID=$TARGET_ZONE_ID" >&3
        echo "REFRESH_ENTRIES=true" >&3
    exec 3>&-
    import_env_vars;
}

function import_env_vars {
    echo "Importing environment variables from $ENVFILE"
    export $(cat $ENVFILE | xargs)
}

function set_env_vars {
    echo "Setting environment variables"
    check_if_file_exists_and_is_not_empty $strEnv;
    if [ $ENVEXIST == "TRUE" ]; then
        if [ "$ENVNOTEMPTY" = "TRUE" ]; then
            echo "File $ENVFILE exists and is not empty. Do you want to continue with environment variables initialization?"
            echo "This action would result in removing the previous environment variables."
            confirm_delete_file $strEnv;
        else
            echo "File $ENVFILE exists but is empty. Initializing Environment variables."
            chmod 600 $ENVFILE;
            input_env_vars;
        fi
    else
        echo "File $ENVFILE does not exist. Proceeding with environment variables initialization."
        create_file $ENVFILE;
        input_env_vars;
    fi
}

set_env_vars;
check_if_server_is_initialized_before;

