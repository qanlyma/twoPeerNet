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
  docker cp ./smallbank.tar.gz cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer
  docker cp ./smallbank.tar.gz cli2:/opt/gopath/src/github.com/hyperledger/fabric/peer
  docker cp ./simple.tar.gz cli1:/opt/gopath/src/github.com/hyperledger/fabric/peer
  docker cp ./simple.tar.gz cli2:/opt/gopath/src/github.com/hyperledger/fabric/peer

  docker exec cli1 peer lifecycle chaincode install smallbank.tar.gz
  docker exec cli2 peer lifecycle chaincode install smallbank.tar.gz
  docker exec cli1 peer lifecycle chaincode install simple.tar.gz
  docker exec cli2 peer lifecycle chaincode install simple.tar.gz

  docker exec cli1 peer lifecycle chaincode approveformyorg --channelID mychannel --name smallbank --version 1.0 --init-required --package-id smallbank_1.0:611176658aba373b4865f78e7e7cdbdfd3df0cfd606bc692475e6af941c12575 --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker exec cli2 peer lifecycle chaincode approveformyorg --channelID mychannel --name smallbank --version 1.0 --init-required --package-id smallbank_1.0:611176658aba373b4865f78e7e7cdbdfd3df0cfd606bc692475e6af941c12575 --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker exec cli1 peer lifecycle chaincode approveformyorg --channelID mychannel --name simple --version 1.0 --init-required --package-id simple_1.0:e2910786738edd3bcd2d85dde90151af5343157c9f521be5def7b88a285fc4ac --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  docker exec cli2 peer lifecycle chaincode approveformyorg --channelID mychannel --name simple --version 1.0 --init-required --package-id simple_1.0:e2910786738edd3bcd2d85dde90151af5343157c9f521be5def7b88a285fc4ac --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  
  docker exec cli1 peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID mychannel --name smallbank --version 1.0 --init-required --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
  docker exec cli1 peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID mychannel --name simple --version 1.0 --init-required --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
 
  echo "Initializing the chaincode..."
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --isInit --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":[]}'
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --isInit --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":[]}'

  sleep 3
  createAccount

  sleep 3
  sendTransactions

  cd crypto-config
  ./ccp-generate.sh
}

function createAccount() {
  echo "Opening new account A..."
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["open","A","1000"]}'
  echo "Opening new account B..."
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["open","B","1000"]}'
  echo "Opening new account C..."
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["open","C","1000"]}'
  # echo "Opening new account D..."
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["open","D","1000"]}'
  
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["create_account","A","A","1000","1000"]}'
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["create_account","B","B","1000","1000"]}'
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["create_account","C","C","1000","1000"]}'
}

function sendTransactions() {
  echo "Transfering1: A>>>100>>>B"
  # # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","100","B","A"]}'
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","A","B","100"]}'
  # echo "Transfering1: A>>>100>>>B"
  # # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","100","B","A"]}'
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","A","B","100"]}'
  # echo "Transfering2: B>>>100>>>C"
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","B","C","100"]}'
  # echo "Opening new account Z..."
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["open","Z","1000"]}'
  # echo "Transfering3: C>>>100>>>D"
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","C","D","100"]}'
  # echo "Transfering4: D>>>100>>>A"
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transferm","D","A","100"]}'
}

function sendSingle() {
  echo "Transfering..."
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["test","A","B"]}'
  docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n smallbank --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["send_payment","200","C","A"]}'
  # docker exec cli1 peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n simple --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["transfer","A","D","200"]}'
}

function queryAccount() {
  if [[ -z $AC ]]; then
    # docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","A"]}'
    # docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","B"]}'
    # docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","C"]}'
    # docker exec cli1 peer chaincode query -C mychannel -n simple -c '{"Args":["query","D"]}'
    docker exec cli1 peer chaincode query -C mychannel -n smallbank -c '{"Args":["query","A"]}'
    docker exec cli1 peer chaincode query -C mychannel -n smallbank -c '{"Args":["query","B"]}'
    docker exec cli1 peer chaincode query -C mychannel -n smallbank -c '{"Args":["query","C"]}'
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
elif [ "$MODE" == "test" ] || [ "$MODE" == "t" ]; then
  sendTransactions
elif [ "$MODE" == "send" ] || [ "$MODE" == "s" ]; then
  sendSingle
elif [ "$MODE" == "query" ] || [ "$MODE" == "q" ]; then
  queryAccount
elif [ "$MODE" == "client" ] || [ "$MODE" == "c" ]; then
  cli1
else
  echo "errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr"
  exit 1
fi

echo "====================================================Done===================================================="