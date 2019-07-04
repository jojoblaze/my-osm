#!/bin/bash
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
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color



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
    echo -e "${RED}Unkown country or territory${NC}"
    exit 1
    ;;
esac



OSMUserHome=/home/${OSMUserName}

echo -e "${GREEN}**********************${NC}"
echo -e "${GREEN}*** Prepare system ***${NC}"
echo -e "${GREEN}**********************${NC}"

echo 'Updating the system'
sudo apt-get update -y --fix-missing
#sudo apt-get upgrade -y

echo 'Setting Frontend as Non-Interactive'
export DEBIAN_FRONTEND=noninteractive



echo -e "${GREEN}*************************${NC}"
echo -e "${GREEN}*** Creating database ***${NC}"
echo -e "${GREEN}*************************${NC}"
# sudo -u postgres -i

echo "Creating database $(${OSMDatabaseName})"
sudo -u postgres -i createdb -E UTF8 -O ${OSMUserName} ${OSMDatabaseName}

echo "Creating hstore extension on the $(${OSMDatabaseName}) database"
sudo -u postgres -i psql -c "CREATE EXTENSION hstore;" -d ${OSMDatabaseName}

echo "Creating postgis extension on $(${OSMDatabaseName}) database"
sudo -u postgres -i psql -c "CREATE EXTENSION postgis;" -d ${OSMDatabaseName}



echo -e "${GREEN}********************************${NC}"
echo -e "${GREEN}*** PostgreSQL configuration ***${NC}"
echo -e "${GREEN}********************************${NC}"

PG_HBA_PATH='/etc/postgresql/10/main/pg_hba.conf'

if [[ ! -f ${PG_HBA_PATH} ]]; then
    echo -e "${RED}$(${PG_HBA_PATH}) file not found.${NC}"
    exit 1
else
    echo 'Set osm user authentication mode to "trust" for local connections'
    sudo sed -i "/^local   all             postgres                                trust/a local   all             $OSMUserName                                trust" ${PG_HBA_PATH}
fi



echo -e "${GREEN}*****************************${NC}"
echo -e "${GREEN}*** Creating service user ***${NC}"
echo -e "${GREEN}*****************************${NC}"

# Create osm user on your operating system so the tile server can run as osm user.
echo "creating operating system user $(${OSMUserName})"
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
sudo useradd -m ${OSMUserName}



echo -e "${GREEN}****************************${NC}"
echo -e "${GREEN}*** Installing osm2pgsql ***${NC}"
echo -e "${GREEN}****************************${NC}"
if [[ ! -d ${OSMUserHome}/src ]]; then

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
sudo apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libproj-dev lua5.2 liblua5.2-dev

if [[ $? > 0 ]]; then
    echo -e "${RED}Some error has occurred while installing osm2pgsql dependecies, exiting.${NC}"
    exit 1
else
    echo "osm2pgsql dependecies installed successfully."
fi

echo 'Installing osm2pgsql'
mkdir build && cd build
cmake ..

make

sudo make install

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi



echo -e "${GREEN}*************************${NC}"
echo -e "${GREEN}*** Download Map Data ***${NC}"
echo -e "${GREEN}*************************${NC}"
echo "downloading from ${MapDataUri}/${MapDataFileName}"
# sudo su - $OSMUserName

if [[ ! -d ${OSMUserHome}/data ]]; then

    cd ${OSMUserHome}

    echo "creating ${OSMUserHome}/data folder"
    mkdir data

    if [[ $? > 0 ]]; then
        echo -e "${RED}Unable to create ${OSMUserHome}/data folder.${NC}"
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



echo -e "${GREEN}***************************${NC}"
echo -e "${GREEN}*** NodeJs Installation ***${NC}"
echo -e "${GREEN}***************************${NC}"
sudo apt-get install -y npm nodejs

if [[ $? > 0 ]]; then
    echo -e "${RED}Unable to install NodeJs.${NC}"
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi



echo -e "${GREEN}**************************${NC}"
echo -e "${GREEN}*** Carto Installation ***${NC}"
echo -e "${GREEN}**************************${NC}"
sudo npm install -g carto

if [[ $? > 0 ]]; then
    echo -e "${RED}Unable to install Carto.${NC}"
    exit 1
else
    echo "Carto installed succesfuly."
    echo "carto -v: $(carto -v)"
fi



echo -e "${GREEN}********************************${NC}"
echo -e "${GREEN}*** Stylesheet configuration ***${NC}"
echo -e "${GREEN}********************************${NC}"
cd ${OSMUserHome}/src

# wget https://github.com/gravitystorm/openstreetmap-carto/archive/v4.21.1.tar.gz
# tar xvf v4.21.1.tar.gz
# rm v4.21.1.tar.gz

echo "cloning openstreetmap-carto repository"
git clone git://github.com/gravitystorm/openstreetmap-carto.git

if [[ $? > 0 ]]; then
    echo -e "${RED}Unable to clone openstreetmap-carto repository.${NC}"
    exit 1
else
    echo "openstreetmap-carto repository cloned successfully."
fi

# chown -R ${OSMUserName}:${OSMUserName} openstreetmap-carto
chown -R ${OSMUserName} openstreetmap-carto
cd openstreetmap-carto

carto project.mml | tee mapnik.xml



echo -e "${GREEN}**************************${NC}"
echo -e "${GREEN}*** Shapefile download ***${NC}"
echo -e "${GREEN}**************************${NC}"

cd ${OSMUserHome}/src/openstreetmap-carto

# # directory 'data' is created by script get-shapefiles.py
# # I need to create it before launch the script in order to give it right permissions
# if [[ ! -d ./data ]]; then

#     # create data directory
#     mkdir data

#     if [[ $? > 0 ]]; then
#         echo -e "${RED}Unable to create [${OSMUserHome}/src/openstreetmap-carto/data] folder.${NC}"
#         exit 1
#     else
#         echo "Folder ${OSMUserHome}/src/openstreetmap-carto/data created successfully."
#     fi

#     chown -R ${OSMUserName} data
# fi

cd ${OSMUserHome}/src/openstreetmap-carto

echo 'running get-shapefiles.py'
sudo ./scripts/get-shapefiles.py

if [[ $? > 0 ]]; then
    echo -e "${RED}Unable to download shape files.${NC}"
    exit 1
else
    echo "Shape files downloaded successfully."
fi

echo 'installing required fonts'
sudo apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont

if [[ $? > 0 ]]; then
    echo -e "${RED}Unable to install fonts.${NC}"
    exit 1
else
    echo "Fonts installed successfully."
fi



echo -e "${GREEN}*****************************************${NC}"
echo -e "${GREEN}*** Import the Map Data to PostgreSQL ***${NC}"
echo -e "${GREEN}*****************************************${NC}"

echo 'running osm2pgsql'
# osm2pgsql -U postgres --slim -d ${OSMDatabaseName} -C 1800 --hstore --create -G --number-processes 1 ~/data/${MapDataFileName}
osm2pgsql -U postgres --slim -d ${OSMDatabaseName} -C 1800 --hstore --tag-transform-script ${OSMUserHome}/src/openstreetmap-carto/openstreetmap-carto.lua --create -G --number-processes 1 -S ${OSMUserHome}/src/openstreetmap-carto/openstreetmap-carto.style ${OSMUserHome}/data/${MapDataFileName}

# osm2pgsql -U $OSMUserName --slim -d ${OSMDatabaseName} -C 1800 --hstore --create -G --number-processes 1 ~/data/${MapDataFileName}
# osm2pgsql -U postgres --slim -d ${OSMDatabaseName} -C 1800 --hstore -S ~/src/openstreetmap-carto/openstreetmap-carto.style --create -G --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes 1  ~/data/${MapDataFileName}

if [[ $? > 0 ]]; then
    echo -e "${RED}some error has occurred running osm2pgsql.${NC}"
    exit 1
else
    echo "osm2pgsql imported data successfully."
fi



echo -e "${GREEN}*********************************************************${NC}"
echo -e "${GREEN}*** Granting all privileges to $(${OSMUserName}) user ***${NC}"
echo -e "${GREEN}*********************************************************${NC}"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${OSMUserName};" -d ${OSMDatabaseName}



echo -e "${GREEN}Congrats! You just successfully built your own GIS OSM DB server.${NC}"