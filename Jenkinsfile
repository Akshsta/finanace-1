pipeline {
    agent any

    environment {
        GIT_REPO = 'https://github.com/Akshsta/finanace-1.git'
        GIT_BRANCH = 'main'
        ANSIBLE_INVENTORY = "finance-me/hosts.ini"
        ANSIBLE_PLAYBOOK = "finance-me/deploy_finance.yml"
        JAR_NAME = "target/banking-0.0.1-SNAPSHOT.jar"
        REMOTE_JAR_PATH = "/home/ubuntu/banking-finance-Me/finance-me/finance-me.jar"
        EC2_PUBLIC_IP = '44.201.199.111' 
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
                stash name: 'built-jar', includes: 'target/*.jar'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Update Ansible Hosts File') {
            steps {
                script {
                    writeFile file: ANSIBLE_INVENTORY, text: """
                    [ec2-finance]
                    ${EC2_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/project.pem
                    """
                }
            }
        }

        stage('Copy JAR to EC2') {
            steps {
                unstash 'built-jar'
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    writeFile file: 'ansible.cfg', text: """
                    [defaults]
                    host_key_checking = False
                    """
                    sh '''
                    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no \
                    target/banking-0.0.1-SNAPSHOT.jar \
                    ubuntu@44.201.199.111:/home/ubuntu/banking-finance-Me/finance-me/finance-me.jar
                    '''
                }
            }
        }
        
        stage('Debug Inventory') {
            steps {
                sh 'cat finance-me/hosts.ini'
            }
        }


        stage('Run Ansible Playbook') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                sh '''
                   unset ANSIBLE_PRIVATE_KEY_FILE
                   unset ANSIBLE_SSH_PRIVATE_KEY_FILE
                   ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOK} --private-key=$SSH_KEY -vvvv
                 '''
                }
            }
        }

        stage('Run Tests Again (Post-Deployment)') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Publish TestNG Report') {
            steps {
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'target/surefire-reports',
                    reportFiles: 'index.html',
                    reportName: 'TestNG Report'
                ])
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
