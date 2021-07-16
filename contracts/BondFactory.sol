// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Bond.sol";

contract BondFactory is Ownable {
    event NewBondCreated(address indexed bond);

    address[] public bonds;

    function createBond(
        address _pancakeRouter,
        address _tokenFrom,
        address _tokenTo,
        string memory _name,
        string memory _symbol
    ) public onlyOwner returns (address newBond) {
        Bond bond = new Bond(_pancakeRouter, _tokenFrom, _tokenTo, _name, _symbol);
        bond.transferOwnership(msg.sender);

        bonds.push(address(bond));
        emit NewBondCreated(address(bond));
        return address(bond);
    }

    function getAllBonds() public view returns (address[] memory) {
        return bonds;
    }
}
