stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', 
                    credentialsId: 'github-credentials', 
                    url: 'https://github.com/YassineDev32/Tp_Jenkins_Docker_AWS.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    powershell '''
                        docker build -t "${env:DOCKER_IMAGE}:${env:VERSION}" .
                    '''
                }
            }
        }

        stage('Test Image') {
            steps {
                script {
                    powershell '''
                        try {
                            # Verify image exists locally
                            $imageExists = docker images -q "${env:DOCKER_IMAGE}:${env:VERSION}"
                            if (-not $imageExists) {
                                throw "Image ${env:DOCKER_IMAGE}:${env:VERSION} doesn't exist locally"
                            }

                            # Run container
                            docker run -d -p 8081:80 --name test-container "${env:DOCKER_IMAGE}:${env:VERSION}"
                            Start-Sleep -Seconds 10
                            
                            # Test application
                            $response = Invoke-WebRequest -Uri "http://localhost:8081" -UseBasicParsing -ErrorAction Stop
                            if ($response.StatusCode -ne 200) { 
                                throw "HTTP Status ${response.StatusCode}" 
                            }
                            Write-Host "Test passed successfully"
                        } catch {
                            Write-Host "Test failed: $_"
                            docker logs test-container
                            exit 1
                        } finally {
                            # Cleanup container
                            docker stop test-container -t 1 | Out-Null
                            docker rm test-container -f | Out-Null
                        }
                    '''
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
                        powershell '''
                            # Clear existing credentials
                            docker logout
                            Remove-Item -Path "$env:USERPROFILE/.docker/config.json" -Force -ErrorAction SilentlyContinue
                            
                            # Create Docker config directory if it doesn't exist
                            $dockerConfigDir = "$env:USERPROFILE/.docker"
                            if (-not (Test-Path $dockerConfigDir)) {
                                New-Item -ItemType Directory -Path $dockerConfigDir -Force | Out-Null
                            }
                            
                            # Create auth token (base64 encoded username:password)
                            $authToken = [Convert]::ToBase64String(
                                [Text.Encoding]::ASCII.GetBytes("${env:DOCKER_USER}:${env:DOCKER_PASS}")
                            )
                            
                            # Create the Docker config file without here-string issues
                            $dockerConfigContent = '{
                                "auths": {
                                    "https://index.docker.io/v1/": {
                                        "auth": "' + $authToken + '"
                                    }
                                }
                            }'
                            
                            $dockerConfigContent | Out-File -FilePath "$dockerConfigDir/config.json" -Encoding ascii
                            
                            # Verify the login works
                            docker pull hello-world
                            if ($LASTEXITCODE -ne 0) {
                                throw "Docker authentication verification failed"
                            }
                            
                            Write-Host "Successfully authenticated with Docker Hub"
                        '''
                    }
                }
            }
        }
}