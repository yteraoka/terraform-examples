# Google Cloud Platform

https://github.com/terraform-google-modules


## 必要なサービスを有効にする

```
gcloud services enable servicemanagement.googleapis.com
gcloud services enable servicecontrol.googleapis.com
gcloud services enable endpoints.googleapis.com
```

## GKE の Credential を取得

```
export KUBECONFIG=kubeconfig
gcloud container clusters get-credentials --zone asia-northeast1-a epsv2-dev
```

## Golang の sample code

https://github.com/GoogleCloudPlatform/golang-samples/tree/master/endpoints/getting-started

Endpoints 用の OpenAPI YAML

https://github.com/GoogleCloudPlatform/golang-samples/blob/master/endpoints/getting-started/openapi.yaml

