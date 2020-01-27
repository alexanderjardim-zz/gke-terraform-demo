# gke-terraform-demo
Simple terraform script to create a gke cluster

# Setup
You will need a google service account credential file with the following permissions:
```
compute.instanceGroupManagers.get
iam.serviceAccounts.create
iam.serviceAccounts.delete
iam.serviceAccounts.get
iam.serviceAccounts.getIamPolicy
iam.serviceAccounts.setIamPolicy
iam.serviceAccounts.update
```

# Deployment
```bash
terraform init
terraform validate
GOOGLE_CLOUD_KEYFILE_JSON=</path/to/credential_file.json> terraform apply -var gcp_project=<your-project-id>
```

