
# Spring Boot Application Deployment with Azure DevOps, Terraform, and Azure Container Apps

This repository contains a Spring Boot application that connects to an Azure MySQL database. The infrastructure is provisioned using Terraform, the application is containerized using Docker, and the CI/CD pipeline is implemented using Azure DevOps.

## Table of Contents

1. [Application Overview](#application-overview)
2. [Dockerfile](#dockerfile)
3. [Health Check Script](#health-check-script)
4. [Terraform Structure](#terraform-structure)
5. [Azure DevOps Pipeline](#azure-devops-pipeline)
6. [Setup and Deployment](#setup-and-deployment)
7. [Download and Installation](#download-and-installation)
8. [License](#license)

---

## Application Overview

The application is a simple Spring Boot API that connects to an Azure MySQL database. It exposes a `/live` endpoint for health checks to ensure the application can connect to the database.

### `/live` Endpoint Responses:
- **"Well done"**: When the application successfully connects to the database.
- **"Maintenance"**: When there is an issue connecting to the database.

### Environment Variables:
- `PORT`: The port on which the Spring Boot application listens.
- `DATABASE_URL`: The JDBC connection string for connecting to the Azure MySQL database.

---

## Dockerfile

The **Dockerfile** is a multi-stage build that compiles the Spring Boot application using Gradle and runs it on an Alpine-based JDK 17 image.

### Dockerfile Overview:

\`\`\`dockerfile
# Stage 1: Build the application
FROM gradle:7.4.2-jdk17 as builder

WORKDIR /app
COPY build.gradle settings.gradle /app/
RUN gradle build --no-daemon || return 0
COPY . /app
RUN gradle build --no-daemon

# Stage 2: Run the application
FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

# Set active Spring profile
ENV SPRING_PROFILES_ACTIVE=prod

# Expose port and run the application
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
\`\`\`

### How to Build and Run the Docker Image:

1. **Build the Docker image**:
    \`\`\`bash
    docker build -t springboot-app .
    \`\`\`

2. **Run the Docker container**:
    \`\`\`bash
    docker run -p 8080:8080 springboot-app
    \`\`\`

---

## Health Check Script

The **\`health_check.sh\`** script continuously monitors the health of the application by sending requests to the `/live` endpoint to ensure the application is connected to the database.

### health_check.sh:

\`\`\`bash
#!/bin/bash

HEALTH_URL="http://localhost:8080/live"

check_database() {
    response=$(curl -s $HEALTH_URL)
    if [[ "$response" == "Well done" ]]; then
        echo "Database connection successful: $response"
        return 0
    else
        echo "Database connection failed: $response"
        return 1
    fi
}

while true; do
    check_database
    if [ $? -ne 0 ]; then
        echo "ALERT: Database connection issue detected at $(date)"
    fi
    sleep 30
done
\`\`\`

### How to Use:
The script runs continuously and logs database connection issues. It can be included in your Docker image or run separately to monitor the application's connection to Azure MySQL.

---

## Terraform Structure

The infrastructure is provisioned using **Terraform**. It includes an Azure Container App, MySQL Flexible Server, Azure Container Registry (ACR), Virtual Network (VNet), and Log Analytics for monitoring.

### Directory Structure:

\`\`\`
.
├── main.tf                # Main entry point for modules
├── variables.tf           # Variables for the deployment
├── outputs.tf             # Outputs after Terraform run
├── providers.tf           # Azure provider configuration
├── network.tf             # Networking components (VNet, Subnets)
├── compute.tf             # Azure Container Apps and ACR setup
├── database.tf            # Azure MySQL setup
├── monitoring.tf          # Log Analytics and monitoring configuration
├── scaling.tf             # Autoscaling rules
├── security.tf            # Security configurations (RBAC, SSL)
└── terraform.tfvars       # Variables values (secrets not included here)
\`\`\`

### Key Terraform Components:

- **Azure Container App**: Hosts the containerized Spring Boot application.
- **Azure MySQL Flexible Server**: Used for the application's database.
- **Azure Container Registry (ACR)**: Stores the Docker images.
- **Virtual Network**: Secures MySQL with private endpoints.
- **Log Analytics**: Enables logging and monitoring for the application.

---

## Azure DevOps Pipeline

The Azure DevOps pipeline automates the building, pushing, and deployment of the Dockerized Spring Boot application to Azure Container Apps.

### Pipeline Overview (YAML):

\`\`\`yaml
trigger:
  branches:
    include:
      - main

variables:
  azureSubscription: '<your-azure-devops-service-connection>'
  containerRegistry: '<your-container-registry-name>'
  containerRepository: 'springboot-app'
  azureResourceGroup: '<your-resource-group>'
  containerAppEnvironment: '<your-container-app-environment>'
  containerAppName: '<your-container-app-name>'

stages:
  - stage: Build_and_Push_Image
    jobs:
      - job: Build
        steps:
          - task: DockerInstaller@0
          - task: AzureCLI@2
            inputs:
              azureSubscription: $(azureSubscription)
              scriptLocation: inlineScript
              inlineScript: |
                az acr login --name $(containerRegistry)
          - task: Docker@2
            inputs:
              containerRegistry: $(containerRegistry)
              repository: $(containerRepository)
              command: buildAndPush
              Dockerfile: '**/Dockerfile'
              tags: |
                latest

  - stage: Deploy_to_Container_App
    dependsOn: Build_and_Push_Image
    jobs:
      - job: Deploy
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: $(azureSubscription)
              scriptLocation: inlineScript
              inlineScript: |
                az containerapp update                   --name $(containerAppName)                   --resource-group $(azureResourceGroup)                   --environment $(containerAppEnvironment)                   --image $(containerRegistry)/$(containerRepository):latest
\`\`\`

### Key Features:
- **Build Docker image**: Builds the Docker image from the repository using the Dockerfile.
- **Push to ACR**: Pushes the built Docker image to **Azure Container Registry (ACR)**.
- **Deploy to Azure Container Apps**: Deploys the container image from ACR to **Azure Container Apps**.

---

## Setup and Deployment

### Step 1: Clone the Repository

Clone this repository to your local machine:

\`\`\`bash
git clone <repository-url>
cd <repository-directory>
\`\`\`

### Step 2: Build and Run Locally (Optional)

You can build and run the Dockerized Spring Boot application locally:

\`\`\`bash
docker build -t springboot-app .
docker run -p 8080:8080 springboot-app
\`\`\`

### Step 3: Run Terraform

Run the Terraform scripts to provision the necessary infrastructure:

\`\`\`bash
terraform init
terraform plan
terraform apply
\`\`\`

Make sure to set your \`terraform.tfvars\` file with the appropriate values.

### Step 4: Azure DevOps Pipeline

1. Set up your Azure DevOps pipeline using the provided **\`azure-pipelines.yml\`** file.
2. Trigger the pipeline by pushing changes to the \`main\` branch or manually starting the pipeline.
3. Monitor the build, push, and deployment steps in Azure DevOps.

### Step 5: Monitor and Test

- Use **Azure Monitor** and **Log Analytics** for monitoring.
- Use the **\`/live\`** endpoint to check the health of the application.

---

## Download and Installation

To download the project, clone it directly from the repository:

\`\`\`bash
git clone https://github.com/your-repo/springboot-app.git
\`\`\`

For a direct download:

[Download ZIP](https://github.com/your-repo/springboot-app/archive/main.zip)

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

### Contact

For any issues or inquiries, please reach out to the project maintainer at **[maintainer-email]**.
