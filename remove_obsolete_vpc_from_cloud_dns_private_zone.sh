#!/bin/bash

function log()  {
    STAMP=$(date +'%Y-%m-%d %H:%M:%S %Z')
    LEVEL=$1
    case ${LEVEL} in
    ERROR)
        printf "\n%s %s    %s\n" "${STAMP}" "${LEVEL}" "$2" >&2
        ;;
    *)
        printf "\n%s %s    %s\n" "${STAMP}" "${LEVEL}" "$2"
        ;;
    esac
}

function tidy_up() {
    for DNS_ZONE_NAME in $(gcloud dns managed-zones list \
                            --project=${GCP_PROJECT_ID} \
                            --format="value(NAME)" \
                            --filter="name=(${DNS_ZONE_NAME_1})")
    do
        gcloud dns managed-zones delete ${DNS_ZONE_NAME} --project=${GCP_PROJECT_ID} -q
    done

    for VPC_NAME in $(gcloud compute networks list \
                        --project=${GCP_PROJECT_ID} \
                        --format="value(NAME)" \
                        --filter="name=(${VPC_NAME_1},${VPC_NAME_2})")
    do
        gcloud compute networks delete ${VPC_NAME} --project=${GCP_PROJECT_ID} -q
    done
}

export VPC_NAME_1="vpc1"
export VPC_NAME_2="vpc2"
export DNS_ZONE_NAME_1="example"

log INFO "display gcloud version"
gcloud version

log INFO "display gcloud config list"
gcloud config list

export GCP_PROJECT_ID=$(gcloud config list --format='value(core.project)')
export GCP_SERVICE_ACCOUNT=$(gcloud config list --format='value(core.account)')

log INFO "clean up environment"
tidy_up

log INFO "Display IAM roles assigned to gcp service account"
gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
    --flatten='bindings[].members[]' \
    --format='table(bindings.role,bindings.members)' \
    | grep ${GCP_SERVICE_ACCOUNT}

log INFO "Display enabled APIs"
gcloud services list --enabled --project ${GCP_PROJECT_ID}

log INFO "create 2 VPCs"
gcloud compute networks create ${VPC_NAME_1} \
    --project=${GCP_PROJECT_ID} \
    --bgp-routing-mode="regional" \
    --subnet-mode=custom
gcloud compute networks create ${VPC_NAME_2} \
    --project=${GCP_PROJECT_ID} \
    --bgp-routing-mode="regional" \
    --subnet-mode=custom

log INFO "create a Cloud DNS private zone and add 2 VPCs into Cloud DNS private zone"
export VPC_URL_LIST=$(printf "%s," \
                        $(gcloud compute networks list \
                            --project=${GCP_PROJECT_ID} \
                            --filter="name=(${VPC_NAME_1},${VPC_NAME_2})" \
                            --format="value(selfLink)"))
gcloud dns --project=${GCP_PROJECT_ID} managed-zones create ${DNS_ZONE_NAME_1} \
    --dns-name=${DNS_ZONE_NAME_1}. \
    --description=${DNS_ZONE_NAME_1} \
    --visibility=private \
    --networks=${VPC_URL_LIST} \
    --verbosity=debug

log INFO "list vpc"
gcloud compute networks list --project=${GCP_PROJECT_ID} --format="table(name,selfLink)"

log INFO "list vpc in Cloud DNS private-access zone"
gcloud dns managed-zones describe ${DNS_ZONE_NAME_1} \
    --project=${GCP_PROJECT_ID} \
    --format="table(name,dnsName,privateVisibilityConfig.networks[].networkUrl)"

log INFO "remove one VPC"
gcloud compute networks delete ${VPC_NAME_1} --project=${GCP_PROJECT_ID} -q

log INFO "list vpc"
gcloud compute networks list --project=${GCP_PROJECT_ID} --format="table(name,selfLink)"

log INFO "list vpc in Cloud DNS private-access zone"
gcloud dns managed-zones describe ${DNS_ZONE_NAME_1} \
    --project=${GCP_PROJECT_ID} \
    --format="table(name,dnsName,privateVisibilityConfig.networks[].networkUrl)"

log INFO "update Cloud DNS private zone to reflect VPC removal changes"
export VPC_URL_LIST=$(printf "%s," \
                        $(gcloud compute networks list \
                            --project=${GCP_PROJECT_ID} \
                            --filter="name=(${VPC_NAME_1},${VPC_NAME_2})" \
                            --format="value(selfLink)"))
gcloud dns --project=${GCP_PROJECT_ID} managed-zones update ${DNS_ZONE_NAME_1} \
    --networks=${VPC_URL_LIST} \
    --verbosity=debug

log INFO "list vpc in Cloud DNS private-access zone"
gcloud dns managed-zones describe ${DNS_ZONE_NAME_1} \
    --project=${GCP_PROJECT_ID} \
    --format="table(name,dnsName,privateVisibilityConfig.networks[].networkUrl)"

log INFO "clean up environment"
tidy_up
