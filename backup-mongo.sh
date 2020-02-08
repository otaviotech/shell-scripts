#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -d|--database)
    DATABASE="$2"
    shift # past argument
    shift # past value
    ;;

  -h|--host)
    HOST="$2"
    shift # past argument
    shift # past value
    ;;

  -o|--output)
    OUTPUT="$2"
    shift # past argument
    shift # past value
    ;;

  -c|--container)
    MONGO_CONTAINER="$2"
    shift # past argument
    shift # past value
    ;;

  -v|--volume)
    CONTAINER_VOLUME="$2"
    shift # past argument
    shift # past value
    ;;

  -h|--help)
    CONTAINER_VOLUME="$2"
    echo "Backup a MongoDB database."
    echo "-d, --database    The MongoDB database name."
    echo "-o, --output      The base output name."
    echo "-h, --help        Show this help menu."

    exit 0
    ;;

  *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

set -- "${POSITIONAL[@]}"

if [ -z "$MONGO_CONTAINER" ]
then
  if ! [ -x "$(command -v mongodump)" ]; then
    echo 'Error: mongodump is not installed.' >&2
    echo 'See -c option if you have a MongoDB .' >&2
    exit 1
  fi
  mongodump --gzip -d $DATABASE --out $OUTPUT
else
  if [ "$(docker ps -q -f name=$MONGO_CONTAINER)" ]; then
    HOST_VOLUME=$(echo $CONTAINER_VOLUME | cut -d ':' -f 1)
    DOCKER_VOLUME=$(echo $CONTAINER_VOLUME | cut -d ':' -f 2)
    DOCKER_OUTPUT="$DOCKER_VOLUME/$OUTPUT"
    DOCKER_OUTPUT=$(echo "${DOCKER_OUTPUT//\/\///}") # Remove double slashes
    HOST_OUTPUT="$HOST_VOLUME/$OUTPUT"
    RAN_THROUGH_DOCKER="true"

    docker exec -it $MONGO_CONTAINER mongodump --gzip -d $DATABASE --out $DOCKER_OUTPUT
  else
    echo "Container with name $MONGO_CONTAINER does not exist or it is not running."
  fi
fi

if [ "$RAN_THROUGH_DOCKER" ]; then
  echo $HOST_OUTPUT $DATABASE
  tar -zcf ${OUTPUT}_$(date +%F_%H-%m-%S).tar.gz -C $HOST_OUTPUT $DATABASE
else
  tar -zcf ${OUTPUT}_$(date +%F_%H-%m-%S).tar.gz -C $OUTPUT/$DATABASE $OUTPUT
fi

