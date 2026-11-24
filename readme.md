# Xeris mainnet Android wallet

Flutter source for the Android Xeris Wallet, configured for the existing `xeris-mainnet-v4` chain at **https://mainnetrpc.xerisweb.com**. The web4 browser opens the new DEX at **https://dex.xerisweb.com**. This repository contains application source, public configuration and regression tests; it is not a Google Play release.

## Open in Android Studio

Install the Flutter and Dart plugins, open this repository's root, and select an ARM64 Android emulator or device. The included native crypto library supports `arm64-v8a`.

The current project uses Flutter 3.44.9 / Dart 3.12.2, Java 17, Android SDK 36, NDK 28.2.13676358, Gradle 8.13 and Android Gradle Plugin 8.11.1. Use Java 17 for Gradle; Android Studio's Java 25 is incompatible with this project's Gradle version. SDK locations and local machine settings are generated locally and are not committed.

```sh
flutter pub get --enforce-lockfile
flutter run --dart-define-from-file=config/mainnet.json
```

Mainnet is also the source default. Mainnet builds ignore a previously saved testnet selection so an upgrade cannot silently reopen the old chain. Explicit development builds can choose `--dart-define=XERIS_NETWORK=testnet`; the two networks have separate caches. `config/mainnet.json` contains public endpoints only.

## Included behavior

- Holdings load independently of price, pool and stake enrichment, with bounded request budgets and explicit retry/stale states.
- Mainnet uses HTTPS for JSON-RPC and REST; WebSockets are not required.
- The web4 browser exposes `window.xeris.connect()`, `getRpcUrl()` and `signTransaction()`. The DEX asks the user's wallet to sign; no treasury or reserve key belongs in this app.
- Built-in old DEX bookmarks resolve to `dex.xerisweb.com`; user-created bookmarks are preserved. The network-status bookmark opens the public mainnet API, since no separate human-facing mainnet explorer is configured.
- Transaction submission preserves the locally computed signature when the response is ambiguous. Dependent wallet operations wait for execution receipts.
- Current-node restrictions on legacy PQ/zk transfers, limit/DCA orders and fixed-roster staking remain enforced by the existing client adapters.

The repository preserves the existing native swap UI and wallet browser. It does not include the unshipped experimental native pool screen or a public automatic USDC deposit/redemption service. The new web DEX is developed separately. App integration code is separate from the L1's CertiK review.

## Offline regression checks

The focused suite uses mocked HTTP and synthetic test keys. These commands do not send transactions or read user wallet material:

```sh
flutter test --no-pub --dart-define-from-file=config/mainnet.json \
  test/mainnet_build_configuration_test.dart \
  test/network_configuration_test.dart \
  test/dashboard_loading_test.dart \
  test/balance_api_loading_test.dart \
  test/dex_pool_loading_test.dart \
  test/node_transaction_compatibility_test.dart \
  test/node_instruction_compatibility_test.dart \
  test/liquidity_compatibility_test.dart \
  test/price_decimal_test.dart \
  test/staking_information_test.dart \
  test/agent_model_compatibility_test.dart \
  test/pool_deployment_test.dart \
  test/transaction_confirmation_test.dart \
  test/transaction_submission_recovery_test.dart
```

Older integration/manual scripts under `test/` may access a configured network or require a host native library. Use the explicit offline list above for regression checks. Do not use an unrestricted test invocation as a production-wallet test.

## Packaging and release

`pubspec.yaml` is the Android version source (`2.2.0+13` in this source import). The existing application ID is `io.xeris.wallet`. Confirm the intended Play listing and choose a version code higher than its published version before release.

A local debug build does not require the owner's release key:

```sh
flutter build apk --debug --target-platform android-arm64 \
  --dart-define-from-file=config/mainnet.json
```

Release builds require the owner's private local `android/key.properties` and keystore. They are excluded from Git. Release no longer falls back silently to debug signing. Configure `storeFile`, `storePassword`, `keyAlias` and `keyPassword` locally, then use the same mainnet defines with `flutter build appbundle --release --target-platform android-arm64`. Never paste those values into issues, chat or CI logs.

The supplied `android/app/src/main/jniLibs/arm64-v8a/libxeris_crypto_ffi.so` is the existing Android crypto library. Its public Rust source and locked dependencies are in `rust_pqc/`; no native-library rebuild is claimed by this source import. No funded Android trade, signed production artifact, Play submission or public bridge launch is implied.
