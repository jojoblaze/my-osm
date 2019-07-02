#!/bin/bash
OSMUserName=$1
OSMDBPassword=$2
OSMDatabaseName=$3
OSMRegion=$4


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

OSMUserHome=/home/$OSMUserName



echo '**********************'
echo '*** Prepare system ***'
echo '**********************'

echo 'Updating the system'
sudo apt-get update -y --fix-missing
#sudo apt-get upgrade -y

echo '* Setting Frontend as Non-Interactive *'
export DEBIAN_FRONTEND=noninteractive




echo '*************************'
echo '*** Creating database ***'
echo '*************************'
# sudo -u postgres -i

echo "Creating PostgreSQL [$OSMDatabaseName] database"
sudo -u postgres -i createdb -E UTF8 -O $OSMUserName $OSMDatabaseName

echo "Creating hstore extension on the [$OSMDatabaseName] database"
sudo -u postgres -i psql -c "CREATE EXTENSION hstore;" -d $OSMDatabaseName

echo "Creating postgis extension on [$OSMDatabaseName] database"
sudo -u postgres -i psql -c "CREATE EXTENSION postgis;" -d $OSMDatabaseName


echo '********************************'
echo '*** PostgreSQL configuration ***'
echo '********************************'

PG_HBA_PATH='/etc/postgresql/10/main/pg_hba.conf'

if [[ ! -f $PG_HBA_PATH ]]; then
    echo "[$PG_HBA_PATH] file not found"
else
    echo 'Set osm user authentication mode to "trust" for local connections'
    sudo sed -i "/^local   all             postgres                                trust/a local   all             $OSMUserName                                trust" $PG_HBA_PATH
fi



echo '*****************************'
echo '*** Creating service user ***'
echo '*****************************'
# Create osm user on your operating system so the tile server can run as osm user.
echo "* creating operating system user [$OSMUserName] *"
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
sudo useradd -m $OSMUserName



# *** Installing osm2pgsql ***
echo '****************************'
echo '*** Installing osm2pgsql ***'
echo '****************************'

if [[ ! -d $OSMUserHome/src ]]; then

    cd $OSMUserHome
    echo "*** creating [$OSMUserHome/src] folder"
    mkdir src

    # set OSM user owner
    chown -R $OSMUserName:$OSMUserName src
fi

cd $OSMUserHome/src
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



if [[ ! -d $OSMUserHome/src/data ]]; then

    cd $OSMUserHome/src

    echo "*** creating [$OSMUserHome/src/data] folder ***"
    mkdir data

    # set OSM user owner
    chown -R $OSMUserName:$OSMUserName data
fi

cd $OSMUserHome/src/data

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



echo '***************************'
echo '*** NodeJs Installation ***'
echo '***************************'

sudo apt-get install -y npm nodejs

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



echo '**************************'
echo '*** Carto Installation ***'
echo '**************************'

sudo npm install -g carto

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Stylesheet configuration ***
echo '********************************'
echo '*** Stylesheet configuration ***'
echo '********************************'

cd $OSMUserHome/src

# wget https://github.com/gravitystorm/openstreetmap-carto/archive/v4.21.1.tar.gz
# tar xvf v4.21.1.tar.gz
# rm v4.21.1.tar.gz
git clone git://github.com/gravitystorm/openstreetmap-carto.git

chown -R $OSMUserName:$OSMUserName openstreetmap-carto
cd openstreetmap-carto

echo "carto -v: $(carto -v)"

carto project.mml | tee mapnik.xml



# *** Shapefile download ***
echo '**************************'
echo '*** Shapefile download ***'
echo '**************************'

cd $OSMUserHome/src/openstreetmap-carto/scripts

echo '*** running get-shapefiles.py ***'
./get-shapefiles.py

if [[ $? > 0 ]]; then
    echo "*** The command failed, exiting. ***"
    exit
else
    echo "*** Shape files downloaded successfully. ***"
fi

echo '*** installing required fonts ***'
sudo apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "*** Fonts installed successfully. ***"
fi



# *** Import the Map Data to PostgreSQL ***
echo '*****************************************'
echo '*** Import the Map Data to PostgreSQL ***'
echo '*****************************************'

echo '* running osm2pgsql *'
# osm2pgsql -U postgres --slim -d $OSMDatabaseName -C 1800 --hstore --create -G --number-processes 1 ~/data/$MapDataFileName
osm2pgsql -U postgres --slim -d $OSMDatabaseName -C 1800 --hstore --tag-transform-script $OSMUserHome/src/openstreetmap-carto/openstreetmap-carto.lua --create -G --number-processes 1 -S $OSMUserHome/src/openstreetmap-carto/openstreetmap-carto.style ~/data/$MapDataFileName

# osm2pgsql -U $OSMUserName --slim -d $OSMDatabaseName -C 1800 --hstore --create -G --number-processes 1 ~/data/$MapDataFileName
# osm2pgsql -U postgres --slim -d $OSMDatabaseName -C 1800 --hstore -S ~/src/openstreetmap-carto/openstreetmap-carto.style --create -G --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes 1  ~/data/$MapDataFileName



echo "******************************************************"
echo "*** Granting all privileges to [$OSMUserName] user ***"
echo "******************************************************"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $OSMUserName;" -d $OSMDatabaseName

echo 'Congrats! You just successfully built your own GIS OSM DB server.'