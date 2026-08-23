pipeline {
    agent any

    environment {
        IMAGE_NAME = "kanban-dashboard"
        AWS_REGION = "ap-south-1"
        ECR_REGISTRY = "382170164329.dkr.ecr.ap-south-1.amazonaws.com"
        ECR_REPOSITORY = "kanban-dashboard"
        CONTAINER_NAME = "kanban-dashboard-ecr"
        CONTAINER_PORT = "80"
    }

    stages {

        stage('Set Image Tag') {
            steps {
                script {
                    def gitSha = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${gitSha}-${BUILD_NUMBER}"

                    echo "Git SHA: ${gitSha}"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Image Tag: ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Save Current Version') {
            steps {
                script {
                    def previousImage = sh(
                        script: """
                            docker inspect ${CONTAINER_NAME} \
                            --format='{{.Config.Image}}' 2>/dev/null || true
                        """,
                        returnStdout: true
                    ).trim()

                    env.PREVIOUS_IMAGE = previousImage

                    if (previousImage) {
                        echo "Previous image: ${previousImage}"
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

                    echo "Stopping current container..."

                    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                    echo "Starting new container..."

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${CONTAINER_PORT}:80 \
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
                            ${CONTAINER_NAME} 2>/dev/null || echo "starting")

                        echo "Health status: ${STATUS}"

                        if [ "${STATUS}" = "healthy" ]; then
                            echo "Container is healthy."
                            exit 0
                        fi

                        if [ "${STATUS}" = "unhealthy" ]; then
                            echo "Container is unhealthy."
                            exit 1
                        fi

                        sleep 5
                    done

                    echo "Health check timed out."
                    exit 1
                '''
            }
        }

        stage('Application Check') {
            steps {
                sh '''
                    echo "Checking application..."

                    curl --fail --max-time 10 http://localhost/

                    echo "Application is responding successfully."
                '''
            }
        }
    }

    post {

        success {
            echo "=========================================="
            echo "CI/CD PIPELINE COMPLETED SUCCESSFULLY"
            echo "=========================================="
            echo "Deployed image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
        }

        failure {
            echo "=========================================="
            echo "CI/CD PIPELINE FAILED"
            echo "=========================================="

            script {

                if (env.PREVIOUS_IMAGE?.trim()) {

                    echo "=========================================="
                    echo "STARTING AUTOMATIC ROLLBACK"
                    echo "=========================================="

                    echo "Failed image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                    echo "Previous image: ${env.PREVIOUS_IMAGE}"

                    sh """
                        set -e

                        echo "Stopping failed deployment..."

                        docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

                        echo "Pulling previous image..."

                        docker pull ${env.PREVIOUS_IMAGE}

                        echo "Starting previous version..."

                        docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p ${CONTAINER_PORT}:80 \
                        --restart unless-stopped \
                        ${env.PREVIOUS_IMAGE}

                        echo "Waiting for rollback container to become healthy..."

                        ROLLBACK_SUCCESS=false

                        for i in \$(seq 1 12); do

                            STATUS=\$(docker inspect \
                                --format='{{.State.Health.Status}}' \
                                ${CONTAINER_NAME} 2>/dev/null || echo "starting")

                            echo "Rollback health status: \${STATUS}"

                            if [ "\${STATUS}" = "healthy" ]; then
                                echo "Rollback container is healthy."
                                ROLLBACK_SUCCESS=true
                                break
                            fi

                            if [ "\${STATUS}" = "unhealthy" ]; then
                                echo "Rollback container is unhealthy."
                                break
                            fi

                            sleep 5
                        done

                        if [ "\${ROLLBACK_SUCCESS}" != "true" ]; then
                            echo "Rollback health check failed."
                            exit 1
                        fi

                        echo "Verifying application after rollback..."

                        curl --fail --max-time 10 http://localhost/

                        echo "Application is responding after rollback."

                        echo "Verifying restored image..."

                        CURRENT_IMAGE=\$(docker inspect \
                            ${CONTAINER_NAME} \
                            --format='{{.Config.Image}}')

                        echo "Current running image: \${CURRENT_IMAGE}"
                        echo "Expected image: ${env.PREVIOUS_IMAGE}"

                        if [ "\${CURRENT_IMAGE}" != "${env.PREVIOUS_IMAGE}" ]; then
                            echo "ERROR: Rollback image verification failed."
                            exit 1
                        fi

                        echo "=========================================="
                        echo "ROLLBACK COMPLETED SUCCESSFULLY"
                        echo "=========================================="

                        echo "Restored image: \${CURRENT_IMAGE}"
                    """

                } else {

                    echo "No previous image available."
                    echo "Rollback skipped."

                }
            }
        }
    }
}