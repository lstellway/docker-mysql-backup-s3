# Backup MySQL Database(s) to S3 Bucket

```sh
docker pull lstellway/mysql-backup-s3
```

## Environment Variables

-   `BACKUP_DATABASES`
    -   Comma-separated list of database names to backup.<br />
        _(User must have access to specified database)_
-   `DB_USER`
    -   Database user
-   `DB_PASS`
    -   Database password
-   `DB_PASS_FILE`
    -   Secret file containing database password
-   `DB_HOST` _(Default: `localhost`)_
    -   Database host
-   `DB_PORT` _(Default: `3306`)_
    -   Database port
-   `S3_PROTOCOL` _(Default: `https`)_
    -   Protocol used to connect to S3 server
-   `S3_REGION` _(Default: `us-east-1`)_
    -   S3 server region
-   `S3_BUCKET`
    -   S3 bucket
-   `S3_ENDPOINT`
    -   S3 endpoint
-   `S3_ACCESS_KEY`
    -   S3 access key
-   `S3_ACCESS_KEY_FILE`
    -   Path to file containing S3 access key
-   `S3_ACCESS_SECRET`
    -   S3 access secret
-   `S3_ACCESS_SECRET_FILE`
    -   Path to file containing S3 access secret

## Recommendations

**MySQL User**

It is recommended to create a MySQL user that only has read permissions on your databases to backup.

```mysql
CREATE USER '{{DB_USER}}'@'%' IDENTIFIED BY '{{DB_PASS}}';
GRANT LOCK TABLES, SELECT ON {{DB_NAME}}.* TO '{{DB_USER}}'@'%';
```

## Resources

-   [GitHub Repository](https://github.com/lstellway/docker-mysql-backup-s3)
-   [Docker Hub Image](https://hub.docker.com/repository/docker/lstellway/mysql-backup-s3)
-   [Issues](https://github.com/lstellway/docker-mysql-backup-s3/issues)
