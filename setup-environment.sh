#/bin/bash


# Check If docker is running
if [ $? -eq 0 ]; then
    echo "$({docker --version}) is running ✅"
else
    echo "Docker is not running ❌"
    echo
    # Restart Docker
    echo "Attempting to restart Docker"
    open -a Docker
    while ! docker info > /dev/null 2>&1; do sleep 1; done
    echo "$({docker --version}) is running ✅"
fi
# load environment variables 
source .env

#Docker compose
docker compose -f ./docker-compose.yaml up -d

# Check if containers are up and running
echo Checking container status ...
for container_name in $(docker ps --format {{.Names}}); do
    if [[ $(docker inspect -f '{{.State.Running}}' $container_name) = "false" ]]; then
        echo $container_name container is not running ❌.
    else
        echo $container_name container is running ✅
    fi
done

echo Waiting for Kafka to be ready ... 🙇
# docker exec kafka ../../usr/bin/cub kafka-ready -b kafka:9092 1 60

# create topic, producer and consumer
docker exec kafka ../../usr/bin/kafka-topics --create --topic ${TOPIC_NAME} --partitions 2 --replication-factor 1 --if-not-exists --bootstrap-server kafka:9092
docker exec kafka ../../usr/bin/kafka-console-consumer --bootstrap-server kafka:9092 --topic ${TOPIC_NAME} 
docker exec kafka ../../usr/bin/kafka-console-producer --bootstrap-server kafka:9092 --topic ${TOPIC_NAME} 

open http://localhost:8080