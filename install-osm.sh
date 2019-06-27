#!/bin/bash
OSMUserName=$1
OSMDBPassword=$2
OSMDatabaseName=$3
OSMRegion=$4

./install-postgresql-10.sh $OSMUserName $OSMDBPassword

if [[ $? > 0 ]]; then
    echo "Something goes wrong in PostgreSQL installation"
    exit
else
    echo "PostgreSQL installation successfully"
fi

./install-postgresql-gis.sh $OSMUserName $OSMDBPassword $OSMDatabaseName $OSMRegion

if [[ $? > 0 ]]; then
    echo "Something goes wrong in PostgreGIS installation"
    exit
else
    echo "PostgreGIS installation successfully"
fi

./install-osm-tile-server.sh $OSMUserName

if [[ $? > 0 ]]; then
    echo "Something goes wrong in webserver configuration"
    exit
else
    echo "webserver configuration successfully"
fi