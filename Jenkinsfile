pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'gouthaman1220'
        IMAGE_NAME      = 'kanban-dashboard'
        APP_PORT        = '3000'
        CONTAINER_PORT  = '8080'
        BUILD_TAG       = "${BUILD_NUMBER}"
        REGISTRY_CRED   = 'dockerhub-credentials'
    }

    stages {
        stage('Checkout Source') {
            steps {
                echo "Source code successfully fetched."
            }
        }

        stage('Docker Build & Tag') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_TAG}"
                    sh """
                        docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_TAG} .
                        docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Docker Registry Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${REGISTRY_CRED}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_TAG}
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to EC2 Container') {
            steps {
                script {
                    echo "Deploying new container with resource constraints..."
                    sh """
                        # Stop and remove existing container if running
                        docker stop kanban-app || true
                        docker rm kanban-app || true

                        # Run new container with CPU and memory limits
                        docker run -d \
                            --name kanban-app \
                            -p ${APP_PORT}:${CONTAINER_PORT} \
                            --memory="512m" \
                            --cpus="0.5" \
                            ${DOCKER_HUB_USER}/${IMAGE_NAME}:${BUILD_TAG}
                    """
                }
            }
        }

        stage('Health Check & Validation') {
            steps {
                script {
                    echo "Validating deployment health..."
                    // Wait for the container internal HEALTHCHECK probe to evaluate
                    sleep time: 15, unit: 'SECONDS'
                    
                    // Verify container is marked healthy by Docker
                    sh """
                        HEALTH_STATUS=\$(docker inspect --format='{{.State.Health.Status}}' kanban-app)
                        echo "Docker health status: \$HEALTH_STATUS"
                        if [ "\$HEALTH_STATUS" != "healthy" ]; then
                            echo "Healthcheck failed!"
                            exit 1
                        fi
                        
                        # Validate HTTP response directly
                        curl -f -I http://localhost:${APP_PORT} || exit 1
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Deployment succeeded! Application is healthy at http://15.207.222.163:${APP_PORT}"
        }
        failure {
            echo "Pipeline failed. Initiating rollback to previous stable version..."
            sh """
                docker stop kanban-app || true
                docker rm kanban-app || true
                docker run -d --name kanban-app -p ${APP_PORT}:${CONTAINER_PORT} --memory="512m" --cpus="0.5" ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest || true
            """
        }
    }
}
