pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = "krushi-kranti-test"
    }

    stages {

        stage('Checkout') {
            steps {
                // Automatically check out the code using the same Git configuration that triggered this Jenkins pipeline
                checkout scm
            }
        }

        stage('Network Setup') {
            steps {
                // Since test environments expect 'krushi-kranti-network' to exist
                sh 'docker network create krushi-kranti-network || true'
            }
        }

        stage('Inject Secrets (.env files)') {
            steps {
                // Jenkins will securely pull the test server's .env files from your configured Jenkins Secret Files
                withCredentials([
                    file(credentialsId: 'microservices-env-test', variable: 'MICROSERVICES_ENV'),
                    file(credentialsId: 'file-service-env-test', variable: 'FILE_SERVICE_ENV')
                ]) {
                    // Force copy (-f) because Jenkins Secret files are Read-Only (0400). 
                    // Without -f, the second build fails because it can't overwrite the read-only file from the first build!
                    sh 'cp -f $MICROSERVICES_ENV microservices/.env.test'
                    sh 'cp -f $FILE_SERVICE_ENV microservices/java-spring-microservices/file-service/.env.test'
                }
            }
        }

        /* 
        stage('Build Backend & SonarQube Prep') {
            steps {
                // Since SonarQube requires compiled Java code to scan, this step builds the .class files on the Jenkins server.
                
                dir('microservices') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }
        */

        stage('Deploy Backend (Test)') {
            steps {
                // Deploys the java microservices using the test compose file
                dir('microservices') {
                    sh 'docker compose --env-file .env.test -f docker-compose-test.yml up --build -d'
                }
            }
        }

        stage('Deploy Frontend (Test)') {
            steps {
                // Deploys the React frontend and Nginx using the test compose file
                sh 'docker compose -f docker-compose.frontend.test.yml up --build -d'
            }
        }

        stage('Cleanup') {
            steps {
                // Clean up old images ONLY for this specific project to protect other applications on the server
                // Deleting only images older than 3 weeks (504 hours)
                sh 'docker image prune -af --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" --filter "until=504h"'
            }
        }
    }
}