#!/bin/sh

OSMUserName=$1

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

OSMUserHome=/home/$OSMUserName


echo "${CYAN}OSMUserName:${NC} ${OSMUserName}"
echo "${CYAN}OSMUserHome:${NC} ${OSMUserHome}"



echo "${GREEN}**********************${NC}"
echo "${GREEN}*** Install Mapnik ***${NC}"
echo "${GREEN}**********************${NC}"


echo 'Installing Mapnik dependecies'
sudo apt-get install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg
# sudo apt-get install -y libmapnik3.0 libmapnik-dev mapnik-utils python-mapnik autoconf apache2-dev

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik

# # * check mapnik version *
# MAPNIK_EXPECTED_VERSION="3.0.19"
# if [ $(mapnik-config -v) != $MAPNIK_EXPECTED_VERSION ]
# then
#     echo 'ASSERT FAILED: expected mapnik version '$MAPNIK_EXPECTED_VERSION >>/dev/stderr
# fi

echo 'Testing python mapnik...'
python -c "import mapnik"

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi



echo "${GREEN}**************************${NC}"
echo "${GREEN}*** Shapefile download ***${NC}"
echo "${GREEN}**************************${NC}"

cd ${OSMUserHome}/src/openstreetmap-carto


cd ${OSMUserHome}/src/openstreetmap-carto


echo 'running get-shapefiles.py'
./scripts/get-shapefiles.py

if [ $? -ne 0 ]; then
    echo "${RED}Unable to download shape files.${NC}"
    exit 1
else
    echo "${GREEN}Shape files downloaded successfully.${NC}"
fi

echo 'installing required fonts'
apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted fonts-hanazono ttf-unifont

if [ $? -ne 0 ]; then
    echo "${RED}Unable to install fonts.${NC}"
    exit 1
else
    echo "Fonts installed successfully."
fi




echo "${GREEN}************************${NC}"
echo "${GREEN}*** Install mod_tile ***${NC}"
echo "${GREEN}************************${NC}"

# mod_tile is an Apache module that is required to serve tiles.
# Currently no binary package is available for Ubuntu.
# We can compile it from Github repository.

# echo 'logging as ['$OSMUserName']'
# sudo su - $OSMUserName

echo 'current user: '$(whoami)
cd ~
echo 'current user home directory: '$(pwd)

if [ ! -d $OSMUserHome/src ]; then
    mkdir $OSMUserHome/src

    # set OSM user owner
    chown -R $OSMUserName:$OSMUserName $OSMUserHome/src
fi

cd $OSMUserHome/src

echo 'cloning mod_tile from GitHub *'
git clone -b switch2osm git://github.com/SomeoneElseOSM/mod_tile.git
# git clone -b switch2osm git://github.com/SomeoneElseOSM/mod_tile.git

chown -R $OSMUserName:$OSMUserName mod_tile
cd mod_tile

echo 'Running autogen'
./autogen.sh

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

./configure

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

make

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo make renderd

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo make install

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Running make install-mod_tile...'
sudo make install-mod_tile

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo ldconfig




echo "${GREEN}****************************${NC}"
echo "${GREEN}*** Setting up webserver ***${NC}"
echo "${GREEN}****************************${NC}"

# *** Configuring renderd ***
echo '*** Configuring renderd ***'

RENDERD_CONF_PATH=$OSMUserHome/src/mod_tile/renderd.conf
# RENDERD_CONF_PATH='/usr/local/etc/renderd.conf'
# RENDERD_CONF_PATH='/home/osm/src/mod_tile/debian/renderd.conf'

if [ ! -f $RENDERD_CONF_PATH ]; then
    echo "File $RENDERD_CONF_PATH not found"
    exit 1
else

    echo 'Replacing the value of num_threads [default] section'
    sudo sed -i "s/^num_threads=[0-9]+/num_threads=2/g" $RENDERD_CONF_PATH

    # In the [default] section, change the value of XML and HOST to
    # XML=/home/osm/openstreetmap-carto-2.41.0/style.xml
    # HOST=localhost
    echo 'Replacing the value of XML [default] section'
    # sudo sed -i "s/^XML=\/home\/jburgess\/osm\/svn.openstreetmap.org\/applications\/rendering\/mapnik\/osm-local.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/g" $RENDERD_CONF_PATH
    # sudo sed -i "s/^XML=[\w+|\/+|-]+.xml/XML=\/home\/osm\/openstreetmap-carto-4.21.1\/style.xml/gmi" $RENDERD_CONF_PATH

    # style_path=$(echo ~/src/openstreetmap-carto/mapnik.xml | sed 's_/_\\/_g')
    # sudo sed -i 's/^XML=[\w+|\/+|\-]+.xml/XML='$style_path'/g' $RENDERD_CONF_PATH

    sudo sed -i "s/renderaccount/$OSMUserName/g" $RENDERD_CONF_PATH

    # echo 'Replacing the value of HOST [default] section'
    # sudo sed -i "s/^HOST=tile.openstreetmap.org/HOST=$HOSTNAME/g" $RENDERD_CONF_PATH

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

fi

# Install renderd init script by copying the sample init script.
echo 'Install renderd init script by copying the sample init script'

if [ ! -f $OSMUserHome/src/mod_tile/debian/renderd.init ]; then
    echo "File [$OSMUserHome/src/mod_tile/renderd.init] not found."
    exit 1
else
    sudo cp $OSMUserHome/src/mod_tile/debian/renderd.init /etc/init.d/renderd

    # Grant execute permission
    echo '* Grant execute permission *'
    sudo chmod a+x /etc/init.d/renderd

    echo 'replacing values in init.d/renderd'
    # Change the following variable in /etc/init.d/renderd file
    # sudo sed -i "s/DAEMON=\/usr\/bin\/\$NAME/DAEMON=\/usr\/local\/bin\/\$NAME/g" /etc/init.d/renderd

    sudo sed -i "s/DAEMON_ARGS=.*/DAEMON_ARGS=\"-c \/home\/osm\/src\/mod_tile\/renderd.conf\"/g" /etc/init.d/renderd

    sudo sed -i "s/RUNASUSER=renderaccount/RUNASUSER=$OSMUserName/g" /etc/init.d/renderd
fi



echo "${GREEN}**************************${NC}"
echo "${GREEN}*** Configuring Apache ***${NC}"
echo "${GREEN}**************************${NC}"

sudo mkdir -p /var/lib/mod_tile

echo 'changing permissions to folder'
sudo chown -R $OSMUserName /var/lib/mod_tile

echo 'creating /var/run/renderd folder...'
sudo mkdir /var/run/renderd

echo 'changing permissions to folder'
sudo chown -R $OSMUserName /var/run/renderd



MOD_TILE_LIB_PATH=/usr/lib/apache2/modules/mod_tile.so
if [ ! -f $MOD_TILE_LIB_PATH ]; then
    echo "File [$MOD_TILE_LIB_PATH] not found."
    exit 1
else
    echo "Create a module load file"
    echo "LoadModule tile_module $MOD_TILE_LIB_PATH" | sudo tee /etc/apache2/conf-available/mod_tile.conf

    echo 'enabling mod_tile module'
    sudo a2enconf mod_tile

    if [ "$?" -ne 0 ]; then
        echo "The command failed, exiting."
        exit 1
    else
        echo "The command ran succesfuly, continuing with script."
    fi

fi



# start renderd service
echo 'start renderd service'
sudo systemctl daemon-reload

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'starting renderd'
sudo systemctl start renderd

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'enabling renderd'
sudo systemctl enable renderd

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

# Save and close the file. Restart Apache.
echo 'Restart Apache.'
sudo systemctl restart apache2

if [ "$?" -ne 0 ]; then
    echo "The command failed, exiting."
    exit 1
else
    echo "The command ran succesfuly, continuing with script."
fi

# Copy map file
echo 'Copying map file under /var/www/html'
cd /var/www/html/
wget https://raw.githubusercontent.com/jojoblaze/my-osm/development/map.html

echo 'Go in your web browser address bar, type: your-server-ip/hot/0/0/0.png'

echo "${GREEN}Congrats! You just successfully built your own OSM tile server.${NC}"