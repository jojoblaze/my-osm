#!/bin/sh
#

#——————————————————————————-

# Name:     install-postgresql-gis.sh

# Purpose:  Install GIS extensions on PostgreSQL, download and import map data.

# Author:   Matteo Dello Ioio  https://github.com/jojoblaze

#——————————————————————————-

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



echo "${CYAN}OSMUserName:${NC} ${OSMUserName}"
echo "${CYAN}OSMDBPassword:${NC} ${OSMDBPassword}"
echo "${CYAN}OSMDatabaseName:${NC} ${OSMDatabaseName}"
echo "${CYAN}OSMRegion:${NC} ${OSMRegion}"

MapDataUri=http://download.geofabrik.de

AfricaMapFileName=africa-latest.osm.pbf
AntarcticaMapFileName=antarctica-latest.osm.pbf
AsiaMapFileName=asia-latest.osm.pbf
AustraliaMapFileName=australia-oceania-latest.osm.pbf
EuropeMapFileName=europe-latest.osm.pbf
CentralAmericaMapFileName=central-america-latest.osm.pbf
NorthAmericaMapFileName=north-america-latest.osm.pbf
SouthAmericaMapFileName=south-america-latest.osm.pbf

# *** Europe ***
MapDataUriEurope=https://download.geofabrik.de/europe
ItalyMapFileName=italy-latest.osm.pbf

# *** Italy ***
MapDataUriItaly=https://download.geofabrik.de/europe/italy
ItalyNorthWestMapFileName=nord-ovest-latest.osm.pbf
ItalyNorthEastMapFileName=nord-est.osm.pbf
ItalyCenterMapFileName=centro-latest.osm.pbf
ItalySouthMapFileName=sud-latest.osm.pbf
ItalyIslandsMapFileName=isole-latest.osm.pbf

case ${OSMRegion} in
africa)
    MapDataFileName=$AfricaMapFileName
    ;;
antarctica)
    MapDataFileName=$AntarcticaMapFileName
    ;;
asia)
    MapDataFileName=$AsiaMapFileName
    ;;
australia-oceania)
    MapDataFileName=$AustraliaMapFileName
    ;;
north-america)
    MapDataFileName=$NorthAmericaMapFileName
    ;;
central-america)
    MapDataFileName=$CentralAmericaMapFileName
    ;;
south-america)
    MapDataFileName=$SouthAmericaMapFileName
    ;;
europe)
    MapDataFileName=$EuropeMapFileName
    ;;
europe/italy | italy)
    MapDataFileName=$ItalyMapFileName
    MapDataUri=$MapDataUriEurope
    ;;
europe/italy/north-west)
    MapDataFileName=$ItalyNorthWestMapFileName
    MapDataUri=$MapDataUriItaly
    ;;
europe/italy/lombardia)
    MapDataFileName=lombardia.pbf
    MapDataUri=http://geodati.fmach.it/gfoss_geodata/osm/output_osm_regioni
    ;;
europe/italy/north-east)
    MapDataFileName=$ItalyNorthEastMapFileName
    MapDataUri=$MapDataUriItaly
    ;;
europe/italy/center)
    MapDataFileName=$ItalyCenterMapFileName
    MapDataUri=$MapDataUriItaly
    ;;
europe/italy/south)
    MapDataFileName=$ItalySouthMapFileName
    MapDataUri=$MapDataUriItaly
    ;;
europe/italy/islands)
    MapDataFileName=$ItalyIslandsMapFileName
    MapDataUri=$MapDataUriItaly
    ;;
*)
    echo "${RED}Unkown country or territory${NC}"
    exit 1
    ;;
esac



OSMUserHome=/home/${OSMUserName}

echo "${GREEN}**********************${NC}"
echo "${GREEN}*** Prepare system ***${NC}"
echo "${GREEN}**********************${NC}"

echo 'Updating the system'
apt-get update -y --fix-missing
#sudo apt-get upgrade -y

echo 'Setting Frontend as Non-Interactive'
export DEBIAN_FRONTEND=noninteractive



echo "${GREEN}*************************${NC}"
echo "${GREEN}*** Creating database ***${NC}"
echo "${GREEN}*************************${NC}"
# sudo -u postgres -i

echo "Creating database ${OSMDatabaseName}"
sudo -u postgres -i createdb -E UTF8 -O ${OSMUserName} ${OSMDatabaseName}

if [ $? -ne 0 ]; then
    echo "${RED}Some problem has occurred while creating the database, exiting.${NC}"
    exit 1
else
    echo "Database created successfully."
fi

echo "Creating hstore extension on the ${OSMDatabaseName} database"
sudo -u postgres -i psql -c "CREATE EXTENSION hstore;" -d ${OSMDatabaseName}

if [ $? -ne 0 ]; then
    echo "${RED}Some problem has occurred while creating HSTORE extension, exiting.${NC}"
    exit 1
else
    echo "Extension created successfully."
fi

echo "Creating postgis extension on ${OSMDatabaseName} database"
sudo -u postgres -i psql -c "CREATE EXTENSION postgis;" -d ${OSMDatabaseName}

if [ $? -ne 0 ]; then
    echo "${RED}Some problem has occurred while creating POSTGIS extension, exiting.${NC}"
    exit 1
else
    echo "Extension created successfully."
fi



echo "${GREEN}********************************${NC}"
echo "${GREEN}*** PostgreSQL configuration ***${NC}"
echo "${GREEN}********************************${NC}"

PG_HBA_PATH='/etc/postgresql/10/main/pg_hba.conf'

if [ ! -e ${PG_HBA_PATH} ]; then
    echo "${RED}${PG_HBA_PATH} file not found.${NC}"
    #exit 1
else
    echo 'Set osm user authentication mode to "trust" for local connections'
    sudo sed -i "/^local   all             postgres                                trust/a local   all             $OSMUserName                                trust" ${PG_HBA_PATH}
fi



echo "${GREEN}*****************************${NC}"
echo "${GREEN}*** Creating service user ***${NC}"
echo "${GREEN}*****************************${NC}"

# Create osm user on your operating system so the tile server can run as osm user.
echo "creating operating system user ${OSMUserName}"
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
# sudo useradd -m ${OSMUserName}
useradd -m ${OSMUserName}

if [ $? -ne 0 ]; then
    echo "${RED}Some problem has occurred while creating service user, exiting.${NC}"
    exit 1
else
    echo "Service user created successfully."
fi



echo "${GREEN}****************************${NC}"
echo "${GREEN}*** Installing osm2pgsql ***${NC}"
echo "${GREEN}****************************${NC}"

if [ ! -d ${OSMUserHome}/src ]; then

    cd ${OSMUserHome}
    echo "creating [${OSMUserHome}/src] folder"
    mkdir src

    # set OSM user owner
    chown -R ${OSMUserName}:${OSMUserName} src
fi

cd ${OSMUserHome}/src
git clone git://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql

echo 'Installing osm2pgsql dependecies'
apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libproj-dev lua5.2 liblua5.2-dev

if [ $? -ne 0 ]; then
    echo "${RED}Some error has occurred while installing osm2pgsql dependecies, exiting.${NC}"
    exit 1
else
    echo "osm2pgsql dependecies installed successfully."
fi

echo 'Installing osm2pgsql'
mkdir build && cd build

cmake ..

if [ $? -ne 0 ]; then
    echo "${RED}cmake failed, exiting.${NC}"
    exit 1
else
    echo "${CYAN}cmake${NC} ran succesfuly, continuing with script."
fi

make

if [ $? -ne 0 ]; then
    echo "${RED}make failed, exiting.${NC}"
    exit 1
else
    echo "${CYAN}make${NC} ran succesfuly, continuing with script."
fi

make install

if [ $? -ne 0 ]; then
    echo "${RED}make install failed, exiting.${NC}"
    exit 1
else
    echo "${CYAN}make install${NC} ran succesfuly, continuing with script."
fi



echo "${GREEN}*************************${NC}"
echo "${GREEN}*** Download Map Data ***${NC}"
echo "${GREEN}*************************${NC}"

echo "downloading from ${MapDataUri}/${MapDataFileName}"
# sudo su - $OSMUserName

if [ ! -d ${OSMUserHome}/data ]; then

    cd ${OSMUserHome}

    echo "creating ${OSMUserHome}/data folder"
    mkdir data

    if [ $? -ne 0 ]; then
        echo "${RED}Unable to create ${OSMUserHome}/data folder.${NC}"
        exit 1
    else
        echo "Folder ${OSMUserHome}/data created successfully."
    fi

    # set OSM user owner
    chown -R ${OSMUserName}:${OSMUserName} data
fi

cd ${OSMUserHome}/data

wget -c ${MapDataUri}/${MapDataFileName}
# wget -c $(~/map_data_url_provider.sh ${OSMRegion})

# Recommendations before Importing Map Data
# sudo fallocate -l 2G /swapfile
# sudo chmod 600 /swapfile
# sudo mkswap /swapfile
# sudo swapon /swapfile

# The import process can take some time. It’s recommended to configure SSH keepalive so that you don’t lose the SSH connection. It’s very easy to do. Just open the SSH client configuration file on your local Linux machine.
# sudo nano /etc/ssh/ssh_config

# And paste the following text at the end of the file.
# ServerAliveInterval 60



echo "${GREEN}*********************************${NC}"
echo "${GREEN}*** NPM + NodeJs Installation ***${NC}"
echo "${GREEN}*********************************${NC}"
apt-get install -y npm nodejs

if [ $? -ne 0 ]; then
    echo "${RED}Unable to install NPM  or NodeJs.${NC}"
    exit 1
else
    echo "NPM and NodeJs installed succesfuly."
fi



echo "${GREEN}**************************${NC}"
echo "${GREEN}*** Carto Installation ***${NC}"
echo "${GREEN}**************************${NC}"
npm install -g carto

if [ $? -ne 0 ]; then
    echo "${RED}Unable to install Carto.${NC}"
    exit 1
else
    echo "Carto installed succesfuly."
    echo "carto -v: $(carto -v)"
fi



echo "${GREEN}********************************${NC}"
echo "${GREEN}*** Stylesheet configuration ***${NC}"
echo "${GREEN}********************************${NC}"
cd ${OSMUserHome}/src

# wget https://github.com/gravitystorm/openstreetmap-carto/archive/v4.21.1.tar.gz
# tar xvf v4.21.1.tar.gz
# rm v4.21.1.tar.gz

echo "cloning openstreetmap-carto repository"
git clone git://github.com/gravitystorm/openstreetmap-carto.git

if [ $? -ne 0 ]; then
    echo "${RED}Unable to clone openstreetmap-carto repository.${NC}"
    exit 1
else
    echo "openstreetmap-carto repository cloned successfully."
fi

# chown -R ${OSMUserName}:${OSMUserName} openstreetmap-carto
chown -R ${OSMUserName} openstreetmap-carto
cd openstreetmap-carto

carto project.mml | tee mapnik.xml



echo "${GREEN}*****************************************${NC}"
echo "${GREEN}*** Import the Map Data to PostgreSQL ***${NC}"
echo "${GREEN}*****************************************${NC}"

echo 'running osm2pgsql'
# osm2pgsql -U postgres --slim -d ${OSMDatabaseName} -C 1800 --hstore --create -G --number-processes 1 ~/data/${MapDataFileName}
osm2pgsql -U postgres --slim -d ${OSMDatabaseName} -C 1800 --hstore --tag-transform-script ${OSMUserHome}/src/openstreetmap-carto/openstreetmap-carto.lua --create -G --number-processes 1 -S ${OSMUserHome}/src/openstreetmap-carto/openstreetmap-carto.style ${OSMUserHome}/data/${MapDataFileName}

# osm2pgsql -U $OSMUserName --slim -d ${OSMDatabaseName} -C 1800 --hstore --create -G --number-processes 1 ~/data/${MapDataFileName}
# osm2pgsql -U postgres --slim -d ${OSMDatabaseName} -C 1800 --hstore -S ~/src/openstreetmap-carto/openstreetmap-carto.style --create -G --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes 1  ~/data/${MapDataFileName}

if [ $? -ne 0 ]; then
    echo "${RED}some error has occurred running osm2pgsql.${NC}"
    exit 1
else
    echo "osm2pgsql imported data successfully."
fi


echo "${GREEN}******************************************************${NC}"
echo "${GREEN}*** Granting all privileges to ${OSMUserName} user ***${NC}"
echo "${GREEN}******************************************************${NC}"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${OSMUserName};" -d ${OSMDatabaseName}





echo "${GREEN}Congrats! You just successfully built your own GIS OSM DB server.${NC}"