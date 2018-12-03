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

echo "Pulling $TARGET_ENVIRONMENT images"
docker-compose up --no-start

docker-compose start db

echo -n "Starting ..."
sleep 5
echo ${green} "done"
docker-compose logs --tail 13 app
echo ""
echo "***********************************"
echo "* START COMPLETE                  *"
echo "***********************************"
docker-compose ps
