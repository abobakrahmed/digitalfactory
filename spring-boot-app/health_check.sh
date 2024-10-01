#!/bin/bash

# URL of the health check endpoint for your Spring Boot application
HEALTH_URL="http://localhost:8080/live"

# Function to check the database connection via the /live endpoint
check_database() {
    # Make the HTTP request to the /live endpoint
    response=$(curl -s $HEALTH_URL)
    
    # Check if the response is "Well done" (meaning the database is accessible)
    if [[ "$response" == "Well done" ]]; then
        echo "$(date) - Database connection to Azure MySQL successful: $response"
        return 0
    else
        echo "$(date) - Database connection to Azure MySQL failed: $response"
        return 1
    fi
}

# Loop to continuously check every 30 seconds
while true; do
    check_database

    # If the database connection fails, log the issue or send an alert
    if [ $? -ne 0 ]; then
        echo "ALERT: Database connection issue detected at $(date)"
        # Optionally, add alerting mechanism here (e.g., send email, webhook, etc.)
    fi
    
    # Wait for 30 seconds before the next check
    sleep 30
done
