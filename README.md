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

----------------------
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
