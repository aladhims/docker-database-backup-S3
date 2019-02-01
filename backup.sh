#! /bin/sh

set -e

# Check important envs

if [ "${S3_ACCESS_KEY_ID}" == "**None**" ]; then
  echo "S3_ACCESS_KEY_ID needs to be set"
  exit 1
fi

if [ "${S3_SECRET_ACCESS_KEY}" == "**None**" ]; then
  echo "S3_SECRET_ACCESS_KEY needs to be set"
  exit 1
fi

if [ "${S3_BUCKET}" == "**None**" ]; then
  echo "S3_BUCKET needs to be set"
  exit 1
fi

if [ "${MYSQL_HOST}" == "**None**" ]; then
  echo "MYSQL_HOST needs to be set"
  exit 1
fi

if [ "${MYSQL_USER}" == "**None**" ]; then
  echo "MYSQL_USER needs to be set"
  exit 1
fi

if [ "${MYSQL_PASSWORD}" == "**None**" ]; then
  echo "MYSQL_PASSWORD needs to be set"
  exit 1
fi

if [ "${MONGODB_HOST}" == "**None**" ]; then
  echo "MONGODB_HOST needs to be set"
  exit 1
fi

if [ "${MONGODB_DATABASE}" == "**None**" ]; then
  echo "MONGODB_DATABASE needs to be set"
  exit 1
fi

export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

copy_s3() {
  SRC_FILE=$1
  DEST_FILE=$2
  DATABASE_DIR=$3

  echo "Uploading ${DEST_FILE} on S3"

  cat $SRC_FILE | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/$DATABASE_DIR/$DEST_FILE

  if [ $? != 0 ]; then
    echo >&2 "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}

DUMP_START_TIME=$(date +"%Y-%m-%dT%H%M%SZ")

# MySQL backup starts here

echo "Creating a dump for MySQL database: ${MYSQL_DATABASE} on ${MYSQL_HOST}"

MYSQL_DUMP_FILE="/tmp/dump.sql.gz"

MYSQL_HOST_OPTIONS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

MYSQLDUMP_OPTIONS="--protocol=tcp --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384"

mysqldump $MYSQL_HOST_OPTIONS $MYSQLDUMP_OPTIONS $MYSQL_DATABASE | gzip >$MYSQL_DUMP_FILE

S3_MYSQL_DIR="MySQL"

if [ $? == 0 ]; then
  if [ "${S3_FILENAME}" == "**None**" ]; then
    S3_MYSQL_DUMP_FILE="${DUMP_START_TIME}.${MYSQL_DATABASE}.dump.sql.gz"
  else
    S3_MYSQL_DUMP_FILE="${S3_FILENAME}.${DUMP_START_TIME}.${MYSQL_DATABASE}.dump.sql.gz"
  fi

  copy_s3 $MYSQL_DUMP_FILE $S3_MYSQL_DUMP_FILE $S3_MYSQL_DIR
else
  echo >&2 "Error creating mysql dump"
fi

echo "SQL backup finished"

# MongoDB backup starts here

echo "Creating a dump for MongoDB database: ${MONGODB_DATABASE} on ${MONGODB_HOST}"

MONGODB_DUMP_FILE="/tmp/dump.mongodb.gz"

MONGODUMP_HOST_OPTIONS="--host ${MONGODB_HOST} --port ${MONGODB_PORT}"
MONGODUMP_OPTIONS="--db ${MONGODB_DATABASE} --gzip --archive=${MONGODB_DUMP_FILE}"

mongodump $MONGODUMP_HOST_OPTIONS $MONGODUMP_OPTIONS

S3_MONGODB_DIR="MongoDB"

if [ $? == 0 ]; then
  if [ "${S3_FILENAME}" == "**None**" ]; then
    S3_MONGODB_DUMP_FILE="${DUMP_START_TIME}.${MONGODB_DATABASE}.dump.mongodb.gz"
  else
    S3_MONGODB_DUMP_FILE="${S3_FILENAME}.${DUMP_START_TIME}.${MONGODB_DATABASE}.dump.mongodb.gz"
  fi

  copy_s3 $MONGODB_DUMP_FILE $S3_MONGODB_DUMP_FILE $S3_MONGODB_DIR
else
  echo >&2 "Error creating mongodb dump"
fi

echo "MongoDB backup finished"