## Installing Plugins Manually:
If you have a plugin in the `.hpi` or `.jpi` file format, you can install it manually:
### Download the Plugin:
Download the `.hpi` or `.jpi` file from the official Jenkins plugin repository or from any other trusted source.
### Upload the Plugin:
From the Jenkins dashboard, click on "Manage Jenkins".
Click on "Manage Plugins".
Go to the "Advanced" tab.
In the "Upload Plugin" section, click "Choose File" and select the `.hpi` or `.jpi` file you downloaded.
Click "Upload".
### Restart Jenkins:
After uploading, Jenkins might require a restart to enable the plugin. Follow the prompt to restart Jenkins.

## Here i have 3 branches like dev,feature and release branches and have two test senarios like smoke and unit so for dev and frature branch unit test will run and comming to the relase branch this smoke test will run How?
```
pipeline {
    agent any

    stages {
        stage('Run Tests') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'dev' || env.BRANCH_NAME.startsWith("feature")) {
                        echo "Running UNIT tests..."
                        sh "./run-unit-tests.sh"
                    } else if (env.BRANCH_NAME.startsWith("release")) {
                        echo "Running SMOKE tests..."
                        sh "./run-smoke-tests.sh"
                    }
                }
            }
        }
    }
}

```
## GitHub Actions (Most Common)
```
name: Run Tests

on:
  push:
    branches:
      - dev
      - feature/**
      - release/**
  pull_request:
    branches:
      - dev
      - feature/**
      - release/**

jobs:
  tests:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      # -------------------------
      # UNIT TESTS (dev + feature)
      # -------------------------
      - name: Run Unit Tests
        if: startsWith(github.ref, 'refs/heads/dev') || startsWith(github.ref, 'refs/heads/feature/')
        run: |
          echo "Running UNIT Tests..."
          ./run-unit-tests.sh

      # -------------------------
      # SMOKE TESTS (release)
      # -------------------------
      - name: Run Smoke Tests
        if: startsWith(github.ref, 'refs/heads/release/')
        run: |
          echo "Running SMOKE Tests..."
          ./run-smoke-tests.sh
```

----------------------
##  Execute multiple stages in parallel within a single parent stage:
In a Jenkins declarative pipeline, you can execute multiple stages in parallel within a single parent stage by using the `parallel directive`. 
Here’s an example that shows how you could structure a Jenkins pipeline to execute two stages in parallel within a single "wrapper" stage.
### Example 1:
```
stage("maven build & test") {
  parallel {
    stage("maven build") {
      steps {
        script {
          // Uses the Maven installation configured in Jenkins
          def mavenHome = tool name: 'M3', type: 'maven'  // change 'M3' to your Maven tool name
          withEnv(["PATH+MAVEN=${mavenHome}/bin"]) {

            // Optional: point to a settings.xml if needed
            // def mvnSettings = "${env.WORKSPACE}/.jenkins/settings.xml"

            sh """
              echo "Maven Home: ${mavenHome}"
              mvn --version

              # Build without running tests (common in multi-stage pipelines)
              mvn -B -U -DskipTests clean package
            """
          }
        }
      }
    }

    stage("test") {
      steps {
        script {
          def mavenHome = tool name: 'M3', type: 'maven'
          withEnv(["PATH+MAVEN=${mavenHome}/bin"]) {
            sh """
              mvn -B -U test
            """
          }

          // Publish test reports (JUnit/Surefire)
          junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true

          // If you also use JaCoCo for coverage:
          // recordCoverage(tools: [[parser: 'JACOCO']], sourceCodeRetention: 'LAST_BUILD', failIfCoverageEmpty: false)
          // Or explicit:
          // jacoco execPattern: '**/target/jacoco.exec', classPattern: '**/target/classes', sourcePattern: '**/src/main/java'
        }
      }
    }
  }
}
```
### Example 2:
```
pipeline {
    agent any
    
    stages {
        stage('Build Application') {
            steps {
                echo 'Building the application...'
                // Insert your build command here, e.g., `mvn clean install`
            }
        }
        stage('Deploy to Environments') {
            parallel {
                stage('Deploy to Staging') {
                    steps {
                        echo 'Deploying to Staging Environment...'
                        // Insert your staging deployment command here, e.g., `kubectl apply -f staging-deployment.yaml`
                    }
                }
                stage('Deploy to Production') {
                    steps {
                        echo 'Deploying to Production Environment...'
                        // Insert your production deployment command here, e.g., `kubectl apply -f production-deployment.yaml`
                    }
                }
            }
        }
    }
}

```
This Jenkins pipeline runs two tasks, `Stage 1` and `Stage 2`, at the same time using the parallel directive within a single stage called Parallel Execution. By running them in parallel, the pipeline completes both tasks faster, instead of waiting for one to finish before starting the other. The agent any setting allows Jenkins to use any available machine for this job, making the setup flexible and efficient.

## Requirement is to build only single microservice from multiple micro-services:
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
                        else {
                                echo "Service '${service}' is valid."
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

------------------------------------------
### Building a Jenkins pipeline that continues executing subsequent stages even if one stage fails involves configuring the pipeline script with appropriate error-handling mechanisms. In Jenkins, this can be achieved using the catchError, catchError, try-catch, and post conditions. Here’s how you can set this up in a real-time Jenkins pipeline using a Jenkinsfile.

## Basic Example: Declarative Pipeline
```
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                // Simulate a build command
                sh 'exit 1' // This command fails
            }
        }
        
        stage('Test') {
            steps {
                echo 'Testing...'
                // Simulate test commands
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                // Simulate deployment commands
            }
        }
    }
    
    post {
        always {
            echo 'This will always run, regardless of the pipeline status.'
        }
    }
}

```

## Handling Failures: Using `catchError`
You can use catchError to allow the pipeline to continue even if a stage fails.
```
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    echo 'Building...'
                    // Simulate a build command
                    sh 'exit 1' // This command fails
                }
            }
        }
        
        stage('Test') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    echo 'Testing...'
                    // Simulate test commands
                }
            }
        }
        
        stage('Deploy') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    echo 'Deploying...'
                    // Simulate deployment commands
                }
            }
        }
    }
    
    post {
        always {
            echo 'This will always run, regardless of the pipeline status.'
        }
    }
}

```

## Advanced Example: Using try-catch in Scripted Pipeline
For more advanced error handling, you can use the scripted pipeline syntax with `try-catch` blocks.

```
node {
    stage('Build') {
        try {
            echo 'Building...'
            // Simulate a build command
            sh 'exit 1' // This command fails
        } catch (Exception e) {
            echo 'Build stage failed: ' + e.toString()
            currentBuild.result = 'UNSTABLE'
        }
    }

    stage('Test') {
        try {
            echo 'Testing...'
            // Simulate test commands
        } catch (Exception e) {
            echo 'Test stage failed: ' + e.toString()
            currentBuild.result = 'UNSTABLE'
        }
    }

    stage('Deploy') {
        try {
            echo 'Deploying...'
            // Simulate deployment commands
        } catch (Exception e) {
            echo 'Deploy stage failed: ' + e.toString()
            currentBuild.result = 'UNSTABLE'
        }
    }

    // Post actions
    echo 'This will always run, regardless of the pipeline status.'
}

```
## Explanation:
### Declarative Pipeline:
`catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`: This command allows the pipeline to continue even if the enclosed steps fail. 
It sets the stage result to FAILURE but the overall build result remains SUCCESS.

## Scripted Pipeline:
    `try-catch`: Each stage is enclosed in a `try-catch` block to handle exceptions. If an exception occurs,
    it catches the error logs and sets the build result to UNSTABLE, allowing the pipeline to proceed.
---------------------------------------------------------------------------
### Dynamic Jenkins Pipeline Script
```
pipeline {
    agent any
    
    parameters {
        string(name: 'SERVICES', defaultValue: 'service1,service2,service3', description: 'Comma-separated list of services to build')
        string(name: 'MVN_PROFILE', defaultValue: 'dev', description: 'Maven profile to use for the build')
    }
    
    environment {
        DOCKER_REGISTRY = "your-docker-registry" // Replace with your Docker registry
        GIT_REPO = "https://your-repo-url.git" // Replace with your Git repository URL
        SONARQUBE_SERVER = "http://your-sonarqube-server" // Replace with your SonarQube server URL
    }

    triggers {
        pollSCM('* * * * *') // Adjust the polling frequency as needed
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "Checking out code from ${GIT_REPO}"
                    checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: GIT_REPO]]])
                }
            }
        }

        stage('Validate Parameters') {
            steps {
                script {
                    def services = params.SERVICES.split(',') // Split services into a list
                    if (!services) {
                        error "No services provided. At least one service is required."
                    } else {
                        for (service in services) {
                            if (!fileExists("${service}/pom.xml")) {
                                error "Specified service '${service}' does not exist or is not a Maven project."
                            } else {
                                echo "Service '${service}' is valid."
                            }
                        }
                    }
                }
            }
        }

        stage('Build and Test Services with Maven') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            stage("Maven Build and Test for ${service}") {
                                echo "Building and testing ${service} with Maven profile ${params.MVN_PROFILE}..."
                                dir(service) {
                                    sh "mvn clean install -P${params.MVN_PROFILE}"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Quality Gate (SonarQube)') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            stage("SonarQube Analysis for ${service}") {
                                echo "Running SonarQube analysis for ${service}..."
                                dir(service) {
                                    sh "mvn sonar:sonar -Dsonar.projectKey=${service} -Dsonar.host.url=${env.SONARQUBE_SERVER}"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                script {
                    def services = params.SERVICES.split(',')
                    for (service in services) {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            stage("Docker Build and Push for ${service}") {
                                echo "Building Docker image for ${service}..."
                                dir(service) {
                                    sh "docker build -t ${env.DOCKER_REGISTRY}/${service}:latest ."
                                    sh "docker push ${env.DOCKER_REGISTRY}/${service}:latest"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo "Pipeline completed."
                // Notifications, cleanup, etc.
            }
        }
        failure {
            script {
                echo "One or more stages have failed."
            }
        }
    }
}

```
### Explanation:
    1.SCM Checkout (pollSCM):
        The pollSCM('* * * * *') directive is configured to poll the SCM repository every minute for changes. 
        Adjust this schedule as needed.The Checkout Code stage checks out the code from a specified Git repository.
    2. Service Validation:
        This stage checks if the provided services are valid by ensuring that each service directory contains a pom.xml file, 
        which indicates it is a Maven project. If any service does not exist or is not a Maven project, the pipeline 
        will fail early, saving time and resources.
    3. Maven Build:
       Each service is built and tested using Maven with the specified profile (MVN_PROFILE). This stage is
       dynamically generated for each service.
    4. Quality Gate (SonarQube):
       The Quality Gate stage performs static code analysis using SonarQube. The analysis results are pushed to the specified SonarQube server.
    5. Docker Build and Push:
        The Docker Build and Push stage builds and pushes Docker images for each service to the specified Docker registry (DOCKER_REGISTRY).
    6. Error Handling:
        The catchError directive is used within each service stage to ensure that the pipeline continues even if a stage fails.
    7. Post Conditions:
        >> The always block is executed at the end of the pipeline, regardless of the build result, allowing for cleanup or notifications.
        >> The failure block is executed if any stage fails, giving a final notification of the failure.
-----------------------------------------------------------------------------
## Deploying an application to Kubernetes (K8s) using Jenkins involves several steps, including setting up Jenkins, configuring Jenkins to interact with Kubernetes, and creating a Jenkins pipeline to automate the deployment. Below is a high-level overview of the process:

### Prerequisites:
Kubernetes Cluster: Ensure you have a running Kubernetes cluster.
Jenkins Server: Have Jenkins installed and running.
Kubernetes CLI (kubectl): Install kubectl on the Jenkins server.
Jenkins Plugins: Install necessary plugins such as Kubernetes plugin, Pipeline plugin, Docker Pipeline plugin, etc.

## Step-by-Step Guide:
### Install Required Plugins: Go to Manage Jenkins > Manage Plugins and install the following:

Kubernetes plugin
Pipeline plugin
Docker Pipeline plugin
Git plugin (if using Git)

### Configure Kubernetes in Jenkins
#### 1.Add Kubernetes Credentials
  
   Go to `Manage Jenkins` > `Manage Credentials` > `System` > `Global credentials` (unrestricted) > `Add Credentials`.
   Select `Secret text` and add your Kubernetes API token.
#### 2.Configure Kubernetes Cloud:

Go to `Manage Jenkins` > `Manage Nodes and Clouds` > `Configure Clouds`.
Click `Add a new cloud` > `Kubernetes`.
Configure the Kubernetes plugin with your cluster details. Provide the Kubernetes API URL, credentials, and other necessary details.

#### 3. Create Jenkins Pipeline
```
pipeline {
    agent any
    environment {
        KUBECONFIG_CREDENTIAL_ID = 'kubeconfig-credentials' // Change this to your credentials ID
        KUBECONFIG = credentials(KUBECONFIG_CREDENTIAL_ID)
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo/your-app.git' // Change to your repo
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("your-docker-repo/your-app:${env.BUILD_ID}")
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') { // Change to your Docker Hub credentials
                        dockerImage.push()
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    kubernetesDeploy(
                        configs: 'k8s/deployment.yaml',
                        kubeconfigId: KUBECONFIG_CREDENTIAL_ID
                    )
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
#### 4.Kubernetes Deployment YAML
Ensure you have a Kubernetes deployment YAML file (k8s/deployment.yaml) in your repository. Below is a sample deployment.yaml:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: your-app
  template:
    metadata:
      labels:
        app: your-app
    spec:
      containers:
      - name: your-app
        image: your-docker-repo/your-app:latest
        ports:
        - containerPort: 80
```
## Summary
Set up Jenkins with the necessary plugins.
Configure Jenkins to connect to your Kubernetes cluster.
Create a Jenkins pipeline job.
Define your pipeline script in a Jenkinsfile.
Ensure you have a Kubernetes deployment YAML file in your repository.
Trigger the pipeline to build, push the Docker image, and deploy it to Kubernetes.

=======================================================================

In Jenkins pipelines, there are several default environment variables available to use. These variables are predefined and can be utilized in pipeline scripts to
help manage and control the execution flow. Below is a list of some of the most commonly used default environment variables in Jenkins pipelines:

### General Environment Variables
`BUILD_ID`: The current build ID, identical to BUILD_NUMBER.
`BUILD_NUMBER`: The current build number, a string that represents the build number for the project.
`BUILD_TAG`: String of jenkins-${JOB_NAME}-${BUILD_NUMBER}, which is unique for each build.
`BUILD_URL`: The URL where the results of the build can be found.
`EXECUTOR_NUMBER`: The number of the executor on which this build is running.
`JENKINS_HOME`: The absolute path of the directory assigned on the master node for Jenkins to store data.
`JENKINS_URL`: The URL of the Jenkins master that's running the build.
`JOB_NAME`: The name of the project of this build.
`JOB_BASE_NAME`: The base name of the job without the folder path.
`JOB_UR`L: The URL to the job.
`NODE_NAME`: Name of the node the build is running on.
`NODE_LABELS`: Whitespace-separated list of labels assigned to the node.
`WORKSPACE`: The absolute path of the directory assigned to the build as a workspace.
### Source Control Management (SCM) Related Variables
`GIT_BRANCH`: The name of the branch currently being used.
`GIT_COMMIT`: The commit hash currently being built.
`GIT_URL`: The URL of the repository.
##  Parameters
`PARAMETER_NAME`: If your pipeline uses parameters, each parameter can be accessed via its name.
## Time and Date Variables
`BUILD_DISPLAY_NAME`: The display name of the build.
`BUILD_ID`: The same as BUILD_NUMBER.
`BUILD_NUMBER`: The current build number, such as "153".
`BUILD_TAG`: A unique identifier, such as "jenkins-my-job-153".
`BUILD_URL`: The URL where the build can be found.
`EXECUTOR_NUMBER`: The executor number on which this build is running.
`HUDSON_HOME`: The same as JENKINS_HOME.
`HUDSON_SERVER_COOKIE`: A unique identifier of the current Jenkins instance.
`JENKINS_HOME`: The home directory of the Jenkins instance.
`JENKINS_SERVER_COOKIE`: A unique identifier of the current Jenkins instance.
`JOB_NAME`: The name of the job being executed.
`JOB_URL`: The URL to the job being executed.
`NODE_NAME`: The name of the node the build is running on.
`NODE_LABELS`: The labels of the node the build is running on.
`WORKSPACE`: The workspace directory where the build is running.
## Pipeline-specific Environment Variables
`STAGE_NAME`: The name of the current stage being executed.
`BUILD_STATUS`: The status of the current build (e.g., "SUCCESS", "FAILURE", "UNSTABLE").

These environment variables provide a wealth of information that can be used to control the behavior of Jenkins pipelines, integrate with other systems, 
and provide meaningful feedback about the build process.




# Securing Containers

This repository is a **hands-on, beginner-friendly guide** to securing containers.

We intentionally start with **insecure defaults**, then **progressively harden**
the container so each concept builds naturally on the previous one.

---

## What You Will Learn

- Why running containers as **root** is dangerous
- How to run containers as a **non-root user**
- Why `.dockerignore` is critical
- How **multi-stage builds** reduce attack surface
- Why **distroless images** are more secure
- How to **harden containers at runtime**

---

## Repository Structure

```text
sample-app/
├── app.js
├── package.json
└── README.md
```

---

## Sample Application

We use a **very small Node.js application** so the focus stays on
**container behavior and security**, not application complexity.

The app prints the **user ID** running inside the container, which makes
root vs non-root immediately visible.

---

## STEP 1: Insecure Container

This is how many people **first learn Docker**.
It works, but it is **not safe for production**.

---

### Dockerfile

```dockerfile
FROM node:25

WORKDIR /app
COPY . .

RUN npm install

EXPOSE 3000
CMD ["npm", "start"]
```

---

### 🚨 What’s Wrong Here?

| Issue | Why It’s a Problem |
|------|-------------------|
| Runs as root | App compromise = full container control |
| Single-stage build | Build tools stay in runtime |
| Copies everything | Secrets & junk may leak |
| Writable filesystem | Easy persistence |
| No limits | Container can impact host |

---

### ▶️ Build & Run

```bash
docker build -f Dockerfile -t insecure-app .
docker run -p 3000:3000 insecure-app
```

Output:

```
User ID: 0
```

👉 **User ID 0 means root**.

---

## STEP 2: Run as Non-Root User (Reduce Blast Radius)

Before optimizing images, the **first real security fix** is to
**stop running applications as root**.

### Why Non-Root Matters

If an attacker exploits your app:
- Root user → full container control
- Non-root user → **limited permissions**

This significantly reduces damage.

---

### Dockerfile.nonroot

```dockerfile
FROM node:25

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY . .
RUN npm install

# Switch to non-root user
USER appuser

EXPOSE 3000
CMD ["npm", "start"]
```

---

### ▶️ Build & Run (Non-Root)

```bash
docker build -f Dockerfile -t nonroot-app .
docker run -p 3000:3000 nonroot-app
```

Output:

```
User ID: 1000
```

👉 The app now runs as a **non-root user**.

⚠️ Still not secure:
- Image is large
- Build tools remain
- OS utilities exist

---

## STEP 3: Add `.dockerignore` 

Now that we fixed **who runs the app**, we fix **what gets copied**.

### Why `.dockerignore` Is Important

Without it:
- `.git` history gets baked in
- `.env` files may leak secrets
- `node_modules` bloats images

---

### .dockerignore

```dockerignore
.git
.gitignore
node_modules
.env
Dockerfile*
README.md
```

---

### ✅ Benefits

| Benefit | Why It Matters |
|------|----------------|
| Smaller image | Faster builds, fewer CVEs |
| No secrets | Prevents accidental leaks |
| Clean context | Easier security review |

---

## STEP 4: Multi-Stage Builds (Reduce Attack Surface)

Next, we separate **build-time** and **runtime** concerns.

### What Multi-Stage Builds Do

- Build app in one image
- Run app in another
- Copy only what is needed

---

### Dockerfile.multistage

```dockerfile
##### Stage 1: Builder Stage #####
FROM node:bookworm AS builder

# Set Working Directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install --production

# Copy the application source code
COPY *.js .

##### Stage 2: Final Stage ##### 
FROM node:bookworm-slim AS final  

# Set Working Directory
WORKDIR /app

# Copy the necessary files from the builder stage
COPY --from=builder /app ./

# Expose the application port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]
```

---

### ✅ Improvements

- Smaller runtime image
- Fewer tools for attackers
- Cleaner separation

---

## STEP 5: Distroless Images (Minimal & Secure)

Now we remove **almost the entire operating system**.

### Why Distroless Works

Distroless images have:
- No shell
- No package manager
- No OS tools

Attackers have very little to work with.

---

### Dockerfile (Multi-Stage + Distroless)

```dockerfile
# -------- Build Stage --------
FROM node:25 AS builder

WORKDIR /build
COPY package.json ./
RUN npm install
COPY . .

# -------- Runtime Stage --------
FROM gcr.io/distroless/nodejs20-debian12

WORKDIR /app
COPY --from=builder /build/app.js ./app.js
COPY --from=builder /build/node_modules ./node_modules

EXPOSE 3000
CMD ["app.js"]
```

---

### ▶️ Run (Distroless)

```
User ID: 65532
```

👉 Non-root by default, no shell available.

---

## STEP 6: Harden the Runtime (Defense in Depth)

Even secure images need runtime protection.

---

### Hardened Run Command

```bash
docker run \
  --read-only \
  --tmpfs /tmp \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --pids-limit 100 \
  --memory 256m \
  --cpus 0.5 \
  -p 3000:3000 \
  secure-app
```

---

## Final Takeaway

> **Secure container = Secure image + Hardened runtime**

Fix:
1. Who runs the app
2. What goes into the image
3. What stays in the image
4. What tools exist
5. What the app can do at runtime

---

### 🛠️ How to Create a Private GitHub Repository
  ## ✅ Method 1: Create a Private Repository (Web UI)
  
      Log into GitHub
      Click the “+” icon → New repository
      Enter a repository name & Add the discripction related to that Repo
      Under Visibility, select Private
      Click Create repository.
      
  ## ✅ Method 2: Create a Private Repository (GitHub CLI)
  
        GitHub CLI command:
            gh repo create <repository-name> --private

| Purpose                                | Certificate / Method Supported               | Notes                                     |
|----------------------------------------|----------------------------------------------|-------------------------------------------|
| Access private repo via HTTPS          | Access Token / Username + Password           | Recommended to use PAT                    |
| Access private repo via SSH            | SSH Public/Private Key Pair                  | Standard GitHub deploy key                |
| Mutual TLS auth for automation tools   | TLS Client Certificate (.crt) + Private Key  | Must be PEM; key must not be encrypted    |


### 🧩 Should I Add Collaborators or Use Teams?
    If your repo is part of an organization, using Teams is recommended.
    
 | Method            | Best For            | Why                                                          |
|-------------------|---------------------|--------------------------------------------------------------|
| Add Collaborators | Individuals         | Simple, direct access                                        |
| Teams             | Dev/QE/Ops groups   | Centralized control, scalable, easier to manage permissions |

## ✅ How to Give Developers / QA / Ops Teams Permissions on Branches in GitHub.

1. GitHub Teams + Repository Permissions
2. Branch Protection Rules (to restrict actions per team)

Note:- People with Admin or custom roles with “edit repository rules” can configure branch protection rules.

## 🚀 Step-by-Step Guide
### Step 1: Create Teams (Developers / QA / Ops)

    1.Go to your GitHub Organization → Teams -> Click “New team”
        |-On the Teams page, click the New team button.
        |-This starts the team creation workflow 
        Fill in Team Details:-
            ✔ Team name (required)
            ✔ Description (optional)
            ✔ Visibility
                Private (default): only visible to team members
                Visible to the org
            After filling this out, click Create team.
    2.Create three teams:
         * developers
         * qa
         * ops 
    3.Add members to each team.
      Teams allow you to assign repository permissions granularly.
  
### Step 2: Set Team Permissions at Repository Level
    To give your new team access to specific repositories:
          ✔  Go to the repository you want to assign.
          ✔ Click Settings → Manage access.
          ✔ Click Collaborators and teams.
          ✔ Click Add teams.
    Select your newly created team and choose permission level:
          ✔ Read
          ✔ Triage
          ✔ Write
          ✔ Maintain
          ✔Admin

| Team        | Recommended Permission | Why                                                |
|-------------|------------------------|-----------------------------------------------------|
| Developers  | Write                  | Can push to non-protected branches                 |
| QA          | Triage or Write        | Can review, test, and manage PRs/issues            |
| Ops         | Maintain               | Can manage workflows, releases, and deployments    |

### Step 3: Configure Branch Protection Rules
Branch Protection Rules let you control who can push, merge, or bypass rules for specific branches.
These rules are configured inside the repository settings:
Repo → Settings → Branches → Branch Protection Rules.

## A. Protect the main Branch
Create rule:
 1. Go to Repo Settings
 2. Click Branches
 3. Click Add rule
 4. Enter branch name: main
 5. Enable protection options like:
       * Require pull request reviews
       * Require status checks
       * Restrict who can push to the branch

## B. Protect release/* Branches
   1. Add rule with pattern:
        ## release/*
   2. Enable:
         * Require pull request reviews
         * Require status checks
         * Restrict pushes to Ops team only
    GitHub allows wildcard patterns like release* or qa/* using fnmatch syntax.

## C. Protect qa/* Branches
  1. Add rule:
      ## qa/*
  2. Allow only QA team to push.
    GitHub confirms patterns like qa/* match branches under QA workflow.

### Step 4: Restrict Who Can Push to a Branch
  In every branch protection rule, GitHub gives an option:
  Restrict who can push to matching branches
  This allows you to select specific users or teams who can push.

### 📘 Is “Adding Collaborators” the Same as Setting Branch Permissions?
  ❌ No, they are related but NOT the same.
  ## ✔ Adding Collaborators / Teams
      Controls repository‑level permissions:
           * Read
           * Triage
           * Write
           * Maintain
           * Admin
  ## ✔ Branch Protection Rules
      Control branch-level restrictions:
           * Who can push
           * Who can merge
           * Required reviews
           * Required CI checks

### How they work together:

| Action                          | Done In                | Purpose                                         |
|---------------------------------|-------------------------|--------------------------------------------------|
| Add collaborators or teams      | Collaborators & teams   | Gives global repository access                   |
| Set role (Write / Maintain, etc.) | Collaborators & teams | Defines what users can do in the repository      |
| Restrict push / merge           | Branch protection rules | Controls who can act on protected branches       |

## ✔ Final Summary
       * Adding collaborators is step 1 (assign repo permissions).
       * Branch protection rules are step 2 (control branch‑level rights).
       * Together, they give Developers / QA / Ops proper access control.
       * GitHub officially manages push/merge control only via branch protection.





