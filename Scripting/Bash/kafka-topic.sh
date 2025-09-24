#!/bin/bash

# Configurations
KAFKA_BIN="/path/to/kafka/bin"        
BOOTSTRAP_SERVERS="kafka1:9092,kafka2:9092,kafka3:9092,kafka4:9092,kafka5:9092,kafka6:9092,kafka7:9092,kafka8:9092,kafka9:9092,kafka10:9092"    
TO_EMAIL="your-email@example.com"    
FROM_EMAIL="kafka-monitor@example.com"

# Temp files
OUTPUT_FILE="/tmp/kafka_topics_partitions.txt"
ERROR_FILE="/tmp/kafka_check_error.log"

# Clear previous files
> "$OUTPUT_FILE"
> "$ERROR_FILE"

echo "Kafka Topics and Partitions Report - $(date)" >> "$OUTPUT_FILE"
echo "---------------------------------------------" >> "$OUTPUT_FILE"

# Get all topics
topics=$($KAFKA_BIN/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVERS --list 2>>"$ERROR_FILE")
if [ $? -ne 0 ]; then
    echo "Failed to fetch topics!" >> "$ERROR_FILE"
fi

if [ -z "$topics" ]; then
    echo "No topics found or error occurred." >> "$ERROR_FILE"
fi

# Loop through each topic to get partitions
for topic in $topics; do
    echo "Topic: $topic" >> "$OUTPUT_FILE"
   
    # Get partition info
    partitions=$($KAFKA_BIN/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVERS --describe --topic "$topic" 2>>"$ERROR_FILE" | grep Partition)
    if [ $? -ne 0 ]; then
        echo "Failed to describe topic $topic" >> "$ERROR_FILE"
    fi
    echo "$partitions" >> "$OUTPUT_FILE"
    echo "---------------------------------------------" >> "$OUTPUT_FILE"
done

# Check if errors occurred
if [ -s "$ERROR_FILE" ]; then
    mailx -s "Kafka Monitoring FAILURE - $(date)" -r "$FROM_EMAIL" "$TO_EMAIL" < "$ERROR_FILE"
    exit 1
else
    mailx -s "Kafka Monitoring SUCCESS - $(date)" -r "$FROM_EMAIL" "$TO_EMAIL" < "$OUTPUT_FILE"
    exit 0
fi
