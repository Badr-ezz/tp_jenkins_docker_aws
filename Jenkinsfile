pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'xanas0/tp_aws'
        VERSION = "${env.BUILD_NUMBER ?: 'latest'}"
        REVIEW_ADRESS_IP = "98.81.203.203"
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
                withCredentials([file(credentialsId: 'ezziyati-cle.pem', variable: 'SSH_KEY')]) {
                    script {
                        // 1. Prepare the key file with proper permissions
                        powershell '''
                            $tempKey = "$env:TEMP\\aws-key-$env:BUILD_NUMBER.pem"
                            
                            # Copy key content with Unix line endings
                            [System.IO.File]::WriteAllText(
                                $tempKey,
                                [System.IO.File]::ReadAllText($env:SSH_KEY).Replace("`r`n","`n"),
                                [System.Text.Encoding]::ASCII
                            )
                            
                            # Set strict permissions
                            icacls $tempKey /inheritance:r
                            icacls $tempKey /grant:r "$env:USERNAME:(R)"
                            icacls $tempKey /grant:r "SYSTEM:(R)"
                        '''
                        
                        // 2. Execute deployment commands with proper waiting
                        powershell '''
                            $sshCommand = "docker pull ${env:DOCKER_IMAGE}:${env:VERSION} && " +
                                          "docker stop review-app || true && " +
                                          "docker rm review-app || true && " +
                                          "docker run -d -p 80:80 --name review-app ${env:DOCKER_IMAGE}:${env:VERSION}"
                            
                            $process = Start-Process -FilePath "ssh" `
                                -ArgumentList @(
                                    "-i", "$env:TEMP\\aws-key-$env:BUILD_NUMBER.pem",
                                    "-o", "StrictHostKeyChecking=no",
                                    "ubuntu@${env:REVIEW_IP}",
                                    $sshCommand
                                ) `
                                -NoNewWindow `
                                -PassThru `
                                -Wait
                            
                            if ($process.ExitCode -ne 0) {
                                throw "SSH command failed with exit code $($process.ExitCode)"
                            }
                        '''
                        
                        // 3. Clean up
                        powershell '''
                            Remove-Item "$env:TEMP\\aws-key-$env:BUILD_NUMBER.pem" -Force -ErrorAction SilentlyContinue
                        '''
                    }
                }
            }
        }
    }    
}
