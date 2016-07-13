#!/bin/bash

usage() {
    echo "
Usage: -from

Available options:
   -s N   Description
   -t     Description
"
    exit 1;
}

pause() {
    printf "Press 'ENTER' to continue or 'CTRL+C' to exit "
    sed -n q </dev/tty
    echo
}

function INFO {
    echo -e "[\033[01;32m*\033[00m] ${1}"
}

function INFO_PLUS {
    echo -e "[\033[01;32m*\033[00m] \033[01;32m${1}\033[00m"
}


function INFO_EXEC {
    echo -e "[\033[01;36m=>\033[00m] ${1}"
}

function ECHO2 {
    printf '%s\n' "$@"
    echo
}

CURRENT_DIR=$(dirname "$0")

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

whiptail --yesno 'This programme guide you to hard upgrade your Postgresql installation.
It will NOT execute upgrade commands for you but describes the upgrade process.
You can report any comment via <dev[at]ovya[dot]fr>.' 10 100 \
         --yes-button 'Continue' \
         --no-button 'Cancel' \
         --title "About $0" 'Cancel'

[ $? -eq 0 ] || {
    # clear
    INFO "Programm canceled"
    exit 1
}

psqlCurrentVersion=$(psql --version | sed -E 's/[^0-9.]//g' | awk -F "." '{print $1 "." $2}')
psqlCurrentPkgRegexp=$(echo "$dependencyPkgFormats" | sed -E ":a;N;$!ba;s/\n/.*|/g;s/%s/${psqlCurrentVersion}/g")
psqlCandidateVersion=$(apt-cache policy postgresql | grep -i 'candidate:' | sed -E 's/ *[a-zA-Z]+: *([0-9.]+).*/\1/g')
psqlCandidatePkgRegexp=$(echo "$dependencyPkgFormats" | sed -E ":a;N;$!ba;s/\n/.*|/g;s/%s/${psqlCandidateVersion}/g")

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


INFO_EXEC 'Execute as root this command :'
aptArg=$(echo ${psqlCandidatePkgs} | sed -E 's/\n/ /g')
ECHO2 "sudo apt-get update && sudo apt-get upgrade && sudo apt-get install $aptArg"

pause

INFO "You need to backups your databases..."
INFO_EXEC "In order to show your currently available database you can execute this command as root :"
ECHO2 "su - postgres -c 'psql --tuples-only -U postgres -c \"\\l\"'"
INFO_EXEC "The script backup_postgresql_db.sh helps you to properly backups a database in the directory /var/lib/postgresql/backups/"
ECHO2 "${CURRENT_DIR}/backup_postgresql_db.sh YOUR_DATA_BASE_NAME"

pause

POSGIS_NEEDED=$(echo "${psqlCandidatePkgs}" | grep -qi 'postgis' && echo true || echo false)

$POSGIS_NEEDED && {
    INFO "Need Postgis upgrade detected"
    INFO_PLUS 'The following instructions are about "Hard upgrade" for Postgis support'
    INFO_PLUS 'More details at http://www.postgis.org/docs/postgis_installation.html#hard_upgrade'
    echo

    pause
}

exit 0

# cd /var/lib/postgresql/temp

# for i in costespro_production costespro_staging; do
#     f="/var/lib/postgresql/temp/${i}_$(date -I).bin"
#     # pg_dump -Fc -b -v -f $f $i;
#     # /usr/lib/postgresql/9.4/bin/createdb -p 5433 -O rcv --encoding=UTF8 $i -T template0
#     # /usr/lib/postgresql/9.4/bin/psql -p 5433 -c "GRANT ALL PRIVILEGES ON DATABASE $i TO rcv WITH GRANT OPTION"
#     # /usr/lib/postgresql/9.4/bin/psql -p 5433 -d $i -c "CREATE EXTENSION postgis;"
#     # /usr/lib/postgresql/9.4/bin/psql -p 5433 -d $i -c "CREATE EXTENSION postgis_topology;"
#     perl /usr/share/postgresql/9.4/contrib/postgis-2.1/postgis_restore.pl $f | \
#         /usr/lib/postgresql/9.4/bin/psql -p 5433 $i 2> ${i}_err.txt
# done


# Install postgres 9.3
sudo apt-get install postgresql-9.3 postgresql-server-dev-9.3 postgresql-contrib-9.3

# Having Postgres 9.2 already, this will create database instance configured to run on port 5433

sudo service postgresql stop

# For pg_upgrade to work, you must switch to postgres user
sudo su - postgres
/usr/lib/postgresql/9.3/bin/pg_upgrade -b /usr/lib/postgresql/9.2/bin -B /usr/lib/postgresql/9.3/bin -d /var/lib/postgresql/9.2/main/ -D /var/lib/postgresql/9.3/main/ -O "-c config_file=/etc/postgresql/9.3/main/postgresql.conf" -o "-c config_file=/etc/postgresql/9.2/main/postgresql.conf"
exit

# Start postgres
sudo service postgresql start

# Run analyze script
sudo su - postgres -c "~/analyze_new_cluster.sh"

# Optionally, delete script
sudo su - postgres -c "~/delete_old_cluster.sh"

# Switch ports, :5432 for 9.3 and :5433 for 9.2
sudo vim /etc/postgresql/9.2/main/postgresql.conf
sudo vim /etc/postgresql/9.3/main/postgresql.conf

# Change user login method from `peer` to `md5`
sudo vim /etc/postgresql/9.3/main/pg_hba.conf
