FROM postgres:18-trixie

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssl \
        postgresql-18-wal2json \
    && rm -rf /var/lib/apt/lists/*

ENV PGDATA=/data/postgres

COPY docker/postgres/render-postgres-entrypoint.sh /usr/local/bin/render-postgres-entrypoint.sh
COPY docker/postgres/docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
COPY docker/postgres/bootstrap-replication-roles.sh /usr/local/bin/bootstrap-replication-roles.sh
COPY docker/postgres/verify-docker-postgres.sh /usr/local/bin/verify-docker-postgres.sh
COPY sql/docker-readiness.sql /usr/local/share/alliance/docker-readiness.sql

RUN chmod +x /usr/local/bin/render-postgres-entrypoint.sh \
    && chmod +x /usr/local/bin/bootstrap-replication-roles.sh \
    && chmod +x /usr/local/bin/verify-docker-postgres.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

ENTRYPOINT ["render-postgres-entrypoint.sh"]
CMD ["postgres", "-c", "listen_addresses=*", "-c", "port=10000", "-c", "wal_level=logical", "-c", "max_wal_senders=10", "-c", "max_replication_slots=10", "-c", "ssl=on", "-c", "ssl_cert_file=/data/server.crt", "-c", "ssl_key_file=/data/server.key"]
