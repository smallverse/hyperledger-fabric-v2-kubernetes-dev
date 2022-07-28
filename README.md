# Hyperledger Fabric v2 with Raft on Kubernetes
---
My implementation for erc20/erc721 (translated from the official nodejs code) Earlier than the official implementation of erc20/erc721

https://github.com/hyperledger/fabric-samples/tree/main/token-erc-20/chaincode-go

https://github.com/hyperledger/fabric-samples/tree/main/token-erc-721/chaincode-go

---
## Prerequisites

- Kubernetes cluster with at least 4GB memory and 2 vCPUs (tested on IBM Cloud free tier IKS)
- kubectl available on path and configured to use a cluster
- Fabric binaries available on path

```shell
wget https://github.com/hyperledger/fabric/releases/download/v2.3.3/hyperledger-fabric-linux-amd64-2.3.3.tar.gz
tar -xzf hyperledger-fabric-linux-amd64-2.3.3.tar.gz
# Move to the bin path
mv bin/* /bin
# Check that you have successfully installed the tools by executing
configtxgen --version
```

## Architechture

- Three peer orgs and two orderer orgs. Peer orgs too run an orderer each.
- Each org components are deployed in org's own namespace
- crypto materials generated by cryptogen
- crypto materials and channel-artifacts are mounted as k8s Secret
- Fabric CA stores data in Postgres (in this demo in sqlite)
- Fabric peer uses couchdb as state db. CouchDB is deployed in a separate pod (in this demo same pod as peer itself)

![hyperledger-fabric-network](http://www.plantuml.com/plantuml/proxy?cache=no&src=https://raw.githubusercontent.com/blockchaind/hyperledger-fabric-v2-kubernetes-dev/master/network-diagram.puml)

## Network KV

Start

```bash
./hlf.sh up
```

Have peers joined to channel. Ensure all components are up and running.

```bash
./hlf.sh joinChannel
```

Chaincode lifecycle

```bash
./hlf.sh ccInstall
./hlf.sh ccApprove
./hlf.sh ccCommit
#
./hlf.sh explorerAndAPI

./hlf.sh ccInvoke ''         # 
./hlf.sh ccQuery  ''        # 
./hlf.sh ccInvoke ''   # 
./hlf.sh ccQuery   ''       # 
```
## Network erc721
```shell
./hlf-erc721.sh up
./hlf-erc721.sh joinChannel

#
./hlf-erc721.sh ccInstall # 安装，通过
./hlf-erc721.sh ccApprove
./hlf-erc721.sh ccCommit

./hlf-erc721.sh explorerAndAPI
#
# 如'{"function":"MintWithTokenURI","Args":["101", "http://172.16.3.20:32000/test/000.jpg"]}'
./hlf-erc721.sh ccInvoke 'xxx' 
#
# 如 '{"function":"ClientAccountBalance","Args":[]}' 
# '{"function":"BalanceOf","Args":["xxx"]}' 
# '{"function":"ClientAccountID","Args":[]}' 
./hlf-erc721.sh ccQuery 'xxx' 

#
./hlf-erc721.sh down
```
## Explorer & Rest API

Start explorer db

explorer should now be available at <http://localhost:8080>

Access API Swagger UI at <http://localhost:3000/swagger>

## TODO
```
1.Custom protection through encryption mechanism. (通过加密机制实现自定义保护。)
2. The chain code does the encryption and decryption itself.(链码自行完成加密解密。)
```


