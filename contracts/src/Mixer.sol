//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IVerifier } from "./Verifier.sol";
import { IncrementalMerkleTree, Poseidon2 } from "./IncrementalMerkleTree.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";

contract Mixer is IncrementalMerkleTree, ReentrancyGuard{

    IVerifier public immutable i_verifier;

    mapping(bytes32 => bool) public s_commitments;
    mapping(bytes32 => bool) public s_nullifierHashes;

    uint256 public constant DENOMINATION = 0.001 ether;

    event Deposit(bytes32 indexed commitment, uint32 indexInserted, uint256 time);
    event Withdrawal(address indexed recipient, bytes32 nullifierHash);

    error Mixer__InvalidAmount(uint256 amountSent, uint256 amountExpected);
    error Mixer__CommitmentAlreadyAdded(bytes32 commitment);
    error Mixer__RootMismatch(bytes32 givenRoot);
    error Mixer__NullifierAlreadyUsed(bytes32 usedNullifier);
    error Mixer__InvalidProof();      
    error Mixer__TransferFailed(address recipient, uint256 amount);

    constructor(IVerifier _verifier, uint32 _merkleTreeDepth, Poseidon2 _hasher) IncrementalMerkleTree(_merkleTreeDepth, _hasher){ 
        i_verifier = _verifier;
    }

    function deposit(bytes32 _commitment) payable external nonReentrant{
        if(msg.value != 0.001 ether){
            revert Mixer__InvalidAmount(msg.value, DENOMINATION);
        }
        if(s_commitments[_commitment]){
            revert Mixer__CommitmentAlreadyAdded(_commitment);
        }
        uint32 insertedIndex = _insert(_commitment);
        s_commitments[_commitment] = true;

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address _recipient) external nonReentrant{
        if(!isKnownRoot(_root)){
            revert Mixer__RootMismatch(_root);
        }
        if(s_nullifierHashes[_nullifierHash]){
            revert Mixer__NullifierAlreadyUsed(_nullifierHash);
        }

        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = _root;
        publicInputs[1] = _nullifierHash;
        publicInputs[2] = bytes32(uint256(uint160(_recipient)));
        if(!i_verifier.verify(_proof, publicInputs)){
            revert Mixer__InvalidProof();
        }

        s_nullifierHashes[_nullifierHash] = true;

        (bool success, ) = payable(_recipient).call{value: DENOMINATION}("");
        if(!success){
            revert Mixer__TransferFailed(_recipient, DENOMINATION);
        }
        
        emit Withdrawal(_recipient, _nullifierHash);
    }
}