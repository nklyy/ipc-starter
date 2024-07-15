#!/bin/sh

# Init config
echo "Initialization config."
ipc-cli config init
echo "Congif inited"
echo

# Update gateway_addr and registry_addr in config.toml
config_file=/root/.ipc/config.toml

sed -i "/\[\[subnets\]\]/,/^\[\[/ {
    /^\[subnets.config\]/!b
    :a
    n
    /^\[/! {
        s/^gateway_addr = .*/gateway_addr = \"0x6d25fbFac9e6215E03C687E54F7c74f489949EaF\"/
        s/^registry_addr = .*/registry_addr = \"0xc938B2B862d4Ef9896E641b3f1269DabFB2D2103\"/
        ba
    }
}" "$config_file" 

# Create evm_keystore.json if it doesn't exist with an empty array
if [ ! -f /root/.ipc/evm_keystore.json ]; then
    echo "[]" > /root/.ipc/evm_keystore.json  # Initialize with an empty JSON array
    echo "Created evm_keystore.json"
else
    echo "evm_keystore.json already exists"
fi
echo

# Remove SUBNET_ID, BOOTSTRAP_NODE_ID, and BOOTSTRAP_PEER_ID from .env file if they exist
if [ -f /root/.env ]; then
    echo "Removing SUBNET_ID, BOOTSTRAP_NODE_ID, and BOOTSTRAP_PEER_ID from .env file if they exist"
    awk '!/^SUBNET_ID=/ && !/^BOOTSTRAP_NODE_ID=/ && !/^BOOTSTRAP_PEER_ID=/' /root/.env > /root/.env.tmp
    cat /root/.env.tmp > /root/.env  # Overwrite .env atomically
    rm /root/.env.tmp
    echo "SUBNET_ID, BOOTSTRAP_NODE_ID, and BOOTSTRAP_PEER_ID removed from .env file"
else
    echo ".env file does not exist"
fi
echo

# Create 3 new wallets
if [ -f /root/.ipc/validator_1.sk ]; then
    ADDRESS1=$(ipc-cli wallet import --wallet-type evm --private-key $(cat /root/.ipc/validator_1.sk) | tr -d '"')
else
    ADDRESS1=$(ipc-cli wallet new --wallet-type evm | tr -d '"')
fi

if [ -f /root/.ipc/validator_2.sk ]; then
    ADDRESS2=$(ipc-cli wallet import --wallet-type evm --private-key $(cat /root/.ipc/validator_2.sk) | tr -d '"')
else
    ADDRESS2=$(ipc-cli wallet new --wallet-type evm | tr -d '"')
fi

if [ -f /root/.ipc/validator_3.sk ]; then
    ADDRESS3=$(ipc-cli wallet import --wallet-type evm --private-key $(cat /root/.ipc/validator_3.sk) | tr -d '"')
else
    ADDRESS3=$(ipc-cli wallet new --wallet-type evm| tr -d '"')
fi

echo "Wallet Addresses:"
echo "Address 1: $ADDRESS1"
echo "Address 2: $ADDRESS2"
echo "Address 3: $ADDRESS3"

# Set one of the wallets as default (optional)
echo Setting $wallet1 as default wallet address
ipc-cli wallet set-default --address $ADDRESS1 --wallet-type evm
echo

# Check the balances and wait until topped up from the faucet
echo For each address above go send some funds to it at the faucet at:
echo https://faucet.calibnet.chainsafe-fil.io/funds.html
echo https://beryx.io/faucet
while true; do
    wallet_balances=$(ipc-cli wallet balances --subnet /r314159 --wallet-type evm)
    my_wallet_balances=$(echo "$wallet_balances" | egrep "$ADDRESS1|$ADDRESS2|$ADDRESS3" | sort)
    echo "$my_wallet_balances"

    if echo "$my_wallet_balances" | awk '{if ($4 <= 10) exit 1}'; then
	echo "All wallets are funded!"
	echo
	break
    else
	echo "Waiting on all wallets to be funded"
    fi

    echo
    sleep 15
done

# Create a child subnet and capture the subnet ID
echo "Creating the subnet"
SUBNET_LOG=$(ipc-cli subnet create --parent /r314159 --min-validator-stake 1 --min-validators 3 --bottomup-check-period 300 --from $ADDRESS1 --permission-mode collateral --supply-source-kind native)
echo "$SUBNET_LOG"

SUBNET_ID=$(echo "$SUBNET_LOG" | grep -oP '(?<=created subnet actor with id: ).*')

echo "Created Subnet ID: $SUBNET_ID"
echo

# Join the subnet with each validator
echo "Joining subnets"
ipc-cli subnet join --from=$ADDRESS1 --subnet=$SUBNET_ID --collateral=10 --initial-balance=1
ipc-cli subnet join --from=$ADDRESS2 --subnet=$SUBNET_ID --collateral=10 --initial-balance=1
ipc-cli subnet join --from=$ADDRESS3 --subnet=$SUBNET_ID --collateral=10 --initial-balance=1
echo

# Export the validator private keys to files
echo "Exporting private keys"
ipc-cli wallet export --wallet-type evm --address $ADDRESS1 --hex > /root/.ipc/validator_1.sk
ipc-cli wallet export --wallet-type evm --address $ADDRESS2 --hex > /root/.ipc/validator_2.sk
ipc-cli wallet export --wallet-type evm --address $ADDRESS3 --hex > /root/.ipc/validator_3.sk
echo

# Output completion message
echo "Initialization complete. Validators have joined the subnet."
echo "Subnet created: ${SUBNET_ID}"

# Ensure newline before appending SUBNET_ID
if [ -w /root/.env ]; then
  echo "" >> /root/.env  # Add newline
  echo "SUBNET_ID=$SUBNET_ID" >> /root/.env
else
  echo "Error: Cannot write to /root/.env"
  exit 1
fi

# Uncomment and update the subnet template in config.toml
sed -i '' -e "/# \[\[subnets\]\]/,/# registry_addr/ {
    s/^# //
    s|id = \"/r314159/<SUBNET_ID>\"|id = \"$SUBNET_ID\"|
    s|<RPC_ADDR>|localhost:8545/|
}" "$config_file"

echo "Initialization complete. Validators have joined the subnet."
echo "Subnet created: ${SUBNET_ID}"
echo "IPC-CLI installed successfully."
echo "SUBNET_ID set in .env file"
echo "/root/.ipc/config.toml has modified to you new SUBNET_ID"

# Keep the container running
tail -f /dev/null