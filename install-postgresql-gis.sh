#!/bin/bash
OSMUserName=$1
OSMDBPassword=$2
OSMRegion=$3

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

WORKING_DIR=$(pwd)

# *** Step 0 - Prepare system ***
echo '*******************************'
echo '*** Step 0 - Prepare system ***'
echo '*******************************'
#sudo apt-get update -y
#sudo apt-get upgrade -y
echo '* Setting Frontend as Non-Interactive *'
export DEBIAN_FRONTEND=noninteractive

# *** Step 1 - Install PostgreSQL Database Server with PostGIS ***
echo '****************************************************************'
echo '*** Step 1 - Install PostgreSQL Database Server with PostGIS ***'
echo '****************************************************************'
sudo apt-get install -y postgresql postgresql-contrib postgis postgresql-10-postgis-2.4 postgresql-10-postgis-scripts

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# sudo -u postgres -i

# create a PostgreSQL database user osm
echo 'Creating PostgreSQL database user ['$OSMUserName']'
sudo -u postgres createuser $OSMUserName

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Setting password to ['$OSMUserName'] database user'
sudo -u postgres psql -c "ALTER USER $OSMUserName WITH PASSWORD '$OSMDBPassword';"

echo 'Creating PostgreSQL gis database'
sudo -u postgres createdb -E UTF8 -O $OSMUserName gis

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Creating hstore extension on the gis database'
sudo -u postgres psql -c "CREATE EXTENSION hstore;" -d gis

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Creating postgis extension on gis database'
command="CREATE EXTENSION postgis;"
echo 'PostgreSQL - Executing command:'$postgis_command
sudo -u postgres psql -c $command -d gis

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Step 2 - PostgreSQL configuration ***
echo '****************************************************************'
echo '*** Step 2 - PostgreSQL configuration ***'
echo '****************************************************************'

# Changing PostgreSQL authentication mode
echo 'Set PostgreSQL authentication mode to "trust" for local connections'
sudo sed -i "s/local   all             postgres                                peer/local   all             postgres                                trust/g" /etc/postgresql/10/main/pg_hba.conf

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Allow remote connection from any ip'
sudo sed -i "s/host    all             all             127.0.0.1\/32            md5/host    all             all             0.0.0.0\/0               md5/g" /etc/postgresql/10/main/pg_hba.conf

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# restarting postgres
echo '* restarting postgres *'
sudo service postgresql restart

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# *** Step 3: Installing osm2pgsql ***
echo '************************************'
echo '*** Step 3: Installing osm2pgsql ***'
echo '************************************'

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

# *** Step 4: Download Map Data ***
echo '*********************************'
echo '*** Step 4: Download Map Data ***'
echo '*********************************'
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

# *** Step 5: Import the Map Data to PostgreSQL ***
echo '*************************************************'
echo '*** Step 5: Import the Map Data to PostgreSQL ***'
echo '*************************************************'

echo '* running osm2pgsql *'

# osm2pgsql -U postgres --slim -d gis -C 1800 --hstore --create -G --number-processes 1 ~/data/$MapDataFileName
osm2pgsql -U $OSMUserName --slim -d gis -C 1800 --hstore --create -G --number-processes 1 ~/data/$MapDataFileName

# osm2pgsql -U postgres --slim -d gis -C 1800 --hstore -S ~/src/openstreetmap-carto/openstreetmap-carto.style --create -G --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes 1  ~/data/$MapDataFileName



echo 'Granting all privileges to ['$OSMUserName'] user'
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $OSMUserName;" -d gis



echo 'Congrats! You just successfully built your own OSM DB server.'
