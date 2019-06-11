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
	*)
		echo "Unkown country or territory"
        exit
		;;
esac

# MapDataFileName=$CentralAmericaMapFileName



WORKING_DIR=$(pwd)


echo 'using user: '$(whoami)' current directory: '$(WORKING_DIR)



# *** Step 1 - Prepare system ***
echo "*** Step 1 - Prepare system ***"
#sudo apt-get update -y
#sudo apt-get upgrade -y
echo "* Setting Frontend as Non-Interactive *"
export DEBIAN_FRONTEND=noninteractive



# *** Step 2 - Install PostgreSQL Database Server with PostGIS ***
echo "*** Step 2 - Install PostgreSQL Database Server with PostGIS ***"
sudo apt-get install postgresql postgresql-contrib postgis postgresql-10-postgis-2.4 -y

# sudo -u postgres -i

# create a PostgreSQL database user osm
sudo -u postgres createuser $OSMUserName

sudo -u postgres createdb -E UTF8 -O $OSMUserName gis

# Create hstore and postgis extension on the gis database
sudo -u postgres psql -c "CREATE EXTENSION hstore;" -d gis

sudo -u postgres psql -c "CREATE EXTENSION postgis;" -d gis


# exit

# Create osm user on your operating system so the tile server can run as osm user.
echo '* creating operating system user ['$OSMUserName'] *'
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
sudo useradd -m $OSMUserName

OSMUserHome=/home/$OSMUserName/



# *** Step 3: Download Map Stylesheet and Map Data ***
echo '*** Step 3: Download Map Stylesheet and Map Data ('$MapDataUri/$MapDataFileName')***'
# sudo su - $OSMUserName

wget https://github.com/gravitystorm/openstreetmap-carto/archive/v4.21.1.tar.gz

tar xvf v4.21.1.tar.gz

sudo mv openstreetmap-carto-4.21.1 $OSMUserHome

wget -c $MapDataUri/$MapDataFileName

sudo mv $MapDataFileName $OSMUserHome

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
echo '*** Step 4: Import the Map Data to PostgreSQL ***'
sudo apt-get install osm2pgsql -y

# sudo su - $OSMUserName

echo 'using user: '$(whoami)' current directory: '$(pwd)

echo 'running osm2pgsql'
# osm2pgsql --slim -d gis -C 3600 --hstore -S openstreetmap-carto-4.21.1/openstreetmap-carto.style $MapDataFileName
osm2pgsql -U postgres --slim -d gis -C 1800 --hstore -S $OSMUserHome/openstreetmap-carto-4.21.1/openstreetmap-carto.style $OSMUserHome/$MapDataFileName

# osm2gpsql will run in slim mode which is recommended over the normal mode. -d stands for --database. -C flag specify the cache size in MB. Bigger cache size results in faster import speed but you need to have enough RAM to use cache. -S flag specify the style file. And finally you need to specify the map data file.

# exit



# *** Step 5: Install mod_tile ***
echo '*** Step 5: Install mod_tile ***'
# mod_tile is an Apache module that is required to serve tiles. Currently no binary package is available for Ubuntu. We can compile it from Github repository.

# First install build dependency.
echo '* Install build dependency *'
sudo apt-get install git autoconf libtool libmapnik-dev apache2-dev -y


echo 'using user: '$(whoami)' current directory: '$(pwd)

echo '* cloning mod_tile from GitHub *'
git clone https://github.com/openstreetmap/mod_tile.git

cd mod_tile/

# Compile and install
echo '* Compile and install *'
./autogen.sh
./configure
sudo make
sudo make install
sudo make install-mod_tile

sudo ldconfig
cd ..



# *** Step 6: Generate Mapnik Stylesheet ***
echo '*** Step 6: Generate Mapnik Stylesheet ***'
echo 'using user: '$(whoami)' current directory: '$(pwd)
sudo apt-get install curl unzip gdal-bin mapnik-utils node-carto -y

sudo apt-get install npm nodejs -y

sudo npm install -g carto

sudo su - $OSMUserName


cd $OSMUserHome

sudo chown -R $OSMUserName:$OSMUserName openstreetmap-carto-4.21.1/

cd openstreetmap-carto-4.21.1/

# ./get-shapefiles.sh
./scripts/get-shapefiles.py

carto project.mml > style.xml

cd ..

# exit


# *** Step 7: Configuring renderd ***
echo '*** Step 7: Configuring renderd ***'
echo 'using user: '$(whoami)' current directory: '$(pwd)
echo '* replacing values in renderd.conf *'
# In the [default] section, change the value of XML and HOST to
# XML=/home/osm/openstreetmap-carto-2.41.0/style.xml
# HOST=localhost
# sed -i "s/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/g" /usr/local/etc/renderd.conf
sed -i "s/XML=\/home\/jburgess\/osm\/svn.openstreetmap.org\/applications\/rendering\/mapnik\/osm-local.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/g" /usr/local/etc/renderd.conf

sed -i "s/HOST=tile.openstreetmap.org/HOST=localhost/g" /usr/local/etc/renderd.conf

# In [mapnik] section, change the value of plugins_dir
sed -i "s/plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/lib\/mapnik\/3.0\/input/g" /usr/local/etc/renderd.conf

echo '* installing required fonts *'
sudo apt-get install fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont -y


cd $WORKING_DIR

# Install renderd init script by copying the sample init script.
echo '* Install renderd init script by copying the sample init script *'
sudo cp mod_tile/debian/renderd.init /etc/init.d/renderd

# Grant execute permission
echo '* Grant execute permission *'
sudo chmod a+x /etc/init.d/renderd

echo '* replacing values in init.d/renderd *'
# Change the following variable in /etc/init.d/renderd file
sed -i "s/DAEMON=\/usr\/bin\/\$NAME/DAEMON=\/usr\/local\/bin\/\$NAME/g" /etc/init.d/renderd
sed -i "s/DAEMON_ARGS=\"\"/DAEMON_ARGS=\"-c \/usr\/local\/etc\/renderd.conf\"/g" /etc/init.d/renderd
sed -i "s/RUNASUSER=www-data/RUNASUSER=osm/g" /etc/init.d/renderd


sudo mkdir -p /var/lib/mod_tile

# sudo chown osm:osm /var/lib/mod_tile
sudo chown $OSMUserName:$OSMUserName /var/lib/mod_tile


# start renderd service
echo '* start renderd service *'
sudo systemctl daemon-reload

sudo systemctl start renderd

sudo systemctl enable renderd



# *** Step 8: Configure Apache ***
echo '*** Step 8: Configure Apache ***'
sudo apt-get install apache2 -y

# Create a module load file
echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" | sudo tee /etc/apache2/mods-available/mod_tile.load


# Create a symlink
sudo ln -s /etc/apache2/mods-available/mod_tile.load /etc/apache2/mods-enabled/


# Then edit the default virtual host file.

# sudo nano /etc/apache2/sites-enabled/000-default.conf
# Paste the following lines in <VirtualHost *:80>

# LoadTileConfigFile /usr/local/etc/renderd.conf
# ModTileRenderdSocketName /var/run/renderd/renderd.sock
# # Timeout before giving up for a tile to be rendered
# ModTileRequestTimeout 0
# # Timeout before giving up for a tile to be rendered that is otherwise missing
# ModTileMissingRequestTimeout 30

wget https://raw.githubusercontent.com/jojoblaze/my-osm/master/000-default.conf

mv 000-default.conf /etc/apache2/sites-enabled/000-default.conf

# Save and close the file. Restart Apache.
echo '* Save and close the file. Restart Apache. *'
sudo systemctl restart apache2



# Then in your web browser address bar, type

# your-server-ip/osm_tiles/0/0/0.png
# You should see the tile of world map. Congrats! You just successfully built your own OSM tile server.