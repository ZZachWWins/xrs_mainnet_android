import 'package:solana/solana.dart';
import 'package:xeris_wallet/core/config/network_config.dart';
import 'package:xeris_wallet/core/services/base_api_service.dart';

class ZkpService {
  static const transferUnavailableMessage =
      'Private proof transfers are unavailable on the current node. '
      'The legacy transfer format is disabled; no transaction was sent.';

  /// Fetches the raw integer balance from the configured explorer endpoint.
  static Future<int> fetchExactBalance(String address) async {
    final data = await BaseApiService.get(
      '${NetworkConfig.rpcUrl}/wallet/$address',
    );
    final balance = data is Map ? data['balance'] : null;
    final parsed = balance is int
        ? balance
        : balance is String
            ? int.tryParse(balance)
            : null;
    if (parsed == null || parsed < 0) {
      throw ApiException(
        message: 'The node returned an invalid raw balance.',
        type: ApiErrorType.rpc,
      );
    }
    return parsed;
  }

  /// The current node disables legacy ZkPrivateTransfer (variant 48).
  /// Do not generate proofs or submit an instruction the node cannot execute.
  static Future<String?> sendZkPrivateTransfer({
    required Ed25519HDKeyPair senderKeypair,
    required String recipientAddress,
    required double amountXrs,
    String tokenId = 'xrs_native',
  }) async {
    throw UnsupportedError(transferUnavailableMessage);
  }
}
