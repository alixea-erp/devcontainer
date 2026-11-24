#!/usr/bin/env bash

set -eax

# The client of the Postgres add-on's version, from PostgreSQL's own repository: Ubuntu's is older, and pg_dump refuses
# a server newer than itself
install -d /usr/share/postgresql-common/pgdg
curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(. /etc/os-release && echo "$VERSION_CODENAME")-pgdg main" > /etc/apt/sources.list.d/pgdg.list

apt-get update -y
apt-get -y install --no-install-recommends postgresql-client-18
