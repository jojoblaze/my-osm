#!/bin/bash
OSMUserName=$1
OSMDBPassword=$2
OSMRegion=$3
OSMDatabaseName=$4

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

case $OSMRegion in
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
    echo '@@@ Unkown country or territory @@@'
    exit 1
    ;;
esac



# *** Prepare system ***
echo '**********************'
echo '*** Prepare system ***'
echo '**********************'

echo 'Updating the system'
sudo apt-get update -y --fix-missing
#sudo apt-get upgrade -y

echo '* Setting Frontend as Non-Interactive *'
export DEBIAN_FRONTEND=noninteractive


# sudo -u postgres -i


echo 'Creating PostgreSQL [$OSMDatabaseName] database'
sudo -u postgres createdb -E UTF8 -O $OSMUserName $OSMDatabaseName

echo 'Creating hstore extension on the [$OSMDatabaseName] database'
sudo -u postgres psql -c "CREATE EXTENSION hstore;" -d $OSMDatabaseName

echo 'Creating postgis extension on [$OSMDatabaseName] database'
sudo -u postgres psql -c "CREATE EXTENSION postgis;" -d $OSMDatabaseName



echo '*****************************'
echo '*** Creating service user ***'
echo '*****************************'
# Create osm user on your operating system so the tile server can run as osm user.
echo '* creating operating system user ['$OSMUserName'] *'
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
sudo useradd -m $OSMUserName



# *** Installing osm2pgsql ***
echo '****************************'
echo '*** Installing osm2pgsql ***'
echo '****************************'

cd ~
mkdir ~/src
cd ~/src
git clone git://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql

echo 'Installing osm2pgsql dependecies...'
sudo apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libproj-dev lua5.2 liblua5.2-dev

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Installing osm2pgsql...'
mkdir build && cd build
cmake ..

make

sudo make install

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Download Map Data ***
echo '*************************'
echo '*** Download Map Data ***'
echo '*************************'
echo '(downloading from '$MapDataUri/$MapDataFileName')'
# sudo su - $OSMUserName

cd ~
mkdir ~/data
cd ~/data
wget -c $MapDataUri/$MapDataFileName
# wget -c $(~/map_data_url_provider.sh $OSMRegion)

# Recommendations before Importing Map Data
# sudo fallocate -l 2G /swapfile
# sudo chmod 600 /swapfile
# sudo mkswap /swapfile
# sudo swapon /swapfile

# The import process can take some time. It’s recommended to configure SSH keepalive so that you don’t lose the SSH connection. It’s very easy to do. Just open the SSH client configuration file on your local Linux machine.
# sudo nano /etc/ssh/ssh_config

# And paste the following text at the end of the file.
# ServerAliveInterval 60

# *** Import the Map Data to PostgreSQL ***
echo '*****************************************'
echo '*** Import the Map Data to PostgreSQL ***'
echo '*****************************************'

echo '* running osm2pgsql *'
osm2pgsql -U postgres --slim -d $OSMDatabaseName -C 1800 --hstore --create -G --number-processes 1 ~/data/$MapDataFileName
# osm2pgsql -U $OSMUserName --slim -d $OSMDatabaseName -C 1800 --hstore --create -G --number-processes 1 ~/data/$MapDataFileName

# osm2pgsql -U postgres --slim -d $OSMDatabaseName -C 1800 --hstore -S ~/src/openstreetmap-carto/openstreetmap-carto.style --create -G --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes 1  ~/data/$MapDataFileName

echo '***************************************'
echo '*** Granting all privileges to user ***'
echo '***************************************'

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $OSMUserName;" -d $OSMDatabaseName

echo 'Congrats! You just successfully built your own GIS OSM DB server.'