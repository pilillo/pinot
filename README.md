# Pinot

Disposable local tests with Apache Pinot. 

## Interacting with Pinot

The broker and controller services expose REST [APIs](https://docs.pinot.apache.org/users/api).
In addition, a [CLI](https://docs.pinot.apache.org/operators/cli) is available to perform any operation on the cluster, such as defining schema or adding tables, i.e.:

```
pinot-admin.sh AddTable -tableConfigFile /path/to/table.json -schemaFile /path/to/schema.json -controllerHost localhost -controllerPort 9000 -exec
```

for instance:

```
docker run \
    --network=pinot-demo \
    --name pinot-streaming-table-creation \
    ${PINOT_IMAGE} AddTable \
    -schemaFile examples/stream/githubEvents/pullRequestMergedEvents_schema.json \
    -tableConfigFile examples/stream/githubEvents/docker/pullRequestMergedEvents_realtime_table_config.json \
    -controllerHost pinot-controller \
    -controllerPort 9000 \
    -exec
```

Pinot supports JSON, Avro, Thrift, Parquet, ORC and Protobuf [out of the box](https://docs.pinot.apache.org/v/release-0.11.0/basics/data-import/pinot-input-formats). For Avro, the schema registry is supported. 

For instance, avro stream ingestion can be configured with:

```
"streamType": "kafka",
"stream.kafka.decoder.class.name": "org.apache.pinot.plugin.stream.kafka.KafkaAvroMessageDecoder",
"stream.kafka.decoder.prop.schema.registry.rest.url": "http://localhost:2222/schemaRegistry",
```

## Docker compose

In the [docker quickstart](https://docs.pinot.apache.org/basics/getting-started/running-pinot-in-docker) Pinot is set up as docker compose.

```
docker-compose --project-name pinot-demo up
```

## Configuring deep storage

By default, Apache Pinot will run with ephimeral storage, so in order to persist ingested data, a connection to a [deep storage](https://docs.pinot.apache.org/basics/data-import#pinot-file-systems) has to be set, for instance [Amazon S3](https://docs.pinot.apache.org/users/tutorials/use-s3-as-deep-store-for-pinot), also documented as tutorial [here](https://dev.startree.ai/docs/pinot/recipes/minio-deep-store).

In the example, we use minio. You can login at `localhost:9101` using the default `minioadmin` user and `minioadmin` password.
Under `identity > users`, you can create a new user with `miniodeepstorage` and `miniodeepstorage` credentials and finally a bucket named `pinot-events`. Do not forget to assgn it `readwrite` access to the user for the bucket. See example `controller-conf.conf` file in case you want to change those default settings.

## Ingesting data

Please head [here](https://docs.pinot.apache.org/basics/getting-started/pushing-your-data-to-pinot) to ingest a batch of data into Pinot, and [here](https://docs.pinot.apache.org/basics/getting-started/pushing-your-streaming-data-to-pinot) to connect a Kafka topic.

For instance, in the data folder you can find a schema and a table configuration, as taken from [the pinot-minio recipe](https://github.com/startreedata/pinot-recipes/tree/main/recipes/minio-real-time):

Create an `events` topic and add it as realtime table as follows:

```
docker exec -it pinot-controller bin/pinot-admin.sh AddTable   \
  -tableConfigFile /config/table-realtime.json   \
  -schemaFile /config/schema.json -exec
```

Finally, use the `generate_data.sh` script to generate random samples. You can also inspect the topic using the kafka utils contained in the kafka container, for instance:

```
kafka-console-consumer --topic events --bootstrap-server localhost:9092 --from-beginning
```

## Connecting to Pinot from Superset

Given the name of the services as defined in the docker compose file, you can connect via a sql alchemy string having format:

```
pinot+http://pinot-broker:8099/query?controller=http://pinot-controller:9000/
```

## Kubernetes setup

Please also refer to the official documentation [here](https://docs.pinot.apache.org/basics/getting-started/kubernetes-quickstart).

### Cluster creation

Make sure you have kind (https://kind.sigs.k8s.io/) installed and select the latest version [here](https://github.com/kubernetes-sigs/kind/releases).

```
export KIND_IMAGE=kindest/node:v1.24.0@sha256:0866296e693efe1fed79d5e6c7af8df71fc73ae45e3679af05342239cdc5bc8e

cat kind-cluster.yaml | envsubst | kind create cluster --config=-
```

### Installing Kafka

```
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
kubectl apply -f k8s/kafka-cluster.yaml -n kafka 
```

### Installing Pinot

```
kubectl create ns pinot
helm repo add pinot https://raw.githubusercontent.com/apache/pinot/master/kubernetes/helm
helm install pinot pinot/pinot -n pinot --set cluster.name=pinot --namespace pinot
```

### Installing Superset

```
kubectl create ns superset
helm repo add superset https://apache.github.io/superset
helm upgrade --install superset superset/superset --namespace superset
```

### Cleanup

```
kind delete cluster --name=pinot-cluster
```