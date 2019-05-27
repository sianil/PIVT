#!/bin/bash

# creates genesis block and channel artifacts
# and copies them to hlf-kube/ folder

if test "$#" -ne 2; then
   echo "usage: init.sh <project_folder> <chaincode_folder>"
   exit 2
fi

project_folder=$1
chaincode_folder=$2

current_folder=$(pwd)

cd $project_folder
config_file=./network.yaml

rm -rf crypto-config
rm -rf channel-artifacts

mkdir -p channel-artifacts

# generate certs
echo "-- creating certificates  --"
cryptogen generate --config ./crypto-config.yaml --output crypto-config

# generate genesis block
echo "-- creating genesis block  --"
genesisProfile=$(yq ".network.genesisProfile" $config_file -r)
configtxgen -profile $genesisProfile -outputBlock ./channel-artifacts/genesis.block

channels=$(yq ".network.channels[]" $config_file -c)
for channelInfo in $channels; do
  echo $channelInfo

  channel=$(echo $channelInfo | jq -c -r '.name')
  orgs=$(echo $channelInfo | jq -c -r '.orgs')

  echo "channel: $channel"
  echo "orgs: $orgs"

  mkdir -p ./channel-artifacts/$channel

  echo "-- creating channel TX for channel $channel --"
  configtxgen -profile $channel -outputCreateChannelTx ./channel-artifacts/$channel/$channel.tx -channelID $channel

    for org in $(echo $orgs | jq -c -r '.[]'); do
      echo "-- creating anchor peer TX for channel $channel org: $org --"
      configtxgen -profile $channel -outputAnchorPeersUpdate ./channel-artifacts/$channel/"$org"MSPanchors.tx -channelID $channel -asOrg "$org"MSP
    done

done

# copy stuff hlf-kube folder (as helm charts cannot access files outside of chart folder)
# see https://github.com/helm/helm/issues/3276#issuecomment-479117753
cd $current_folder

rm -rf hlf-kube/crypto-config
rm -rf hlf-kube/channel-artifacts

cp -r $project_folder/crypto-config hlf-kube/
cp -r $project_folder/channel-artifacts hlf-kube/

# prepare chaincodes
./prepare_chaincodes.sh $project_folder $chaincode_folder
