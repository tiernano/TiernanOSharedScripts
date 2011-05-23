#!/bin/bash
# directory structure:
# ~/s3sync has scripts
# ~/s3sync/s3backup is a folder for temp backup files
cd /home/tiernano
BUCKET=<BucketName>

BlogDBNAME=wordpress


DBPWD=<EnterPasswordHere>
DBUSER=<EnterDBUserNameHere>
NOW=$(date +_%b_%d_%y)
tar czvf httpdocs_blog_backup$NOW.tar.gz <Wordpress Files Location>

mv httpdocs_blog_backup$NOW.tar.gz s3sync/s3backup

cd s3sync/s3backup
touch $BlogDBNAME.backup$NOW.sql.gz

mysqldump -u $DBUSER -p$DBPWD $BlogDBNAME | gzip -9 > $BlogDBNAME.backup$NOW.sql.gz

tar czvf Blog_backup$NOW.tar.gz $BlogDBNAME.backup$NOW.sql.gz httpdocs_blog_backup$NOW.tar.gz

rm -f $BlogDBNAME.backup$NOW.sql.gz httpdocs_blog_backup$NOW.tar.gz

ruby <s3SyncDir>/s3sync.rb -r --ssl --progress -v s3backup/ $BUCKET:

