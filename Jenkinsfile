pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'xanas0/tp_aws'
        VERSION = "${env.BUILD_NUMBER ?: 'latest'}"
        REVIEW_ADRESS_IP = "98.81.203.203"
        AWS_SSH_KEY = credentials('ezziyati-cle.pem')
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
                        docker build -t ${DOCKER_IMAGE}:${VERSION} .
                    """
                }
            }
        }

        stage('Test Image') {
            steps {
                script {
                    powershell """
                        try {
                            \$imageExists = docker images -q "${DOCKER_IMAGE}:${VERSION}"
                            if (-not \$imageExists) {
                                throw "Image ${DOCKER_IMAGE}:${VERSION} doesn't exist locally"
                            }

                            docker run -d -p 8081:80 --name test-container "${DOCKER_IMAGE}:${VERSION}"
                            Start-Sleep -Seconds 10

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
                            docker stop test-container -t 1 | Out-Null
                            docker rm test-container -f | Out-Null
                        }
                    """
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    script {
                        powershell """
                            docker logout
                            docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"
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
                        docker push "${DOCKER_IMAGE}:${VERSION}"
                    """
                }
            }
        }

        stage('Deploy to Review') {
            steps {
                withCredentials([file(credentialsId: 'aws-key.pem', variable: 'SSH_KEY')]) {
                    script {
                        powershell """
                            \$tempKey = "\$env:TEMP\\aws-key-\$env:BUILD_NUMBER.pem"

                            # Save key with correct line endings
                            [System.IO.File]::WriteAllText(
                                \$tempKey,
                                [System.IO.File]::ReadAllText("\$env:SSH_KEY").Replace("`r`n","`n"),
                                [System.Text.Encoding]::ASCII
                            )

                            icacls \$tempKey /inheritance:r
                            icacls \$tempKey /grant:r "\$env:USERNAME:(R)"
                            icacls \$tempKey /grant:r "SYSTEM:(R)"
                            
                            \$sshCommand = "docker pull ${DOCKER_IMAGE}:${VERSION} && " +
                                           "docker stop review-app || true && " +
                                           "docker rm review-app || true && " +
                                           "docker run -d -p 80:80 --name review-app ${DOCKER_IMAGE}:${VERSION}"

                            \$process = Start-Process -FilePath "ssh" `
                                -ArgumentList @(
                                    "-i", "\$tempKey",
                                    "-o", "StrictHostKeyChecking=no",
                                    "ubuntu@${REVIEW_ADRESS_IP}",
                                    \$sshCommand
                                ) `
                                -NoNewWindow `
                                -PassThru `
                                -Wait

                            if (\$process.ExitCode -ne 0) {
                                throw "SSH command failed with exit code \$($process.ExitCode)"
                            }

                            Remove-Item "\$tempKey" -Force -ErrorAction SilentlyContinue
                        """
                    }
                }
            }
        }
    }

    post {
        cleanup {
            powershell """
                docker rmi "${DOCKER_IMAGE}:${VERSION}" -f | Out-Null
            """
        }
    }
}
