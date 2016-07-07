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

psqlCurrentVersion=$(psql --version | sed 's/[^0-9.]//g' | awk -F "." '{print $1 "." $2}')
psqlCurrentPkgRegexp=$(echo "$dependencyPkgFormats" | sed -E ":a;N;$!ba;s/\n/.*|/g;s/%s/${psqlCurrentVersion}/g")
psqlCandidateVersion=$(apt-cache policy postgresql | grep -i 'candidate:' | sed -E 's/ *[a-zA-Z]+: *([0-9.]+).*/\1/g')
psqlCandidatePkgRegexp=$(echo "$dependencyPkgFormats" | sed -E "s/:a;N;$!ba;s/\n/.*|/g;s/%s/${psqlCandidateVersion}/g")

echo "* Current installed version of Postgresql : ${psqlCurrentVersion}"
echo "* Candidate version of Postgresql :         ${psqlCandidateVersion}"
echo

echo $psqlPkgRegexp
psqlCurrentPkgs=$(dpkg-query -f '${binary:Package}\n' -W | grep -E "^postgresql-.*${psqlCurrentVersion}.*")
psqlCandidatePkgRegexp=$(echo "$psqlCurrentPkgs" | sed -E ":a;N;\$!ba;s/\n/|/g;s/[0-9]/./g" | sed -E "s/^postgresql-.\..\|//;")

# echo "psqlCandidatePkgRegexp = $psqlCandidatePkgRegexp"

psqlCandidatePkgs=$(apt-cache search "postgresql-.*${psqlCandidateVersion}.*" | sed -E 's/ - .*//g' | grep -E "${psqlCandidatePkgRegexp}")
psqlCandidatePkgs="postgresql-${psqlCandidateVersion}
${psqlCandidatePkgs}"


echo -e "* The folowing package was detected to be upgraded : \n${psqlCurrentPkgs}\n"
echo -e "* The folowing package shoud be installed : \n$psqlCandidatePkgs"

echo
echo '=> Execute as root this command :'
aptArg=$(echo ${psqlCandidatePkgs} | sed -E 's/\n/ /g')
echo "apt-get install $aptArg"

exit 0

# Update and upgrade packages
sudo apt-get update && sudo apt-get upgrade

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
