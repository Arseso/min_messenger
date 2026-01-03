cd ./src/ContentFilter/
echo "======= CREATING DOCKER IMAGE ========"
docker build -t content-filter:1.0.0 .
echo "======= RUNNING DOCKER COMPOSE FILE ========"
docker compose up