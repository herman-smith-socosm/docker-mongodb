#!/bin/bash

#green=`tput setaf 2`
echo "***********************************"
echo "*  START.                         *"
echo "***********************************"
echo ""
CURRENT_DIR=`dirname $0`
ROOT_DIR=$CURRENT_DIR/..

# prepare parameters from the AWS Parameter Store
password=`aws ssm get-parameter --name "DB_PASSWORD" --with-decryption --query Parameter.Value`
export DB_PASSWORD="${password//\"}"
export MQ_PASSWORD="${password//\"}"
export ROOTPASS="${password//\"}"
userdb=`aws ssm get-parameter --name "DB_USER" --with-decryption --query Parameter.Value`
export DB_USER="${userdb//\"}"
usermq=`aws ssm get-parameter --name "MQ_USER" --with-decryption --query Parameter.Value`
export MQ_USER="${usermq//\"}"
cipher=`aws ssm get-parameter --name "ASYMCYPHER" --with-decryption --query Parameter.Value`
export ASYMCYPHER="${cipher//\"}"
cipherkey=`aws ssm get-parameter --name "ASYMKEY" --with-decryption --query Parameter.Value`
export ASYMKEY="${cipherkey//\"}"
admin=`aws ssm get-parameter --name "ROOT" --with-decryption --query Parameter.Value`
export ROOT="${admin//\"}"

echo "DB_PASSWORD: ${DB_PASSWORD}"
echo $ROOT_DIR
dbadmin="$ROOT_DIR/dbadmin"
echo "Check if ${dbadmin} dir present"
echo "Does ${dbadmin} exist? "
if [ -d "${dbadmin}" ]
then
  echo "YES"

  sed -i "s|%%USER%%|$DB_USER|" "$dbadmin/create-admin-user.js"
  sed -i "s|%%PASSWORD%%|$DB_PASSWORD|" "$dbadmin/create-admin-user.js"
  sudo mv $dbadmin/create-admin-user.js $ROOT_DIR/db/

  sed -i "s|%%USER%%|$DB_USER|" "$dbadmin/create-elysian-user.js"
  sed -i "s|%%PASSWORD%%|$DB_PASSWORD|" "$dbadmin/create-elysian-user.js"
  sudo mv $dbadmin/create-elysian-user.js $ROOT_DIR/db/

  rm -rf ${dbadmin}
else
  echo "NO"
fi

echo "Pulling $TARGET_ENVIRONMENT images"
docker-compose up --no-start

docker-compose start db

# attempting to wait for mongodb to be ready
$ROOT_DIR/bin/wait-for-service.sh db 'waiting for connections on port' 10

docker exec db mongo admin /data/db/create-admin-user.js
docker exec db rm /data/db/create-admin-user.js

docker exec db mongo elysian /data/db/create-elysian-user.js
docker exec db rm /data/db/create-elysian-user.js

echo -n "Starting ..."
sleep 5
echo ${green} "done"
echo ""
echo "***********************************"
echo "* START COMPLETE                  *"
echo "***********************************"
docker-compose ps
