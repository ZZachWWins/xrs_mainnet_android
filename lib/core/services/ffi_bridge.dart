import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class DilithiumKeypair {
  final Uint8List publicKey; // 1952 bytes
  final Uint8List secretKey; // 4032 bytes
  DilithiumKeypair(this.publicKey, this.secretKey);
}

// ignore_for_file: non_constant_identifier_names

class FfiBridge {
  static late final DynamicLibrary _lib;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    if (Platform.isMacOS) {
      // Look for the dylib in the rust_pqc target directory for development
      // In production, this would be bundled in the app
      final dylibPath = p.join(
        Directory.current.path,
        'rust_pqc',
        'target',
        'release',
        'libxeris_crypto_ffi.dylib',
      );
      
      if (File(dylibPath).existsSync()) {
        _lib = DynamicLibrary.open(dylibPath);
      } else {
        // Fallback to searching in default paths (for bundled app)
        _lib = DynamicLibrary.open('libxeris_crypto_ffi.dylib');
      }
    } else if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libxeris_crypto_ffi.so');
    } else if (Platform.isIOS) {
      // For iOS, static libraries are linked into the executable.
      // DynamicLibrary.executable() is the correct way to access them.
      // DynamicLibrary.process() does not reliably expose statically linked symbols on iOS.
      _lib = DynamicLibrary.executable();
      if (kDebugMode) print('PQC: Loaded via DynamicLibrary.executable()');
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
    
    _initialized = true;
  }

  // Keygen
  static final _KeygenDart _keygen = _lib.lookupFunction<_KeygenC, _KeygenDart>('xeris_dilithium_keygen');

  static DilithiumKeypair dilithiumKeygen() {
    initialize();
    final pk = calloc<Uint8>(1952);
    final sk = calloc<Uint8>(4032);
    try {
      final result = _keygen(pk, sk);
      if (result != 0) throw Exception('Dilithium keygen failed with code $result');
      return DilithiumKeypair(
        Uint8List.fromList(pk.asTypedList(1952)),
        Uint8List.fromList(sk.asTypedList(4032)),
      );
    } finally {
      calloc.free(pk);
      calloc.free(sk);
    }
  }

  // Deterministic keygen from a wallet seed (e.g. the BIP39 seed). Same seed ->
  // same keypair on every device, so the PQ key follows the recovery phrase.
  static final _KeygenSeedDart _keygenSeed =
      _lib.lookupFunction<_KeygenSeedC, _KeygenSeedDart>('xeris_mldsa_keygen_from_seed');

  static DilithiumKeypair dilithiumKeygenFromSeed(Uint8List seed) {
    initialize();
    if (seed.isEmpty) throw Exception('Empty seed for PQ keygen');
    final seedPtr = calloc<Uint8>(seed.length);
    final pk = calloc<Uint8>(1952);
    final sk = calloc<Uint8>(4032);
    try {
      seedPtr.asTypedList(seed.length).setAll(0, seed);
      final result = _keygenSeed(seedPtr, seed.length, pk, sk);
      if (result != 0) throw Exception('Dilithium seed keygen failed with code $result');
      return DilithiumKeypair(
        Uint8List.fromList(pk.asTypedList(1952)),
        Uint8List.fromList(sk.asTypedList(4032)),
      );
    } finally {
      calloc.free(seedPtr);
      calloc.free(pk);
      calloc.free(sk);
    }
  }

  // Sign
  static final _SignDart _sign = _lib.lookupFunction<_SignC, _SignDart>('xeris_dilithium_sign');

  static Uint8List dilithiumSign(Uint8List secretKey, Uint8List message) {
    initialize();
    if (secretKey.length != 4032) throw Exception('Invalid secret key length: ${secretKey.length}');
    
    final skPtr = calloc<Uint8>(secretKey.length);
    final msgPtr = calloc<Uint8>(message.length);
    final sigPtr = calloc<Uint8>(3309);
    
    try {
      skPtr.asTypedList(secretKey.length).setAll(0, secretKey);
      msgPtr.asTypedList(message.length).setAll(0, message);
      
      final result = _sign(skPtr, secretKey.length, msgPtr, message.length, sigPtr);
      if (result != 0) throw Exception('Dilithium sign failed with code $result');
      
      return Uint8List.fromList(sigPtr.asTypedList(3309));
    } finally {
      calloc.free(skPtr);
      calloc.free(msgPtr);
      calloc.free(sigPtr);
    }
  }

  // Verify
  static final _VerifyDart _verify = _lib.lookupFunction<_VerifyC, _VerifyDart>('xeris_dilithium_verify');

  static bool dilithiumVerify(Uint8List publicKey, Uint8List message, Uint8List signature) {
    initialize();
    if (publicKey.length != 1952) return false;
    if (signature.length != 3309) return false;

    final pkPtr = calloc<Uint8>(publicKey.length);
    final msgPtr = calloc<Uint8>(message.length);
    final sigPtr = calloc<Uint8>(signature.length);

    try {
      pkPtr.asTypedList(publicKey.length).setAll(0, publicKey);
      msgPtr.asTypedList(message.length).setAll(0, message);
      sigPtr.asTypedList(signature.length).setAll(0, signature);

      final result = _verify(pkPtr, publicKey.length, msgPtr, message.length, sigPtr, signature.length);
      return result == 0;
    } finally {
      calloc.free(pkPtr);
      calloc.free(msgPtr);
      calloc.free(sigPtr);
    }
  }
}

// C typedefs
typedef _KeygenC = Int32 Function(Pointer<Uint8> pk_out, Pointer<Uint8> sk_out);
typedef _KeygenDart = int Function(Pointer<Uint8> pk_out, Pointer<Uint8> sk_out);

typedef _KeygenSeedC = Int32 Function(
  Pointer<Uint8> seed_ptr, Uint64 seed_len, Pointer<Uint8> pk_out, Pointer<Uint8> sk_out);
typedef _KeygenSeedDart = int Function(
  Pointer<Uint8> seed_ptr, int seed_len, Pointer<Uint8> pk_out, Pointer<Uint8> sk_out);

typedef _SignC = Int32 Function(
  Pointer<Uint8> sk_ptr,
  Uint64 sk_len,
  Pointer<Uint8> msg_ptr,
  Uint64 msg_len,
  Pointer<Uint8> sig_out,
);
typedef _SignDart = int Function(
  Pointer<Uint8> sk_ptr,
  int sk_len,
  Pointer<Uint8> msg_ptr,
  int msg_len,
  Pointer<Uint8> sig_out,
);

typedef _VerifyC = Int32 Function(
  Pointer<Uint8> pk_ptr,
  Uint64 pk_len,
  Pointer<Uint8> msg_ptr,
  Uint64 msg_len,
  Pointer<Uint8> sig_ptr,
  Uint64 sig_len,
);
typedef _VerifyDart = int Function(
  Pointer<Uint8> pk_ptr,
  int pk_len,
  Pointer<Uint8> msg_ptr,
  int msg_len,
  Pointer<Uint8> sig_ptr,
  int sig_len,
);
