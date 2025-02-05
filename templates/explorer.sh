CHANNEL_ID=$1
cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: explorer
  name: explorer
  namespace: org1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: explorer
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: explorer
    spec:
      volumes:
      - name: admin
        secret:
          secretName: admin
          items:
          - key: config.yaml
            path: config.yaml
          - key: key.pem
            path: keystore/key.pem
          - key: cert.pem
            path: signcerts/cert.pem
          - key: tlsca-cert.pem
            path: tlsca/tlsca-cert.pem
          - key: ca-cert.pem
            path: cacerts/ca-cert.pem
          - key: tls.crt
            path: tls/client.crt
          - key: tls.key
            path: tls/client.key
      containers:
      - image: hyperledger/explorer:latest
        name: explorer
        resources: {}
        env:
        - name: DATABASE_HOST
          value: explorerdb
        - name: DATABASE_USERNAME
          value: hppoc
        - name: DATABASE_PASSWD
          value: password
        - name: LOG_LEVEL_APP
          value: debug
        - name: LOG_LEVEL_DB
          value: debug
        - name: LOG_LEVEL_CONSOLE
          value: info
        - name: LOG_CONSOLE_STDOUT
          value: "true"
        - name: DISCOVERY_AS_LOCALHOST
          value: "false"
        volumeMounts:
        - name: admin
          mountPath: "/etc/hyperledger/fabric-peer/adminmsp"
        command:
        - "sh"
        - "-c"
        - |
          cat > /opt/explorer/app/platform/fabric/config.json <<EOF
          {
            "network-configs": {
              "fabnetv2": {
                "name": "fabnetv2",
                "profile": "/var/hyperledger/conn.cluster.json"
              }
            },
            "license": "Apache-2.0"
          }
          EOF
          mkdir -p /var/hyperledger
          cd /var/hyperledger
          cat > /var/hyperledger/conn.cluster.json <<EOF
          {
            "name": "fabnetv2",
            "version": "1.0.0",
            "client": {
              "tlsEnable": true,
              "adminCredential": {
                "id": "admin",
                "password": "adminpw"
              },
              "enableAuthentication": false,
              "organization": "Org1MSP",
              "connection": {
                "timeout": {
                  "peer": {
                    "endorser": "300"
                  },
                  "orderer": "300"
                }
              }
            },
            "channels": {
              "${CHANNEL_ID}": {
                "peers": {
                  "peer0.org1": {}
                },
                "connection": {
                  "timeout": {
                    "peer": {
                      "endorser": "6000"
                    }
                  }
                }
              }
            },
            "organizations": {
              "Org1MSP": {
                "mspid": "Org1MSP",
                "fullpath": true,
                "adminPrivateKey": {
                  "path": "/etc/hyperledger/fabric-peer/adminmsp/keystore/key.pem"
                },
                "signedCert": {
                  "path": "/etc/hyperledger/fabric-peer/adminmsp/signcerts/cert.pem"
                },
                "peers": ["peer0.org1"]
              }
            },
            "peers": {
              "peer0.org1": {
                "tlsCACerts": {
                  "path": "/etc/hyperledger/fabric-peer/adminmsp/tlsca/tlsca-cert.pem"
                },
                "url": "grpcs://peer0.org1:7051",
                "grpcOptions": {
                  "ssl-target-name-override": "peer0.org1"
                }
              }
            }
          }
          EOF
          cd /opt/explorer
          npm run app-start && tail -f /dev/null
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: explorer
  name: explorer
  namespace: org1
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: explorer
  type: NodePort

EOF
