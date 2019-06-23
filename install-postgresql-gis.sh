#!/bin/bash
OSMUserName=$1
OSMRegion=$2



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
sudo -u postgres createuser $OSMUserName

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



echo 'Creating PostgreSQL gis database'
sudo -u postgres createdb -E UTF8 -O $OSMUserName gis

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



echo 'Creating hstore extension on the gis database'
sudo -u postgres psql -c "CREATE EXTENSION hstore;" -d gis

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



echo 'Creating postgis extension on gis database'
command="CREATE EXTENSION postgis;"
echo 'PostgreSQL - Executing command:'$postgis_command
sudo -u postgres psql -c $command -d gis

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

command="ALTER TABLE geometry_columns OWNER TO $OSMUserName;"
echo 'PostgreSQL - Executing command:'$command
sudo -u postgres psql -c $command -d gis

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

command="ALTER TABLE spatial_ref_sys OWNER TO $OSMUserName;"
echo 'PostgreSQL - Executing command:'$command
sudo -u postgres psql -c $command -d gis

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# Changing PostgreSQL authentication mode
echo '@@@ Changing PostgreSQL authentication mode...'
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



# Create osm user on your operating system so the tile server can run as osm user.
echo '* creating operating system user ['$OSMUserName'] *'
#sudo adduser $OSMUserName --disabled-password --shell /bin/bash --gecos ""
sudo useradd -m $OSMUserName

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



OSMUserHome=/home/$OSMUserName/



# *** Step 2: Installing osm2pgsql ***
echo '************************************'
echo '*** Step 3: Installing osm2pgsql ***'
echo '************************************'

cd ~
mkdir ~/src
cd ~/src
git clone git://github.com/openstreetmap/osm2pgsql.git
cd osm2pgsql

echo 'Installing osm2pgsql dependecies...'
apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libproj-dev lua5.2 liblua5.2-dev

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


echo 'Installing osm2pgsql...'
mkdir build && cd build
cmake ..

make

make install


if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Step 3: Download Map Data ***
echo '*********************************'
echo '*** Step 7: Download Map Data ***'
echo '*********************************'
echo '(downloading from '$MapDataUri/$MapDataFileName')'
# sudo su - $OSMUserName

cd ~
mkdir ~/data
cd ~/data
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



# *** Step 8: Import the Map Data to PostgreSQL ***
echo '*************************************************'
echo '*** Step 8: Import the Map Data to PostgreSQL ***'
echo '*************************************************'


echo '* running osm2pgsql *'

# osm2pgsql -U postgres --slim -d gis -C 1800 --hstore -S $OSMUserHome/openstreetmap-carto-4.21.1/openstreetmap-carto.style $OSMUserHome/$MapDataFileName

osm2pgsql -U postgres --slim -d gis -C 1800 --hstore -S ~/src/openstreetmap-carto/openstreetmap-carto.style --create -G --tag-transform-script ~/src/openstreetmap-carto/openstreetmap-carto.lua --number-processes 1  ~/data/$MapDataFileName

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

cd ~/src/openstreetmap-carto/scripts

echo '@@@ running get-shapefiles.py...'
./get-shapefiles.py

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


echo '@@@ installing required fonts...'
sudo apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi





# *** Step 9: Setting up webserver ***
echo '************************************'
echo '*** Step 9: Setting up webserver ***'
echo '************************************'

# *** Step 9.1: Configuring renderd ***
echo '*** Step 9.1: Configuring renderd ***'
echo 'using user: '$(whoami)' current directory: '$(pwd)

echo '* replacing values in renderd.conf *'
RENDERD_CONF_PATH='/usr/local/etc/renderd.conf'
# RENDERD_CONF_PATH='/home/osm/src/mod_tile/debian/renderd.conf'


echo 'Replacing the value of num_threads [default] section'
sudo sed -i "s/^num_threads=\d+/num_threads=2/g" $RENDERD_CONF_PATH


# In the [default] section, change the value of XML and HOST to
# XML=/home/osm/openstreetmap-carto-2.41.0/style.xml
# HOST=localhost
echo 'Replacing the value of XML [default] section'
# sudo sed -i "s/^XML=\/home\/jburgess\/osm\/svn.openstreetmap.org\/applications\/rendering\/mapnik\/osm-local.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/g" $RENDERD_CONF_PATH
# sudo sed -i "s/^XML=[\w+|\/+|-]+.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/gmi" $RENDERD_CONF_PATH

style_path=$(echo ~/src/openstreetmap-carto/mapnik.xml | sed 's_/_\\/_g')
sudo sed -i 's/^XML=[\w+|\/+|\-]+.xml/XML='$style_path'/g' $RENDERD_CONF_PATH


# if [[ $? > 0 ]]
# then
#     echo "The command failed, exiting."
#     exit
# else
#     echo "The command ran succesfuly, continuing with script."
# fi


echo 'Replacing the value of HOST [default] section'
sudo sed -i "s/^HOST=tile.openstreetmap.org/HOST=$HOSTNAME/g" $RENDERD_CONF_PATH

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


# # Replacing the value of plugins_dir [mapnik] section
# echo 'Replacing the value of plugins_dir [mapnik] section'
# sudo sed -i "s/^plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/lib\/mapnik\/3.0\/input/g" $RENDERD_CONF_PATH

# if [[ $? > 0 ]]
# then
#     echo "The command failed, exiting."
#     exit
# else
#     echo "The command ran succesfuly, continuing with script."
# fi



cd $WORKING_DIR

# Install renderd init script by copying the sample init script.
echo '* Install renderd init script by copying the sample init script *'

sudo cp ~/src/mod_tile/debian/renderd.init /etc/init.d/renderd

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








# *** Step 10: Configuring Apache ***
echo '***********************************'
echo '*** Step 10: Configuring Apache ***'
echo '***********************************'

echo '@@@ creating /var/lib/mod_tile folder...'
sudo mkdir -p /var/lib/mod_tile

if [[ $? > 0 ]]
then
    echo "@@@ Unable to create /var/lib/mod_tile folder @@@"
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo '@@@ changing permissions to folder'
sudo chown $OSMUserName /var/lib/mod_tile

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


echo '@@@ creating /var/run/renderd folder...'
sudo mkdir /var/run/renderd

if [[ $? > 0 ]]
then
    echo "@@@ Unable to create /var/run/renderd folder @@@"
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo '@@@ changing permissions to folder'
sudo chown -R $OSMUserName /var/run/renderd






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

echo Create a module load file
echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" | sudo tee /etc/apache2/conf-available/mod_tile.conf


echo '@@@ enabling mod_tile module'
sudo a2enconf mod_tile

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

sudo a2enconf mod_tile

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