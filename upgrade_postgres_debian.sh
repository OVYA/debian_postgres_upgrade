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

dependencyPkgFormats='postgresql-%s-asn1oid
postgresql-%s-dbg
postgresql-%s-debversion
postgresql-%s-ip4r
postgresql-%s-mimeo
postgresql-%s-mysql-fdw
postgresql-%s-orafce
postgresql-%s-partman
postgresql-%s-pgespresso
postgresql-%s-pgextwlist
postgresql-%s-pgfincore
postgresql-%s-pgmemcache
postgresql-%s-pgmp
postgresql-%s-pgpool2
postgresql-%s-pgq3
postgresql-%s-pgrouting
postgresql-%s-pgrouting-doc
postgresql-%s-pgtap
postgresql-%s-pllua
postgresql-%s-plproxy
postgresql-%s-plr
postgresql-%s-plsh
postgresql-%s-postgis
postgresql-%s-postgis-scripts
postgresql-%s-powa
postgresql-%s-prefix
postgresql-%s-preprepare
postgresql-%s-prioritize
postgresql-%s-python-multicorn
postgresql-%s-python3-multicorn
postgresql-%s-repack
postgresql-%s-repmgr
postgresql-%s-repmgr-dbg
postgresql-%s-slony1
postgresql-client-%s
postgresql-contrib-%s
postgresql-doc-%s
postgresql-plperl-%s
postgresql-plpython3-%s
postgresql-pltcl-%s
postgresql-server-dev-%s'

whiptail --yesno 'This programme guides you to hard upgrade your Postgresql installation.
IT WILL NOT EXECUTE UPGRADE COMMANDS for you but describes the upgrade process.
IF EXECUTED AS user postgres, this script will execute some commands displaying usefull informations.

THIS SCRIPT WILL NEVER MODIFY YOUR INSTALLATION.

You can report any comment via <dev[at]ovya[dot]fr>.' 20 100 \
         --yes-button 'Continue' \
         --no-button 'Cancel' \
         --title "About $0" 'Cancel'

[ $? -eq 0 ] || {
    # clear
    INFO "Programm canceled"
    exit 1
}

CAN_EXEC=$([[ "$USER" = "root" || "$USER" = "postgres" ]] && echo true || echo false)

psqlCurrentVersion=$(psql --version | sed -E 's/[^0-9.]//g' | awk -F "." '{print $1 "." $2}')
psqlCurrentPkgRegexp=$(echo "$dependencyPkgFormats" | sed -E ":a;N;$!ba;s/\n/.*|/g;s/%s/${psqlCurrentVersion}/g")
psqlCandidateVersion=$(LC_ALL='en_US.UTF-8' apt-cache policy postgresql | grep -iE '^ *candidat' | sed -E 's/ *[a-zA-Z]+: *([0-9.]+).*/\1/g')
psqlCandidatePkgRegexp=$(echo "$dependencyPkgFormats" | sed -E ":a;N;$!ba;s/\n/.*|/g;s/%s/${psqlCandidateVersion}/g")

[ "$psqlCurrentVersion" = "$psqlCandidateVersion" ] && {
    INFO "Can not find dpkg candidate version."
    INFO "Trying to find cluster version..."

    _VERSIONS=$(pg_lsclusters -h | awk '{print $1}' | sort -n -t. -k 1,2n | tail -2)
    psqlCurrentVersion=$(echo $_VERSIONS | awk '{print $1}')
    psqlCandidateVersion=$(echo $_VERSIONS | awk '{print $2}')

    [ "$psqlCurrentVersion" = "$psqlCandidateVersion" ] && {
        ABORT "No new version of PostgreSQL found..."
    }
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

# echo $psqlPkgRegexp
psqlCurrentPkgs=$(dpkg-query -f '${binary:Package}\n' -W | grep -E "^postgresql-.*${psqlCurrentVersion}.*" | grep -Ev "^postgresql-${psqlCurrentVersion}\$")
psqlCandidatePkgRegexp=$(echo "$psqlCurrentPkgs" | sed -E ":a;N;\$!ba;s/\n/|/g;s/[0-9]/./g")

# echo "psqlCandidatePkgRegexp = $psqlCandidatePkgRegexp"

psqlCandidatePkgs=$(apt-cache search "postgresql-.*${psqlCandidateVersion}.*" | sed -E 's/ - .*//g' | grep -E "${psqlCandidatePkgRegexp}")
psqlCurrentPkgs="postgresql-${psqlCurrentVersion}
${psqlCurrentPkgs}"
psqlCandidatePkgs="postgresql-${psqlCandidateVersion}
${psqlCandidatePkgs}"


INFO "The folowing package was detected to be upgraded :"
ECHO2 "${psqlCurrentPkgs}"

INFO "The folowing package shoud be installed :"
ECHO2 "$psqlCandidatePkgs"


INFO 'Execute as root this command :'
aptArg=$(echo ${psqlCandidatePkgs} | sed -E 's/\n/ /g')
INFO_EXEC_NL "apt-get update && apt-get upgrade && apt-get install ${aptArg}"

pause

INFO "You need to backups your databases..."

CMD="psql --tuples-only -U postgres -c \"\\l\""
$CAN_EXEC && {
    INFO "The current available databases are :"
    eval $CMD
} || {
    INFO "To show the current available databases, execute this command as postgres :"
    INFO_EXEC_NL "$CMD"
}

INFO "The script backup_postgresql_db.sh helps you to properly backups a database in the directory /var/lib/postgresql/backups/"
INFO_EXEC_NL "${CURRENT_DIR}/backup_postgresql_db.sh YOUR_DATA_BASE_NAME"

pause


CMD="psql --tuples-only -U postgres -c '\du'"
$CAN_EXEC && {
    INFO "The current user account are :"
    eval $CMD
} || {
    INFO "To show current user accounts execute the folowing command as postgres :"
    INFO_EXEC_NL "$CMD"
}

pause

CMD="pg_lsclusters -h | sort -n -t. -k 1,2n | tail -1 | awk '{print $3}'"
PG_TARGET_PORT="PORT_${psqlCandidateVersion}"

$CAN_EXEC && {
    PG_TARGET_PORT=$(pg_lsclusters -h | sort -n -t. -k 1,2n | tail -1 | awk '{print $3}')
    INFO "The port number of the newer cluster is ${PG_TARGET_PORT}"
} || {
    INFO "To show current user accounts execute the folowing command as postgres :"
    INFO_EXEC_NL "$CMD"
}

pause

INFO "Create some users. You must be the user postgres. Here an example creating an user"
INFO_EXEC_NL "psql -p ${PG_TARGET_PORT} -U postgres -c \\
               \"create role THE_OLD_USER_NAME password 'THE_PASSWORD' nosuperuser createdb nocreaterole inherit login\""

pause

INFO "Create the databases in the new Postgresql cluster"
INFO_EXEC_NL "/usr/lib/postgresql/${psqlCandidateVersion}/bin/createdb -p ${PG_TARGET_PORT} -O THE_OWNER --encoding=UTF8 THE_DB_NAME -T template0"

pause

## Test if posgit update is needed
POSGIS_NEEDED=$(echo "${psqlCandidatePkgs}" | grep -qi 'postgis' && echo true || echo false)

$POSGIS_NEEDED && {
    INFO "Need Postgis upgrade detected"
    INFO_PLUS 'The following instructions are about "Hard upgrade" for Postgis support'
    INFO_PLUS 'More details at http://www.postgis.org/docs/postgis_installation.html#hard_upgrade'
    INFO "You can execute the script upgrade_postgis_debian.sh which does it for you :"
    INFO_EXEC_NL "${CURRENT_DIR}/upgrade_postgis_debian.sh -p ${PG_TARGET_PORT} -d YOUR_DB_NAME -f YOUR_PG_DUMP"
} || {
    INFO "Restore your dumps in the new cluster, executing this command as postgresql for each (database, file)"
    INFO_EXEC_NL "/usr/lib/postgresql/${psqlCurrentVersion}/bin/pg_restore -p ${PG_TARGET_PORT} -e -F c -d YOUR_DATABASE_NAME -v 'YOUR_DUMP_FILE'"
}

pause

INFO "Cleaning installation with this process :"
INFO_EXEC_NL "service postgres stop"
INFO "Modify the files according to your need (port, login method from 'peer' to 'md5', etc)
  /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf
  /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf"
INFO "OR execute these commands as root :"
INFO_EXEC "mv /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf.dist"
INFO_EXEC "mv /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf.dist"
INFO_EXEC "cp /etc/postgresql/${psqlCurrentVersion}/main/pg_hba.conf /etc/postgresql/${psqlCandidateVersion}/main/pg_hba.conf"
INFO_EXEC "cp /etc/postgresql/${psqlCurrentVersion}/main/postgresql.conf /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf"

psqlCurrentRegexpVersion=$(echo $psqlCurrentVersion | sed -e 's/[]\/$*.^|[]/\\&/g')

INFO_EXEC_NL "sed -i -e 's/${psqlCurrentRegexpVersion}/${psqlCandidateVersion}/g' /etc/postgresql/${psqlCandidateVersion}/main/postgresql.conf"

pause

INFO "Uninstall the package postgresql-${psqlCurrentVersion} :"
INFO_EXEC_NL "apt-get remove postgresql-${psqlCurrentVersion}"

pause

echo
echo "That's all folks !"

# Local variables:
# coding: utf-8
# End:
