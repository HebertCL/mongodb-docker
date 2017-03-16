#!/bin/bash

# Build image for container
images=$(sudo docker images | grep mongo_test | awk '{print $1}')
if [ -z  $images ]
then
	echo "Building image..."
	sudo docker build -t mongo_test .
	sleep 1 
else
	echo "Using existing image..."
	sleep 1
fi

#Build network for mongo cluster
net=$(sudo docker network ls | grep mongo_test_cluster | awk '{print $2}')
if [ -z $net ]
then
	echo "Creating network interface..."
	sudo docker network create mongo_test_cluster 
	sleep 1
else
	echo "Using existing network interface..."
	sleep 1
fi

#Setting up replicaset
echo "Deleting old containers..."
sleep 1
old_containers=$(sudo docker ps -a | grep epic | wc -l)
if [ $old_containers -gt 0 ]
then
	sudo docker ps -a | grep epic | awk '{print $1}' >> old_containers; cat old_containers | while read value; do sudo docker rm $value; done; rm old_containers
	sleep 1
fi

echo "Creating replica set..."
sudo docker run -p 27000:27017 --name epic_primary --net mongo_test_cluster mongo_test mongod --setParameter authenticationMechanisms=MONGODB-CR --replSet epic & 
sleep 5
sudo docker run -p 27001:27017 --name epic_sec_1 --net mongo_test_cluster mongo_test mongod --setParameter authenticationMechanisms=MONGODB-CR --replSet epic &
sleep 5
sudo docker run -p 27002:27017 --name epic_sec_2 --net mongo_test_cluster mongo_test mongod --setParameter authenticationMechanisms=MONGODB-CR --replSet epic &
sleep 5
sudo docker run -p 27003:27017 --name epic_sec_3 --net mongo_test_cluster mongo_test mongod --setParameter authenticationMechanisms=MONGODB-CR --replSet epic &
sleep 5
sudo docker run -p 30000:27017 --name epic_arb --net mongo_test_cluster mongo_test mongod --setParameter authenticationMechanisms=MONGODB-CR --replSet epic &
sleep 5
echo "Replicaset created."
sleep 1
#Configure replicaset
echo "Configuring replicaset..."
mongo --port 27000 configure_replicaset.js
sleep 25
#Configure priority
echo "Configuring replicaset priority..."
mongo --port 27000 configure_priority.js
sleep 20
#Configure arbiter
mongo --port 27001 configure_arbiter.js
sleep 20
echo "Replicaset configured."
echo "Done!"

