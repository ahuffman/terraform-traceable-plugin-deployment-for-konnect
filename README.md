## Purpose

To create a Kong Konnect Control Plane and Upload the Traceable.AI Plugin schema.  This was created for a Kong & Traceable.ai lab environment.

## Requirements

1. [Terraform installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
1. You have a [Kong Personal Access Token](https://docs.konghq.com/konnect/gateway-manager/declarative-config/#generate-a-personal-access-token)


## Running

```bash
openssl req -new -x509 -nodes -newkey ec:<(openssl ecparam -name secp384r1) -keyout ./tls.key -out ./tls.crt -days 1095 -subj "/CN=kong_clustering" && \
./kreate-konnect-control-plane.sh && \
source ./kong_out && \
terraform init -var konnect_personal_access_token=$konnect_pat -var konnect_control_plane_id=$konnect_cp_id && \
sleep 10 && \
terraform apply -var konnect_personal_access_token=$konnect_pat -var konnect_control_plane_id=$konnect_cp_id -auto-approve
```

## Explanation

1. We create a certificate for Konnect hybrid-mode communication
1. We launch the control plane creation script, input our personal access token, and the script uploads our communication certificate to the control plane, and we capture all the required information to deploy a dataplane and to upload the Traceable.ai plugin into the new Konnect Control Plane
1. We source the output variables from the prior step for use in additional steps
1. We initialize the terraform modules we need (Konnect)
1. We launch the terraform script to upload the Traceable.ai plugin into the control plane.
1. You can now deploy the dataplane using helm and the sourced variables.