#!/bin/bash
OSMUserName=$1
OSMRegion=$2



# *** Step 4: Installing Mapnik ***
echo '************************************'
echo '*** Step 1: Installing Mapnik ***'
echo '************************************'

echo 'Installing Mapnik dependecies'
sudo apt-get install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg curl

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



echo 'Installing Mapnik'
sudo apt-get install autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik


echo '@@@ Testing python mapnik...'
python -c "import mapnik"

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

cd ~/src
echo '* cloning mod_tile from GitHub *'
git clone -b switch2osm git://github.com/SomeoneElseOSM/mod_tile.git
# git clone -b switch2osm git://github.com/SomeoneElseOSM/mod_tile.git
cd mod_tile

echo 'Running autogen'
./autogen.sh

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


./configure

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



make

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi


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





# *** Step 6: Stylesheet configuration ***
echo '********************************'
echo '*** Stylesheet configuration ***'
echo '********************************'

sudo apt-get install -y npm nodejs

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# # * check mapnik version *
# MAPNIK_EXPECTED_VERSION="3.0.19"
# if [ $(mapnik-config -v) != $MAPNIK_EXPECTED_VERSION ]
# then
#     echo 'ASSERT FAILED: expected mapnik version '$MAPNIK_EXPECTED_VERSION >>/dev/stderr
# fi

sudo npm install -g carto

if [[ $? > 0 ]]
then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

cd ~/src
# wget https://github.com/gravitystorm/openstreetmap-carto/archive/v4.21.1.tar.gz
# tar xvf v4.21.1.tar.gz
# rm v4.21.1.tar.gz
git clone git://github.com/gravitystorm/openstreetmap-carto.git
cd openstreetmap-carto

echo '@@@ carto -v: $(carto -v)'

carto project.mml | tee mapnik.xml



# *** Shapefile download ***
echo '**************************'
echo '*** Shapefile download ***'
echo '**************************'

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






# *** Configuring Apache ***
echo '**************************'
echo '*** Configuring Apache ***'
echo '**************************'


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


echo "Create a module load file"
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



# Replace default virtual host file
cd ~/src
wget https://raw.githubusercontent.com/jojoblaze/my-osm/master/000-default.conf

mv 000-default.conf /etc/apache2/sites-available/000-default.conf




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