---

# **Spring Boot Application Deployment with Azure DevOps, Terraform, and Azure Container Apps**

This repository contains a Spring Boot application that connects to an Azure MySQL database. The infrastructure is provisioned using Terraform, the application is containerized using Docker, and the CI/CD pipeline is implemented using Azure DevOps.

## **Table of Contents**

1. [Application Overview](#application-overview)  
2. [Dockerfile](#dockerfile)  
3. [Health Check Script](#health-check-script)  
4. [Terraform Structure](#terraform-structure)  
5. [Azure DevOps Pipeline](#azure-devops-pipeline)  
6. [Setup and Deployment](#setup-and-deployment)

---

## **Application Overview** {#application-overview}

The application is a simple Spring Boot API that connects to an Azure MySQL database. It exposes a /live endpoint for health checks to ensure the application can connect to the database.

### /live **Endpoint Responses:**

* **"Well done"**: When the application successfully connects to the database.  
* **"Maintenance"**: When there is an issue connecting to the database.

### **Environment Variables:**

* PORT: The port on which the Spring Boot application listens.  
* DATABASE\_URL: The JDBC connection string for connecting to the Azure MySQL database.

---

## **Dockerfile** {#dockerfile}

The **Dockerfile** is a multi-stage build that compiles the Spring Boot application using Gradle and runs it on an Alpine-based JDK 17 image.

### **Dockerfile Overview:**

| \# Stage 1: Build the applicationFROM gradle:7.4.2\-jdk17 as builder\# Set the working directory inside the containerWORKDIR /app\# Copy the Gradle wrapper, settings, and build files first (to leverage Docker layer caching)COPY build.gradle settings.gradle /app/\# Download all dependencies before copying the source code to take advantage of Docker cachingRUN gradle build \--no-daemon || return 0\# Copy the rest of the application codeCOPY . /app\# Build the application (this will create the jar file)RUN gradle build \--no-daemon \-x test\# Stage 2: Run the applicationFROM openjdk:17\-jdk-alpine\# Set the working directory inside the containerWORKDIR /app\# Copy the built JAR file from the builder stageCOPY \--from=builder /app/build/libs/\*.jar app.jar\#\# Copy the health check script into the containerCOPY health\_check.sh /app/health\_check.sh\# Verify the script is copied and check the file pathRUN ls \-la /app/health\_check.sh\# Set the active Spring profileENV SPRING\_PROFILES\_ACTIVE=dev\# Expose the application port (default for Spring Boot is 8080\)EXPOSE 8080\# Ensure the health check script is executableRUN chmod \+x /app/health\_check.sh\# Run both the application and the health check script in the backgroundCMD \["sh", "-c", "java \-jar app.jar & /app/health\_check.sh"\] |
| :---- |

### **How to Build and Run the Docker Image:**

**Build the Docker image**:

| docker build \-t springboot-app . |
| :---- |

**Run the Docker container**:

| docker run \-p 8080:8080 springboot-app |
| :---- |

## **Health Check Script** {#health-check-script}

The **`health_check.sh`** script continuously monitors the health of the application by sending requests to the `/live` endpoint to ensure the application is connected to the database.

| \#\!/bin/bash\# URL of the health check endpoint for your Spring Boot applicationHEALTH\_URL="http://localhost:8080/live"\# Function to check the database connection via the /live endpointcheck\_database() {    \# Make the HTTP request to the /live endpoint    response=$(curl \-s $HEALTH\_URL)    \# Check if the response is "Well done" (meaning the database is accessible)    if \[\[ "$response" \== "Well done" \]\]; then        echo "$(date) \- Database connection to Azure MySQL successful: $response"        return 0    else        echo "$(date) \- Database connection to Azure MySQL failed: $response"        return 1    fi}\# Loop to continuously check every 30 secondswhile true; do    check\_database    \# If the database connection fails, log the issue or send an alert    if \[ $? \-ne 0 \]; then        echo "ALERT: Database connection issue detected at $(date)"        \# Optionally, add alerting mechanism here (e.g., send email, webhook, etc.)    fi    \# Wait for 30 seconds before the next check    sleep 30done |
| :---- |

## **Terraform Structure** {#terraform-structure}

The infrastructure is provisioned using **Terraform**. It includes an Azure Container App, MySQL Flexible Server, Azure Container Registry (ACR), Virtual Network (VNet), and Log Analytics for monitoring.

| ├── main.tf                \# Main entry point for modules├── variables.tf           \# Variables for the deployment├── outputs.tf             \# Outputs after Terraform run├── providers.tf           \# Azure provider configuration├── network.tf             \# Networking components (VNet, Subnets)├── compute.tf             \# Azure Container Apps and ACR setup├── database.tf            \# Azure MySQL setup├── monitoring.tf          \# Log Analytics and monitoring configuration├── scaling.tf             \# Autoscaling rules├── security.tf            \# Security configurations (RBAC, SSL) |
| :---- |

### **Key Terraform Components:**

* **Azure Container App**: Hosts the containerized Spring Boot application.  
* **Azure MySQL Flexible Server**: Used for the application's database.  
* **Azure Container Registry (ACR)**: Stores the Docker images.  
* **Virtual Network**: Secures MySQL with private endpoints.  
* **Log Analytics**: Enables logging and monitoring for the application.

## **Azure DevOps Pipeline** {#azure-devops-pipeline}

The Azure DevOps pipeline automates the building, pushing, and deployment of the 

| Dockerized Spring Boot application to Azure Container Apps.trigger:  branches:    include:      \- devvariables:  azureSubscription: '\<your-azure-devops-service-connection\>'  containerRegistry: '\<your-container-registry-name\>'  containerRepository: 'springboot-app'  azureResourceGroup: '\<your-resource-group\>'  containerAppEnvironment: '\<your-container-app-environment\>'  containerAppName: '\<your-container-app-name\>'stages:  \- stage: Build\_and\_Push\_Image    jobs:      \- job: Build        steps:          \- task: DockerInstaller@0          \- task: AzureCLI@2            inputs:              azureSubscription: $(azureSubscription)              scriptLocation: inlineScript              inlineScript: |                az acr login \--name $(containerRegistry)          \- task: Docker@2            inputs:              containerRegistry: $(containerRegistry)              repository: $(containerRepository)              command: buildAndPush              Dockerfile: '\*\*/Dockerfile'              tags: |                latest  \- stage: Deploy\_to\_Container\_App    dependsOn: Build\_and\_Push\_Image    jobs:      \- job: Deploy        steps:          \- task: AzureCLI@2            inputs:              azureSubscription: $(azureSubscription)              scriptLocation: inlineScript              inlineScript: |                az containerapp update \\                  \--name $(containerAppName) \\                  \--resource-group $(azureResourceGroup) \\                  \--environment $(containerAppEnvironment) \\                  \--image $(containerRegistry)/$(containerRepository):latest |
| :---- |

## **Setup and Deployment** {#setup-and-deployment}

### **Step 1: Clone the Repository**

Clone this repository to your local machine:

| git clone https://github.com/abobakrahmed/digitalfactory.gitcd digitalfactory |
| :---- |

### **Step 2: Build and Run Locally (Optional)**

You can build and run the Dockerized Spring Boot application locally:

| docker build \-t springboot-app .docker run \-p 8080:8080 springboot-app |
| :---- |

### **Step 3: Run Terraform**

Run the Terraform scripts to provision the necessary infrastructure:

| terraform initterraform planterraform apply |
| :---- |

Make sure to set your terraform.tfvars file with the appropriate values.

### **Step 4: Azure DevOps Pipeline**

1. Set up your Azure DevOps pipeline using the provided azure-pipelines.yml file.  
2. Trigger the pipeline by pushing changes to the dev branch or manually starting the pipeline.  
3. Monitor the build, push, and deployment steps in Azure DevOps.

### **Step 5: Monitor and Test**

* Use **Azure Monitor** and **Log Analytics** for monitoring.  
* Use the /live endpoint to check the health of the application.

