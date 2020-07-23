## chap02

```bash
# acr 用の RESOURCE_GROUP
$ az group create --resource-group $ACR_RESOURCE_GROUP --location $AZURE_LOCATION
$ az acr create --resource-group $ACR_RESOURCE_GROUP --name $ACR_NAME --sku Standard --location $AZURE_LOCATION

$ cd chap02
$ az acr build --registry $ACR_NAME --image photo-view:v1.0 v1.0/
$ az acr build --registry $ACR_NAME --image photo-view:v2.0 v2.0/
$ az acr repository show-tags -n $ACR_NAME --repository photo-view

# aks 用の RESOURCE_GROUP
$ az group create --resource-group $AKS_RESOURCE_GROUP --location $AZURE_LOCATION

# support されている version 一覧
$ az aks get-versions --location eastus --output table

# cluster 作成
$ az aks create \
    --name $AKS_CLUSTER_NAME \
    --resource-group $AKS_RESOURCE_GROUP \
    --node-count 2 \
    --kubernetes-version 1.17.7 \
    --node-vm-size Standard_DS2_v2 \
    --generate-ssh-keys \
    --service-principal $APP_ID \
    --client-secret $SP_PASSWORD
    --load-balancer-sku standard
    --vm-set-type VirtualMachineScaleSets \

# クラスタへの認証情報取得
$ az aks get-credentials --admin --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME
Merged "$AKS_CLUSTER_NAME" as current context in /Users/xxxxx/.kube/config

# node の情報
$ kubectl get node -o=wide

# repository manifest 詳細
$ az acr repository show-manifests --name $ACR_NAME --repository photo-view
[
  {
    "digest": "sha256:2442196f1ed22960f4a37245a7f97215b120339acf836d71a2ea7004e25255ae",
    "tags": [
      "v2.0"
    ],
    "timestamp": "2020-07-12T02:29:02.2689091Z"
  },
  {
    "digest": "sha256:7d29a265cbe8df4429ebad59228a4bbeed9a8e705ff3abbbfc48ee9b0edffd3d",
    "tags": [
      "v1.0"
    ],
    "timestamp": "2020-07-12T02:19:45.2093152Z"
  }
]

# レジストリリスト
$ az acr list
[
  {
    "adminUserEnabled": false,
    "creationDate": "2020-07-12T02:09:27.357147+00:00",
    "dataEndpointEnabled": false,
    "dataEndpointHostNames": [],
    "encryption": {
      "keyVaultProperties": null,
      "status": "disabled"
    },
    "id": "/subscriptions/26fc75fa-ee81-44c5-a4bc-932e68f6679d/resourceGroups/smith30SampleACRRegistry/providers/Microsoft.ContainerRegistry/registries/smith30SampleACRRegistry",
    "identity": null,
    "location": "japaneast",
    "loginServer": "smith30sampleacrregistry.azurecr.io",
    "name": "smith30SampleACRRegistry",
    "networkRuleSet": null,
    "policies": {
      "quarantinePolicy": {
        "status": "disabled"
      },
      "retentionPolicy": {
        "days": 7,
        "lastUpdatedTime": "2020-07-12T02:09:30.080433+00:00",
        "status": "disabled"
      },
      "trustPolicy": {
        "status": "disabled",
        "type": "Notary"
      }
    },
    "privateEndpointConnections": [],
    "provisioningState": "Succeeded",
    "publicNetworkAccess": "Enabled",
    "resourceGroup": "smith30SampleACRRegistry",
    "sku": {
      "name": "Standard",
      "tier": "Standard"
    },
    "status": null,
    "storageAccount": null,
    "tags": {},
    "type": "Microsoft.ContainerRegistry/registries"
  }
]
```

## 作業メモ

2019/01 出版の本の version が 1.11.4 だけど、もうそのバージョンでクラスタ組めない

サポートされているのは下記

```
$ az aks get-versions --location eastus --output table
KubernetesVersion    Upgrades
-------------------  --------------------------------
1.18.4(preview)      None available
1.18.2(preview)      1.18.4(preview)
1.17.7               1.18.2(preview), 1.18.4(preview)
1.16.10              1.17.7
1.15.12              1.16.10
1.15.11              1.15.12, 1.16.10
```

とりあえず 1.17.7 にしてみる

AKS 自体は無料(クラスタの管理)。動かしている kubernetes の node にお金がかかる

```
Azure Kubernetes Service (AKS) は、フル マネージドの Kubernetes コンテナー オーケストレーター サービスとして、Kubernetes のデプロイ、管理、および操作を簡素化する無料のコンテナー サービスです。
仮想マシンと、関連するストレージとネットワーク リソースの使用した分だけをお支払いいただくため、AKS は市場で最も効率的でコスト効果の高いコンテナー サービスです。
```


### mac での kubectl 補完

https://kubernetes.io/ja/docs/tasks/tools/install-kubectl/#%E3%81%AF%E3%81%98%E3%82%81%E3%81%AB


## Kubernetes

クラスターにアプリケーションをデプロイするときは **マニフェストファイル** を作成する

**リソース**
デプロイしたコンテナアプリやネットワークの構成のこと

**アーキテクチャ**

```
                               Kubernetes Cluster

                          +------------------------------------------------------------------------------------------+
                          |                                                                                          |
                          |      +------------------+         +------------------+         +-------------------+     |
                          |      | +--------------+ |         |                  |         |                   |     |
                          |      | | Container    | |         |                  |         |                   |     |
                          |      | +--------------+ |         |                  |         | +---------------+ |     |
                          |      |                  |         | +--------------+ |         | | Container     | |     |
                          |      |                  |         | | Container    | |         | +---------------+ |     |
                          |      |                  |         | +--------------+ |         |                   |     |
                          |      |                  |         |                  |         |                   |     |
                          |      |                  |         |                  |         | +---------------+ |     |
                          |      |                  |         |                  |         | | Container     | |     |
                          |      |                  |         | +--------------+ |         | +---------------+ |     |
                          |      |                  |         | | Container    | |         |                   |     |
                          |      |                  |         | +--------------+ |         |                   |     |
                          |      |                  |         |                  |         |                   |     |
                          |      |                  |         |                  |         |                   |     |
                        +---+    |                  |         |                  |         |                   |     |
                        | | |    +------------------+         +------------------+         +-------------------+     |
+---------------------->+ | |                                                                                        |
                        | | |        Node                          Node                          Node                |
                  +-----+ | |                                                                                        |
                  |     +---+                                                                                        |
                  |       +------------------------------------------------------------------------------------------+
                  |
                  |
                  +-+ Gateway


```

## 設定ファイル

**deployment** (一般的なのか?)
コンテナアプリケーションの設定

**service**
Pod にクライアントからアクセスするためのサービス設定。クラスタと外部ネットワークとの設定を定義
この定義は、各クラウドや自分たちの環境よってことなりそう