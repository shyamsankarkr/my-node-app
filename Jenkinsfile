pipeline {
    agent {
        label 'ansible-node'  
    }
    tools {
        nodejs 'nodejs23'  
    }
    environment {
        DOCKER_USERNAME = credentials('docker-username')  
        DOCKER_PASSWORD = credentials('docker-password')  
    }
    stages {
        stage('Increment Version') {
            steps {
                script {
                    echo 'Incrementing app version...'
                    sh 'npm version patch --no-git-tag-version'
                    def packageJson = readFile('package.json')
                    def matcher = packageJson =~ /"version":\s*"([^"]+)"/
                    def ver = matcher[0][1]
                    env.version = ver
                    env.IMAGE_NAME = "${version}-${BUILD_NUMBER}"
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                script {
                    echo "Installing dependencies..."
                    sh 'npm install'
                }
            }
        }
        stage('Code Review (SonarQube)') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    echo "Running SonarQube analysis..."
                    sh 'sonar-scanner -Dsonar.projectKey=nodejs-app -Dsonar.sources=.'
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Build and Package') {
            steps {
                script {
                    echo "Building the Node.js application..."
                    sh "tar --exclude='${env.IMAGE_NAME}.tar.gz' --exclude='node_modules' -czf ${env.IMAGE_NAME}.tar.gz app/ package.json"
                }
            }
        }
        stage('Upload to Nexus') {
            steps {
                nexusArtifactUploader(
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    nexusUrl: '3.108.63.133:8081',  
                    groupId: 'in.shyam',
                    version: "${env.version}",
                    repository: 'npm-releases',  
                    credentialsId: 'nexus-server',  
                    artifacts: [[
                        artifactId: 'nodejs-app',  
                        classifier: '',
                        file: "${env.IMAGE_NAME}.tar.gz",
                        type: 'tar.gz'  
                    ]]
                )
            }
        }
        stage('Deploy') {
            steps {
                script {
                    echo "Deploying the application using Ansible..."
                    sh "ansible-playbook -i hosts nodejs.yml -e IMAGE_NAME=${env.IMAGE_NAME} -e DOCKER_USERNAME=${env.DOCKER_USERNAME} -e DOCKER_PASSWORD=${env.DOCKER_PASSWORD}"
                }
            }
        }
    }
}
