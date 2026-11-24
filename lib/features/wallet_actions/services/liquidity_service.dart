import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/services/pool_deployment_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/liquidity_quote_service.dart';
import 'package:xeris_wallet/core/config/network_config.dart';

class LiquidityService {
  final PoolDeploymentService _poolDeployment;

  LiquidityService({PoolDeploymentService? poolDeployment})
    : _poolDeployment = poolDeployment ?? PoolDeploymentService();

  /// Adds liquidity with fresh token decimals and signed 0.5% slippage bounds.
  /// UI callers bind the network and token pair visible when the form opened.
  Future<String?> addLiquidity({
    required String mnemonic,
    required String walletAddress,
    required String poolId,
    required String amountA,
    required String amountB,
    String? expectedNetworkScope,
    String? expectedTokenA,
    String? expectedTokenB,
    int slippageBps = LiquidityQuoteService.defaultSlippageBps,
  }) async {
    final networkScope = NetworkConfig.cacheKey;
    if (expectedNetworkScope != null && expectedNetworkScope != networkScope) {
      throw StateError(
        'The network changed. Close this form and review the deposit again.',
      );
    }
    final network = NetworkConfig.currentNetwork;
    final endpoint = NetworkConfig.controlUrl;
    final pool = await LiquidityQuoteService.fetchPoolState(poolId);
    if ((expectedTokenA != null && pool.tokenA != expectedTokenA) ||
        (expectedTokenB != null && pool.tokenB != expectedTokenB)) {
      throw StateError(
        'The pool token pair changed. Close this form and review the deposit again.',
      );
    }
    if (NetworkConfig.currentNetwork != network ||
        NetworkConfig.controlUrl != endpoint) {
      throw StateError('The network changed. Review the deposit again.');
    }
    final decimals = await Future.wait([
      LiquidityQuoteService.fetchTokenDecimals(walletAddress, pool.tokenA),
      LiquidityQuoteService.fetchTokenDecimals(walletAddress, pool.tokenB),
    ]);
    final quote = LiquidityQuoteService.quoteAdd(
      pool: pool,
      amountA: LiquidityQuoteService.parseDisplayAmount(amountA, decimals[0]),
      amountB: LiquidityQuoteService.parseDisplayAmount(amountB, decimals[1]),
      slippageBps: slippageBps,
    );
    if (NetworkConfig.currentNetwork != network ||
        NetworkConfig.controlUrl != endpoint) {
      throw StateError('The network changed. Review the deposit again.');
    }
    final keyPair = await WalletService.getKeyPair(mnemonic);
    if (keyPair.address != walletAddress) {
      throw StateError('The active wallet changed. Review the deposit again.');
    }
    return XerisApiService.submitXerisInstruction(
      keyPair: keyPair,
      instructionData: quote.toInstruction(),
      expectedNetworkScope: networkScope,
    );
  }

  /// [shares] is the exact raw LP share count, never a rounded display value.
  Future<String?> removeLiquidity({
    required String mnemonic,
    required String walletAddress,
    required String poolId,
    required int shares,
    int slippageBps = LiquidityQuoteService.defaultSlippageBps,
  }) async {
    final networkScope = NetworkConfig.cacheKey;
    final network = NetworkConfig.currentNetwork;
    final endpoint = NetworkConfig.controlUrl;
    final keyPair = await WalletService.getKeyPair(mnemonic);
    if (keyPair.address != walletAddress) {
      throw StateError(
        'The active wallet changed. Review the withdrawal again.',
      );
    }
    final instruction = await LiquidityQuoteService.buildRemoveInstruction(
      poolId: poolId,
      walletAddress: walletAddress,
      shares: shares,
      slippageBps: slippageBps,
    );
    if (NetworkConfig.currentNetwork != network ||
        NetworkConfig.controlUrl != endpoint) {
      throw StateError('The network changed. Review the withdrawal again.');
    }
    return XerisApiService.submitXerisInstruction(
      keyPair: keyPair,
      instructionData: instruction,
      expectedNetworkScope: networkScope,
    );
  }

  /// Deploy once, then follow the same signature until execution and pool state
  /// are verified. Native XRS must already be wrapped in the owner's account.
  Future<PoolDeploymentResult> deployPool({
    required String mnemonic,
    required String walletAddress,
    required String expectedNetworkScope,
    required String poolId,
    required String tokenA,
    required String tokenB,
    required String amountA,
    required String amountB,
    int feeBps = 30,
  }) async {
    Ed25519HDKeyPair? signingKey;
    return _poolDeployment.deploy(
      request: PoolDeploymentRequest(
        poolId: poolId,
        walletAddress: walletAddress,
        expectedNetworkScope: expectedNetworkScope,
        tokenA: tokenA,
        tokenB: tokenB,
        amountA: amountA,
        amountB: amountB,
        feeBps: feeBps,
      ),
      signerAddress: () async {
        signingKey = await WalletService.getKeyPair(mnemonic);
        return signingKey!.address;
      },
      submit: (plan) => XerisApiService.deployContract(
        keyPair: signingKey!,
        contractId: plan.request.poolId,
        contractType: 'swap',
        paramsJson: plan.paramsJson,
        expectedNetworkScope: expectedNetworkScope,
      ),
    );
  }
}
