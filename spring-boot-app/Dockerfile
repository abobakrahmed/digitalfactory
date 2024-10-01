# Stage 1: Build the application
FROM gradle:7.4.2-jdk17 as builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Gradle wrapper, settings, and build files first (to leverage Docker layer caching)
COPY build.gradle settings.gradle /app/

# Download all dependencies before copying the source code to take advantage of Docker caching
RUN gradle build --no-daemon || return 0

# Copy the rest of the application code
COPY . /app

# Build the application (this will create the jar file)
RUN gradle build --no-daemon -x test

# Stage 2: Run the application
FROM openjdk:17-jdk-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the built JAR file from the builder stage
COPY --from=builder /app/build/libs/*.jar app.jar


## Copy the health check script into the container
COPY health_check.sh /app/health_check.sh
#

# Verify the script is copied and check the file path
RUN ls -la /app/health_check.sh
# Set the active Spring profile
ENV SPRING_PROFILES_ACTIVE=dev

# Expose the application port (default for Spring Boot is 8080)
EXPOSE 8080

# Ensure the health check script is executable
RUN chmod +x /app/health_check.sh

# Run both the application and the health check script in the background
CMD ["sh", "-c", "java -jar app.jar & /app/health_check.sh"]
