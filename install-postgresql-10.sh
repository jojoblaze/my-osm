#!/bin/bash
OSMUserName=$1
OSMDBPassword=$2


# *** Prepare system ***
echo '**********************'
echo '*** Prepare system ***'
echo '**********************'

echo 'Updating the system'
sudo apt-get update -y --fix-missing
#sudo apt-get upgrade -y

echo '* Setting Frontend as Non-Interactive *'
export DEBIAN_FRONTEND=noninteractive



# *** Install PostgreSQL Database Server with PostGIS ***
echo '*******************************************************'
echo '*** Install PostgreSQL Database Server with PostGIS ***'
echo '*******************************************************'
sudo apt-get install -y postgresql postgresql-contrib postgresql-client-common postgis postgresql-10-postgis-2.4 postgresql-10-postgis-scripts

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



# *** PostgreSQL configuration ***
echo '********************************'
echo '*** PostgreSQL configuration ***'
echo '********************************'

PG_HBA_PATH='/etc/postgresql/10/main/pg_hba.conf'

if [[ ! -f $PG_HBA_PATH ]]; then
    echo '$PG_HBA_PATH file not found'
else
    # Changing PostgreSQL authentication mode
    echo 'Set postgres user authentication mode to "trust" for local connections'
    sudo sed -i "s/local   all             postgres                                peer/local   all             postgres                                trust/g" $PG_HBA_PATH

    if [[ $? > 0 ]]; then
        echo "The command failed, exiting."
        exit
    else
        echo "The command ran succesfuly, continuing with script."
    fi



    echo 'Set osm user authentication mode to "trust" for local connections'
    sudo sed -i "a/local   all             postgres                                trust/local   all             $OSMUserName                                peer/g" $PG_HBA_PATH

    if [[ $? > 0 ]]; then
        echo "The command failed, exiting."
        exit
    else
        echo "The command ran succesfuly, continuing with script."
    fi



    echo 'Allow remote connection from any ip'
    sudo sed -i "s/host    all             all             127.0.0.1\/32            md5/host    all             all             0.0.0.0\/0               md5/g" $PG_HBA_PATH

    if [[ $? > 0 ]]; then
        echo "The command failed, exiting."
        exit
    else
        echo "The command ran succesfuly, continuing with script."
    fi
fi



# restarting postgres
echo '* restarting postgres *'
sudo service postgresql restart

if [[ $? > 0 ]]; then
    echo "Some problem has occurred while restarting postgresql service, exiting."
    exit
else
    echo "postgresql service restarted successfully."
fi



echo 'Congrats! You just successfully built your own PostgreSQL server.'