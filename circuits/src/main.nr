fn main{

    root: pub Field,
    nullifier_hash: pub Field,

    // Private inputs
    nullifier: Field,
    secret: Field,
    merkle_path: [Field; 20],
    is_even: [bool; 20],
}