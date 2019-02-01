FROM alpine:latest

LABEL maintainer="Alfian Dhimas Nur Marita <therealaladhims@gmail.com>"

ADD prepare.sh prepare.sh
RUN sh prepare.sh && rm prepare.sh

# MYSQL Envs
ENV MYSQL_DATABASE yourdatabase
ENV MYSQL_HOST localhost
ENV MYSQL_PORT 3306
ENV MYSQL_USER user
ENV MYSQL_PASSWORD password

# MongoDB Envs
ENV MONGODB_DATABASE yourdatabase
ENV MONGODB_HOST localhost
ENV MONGODB_PORT 27017

# AWS S3 Envs
ENV S3_ACCESS_KEY_ID yours3key
ENV S3_SECRET_ACCESS_KEY yours3secretkey
ENV S3_BUCKET yourbucketname
ENV S3_REGION your-region-2
ENV S3_PREFIX backups
ENV S3_FILENAME yourfilename

# Go cron schedule
ENV SCHEDULE **None**

ADD run.sh run.sh
ADD backup.sh backup.sh

CMD ["sh", "run.sh"]