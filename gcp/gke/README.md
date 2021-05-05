# GKE

```
terraform plan -var base_name=example -var project_id=xxx -out tfplan
```

```
terraform apply tfplan
```

```
gcloud container clusters list
```

```
export KUBECONFIG=kubeconfig
```

```
gcloud container clusters get-credentials example-blue --zone asia-northeast1-a
```

```
helm install nginx bitnami/nginx
```

```
helm upgrade nginx bitnami/nginx --set resources.requests.cpu=500m --set replicaCount=3
```
