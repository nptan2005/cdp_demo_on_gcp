FROM nptan2005/atlas-kafka:2.8.2

# Ensure Kafka data dir is EMPTY in the image
RUN rm -rf /var/lib/kafka/data/*

CMD ["/opt/kafka/bin/kafka-server-start.sh", "/opt/kafka/config/server.properties"]