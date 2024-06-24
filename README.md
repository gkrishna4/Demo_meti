Requirement is to build only single microservice from multiple micro-services
=================================================================================
build only a single microservice from a monorepo containing multiple microservices, and using Maven as your build tool, you can structure your Jenkinsfile to selectively 
build and deploy only the specified microservice.
Monorepo Structure
===================
microservices-repo/
├── serviceA/
│   ├── src/
│   ├── Dockerfile
│   ├── pom.xml
│   └── ...
├── serviceB/
│   ├── src/
│   ├── Dockerfile
│   ├── pom.xml
│   └── ...
├── serviceC/
│   ├── src/
│   ├── Dockerfile
│   ├── pom.xml
│   └── ...
└── Jenkinsfile

Here’s a Jenkinsfile that builds, runs SonarQube analysis, and deploys a specified microservice based on a parameter passed to the pipeline:
pipeline {
    agent any
    parameters {
        string(name: 'SERVICE', defaultValue: '', description: 'Name of the microservice to build (e.g., serviceA, serviceB, serviceC)')
    }
    environment {
        DOCKER_REGISTRY = 'your-docker-registry'
        DOCKER_CREDENTIALS_ID = 'docker-credentials-id'
        SONARQUBE_SERVER = 'SonarQubeServer'
    }
    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.SERVICE) {
                        error "SERVICE parameter is required."
                    }
                }
            }
        }
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build and Test') {
            steps {
                dir("${params.SERVICE}") {
                    script {
                        sh 'mvn clean package'
                    }
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                dir("${params.SERVICE}") {
                    withSonarQubeEnv('SonarQubeServer') {
                        sh 'mvn sonar:sonar'
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    timeout(time: 1, unit: 'HOURS') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                dir("${params.SERVICE}") {
                    script {
                        docker.build("${DOCKER_REGISTRY}/${params.SERVICE}:${env.BUILD_ID}")
                    }
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                dir("${params.SERVICE}") {
                    script {
                        docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                            docker.image("${DOCKER_REGISTRY}/${params.SERVICE}:${env.BUILD_ID}").push()
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
-------------------------------------

Explanation
============
Parameters Section:---->  SERVICE: This parameter allows you to specify which microservice to build.
Validate Parameters Stage:-------> Ensures the SERVICE parameter is provided.
Checkout Stage:-------> Checks out the code from the repository.
Build and Test Stage:------> Uses the SERVICE parameter to navigate to the correct directory and build the specified microservice using Maven.
SonarQube Analysis Stage:------> Runs SonarQube analysis on the specified microservice.
Quality Gate Stage:-----> Waits for the SonarQube Quality Gate result.
Build Docker Image Stage:------> Builds a Docker image for the specified microservice.
Push Docker Image Stage:------> Pushes the Docker image to the Docker registry.


Running the Pipeline:
======================
When you run this pipeline, you need to specify the SERVICE parameter to indicate which microservice to build.This can be done through the Jenkins UI 
or via a script that triggers the build.
Example of Running the Pipeline:
Via Jenkins UI:

Go to the pipeline’s page in Jenkins.
=====================================
Click on "Build with Parameters."
Enter the name of the service (e.g., serviceA) in the SERVICE field.
Click "Build."

Via Script:
===========
Use the Jenkins CLI or a script to trigger the build with parameters:
curl -X POST "http://your-jenkins-url/job/your-job-name/buildWithParameters?SERVICE=serviceA"

This setup allows you to selectively build and deploy only the specified microservice from the monorepo, ensuring efficient and targeted CI/CD operations.















