import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xeris_wallet/core/services/dapp_session_guard.dart';
import 'package:xeris_wallet/features/dapp_browser/browser_tab_lifecycle.dart';

void main() {
  test(
      'closing a preceding inactive tab preserves active page and its authorized scope',
      () async {
    final tabs = [Object(), Object(), Object()];
    final a = tabs[0], b = tabs[1], c = tabs[2];
    var active = 1;
    final closed = <Object>[];
    final guard = DAppSessionGuard(
        networkScope: 'mainnet',
        currentNetworkScope: () => 'mainnet',
        currentPublicKey: () => 'public-fixture',
        currentWalletId: () async => 'fixture-wallet',
        currentTopLevelUrl: () async => Uri.parse('https://dex.xerisweb.com'),
        isCurrentDocument: (_) async => true,
        isActive: () => identical(tabs[active], b));
    final scope = await guard.pin(
        sourceOrigin: Uri.parse('https://dex.xerisweb.com'),
        isMainFrame: true,
        documentId: 'a' * 32);
    active = closeTabAndPreserveActive(
        tabs: tabs, activeIndex: active, closingIndex: 0, close: closed.add);
    expect(tabs, [b, c]);
    expect(active, 0);
    expect(tabs[active], same(b));
    expect(closed, [a]);
    await guard.ensureCurrent(scope);
  });
  test(
      'closing following, active-middle and active-last tabs uses the expected surviving page',
      () {
    for (final fixture in [(1, 2, 1), (1, 1, 1), (2, 2, 1), (0, 0, 0)]) {
      final tabs = [Object(), Object(), Object()], before = [...<Object>[]];
      before.addAll(tabs);
      var closed = 0;
      final result = closeTabAndPreserveActive(
          tabs: tabs,
          activeIndex: fixture.$1,
          closingIndex: fixture.$2,
          close: (tab) {
            expect(tab, same(before[fixture.$2]));
            expect(tabs, hasLength(3),
                reason: 'bridge closes before element removal');
            closed++;
          });
      expect(result, fixture.$3);
      expect(closed, 1);
      if (fixture.$1 != fixture.$2) {
        expect(tabs[result], same(before[fixture.$1]));
      }
    }
  });
  test(
      'closing the sole tab is a no-op and closing active invalidates its guard',
      () async {
    final tabs = [Object()];
    var closes = 0;
    expect(
        closeTabAndPreserveActive(
            tabs: tabs,
            activeIndex: 0,
            closingIndex: 0,
            close: (_) {
              closes++;
            }),
        0);
    expect(tabs, hasLength(1));
    expect(closes, 0);
    final guard = DAppSessionGuard(
        networkScope: 'mainnet',
        currentNetworkScope: () => 'mainnet',
        currentPublicKey: () => 'public-fixture',
        currentWalletId: () async => 'fixture-wallet',
        currentTopLevelUrl: () async => Uri.parse('https://dex.xerisweb.com'),
        isCurrentDocument: (_) async => true);
    final scope = await guard.pin(
        sourceOrigin: Uri.parse('https://dex.xerisweb.com'),
        isMainFrame: true,
        documentId: 'a' * 32);
    tabs.add(Object());
    closeTabAndPreserveActive(
        tabs: tabs,
        activeIndex: 0,
        closingIndex: 0,
        close: (_) => guard.close());
    await expectLater(guard.ensureCurrent(scope), throwsStateError);
  });
  test(
      'current title applies once, while late disposed/closed/replaced/navigated results are discarded',
      () async {
    for (final change in [
      'none',
      'screen',
      'tab',
      'controller',
      'navigation'
    ]) {
      var mounted = true, present = true, sameController = true, sameUrl = true;
      final title = Completer<String?>(), applied = <String?>[];
      final pending = applyCurrentTabTitle(
          isCurrent: () => mounted && present && sameController && sameUrl,
          readTitle: () => title.future,
          apply: applied.add);
      switch (change) {
        case 'screen':
          mounted = false;
        case 'tab':
          present = false;
        case 'controller':
          sameController = false;
        case 'navigation':
          sameUrl = false;
      }
      title.complete('Original page');
      await pending;
      expect(applied, change == 'none' ? ['Original page'] : isEmpty,
          reason: change);
    }
  });
  test('already-disposed tabs and failed title reads never apply metadata',
      () async {
    var reads = 0, applies = 0;
    await applyCurrentTabTitle(
        isCurrent: () => false,
        readTitle: () async {
          reads++;
          return 'stale';
        },
        apply: (_) {
          applies++;
        });
    expect(reads, 0);
    await applyCurrentTabTitle(
        isCurrent: () => true,
        readTitle: () async => throw StateError('view disposed'),
        apply: (_) {
          applies++;
        });
    expect(applies, 0);
  });
  test(
      'leaving parent Web4 selection synchronously revokes a pending approval and cannot revive it',
      () async {
    final selected = ValueNotifier(true), approval = Completer<bool>();
    var signs = 0;
    late final DAppSessionGuard guard;
    final activity = BrowserPageActivity(
        selected: selected, onHidden: () => guard.navigationStarted());
    guard = DAppSessionGuard(
        networkScope: 'mainnet',
        currentNetworkScope: () => 'mainnet',
        currentPublicKey: () => 'public-fixture',
        currentWalletId: () async => 'fixture-wallet',
        currentTopLevelUrl: () async => Uri.parse('https://dex.xerisweb.com'),
        isCurrentDocument: (_) async => true,
        isActive: () => activity.isSelected);
    final scope = await guard.pin(
        sourceOrigin: Uri.parse('https://dex.xerisweb.com'),
        isMainFrame: true,
        documentId: 'a' * 32);
    final pending = () async {
      await approval.future;
      await guard.ensureCurrent(scope);
      signs++;
    }();
    selected.value = false;
    expect(guard.isCurrentSynchronously(scope), false,
        reason: 'revoked before the next frame or approval result');
    await expectLater(
        guard.pin(
            sourceOrigin: Uri.parse('https://dex.xerisweb.com'),
            isMainFrame: true,
            documentId: 'a' * 32),
        throwsStateError);
    selected.value = true;
    approval.complete(true);
    await expectLater(pending, throwsStateError);
    expect(signs, 0);
    activity.dispose();
    selected.dispose();
  });
}
