import hre from "hardhat";
import { writeFileSync } from "fs";
import { numToWei } from "../utils/ethUnitParser";

const outputFilePath = `./deployments/${hre.network.name}.json`;

const pancakeRouter = "0x10ed43c718714eb63d5aa57b78b54704e256024e";
const busd = "0xe9e7cea3dedca5984780bafc599bd69add087d56";
const usdo = "0x5801d0e1c7d977d78e4890880b8e579eb4943276";
const name = "Test Bond";
const symbol = "tBOND";

async function main() {
  const Bond = await hre.ethers.getContractFactory("Bond");
  const bond = await Bond.deploy(pancakeRouter, busd, usdo, name, symbol);
  await bond.deployed();
  console.log("Bond deployed to:", bond.address);

  const output = {
    Bond: bond.address,
  };
  writeFileSync(outputFilePath, JSON.stringify(output, null, 2));

  console.log("updating price");
  await bond.updatePrice({
    gasLimit: 100000,
  });
  const busdI = await hre.ethers.getContractAt("IERC20", busd);
  console.log("approving busd");
  await busdI.approve(bond.address, hre.ethers.constants.MaxUint256);
  console.log("bond.deposit");
  await bond.deposit(numToWei("1", "18"), {
    gasLimit: 500000,
  });
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
