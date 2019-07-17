#!/bin/bash

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



programname=$0
OSMRegion=$1

echo "${CYAN}OSMRegion:${NC} ${OSMRegion}"


function usage() {
    echo "usage: $programname [region]"
    echo "  region   specify input file for map data"
    echo "allowed values: "
    echo "africa"
    echo "antarctica"
    echo "asia"
    echo "australia-oceania"
    echo "north-america"
    echo "central-america"
    echo "south-america"
    echo "europe"
    echo "europe/italy | italy"
    echo "europe/italy/north-west"
    echo "europe/italy/north-east"
    echo "europe/italy/center"
    echo "europe/italy/south"
    echo "europe/italy/islands"
    exit 1
}


if [ ${#} -lt 1 ]; then
    usage
    exit 1
fi

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

echo $MapDataUri/$MapDataFileName
