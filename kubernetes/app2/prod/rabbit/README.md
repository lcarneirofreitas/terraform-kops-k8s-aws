## Docker images

To create the images

```bash
docker build -t lcarneirofreitas/consumer:latest . -f DockerfileConsumer
docker build -t lcarneirofreitas/producer:latest . -f DockerfileProducer
```

To run the images

```bash
docker run --network host -d producer
docker run --network host -d consumer
```
