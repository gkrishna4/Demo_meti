
```
https://docs.redhat.com/en/documentation/red_hat_satellite/6.18/
```
```
https://github.com/ansible/ansible/tree/stable-2.9/contrib/inventory
```
```
https://www.linuxtechi.com/upgrade-rhel-9-to-rhel-10-step-by-step-guide/
```
```
https://www.linuxtechi.com/top-command-monitor-linux-server/
```
```
https://www.linuxtechi.com/setup-nfs-server-on-centos-8-rhel-8/
```


GIT
-----
1) what does git rebase?

You are working on "feature-branch", but "main" has new updates. You want to update your branch with the latest main changes.
Step-by-Step Process:
---------------------
# Step 1: Switch to the feature branch
git checkout feature-branch  

# Step 2: Fetch the latest changes
git fetch origin  

# Step 3: Rebase the feature branch onto main
git rebase main  

Your commits are now on top of the latest main.


2)what is git stash command?

The git stash command takes our uncommitted changes (both staged and unstaged), saves in some temporary location.
After completing our urgent work, we can bring these stashed changes to our current working directory.

Note: 
--------
1. Stashing concept is applicable only for tracked files but not for newly created files.
2. To perform stashing, atleast one commit must be complete



3) why we can use squash command in git?

If we want to combine all commits of feature branch into a single commit and merge that commit to the master branch, 
then we should go for squash option.

git merge --squash feature


4) What is the difference between featch and pull in GIT?

featch-->> To get updated files from remote repository to local repository.from there we can update the files in to the working copy.
pull-->> insted of featch and update....if we do pull it will update changes done in remote repository  to local repository
         and also update working copy/actual copy(here we no need of featch  saparately.....pull only internally performs  featch oparation) 
         pull=featch+update

5) What is the command to revert the code from staging area to working area?

$ git checkout -- file1.txt 
It will discard any unstaged changes made in file1.txt.
 After executing this command, staged copy content and working directory content is same.


6)what is Branch?

A Branch is nothing but an independent flow of development and by using branching concept, we can create multiple work flows.

master branch is the default branch/ main branch in git. Generally main source code will be placed in master branch.
Based on our requirement, we can create any number of branches.



Jenkins
--------
7) How Many ways you can trigger the Build?
in Jenkins we can trigger the Build in 3 ways by using 
pollSCM
Build Periodically
Webhooks

8)what is continuous intigration
==============================
Let's say we have multiple devlopers working on the same application, each of them have their own feature (or) bug-fix that they are 
working-on and they all are contributing the same application, by pushing their code into the same code repository like GitHub. when the 
devloper pushes the code to the repository it will link to a build mangement system like jenkins, that takes the code and build's it, 
so here multiple devlopers pushing their code to the same application, we would like to make shore it build currectly & it will not 
intraduce new issues into the application for this we can configure the build system to run testcases on  build package. once the 
testcase's pass successfull, we can conform that the build cycle complete this whole process we call it as continuous integration

9)how to maintain the end to end software devlopment and what are the tools using there?
=======================================================================================
when ever devloper commited the feature branch, performing few stages like cloning, compileing 
and then performing the unit testing and sonarQube analasis and all, so once these stages are completed 
then the notification will get the devloper, if the changes are good and we can mearge the changes into the
dev environment, by creating the PR(pull request). but here we have a the break down its not continuous becouse some manual
approvals are required before moving to the UAT Pre-prod

10)What is shared library?
=======================
In Jenkins, a shared library is a way to store commonly used code(reusable code), such as scripts or functions, that can be used by different Jenkins pipelines.
Instead of writing the same code again and again in multiple pipelines, you can create a shared library and use it in all the pipelines that need it. 
This can make your code more organized and easier to maintain.

11)Difference between Continuous Delivery & Continuous Deployment
================================================================
Continuous Delivery:-   A process where code changes are automatically built, tested, and prepared for release (The code is always ready to be deployed, but the actual deployment to production is done manually. so here the code is always in a deployable state and reduces the risk of issues.)

Continuous Deployment- 	A process where code changes are automatically built, tested, and deployed to production.( Every change that passes the tests is automatically deployed to production without any manual steps.Speeds up the delivery of new features and fixes to users)

12) can you write the Jenkins pipeline syntax?
pipeline{
	agent any
	parameters{
		choice();
		string();
		Boolean();
	}
	environment{
		//maven
		//SonarQube
		//Docker
		//k8s
	}
	trigger{
		polescm();
	       }
	stages{
		stage("checkout the code")
		{
		  steps{
			script{
				checkout SCM
			     }
			}

		}
		stage{"Build & Test"}
		{
		  parallel{
			  stage("maven build")
			  {
			    script{
				echo "Building"
			    	sh "mvn clean install"
			    }	
			  }
			 stage("Test")
			 {
			   script{
				echo "Build testing"
				 }
			 }
			  }
		}
		
	}
}

13)Here i have 3 branches like dev,feature and release branches and have two test senarios like smoke and unit so for dev and frature branch unit test will run and comming to the relase branch this smoke test will run How?

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


14How to add a new worker node in Jenkins ?
=========================================
 Log into the Jenkins master and navigate to Manage Jenkins > Manage Nodes > New Node. Enter a name for the new node and select Permanent Agent.
Configure SSH and click on Launch.

15)what is Docker?
--------------

Docker implements a high-level API to provide lightweight containers that run processes in isolation.
A Docker container enables rapid deployment with minimum run-time requirements. It also ensures better
management and simplified portability.

16)What is the difference between CMD & RUN?
---------------------------------------
Run instructions will be execute while creating a image.CMD instructions will be executed while 
Creating a container. we can have more than one RUN keyword in a docker-file. All RUN keyword’s
Will be processed while creating an image in the defind order (Top to Bottom).

17)What is the difference between CMD & ENTRYPOINT?
-------------------------------------------------
CMD commands/instructions can be overridden while creating a container. 
ENTRYPOINT commands/instructions cannot be overridden while creating a container.

18)Diff b/w USER & useradd in Docker file?
-----------------------------------------
useradd command and the USER instruction in a Docker file serve different purposes related to user management 
1. useradd Command:- creates the new user in the containers filesystem
2. USER instruction:-USER switches to that user for execution 

19)What is Docker Daemon?
-----------------------
The Docker daemon listens for Docker API requests and manages Docker objects such as images, containers, networks, and volumes. A daemon can also communicate with other daemons to manage Docker services


20)can you explain the Life cycle of Docker ?
-------------------------------------------
docker build -> builds docker images from Docker file
docker run -> runs container from docker images
docker push -> push the container image to public/private regestries to share the docker


21)How to write a script to delete messages in a log file older than 30 days automatically?
-------------------------------------------------------------------------------------------
find <Path_To_Old_Files> -type f -mtime +30 -delete

22)how do we check the open port in linux?
------------------------------------------

1) netstat -ltnp | grep -w :<port number>
2) lsof -i :<port number>

23)List any 3 type of filesystem?
------------------------------
For Linux: ext3, ext4 and xfs
For Windows: NTFS and FAT

24)What are the different fields in /etc/passwd file?
---------------------------------------------------
1) User name
2) Encrypted password
3) User ID number (UID)
4) User's group ID number (GID)
5) Full name of the user (GECOS)
6) User home directory
7) Login shell

25) what is an Idempotency in Ansible?
--------------------------------------  
Configuration management tools are used to bring the server to a particular state, called as desired state. If a server 
already in the desired state, configuration management tools will not reconfigure that server. 


26) what is an ansible Vault?
==============================
Ansible Vault is for security , if we have  any confidential information  in that playbook we can restrict the people to
 accessing by using the command called Ansible Vault  
if our-requirement is to ----->restrict people from executing/seeing the playbook by making use of command  called 
Ansible Vault  
