#!/bin/bash
OSMUserName=$1
OSMDBPassword=$2
OSMDatabaseName=$3
OSMRegion=$4

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


./install-postgresql-10.sh $OSMUserName $OSMDBPassword

if [[ $? > 0 ]]; then
    echo -e "${RED}Something goes wrong in PostgreSQL installation.${NC}"
    exit 1
else
    echo -e "${GREEN}PostgreSQL installation successfully.${NC}"
fi

./install-postgresql-gis.sh $OSMUserName $OSMDBPassword $OSMDatabaseName $OSMRegion

if [[ $? > 0 ]]; then
    echo "${RED}Something goes wrong in PostgreGIS installation${NC}"
    exit 1
else
    echo "${GREEN}PostgreGIS installation successfully${NC}"
fi

./install-osm-tile-server.sh $OSMUserName

if [[ $? > 0 ]]; then
    echo "${RED}Something goes wrong in webserver configuration${NC}"
    exit 1
else
    echo "${GREEN}webserver configuration successfully${NC}"
fi