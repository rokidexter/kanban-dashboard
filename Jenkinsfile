pipeline {
    agent any

    environment {
        IMAGE_NAME = "kanban-dashboard"
        AWS_REGION = "ap-south-1"
        ECR_REGISTRY = "382170164329.dkr.ecr.ap-south-1.amazonaws.com"
        ECR_REPOSITORY = "kanban-dashboard"
        CONTAINER_NAME = "kanban-dashboard-ecr"
        HOST_PORT = "80"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Set Image Tag') {
            steps {
                script {
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${env.GIT_SHA}-${env.BUILD_NUMBER}"

                    echo "Git SHA: ${env.GIT_SHA}"
                    echo "Build Number: ${env.BUILD_NUMBER}"
                    echo "Image Tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Save Current Version') {
            steps {
                script {
                    env.PREVIOUS_IMAGE = sh(
                        script: """
                            docker inspect ${CONTAINER_NAME} \
                            --format='{{.Config.Image}}' 2>/dev/null || true
                        """,
                        returnStdout: true
                    ).trim()

                    if (env.PREVIOUS_IMAGE) {
                        echo "Previous image: ${env.PREVIOUS_IMAGE}"
                    } else {
                        echo "No previous deployment found."
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password \
                        --region ${AWS_REGION} | \
                    docker login \
                        --username AWS \
                        --password-stdin ${ECR_REGISTRY}
                '''
            }
        }

        stage('Docker Tag') {
            steps {
                sh '''
                    docker tag \
                        ${IMAGE_NAME}:${IMAGE_TAG} \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                '''
            }
        }

        stage('Docker Push') {
            steps {
                sh '''
                    docker push \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                    echo "Deploying ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"

                    docker pull \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}

                    docker rm -f ${CONTAINER_NAME} || true

                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p ${HOST_PORT}:80 \
                        --restart unless-stopped \
                        ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for container health..."

                    for i in $(seq 1 12); do

                        STATUS=$(docker inspect \
                            --format='{{.State.Health.Status}}' \
                            ${CONTAINER_NAME} 2>/dev/null || true)

                        echo "Health status: ${STATUS}"

                        if [ "${STATUS}" = "healthy" ]; then
                            echo "Container is healthy."
                            exit 0
                        fi

                        sleep 5
                    done

                    echo "Container failed health check."
                    exit 1
                '''
            }
        }

        stage('Application Check') {
            steps {
                sh '''
                    echo "Checking application..."

                    curl --fail --max-time 10 \
                        http://localhost/

                    echo "Application is responding successfully."
                '''
            }
        }
    }

    post {

        success {
            echo "CI/CD pipeline completed successfully."
            echo "Deployed image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }

        failure {
            echo "Deployment failed. Starting rollback..."

            script {
                if (env.PREVIOUS_IMAGE?.trim()) {

                    sh """
                        echo "Rolling back to: ${env.PREVIOUS_IMAGE}"

                        docker rm -f ${CONTAINER_NAME} || true

                        docker run -d \
                            --name ${CONTAINER_NAME} \
                            -p ${HOST_PORT}:80 \
                            --restart unless-stopped \
                            ${env.PREVIOUS_IMAGE}

                        sleep 10

                        docker inspect \
                            --format='Rollback health: {{.State.Health.Status}}' \
                            ${CONTAINER_NAME} || true

                        curl --fail --max-time 10 \
                            http://localhost/

                        echo "Rollback completed successfully."
                    """

                } else {
                    echo "No previous image available. Rollback skipped."
                }
            }

            echo "CI/CD pipeline failed."
        }
    }
}