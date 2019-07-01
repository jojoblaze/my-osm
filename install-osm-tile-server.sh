#!/bin/bash
OSMUserName=$1

OSMUserHome=/home/$OSMUserName

# *** Installing Mapnik ***
echo '*************************'
echo '*** Installing Mapnik ***'
echo '*************************'

echo 'Installing Mapnik dependecies'
sudo apt-get install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev ttf-unifont lua5.1 liblua5.1-dev libgeotiff-epsg curl
# sudo apt-get install -y libmapnik3.0 libmapnik-dev mapnik-utils python-mapnik autoconf apache2-dev

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Installing Mapnik'
sudo apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python-mapnik

echo '@@@ Testing python mapnik...'
python -c "import mapnik"

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi



# *** Install mod_tile ***
echo '************************'
echo '*** Install mod_tile ***'
echo '************************'
# mod_tile is an Apache module that is required to serve tiles. 
# Currently no binary package is available for Ubuntu. 
# We can compile it from Github repository.

# echo 'logging as ['$OSMUserName']'
# sudo su - $OSMUserName

echo 'current user: '$(whoami)
cd ~
echo 'current user home directory: '$(pwd)

if [[ ! -d $OSMUserHome/src ]]; then
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

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

./configure

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

make

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo make renderd

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo make install

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'Running make install-mod_tile...'
sudo make install-mod_tile

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

sudo ldconfig



# *** Stylesheet configuration *** (moved in install-postgresql-gis.sh)


# *** Setting up webserver ***
echo '****************************'
echo '*** Setting up webserver ***'
echo '****************************'

# *** Configuring renderd ***
echo '*** Configuring renderd ***'

echo '* replacing values in renderd.conf *'

RENDERD_CONF_PATH=$OSMUserHome/src/mod_tile/renderd.conf
# RENDERD_CONF_PATH='/usr/local/etc/renderd.conf'
# RENDERD_CONF_PATH='/home/osm/src/mod_tile/debian/renderd.conf'

if [[ ! -f $RENDERD_CONF_PATH ]]; then
    echo "File $RENDERD_CONF_PATH not found"
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
echo '* Install renderd init script by copying the sample init script *'

if [[ ! -f $OSMUserHome/src/mod_tile/renderd.init ]]; then
    echo "file $OSMUserHome/src/mod_tile/renderd.init not found"
else
    sudo cp $OSMUserHome/src/mod_tile/renderd.init /etc/init.d/renderd

    # Grant execute permission
    echo '* Grant execute permission *'
    sudo chmod a+x /etc/init.d/renderd

    echo 'replacing values in init.d/renderd'
    # Change the following variable in /etc/init.d/renderd file
    # sudo sed -i "s/DAEMON=\/usr\/bin\/\$NAME/DAEMON=\/usr\/local\/bin\/\$NAME/g" /etc/init.d/renderd


    sudo sed -i "s/DAEMON_ARGS=.*/DAEMON_ARGS=\"-c \/home\/osm\/src\/mod_tile\/renderd.conf\"/g" /etc/init.d/renderd

    sudo sed -i "s/RUNASUSER=renderaccount/RUNASUSER=$OSMUserName/g" /etc/init.d/renderd
fi



# *** Configuring Apache ***
echo '**************************'
echo '*** Configuring Apache ***'
echo '**************************'

sudo mkdir -p /var/lib/mod_tile


echo 'changing permissions to folder'
sudo chown -R $OSMUserName /var/lib/mod_tile


echo 'creating /var/run/renderd folder...'
sudo mkdir /var/run/renderd


echo 'changing permissions to folder'
sudo chown -R $OSMUserName /var/run/renderd

echo "Create a module load file"
echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" | sudo tee /etc/apache2/conf-available/mod_tile.conf

echo '@@@ enabling mod_tile module'
sudo a2enconf mod_tile

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# Replace default virtual host file
cd $OSMUserHome/src
wget https://raw.githubusercontent.com/jojoblaze/my-osm/master/000-default.conf

mv 000-default.conf /etc/apache2/sites-available/000-default.conf

# start renderd service
echo '* start renderd service *'
sudo systemctl daemon-reload

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'starting renderd...'
sudo systemctl start renderd

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

echo 'enabling renderd...'
sudo systemctl enable renderd

if [[ $? > 0 ]]; then
    echo "The command failed, exiting."
    exit
else
    echo "The command ran succesfuly, continuing with script."
fi

# Save and close the file. Restart Apache.
echo '* Restart Apache. *'
sudo systemctl restart apache2

if [[ $? > 0 ]]; then
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
