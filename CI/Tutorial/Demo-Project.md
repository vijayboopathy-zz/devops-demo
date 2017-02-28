# Docker compose file  
```
version: '2'
services:
  jenkins:
    image: jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - /docker/jenkins_home:/var/jenkins_home
    container_name: compose-jenkins

  artifactory:
    image: docker.bintray.io/jfrog/artifactory-oss
    ports:
      - "8081:8081"
    volumes:
      - /artifactory/data:/var/opt/jfrog/artifactory/data
      - /artifactory/logs:/var/opt/jfrog/artifactory/logs
      - /artifactory/etc:/var/opt/jfrog/artifactory/etc
    container_name: compose-artifactory-oss

  sonarqube:
    image: sonarqube
    ports:
      - "9000:9000"
      - "9092:9092"
    container_name: compose-sonarqube

  tomcat:
    image: tomcat
    ports:
      - "8888:8080"
    volumes:
        - /docker/tomcat/usr/local/tomcat/conf/tomcat-users.xml:/usr/local/tomcat/conf/tomcat-users.xml
    container_name: compose-tomcat
```  

# Manual Configuration
## Jenkins-Docker  
### Command  
```
docker run -d -v /docker/jenkins_home:/var/jenkins_home -p 8081:8080 -p 50000:50000 --name jenkins jenkins:latest
```  
### Conditions  
  * Port 8080 was already allocated on the host machine.  
  * User: admin  
  * Pass: 1nitCr0n  
  * Study : Maven in 5 mins  

## Artifactory-Docker
### Command  
```
docker run -d --name artifactory -p 8082:8081 -v $ARTIFACTORY_HOME/data:/var/opt/jfrog/artifactory/data -v $ARTIFACTORY_HOME/logs:/var/opt/jfrog/artifactory/logs -v $ARTIFACTORY_HOME/etc:/var/opt/jfrog/artifactory/etc docker.bintray.io/jfrog/artifactory-oss:latest
```  
### Conditions
  * Create home dir mount for artifactory : mkdir /docker/artifactory/  
  * Change permissions: chmod 777 /docker/artifactory/  
  * Set Environment variable: export ARTIFACTORY_HOME=/docker/artifactory/  
  * Check the variable: echo $ARTIFACTORY_HOME  
  * Visit: IP:8082  
  * User: admin  
  * Password: password  

## Sonarqube-Docker  
### Command  
```
docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube:latest
```  
### Conditions  
  * Visit: IP:9000  
  * User: admin  
  * Pass: admin  
  * Token: c47d72f6362bd31a1f48a88b48920467d3f39e78  
  * Install Sonarqube Scanner in jenkins  from Global Tool Configuration  

## Tomcat-Docker  
### Command  
```
docker run -d --name tomcat -v /docker/tomcat/usr/local/tomcat/conf/tomcat-users.xml:/usr/local/tomcat/conf/tomcat-users.xml -p 8083:8080 tomcat:latest
```  

# Jenkins-Project Configuration  
## BUILD
  * Project: Maven project  
  * SCM: Git  
  * Build Trigger: Poll SCM ( H/2 * * * * )
  * Build Environment:  
    * Enable Artifactory release management  
    * Resolve artifacts from Artifactory(libs-release, libs-snapshot)  
  * Build:  
    * Root: pom.xml  
    * Goal: install  
  * Post Build:
    * Deploy artifacts to artifactory(libs-release-local, libs-snapshot-local)
      * Deploy maven artifacts  
      * Filter excluded artifacts from build info  
      * Capture and publish build info  
      * Include environment variables  

## TEST:  
  * Project: Freestyle  
  * SCM: Git  
  * Build Trigger: Poll SCM ( H/2 * * * * )  
  * Build:  
    * Invoke artifactory maven3  
      * Root: pom.xml  
      * Goal: test  
    * Execute Sonar Scanner:  
      * Analysis Properties:  
        * sonar.projectKey=CMADsession  
        * sonar.projectName=CMAD  
        * sonar.projectVersion=1.0  
        * sonar.sources=/var/jenkins_home/workspace/Test/src  

## Package:
  * Project: Maven  
  * SCM: Git  
  * Build Trigger: Poll SCM ( H/2 * * * * )  
  * Build Environment:  
    * Enable Artifactory release management:  
      * Default module version configuration: One version for all modules  
      * Use release branch : Check  
    * Resolve artifacts from Artifactory  
      * Artifactory server: IP:/artifactory  
      * Resolution releases repository: libs-release  
      * Resolution snapshots repository: libs-snapshot  
  * Build:  
    * Root POM: pom.xml  
    * Goals and options: package  
  * Post-build Actions:  
    * Deploy artifacts to Artifactory  
      * Artifactory server: IP:/artifactory  
      * Target releases repository: libs-release-local  
      * Target snapshot repository: libs-snapshot-local  
      * Deploy maven artifacts: Check  
      * Filter excluded artifacts from build Info: Check  
      * Capture and publish build info: Check  
      * Include environment variables: Check  
    * Deploy war/ear to container  
      * WAR/EAR files: target/*.war  
      * Context path: CMADSession  
      * Containers: Tomcat 7.x
        * Manager user name: admin  
        * Manager password: s3cret  
        * Tomcat URL: http://192.168.0.59:8888

## Image
  * Publish over ssh
    * Define details in Configure System
    * Put private key in Publish over SSH
  * In Image job - Build steps
    * Select SSH server
    * work dir: /home/ubuntu
    * exec command: sudo bash image.sh

In manager node install 'expect'
  apt install expect
image script (image.sh)
  ```
  #!/bin/bash
  cd /docker/jenkins_home/
  docker build -t tomcatapp .
  #Username and Password for local docker registry
  USER="admin"
  PASS="1nitCr0n"
  #Start of expect script
  expect <<EOF
  spawn docker login https://initcronregistry.org
  #Turn logging off
  log_user 0
  expect "Username:"
  send "$USER\r"
  expect "Password:"
  send "$PASS\r"
  #Tag the custom image
  spawn docker tag tomcatapp initcronregistry.org/tomcatapp
  #Push the image
  spawn docker push initcronregistry.org/tomcatapp
  #Turn logging on
  log_user 1
  expect eof
  EOF
  ```


# Custom Tomcat Image  
  * PWD: /docker/  
  * Dockerfile:  
```
FROM tomcat:latest
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME
ADD workspace/Deploy/CMADSession.war /usr/local/tomcat/webapps/
EXPOSE 8080
CMD ["catalina.sh", "run"]  
```  

# Docker Registry
  * Credentials:
    * User: admin  
    * Password: 1nitCr0n  
  * Followed Digital Ocean's guide (https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-ubuntu-14-04)  
  * Regisry Steps:
    * Add registry host:
    ```
    vi /etc/hosts
    #Add the following line
    192.168.0.68  initcronregistry.org  
    ```  
    * From swarm manager:  
      * Connect to registry and log in (refer link)  
      * Tag the image with registry name  
      * Push the image  
    * In Worker nodes:  
      * Same steps as manager  
      * Log in to the registry  
      * Pull the image using the correct tag  

# Docker Swarm:  
  * Create Swarm:  
  ```
  docker swarm init --advertise-addr 192.168.0.57
  ```  
  * SSH into other worker nodes  
  * Run the output command of docker swarm init  
  * Check the nodes in manages node  
  * List nodes:
  ```
  Docker node ls
  ```  
  * Create tomcat service:  
  ```
  docker service create --replicas 6 --publish 8080:8080 --name tomapp initcronregistry.org/tomcatapp
  ```
# C Advisor in Swarm worker nodes
```
sudo docker run   --volume=/:/rootfs:ro   --volume=/var/run:/var/run:rw   --volume=/sys:/sys:ro   --volume=/var/lib/d ocker/:/var/lib/docker:ro   --publish=9090:8080   --detach=true   --name=cadvisor google/cadvisor:latest

```
