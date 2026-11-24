import 'package:flutter/services.dart';

/// Copies sensitive text (recovery phrase, secret key) to the clipboard and
/// automatically clears it after [clearAfter] — but only if the clipboard still
/// holds that exact text, so we never wipe something the user copied afterward.
///
/// Android exposes the clipboard to any app, and iOS Universal Clipboard syncs
/// it across devices, so leaving a seed phrase or private key there indefinitely
/// is a well-known wallet leak path.
Future<void> copySensitiveToClipboard(
  String secret, {
  Duration clearAfter = const Duration(seconds: 60),
}) async {
  await Clipboard.setData(ClipboardData(text: secret));
  Future.delayed(clearAfter, () async {
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == secret) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  });
}
