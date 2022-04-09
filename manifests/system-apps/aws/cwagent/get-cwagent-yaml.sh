#!/bin/bash

EKSCTL_OUTPUT="$( eksctl get clusters -o json | jq -r '.[0] | "\(.metadata.name):\(.metadata.region)"'  )"
REGION="${EKSCTL_OUTPUT##*:}"
CLUSTER="${EKSCTL_OUTPUT%%:*}"
[ -z "$REGION" ] && { echo "Não consegui identificar a Region"; exit 1 ; } 
[ -z "$CLUSTER" ] && { echo "Não consegui identificar a Region"; exit 1 ; } 

ClusterName="$CLUSTER"
RegionName="$REGION"
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
curl -s https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' > cwagent-fluent-bit-quickstart.yaml 
