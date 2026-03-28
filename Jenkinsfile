pipeline {
    agent any
    environment {
        COMPOSE_PROJECT_NAME = "krushi-kranti-test"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Pre-Cleanup') {
            steps {
                dir('microservices') {
                    sh '''
                    docker compose -p $COMPOSE_PROJECT_NAME -f docker-compose-test.yml down --remove-orphans || true
                    '''
                }
            }
        }
        stage('Network Setup') {
            steps {
                sh 'docker network create krushi-kranti-network || true'
            }
        }
        stage('Inject Secrets (.env files)') {
            steps {
                withCredentials([
                    file(credentialsId: 'microservices-env-test', variable: 'MICROSERVICES_ENV'),
                    file(credentialsId: 'file-service-env-test', variable: 'FILE_SERVICE_ENV')
                ]) {
                    sh 'cp -f $MICROSERVICES_ENV microservices/.env.test'
                    sh 'cp -f $FILE_SERVICE_ENV microservices/java-spring-microservices/file-service/.env.test'
                }
            }
        }
        stage('Deploy Backend (Test)') {
            steps {
                dir('microservices') {
                    sh 'docker compose --env-file .env.test -f docker-compose-test.yml up --build -d redis zookeeper kafka auth-service'
                    sh 'sleep 40'
                    sh 'docker compose --env-file .env.test -f docker-compose-test.yml up --build -d farmer-service file-service'
                    sh 'sleep 40' 
                    sh 'docker compose --env-file .env.test -f docker-compose-test.yml up --build -d'
                }
            }
        }
        stage('Deploy Frontend (Test)') {
            steps {
                sh 'docker compose -f docker-compose.frontend.test.yml up --build -d'
            }
        }
        stage('Cleanup') {
            steps {
                sh 'docker image prune -af --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" --filter "until=504h"'
            }
        }
    }
}