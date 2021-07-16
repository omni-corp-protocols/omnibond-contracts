import hre from "hardhat";
import { writeFileSync, readFileSync } from "fs";

const outputFilePath = `./deployments/${hre.network.name}.json`;

async function main() {
  const BondFactory = await hre.ethers.getContractFactory("BondFactory");
  const bondFactory = await BondFactory.deploy();
  await bondFactory.deployed();
  console.log("BondFactory deployed to:", bondFactory.address);

  let output = JSON.parse(readFileSync(outputFilePath, 'utf-8'));
  output.BondFactory = bondFactory.address;
  writeFileSync(outputFilePath, JSON.stringify(output, null, 2));

  console.log(output)
  console.log(output.Bond)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
