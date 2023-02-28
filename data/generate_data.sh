while true; do
  if command -v uuidgen &> /dev/null
  then
    uuid=`uuidgen | sed 's/[-]//g'`
    ts=$(($(date +'%s * 1000 + %-N / 1000000')))
  else
    ts=`date +%s%N | cut -b1-13`;
    uuid=`cat /proc/sys/kernel/random/uuid | sed 's/[-]//g'`
  fi
  count=$[ $RANDOM % 1000 + 0 ]
  echo "{\"ts\": \"${ts}\", \"uuid\": \"${uuid}\", \"count\": $count}"
done |
docker exec -i pinot-kafka-1 kafka-console-producer --bootstrap-server localhost:9092 --topic events