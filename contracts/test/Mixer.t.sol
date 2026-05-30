//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { Mixer } from "../src/Mixer.sol";
import { HonkVerifier } from "../src/Verifier.sol";
import { IncrementalMerkleTree, Poseidon2 } from "../src/IncrementalMerkleTree.sol";

contract MixerTest is Test {

    Mixer public mixer;
    HonkVerifier public verifier;
    Poseidon2 public hasher;

    uint32 public constant MERKLE_TREE_DEPTH = 20;

    address public recipient = makeAddr("user");

    function setUp() public {
        hasher = new Poseidon2();
        verifier = new HonkVerifier();

        mixer = new Mixer(verifier, MERKLE_TREE_DEPTH, hasher);
    }

    function _getCommitment() public returns(bytes32 _commitment, bytes32 _nullifier, bytes32 _secret){
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateCommitment.ts";

        bytes memory result = vm.ffi(inputs);

        (_commitment, _nullifier, _secret) = abi.decode(result, (bytes32, bytes32, bytes32));
    }

   
    

    function testDeposit() public {
        (bytes32 _commitment,,) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(_commitment);

        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: 0.001 ether}(_commitment);
        assertEq(address(mixer).balance, 0.001 ether);
    }

   
}