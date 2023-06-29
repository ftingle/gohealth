@Library('jenkins-pipelines') _

def VERSION = utils.BUILD_VERSION

def SERVICE_NAME = 'unicorns'
def APPLICATION_NAME = 'hasselhoff-unicorns'
def TASK_NAME = 'unicorns-task'
def SERVICE_IMAGE_NAME = "gohealth/${APPLICATION_NAME}"
def NOTIFY_WEBHOOK_URL_CREDENTIALS_ID = 'ms_teams_webhook_tech-ietpe_jenkins-notifications'

def UNICORNS_LOCK = 'unicorns-deployment'

pipeline {
    agent {
        label 'aws'
    }

    tools {
        jdk 'amazon-corretto-jdk-11'
    }

    stages {
        stage('Test') {
            when {
                not { branch 'main' }
            }
            steps {
                withGradleCache {
                    sh "./gradlew test --info"
                }
            }
        }

        stage('Publish') {
            when {
                branch 'main'
            }

            steps {
                withGradleCache {
                    sh "./gradlew -PversionOverride=${VERSION} dockerBuildArtifacts migrationsBuildArtifacts publish generateSBOM --info"
                }

                dependencyTrackPublish(
                    projectName: SERVICE_NAME,
                    projectVersion: VERSION,
                    sbomPath: 'unicorns-server/build/reports/bom.json'
                )

                dockerPublish(
                    directory: 'unicorns-server/build/migrations',
                    imageName: SERVICE_IMAGE_NAME,
                    version: "${VERSION}-migrations",
                    pushLatestTag: false
                )

                dockerPublish(
                    directory: 'unicorns-server/build/docker',
                    imageName: SERVICE_IMAGE_NAME,
                    version: VERSION,
                    buildArgs: [
                        APPLICATION_NAME: APPLICATION_NAME,
                        APPLICATION_VERSION: VERSION
                    ],
                    targetPlatforms: ['arm64', 'amd64']
                )

                gitTag(
                    name: VERSION,
                    message: "${SERVICE_NAME} release ${VERSION}"
                )

                script {
                    currentBuild.description = VERSION
                }
            }
        }

        stage('QA') {
            when {
                branch 'main'
            }

            options {
                lock(UNICORNS_LOCK)
            }

            steps {
                notifyJobStarted(
                    webhookUrlCredentialsId: NOTIFY_WEBHOOK_URL_CREDENTIALS_ID,
                    message: "Deployment of ${env.JOB_NAME} to QA started, Build: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
                )

                ecsDeploy {
                    env 'qa'
                    service SERVICE_NAME
                    version VERSION
                    verbose true
                }

                ecsRunTask {
                    env 'qa'
                    task TASK_NAME
                    version 'latest'
                    cmd "/bin/bash,-c,'echo hello world'"
                }

                dependencyTrackActivate(
                    projectName: SERVICE_NAME,
                    projectVersion: VERSION,
                    environment: 'qa'
                )
            }

            post {
                success {
                    notifyJobSucceeded(
                        webhookUrlCredentialsId: NOTIFY_WEBHOOK_URL_CREDENTIALS_ID,
                        message: "Deployment of ${env.JOB_NAME} to QA succeeded, Build: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
                    )
                }

                failure {
                    notifyJobFailed(
                        webhookUrlCredentialsId: NOTIFY_WEBHOOK_URL_CREDENTIALS_ID,
                        message: "Deployment of ${env.JOB_NAME} to QA failed, Build: ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
                    )
                }
            }
        }
    }
}
