Sure, here's a detailed step-by-step guide on setting up IPC in a Docker environment.

## Prerequisites

1. **Docker**: Ensure Docker is installed on your server. You can download it from [Docker's official website](https://www.docker.com/get-started).
2. **Docker Compose**: Ensure Docker Compose is installed. You can follow the installation instructions from [Docker's official documentation](https://docs.docker.com/compose/install/).

## Step-by-Step Guide

### 1. Clone the Repository

First, clone the repository that contains the IPC setup:

```bash
git clone https://github.com/nklyy/ipc-starter.git
cd ipc-starter
```

### 2. Run IPC-CLI

Next, use Docker Compose to start the IPC-CLI:

```bash
docker-compose up ipc-cli
```

Wait until you see the message `IPC-CLI installed successfully` and the following message:

```
For each address above go send some funds to it at the faucet at
```

### 3. Fund the Addresses

1. Copy the three addresses displayed in the IPC-CLI logs.
2. Visit [the faucet](https://faucet.calibnet.chainsafe-fil.io/funds.html).
3. Paste each address one by one and request funds.
4. Wait until all addresses are funded.

### 4. Run Bootstrap

Now, start the bootstrap process to pull all necessary libraries and dependencies:

```bash
docker-compose up bootstrap
```

Wait until the process completes successfully and exits with a `0` code.

### 5. Start Validator-1

Once the bootstrap process is complete, start the first validator:

```bash
docker-compose up validator-1
```

Wait until you see the message `Subnet is ready`.

### 6. Start the Remaining Validators

Finally, start the remaining validators one by one:

```bash
docker-compose up validator-2
docker-compose up validator-3
```

### Summary of Commands

```bash
# Clone the repository
git clone https://github.com/nklyy/ipc-starter.git
cd ipc-starter

# Run IPC-CLI
docker-compose up ipc-cli

# Fund addresses using the faucet
# (Visit the faucet link and fund the addresses displayed in IPC-CLI logs)

# Run bootstrap
docker-compose up bootstrap

# Start Validator-1
docker-compose up validator-1

# Start remaining validators
docker-compose up validator-2
docker-compose up validator-3
```

By following these steps, you should be able to set up IPC in a Docker environment successfully. If you encounter any issues, make sure to check the logs for error messages and ensure all prerequisites are met.