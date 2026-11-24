import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/asset_model.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/services/pqc_service.dart';
import 'package:xeris_wallet/core/services/stealth_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/features/wallet_actions/screens/send_review_screen.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class _NoNetwork extends HttpOverrides {
  int calls = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    calls++;
    throw StateError('Network is forbidden in this test');
  }
}

class _Currency extends CurrencyNotifier {
  @override
  String build() => 'USD';
}

const _address = '4p897nUzAxU9xbaQH69fa3S3hvtn9o1STiobHX4vnLoL';
const _asset = AssetModel(
    id: 'xrs',
    symbol: 'XRS',
    name: 'Xeris',
    balance: 2,
    price: 0.01,
    changePercentage24h: 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late XerisNetwork original;
  late _NoNetwork network;
  int storageCalls = 0;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    original = NetworkConfig.currentNetwork;
    NetworkConfig.currentNetwork = XerisNetwork.mainnet;
    storageCalls = 0;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      storageCalls++;
      throw StateError('Wallet storage is forbidden in this test');
    });
  });
  tearDown(() {
    NetworkConfig.currentNetwork = original;
    HttpOverrides.global = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('mainnet rejects before recipient decoding, derivation, signing or IO',
      () async {
    await expectLater(
        StealthService.sendToStealthAddress(
            senderWalletId: 'synthetic-never-loaded',
            mnemonic: 'not a recovery phrase',
            stealthMetaAddress: 'invalid-before-derivation',
            amount: 1),
        throwsA(isA<UnsupportedError>().having(
            (e) => e.message, 'message', StealthService.unavailableMessage)));
    expect(storageCalls, 0);
    expect(network.calls, 0);
  });
  test('stealth policy follows runtime network and preserves testnet decoder',
      () async {
    expect(NetworkConfig.stealthEnabled, false);
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    expect(NetworkConfig.stealthEnabled, true);
    await expectLater(
        StealthService.sendToStealthAddress(
            senderWalletId: 'synthetic-never-loaded',
            mnemonic: 'not a recovery phrase',
            stealthMetaAddress: 'invalid-before-derivation',
            amount: 1),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Invalid stealth meta-address'))));
    NetworkConfig.currentNetwork = XerisNetwork.mainnet;
    expect(
        () => StealthService.requireSendingAvailable(), throwsUnsupportedError);
    expect(storageCalls, 0);
    expect(network.calls, 0);
  });
  test('captured transfer network rejects a change before key derivation',
      () async {
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    final expectedScope = NetworkConfig.cacheKey;
    NetworkConfig.currentNetwork = XerisNetwork.mainnet;
    await expectLater(
        WalletService.sendTransfer(
            mnemonic: 'not a recovery phrase',
            destinationAddress: 'never-used',
            solAmount: 1,
            expectedNetworkScope: expectedScope),
        throwsStateError);
    expect(storageCalls, 0);
    expect(network.calls, 0);
  });
  for (final stealth in [true, false]) {
    testWidgets(
        '${stealth ? "stealth" : "PQ"} direct review blocks before auth and unwrap',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
          overrides: [currencyProvider.overrideWith(_Currency.new)],
          child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SendReviewScreen(
                  asset: _asset,
                  address: 'synthetic-never-used',
                  amount: 1,
                  stealthMode: stealth,
                  pqMode: !stealth))));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(ElevatedButton, 'Confirm & Send');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(
          find.text(stealth
              ? StealthService.unavailableMessage
              : PqcService.transferUnavailableMessage),
          findsOneWidget);
      expect(storageCalls, 0);
      expect(network.calls, 0);
      expect(tester.takeException(), isNull);
    });
  }
  test('PQ registration is distinct from transfer protection', () async {
    for (final registered in [true, false]) {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(),
            '${NetworkConfig.controlUrl}/pq/keys/$_address');
        return http.Response('{"success":true,"has_pq_key":$registered}', 200);
      });
      final state =
          await PqcService.getRegistrationStatus(_address, client: client);
      expect(
          state,
          registered
              ? PqRegistrationStatus.registered
              : PqRegistrationStatus.notRegistered);
      expect(PqcService.registrationLabel(state),
          registered ? 'PQ key registered' : 'No PQ key registered');
      expect(PqcService.registrationExplanation, contains('Ed25519'));
      expect(PqcService.registrationExplanation, contains('disabled'));
      client.close();
    }
    expect(storageCalls, 0);
  });
  test('malformed or unavailable PQ results never promote a local flag',
      () async {
    for (final response in [
      http.Response('{}', 200),
      http.Response('not json', 200),
      http.Response('{"success":true,"has_pq_key":"true"}', 200),
      http.Response('', 404)
    ]) {
      final client = MockClient((_) async => response);
      expect(await PqcService.getRegistrationStatus(_address, client: client),
          PqRegistrationStatus.unavailable);
      client.close();
    }
    expect(storageCalls, 0);
  });
  test('PQ response for an old runtime network is discarded', () async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    final pending = PqcService.getRegistrationStatus(_address, client: client);
    NetworkConfig.currentNetwork = XerisNetwork.testnet;
    response.complete(http.Response('{"success":true,"has_pq_key":true}', 200));
    expect(await pending, PqRegistrationStatus.unavailable);
    expect(storageCalls, 0);
    client.close();
  });
}
