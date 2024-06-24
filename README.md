# Requirement is to build only single microservice from multiple micro-services

build only a single microservice from a monorepo containing multiple microservices, and using Maven as your build tool, you can structure your Jenkinsfile to selectively 
build and deploy only the specified microservice.

## Monorepo Structure

```
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
```

Here’s a Jenkinsfile that builds, runs SonarQube analysis, and deploys a specified microservice based on a parameter passed to the pipeline:

```
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
```

## Explanation
```
Parameters Section:---->  SERVICE: This parameter allows you to specify which microservice to build.
Validate Parameters Stage:-------> Ensures the SERVICE parameter is provided.
Checkout Stage:-------> Checks out the code from the repository.
Build and Test Stage:------> Uses the SERVICE parameter to navigate to the correct directory and build the specified microservice using Maven.
SonarQube Analysis Stage:------> Runs SonarQube analysis on the specified microservice.
Quality Gate Stage:-----> Waits for the SonarQube Quality Gate result.
Build Docker Image Stage:------> Builds a Docker image for the specified microservice.
Push Docker Image Stage:------> Pushes the Docker image to the Docker registry.
```

## Running the Pipeline:

When you run this pipeline, you need to specify the SERVICE parameter to indicate which microservice to build.This can be done through the Jenkins UI 
or via a script that triggers the build.
Example of Running the Pipeline:
Via Jenkins UI:

## Go to the pipeline’s page in Jenkins.
Click on "Build with Parameters."
Enter the name of the service (e.g., serviceA) in the SERVICE field.
Click "Build."

## Via Script:

Use the Jenkins CLI or a script to trigger the build with parameters:
curl -X POST "http://your-jenkins-url/job/your-job-name/buildWithParameters?SERVICE=serviceA"

This setup allows you to selectively build and deploy only the specified microservice from the monorepo, ensuring efficient and targeted CI/CD operations.

### The Validate Parameters stage as it stands in the provided script is designed to validate a single service parameter (SERVICE). However, if you want to choose multiple services and build them, you'll need to modify the script to accept and handle multiple service parameters.

Here's how you can modify the script to accept and validate multiple service parameters:
```
stages {
    stage('Validate Parameters') {
        steps {
            script {
                def services = params.SERVICES.split(',') // Assuming services are passed as a comma-separated string
                if (!services) {
                    error "No services provided. At least one service is required."
                } else {
                    for (service in services) {
                        if (!fileExists("${service}/pom.xml")) {
                            error "Specified service '${service}' does not exist or is not a Maven project."
                        }
                    }
                }
            }
        }
    }
    // Add other stages for building, testing, and deploying the services here
}
```

The Validate Parameters stage as it stands in the provided script is designed to validate a single service parameter (SERVICE). However, if you want to choose multiple services and build them, you'll need to modify the script to accept and handle multiple service parameters.

Here's how you can modify the script to accept and validate multiple service parameters:
```
stages {
    stage('Validate Parameters') {
        steps {
            script {
                def services = params.SERVICES.split(',') // Assuming services are passed as a comma-separated string
                if (!services) {
                    error "No services provided. At least one service is required."
                } else {
                    for (service in services) {
                        if (!fileExists("${service}/pom.xml")) {
                            error "Specified service '${service}' does not exist or is not a Maven project."
                        }
                    }
                }
            }
        }
    }
    // Add other stages for building, testing, and deploying the services here
}
```
With this modification:

You can pass multiple services as a comma-separated string in the SERVICES parameter.
The script splits the string into individual service names.
It then iterates over each service name to validate if the corresponding pom.xml file exists for each service.
If any service is missing or is not a Maven project, it throws an error.
After validating the parameters, you can continue with the stages for building, testing, and deploying the services as needed within the same pipeline script. Adjust the script further according to your specific requirements for building and deploying multiple services.

Certainly! Here's a complete Jenkinsfile that accepts multiple services as parameters, validates them, and then proceeds with building, testing, and deploying each service:
```
pipeline {
    agent any
    
    parameters {
        string(name: 'SERVICES', defaultValue: '', description: 'Comma-separated list of services to build (e.g., serviceA,serviceB,serviceC)')
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
                    def services = params.SERVICES.split(',')
                    if (!services) {
                        error "No services provided. At least one service is required."
                    } else {
                        for (service in services) {
                            if (!fileExists("${service}/pom.xml")) {
                                error "Specified service '${service}' does not exist or is not a Maven project."
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build and Test Services') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        dir(service) {
                            echo "Building and testing ${service}..."
                            sh "mvn clean package"
                        }
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        dir(service) {
                            echo "Running SonarQube analysis for ${service}..."
                            withSonarQubeEnv('SonarQubeServer') {
                                sh "mvn sonar:sonar"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        echo "Waiting for SonarQube Quality Gate for ${service}..."
                        timeout(time: 1, unit: 'HOURS') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
            }
        }
        
        stage('Build and Push Docker Images') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        dir(service) {
                            echo "Building Docker image for ${service}..."
                            docker.build("${DOCKER_REGISTRY}/${service}:${env.BUILD_ID}")
                            echo "Pushing Docker image for ${service}..."
                            docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                                docker.image("${DOCKER_REGISTRY}/${service}:${env.BUILD_ID}").push()
                            }
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
```
## To run or skip specific stages in a Jenkins pipeline, you can use the when directive, environment variables, and parameters to control the flow of your pipeline. Here's an example of how you can achieve this:
> Using Parameters: Define parameters at the beginning of your pipeline to control which stages to run. Use the `when` directive in each stage to conditionally execute it based on the parameters.

```
pipeline {
    agent any

    // Define parameters
    parameters {
        booleanParam(name: 'RUN_BUILD', defaultValue: true, description: 'Run Build Stage')
        booleanParam(name: 'RUN_TEST', defaultValue: true, description: 'Run Test Stage')
        booleanParam(name: 'RUN_SONARQUBE', defaultValue: true, description: 'Run SonarQube Analysis Stage')
        booleanParam(name: 'RUN_DOCKER_BUILD', defaultValue: true, description: 'Run Docker Build Stage')
        booleanParam(name: 'RUN_STAGING', defaultValue: true, description: 'Run Staging Stage')
        booleanParam(name: 'RUN_UAT', defaultValue: true, description: 'Run UAT Stage')
        booleanParam(name: 'RUN_PRODUCTION', defaultValue: true, description: 'Run Production Stage')
    }

    stages {
        stage('Build') {
            when {
                expression { return params.RUN_BUILD }
            }
            steps {
                echo 'Building...'
                // Your build steps here
            }
        }

        stage('Test') {
            when {
                expression { return params.RUN_TEST }
            }
            steps {
                echo 'Testing...'
                // Your test steps here
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { return params.RUN_SONARQUBE }
            }
            steps {
                echo 'Running SonarQube Analysis...'
                // Your SonarQube analysis steps here
            }
        }

        stage('Docker Build') {
            when {
                expression { return params.RUN_DOCKER_BUILD }
            }
            steps {
                echo 'Building Docker Image...'
                // Your Docker build steps here
            }
        }

        stage('Staging') {
            when {
                expression { return params.RUN_STAGING }
            }
            steps {
                echo 'Deploying to Staging...'
                // Your staging steps here
            }
        }

        stage('UAT') {
            when {
                expression { return params.RUN_UAT }
            }
            steps {
                echo 'Running UAT...'
                // Your UAT steps here
            }
        }

        stage('Production') {
            when {
                expression { return params.RUN_PRODUCTION }
            }
            steps {
                echo 'Deploying to Production...'
                // Your production steps here
            }
        }
    }
}
```
## Explanation:
> Parameters Section: We define boolean parameters for each stage, allowing the user to specify which stages to run. By default, all stages are set to run.
> ` when` Directive: Each stage has a `when` directive that checks the corresponding parameter to decide whether to execute the stage. The `expression` closure returns the value of the parameter (`true` or `false`), controlling the execution of the stage.

## Usage:
> When triggering the pipeline, you can choose which stages to run by setting the parameters accordingly. This can be done manually through the Jenkins UI or by passing parameters in a script or from another job.

## How to Use: Triggering the Pipeline:  
   > When triggering the pipeline, you can choose which stages to run by setting the parameters.
   > For example, if you want to skip the SonarQube analysis and UAT stages, you can set `RUN_SONARQUBE=false` and `RUN_UAT=false` when starting the pipeline.

## Manual Trigger via Jenkins UI:

>Go to your Jenkins job.
>Click on "Build with Parameters".
>Uncheck the stages you want to skip and leave the others checked.

## Trigger via Script:
You can also trigger the pipeline via a script or another Jenkins job with parameters.
```
curl -X POST 'http://jenkins-url/job/your-job/buildWithParameters' --data 'RUN_BUILD=true&RUN_TEST=true&RUN_SONARQUBE=false&RUN_DOCKER_BUILD=true&RUN_STAGING=true&RUN_UAT=false&RUN_PRODUCTION=true'
```

## Explaining the Release Process to an Interviewer

 `Feature Development`
          Developers work on new features and bug fixes in separate feature branches. These are reviewed and merged into the main branch once they are ready.
          
 `Creating a Release Branch`
         When we are ready to prepare a new release, we create a release branch from the main branch. This branch is used to stabilize the release 
          and ensure that all changes are thoroughly tested.
          
` Staging Environment`
             We deploy the release branch to our staging environment, which closely mimics our production setup. Here, we conduct extensive testing, 
             including integration, performance, and security tests. This helps us catch any issues that might occur in a production-like environment.
             
` Pre-Production Environment`
            After successful testing in staging, we deploy the release branch to our pre-production environment. This environment is used for
             final user acceptance testing and serves as the last checkpoint before production. It ensures that everything works as expected and provides
             an additional layer of validation.
             
 ` Final Release`
            Once we are confident in the stability of the release, we tag the release branch with the release version, merge it back into the main branch, 
            and deploy it to production. This structured process allows us to maintain high quality and minimize risks associated with releasing new software.
             
> By using staging and pre-production environments, we can isolate different phases of testing and validation, which greatly enhances the reliability of our releases
> and reduces the risk of introducing issues into our production environment."
            















