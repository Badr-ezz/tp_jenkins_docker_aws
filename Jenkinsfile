pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'xanas0/tp_aws'
        VERSION = "${env.BUILD_NUMBER ?: 'latest'}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', 
                    credentialsId: 'github-credentials', 
                    url: 'https://github.com/Badr-ezz/tp_jenkins_docker_aws.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    powershell """
                        docker build -t "${env:DOCKER_IMAGE}:${env:VERSION}" .
                    """
                }
            }
        }

        stage('Test Image') {
            steps {
                script {
                    powershell """
                        try {
                            # Verify image exists locally
                            \$imageExists = docker images -q "${env:DOCKER_IMAGE}:${env:VERSION}"
                            if (-not \$imageExists) {
                                throw "Image ${env:DOCKER_IMAGE}:${env:VERSION} doesn't exist locally"
                            }

                            # Run container
                            docker run -d -p 8081:80 --name test-container "${env:DOCKER_IMAGE}:${env:VERSION}"
                            Start-Sleep -Seconds 10

                            # Test application
                            \$response = Invoke-WebRequest -Uri "http://localhost:8081" -UseBasicParsing -ErrorAction Stop
                            if (\$response.StatusCode -ne 200) { 
                                throw "HTTP Status \$response.StatusCode" 
                            }
                            Write-Host "Test passed successfully"
                        } catch {
                            Write-Host "Test failed: \$_"
                            docker logs test-container
                            exit 1
                        } finally {
                            # Cleanup container
                            docker stop test-container -t 1 | Out-Null
                            docker rm test-container -f | Out-Null
                        }
                    """
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-hub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        powershell """
                            docker logout
                            docker login -u "${env:DOCKER_USER}" -p "${env:DOCKER_PASS}"

                            if (\$LASTEXITCODE -ne 0) {
                                throw "Docker authentication failed"
                            }

                            Write-Host "Successfully authenticated with Docker Hub"
                        """
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    powershell """
                        docker push "${env:DOCKER_IMAGE}:${env:VERSION}"
                    """
                }
            }
        }
    }

    post {
        cleanup {
            powershell """
                docker rmi "${env:DOCKER_IMAGE}:${env:VERSION}" -f | Out-Null
            """
        }
    }
}
