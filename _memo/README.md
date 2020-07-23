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
# 認証切れてエラーになってたら更新する
$ az aks update-credentials -g $AKS_RESOURCE_GROUP -n $AKS_CLUSTER_NAME --reset-service-principal --service-principal $APP_ID --client-secret $SP_PASSWORD

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

###
# chap 03
###
$ cd chap03

# cluster にコンテナをデプロイ
$ kubectl apply -f tutorial-deployment.yaml
$ kubectl get pod -o wide
# 5 つの Pod が2つのクラスタに均等にはいっているはず

$ kubectl describe pods <pods-name>

# cluster の 公開。LB がインターネットゲートウェイとして機能し、Cluster へリクエストをリバースプロキシする
$ kubectl apply -f tutorial-service.yaml

# webserver の External-IP にアクセスする
$ kubectl get svc # Display one or many resources

# error 出力 (LB がpending のままステータス変わらなかった)
$ kubectl get events --all-namespaces

# リソースの削除 (Cluster は動いたまま、pods や LB が削除される)
$ kubectl delete -f tutorial-service.yml
$ kubectl delete -f tutorial-deployment.yml
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
ただし、kubernetes の master node は azure が管理してくれている。すごい。

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
                  +-+ Gateway (LoadBalancer)


```

## 設定ファイル

**deployment** (一般的なのか?)
コンテナアプリケーションの設定

**service**
Pod にクライアントからアクセスするためのサービス設定。クラスタと外部ネットワークとの設定を定義
この定義は、各クラウドや自分たちの環境よってことなりそう


## Immutable Infrastructure

メンテナンスしながら既存の設定を上書きしていく Mutable Infrastructure とは違い。
変更毎に新規の環境を立ち上げていく手法。古いものは破棄していく。

## 宣言的設定

Kubernetes Cluster は、定義ファイルを見て CPU やメモリのリソースを配分し、維持してくれる。
この維持してくれる機能が自己修復機能となっている。
あるべき姿を定義しておけばソフトウェア側でやってくれる模様。
API も公開されているのでコマンドを打つ必要がない。

## Kubernetes のパラダイム

デプロイするものは、kubernetes がどこに置くか決める。
**アプリケーションを見つける/適切な場所に置く仕組みが必要になっている**

### スケジューリング

アプリケーションを適切なところにデプロイする仕組み

### サービスディスカバリ

デプロイされたアプリケーションがどこにあるかを見つけ出す仕組み

### 構成

Master の API がクラスター全体を制御する

```
                    Kubernetes Cluster
+-----------------------------------------------------------------------------------------------------------+
|                                                                                                           |
|       Master                                                                                              |
|      +-----------------------------+                                                                      |
|      |               +----------+  |                                                                      |
|      | +--------+    |   etcd   |  |                                                                      |
|      | |  API   |    +----------+  |                                                                      |
|      | +-^--^--^+     kvs for cluster data                                                                |
|      |   |  |  |                   |                                                                      |
|      +-----------------------------+                                                                      |
|          |  |  |                                                                                          |
|          |  |  |                                                                                          |
|          |  |  +-----------------------------------------------------------+                              |
|          |  |                                                              |                              |
|          |  +----------------------------+                                 |                              |
|          |                               |                                 |                              |
|          |                               |                                 |                              |
|          |                               |                                 |                              |
|      +-----------------+           +------------------+          +-------------------+                    |
|      |   +--------+    |           | +-------------+  |          |    +---------+    |                    |
|      |   | kubelet|    |           | |  kubelet    |  |          |    | kubelet |    |                    |
|      |   +--------+    |           | +-------------+  |          |    +---------+    |                    |
|      |                 |           |                  |          | +--------+        |                    |
|      |   +---------+   |           |  +-----------+   |          | |        |        |                    |
|      |   | Container   |           |  |           |   |          | +--------+        |                    |
|      |   +---------+   |           |  +-----------+   |          |       +---------+ |                    |
|      |                 |           |                  |          |       |         | |                    |
|      +-----------------+           +------------------+          +-------+---------+-+                    |
|                                                                                                           |
|          Node #0                         Node #01                      Node #02                           |
|                                                                                                           |
|                                                                                                           |
|                                                                                                           |
+-----------------------------------------------------------------------------------------------------------+

```

今までの kubectl 経由の操作は、Master に向けて行われてたわけだ

### Scheduler 

Pod をどのNode で動かすかを制御するためのバックエンドコンポーネント。
ノードに割り当てられていない Pod に対してKubernetes クラスターの状態を管理し
空きスペースを持つNode を探してPodを実行させていく

### Controller Manager

クラスターの状態を監視し、あるべき状態を維持するバックエンドコンポーネント

### etcd

クラスターの構成を保持する分散KVS. Key-Value 型。
API が利用する。もちろん、認証認可の情報も入っている。

## Node

### kubelet

master の API を通信するための Agent
Pod の定義ファイルに従ってコンテナを実行したり
ストレージをマウントしたりする機能をもつ
**また、Node のステータスを定期的に監視し、Master に報告する**

## リソース関連

### Pod

アプリケーションの単位
複数 or 一つのコンテナをPod として管理する
そのため、Pod は アプリケーションコンテナとプロキシコンテナがくっついていても一つのPodとして扱える
ECS のタスクに複数のコンテナ指定できるイメージかと
アプリケーションコンテナ * fluentd コンテナとか

この Pod がアプリケーションのデプロイの単位になる
Pod 内の複数のコンテナで仮想NIC を共有する構成をとるので、コンテナ同士はlocalhost 経由で通信可能
また、ディレクトリも共有できる

ノードの中には複数の Pod が配置される

### ReplicaSet

クラスタ内で指定された数の Pod を起動しておく仕組み。

### Deployment

アプリケーションの配布単位を管理する
ReplicaSet の履歴を管理し、ローリングアップデートを行ってくれる。
また、履歴を元にロールバックすることもできる。

### DaemonSet

ログコレクタや監視エージェントのようにNode で必ず一つ動かしたいものがあるときに使う
Kubernetes のネットワークプロキシ機能である kube-proxy は DaemonSet の仕組みで動いている

### StatefulSet

ステータスをもつような Pod を管理するための仕組み。一貫性を保証してくれる。
Pod がスケールダウン時に落とされることをブロックしてくれる
mysql とか永続化を扱うPod に使うのかな ↓
https://kubernetes.io/ja/docs/tasks/run-application/run-replicated-stateful-application/

## ネットワークの管理

### サービス

Pod へアクセスするためのゲートウェイ
LB などがそれにあたる

### Ingress

L7 の機能を提供する
クラスタ外部のネットワークアクセスを受け付けるためのオブジェクト

