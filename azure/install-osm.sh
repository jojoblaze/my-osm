#!/bin/bash

PostgreSQLUserName=$1


# *** Step 1 - Update system ***
sudo apt update

sudo apt upgrade


# *** Step 2 - Install PostgreSQL Database Server with PostGIS ***
sudo apt install postgresql postgresql-contrib postgis postgresql-9.5-postgis-2.2

sudo -u postgres -i

# create a PostgreSQL database user osm
createuser $PostgreSQLUserName


createdb -E UTF8 -O $PostgreSQLUserName gis

# Create hstore and postgis extension on the gis database
psql -c "CREATE EXTENSION hstore;" -d gis

psql -c "CREATE EXTENSION postgis;" -d gis


exit

# Create osm user on your operating system so the tile server can run as osm user.
sudo adduser $PostgreSQLUserName



# *** Step 3: Download Map Stylesheet and Map Data ***
su - osm

wget https://github.com/gravitystorm/openstreetmap-carto/archive/v2.41.0.tar.gz


tar xvf v2.41.0.tar.gz


wget -c http://download.geofabrik.de/central-america-latest.osm.pbf

exit


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
sudo apt install osm2pgsql

su - $PostgreSQLUserName

osm2pgsql --slim -d gis -C 3600 --hstore -S openstreetmap-carto-2.41.0/openstreetmap-carto.style central-america-latest.osm.pbf

# osm2gpsql will run in slim mode which is recommended over the normal mode. -d stands for --database. -C flag specify the cache size in MB. Bigger cache size results in faster import speed but you need to have enough RAM to use cache. -S flag specify the style file. And finally you need to specify the map data file.

exit



# *** Step 5: Install mod_tile ***

# mod_tile is an Apache module that is required to serve tiles. Currently no binary package is available for Ubuntu. We can compile it from Github repository.

# First install build dependency.

sudo apt install git autoconf libtool libmapnik-dev apache2-dev

git clone https://github.com/openstreetmap/mod_tile.git

cd mod_tile/

# Compile and install
./autogen.sh
./configure
make
sudo make install
sudo make install-mod_tile

# *** Step 6: Generate Mapnik Stylesheet ***

sudo apt install curl unzip gdal-bin mapnik-utils node-carto

su - osm

cd openstreetmap-carto-2.41.0/

./get-shapefiles.sh

carto project.mml > style.xml

exit


# *** Step 7: Configuring renderd ***

# In the [default] section, change the value of XML and HOST to
# XML=/home/osm/openstreetmap-carto-2.41.0/style.xml
# HOST=localhost
sed -i "s/XML=\/home\/osm\/openstreetmap-carto-2.41.0\/style.xml/XML=\/home\/osm\/openstreetmap-carto-2.41.0\/style.xml/g" /usr/local/etc/renderd.conf
sed -i "s/HOST=tile.openstreetmap.org/HOST=localhost/g" /usr/local/etc/renderd.conf


# In [mapnik] section, change the value of plugins_dir
sed -i "s/plugins_dir=\/usr\/lib\/mapnik\/input\//plugins_dir=\/usr\/lib\/mapnik\/3.0\/input\//g" /usr/local/etc/renderd.conf


# Install renderd init script by copying the sample init script.
sudo cp mod_tile/debian/renderd.init /etc/init.d/renderd

# Grant execute permission
sudo chmod a+x /etc/init.d/renderd

# Change the following variable in /etc/init.d/renderd file
sed -i "s/DAEMON=\/usr\/bin\/\$NAME/DAEMON=\/usr\/local\/bin\/\$NAME/g" /etc/init.d/renderd
sed -i "s/DAEMON_ARGS=\"\"/DAEMON_ARGS=\"-c \/usr\/local\/etc\/renderd.conf\"/g" /etc/init.d/renderd
sed -i "s/RUNASUSER=www-data/RUNASUSER=osm/g" /etc/init.d/renderd



sudo mkdir -p /var/lib/mod_tile

# sudo chown osm:osm /var/lib/mod_tile
sudo chown $PostgreSQLUserName:$PostgreSQLUserName /var/lib/mod_tile

# start renderd service
sudo systemctl daemon-reload

sudo systemctl start renderd

sudo systemctl enable renderd



# *** Step 8: Configure Apache ***
sudo apt install apache2

# Create a module load file
echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" >> /etc/apache2/mods-available/mod_tile.load

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

# Save and close the file. Restart Apache.
sudo systemctl restart apache2



# Then in your web browser address bar, type

# your-server-ip/osm_tiles/0/0/0.png
# You should see the tile of world map. Congrats! You just successfully built your own OSM tile server.