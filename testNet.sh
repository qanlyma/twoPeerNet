#!/bin/bash

## Parse mode
if [[ $# -lt 1 ]] ; then
  echo "errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr"
  exit 0
else
  MODE=$1
  AC=$2
fi

function networkUp() {
  echo "===========================================Starting Test Network==========================================="

  echo "Generating files..."

  export PATH=$PWD/bin:/bin:/usr/bin
  cryptogen generate --config=crypto-config.yaml
  configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID test-channel
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP

  echo "Starting docker containers..."

  docker-compose up -d
  sleep 3

  echo "Creating mychannel..."

  docker exec cli1 peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker cp cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer/mychannel.block ./
  docker cp ./mychannel.block cli2:/opt/gopath/src/github.com/hyperledger/fabric/peer
  docker exec cli1 peer channel join -b mychannel.block
  docker exec cli2 peer channel join -b mychannel.block
  docker exec cli1 peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker exec cli2 peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

  echo "Installing test chaincode..."

  docker cp ./simple.tar.gz cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer
  docker cp ./simple.tar.gz cli2:/opt/gopath/src/github.com/hyperledger/fabric/peer

  docker exec cli1 peer lifecycle chaincode install simple.tar.gz
  docker exec cli2 peer lifecycle chaincode install simple.tar.gz

  docker exec cli1 peer lifecycle chaincode approveformyorg --channelID mychannel --name simple --version 1.0 --init-required --package-id simple_1.0:fd64e745f61cd4efa745f701541d77068b5fd92f2a0189447ca230e1f5f48a65 --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker exec cli2 peer lifecycle chaincode approveformyorg --channelID mychannel --name simple --version 1.0 --init-required --package-id simple_1.0:fd64e745f61cd4efa745f701541d77068b5fd92f2a0189447ca230e1f5f48a65 --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker exec cli1 peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID mychannel --name simple --version 1.0 --init-required --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
 
  echo "Initializing the chaincode..."

  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --isInit --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":[]}'

  cd crypto-config
  ./ccp-generate.sh
}

COMMAND="docker exec cli1 peer chaincode invoke \
    -o orderer.example.com:7050 \
    -C mychannel \
    -n simple \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls true \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --peerAddresses peer0.org1.example.com:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses peer0.org2.example.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

function createAccount() {
  echo "Opening new account ..."
  $COMMAND -c '{"Args":["open","A","1000"]}'
  $COMMAND -c '{"Args":["open","B","1000"]}'
  $COMMAND -c '{"Args":["open","C","1000"]}'
  $COMMAND -c '{"Args":["open","D","1000"]}'
  $COMMAND -c '{"Args":["open","E","1000"]}'
  $COMMAND -c '{"Args":["open","F","1000"]}'
}

function sendTransactions() {
  echo "Sending..."
  $COMMAND -c '{"Args":["transfer","A","B","100"]}'
  # $COMMAND -c '{"Args":["transfer","A","B","100"]}'
  # $COMMAND -c '{"Args":["transfer","A","C","100"]}'
  # $COMMAND -c '{"Args":["transfer","D","A","100"]}'
}

function testReorder() {
  echo "Testing..."
  $COMMAND -c '{"Args":["raw2","A","B"]}'
  $COMMAND -c '{"Args":["raw2","C","D"]}'
  $COMMAND -c '{"Args":["raw2","B","F"]}'
  $COMMAND -c '{"Args":["raw2","B","C"]}'
  $COMMAND -c '{"Args":["raw2","B","C"]}'
}

function queryAccount() {
  if [[ -z $AC ]]; then
    docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","c"]}'
    docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","e"]}'
    docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","g"]}'
    docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","g"]}'
  else 
    docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query", "'"$AC"'"]}'
  fi
}

function cli1() {
  docker exec -it cli1 bash
}

function networkDown() {
  echo "===========================================Ending Test Network==========================================="

  echo "Stoping and Pruning fabric dockers..."
  docker ps -a | awk '/fabric/ {print $1}' | xargs -r docker stop
  docker ps -a | awk '/dev/ {print $1}' | xargs -r docker stop
  docker ps -a | awk '/fabric/ {print $1}' | xargs -r docker rm -f
  docker ps -a | awk '/dev/ {print $1}' | xargs -r docker rm -f
  docker volume prune -f
  docker network rm fabric_test
  docker rmi $(docker images | grep dev)
  docker image prune -f

  echo "Removing files..."
  rm -rf ./channel-artifacts
  rm -rf ./crypto-config/ordererOrganizations
  rm -rf ./crypto-config/peerOrganizations
  rm ./mychannel.block
}

if [ "$MODE" == "up" ]; then
  networkUp
elif [ "$MODE" == "down" ]; then
  networkDown
elif [ "$MODE" == "open" ]; then
  createAccount
elif [ "$MODE" == "send" ] || [ "$MODE" == "s" ]; then
  sendTransactions
elif [ "$MODE" == "test" ] || [ "$MODE" == "t" ]; then
  testReorder
elif [ "$MODE" == "query" ] || [ "$MODE" == "q" ]; then
  queryAccount
elif [ "$MODE" == "client" ] || [ "$MODE" == "c" ]; then
  cli1
else
  echo "errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr"
  exit 1
fi

echo "====================================================Done===================================================="
