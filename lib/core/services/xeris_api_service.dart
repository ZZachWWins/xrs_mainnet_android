import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:solana/solana.dart';
import 'package:solana/encoder.dart';
import 'package:bs58/bs58.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/models/xeris_api_models.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';
import 'package:xeris_wallet/core/services/staking_api_service.dart';
import 'package:xeris_wallet/core/services/dex_service.dart';
import 'package:xeris_wallet/core/services/instruction_builder.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/liquidity_quote_service.dart';

/// A signed submission may have reached the node even though its response did
/// not arrive. Keep its canonical ID so callers can check it without resending.
class TransactionSubmissionUnknown implements Exception {
  final String signature;
  final Object? cause;

  const TransactionSubmissionUnknown({required this.signature, this.cause});

  @override
  String toString() =>
      'Transaction status is not yet known. Check signature '
      '$signature before submitting again.';
}

/// Facade for all Xeris blockchain API interactions.
/// Audit Note: Refactored from a monolithic class into a facade for modular services
/// to improve maintainability and error handling.
class XerisApiService extends BaseApiService {
  @visibleForTesting
  static DateTime Function()? nowOverride;
  static DateTime get _now => nowOverride?.call() ?? DateTime.now();

  // --- Explorer Logic (Delegated) ---

  // --- RPC-based Blockchain Logic (Replaces ExplorerService) ---

  static Future<XerisStatsResponse?> getStats() async {
    try {
      final txCount = await BaseApiService.callRpc('getTransactionCount');
      final currentSlot = await BaseApiService.callRpc('getSlot');

      return XerisStatsResponse(
        success: true,
        data: StatsData(
          blockHeight: currentSlot,
          currentSlot: currentSlot,
          totalTransactions: txCount,
          totalAccounts: 0, // RPC doesn't have a single call for total accounts
          totalStaked: 0,
          validatorCount: 0,
          tpsEstimate: 0.0,
        ),
      );
    } catch (e) {
      debugPrint('Error fetching RPC stats: $e');
      return null;
    }
  }

  static Future<XerisBlocksResponse?> getBlocks(
      {int page = 1, int pageSize = 20}) async {
    // Note: RPC getBlock requires a slot. Fetching a range of blocks via RPC is expensive.
    // For now, returning an empty response or the last block.
    try {
      final slot = await BaseApiService.callRpc('getSlot');
      final block = await getBlockBySlot(slot);
      return XerisBlocksResponse(
        success: true,
        data: block != null ? [block] : [],
      );
    } catch (_) {
      return null;
    }
  }

  static Future<XerisBlock?> getBlockBySlot(int slot) async {
    try {
      final result = await BaseApiService.callRpc('getBlock', [
        slot,
        {'encoding': 'json', 'transactionDetails': 'none'}
      ]);
      if (result != null) {
        return XerisBlock(
          slot: slot,
          hash: result['blockhash'] ?? '',
          proposer: '',
          txCount: (result['transactions'] as List?)?.length ?? 0,
          pohTimestamp: result['blockTime'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Error fetching block $slot via RPC: $e');
    }
    return null;
  }

  static Future<XerisTransactionsResponse?> getTransactions(
      {String? address, int page = 1, int pageSize = 20}) async {
    // Transaction fetching logic is now handled in WalletService.getTransactions via RPC.
    // This method is kept for compatibility with other callers but returns empty or delegatess.
    if (address != null) {
      await WalletService.getTransactions(address);
      // Conversion back to XerisTransaction would be needed if used elsewhere.
      return XerisTransactionsResponse(success: true, data: []);
    }
    return null;
  }

  static Future<XerisTransaction?> getTransactionBySignature(
      String signature) async {
    try {
      final result = await getRpcTransaction(signature);
      if (result != null) {
        return XerisTransaction.fromJson({
          'signature': signature,
          'block_slot': result['slot'] ?? 0,
          'from': '', // Would need to parse message
          'to': '',
          'amount': 0,
          'amount_xrs': 0.0,
          'status': (result['meta']?['err'] == null) ? 'confirmed' : 'failed',
          'timestamp': result['blockTime'],
        });
      }
    } catch (_) {}
    return null;
  }

  static Future<XerisAccount?> getAccount(String address) async {
    final scope = _networkScope;
    try {
      // 1. Try Explorer REST endpoint for balance and tokens (port 50008)
      final url = '${NetworkConfig.rpcUrl}/wallet/$address';
      if (kDebugMode) {
        debugPrint('Fetching account from Explorer REST: $url');
      }

      // Fetch account and staking info in parallel
      final stakeUrl = '${NetworkConfig.controlUrl}/stake/$address';
      final responses = await Future.wait([
        BaseApiService.get(url).catchError((_) => null),
        BaseApiService.get(stakeUrl).catchError((_) => null),
      ]);

      if (scope != _networkScope) return null;
      XerisAccount? account;
      var hasStake = false;
      final data = responses[0];
      if (data is Map<String, dynamic>) {
        account = XerisAccount.fromJson(data);
        hasStake = data.containsKey('stake') &&
            num.tryParse(data['stake'].toString()) != null;
      }

      // 2. Merge staking info fetched in parallel above
      try {
        final stakeData = responses[1];
        final rawStake = stakeData is Map ? stakeData['stake'] : null;
        final stake = num.tryParse(rawStake?.toString() ?? '');
        if (stake != null && stake.isFinite && stake >= 0) {
          hasStake = true;

          if (account != null) {
            account = account.copyWith(stake: stake);
          } else {
            // If Explorer failed but Control succeeded, build partial account
            account = XerisAccount(
              address: address,
              balance: 0,
              balanceXrs: 0,
              stake: stake,
              isValidator: stakeData['isValidator'] ?? false,
              blocksProposed:
                  XerisAccount.toNum(stakeData['blocksProposed'] ?? 0).toInt(),
              nonce: 0,
              tokens: {},
            );
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error fetching stake for $address: $e');
      }

      if (account != null && hasStake) return account;

      // /wallet does not contain stake in the current node. If /stake fails,
      // try authoritative RPC stake rather than treating missing data as zero.
      final result = await BaseApiService.callRpc('getAccountInfo', [
        address,
        {'encoding': 'jsonParsed'}
      ]);
      if (scope != _networkScope) return null;
      if (result is Map && result['value'] is Map) {
        final value = result['value'];
        final stake = num.tryParse(value['stake']?.toString() ?? '');
        if (stake == null || !stake.isFinite || stake < 0) return null;
        if (account != null) return account.copyWith(stake: stake);
        final lamports = XerisAccount.toNum(value['lamports']);

        return XerisAccount(
          address: address,
          balance: lamports,
          balanceXrs: lamports / 1e9,
          stake: stake,
          isValidator: value['isValidator'] ?? false,
          blocksProposed: 0,
          nonce: 0,
          tokens: {},
        );
      }
    } catch (e) {
      debugPrint('Error fetching account $address: $e');
    }
    return null;
  }

  static Future<List<XerisValidator>> getValidators() async {
    try {
      final result = await BaseApiService.callRpc('getVoteAccounts');
      if (result != null && result['current'] is List) {
        return (result['current'] as List)
            .map((v) => XerisValidator.fromJson(v))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<dynamic> search(String query) async {
    // Local heuristic search
    if (query.length >= 32 && query.length <= 44) {
      // Likely an address
      return {'result_type': 'account', 'data': await getAccount(query)};
    } else if (query.length >= 64) {
      // Likely a transaction
      return {
        'result_type': 'transaction',
        'data': await getTransactionBySignature(query)
      };
    }
    return null;
  }

  // --- RPC/Node Logic ---

  static Future<dynamic> getSignaturesForAddress(String address,
          {int limit = 20}) =>
      BaseApiService.callRpc('getSignaturesForAddress', [
        address,
        {'limit': limit}
      ]);

  static Future<dynamic> getRpcTransaction(String signature) =>
      BaseApiService.callRpc('getTransaction', [signature]);

  static Future<AccountBalances> getAccountBalances(String address) async {
    final scope = _networkScope;
    final key = '$scope|$address';
    final cached = _balanceCache[key];
    if (cached != null &&
        _now.difference(cached.fetchedAt) < _balanceCacheTtl) {
      return cached.balances;
    }
    final pending = _balanceRequests[key];
    if (pending != null) return pending;

    final generation = _balanceGeneration;
    final endpoint = NetworkConfig.controlUrl;
    late final Future<AccountBalances> request;
    request = _fetchAccountBalances(address, endpoint).then((balances) {
      if (generation == _balanceGeneration && scope == _networkScope) {
        _balanceCache[key] = _BalanceCacheEntry(balances, _now);
      }
      return balances;
    }).catchError((Object error, StackTrace stack) {
      // Only the same wallet on the same network may use a previous success.
      // A failed first load must remain an error, never a fabricated zero.
      if (generation == _balanceGeneration &&
          scope == _networkScope &&
          cached != null) {
        return cached.balances.asStale();
      }
      Error.throwWithStackTrace(error, stack);
    }).whenComplete(() {
      if (identical(_balanceRequests[key], request)) {
        _balanceRequests.remove(key);
      }
    });
    _balanceRequests[key] = request;
    return request;
  }

  static Future<AccountBalances> _fetchAccountBalances(
    String address,
    String endpoint,
  ) async {
    final data = await BaseApiService.get(
      '$endpoint/token/accounts/${Uri.encodeComponent(address)}',
      maxRetries: 2,
    );
    if (data is! Map || data['success'] == false) {
      throw ApiException(
          message: 'Invalid balance response', type: ApiErrorType.server);
    }
    final raw = data['native_xrs'] ?? data['balance'] ?? data['lamports'];
    final nativeRaw = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
    final accounts = data['token_accounts'] ?? const [];
    if (nativeRaw == null ||
        !nativeRaw.isFinite ||
        nativeRaw < 0 ||
        accounts is! List) {
      throw ApiException(
          message: 'Invalid balance response', type: ApiErrorType.server);
    }
    final tokens = accounts.map((account) {
      if (account is! Map || account['token_id'] is! String) {
        throw const FormatException('Invalid token account');
      }
      return XerisTokenBalance.fromJson({
        ...Map<String, dynamic>.from(account),
        'address': address,
      });
    }).toList(growable: false);
    return AccountBalances(
      nativeXrs: nativeRaw.toDouble() / 1e9,
      tokenBalances: List.unmodifiable(tokens),
    );
  }

  static Future<double> getBalance(String address) async {
    final balances = await getAccountBalances(address);
    return balances.nativeXrs;
  }

  // --- Token Logic ---

  static Future<XerisTokenBalance?> getTokenBalance(
      String address, String tokenId) async {
    try {
      final data = await BaseApiService.get(
          '${NetworkConfig.controlUrl}/token/balance/$address/$tokenId');
      if (data != null) {
        return XerisTokenBalance.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching token balance for $tokenId: $e');
    }
    return null;
  }

  static Future<List<XerisTokenBalance>> getAllTokenBalances(
      String address) async {
    final balances = await getAccountBalances(address);
    return balances.tokenBalances;
  }

  static String get _networkScope =>
      '${NetworkConfig.currentNetwork.name}|${NetworkConfig.rpcUrl}|${NetworkConfig.controlUrl}';
  static final Map<String, _BalanceCacheEntry> _balanceCache = {};
  static final Map<String, Future<AccountBalances>> _balanceRequests = {};
  static int _balanceGeneration = 0;
  static const Duration _balanceCacheTtl = Duration(seconds: 8);

  static void clearBalanceCache() {
    _balanceGeneration++;
    _balanceCache.clear();
    _balanceRequests.clear();
  }

  /// Invalidates completed and in-flight results from the previous network.
  static void clearNetworkCaches() {
    clearBalanceCache();
    _tokensGeneration++;
    _tokenCache.clear();
    _tokenRequests.clear();
  }

  static final Map<String, ({List<XerisToken> tokens, DateTime fetchedAt})>
      _tokenCache = {};
  static final Map<String, Future<List<XerisToken>?>> _tokenRequests = {};
  static int _tokensGeneration = 0;

  // Token names/symbols are user-created on-chain content. On testnet this list
  // includes spam and offensive names, which would surface in the "Manage Coins"
  // sheet and the swap token selector and risk App Review rejection under
  // Guideline 1.1.1 (objectionable content). This word-boundary blocklist drops
  // the clearly-offensive entries. It is intentionally conservative; extend the
  // set as needed. A user's own held balances are unaffected by this filter.
  static final RegExp _offensiveTokenPattern = RegExp(
    r'\b(dick|cock|pussy|testicle|foreskin|4skin|cum|cunt|fuck|shit|slut|whore|'
    r'nigger|nigga|faggot|fag|retard|rape|nazi|semen|jizz|boner|penis|vagina|'
    r'anus|anal|bitch|bastard|wank|coon|kike|spic|tranny)\b',
    caseSensitive: false,
  );

  static bool _isDisplayableToken(XerisToken t) {
    final haystack = '${t.name} ${t.symbol}';
    return !_offensiveTokenPattern.hasMatch(haystack);
  }

  static Future<List<XerisToken>?> getTokens() async {
    final scope = _networkScope;
    final cached = _tokenCache[scope];
    if (cached != null &&
        _now.difference(cached.fetchedAt) < const Duration(minutes: 10)) {
      return cached.tokens;
    }
    final pending = _tokenRequests[scope];
    if (pending != null) return pending;
    final generation = _tokensGeneration;
    final control = NetworkConfig.controlUrl;
    final explorer = NetworkConfig.rpcUrl;
    late final Future<List<XerisToken>?> request;
    request = _firstTokenRegistry([
      () => _fetchTokenPages('$control/tokens', 'tokens', 16),
      () => _fetchTokenPages('$explorer/v2/tokens', 'data', 32),
    ]).then((tokens) {
      final result = tokens.where(_isDisplayableToken).toList(growable: false);
      if (generation == _tokensGeneration && scope == _networkScope) {
        _tokenCache[scope] = (tokens: result, fetchedAt: _now);
      }
      return result;
    }).whenComplete(() {
      if (identical(_tokenRequests[scope], request)) {
        _tokenRequests.remove(scope);
      }
    });
    _tokenRequests[scope] = request;
    return request;
  }

  // Finish as soon as one complete registry succeeds. A failed first endpoint
  // does not cancel the other; a hanging fallback cannot hold up healthy data.
  static Future<List<XerisToken>> _firstTokenRegistry(
    List<Future<List<XerisToken>> Function()> sources,
  ) {
    final result = Completer<List<XerisToken>>();
    var remaining = sources.length;
    Object? lastError;
    StackTrace? lastStack;
    for (final source in sources) {
      Future.sync(source).then((tokens) {
        if (!result.isCompleted) result.complete(tokens);
      }, onError: (Object error, StackTrace stack) {
        lastError = error;
        lastStack = stack;
      }).whenComplete(() {
        remaining--;
        if (remaining == 0 && !result.isCompleted) {
          result.completeError(
              lastError ?? StateError('Token registry unavailable'), lastStack);
        }
      });
    }
    return result.future;
  }

  static Future<List<XerisToken>> _fetchTokenPages(
    String endpoint,
    String listKey,
    int limit,
  ) async {
    final tokens = <String, XerisToken>{};
    final cursors = <String>{};
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    String? after;
    while (true) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw TimeoutException('Token registry timed out');
      }
      final uri = Uri.parse(endpoint).replace(queryParameters: {
        'limit': '$limit',
        if (after != null) 'after': after,
      });
      final data = await BaseApiService.get(uri.toString(), timeout: remaining);
      final dynamic page = data is List
          ? data
          : (data is Map ? data[listKey] ?? data['tokens'] : null);
      if (page is! List || (data is Map && data['success'] == false)) {
        throw const FormatException('Invalid token registry response');
      }
      for (final item in page) {
        if (item is! Map) {
          throw const FormatException('Invalid token registry entry');
        }
        final token = XerisToken.fromJson(Map<String, dynamic>.from(item));
        if (token.id.isEmpty) throw const FormatException('Missing token ID');
        tokens[token.id] = token;
      }
      final next = data is Map ? data['next_after'] : null;
      if (next == null || next == '') {
        return tokens.values.toList(growable: false);
      }
      if (next is! String || !cursors.add(next) || page.isEmpty) {
        throw const FormatException('Invalid token registry cursor');
      }
      after = next;
    }
  }

  static Future<int?> getTokenHoldersCount(String tokenId) async {
    // Not easily available via core RPC without indexing
    return 0;
  }

  // --- Price History ---

  /// Fetches price snapshots for a pool. Returns [{timestamp_ms, price, tvl, ...}].
  static Future<List<Map<String, dynamic>>> fetchPriceHistory(String poolId,
      {int limit = 100}) async {
    try {
      final url =
          '${NetworkConfig.controlUrl}/price-history?pool_id=${Uri.encodeComponent(poolId)}&limit=$limit';
      final data = await BaseApiService.get(url);
      final history = data['history'] as List<dynamic>? ?? [];
      return history.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('fetchPriceHistory error: $e');
      return [];
    }
  }

  // --- DEX Logic (Delegated) ---

  static Future<List<XerisPool>?> getPools({bool forceRefresh = false}) =>
      DexService.getPools(forceRefresh: forceRefresh);

  static Future<SwapQuote?> getSwapQuote(
      {required String poolId,
      required String inputTokenId,
      required int amount}) async {
    try {
      if (kDebugMode) {
        debugPrint(
            'Fetching swap quote for pool $poolId, input $inputTokenId, amount $amount');
      }
      final response = await DexService.getSwapQuote(
          poolId: poolId, inputTokenId: inputTokenId, amount: amount);

      if (kDebugMode) {
        debugPrint('Swap quote raw response: $response');
      }

      if (response is Map) {
        // Handle both nested and flat responses reliably
        final Map<String, dynamic> data = Map<String, dynamic>.from(response);

        if (data.containsKey('quote') && data['quote'] is Map) {
          return SwapQuote.fromJson(Map<String, dynamic>.from(data['quote']));
        }

        // Check if this looks like a quote itself
        if (data.containsKey('output_amount') ||
            data.containsKey('output_token')) {
          return SwapQuote.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Error parsing swap quote: $e');
    }
    return null;
  }

  static Future<XerisPool?> getPoolInfo(String poolId) =>
      DexService.getPoolInfo(poolId);

  // --- Staking Logic (Delegated) ---

  static Future<String?> stakeXrs({
    required Ed25519HDKeyPair keyPair,
    required String validatorAddress,
    required int amountLamports,
  }) =>
      StakingApiService.stakeXrs(
        keyPair: keyPair,
        validatorAddress: validatorAddress,
        amountLamports: amountLamports,
      );

  static Future<String?> unstakeXrs({
    required Ed25519HDKeyPair keyPair,
    required String validatorAddress,
    required int amountLamports,
  }) =>
      StakingApiService.unstakeXrs(
        keyPair: keyPair,
        validatorAddress: validatorAddress,
        amountLamports: amountLamports,
      );

  static Future<dynamic> getAgentsRegistry(String ownerAddress) =>
      StakingApiService.getAgentsRegistry(ownerAddress);

  static Future<dynamic> getOpenTasks() => StakingApiService.getOpenTasks();

  static Future<String?> wrapXrs({
    required Ed25519HDKeyPair keyPair,
    required int amountLamports,
    String? expectedNetworkScope,
  }) async {
    final ixData = buildWrapInstruction(amountLamports: amountLamports);
    return await submitXerisInstruction(
      keyPair: keyPair,
      instructionData: ixData,
      expectedNetworkScope: expectedNetworkScope,
    );
  }

  static Future<String?> unwrapXrs({
    required Ed25519HDKeyPair keyPair,
    required int amountLamports,
    String? expectedNetworkScope,
  }) async {
    final ixData = buildUnwrapInstruction(amountLamports: amountLamports);
    return await submitXerisInstruction(
      keyPair: keyPair,
      instructionData: ixData,
      expectedNetworkScope: expectedNetworkScope,
    );
  }

  static Future<String?> swap({
    required Ed25519HDKeyPair keyPair,
    required String poolId,
    required String direction,
    required int inputAmount,
    required int minOutput,
    String? expectedNetworkScope,
  }) async {
    final ixData = InstructionBuilder.buildSwapInstruction(
      poolId: poolId,
      direction: direction,
      inputAmount: inputAmount,
      minOutput: minOutput,
    );
    return await submitXerisInstruction(
      keyPair: keyPair,
      instructionData: ixData,
      expectedNetworkScope: expectedNetworkScope,
    );
  }

  static Future<String?> addLiquidity(
      {required Ed25519HDKeyPair keyPair,
      required String poolId,
      required int amountA,
      required int amountB}) async {
    final scope = NetworkConfig.cacheKey;
    final ixData = await LiquidityQuoteService.buildAddInstruction(
      poolId: poolId,
      amountA: amountA,
      amountB: amountB,
    );
    return await submitXerisInstruction(
      keyPair: keyPair,
      instructionData: ixData,
      expectedNetworkScope: scope,
    );
  }

  static Future<String?> removeLiquidity(
      {required Ed25519HDKeyPair keyPair,
      required String poolId,
      required int shares}) async {
    final scope = NetworkConfig.cacheKey;
    final ixData = await LiquidityQuoteService.buildRemoveInstruction(
      poolId: poolId,
      walletAddress: keyPair.address,
      shares: shares,
    );
    return await submitXerisInstruction(
      keyPair: keyPair,
      instructionData: ixData,
      expectedNetworkScope: scope,
    );
  }

  static Future<String?> callContract(
      {required Ed25519HDKeyPair keyPair,
      required String contractId,
      required String method,
      required Uint8List args}) async {
    final ixData = InstructionBuilder.buildContractCallInstruction(
        contractId: contractId, method: method, args: args);
    return await submitXerisInstruction(
        keyPair: keyPair, instructionData: ixData);
  }

  static Future<String?> deployContract({
    required Ed25519HDKeyPair keyPair,
    required String contractId,
    required String contractType,
    required String paramsJson,
    String? expectedNetworkScope,
  }) async {
    final ixData = InstructionBuilder.buildContractDeployInstruction(
      contractId: contractId,
      contractType: contractType,
      paramsJson: paramsJson,
    );
    return await submitXerisInstruction(
      keyPair: keyPair,
      instructionData: ixData,
      expectedNetworkScope: expectedNetworkScope,
    );
  }

  static Future<Ed25519HDKeyPair> getKeyPair(String mnemonic) =>
      WalletService.getKeyPair(mnemonic);

  // --- Transaction Submission Helpers ---

  static Future<String?> submitXerisInstruction({
    required Ed25519HDKeyPair keyPair,
    required Uint8List instructionData,
    List<AccountMeta>? extraAccounts,
    String endpoint = '/submit',
    String? expectedNetworkScope,
  }) async {
    final scope = NetworkConfig.cacheKey;
    final controlEndpoint = NetworkConfig.controlUrl;
    void checkNetwork() {
      if (scope != NetworkConfig.cacheKey ||
          (expectedNetworkScope != null && expectedNetworkScope != scope)) {
        throw StateError(
          'Network changed. Review the transaction again before signing.',
        );
      }
    }

    try {
      checkNetwork();
      final programId = Ed25519HDPublicKey.fromBase58(
        '11111111111111111111111111111111',
      );

      final accounts = [
        AccountMeta.writeable(pubKey: keyPair.publicKey, isSigner: true),
      ];
      if (extraAccounts != null) {
        accounts.addAll(extraAccounts);
      }

      final instruction = Instruction(
        programId: programId,
        accounts: accounts,
        data: ByteArray(instructionData),
      );

      // Use the same bounded, validated blockhash request as ordinary sends.
      // No WebSocket server or unbounded Solana client request is required.
      final blockhash = await WalletService.getRecentBlockhash();
      checkNetwork();

      final message = Message(instructions: [instruction]);
      final compiledMessage = message.compile(
        recentBlockhash: blockhash,
        feePayer: keyPair.publicKey,
      );

      final signature = await keyPair.sign(
        compiledMessage.toByteArray().toList(),
      );
      checkNetwork();

      final signedTx = SignedTx(
        signatures: [signature],
        compiledMessage: compiledMessage,
      );

      final txBase64 = signedTx.encode();

      if (kDebugMode) {
        debugPrint('Submitting XRS transaction...');
        debugPrint('Program ID: ${programId.toBase58()}');
        debugPrint(
          'Accounts: ${accounts.map((AccountMeta a) => a.pubKey.toBase58()).toList()}',
        );
        debugPrint(
          'Instruction variant: ${instructionData.isNotEmpty ? instructionData[0] : 'empty'}',
        );
        debugPrint('Encoded length: ${txBase64.length}');
      }

      // The locally-computed signature IS the canonical transaction id, so we can
      // report it even when the node's success response omits an explicit id.
      final localTxId = base58.encode(Uint8List.fromList(signature.bytes));

      // README says: POST /submit { tx_base64: "..." } to RPC port (56001).
      // Use a generous timeout: a submit that succeeds slowly must not be
      // reported as a failure, or the user retries and double-sends.
      final dynamic body;
      try {
        body = await BaseApiService.post('$controlEndpoint$endpoint', {
          'tx_base64': txBase64,
        }, timeout: const Duration(seconds: 25));
      } catch (error) {
        throw TransactionSubmissionUnknown(signature: localTxId, cause: error);
      }

      if (kDebugMode) {
        debugPrint('Submission response: $body');
      }

      if (body is Map &&
          (body['status'] == 'ok' || body['status'] == 'queued')) {
        final nodeId = body['signature'] ?? body['hash'];
        if (nodeId != null && nodeId != localTxId) {
          throw TransactionSubmissionUnknown(
            signature: localTxId,
            cause: StateError('The acknowledgment used a different signature.'),
          );
        }
        return localTxId;
      }
      throw TransactionSubmissionUnknown(
        signature: localTxId,
        cause: StateError('The node did not acknowledge the submission.'),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Transaction submission failed error: $e');
      }
      rethrow;
    }
  }

  // --- Instruction Builders (Delegated to InstructionBuilder) ---

  static Uint8List buildNativeTransfer({
    required String from,
    required String to,
    required int amountLamports,
  }) =>
      InstructionBuilder.buildNativeTransferInstruction(
        from: from,
        to: to,
        amountLamports: amountLamports,
      );

  static Uint8List buildWrapInstruction({required int amountLamports}) =>
      InstructionBuilder.buildWrapInstruction(amountLamports: amountLamports);

  static Uint8List buildUnwrapInstruction({required int amountLamports}) =>
      InstructionBuilder.buildUnwrapInstruction(amountLamports: amountLamports);

  static Uint8List buildStakingInstruction(
          {required String validatorAddress, required int amountLamports}) =>
      InstructionBuilder.buildStakingInstruction(
          validatorAddress: validatorAddress, amountLamports: amountLamports);

  static Uint8List buildUnstakingInstruction(
          {required String validatorAddress, required int amountLamports}) =>
      InstructionBuilder.buildUnstakingInstruction(
          validatorAddress: validatorAddress, amountLamports: amountLamports);

  static Uint8List buildPqKeyRegister(
          {required String ed25519Pubkey, required Uint8List pqPublicKey}) =>
      InstructionBuilder.buildPqKeyRegisterInstruction(
          ed25519Pubkey: ed25519Pubkey, pqPublicKey: pqPublicKey);

  static Uint8List buildPqSignedTransfer({
    required String from,
    required String to,
    required int amountLamports,
    required Uint8List pqSignature,
    String pqAlgorithm = 'dilithium3',
  }) =>
      InstructionBuilder.buildPqSignedTransferInstruction(
        from: from,
        to: to,
        amountLamports: amountLamports,
        pqSignature: pqSignature,
        pqAlgorithm: pqAlgorithm,
      );

  static Uint8List buildTokenTransfer({
    required String tokenId,
    required String from,
    required String to,
    required int amount,
  }) =>
      InstructionBuilder.buildTokenTransferInstruction(
        tokenId: tokenId,
        from: from,
        to: to,
        amount: amount,
      );

  static Uint8List buildTokenMint({
    required String tokenId,
    required String to,
    required int amount,
  }) =>
      InstructionBuilder.buildTokenMintInstruction(
        tokenId: tokenId,
        to: to,
        amount: amount,
      );

  static Uint8List buildTokenBurn({
    required String tokenId,
    required String from,
    required int amount,
  }) =>
      InstructionBuilder.buildTokenBurnInstruction(
        tokenId: tokenId,
        from: from,
        amount: amount,
      );

  static Uint8List buildTokenCreate({
    required String tokenId,
    required String name,
    required String symbol,
    required int decimals,
    required int maxSupply,
    required String mintAuthority,
  }) =>
      InstructionBuilder.buildTokenCreateInstruction(
        tokenId: tokenId,
        name: name,
        symbol: symbol,
        decimals: decimals,
        maxSupply: maxSupply,
        mintAuthority: mintAuthority,
      );

  static Uint8List buildRegisterAgent({
    required String agentName,
    required String agentPubkey,
    required int maxPerTxLamports,
    required int maxDailyLamports,
    List<String> allowedContracts = const [],
    List<String> allowedOperations = const [
      'NativeTransfer',
      'ContractCall',
      'WrapXrs',
      'UnwrapXrs'
    ],
    int expiresAtSlot = 0,
  }) =>
      InstructionBuilder.buildRegisterAgentInstruction(
        agentName: agentName,
        agentPubkey: agentPubkey,
        maxPerTxLamports: maxPerTxLamports,
        maxDailyLamports: maxDailyLamports,
        allowedContracts: allowedContracts,
        allowedOperations: allowedOperations,
        expiresAtSlot: expiresAtSlot,
      );

  static Uint8List buildUpdateAgent({
    required String agentPubkey,
    int? newMaxPerTx,
    int? newMaxDaily,
    List<String>? newAllowedContracts,
    List<String>? newAllowedOperations,
    int? newExpiresAtSlot,
    bool revoked = false,
  }) =>
      InstructionBuilder.buildUpdateAgentInstruction(
        agentPubkey: agentPubkey,
        newMaxPerTx: newMaxPerTx,
        newMaxDaily: newMaxDaily,
        newAllowedContracts: newAllowedContracts,
        newAllowedOperations: newAllowedOperations,
        newExpiresAtSlot: newExpiresAtSlot,
        revoked: revoked,
      );

  static Uint8List buildAgentExecute({
    required String ownerPubkey,
    required Uint8List innerInstruction,
  }) =>
      InstructionBuilder.buildAgentExecuteInstruction(
        ownerPubkey: ownerPubkey,
        innerInstruction: innerInstruction,
      );

  static Uint8List buildClaimTask({
    required String taskId,
    required String claimantIdentity,
  }) => InstructionBuilder.buildClaimTaskInstruction(
        taskId: taskId,
        claimantIdentity: claimantIdentity,
      );

  static Uint8List buildAgentHeartbeat({
    required String identityPubkey,
    String currentModelHash = '',
    int activeTasks = 0,
    int availableCapacity = 10,
    String statusMessage = 'online',
  }) =>
      InstructionBuilder.buildAgentHeartbeatInstruction(
        identityPubkey: identityPubkey,
        currentModelHash: currentModelHash,
        activeTasks: activeTasks,
        availableCapacity: availableCapacity,
        statusMessage: statusMessage,
      );

  static Uint8List buildRevokeAgent({required String agentPubkey}) =>
      InstructionBuilder.buildUpdateAgentInstruction(
        agentPubkey: agentPubkey,
        revoked: true,
      );
}

class _BalanceCacheEntry {
  final AccountBalances balances;
  final DateTime fetchedAt;

  _BalanceCacheEntry(this.balances, this.fetchedAt);
}
