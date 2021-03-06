#!/usr/bin/env bash

. ./env.sh 

##### START: Set up DEV Project #####

oc new-project $DEV_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $DEV_PROJECT 2> /dev/null
done

# /!\ Create the persistent Jenkins instance

# - Using an OpenShift template
oc new-app --template=jenkins-persistent \
-p VOLUME_CAPACITY=4Gi \
-p MEMORY_LIMIT=2Gi \
-p ENABLE_OAUTH=true

# - Using the Jenkins Operator
# /!\ Install the Jenkins Operator in the DEV project through OLM
## Create the namespace OperatorGroup (the Jenkins operator is singleNamespace-scoped)
# oc create --save-config -f setup/rh-dev-operatorgroup.yaml

## The _Jenkins Operator_ subscription
# oc create --save-config -f setup/openshift-jenkins-operator-subscription.yaml

## Wait for Jenkins Operator to be installed
# watch oc get sub,csv,installPlan

## Create the Jenkins instance:
# oc create --save-config -f setup/jenkins-persistent_cr.yaml

# /!\ If Jenkins Instance is installed using the OpenShift template
oc policy add-role-to-user admin system:serviceaccount:${DEV_PROJECT}:jenkins -n ${DEV_PROJECT}
# /!\ If Jenkins Instance is installed using the  Jenkins Operator
# oc policy add-role-to-user admin system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${DEV_PROJECT}

echo "import camel-quarkus-fruits-and-legumes-api CI/CD build pipeline"
oc new-app -f cicd-api-build/camel-quarkus-fruits-and-legumes-api/build-deploy-pipeline.yml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT

echo "import camel-quarkus-jsonvalidation-api CI/CD build pipeline"
oc new-app -f cicd-api-build/camel-quarkus-jsonvalidation-api/build-deploy-pipeline.yml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT

echo "import camel-quarkus-xmlvalidation-api CI/CD build pipeline"
oc new-app -f cicd-api-build/camel-quarkus-xmlvalidation-api/build-deploy-pipeline.yml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT

echo "import camel-quarkus-rhoam-webhook-handler-api CI/CD build pipeline"
oc new-app -f cicd-api-build/camel-quarkus-rhoam-webhook-handler-api/build-deploy-pipeline.yml \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p AMQP_BROKER_URL="amqps://amq-ssl-broker-amqp-0-svc.amq7-broker-cluster.svc:5672?transport.trustAll=true&transport.verifyHost=false&amqp.idleTimeout=120000" \
-p AMQP_BROKER_USER="amq-user" \
-p AMQP_BROKER_PWD="P@ssw0rd"

# echo "import integration-master-pipeline"
# TODO

echo "import camel-quarkus-fruits-and-legumes-api 3Scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/camel-quarkus-fruits-and-legumes-api/pipeline-template.yaml \
-p GIT_REPO="https://github.com/jeannyil-rhoam-resources/rhoam-automation.git" \
-p GIT_BRANCH="main" \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p TARGET_INSTANCE="apim-demo" \
-p SELF_MANAGED_APICAST_NS=$SELF_MANAGED_APICAST_NS \
-p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=apps.jeannyil.sandbox500.opentlc.com \
-p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.apps.jeannyil.sandbox500.opentlc.com \
-p OIDC_ISSUER_ENDPOINT="https://<CLIENT_ID>:<CLIENT_SECRET>@<HOST>:<PORT>/auth/realms/<REALM_NAME>" \
-p DEVELOPER_ACCOUNT_ID="john" \
-p BASIC_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-fruits-and-legumes-api/basic-plan.yaml" \
-p UNLIMITED_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-fruits-and-legumes-api/unlimited-plan.yaml" \
-p DISABLE_TLS_VALIDATION="no" \
-p TOOLBOX_IMAGE_REGISTRY="image-registry.openshift-image-registry.svc:5000/rh-dev/toolbox-rhel7:3scale2.10"

echo "import camel-quarkus-jsonvalidation-api 3Scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/pipeline-template.yaml \
-p GIT_REPO="https://github.com/jeannyil-rhoam-resources/rhoam-automation.git" \
-p GIT_BRANCH="main" \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p TARGET_INSTANCE="apim-demo" \
-p SELF_MANAGED_APICAST_NS=$SELF_MANAGED_APICAST_NS \
-p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=apps.jeannyil.sandbox500.opentlc.com \
-p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.apps.jeannyil.sandbox500.opentlc.com \
-p OIDC_ISSUER_ENDPOINT="https://<CLIENT_ID>:<CLIENT_SECRET>@<HOST>:<PORT>/auth/realms/<REALM_NAME>" \
-p DEVELOPER_ACCOUNT_ID="john" \
-p BASIC_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/basic-plan.yaml" \
-p UNLIMITED_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-jsonvalidation-api/unlimited-plan.yaml" \
-p DISABLE_TLS_VALIDATION="no" \
-p TOOLBOX_IMAGE_REGISTRY="image-registry.openshift-image-registry.svc:5000/rh-dev/toolbox-rhel7:3scale2.10"

echo "import camel-quarkus-xmlvalidation-api 3Scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/camel-quarkus-xmlvalidation-api/pipeline-template.yaml \
-p GIT_REPO="https://github.com/jeannyil-rhoam-resources/rhoam-automation.git" \
-p GIT_BRANCH="main" \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p TARGET_INSTANCE="apim-demo" \
-p SELF_MANAGED_APICAST_NS=$SELF_MANAGED_APICAST_NS \
-p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=apps.jeannyil.sandbox500.opentlc.com \
-p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.apps.jeannyil.sandbox500.opentlc.com \
-p OIDC_ISSUER_ENDPOINT="https://<CLIENT_ID>:<CLIENT_SECRET>@<HOST>:<PORT>/auth/realms/<REALM_NAME>" \
-p DEVELOPER_ACCOUNT_ID="john" \
-p BASIC_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-xmlvalidation-api/basic-plan.yaml" \
-p UNLIMITED_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-xmlvalidation-api/unlimited-plan.yaml" \
-p DISABLE_TLS_VALIDATION="no" \
-p TOOLBOX_IMAGE_REGISTRY="image-registry.openshift-image-registry.svc:5000/rh-dev/toolbox-rhel7:3scale2.10"

echo "import camel-quarkus-rhoam-webhook-handler-api 3Scale API publishing pipeline"
oc new-app -f cicd-3scale/3scaletoolbox/camel-quarkus-rhoam-webhook-handler-api/pipeline-template.yaml \
-p GIT_REPO="https://github.com/jeannyil-rhoam-resources/rhoam-automation.git" \
-p GIT_BRANCH="main" \
-p IMAGE_NAMESPACE=$DEV_PROJECT \
-p DEV_PROJECT=$DEV_PROJECT \
-p TEST_PROJECT=$TEST_PROJECT \
-p PROD_PROJECT=$PROD_PROJECT \
-p TARGET_INSTANCE="apim-demo" \
-p SELF_MANAGED_APICAST_NS=$SELF_MANAGED_APICAST_NS \
-p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=apps.jeannyil.sandbox500.opentlc.com \
-p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.apps.jeannyil.sandbox500.opentlc.com \
-p OIDC_ISSUER_ENDPOINT="https://<CLIENT_ID>:<CLIENT_SECRET>@<HOST>:<PORT>/auth/realms/<REALM_NAME>" \
-p DEVELOPER_ACCOUNT_ID="john" \
-p BASIC_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-rhoam-webhook-handler-api/basic-plan.yaml" \
-p UNLIMITED_PLAN_YAML_FILE_PATH="https://raw.githubusercontent.com/jeannyil-rhoam-resources/rhoam-automation/main/cicd-3scale/3scaletoolbox/camel-quarkus-rhoam-webhook-handler-api/unlimited-plan.yaml" \
-p DISABLE_TLS_VALIDATION="no" \
-p TOOLBOX_IMAGE_REGISTRY="image-registry.openshift-image-registry.svc:5000/rh-dev/toolbox-rhel7:3scale2.10"

##### END: Set up DEV Project #####

##### START: Set up Test Project #####

oc new-project $TEST_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $TEST_PROJECT 2> /dev/null
done

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${TEST_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:camel-quarkus-http -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:camel-quarkus-jsonvalidation-api -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:camel-quarkus-xmlvalidation-api -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:camel-quarkus-rhoam-webhook-handler-api -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}
# /!\ If Jenkins Instance is installed using the OpenShift template
oc policy add-role-to-user admin system:serviceaccount:${DEV_PROJECT}:jenkins -n ${TEST_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${SELF_MANAGED_APICAST_NS}
# \!\ If Jenkins Instance is installed using the  Jenkins Operator
# oc policy add-role-to-user admin system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${TEST_PROJECT}
# oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${SELF_MANAGED_APICAST_NS}

##### END: Set up Test Project #####

#this should be used in development/demo environment for testing purpose

##### START: Set up PROD Project #####

oc new-project $PROD_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $PROD_PROJECT 2> /dev/null
done

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${PROD_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:camel-quarkus-http -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:camel-quarkus-jsonvalidation-api -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:camel-quarkus-xmlvalidation-api -n ${DEV_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:camel-quarkus-rhoam-webhook-handler-api -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}
# /!\ If Jenkins Instance is installed using the OpenShift template
oc policy add-role-to-user admin system:serviceaccount:${DEV_PROJECT}:jenkins -n ${PROD_PROJECT}
# /!\ If Jenkins Instance is installed using the  Jenkins Operator
# oc policy add-role-to-user admin system:serviceaccount:${DEV_PROJECT}:jenkins-persistent -n ${PROD_PROJECT}

##### END: Set up PROD Project #####

# Set context to the DEV OpenShift project
oc project $DEV_PROJECT
