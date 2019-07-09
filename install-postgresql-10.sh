#!/bin/sh

#——————————————————————————————————————————————————————————————

# Name:     install-postgresql-10.sh

# Purpose:  Install PostgreSQL and do some basic configuration.

# Author:   Matteo Dello Ioio  https://github.com/jojoblaze

#——————————————————————————————————————————————————————————————

DB_USER=$1
DB_USER_PASSWORD=$2

# output coloring
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'

DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'

NC='\033[0m' # No Color



echo "${GREEN}****************************${NC}"
echo "${GREEN}*** Preparing the system ***${NC}"
echo "${GREEN}****************************${NC}"

echo 'Updating the system'
sudo apt-get update -y --fix-missing
#sudo apt-get upgrade -y

echo 'Setting Frontend as Non-Interactive'
export DEBIAN_FRONTEND=noninteractive



echo "${GREEN}*******************************************************${NC}"
echo "${GREEN}*** Install PostgreSQL Database Server with PostGIS ***${NC}"
echo "${GREEN}*******************************************************${NC}"
# sudo apt-get install -y postgresql postgresql-contrib postgresql-client-common postgis postgresql-10-postgis-2.4 postgresql-10-postgis-scripts
apt-get install -y postgresql postgresql-contrib postgresql-client-common postgis postgresql-10-postgis-2.4 postgresql-10-postgis-scripts

if $? > 0 ; then
    echo "${RED}Some error has occurred installing PostgreSQL.${NC}"
    exit 1
else
    echo "PostgreSQL installed succesfuly."
fi

# sudo -u postgres -i

# create a PostgreSQL database user osm
echo "Creating PostgreSQL database user ${DB_USER}"
sudo -u postgres createuser ${DB_USER}

if $? > 0 ; then
    echo "${RED}Unable to create PostgreSQL user ${DB_USER}.${NC}"
    exit 1
else
    echo "PostgreSQL user ${DB_USER} created succesfuly."
fi

echo "Setting password to ${DB_USER} database user"
sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_USER_PASSWORD}';"



echo "${GREEN}********************************${NC}"
echo "${GREEN}*** PostgreSQL configuration ***${NC}"
echo "${GREEN}********************************${NC}"

PG_HBA_PATH='/etc/postgresql/10/main/pg_hba.conf'

if [ ! -f ${PG_HBA_PATH} ]; then
    echo "${RED}${PG_HBA_PATH} file not found.${NC}"
    exit 1
else

    echo "creating a backup of original pg_hba.conf"
    cp ${PG_HBA_PATH} ${PG_HBA_PATH}.bck

    # Changing PostgreSQL authentication mode
    echo 'Set postgres user authentication mode to "trust" for local connections'
    sed -i "s/local   all             postgres                                peer/local   all             postgres                                trust/g" ${PG_HBA_PATH}

    if $? > 0 ; then
        echo "${RED}The command failed, exiting.${NC}"
        exit 1
    fi



    echo 'Allow remote connection from any ip'
    sed -i "s/host    all             all             127.0.0.1\/32            md5/host    all             all             0.0.0.0\/0               md5/g" ${PG_HBA_PATH}

    if $? > 0 ; then
        echo "${RED}The command failed, exiting.${NC}"
        exit 1
    fi
fi



# restarting postgres
echo 'restarting postgres'
service postgresql restart

if $? > 0 ; then
    echo "${RED}Some problem has occurred while restarting postgresql service, exiting.${NC}"
    exit 1
else
    echo "postgresql service restarted successfully."
fi



echo "${GREEN}Congrats! You just successfully built your own PostgreSQL server.${NC}"