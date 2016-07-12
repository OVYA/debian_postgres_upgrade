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
    echo '### DESCRIPTION ###'  >&2
    echo 'This script make a binary dump of a Postgres database using pg_dump'
    echo 'The default directory where the backups live will be ~postgres/backups/ (/var/lib/postgresql/backups in debian system)'
    echo 'Root can list the databases with the command : '
    echo "su - postgres -c 'psql --tuples-only -U postgres -c \"\\l\"'"
    echo
    echo '### USAGE ###'  >&2
    echo "$0 [-o output-file-path] database-name-to-backup"  >&2
    exit 1
}


[ $# -lt 1 ] && {
    usage;
}

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

while getopts o:h option
do
    case $option in
        o)
            BACK=~postgres/backups/${OPTARG}
            ;;
        h)
            usage
            ;;
    esac
done

shift $(($OPTIND-1))

databaseName="$1"

[ "$BACK" = "" ] && {
    BACK=~postgres/backups/${databaseName}.$(date '+%Y-%m-%d:%H-%M-%S').bin
}

[  -e $BACK ] && {
    echo "The file ${BACK} exists" >&2
    echo 'Remove or rename it before proceed' >&2
    exit 1
}

su - postgres -c "pg_dump -v -F c -f $BACK $databaseName" && {
    echo "The database ${databaseName} was backuped in ${BACK}"
}




# Local variables:
# coding: utf-8
# End:
