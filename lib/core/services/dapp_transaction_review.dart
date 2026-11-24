import 'dart:convert';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';

Never _reject(String text) => throw FormatException(text);
const _pool = 'xrs-xusdc-mainnet-v1';
final _u64Max = (BigInt.one << 64) - BigInt.one;

String _address(String text) {
  if (text.isEmpty || text.length > 128) _reject('Invalid public address.');
  final bytes = base58.decode(text);
  if (bytes.length != 32 ||
      bytes.every((v) => v == 0) ||
      base58.encode(bytes) != text) {
    _reject('Invalid public address.');
  }
  return text;
}

BigInt _positive(Object raw) {
  final text = raw.toString();
  if (!RegExp(r'^[1-9][0-9]{0,19}$').hasMatch(text)) {
    _reject('Invalid exact amount.');
  }
  final value = BigInt.parse(text);
  if (value > _u64Max) _reject('Amount exceeds u64.');
  return value;
}

String _amount(BigInt value, int decimals) {
  final base = BigInt.from(10).pow(decimals);
  final fraction = (value % base)
      .toString()
      .padLeft(decimals, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${value ~/ base}${fraction.isEmpty ? '' : '.$fraction'}';
}

class _Reader {
  final Uint8List bytes;
  int offset = 0;
  _Reader(this.bytes);
  Uint8List take(int count) {
    if (count < 0 || offset + count > bytes.length) {
      _reject('Truncated transaction.');
    }
    final value = Uint8List.fromList(bytes.sublist(offset, offset + count));
    offset += count;
    return value;
  }

  int byte() => take(1)[0];
  int u32() {
    final b = take(4);
    return ByteData.sublistView(b).getUint32(0, Endian.little);
  }

  BigInt u64() {
    final b = take(8);
    var n = BigInt.zero;
    for (var i = 7; i >= 0; i--) {
      n = (n << 8) | BigInt.from(b[i]);
    }
    return n;
  }

  int compact() {
    var value = 0;
    for (var i = 0; i < 3; i++) {
      final part = byte();
      value |= (part & 127) << (i * 7);
      if (i == 2 && part > 3) _reject('Invalid compact length.');
      if ((part & 128) == 0) {
        if (i > 0 && part == 0) _reject('Noncanonical compact length.');
        return value;
      }
    }
    _reject('Invalid compact length.');
  }

  Uint8List vector(int maximum) {
    final size = u64();
    if (size > BigInt.from(maximum)) _reject('Oversized instruction field.');
    return take(size.toInt());
  }

  String text() => utf8.decode(vector(128));
  void end() {
    if (offset != bytes.length) _reject('Unexpected trailing bytes.');
  }
}

/// Narrow, complete interpretation. Unsupported actions are never blind-signed.
class DAppTransactionReview {
  final String transactionBase64, signer, blockhash;
  final Map<String, String> intent;
  final Uint8List _wire, _message;
  Uint8List get wire => Uint8List.fromList(_wire);
  Uint8List get message => Uint8List.fromList(_message);
  DAppTransactionReview._(this.transactionBase64, this.signer, this.blockhash,
      Map<String, String> effects, Uint8List wire, Uint8List message)
      : intent = Map.unmodifiable(effects),
        _wire = Uint8List.fromList(wire),
        _message = Uint8List.fromList(message);

  static DAppTransactionReview parse(String text, String selectedSigner) {
    _address(selectedSigner);
    if (text.length > 8192) _reject('Oversized transaction.');
    final wire = base64Decode(text);
    if (wire.length > 4096 || base64Encode(wire) != text) {
      _reject('Noncanonical transaction encoding.');
    }
    final r = _Reader(wire);
    if (r.compact() != 1 || r.take(64).any((v) => v != 0)) {
      _reject('Exactly one unsigned signature is required.');
    }
    final messageOffset = r.offset;
    final header = r.take(3);
    if (header[0] != 1 ||
        header[1] != 0 ||
        header[2] != 1 ||
        r.compact() != 2) {
      _reject('Unsupported signer/account layout.');
    }
    if (base58.encode(r.take(32)) != selectedSigner ||
        r.take(32).any((v) => v != 0)) {
      _reject('Selected signer or system program mismatch.');
    }
    final hash = r.take(32);
    if (hash.every((v) => v == 0)) {
      _reject('A recent verified mainnet blockhash is required.');
    }
    if (r.compact() != 1 || r.byte() != 1) {
      _reject('Exactly one system instruction is supported.');
    }
    final accounts = r.compact();
    if (accounts != 0 && !(accounts == 1 && r.byte() == 0)) {
      _reject('Unsupported instruction account layout.');
    }
    final data = _Reader(r.take(r.compact()));
    r.end();
    final variant = data.u32();
    late Map<String, String> effects;
    if (variant == 13 || variant == 14) {
      final amount = _positive(data.u64());
      effects = {
        'action': variant == 13 ? 'wrap' : 'unwrap',
        'title': variant == 13 ? 'Wrap XRS' : 'Unwrap XRS',
        'amountRaw': '$amount',
        'amount': _amount(amount, 9),
        'asset': 'XRS',
        'recipient': selectedSigner
      };
    } else if (variant == 11 || variant == 1) {
      final token = variant == 1 ? data.text() : null;
      if (token != null && token != 'xrs_native' && token != 'xeris_usdc') {
        _reject('Token metadata is not approved for signing.');
      }
      final from = _address(data.text()),
          to = _address(data.text()),
          amount = _positive(data.u64());
      if (from != selectedSigner || to == from) {
        _reject('Transfer signer or recipient mismatch.');
      }
      effects = {
        'action': variant == 11 ? 'transfer' : 'tokenTransfer',
        'title': variant == 11 ? 'Send native XRS' : 'Send tokens',
        'amountRaw': '$amount',
        'amount': _amount(amount, token == 'xeris_usdc' ? 6 : 9),
        'asset': token == null
            ? 'XRS'
            : token == 'xeris_usdc'
                ? 'xUSDC'
                : 'wXRS',
        'recipient': to,
        if (token != null) 'token': token
      };
    } else if (variant == 4) {
      final contract = data.text(),
          method = data.text(),
          args = utf8.decode(data.vector(256));
      if (contract != _pool ||
          !['swap_a_to_b', 'swap_b_to_a'].contains(method)) {
        _reject('Unsupported contract action.');
      }
      final match = RegExp(
              r'^\{"amount":([1-9][0-9]{0,19}),"min_output":([1-9][0-9]{0,19})\}$')
          .firstMatch(args);
      if (match == null) _reject('Ambiguous or unsupported swap arguments.');
      final amount = _positive(match.group(1)!),
          minimum = _positive(match.group(2)!),
          buy = method == 'swap_b_to_a';
      effects = {
        'action': buy ? 'buy' : 'sell',
        'title': buy ? 'Buy XRS' : 'Sell XRS',
        'contract': contract,
        'amountRaw': '$amount',
        'amount': _amount(amount, buy ? 6 : 9),
        'asset': buy ? 'xUSDC' : 'wXRS',
        'minimumRaw': '$minimum',
        'minimum': _amount(minimum, buy ? 9 : 6),
        'minimumAsset': buy ? 'wXRS' : 'xUSDC',
        'recipient': selectedSigner
      };
    } else {
      _reject(
          'Unsupported instruction. Unbound burns and blind signing are disabled.');
    }
    data.end();
    return DAppTransactionReview._(
        text,
        selectedSigner,
        hash.map((v) => v.toRadixString(16).padLeft(2, '0')).join(),
        effects,
        wire,
        Uint8List.fromList(wire.sublist(messageOffset)));
  }

  Map<String, String> get display {
    final action = intent['action'];
    return {
      'Action': intent['title']!,
      'From wallet': signer,
      'Amount':
          '${intent['amount']} ${action == 'wrap' ? 'native XRS' : action == 'unwrap' ? 'wXRS' : intent['asset']}',
      'Recipient': intent['recipient']!,
      if (action == 'wrap' || action == 'unwrap')
        'Received 1:1':
            '${intent['amount']} ${action == 'wrap' ? 'wXRS' : 'native XRS'}',
      if (intent['minimum'] != null)
        'Minimum received': '${intent['minimum']} ${intent['minimumAsset']}',
      if (intent['contract'] != null) 'Pool': intent['contract']!,
      'Network fee': '0.001 native XRS',
      if (action == 'buy' || action == 'sell')
        'Pool fee': '0.3% included; minimum is a slippage limit',
      'Network': 'Xeris Mainnet',
    };
  }
}

String reviewDAppMessage(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 8192) {
    _reject('Only bounded readable text messages are supported.');
  }
  final text = utf8.decode(bytes);
  if (text.trim().isEmpty ||
      text.runes.any((rune) => rune != 10 && (rune < 32 || rune > 126))) {
    _reject('Only printable ASCII text and line breaks can be signed.');
  }
  // Printable base64 is not used to hide a canonical transaction/message.
  if (RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(text)) {
    try {
      final decoded = base64Decode(text);
      if (base64Encode(decoded) == text &&
          decoded.length > 100 &&
          (decoded[0] == 1 &&
              (decoded[1] == 0 ||
                  decoded.length > 165 &&
                      decoded[65] == 1 &&
                      decoded[66] == 0))) {
        _reject('Use transaction review for transaction bytes.');
      }
    } on FormatException catch (e) {
      if (e.message == 'Use transaction review for transaction bytes.') rethrow;
    }
  }
  return text;
}
