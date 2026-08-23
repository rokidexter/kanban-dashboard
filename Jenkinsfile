pipeline {
    agent any

    environment {
        IMAGE_NAME = "kanban-dashboard"
        AWS_REGION = "ap-south-1"
        ECR_REGISTRY = "382170164329.dkr.ecr.ap-south-1.amazonaws.com"
        ECR_REPOSITORY = "kanban-dashboard"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:jenkins-build .
                '''
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Docker Tag') {
            steps {
                sh '''
                    docker tag \
                    ${IMAGE_NAME}:jenkins-build \
                    ${ECR_REGISTRY}/${ECR_REPOSITORY}:jenkins-build
                '''
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    docker push \
                    ${ECR_REGISTRY}/${ECR_REPOSITORY}:jenkins-build
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'CI/CD pipeline failed.'
        }
    }
}