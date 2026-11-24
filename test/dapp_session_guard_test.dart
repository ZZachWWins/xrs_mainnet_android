import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/dapp_session_guard.dart';

class Fixture {
  String network = 'mainnet', publicKey = 'public-account-a';
  int now = 0;
  bool active = true;
  String? walletId = 'wallet-a';
  Uri? top = Uri.parse('https://dex.xerisweb.com/?network=mainnet');
  String documentId = 'a' * 32;
  Future<Uri?> Function()? readTop;
  Future<String?> Function()? readWallet;
  late final guard = DAppSessionGuard(
    networkScope: 'mainnet',
    monotonicNow: () => now,
    isActive: () => active,
    currentNetworkScope: () => network,
    currentPublicKey: () => publicKey,
    currentWalletId: () async =>
        readWallet == null ? walletId : await readWallet!(),
    currentTopLevelUrl: () async => readTop == null ? top : await readTop!(),
    isCurrentDocument: (candidate) async => candidate == documentId,
  );
  Future<DAppRequestScope> pin({Uri? origin, bool mainFrame = true}) =>
      guard.pin(
        sourceOrigin: origin ?? Uri.parse('https://dex.xerisweb.com'),
        isMainFrame: mainFrame,
        documentId: documentId,
      );
}

void main() {
  test('native HTTPS main-frame origin is pinned independently of path/query',
      () async {
    final f = Fixture(), scope = await f.pin();
    expect(scope.origin, 'https://dex.xerisweb.com');
    expect(scope.walletId, 'wallet-a');
    await f.guard.ensureCurrent(scope);
  });
  test('iframe, HTTP, opaque and wrong actual origins are rejected', () async {
    for (final uri in [
      'http://dex.xerisweb.com',
      'file:///tmp/page.html',
      'data:text/html,test',
      'https://evil.example'
    ]) {
      await expectLater(
          Fixture().pin(origin: Uri.parse(uri)), throwsStateError);
    }
    await expectLater(Fixture().pin(mainFrame: false), throwsStateError);
    final f = Fixture();
    await expectLater(
        f.guard.pin(
            sourceOrigin: null, isMainFrame: true, documentId: f.documentId),
        throwsStateError);
  });
  test(
      'navigation invalidates old requests even when returning to the same origin',
      () async {
    final f = Fixture(), old = await f.pin();
    f.guard.navigationStarted();
    await expectLater(f.guard.ensureCurrent(old), throwsStateError);
    await f.guard.ensureCurrent(await f.pin());
  });
  test(
      'account, wallet-ID, network, document nonce and closed-tab changes revoke a request',
      () async {
    final mutations = <void Function(Fixture)>[
      (f) => f.publicKey = 'public-account-b',
      (f) => f.walletId = 'wallet-b',
      (f) => f.network = 'testnet',
      (f) => f.documentId = 'b' * 32,
      (f) => f.guard.close(),
    ];
    for (final mutate in mutations) {
      final f = Fixture(), scope = await f.pin();
      mutate(f);
      await expectLater(f.guard.ensureCurrent(scope), throwsStateError);
    }
  });
  test(
      'a change while URL/wallet metadata is awaiting cannot restore a stale context',
      () async {
    final f = Fixture(), scope = await f.pin(), pending = Completer<Uri?>();
    f.readTop = () => pending.future;
    final checked = expectLater(f.guard.ensureCurrent(scope), throwsStateError);
    f.guard.navigationStarted();
    pending.complete(f.top);
    await checked;
    final g = Fixture(), walletRead = Completer<String?>();
    g.readWallet = () => walletRead.future;
    final pinned = expectLater(g.pin(), throwsStateError);
    g.network = 'testnet';
    walletRead.complete('wallet-a');
    await pinned;
  });
  test('an invalid or reused document nonce cannot authorize another page',
      () async {
    final f = Fixture();
    for (final value in ['', 'a' * 31, 'A' * 32, 'a' * 33, 'x' * 32]) {
      await expectLater(
          f.guard.pin(
              sourceOrigin: Uri.parse('https://dex.xerisweb.com'),
              isMainFrame: true,
              documentId: value),
          throwsStateError);
    }
    final scope = await f.pin();
    f.top = Uri.parse('https://launchpad.xerisweb.com');
    await expectLater(f.guard.ensureCurrent(scope), throwsStateError);
  });
  test(
      'native monotonic deadline expires across awaits even when the page timer is bypassed',
      () async {
    final f = Fixture();
    final current = await f.pin();
    f.now = 119999;
    await f.guard.ensureCurrent(current);
    f.now = 120000;
    expect(f.guard.isCurrentSynchronously(current), false);
    await expectLater(f.guard.ensureCurrent(current), throwsStateError);
    final fresh = await f.pin();
    final pending = Completer<Uri?>();
    f.readTop = () => pending.future;
    final result = f.guard.ensureCurrent(fresh);
    f.now += 120000;
    pending.complete(f.top);
    await expectLater(result, throwsStateError);
    expect(current.deadlineMs, 120000);
  });
  test(
      'inactive tabs are never authorized and switching back does not revive a request',
      () async {
    final f = Fixture();
    final scope = await f.pin();
    f.active = false;
    await expectLater(f.pin(), throwsStateError);
    f.guard.navigationStarted();
    f.active = true;
    await expectLater(f.guard.ensureCurrent(scope), throwsStateError);
  });
  test('new grant is rolled back if context changes during storage write',
      () async {
    final f = Fixture(), scope = await f.pin();
    var stored = false, removed = 0;
    await expectLater(
        persistDAppConnection(
          ensureCurrent: () => f.guard.ensureCurrent(scope),
          contains: () async => stored,
          add: () async {
            stored = true;
            f.guard.navigationStarted();
          },
          remove: () async {
            stored = false;
            removed++;
          },
        ),
        throwsStateError);
    expect(stored, false);
    expect(removed, 1);
  });
  test('existing grants survive a rejected persistence attempt', () async {
    var calls = 0, removed = false;
    await expectLater(
        persistDAppConnection(
          ensureCurrent: () async {
            if (++calls == 3) throw StateError('changed');
          },
          contains: () async => true,
          add: () async => fail('must not rewrite existing grant'),
          remove: () async {
            removed = true;
          },
        ),
        throwsStateError);
    expect(removed, false);
  });
  test('a storage failure after a partial grant write is rolled back',
      () async {
    var stored = false;
    await expectLater(
        persistDAppConnection(
          ensureCurrent: () async {},
          contains: () async => false,
          add: () async {
            stored = true;
            throw StateError('write failed');
          },
          remove: () async {
            stored = false;
          },
        ),
        throwsStateError);
    expect(stored, false);
  });
}
