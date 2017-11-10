# Jenkins Pipeline Tips and Tricks

## Chained Pipelines:
```groovy
pipeline {
    agent {
        label 'docker'
    }

    stages {
        stage('Test') {
            steps {
                build job: '/Yovko_test/AWS_Jobs/Stop_Start_AWS_Instances_test', parameters: [
                    string(name: 'INSTANCES', value: 'CS51-22TEST15'),
                    string(name: 'state', value: 'stop')
                ]
            }
        }
    }
}
```

## Pipeline as a Shared Library
```groovy
#!/usr/bin/env groovy

def call(String awsInstances = '', String awsState = '') {
    build job: '/Yovko_test/AWS_Jobs/Stop_Start_AWS_Instances_test', parameters: [
                            string(name: 'INSTANCES', value: "${awsInstances}"),
                            string(name: 'STATE', value: "${awsState}")
                        ]
}
```

## Invoke Shared Library
```groovy
@Library('jenkins-pipeline-libraries@master') _

pipeline {
  agent {
    label 'docker'
  }

  stages {
    stage('Start AWS Instances') {
      steps {
          startStopAWSInstances('CS51-22TEST15', 'stop')
      }
    }
  }
}
```

## Run Pipeline on multiple agents
```groovy
@Library('jenkins-pipeline-libraries@master') _

pipeline {
  agent none

  stages {
    stage('Start AWS Instances') {
      agent none
      steps {
        startStopAWSInstances('CS51-22TEST15,CS51-22TEST16', 'stop')
      }
    }
    stage('Running Task on Linux') {
      agent { label 'docker' }
      steps {
        sh 'pwd'
      }
    }
    stage('Running Task on Windows'){
      agent { label 'win2012' }
      steps  {
        bat 'dir "c:/"'
      }
    }
  }
}
```

## Use case to set environemnt variables
```groovy
case environment
when 'hsm_dr'
  default['test']['value'] = 'hsm_dr'
when 'hsm_test'
  default['test']['value'] = 'hsm_test'
end
```

## Use if to set environment variables
```groovy
if environment == 'hsw_dr'
    default['hs_reconconsole2']['package_path'] = "#{ node['artifactory_url'] }#{node['hs_reconconsole2']['base_repo_path']}"
    default['hazelcast']['download_url'] = "#{ node['artifactory_url'] }anonymous_generic/hazelcast/hazelcast-all/hazelcast-all-3.8.1.jar"
    default['java_se']['uri'] = "#{ node['artifactory_url'] }anonymous_generic/java-jdk/"
end
```