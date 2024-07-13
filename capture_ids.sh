#!/bin/sh

# Run the original command and capture the output
cd /app/fendermint
echo "Creating validator..."
bootstrap_output=$(cargo make --makefile ./infra/fendermint/Makefile.toml \
    -e NODE_NAME=${NODE_NAME} \
    -e PRIVATE_KEY_PATH=${PRIVATE_KEY_PATH} \
    -e SUBNET_ID=${SUBNET_ID} \
    -e CMT_P2P_HOST_PORT=${CMT_P2P_HOST_PORT} \
    -e CMT_RPC_HOST_PORT=${CMT_RPC_HOST_PORT} \
    -e ETHAPI_HOST_PORT=${ETHAPI_HOST_PORT} \
    -e RESOLVER_HOST_PORT=${RESOLVER_HOST_PORT} \
    -e PARENT_REGISTRY=${PARENT_REGISTRY} \
    -e PARENT_GATEWAY=${PARENT_GATEWAY} \
    -e FM_PULL_SKIP=1 \
    child-validator 2>&1)

echo "$bootstrap_output"

# Extract the CometBFT node ID and IPLD Resolver Multiaddress
bootstrap_node_id=$(echo "$bootstrap_output" | sed -n '/CometBFT node ID:/ {n;p;}' | tr -d "[:blank:]")
bootstrap_peer_id=$(echo "$bootstrap_output" | sed -n '/IPLD Resolver Multiaddress:/ {n;p;}' | tr -d "[:blank:]" | sed 's/.*\/p2p\///')

# Append the extracted information to the .env file
if [ -w /root/.env ]; then
  echo "" >> /root/.env  # Add newline
  echo "BOOTSTRAP_NODE_ID=$bootstrap_node_id" >> /root/.env

  echo "" >> /root/.env  # Add newline
  echo "BOOTSTRAP_PEER_ID=$bootstrap_peer_id" >> /root/.env
else
  echo "Error: Cannot write to /root/.env"
  exit 1
fi

# Keep the container running
tail -f /dev/null
