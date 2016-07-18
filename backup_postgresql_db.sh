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

BACK_DIR=~postgres/backups
CURRENT_DIR=$(dirname "$0")

. ${CURRENT_DIR}/functions.rc

usage() {
    echo '### DESCRIPTION ###'  >&2
    echo 'This script make a binary dump of a Postgres database using pg_dump'
    echo "The directory where the backups live will be ${BACK_DIR}"
    echo 'You can list the databases with the command executed as postgres : '
    echo "psql --tuples-only -U postgres -c \"\\l\""
    echo
    echo '### USAGE ###'  >&2
    echo "$0 [-o output-file-name] database-name-to-backup"  >&2
    exit 1
}

[ $# -lt 1 ] && {
    usage;
}

while getopts o:h option
do
    case $option in
        o)
            BACK="${BACK_DIR}/${OPTARG}"
            ;;
        h)
            usage
            ;;
    esac
done

if [ "$USER" != "postgres" ]; then
    ERROR 'This script must be run as postgres user.'
    exit 1
fi

shift $(($OPTIND-1))

[ -e $BACK_DIR ] || {
    INFO "Creating directory '${BACK_DIR}'"
    mkdir -p "$BACK_DIR"
    chown postgres "$BACK_DIR"
}

databaseName="$1"

[ "$BACK" = "" ] && {
    BACK="${BACK_DIR}/${databaseName}.$(date '+%Y-%m-%d_%H-%M-%S').bin"
}

[  -e $BACK ] && {
    ERROR "The file ${BACK} exists"
    ERROR 'Remove or rename it before proceed'
    exit 1
}

pg_dump -v -F c -U postgres -f "$BACK" "$databaseName" && {
    INFO "The database ${databaseName} was backuped in ${BACK}"
}

# Local variables:
# coding: utf-8
# End:
