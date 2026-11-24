// ML-DSA-65 (FIPS 204 final). Aliased as `dilithium3` to keep the FFI symbol
// names and call sites stable; the byte format (PK 1952 / SK 4032 / sig 3309)
// is identical to the node's pqcrypto-mldsa mldsa65 usage.
use pqcrypto_mldsa::mldsa65 as dilithium3;
use pqcrypto_traits::sign::{PublicKey, SecretKey, DetachedSignature};
use std::slice;

// Deterministic seed-derived keygen (RustCrypto ml-dsa, FIPS 204). The keys it
// emits are byte-identical to pqcrypto-mldsa, so xeris_dilithium_sign/verify
// (pqcrypto path) operate on the derived secret key unchanged.
use ml_dsa::{MlDsa65, B32, SigningKey};
use hkdf::Hkdf;
use sha2::Sha256;

/// HKDF-SHA256 domain separation label for the ML-DSA keygen seed.
/// MUST stay stable — changing it changes every derived PQ key.
const PQ_HKDF_INFO: &[u8] = b"xeris/pq/ml-dsa-65/v1";

/// Deterministically derive an ML-DSA-65 keypair from a wallet seed (e.g. the
/// BIP39 seed). Same seed -> same keypair on every device, so enabling Quantum
/// Shield follows the recovery phrase instead of being trapped on one device.
///
/// `seed_ptr`/`seed_len`: input keying material (the BIP39 seed bytes).
/// `pk_out`: 1952-byte buffer. `sk_out`: 4032-byte buffer. Returns 0 on success.
#[no_mangle]
pub extern "C" fn xeris_mldsa_keygen_from_seed(
    seed_ptr: *const u8, seed_len: usize,
    pk_out: *mut u8, sk_out: *mut u8,
) -> i32 {
    if seed_ptr.is_null() || pk_out.is_null() || sk_out.is_null() || seed_len == 0 {
        return -1;
    }
    let ikm = unsafe { slice::from_raw_parts(seed_ptr, seed_len) };

    // Domain-separated 32-byte keygen seed ξ (independent of the Ed25519 path).
    let hk = Hkdf::<Sha256>::new(None, ikm);
    let mut xi = [0u8; 32];
    if hk.expand(PQ_HKDF_INFO, &mut xi).is_err() {
        return -1;
    }

    let ssk = SigningKey::<MlDsa65>::from_seed(&B32::from(xi));
    xi.iter_mut().for_each(|b| *b = 0); // wipe the keygen seed
    let esk = ssk.expanded_key();
    let pk = esk.verifying_key().encode(); // 1952 bytes
    // to_expanded() is deprecated upstream in favour of the 32-byte seed form,
    // but the node (pqcrypto-mldsa) consumes the 4032-byte expanded secret key,
    // so the expanded form is exactly what we need for wire compatibility.
    #[allow(deprecated)]
    let sk = esk.to_expanded();            // 4032 bytes

    unsafe {
        std::ptr::copy_nonoverlapping(pk[..].as_ptr(), pk_out, 1952);
        std::ptr::copy_nonoverlapping(sk[..].as_ptr(), sk_out, 4032);
    }
    0
}

#[no_mangle]
pub extern "C" fn xeris_dilithium_keygen(pk_out: *mut u8, sk_out: *mut u8) -> i32 {
    let (pk, sk) = dilithium3::keypair();
    unsafe {
        std::ptr::copy_nonoverlapping(pk.as_bytes().as_ptr(), pk_out, 1952);
        std::ptr::copy_nonoverlapping(sk.as_bytes().as_ptr(), sk_out, 4032);
    }
    0
}

#[no_mangle]
pub extern "C" fn xeris_dilithium_sign(
    sk_ptr: *const u8, sk_len: usize,
    msg_ptr: *const u8, msg_len: usize,
    sig_out: *mut u8,
) -> i32 {
    if sk_len != 4032 { return -1; }
    let sk_bytes = unsafe { slice::from_raw_parts(sk_ptr, sk_len) };
    let msg = unsafe { slice::from_raw_parts(msg_ptr, msg_len) };
    let sk = match dilithium3::SecretKey::from_bytes(sk_bytes) {
        Ok(k) => k, Err(_) => return -1,
    };
    let sig = dilithium3::detached_sign(msg, &sk);
    unsafe { std::ptr::copy_nonoverlapping(sig.as_bytes().as_ptr(), sig_out, 3309); }
    0
}

#[no_mangle]
pub extern "C" fn xeris_dilithium_verify(
    pk_ptr: *const u8, pk_len: usize,
    msg_ptr: *const u8, msg_len: usize,
    sig_ptr: *const u8, sig_len: usize,
) -> i32 {
    if pk_len != 1952 || sig_len != 3309 { return -1; }
    let pk_bytes = unsafe { slice::from_raw_parts(pk_ptr, pk_len) };
    let msg = unsafe { slice::from_raw_parts(msg_ptr, msg_len) };
    let sig_bytes = unsafe { slice::from_raw_parts(sig_ptr, sig_len) };
    let pk = match dilithium3::PublicKey::from_bytes(pk_bytes) {
        Ok(k) => k, Err(_) => return -1,
    };
    let sig = match dilithium3::DetachedSignature::from_bytes(sig_bytes) {
        Ok(s) => s, Err(_) => return -1,
    };
    if dilithium3::verify_detached_signature(&sig, msg, &pk).is_ok() { 0 } else { -1 }
}
