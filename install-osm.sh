#!/bin/bash
OSMUserName=$1
OSMRegion=$2


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
MapDataUriItaly=https://download.geofabrik.de/europe/italy/
ItalyNorthWestMapFileName=nord-ovest-latest.osm.pbf
ItalyNorthEastMapFileName=nord-est.html
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
    europe/italy)
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
		echo "Unkown country or territory"
        exit
		;;
esac

# MapDataFileName=$CentralAmericaMapFileName



WORKING_DIR=$(pwd)


echo 'using user: '$(whoami)' current directory: '$(WORKING_DIR)



# *** Step 0 - Prepare system ***
echo '*******************************'
echo '*** Step 0 - Prepare system ***'
echo '*******************************'
#sudo apt-get update -y
#sudo apt-get upgrade -y
echo '* Setting Frontend as Non-Interactive *'
export DEBIAN_FRONTEND=noninteractive



# *** Step 1 - Install dependencies ***
echo '*************************************'
echo '*** Step 1 - Install dependencies ***'
echo '*************************************'
sudo apt-get install -y autoconf autogen automake apache2 apache2-dev build-essential bzip2 curl git-core git libboost-all-dev libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev libprotobuf-c0-dev libfreetype6-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev libagg-dev lua5.1 liblua5.1-dev liblua5.2-dev libgeotiff-epsg munin-node munin pkg-config protobuf-c-compiler tar ttf-unifont unzip wget 

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Step 2 - Install PostgreSQL Database Server with PostGIS ***
echo '****************************************************************'
echo '*** Step 2 - Install PostgreSQL Database Server with PostGIS ***'
echo '****************************************************************'
sudo apt-get install -y postgresql postgresql-contrib postgis postgresql-10-postgis-2.4 postgresql-10-postgis-scripts


if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


# sudo -u postgres -i

# create a PostgreSQL database user osm
echo 'Creating PostgreSQL database user ['$OSMUserName']'
sudo -u postgres createuser $OSMUserName || echo "Unable to create PostgreSQL user $OSMUserName" && exit

sudo -u postgres createdb -E UTF8 -O $OSMUserName gis || echo "Unable to create gis database" && exit

# Create hstore and postgis extension on the gis database
sudo -u postgres psql -c "CREATE EXTENSION hstore;" -d gis || echo "Unable to create hstore extension" && exit

postgis_command="CREATE EXTENSION postgis; ALTER TABLE geometry_columns OWNER TO $OSMUserName; ALTER TABLE geometry_columns OWNER TO $OSMUserName;"
echo 'PostgreSQL - Executing command:'$postgis_command
sudo -u postgres psql -c $postgis_command -d gis || echo "Unable to create postgis extension" && exit

# sudo -u postgres psql -c "ALTER TABLE geometry_columns OWNER TO $OSMUserName;" -d gis

# sudo -u postgres psql -c "ALTER TABLE geometry_columns OWNER TO $OSMUserName;" -d gis

# exit

# Create osm user on your operating system so the tile server can run as osm user.
echo '* creating operating system user ['$OSMUserName'] *'
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
sudo useradd -m $OSMUserName || echo "Unable to create $OSMUserName user" && exit

OSMUserHome=/home/$OSMUserName/



# *** Step 3: Download Map Stylesheet and Map Data ***
echo '****************************************************'
echo '*** Step 3: Download Map Stylesheet and Map Data ***'
echo '****************************************************'

echo '(downloading from '$MapDataUri/$MapDataFileName')'
# sudo su - $OSMUserName

cd $OSMUserHome

wget https://github.com/gravitystorm/openstreetmap-carto/archive/v4.21.1.tar.gz

tar xvf v4.21.1.tar.gz

rm v4.21.1.tar.gz

wget -c $MapDataUri/$MapDataFileName

# exit


# Recommendations before Importing Map Data
# sudo fallocate -l 2G /swapfile
# sudo chmod 600 /swapfile
# sudo mkswap /swapfile
# sudo swapon /swapfile

# The import process can take some time. It’s recommended to configure SSH keepalive so that you don’t lose the SSH connection. It’s very easy to do. Just open the SSH client configuration file on your local Linux machine.
# sudo nano /etc/ssh/ssh_config

# And paste the following text at the end of the file.
# ServerAliveInterval 60



# *** Step 4: Import the Map Data to PostgreSQL ***
echo '*************************************************'
echo '*** Step 4: Import the Map Data to PostgreSQL ***'
echo '*************************************************'

echo 'Installing osm2pgsql...'
sudo apt-get install -y osm2pgsql

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



cd $OSMUserHome
echo 'using user: '$(whoami)' current directory: '$(pwd)
# sudo su - $OSMUserName

# changing authentication mode
echo 'Changing PostgreSQL authentication mode...'
sed -i "s/local   all             postgres                                peer/local   all             postgres                                trust/g" /etc/postgresql/10/main/pg_hba.conf

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# restarting postgres
echo '* restarting postgres *'
sudo service postgresql restart

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



echo '* running osm2pgsql *'
# osm2pgsql --slim -d gis -C 3600 --hstore -S openstreetmap-carto-4.21.1/openstreetmap-carto.style $MapDataFileName
osm2pgsql -U postgres --slim -d gis -C 1800 --hstore -S $OSMUserHome/openstreetmap-carto-4.21.1/openstreetmap-carto.style $OSMUserHome/$MapDataFileName

# osm2gpsql will run in slim mode which is recommended over the normal mode. -d stands for --database. -C flag specify the cache size in MB. Bigger cache size results in faster import speed but you need to have enough RAM to use cache. -S flag specify the style file. And finally you need to specify the map data file.

# exit
if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Step 5: Install mod_tile ***
echo '********************************'
echo '*** Step 5: Install mod_tile ***'
echo '********************************'
# mod_tile is an Apache module that is required to serve tiles. Currently no binary package is available for Ubuntu. We can compile it from Github repository.

cd $OSMUserHome

# mkdir ~/src && cd ~/src
sudo mkdir src && cd src

echo 'using user: '$(whoami)' current directory: '$(pwd)

echo '* cloning mod_tile from GitHub *'
# git clone https://github.com/openstreetmap/mod_tile.git
git clone https://github.com/SomeoneElseOSM/mod_tile.git

cd mod_tile/

# Compile and install
echo 'Running autogen...'
sudo ./autogen.sh

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Running configure...'
sudo ./configure

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Running make...'
sudo make

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Running make install...'
sudo make install

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Running make install-mod_tile...'
sudo make install-mod_tile

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo ldconfig


sudo mkdir /var/run/renderd
sudo chown -R $OSMUserName:$OSMUserName /var/run/renderd



# *** Step 6: Generate Mapnik Stylesheet ***
echo '******************************************'
echo '*** Step 6: Generate Mapnik Stylesheet ***'
echo '******************************************'
echo 'using user: '$(whoami)' current directory: '$(pwd)



echo 'installing required fonts'
sudo apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



sudo apt-get install gdal-bin libmapnik-dev mapnik-utils python-mapnik node-carto -y

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



sudo apt-get install npm nodejs -y

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# * check mapnik version *
MAPNIK_EXPECTED_VERSION="3.0.19"
if [ $(mapnik-config -v) != $MAPNIK_EXPECTED_VERSION ]
then
    echo 'ASSERT FAILED: expected mapnik version '$MAPNIK_EXPECTED_VERSION >>/dev/stderr
fi



sudo npm install -g carto

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



sudo su - $OSMUserName


cd $OSMUserHome

sudo chown -R $OSMUserName:$OSMUserName openstreetmap-carto-4.21.1/

cd openstreetmap-carto-4.21.1/

# ./get-shapefiles.sh
./scripts/get-shapefiles.py

carto project.mml > style.xml || echo "Something goes wrong executing carto" && exit

cd ..

# exit



# *** Step 7: Configuring renderd ***
echo '***********************************'
echo '*** Step 7: Configuring renderd ***'
echo '***********************************'
echo 'using user: '$(whoami)' current directory: '$(pwd)

echo '* replacing values in renderd.conf *'
# RENDERD_CONF_PATH='/usr/local/etc/renderd.conf'
RENDERD_CONF_PATH='/home/osm/src/mod_tile/debian/renderd.conf'

# In the [default] section, change the value of XML and HOST to
# XML=/home/osm/openstreetmap-carto-2.41.0/style.xml
# HOST=localhost
echo 'Replacing the value of XML [default] section'
sudo sed -i "s/^XML=\/home\/jburgess\/osm\/svn.openstreetmap.org\/applications\/rendering\/mapnik\/osm-local.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/g" $RENDERD_CONF_PATH

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


echo 'Replacing the value of HOST [default] section'
sudo sed -i "s/^HOST=tile.openstreetmap.org/HOST=$HOSTNAME/g" $RENDERD_CONF_PATH

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


# Replacing the value of plugins_dir [mapnik] section
echo 'Replacing the value of plugins_dir [mapnik] section'
sudo sed -i "s/^plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/lib\/mapnik\/3.0\/input/g" $RENDERD_CONF_PATH

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



cd $WORKING_DIR

# Install renderd init script by copying the sample init script.
echo '* Install renderd init script by copying the sample init script *'
sudo cp mod_tile/debian/renderd.init /etc/init.d/renderd

# Grant execute permission
echo '* Grant execute permission *'
sudo chmod a+x /etc/init.d/renderd

echo '* replacing values in init.d/renderd *'
# Change the following variable in /etc/init.d/renderd file
sudo sed -i "s/DAEMON=\/usr\/bin\/\$NAME/DAEMON=\/usr\/local\/bin\/\$NAME/g" /etc/init.d/renderd

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# sudo sed -i "s/DAEMON_ARGS=\"\"/DAEMON_ARGS=\"-c \/usr\/local\/etc\/renderd.conf\"/g" /etc/init.d/renderd
sudo sed -i "s/DAEMON_ARGS=\"\"/DAEMON_ARGS=\"-c \/home\/osm\/mod_tile\/debian\/renderd.conf\"/g" /etc/init.d/renderd

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo sed -i "s/RUNASUSER=www-data/RUNASUSER=$OSMUserName/g" /etc/init.d/renderd

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo mkdir -p /var/lib/mod_tile || echo "Unable to create /var/lib/mod_tile folder" && exit

# sudo chown osm:osm /var/lib/mod_tile
sudo chown $OSMUserName:$OSMUserName /var/lib/mod_tile


# start renderd service
echo '* start renderd service *'
sudo systemctl daemon-reload

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'starting renderd...'
sudo systemctl start renderd

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'enabling renderd...'
sudo systemctl enable renderd

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Step 8: Configure Apache ***
echo '********************************'
echo '*** Step 8: Configure Apache ***'
echo '********************************'
sudo apt-get install apache2 -y

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# Create a module load file
echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" | sudo tee /etc/apache2/mods-available/mod_tile.load


# Create a symlink
sudo ln -s /etc/apache2/mods-available/mod_tile.load /etc/apache2/mods-enabled/


# Replace default virtual host file
wget https://raw.githubusercontent.com/jojoblaze/my-osm/master/000-default.conf

mv 000-default.conf /etc/apache2/sites-enabled/000-default.conf

# Save and close the file. Restart Apache.
echo '* Restart Apache. *'
sudo systemctl restart apache2

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


# Copy map file
echo 'Copying map file under /var/www/html'
cd /var/www/html/
wget https://raw.githubusercontent.com/jojoblaze/my-osm/master/map.html

echo 'Then in your web browser address bar, type: your-server-ip/osm_tiles/0/0/0.png'

echo 'Congrats! You just successfully built your own OSM tile server.'