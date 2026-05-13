//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IVerifier} from "./Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "./IncrementalMerkleTree.sol";



contract Mixer is IncrementalMerkleTree {
    //mapping to store whether a commitment has been used before to prevent double deposits
    mapping(bytes32 => bool) public s_commitments;
    mapping(bytes32 => bool) public s_nullifierHashes; //mapping to store whether a nullifier hash has been used before to prevent double spending

    //the amount of ETH that can be deposited and withdrawn from the mixer 
    uint256 public constant DENOMINATION = 0.01 ether; 

    error Mixer_CommitmentAlreadyAdded(bytes32 commitment);
    error Mixer_DepositAmountNotCorrect(uint256 value, uint256 expected);
    error Mixer_UnknownRoot(bytes32 root);
    error Mixer_NullifierAlreadyUsed(bytes32 nullifierHash);


    IVerifier public immutable  i_verifier;
    constructor(IVerifier _verifier, Poseidon2 _hasher, uint32 _merkleTreeDepth) IncrementalMerkleTree(_merkleTreeDepth, _hasher) {
        i_verifier = _verifier;
    }
    //@notice Deposit Funds into the mixer
    //@param _commitment the poseidon commitment of the nullifier and secret(generated off-chain)
    function deposit(bytes32 _commitment) external payable {
       //check whether the commitment has been used before to prevent a deposit being added twice to the merkle tree
       if (s_commitments[_commitment]) {
           revert Mixer_CommitmentAlreadyAdded(_commitment);
       }

       //check that the user has sent the correct amount of ETH (e.g. 0.1, 1, 10 ETH)
       if (msg.value != DENOMINATION) {
           revert Mixer_DepositAmountNotCorrect(msg.value, DENOMINATION);
       }
       
       //add the commitment to to the on-chain incremental merkle tree containing all the commitments and add the commitment to the merkle tree
       //allow the user to seend ETH and make sure it is of the correct denomination (e.g. 0.1, 1, 10 ETH)
        uint32 insertedIndex = _insert(_commitment);
        s_commitments[_commitment] = true; //mark the commitment as used

        emit Deposit(_commitment, insertedIndex, block.timestamp);

    } 


    //@notice Withdraw Funds from the mixer in a private way
    function withdraw(bytes _proof, bytes32 _root, bytes32 _nullifierHash) external {
    // check that the root that was used in the proof matches the root on-chain to prevent a user from using an old root that is no longer valid
     if (_root != s_root) {
         revert Mixer_UnknownRoot(_root);
     }
    
    // check that the nullifier has not yet been used to prevent double spending

     if (s_nullifierHashes[_nullifierHash]) {
         revert Mixer_NullifierAlreadyUsed(_nullifierHash);
     }

    //check that the proof is valid by calling the verifier contract
    s_nullifierHashes[_nullifierHash] = true; //mark the nullifier as used to prevent double spending

    //verify the proof using the verifier contract and make sure the nullifier has not been used before to prevent double spending
    //if the proof is valid and the nullifier has not been used before, transfer the funds
        }
}