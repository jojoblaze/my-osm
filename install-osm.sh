#!/bin/sh

#——————————————————————————————————————————————————————————————

# Name:     install-osm.sh

# Purpose:  Setup a custom Openstreetmap tile server .

# Author:   Matteo Dello Ioio  https://github.com/jojoblaze

#——————————————————————————————————————————————————————————————

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

echo "${CYAN}PATH:${NC} ${PATH}"
echo "${CYAN}OSMUserName:${NC} ${OSMUserName}"
echo "${CYAN}OSMDBPassword:${NC} ${OSMDBPassword}"
echo "${CYAN}OSMDatabaseName:${NC} ${OSMDatabaseName}"
echo "${CYAN}OSMRegion:${NC} ${OSMRegion}"


echo "${GREEN}****************************************${NC}"
echo "${GREEN}*** OpenStreetMap Custom Tile Server ***${NC}"
echo "${GREEN}****************************************${NC}"

sh ./install-postgresql-10.sh ${OSMUserName} ${OSMDBPassword}

if [ "$?" -ne 0 ]; then
    echo "${RED}Something goes wrong in PostgreSQL installation.${NC}"
    exit 1
else
    echo "${GREEN}PostgreSQL installation successfully.${NC}"
fi



OSMMapDataUrl=$(./map_data_url_provider.sh "${OSMRegion}")
echo "OSMMapDataUrl: ${OSMMapDataUrl}"

if [ "$?" -ne 0 ]; then
    echo "${RED}Unable to retrieve map data url.${NC}"
    exit 1
else
    echo "${GREEN}Maps data will be downloaded from '${OSMMapDataUrl}'.${NC}"
fi


sh ./install-postgresql-gis.sh ${OSMUserName} ${OSMDBPassword} ${OSMDatabaseName} ${OSMMapDataUrl}

if [ "$?" -ne 0 ]; then
    echo "${RED}Something goes wrong in PostgreGIS installation${NC}"
    exit 1
else
    echo "${GREEN}PostgreGIS installation successfully${NC}"
fi



sh ./install-apache2-web-server.sh

if [ "$?" -ne 0 ]; then
    echo "${RED}Something goes wrong in webserver installation${NC}"
    exit 1
else
    echo "${GREEN}webserver installed successfully${NC}"
fi



sh ./install-osm-tile-server.sh ${OSMUserName} "https://raw.githubusercontent.com/jojoblaze/my-osm/development/000-default.conf"

if [ "$?" -ne 0 ]; then
    echo "${RED}Something goes wrong in webserver configuration${NC}"
    exit 1
else
    echo "${GREEN}webserver configuration successfully${NC}"
fi