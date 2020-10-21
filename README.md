# Introduction 
This script [remove_obsolete_vpc_from_cloud_dns_private_zone.sh](remove_obsolete_vpc_from_cloud_dns_private_zone.sh) is to test
what would happen when we remove an obsoleted VPC record from Cloud DNS private zone. <br/> 
<br/>
We are following this gcp doc to update Cloud DNS private zone networks list <br/>
https://cloud.google.com/dns/docs/zones#updating_authorized_networks_for_a_private_zone

# Prerequisite
### GCP Project APIs
A GCP project with necessary APIs enabled to create VPC and Cloud DNS private zone, 
such as below, see this [log file](remove_obsolete_vpc_from_cloud_dns_private_zone.log) for more details 
```
NAME                                 TITLE
cloudresourcemanager.googleapis.com  Cloud Resource Manager API
compute.googleapis.com               Compute Engine API
dns.googleapis.com                   Cloud DNS API
iam.googleapis.com                   Identity and Access Management (IAM) API
serviceusage.googleapis.com          Service Usage API
```

### GCP Service Account
A GCP service account with necessary IAM roles assigned, 
such as below, see this [log file](remove_obsolete_vpc_from_cloud_dns_private_zone.log) for more details
```
roles/compute.networkAdmin            serviceAccount:terraform@gke-eu-1.iam.gserviceaccount.com
roles/dns.admin                       serviceAccount:terraform@gke-eu-1.iam.gserviceaccount.com
roles/iam.securityReviewer            serviceAccount:terraform@gke-eu-1.iam.gserviceaccount.com
roles/serviceusage.serviceUsageAdmin  serviceAccount:terraform@gke-eu-1.iam.gserviceaccount.com
```

### gcloud SDK, gcloud config and Bash Environment
These should be in place in the environment

# Instruction
Run [remove_obsolete_vpc_from_cloud_dns_private_zone.sh](remove_obsolete_vpc_from_cloud_dns_private_zone.sh) <br/>
such as below, redirect output to a log file
```
$./remove_obsolete_vpc_from_cloud_dns_private_zone.sh > remove_obsolete_vpc_from_cloud_dns_private_zone.log 2>&1
$
```

# Conclusion
From the [log file](remove_obsolete_vpc_from_cloud_dns_private_zone.log) we can see <br/>

At some point, we have 2 VPCs created and These 2 VPCs are added into Cloud DNS private zone
```
2020-10-21 13:20:00 CST INFO    list vpc
NAME  SELF_LINK
vpc1  https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc1
vpc2  https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc2

2020-10-21 13:20:03 CST INFO    list vpc in Cloud DNS private-access zone
NAME     DNS_NAME  NETWORK_URL
example  example.  ['https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc1', 'https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc2']
``` 

We will remove one of the VPCs. 
Existing Cloud DNS private zone will still contain the obsoleted VPC in its network list. <br/>
When we update Cloud DNS private zone to reflect latest VPC network, it will hit an 403 error. <br/>
```
020-10-21 13:20:06 CST INFO    remove one VPC
Deleted [https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc1].

2020-10-21 13:20:24 CST INFO    list vpc
NAME  SELF_LINK
vpc2  https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc2

2020-10-21 13:20:26 CST INFO    list vpc in Cloud DNS private-access zone
NAME     DNS_NAME  NETWORK_URL
example  example.  ['https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc1', 'https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc2']

2020-10-21 13:20:28 CST INFO    update Cloud DNS private zone to reflect VPC removal changes
DEBUG: Running [gcloud.dns.managed-zones.update] with arguments: [--networks: "['https://www.googleapis.com/compute/v1/projects/gke-eu-1/global/networks/vpc2']", --project: "gke-eu-1", --verbosity: "debug", ZONE: "example"]
DEBUG: (gcloud.dns.managed-zones.update) HTTPError 403: Forbidden
Traceback (most recent call last):
  File "/Users/junxingmo/google-cloud-sdk/lib/googlecloudsdk/calliope/cli.py", line 983, in Execute
    resources = calliope_command.Run(cli=self, args=args)
  File "/Users/junxingmo/google-cloud-sdk/lib/googlecloudsdk/calliope/backend.py", line 808, in Run
    resources = command_instance.Run(args)
  File "/Users/junxingmo/google-cloud-sdk/lib/surface/dns/managed_zones/update.py", line 151, in Run
    reverse_lookup_config=reverse_lookup_config)
  File "/Users/junxingmo/google-cloud-sdk/lib/surface/dns/managed_zones/update.py", line 76, in _Update
    **kwargs)
  File "/Users/junxingmo/google-cloud-sdk/lib/googlecloudsdk/api_lib/dns/managed_zones.py", line 74, in Patch
    managedZone=zone_ref.Name()))
  File "/Users/junxingmo/google-cloud-sdk/lib/googlecloudsdk/third_party/apis/dns/v1/dns_v1_client.py", line 387, in Patch
    config, request, global_params=global_params)
  File "/Users/junxingmo/google-cloud-sdk/lib/third_party/apitools/base/py/base_api.py", line 731, in _RunMethod
    return self.ProcessHttpResponse(method_config, http_response, request)
  File "/Users/junxingmo/google-cloud-sdk/lib/third_party/apitools/base/py/base_api.py", line 737, in ProcessHttpResponse
    self.__ProcessHttpResponse(method_config, http_response, request))
  File "/Users/junxingmo/google-cloud-sdk/lib/third_party/apitools/base/py/base_api.py", line 604, in __ProcessHttpResponse
    http_response, method_config=method_config, request=request)
apitools.base.py.exceptions.HttpForbiddenError: HttpError accessing <https://dns.googleapis.com/dns/v1/projects/gke-eu-1/managedZones/example?alt=json>: response: <{'cache-control': 'private', 'content-length': '194', 'vary': 'Origin, X-Origin, Referer', 'alt-svc': 'h3-Q050=":443"; ma=2592000,h3-29=":443"; ma=2592000,h3-27=":443"; ma=2592000,h3-T051=":443"; ma=2592000,h3-T050=":443"; ma=2592000,h3-Q046=":443"; ma=2592000,h3-Q043=":443"; ma=2592000,quic=":443"; ma=2592000; v="46,43"', 'server': 'ESF', 'transfer-encoding': 'chunked', 'content-type': 'application/json; charset=UTF-8', 'x-content-type-options': 'nosniff', 'x-frame-options': 'SAMEORIGIN', 'x-xss-protection': '0', 'status': '403', 'date': 'Wed, 21 Oct 2020 05:20:33 GMT', '-content-encoding': 'gzip'}>, content <{
  "error": {
    "code": 403,
    "message": "Forbidden",
    "errors": [
      {
        "message": "Forbidden",
        "domain": "global",
        "reason": "forbidden"
      }
    ]
  }
}
>
ERROR: (gcloud.dns.managed-zones.update) HTTPError 403: Forbidden
```

When we do similar steps on the console, console has no effect, console will still display the obsoleted VPC