/// Public request identity only. This guard never accesses keys or signs.
class DAppRequestScope {
  final String origin;
  final String documentId;
  final int documentGeneration;
  final String publicKey;
  final String? walletId;
  final int deadlineMs;

  const DAppRequestScope({
    required this.origin,
    required this.documentId,
    required this.documentGeneration,
    required this.publicKey,
    required this.walletId,
    required this.deadlineMs,
  });
}

/// Native caller metadata is mandatory; a JavaScript-provided origin is never
/// accepted. The document nonce also binds asynchronous replies to one page.
class DAppSessionGuard {
  final String networkScope;
  final String Function() currentNetworkScope;
  final String Function() currentPublicKey;
  final Future<String?> Function() currentWalletId;
  final Future<Uri?> Function() currentTopLevelUrl;
  final Future<bool> Function(String documentId) isCurrentDocument;
  static final Stopwatch _clock = Stopwatch()..start();
  final int Function() monotonicNow;
  final bool Function() isActive;
  int _generation = 0;
  bool _closed = false;

  DAppSessionGuard({
    required this.networkScope,
    required this.currentNetworkScope,
    required this.currentPublicKey,
    required this.currentWalletId,
    required this.currentTopLevelUrl,
    required this.isCurrentDocument,
    int Function()? monotonicNow,
    bool Function()? isActive,
  })  : monotonicNow = monotonicNow ?? (() => _clock.elapsedMilliseconds),
        isActive = isActive ?? (() => true);

  static String secureOrigin(Uri? value) {
    if (value == null ||
        value.scheme != 'https' ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty) {
      throw StateError('Wallet connections require a secure HTTPS page.');
    }
    return value.origin;
  }

  void navigationStarted() => _generation++;
  void close() {
    _closed = true;
    _generation++;
  }

  bool isCurrentSynchronously(DAppRequestScope scope) =>
      !_closed &&
      isActive() &&
      monotonicNow() < scope.deadlineMs &&
      _generation == scope.documentGeneration &&
      networkScope == currentNetworkScope() &&
      currentPublicKey() == scope.publicKey;

  void _check(DAppRequestScope scope) {
    if (!isCurrentSynchronously(scope)) {
      throw StateError('The page, wallet or network changed. Review again.');
    }
  }

  Future<DAppRequestScope> pin({
    required Uri? sourceOrigin,
    required bool isMainFrame,
    required String documentId,
  }) async {
    if (!isMainFrame) {
      throw StateError('Embedded frames cannot access the wallet.');
    }
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(documentId)) {
      throw StateError('Invalid wallet document session.');
    }
    final origin = secureOrigin(sourceOrigin);
    final deadlineMs = monotonicNow() + 120000;
    final generation = _generation;
    final publicKey = currentPublicKey();
    final walletId = await currentWalletId();
    final scope = DAppRequestScope(
      origin: origin,
      documentId: documentId,
      documentGeneration: generation,
      publicKey: publicKey,
      walletId: walletId,
      deadlineMs: deadlineMs,
    );
    await ensureCurrent(scope);
    return scope;
  }

  Future<void> ensureCurrent(DAppRequestScope scope) async {
    _check(scope);
    final top = await currentTopLevelUrl();
    _check(scope);
    if (secureOrigin(top) != scope.origin) {
      throw StateError('The wallet caller does not match the current page.');
    }
    final walletId = await currentWalletId();
    _check(scope);
    if (walletId != scope.walletId) {
      throw StateError('The active wallet changed. Review again.');
    }
    final documentMatches = await isCurrentDocument(scope.documentId);
    _check(scope);
    if (!documentMatches) {
      throw StateError('The requesting document is no longer active.');
    }
  }
}

/// Roll back a newly persisted permission if its approving context expires.
/// Existing grants are never removed by this operation.
Future<void> persistDAppConnection({
  required Future<void> Function() ensureCurrent,
  required Future<bool> Function() contains,
  required Future<void> Function() add,
  required Future<void> Function() remove,
}) async {
  await ensureCurrent();
  final existed = await contains();
  await ensureCurrent();
  try {
    if (!existed) await add();
    await ensureCurrent();
  } catch (_) {
    if (!existed) await remove();
    rethrow;
  }
}
