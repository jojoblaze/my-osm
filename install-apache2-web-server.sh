#!/bin/sh

# Url of virtual host file.
# example: https://raw.githubusercontent.com/jojoblaze/my-osm/master/000-default.conf
VirtualHostUrl=$1
VirtualHostFileName=$(basename ${VirtualHostUrl})


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



echo "${CYAN}VirtualHostUrl:${NC} ${VirtualHostUrl}"




echo "${GREEN}***********************${NC}"
echo "${GREEN}*** Install Apache2 ***${NC}"
echo "${GREEN}***********************${NC}"

sudo apt-get install -y apache2

if [ "$?" -ne 0 ]; then
    echo "${RED}Some error has occurred installing Apache2, exiting."
    exit 1
else
    echo "${GREEN}Apache2 installed successfully."
fi



echo "${GREEN}**************************${NC}"
echo "${GREEN}*** Configuring Apache ***${NC}"
echo "${GREEN}**************************${NC}"


# Replace default virtual host file
cd /tmp
wget "${VirtualHostUrl}"

if [ "$?" -ne 0 ]; then
    echo "Some error has occurred downloading Apache virtual host configuration."
    exit 1
else
    echo "Apache virtual host configuration downloaded successfully."
fi


# mv 000-default.conf /etc/apache2/sites-available/000-default.conf
mv "${VirtualHostFileName}" /etc/apache2/sites-available/"${VirtualHostFileName}"


echo 'Restart Apache2.'
sudo systemctl restart apache2

if [ "$?" -ne 0 ]; then
    echo "${RED}Some error has occurred restarting Apache2 service.${NC}"
    exit 1
fi

echo "${GREEN}Congrats! You just successfully built your own Apache2 web server.${NC}""