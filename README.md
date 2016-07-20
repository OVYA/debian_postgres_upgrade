# Debian Postgres Upgrade

Bash scripts helping to hard upgrade PostgreSQL packages on a Debian like system.

# Features and Usages

There are three scripts useful for hard upgrade :    

* `upgrade_postgres_debian.sh`

  This is the first script to execute when you want to upgrade the
  PostgreSQL version.
  
  This script can be executed by any user but best indications are
  obtained when executed by the user *postgres*.
  
  Note that this script DOES NOT modify you installation, it ONLY
  INDICATE A PROCESS to follow and you must read *CAREFULLY* the
  indicated process.

* `backup_postgresql_db.sh`
  
  A simple wraper to `pg_dump` with the best options (to my mind) to
  make a backup of a database.
  
  This script must be executed as *postgres*.
  
  `backup_postgresql_db.sh -h` for more details.

* `upgrade_postgis_debian.sh`
  
  This script restore safely a custom pg dump file when Postgist extension need a hard upgraded.
  
  Based on the process described [here](http://www.postgis.org/docs/postgis_installation.html#hard_upgrade)
  
  `upgrade_postgis_debian.sh -h` for more details.

# Installation

Clone this repository on your computer, in the directory `/opt` for example :

```bash
cd /opt
git clone https://github.com/OVYA/debian_postgres_upgrade.git
cd debian_postgres_upgrade && chmod +x *.sh
```

Add the directory `/opt/debian_postgres_upgrade` to your environment
variable `PATH`, inserting at the end of your file `~/.bashrc`, the
code :

```bash
export PATH=$PATH:/opt/upgrade_postgres_debian/

```
