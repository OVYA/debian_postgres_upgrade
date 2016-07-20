#!/bin/bash

# Copyright (c) 2016, OVYA <ovya.fr>

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

CURRENT_DIR=$(dirname "$0")
. ${CURRENT_DIR}/functions.rc

NB_CLUSTER=$(pg_lsclusters -h | wc -l)

[ $NB_CLUSTER = 2 ] || {
    ABORT "Exactly two clustres are required ; found ${NB_CLUSTER}..."
}

[ "$USER" = "postgres" ] || {
    ABORT 'You must execute this script as postgres user'
}

_VERSIONS=$(pg_lsclusters -h | awk '{print $1}' | sort -n -t. -k 1,2n | tail -2)
psqlCurrentVersion=$(echo $_VERSIONS | awk '{print $1}')
psqlCandidateVersion=$(echo $_VERSIONS | awk '{print $2}')

[ "$psqlCurrentVersion" = "$psqlCandidateVersion" ] && {
    ABORT "No new version of PostgreSQL found..."
}

echo $psqlCurrentVersion | grep -Eq '[0-9.]+' || {
    ABORT "Wrong current version of PostgreSQL found..."
}

echo $psqlCandidateVersion | grep -Eq '[0-9.]+' || {
    ABORT "Wrong candidate version of PostgreSQL found..."
}

INFO "Current installed version of Postgresql : ${psqlCurrentVersion}"
INFO "Candidate version of Postgresql :         ${psqlCandidateVersion}"
echo
INFO "This script will try to do a soft upgrade of your current cluster ; from pg ${psqlCurrentVersion} to pg ${psqlCandidateVersion}"
INFO ""

CMD="/usr/lib/postgresql/${psqlCandidateVersion}/bin/pg_upgrade \\
    -b /usr/lib/postgresql/${psqlCurrentVersion}/bin \\
    -B /usr/lib/postgresql/${psqlCandidateVersion}/bin \\
    -d /var/lib/postgresql/${psqlCurrentVersion}/main/ \\
    -D /var/lib/postgresql/${psqlCandidateVersion}/main/ \\
    -O \"-c config_file=/etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf\" \\
    -o \"-c config_file=/etc/postgresql/${psqlCurrentVersion}/main/postgresql.conf\""


INFO "This script will stop the pg clusters $psqlCurrentVersion and $psqlCandidateVersion and execute this command :"
INFO_EXEC "$CMD"
echo

confirm "Do you still wish to continue ?" || {
    ABORT
}

INFO "Stoping cluster $psqlCurrentVersion main"
pg_ctlcluster $psqlCurrentVersion main stop > /dev/null || {
    ABORT
}

INFO "Stoping cluster $psqlCandidateVersion main"
pg_ctlcluster $psqlCandidateVersion main stop > /dev/null || {
    ABORT
}

eval "$CMD" || {
    echo
    ABORT "Error detected.."
}

INFO "Clean your installation with this process :"
INFO_EXEC_NL "service postgres stop"
INFO "Modify the files according to your need (port, login method from 'peer' to 'md5', etc)
  /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf
  /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf"
INFO "OR execute these commands as root :"
INFO_EXEC "mv /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf.dist"
INFO_EXEC "mv /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf.dist"
INFO_EXEC "cp /etc/postgresql/${psqlCurrentVersion}/main/pg_hba.conf /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf"
INFO_EXEC "cp /etc/postgresql/${psqlCurrentVersion}/main/postgresql.conf /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf"
INFO_EXEC "chown postgres /etc/postgresql/${psqlCurrentVersion}/main/{postgresql,pg_hba}.conf"

psqlCurrentRegexpVersion=$(echo $psqlCurrentVersion | sed -e 's/[]\/$*.^|[]/\\&/g')

INFO_EXEC_NL "sed -i -e 's/${psqlCurrentRegexpVersion}/${psqlCandidateVersion}/g' /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf"

pause

INFO "Uninstall the package postgresql-${psqlCurrentVersion} :"
INFO_EXEC "apt-get remove postgresql-${psqlCurrentVersion}"
INFO "Restart postgresql-${psqlCandidateVersion} :"
INFO_EXEC_NL "service postgresql@${psqlCandidateVersion}-main start"

pause

echo
echo "That's all folks !"

# Local variables:
# coding: utf-8
# End:
