#!/bin/bash

# Copyright (c) 2016, Philippe Ivaldi <www.piprime.fr>

# This program is free software ; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation ; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY ; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with this program ; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

usage() {
    echo "This scrit restore the custome pg dump file DUMP_PATH in the database DB_NAME
Usage: $0 -p PORT_NUM -d DB_NAME -f DUMP_PATH [OPTIONS...]

Available options:
   -p N   The port number of the new PostgreSQL server version.
   -d S   The database name, it must already exists.
   -f S   The custome binary pg_dump file to upgrade.
   -c     Create postgis extension in the database for you.
   -v S   Force the target version of postgresql (9.5 or 10.2 etc)
   -g S   Force the target version of postgis (2.1 or 3.0 etc.)
   -h     This help.
"
    echo -e "$1"

    exit 1;
}

confirm() {
    declare -l yesno
    while [ "$yesno" != "y" -a "$yesno" != "n" ] ; do
	read -p "$(tput setaf 3)$1 (y|n) $(tput sgr0)$(tput bold)" -N 1 yesno
	echo
	[ "$yesno" == "n" ] && return 1
	[ "$yesno" == "y" ] && return 0
	printf "%sPlease answer with n or y.%s\n" "$(tput setaf 1)" "$(tput sgr0)"
    done
}

## Init config ######################

PORT=0
DB_NAME=''
FILE_PATH=''
CREATE_POSTGIS=false
PG_TARGET_VERSION=0
PGIS_TARGET_VERSION=0

while getopts 'p:d:f:hc' OPT; do
    case "$OPT" in
        p) # Port
            PORT="$OPTARG"
            ;;
        d) # db name
            DB_NAME="$OPTARG"
            ;;
        f) # file path
            FILE_PATH="$OPTARG"
            ;;
        c) # Create postgis extension
            CREATE_POSTGIS=true
            ;;
        h) # short help
            usage
            ;;
        \?) # error
            usage
            ;;
    esac
done

## Check config ######################

ERROR=false
MSG='\n'

[ $OPTIND -gt $# ] || ERROR=true  # no non-option args

[ $PORT -eq 0 ] && {
    ERROR=true
    MSG='Missing port number\n'
}

[ "$DB_NAME" = "" ] && {
    ERROR=true
    MSG='Missing database name\n'
}

[ "$FILE_PATH" = "" ] && {
    ERROR=true
    MSG='Missing pg dump file path\n'
}


$ERROR && {
    usage "$MSG"
}

[ -f "$FILE_PATH" ] || {
    echo "'${FILE_PATH}' does not exits or is not readable"
    exit 1
}

### Starting commands ######################
[ "$USER" = "postgres" ] || {
    echo "$0"
    echo 'This script must be executed by the user postgres.'
    echo 'Process aborted...'
    exit 1
}

CONFIRM=false
[ $PG_TARGET_VERSION -eq 0 ] && {
    echo "Detecting target Postgresql version..."
    PG_TARGET_VERSION=$(locate pg_hba.conf | sed -E 's!.*postgresql/([0-9.]+).*!\1!' | sort -n -t. -k 1,2n | tail -1)
    CONFIRM=true
}

[ $PGIS_TARGET_VERSION -eq 0 ] && {
    echo "Detecting target Postgis version..."
    PGIS_TARGET_VERSION=$(locate postgis_restore.pl | sed -E 's/.*postgis-([0-9.]+).*/\1/' | sort -n -t. -k 1,2n | tail -1)
    CONFIRM=true
}

$CONFIRM && {
    echo "The folowing TARGET versions will be used :"
    echo "Postgresql : ${PG_TARGET_VERSION}"
    echo "POstgis    : ${PGIS_TARGET_VERSION}"
    echo
    confirm "Are you agree ?" || {
        echo 'Aborted...'
        exit 1
    }
}

PSQL_CMD="/usr/lib/postgresql/${PG_TARGET_VERSION}/bin/psql -p ${PORT}"
PGIS_CMD="perl /usr/share/postgresql/${PG_TARGET_VERSION}/contrib/postgis-{PGIS_TARGET_VERSION}/postgis_restore.pl"

$CREATE_POSTGIS && {
$PSQL_CMD -d ${DB_NAME} -c "CREATE EXTENSION postgis;"
$PSQL_CMD -d ${DB_NAME} -c "CREATE EXTENSION postgis_topology;"
}

ERROR_FILE="/tmp/${DB_NAME}_err.txt"

$PGIS_CMD $FILE_PATH | $PSQL_CMD ${DB_NAME} 2> $ERROR_FILE && echo "Operation done !"

echo "You can check error messages in the file ${ERROR_FILE}"

# Local variables:
# coding: utf-8
# End:
