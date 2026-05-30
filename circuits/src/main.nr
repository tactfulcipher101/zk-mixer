use poseidon::poseidon2;
mod merkle_tree;

fn main(
    //public inputs
    root: pub Field,
    nullifier_hash: pub Field,
    _recipient: pub Field,

    //private inputs
    nullifier: Field,
    secret: Field,
    merkle_proof: [Field; 20],
    is_even: [bool; 20]
){
    let commitment: Field = poseidon2::Poseidon2::hash([nullifier, secret],2);
    let computed_nullifier_hash: Field = poseidon2::Poseidon2::hash([nullifier], 1);

    assert(nullifier_hash==computed_nullifier_hash);

    let computed_root: Field = merkle_tree::compute_merkle_root(commitment, merkle_proof, is_even);
    assert(root == computed_root);
}