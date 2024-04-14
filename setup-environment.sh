#/bin/bash

# Get The Host OS Name
OS=$(uname)

# Check If docker is running
which docker
if [ $? -eq 1 ]; then
    echo "$(docker --version) is running ✅"
else
    echo "Docker is not running ❌"
    echo

    # Restart Docker
    echo "Attempting to start Docker..."

    if [[ $OS == "linux" ]]; then
        # Restart Docker on Linux
        sudo service docker restart
    elif [[ $OS == "Darwin" ]]; then
        open -a Docker
        while ! docker info > /dev/null 2>&1; do sleep 1; done
    elif [[ $OS == "windows" ]]; then
        # Restart Docker on Windows (using powershell)
        powershell -Command "Stop-Service docker; Start-Service docker"
    else
        echo "Unsupported OS: $OS. Docker restart failed ❌."
        exit
    fi
echo "$(docker --version) is running ✅"

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
        exit
    else
        echo $container_name container is running ✅
    fi
done

echo Waiting for Kafka cluster to be ready ... 🙇
# docker exec kafka ../../usr/bin/cub kafka-ready -b kafka:9092 1 60

# create topic, producer and consumer
docker exec kafka ../../usr/bin/kafka-topics --create --topic ${TOPIC_NAME} --partitions 2 --replication-factor 1 --if-not-exists --bootstrap-server kafka:9092
docker exec kafka ../../usr/bin/kafka-console-consumer --bootstrap-server kafka:9092 --topic ${TOPIC_NAME} 
docker exec kafka ../../usr/bin/kafka-console-producer --bootstrap-server kafka:9092 --topic ${TOPIC_NAME} 

# Open default browser to see kafka cluster UI
if [[ $OS == "linux" ]]; then
        xdg-open http://localhost:8080
        xdg-open http://localhost:9090
    elif [[ $OS == "Darwin" ]]; then
        open http://localhost:8080
        open http://localhost:9090
    elif [[ $OS == "windows" ]]; then
        explorer "http://localhost:8080"
        explorer "http://localhost:9090"
    else
        echo "Unsupported OS: Please Open the following Links."
        echo Open Kafka UI on http://localhost:8080
        echo Open Prometheus UI on http://localhost:9090
        exit
    fi
