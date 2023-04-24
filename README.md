# Cederpay_contract
 To be deployed on Hedera test net using Hardhat.
 
 # Testing the contract with Hardhat
 
 Install Hardhat globally by running the following command in your terminal:
 
```
npm install -g hardhat
```

Create a new Solidity contract under the contracts/ folder in your Hardhat project directory with the code I provided earlier.

Inside the Hardhat project directory, generate a new test file in a /test folder using the following command:

```
npx hardhat generate-test-file
```

Open the generated test file test/sample-test.js and replace its content with the following:

```
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Collateralized Token Contract", function () {
  let hBarToken, collateralizedToken;

  beforeEach(async function () {
    const HbarToken = await ethers.getContractFactory("HbarToken");
    hBarToken = await HbarToken.deploy();
    await hBarToken.deployed();

    const CollateralizedToken = await ethers.getContractFactory("CollateralizedToken");
    collateralizedToken = await CollateralizedToken.deploy(hBarToken.address, 2);
    await collateralizedToken.deployed();

    await hBarToken.mint(collateralizedToken.address, 100 * 10**8);
    await hBarToken.mint("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", 1000 * 10**8);
  });

  it("Deploys and initializes values", async function () {
    expect(await collateralizedToken.name()).to.equal("Collateralized Token");
    expect(await collateralizedToken.symbol()).to.equal("COLL");
    expect(await collateralizedToken.decimals()).to.equal(8);
    expect(await collateralizedToken.totalSupply()).to.equal(0);
    expect(await collateralizedToken.balanceOf("0x627306090abaB3A6e1400e9345bC60c78a8BEf57")).to.equal(0);
    expect(await hBarToken.balanceOf(collateralizedToken.address)).to.equal(100 * 10**8);
  });

  it("Adds collateral correctly", async function () {
    await collateralizedToken.addCollateral(100);
    expect(await hBarToken.balanceOf(collateralizedToken.address)).to.equal(200 * 10**8);
    expect(await collateralizedToken.totalSupply()).to.equal(0);
  });

  it("Withdraws collateral correctly", async function () {
    await collateralizedToken.addCollateral(100);
    expect(await hBarToken.balanceOf(collateralizedToken.address)).to.equal(200 * 10**8);

    await collateralizedToken.withdrawCollateral(50);
    expect(await hBarToken.balanceOf(collateralizedToken.address)).to.equal(150 * 10**8);
  });

  it("Transfers tokens correctly", async function () {
    await collateralizedToken.addCollateral(100);
    await collateralizedToken.transfer("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", 10);
    expect(await collateralizedToken.balanceOf("0x627306090abaB3A6e1400e9345bC60c78a8BEf57")).to.equal(10);
  });

  it("Fails to transfer if there's not enough balance", async function () {
    await expect(collateralizedToken.transfer("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", 10)).to.be.reverted;
  });

  it("Mints tokens and adds the required collateral", async function () {
    expect(await collateralizedToken.totalSupply()).to.equal(0);
    await collateralizedToken.mint("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", 10);
    expect(await collateralizedToken.balanceOf("0x627306090abaB3A6e1400e9345bC60c78a8BEf57")).to.equal(10);
    expect(await collateralizedToken.totalSupply()).to.equal(10);

    await expect(collateralizedToken.mint("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", 20)).to.be.reverted;

    await expect(collateralizedToken.mint("0x627306090abaB3A6e1400e9345bC60c78a8BEf57", 10)).to.be.reverted;
  });
});
```

In the terminal, run the following command to compile the contracts:

```
npx hardhat compile
```

Finally, run the test suite by running:

```
npx hardhat test
```
 
 
# Deploying the smart contract

 Run the following command to create a new Hardhat project:

```npx hardhat init```

To use the Hedera network, you need to install the @hashgraph/sdk package. You can install it by running the following command from your project root directory:

```npm install @hashgraph/sdk```

Open the hardhat.config.js file and add the following lines to your module.exports object:

```
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@typechain/hardhat");
require("dotenv").config();

const { HEDERA_NETWORK, HEDERA_ACCOUNT_ID, HEDERA_PRIVATE_KEY } = process.env;

task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

module.exports = {
  solidity: "0.8.0",
  networks: {
    hardhat: {},
    testnet: {
      url: `https://${HEDERA_NETWORK}.testnet.hedera.com:50211`,
      accounts: [HEDERA_PRIVATE_KEY],
    },
    mainnet: {},
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};
```


Create a .env file in the root directory of your project, and add your Hedera account ID, private key, and network:

```
HEDERA_NETWORK=testnet
HEDERA_ACCOUNT_ID=<Your Hedera Account ID>
HEDERA_PRIVATE_KEY=<Your Hedera Private Key>
```

You can now run the following command to deploy your Solidity smart contract to the Hedera testnet:

```
npx hardhat run --network testnet scripts/deploy.js
```

deploy.js:

```
const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  // Retrieve the provider and the signer from the Hardhat runtime
  const provider = ethers.provider;
  const signer = ethers.provider.getSigner();

  // Compile the contract
  const factory = await ethers.getContractFactory("CollateralizedToken");
  console.log("Contract compiled");

  // Deploy the contract
  const contract = await factory.deploy(hBarTokenAddress, 2);
  console.log(`Contract deployed to address: ${contract.address}`);

  // Verify the contract on Etherscan (optional)
  await contract.verify();

  // Write the contract address to a file
  fs.writeFileSync("contract-address.txt", contract.address);

  // Print the contract's ABI (optional)
  const abi = JSON.stringify(contract.interface.abi, null, 2);
  console.log(`Contract ABI:\n${abi}`);
}

// Run the deploy function
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```
