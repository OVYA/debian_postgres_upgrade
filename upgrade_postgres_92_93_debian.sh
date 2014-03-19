#!/bin/bash

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