pipeline {
    agent any
    
    parameters {
        string(name: 'MAJOR_VERSION', defaultValue: '1', description: 'Major version for the Docker image tag (e.g., 1 for v1.x)')
    }
    
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    
    environment {
        SCANNER_HOME = tool 'sonarqube-scanner'
        TRIVY_HOME = '/usr/bin'
        REPO_URL = 'https://github.com/hlaingminpaing/youtube-clone-CICD.git' 
        REPO_BRANCH = 'main'
        DOCKER_IMAGE_NAME = 'hlaingminpaing/youtube-clone'
        SONAR_PROJECT_NAME = 'youtube-cicd'
        SONAR_PROJECT_KEY = 'youtube-cicd'
        DOCKER_CREDENTIALS_ID = 'dockerhub'
        SONAR_CREDENTIALS_ID = 'SonarQube-Token'
        KUBERNETES_CREDENTIALS_ID = 'kubernetes'
        SONAR_SERVER = 'SonarQube-Server'
        DOCKER_TOOL_NAME = 'docker'
        TRIVY_FS_REPORT = 'trivyfs.txt'
        TRIVY_IMAGE_REPORT = 'trivyimage.txt'
        K8S_NAMESPACE = 'default'  
        APP_NAME = 'youtube-clone'
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
            post {
                always {
                    echo "Workspace cleaned successfully"
                }
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: "${REPO_BRANCH}", url: "${REPO_URL}", credentialsId: 'github-credentials'
            }
        }
        stage('Sonarqube Analysis') {
            steps {
                withSonarQubeEnv(credentialsId: "${SONAR_CREDENTIALS_ID}", installationName: "${SONAR_SERVER}") {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=${SONAR_PROJECT_NAME} \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY}
                    """
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: "${SONAR_CREDENTIALS_ID}"
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                script {
                    def nodeHome = tool name: 'node16', type: 'nodejs'
                    env.PATH = "${nodeHome}/bin:${env.PATH}"
                    sh "node --version"
                    sh "npm --version"
                    sh "npm install"
                }
            }
            post {
                failure {
                    echo "Failed to install dependencies. Check Node.js setup or package.json."
                }
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                script {
                    sh "${TRIVY_HOME}/trivy fs . > ${TRIVY_FS_REPORT}"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${TRIVY_FS_REPORT}", allowEmptyArchive: true
                }
            }
        }
        stage('Set Version') {
            steps {
                script {
                    def buildNumber = env.BUILD_NUMBER ?: '0'
                    env.IMAGE_TAG = "v${params.MAJOR_VERSION}.${buildNumber}"
                    echo "Docker image will be tagged as: ${DOCKER_IMAGE_NAME}:${env.IMAGE_TAG}"
                }
            }
        }
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'docker') {
                        // Build the Docker image
                        sh "docker build -t youtube-clone ."
                        // Tag the image with the dynamically fetched version
                        sh "docker tag youtube-clone hlaingminpaing/youtube-clone:${env.IMAGE_TAG}"
                        // Push the tagged image
                        sh "docker push hlaingminpaing/youtube-clone:${env.IMAGE_TAG}"
                    }
                }
            }
            post {
                always {
                    // Clean up Docker images to save disk space
                    sh "docker rmi youtube-clone hlaingminpaing/youtube-clone:${env.IMAGE_TAG} || true"
                }
            }
        }
        
        stage('TRIVY') {
            steps {
                script {
                    sh "${TRIVY_HOME}/trivy image ${DOCKER_IMAGE_NAME}:${env.IMAGE_TAG} > ${TRIVY_IMAGE_REPORT}"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "${TRIVY_IMAGE_REPORT}", allowEmptyArchive: true
                }
            }
        }

        // stage('Deploy to Kubernets'){
        //      steps{
        //          script{
        //              dir('Kubernetes') {
        //                  kubeconfig(credentialsId: "${KUBERNETES_CREDENTIALS_ID}", serverUrl: '') {
        //                  sh 'kubectl delete --all pods'
        //                  sh 'kubectl apply -f deployment.yml'
        //                  sh 'kubectl apply -f service.yml'
        //                  }   
        //              }
        //          }
        //      }
        //  }

        // stage('Deploy to Kubernetes') {
        //     steps {
        //         script {
        //             dir('Kubernetes') {
        //                 // Update the image tag in deployment.yml
        //                 sh "sed -i 's|image: hlaingminpaing/youtube-clone:.*|image: hlaingminpaing/youtube-clone:${env.IMAGE_TAG}|' deployment.yml"

        //                 withKubeCredentials([
        //                     [ credentialsId: 'jenkins-k8s-token', serverUrl: 'https://<your-eks-api-server-url>' ]
        //                 ]) {
        //                     sh "kubectl apply -f deployment.yml -n ${K8S_NAMESPACE}"
        //                     sh "kubectl apply -f service.yml -n ${K8S_NAMESPACE}"
        //                     sh "kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE} --timeout=5m"
        //                 }
        //             }
        //         }
        //     }
        //     post {
        //         success {
        //             echo "Successfully deployed ${APP_NAME} to Kubernetes in namespace ${K8S_NAMESPACE}"
        //         }
        //         failure {
        //             echo "Failed to deploy ${APP_NAME} to Kubernetes in namespace ${K8S_NAMESPACE}"
        //             sh "kubectl rollout undo deployment/${APP_NAME} -n ${K8S_NAMESPACE} || true"
        //         }
        //     }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    dir('Kubernetes') {
                        sh "sed -i.bak 's|image: hlaingminpaing/youtube-clone:.*|image: hlaingminpaing/youtube-clone:${env.IMAGE_TAG}|' deployment.yml && rm deployment.yml.bak"

                        withCredentials([
                            string(credentialsId: 'k8s-server-url', variable: 'K8S_SERVER_URL'),
                            string(credentialsId: 'jenkins-k8s-token', variable: 'K8S_TOKEN')
                        ]) {
                            sh """
                            cat > kubeconfig <<EOF
                            apiVersion: v1
                            clusters:
                            - cluster:
                                server: ${K8S_SERVER_URL}
                              name: eks-cluster
                            contexts:
                            - context:
                                cluster: eks-cluster
                                user: jenkins
                                namespace: ${K8S_NAMESPACE}
                              name: eks-context
                            current-context: eks-context
                            kind: Config
                            preferences: {}
                            users:
                            - name: jenkins
                              user:
                                token: ${K8S_TOKEN}
                            EOF
                            """

                            withEnv(["KUBECONFIG=${WORKSPACE}/Kubernetes/kubeconfig"]) {
                                sh "kubectl apply -f deployment.yml -n ${K8S_NAMESPACE}"
                                sh "kubectl apply -f service.yml -n ${K8S_NAMESPACE}"
                                sh "kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE} --timeout=5m"
                            }

                            sh "rm kubeconfig"
                        }
                    }
                }
            }
            post {
                success {
                    echo "Successfully deployed ${APP_NAME} to Kubernetes in namespace ${K8S_NAMESPACE}"
                }
                failure {
                    echo "Failed to deploy ${APP_NAME} to Kubernetes in namespace ${K8S_NAMESPACE}"
                    dir('Kubernetes') {
                        withCredentials([
                            string(credentialsId: 'k8s-server-url', variable: 'K8S_SERVER_URL'),
                            string(credentialsId: 'jenkins-k8s-token', variable: 'K8S_TOKEN')
                        ]) {
                            sh """
                            cat > kubeconfig <<EOF
                            apiVersion: v1
                            clusters:
                            - cluster:
                                server: ${K8S_SERVER_URL}
                              name: eks-cluster
                            contexts:
                            - context:
                                cluster: eks-cluster
                                user: jenkins
                                namespace: ${K8S_NAMESPACE}
                              name: eks-context
                            current-context: eks-context
                            kind: Config
                            preferences: {}
                            users:
                            - name: jenkins
                              user:
                                token: ${K8S_TOKEN}
                            EOF
                            """
                            withEnv(["KUBECONFIG=${WORKSPACE}/Kubernetes/kubeconfig"]) {
                                sh "kubectl rollout undo deployment/${APP_NAME} -n ${K8S_NAMESPACE} || true"
                            }
                            sh "rm kubeconfig"
                        }
                    }
                }
            }
        }
    }
}