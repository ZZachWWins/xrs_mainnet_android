// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settingsTitle => '設定';

  @override
  String get accountSection => 'アカウント';

  @override
  String get manageWalletsTitle => 'ウォレットを管理';

  @override
  String get manageWalletsSubtitle => 'ウォレットの追加、削除、切り替え';

  @override
  String get recoveryPhraseTitle => 'リカバリーフレーズ';

  @override
  String get recoveryPhraseSubtitle => '保護されたシークレットシードフレーズを表示';

  @override
  String get generalSection => '一般';

  @override
  String get currencyTitle => '通貨';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsSubtitle => '取引のアラートを受け取る';

  @override
  String get privacyModeTitle => 'プライバシーモード';

  @override
  String get privacyModeSubtitle => 'ダッシュボード上の残高を非表示にする';

  @override
  String get securitySection => 'セキュリティ';

  @override
  String get biometricTitle => '生体認証';

  @override
  String get biometricSubtitle => '起動時に Face ID / 指紋認証を要求';

  @override
  String get supportSection => 'サポート';

  @override
  String get privacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get privacyPolicySubtitle => 'プライバシーポリシーを読む';

  @override
  String get termsOfServiceTitle => '利用規約';

  @override
  String get termsOfServiceSubtitle => '利用規約を読む';

  @override
  String get aboutWalletTitle => 'Xeris ウォレットについて';

  @override
  String get languageTitle => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get addressCopied => 'アドレスをクリップボードにコピーしました';

  @override
  String get loadingAddress => '読み込み中...';

  @override
  String get errorLoadingAddress => 'アドレスの読み込みエラー';

  @override
  String get sinceLastMonth => '先月から';

  @override
  String get tokensTitle => 'トークン';

  @override
  String comingSoon(String itemName) {
    return '$itemName の詳細は近日公開予定です！';
  }

  @override
  String get actionSend => '送信';

  @override
  String get actionReceive => '受信';

  @override
  String get actionSwap => 'スワップ';

  @override
  String get actionEarn => '稼ぐ';

  @override
  String get actionScan => 'スキャン';

  @override
  String get navWallet => 'ウォレット';

  @override
  String get navBrowser => 'ブラウザ';

  @override
  String get navActivity => 'アクティビティ';

  @override
  String get balanceHistoryTitle => '残高履歴';

  @override
  String get totalBalanceTitle => '合計残高';

  @override
  String get noHistoryAvailable => '履歴がありません';

  @override
  String errorPrefix(String error) {
    return 'エラー: $error';
  }

  @override
  String get addWalletTitle => 'ウォレットを追加';

  @override
  String get addWalletSubtitle => 'ウォレットをどのように追加しますか？';

  @override
  String get createNewWallet => '新しいウォレットを作成';

  @override
  String get createNewWalletDesc => '新しい12単語のシークレットリカバリーフレーズを生成します';

  @override
  String get importExistingWallet => '既存のウォレットをインポート';

  @override
  String get importExistingWalletDesc => 'シークレットリカバリーフレーズを使って復元します';

  @override
  String get myWalletsTitle => 'マイウォレット';

  @override
  String get noWallets => 'ウォレットがありません';

  @override
  String get noWalletsDesc => 'まだウォレットがありません。最初のウォレットを作成またはインポートして始めましょう。';

  @override
  String get deleteWalletPromptTitle => 'ウォレットを削除しますか？';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return '「$walletName」を本当に削除しますか？リカバリーフレーズを保存していない限り、この操作は取り消せません。';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get unlockWallet => 'ウォレットのロック解除';

  @override
  String get authRequired => '認証が必要です。';

  @override
  String get verifySecretPhraseTitle => 'シークレットフレーズを確認';

  @override
  String get verifyBackup => 'バックアップを確認';

  @override
  String get verifyBackupDesc => 'シークレットフレーズから次の単語を入力して、保存済みであることを確認してください。';

  @override
  String wordNumber(String number) {
    return '単語 #$number';
  }

  @override
  String enterWordNumber(String number) {
    return '単語 #$number を入力';
  }

  @override
  String get verifyComplete => '確認して完了';

  @override
  String get walletVerified => 'ウォレットが確認され、保護されました！';

  @override
  String failedCreateWallet(String error) {
    return 'ウォレットの作成に失敗しました: $error';
  }

  @override
  String get incorrectWords => '単語が正しくありません。フレーズを確認して再度お試しください。';

  @override
  String get importWalletTitle => 'ウォレットをインポート';

  @override
  String get enterSecretPhrase => 'シークレットフレーズを入力';

  @override
  String get enterRecoveryPhraseDesc =>
      '12単語または24単語のリカバリーフレーズを入力してウォレットを復元します。';

  @override
  String get invalidRecoveryPhrase => '無効なリカバリーフレーズ';

  @override
  String get walletImportedSuccess => 'ウォレットを正常にインポートしました！';

  @override
  String failedImportWallet(String error) {
    return 'ウォレットのインポートに失敗しました: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'シークレットリカバリーフレーズ';

  @override
  String get secretPhraseMasterKeyDesc =>
      'このシークレットフレーズはウォレットのマスターキーです。書き留めて安全な場所に保管してください。誰にも共有しないでください。';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get secretPhraseCopied => 'シークレットフレーズをクリップボードにコピーしました';

  @override
  String get savedSecretPhraseBtn => 'シークレットフレーズを保存しました';

  @override
  String get welcomeTo => 'Xeris ウォレットへ\nようこそ';

  @override
  String get secureWalletForChain => 'Xeris チェーンのための安全なウォレット。';

  @override
  String get createANewWallet => '新しいウォレットを作成';

  @override
  String get alreadyHaveWallet => 'すでにウォレットを持っています';

  @override
  String get sendAssetsTitle => 'アセットを送信';

  @override
  String get recipientAddress => '受信者のアドレス';

  @override
  String get pasteAddressOrScan => 'アドレスを貼り付けるか QR をスキャン';

  @override
  String get amount => '金額';

  @override
  String get max => '最大';

  @override
  String get review => '確認';

  @override
  String balance(String amount, String symbol) {
    return '残高: $amount $symbol';
  }

  @override
  String get errorEnterRecipient => '受信者のアドレスを入力してください';

  @override
  String get errorInvalidAddress => '無効な Xeris チェーンアドレス';

  @override
  String get errorEnterValidAmount => '有効な金額を入力してください';

  @override
  String get errorInsufficientBalance => '残高が不足しています';

  @override
  String get receiveAssetsTitle => 'アセットを受信';

  @override
  String get scanToReceive => 'スキャンして受信';

  @override
  String get sendOnlyXerisAssets => 'このアドレスには Xeris チェーンのアセットのみ送信してください。';

  @override
  String get shareAddress => 'アドレスを共有';

  @override
  String get swapTitle => 'スワップ';

  @override
  String get from => 'From';

  @override
  String get toEstimated => 'To（見積もり）';

  @override
  String get price => '価格';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'スリッページ許容値';

  @override
  String get swapping => 'スワップ中...';

  @override
  String get selectToken => 'トークンを選択';

  @override
  String get scanQrCodeTitle => 'QR コードをスキャン';

  @override
  String get alignQrCode => 'フレーム内に QR コードを合わせてください';

  @override
  String get earnRewardsTitle => '報酬を獲得';

  @override
  String get noValidatorsFound =>
      'テストネット上にバリデーターが見つかりませんでした。\nネットワークへのステーキングは引き続き可能です。';

  @override
  String validatorAddress(String address) {
    return 'バリデーター $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'ステーキング: $amount XRS';
  }

  @override
  String get stake => 'ステーキング';

  @override
  String get unstake => 'アンステーキング';

  @override
  String get directStake => '直接ステーキング';

  @override
  String get stakedBalance => 'ステーキング残高';

  @override
  String totalStaked(String amount) {
    return '合計ステーキング: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return '手数料: $value%';
  }

  @override
  String get searchValidators => 'バリデーターを検索';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'ステーキングを確認';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return '$amount XRS を $validator にステーキングしようとしています。';
  }

  @override
  String get confirmUnstakeTitle => 'アンステーキングを確認';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return '$amount XRS を $validator からアンステーキングしようとしています。';
  }

  @override
  String get unbondingNotice => '7日間のアンボンディング期間が適用されます';

  @override
  String get transactionSubmitted => '取引が送信されました';

  @override
  String get transactionFailed => '取引に失敗しました';

  @override
  String get txSubmittedDesc => '取引が Xeris ネットワークに送信されました。';

  @override
  String hashLabel(String hash) {
    return 'ハッシュ: $hash';
  }

  @override
  String get txHashCopied => '取引ハッシュをクリップボードにコピーしました';

  @override
  String get viewInExplorer => 'エクスプローラーで表示';

  @override
  String get backToDashboard => 'ダッシュボードに戻る';

  @override
  String get shareReceipt => '領収書を共有';

  @override
  String get transactionDetails => '取引の詳細';

  @override
  String get receiptTitle => 'Xeris 取引明細書';

  @override
  String get dateLabel => '日付';

  @override
  String get statusLabel => 'ステータス';

  @override
  String get successStatus => '成功';

  @override
  String get failedStatus => '失敗';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String connectToDapp(String dappName) {
    return '$dappName に接続しますか？';
  }

  @override
  String get reject => '拒否';

  @override
  String get approve => '承認';

  @override
  String get details => '詳細';

  @override
  String get activityTitle => 'アクティビティ';

  @override
  String get noActivityYet => 'アクティビティはまだありません';

  @override
  String get noActivityDesc => '送金または受け取りを行うと、ここに取引が表示されます。';

  @override
  String get errorLoadingActivity => 'アクティビティの読み込みエラー';

  @override
  String get activitySearchHint => 'アドレス、tx ハッシュ、トークンを検索';

  @override
  String get activityFilterAll => 'すべて';

  @override
  String get activityFilterSent => '送信済み';

  @override
  String get activityFilterReceived => '受信済み';

  @override
  String get activityFilterSwap => 'スワップ';

  @override
  String get activityFilterFailed => '失敗';

  @override
  String get activityNoMatches => '一致なし';

  @override
  String get activityNoMatchesDesc => 'フィルターまたは検索を調整してみてください';

  @override
  String get unknownAddress => '不明';

  @override
  String receivedAsset(String symbol) {
    return '$symbol を受信';
  }

  @override
  String sentAsset(String symbol) {
    return '$symbol を送信';
  }

  @override
  String fromAddress(String address) {
    return 'From: $address';
  }

  @override
  String toAddress(String address) {
    return 'To: $address';
  }

  @override
  String get execContract => '実行';

  @override
  String todayAt(String time) {
    return '今日 $time';
  }

  @override
  String yesterdayAt(String time) {
    return '昨日 $time';
  }

  @override
  String get connectingToDapp => 'dApp に接続中...';

  @override
  String get signMessageTitle => 'メッセージに署名';

  @override
  String get messageToSign => 'メッセージ';

  @override
  String get signBtn => '署名';

  @override
  String get searchOrEnterUrl => '検索または URL を入力';

  @override
  String get renameWalletTitle => 'ウォレット名を変更';

  @override
  String get renameWalletPromptDesc => 'ウォレットの新しい名前を入力してください。';

  @override
  String get walletNameLabel => 'ウォレット名';

  @override
  String get save => '保存';

  @override
  String get rename => '名前変更';

  @override
  String get marketOrder => '成行';

  @override
  String get limitOrder => '指値';

  @override
  String get limitPriceLabel => '指値価格';

  @override
  String get placeLimitOrder => '指値注文を出す';

  @override
  String get manageCoins => 'コインを管理';

  @override
  String get dAppBrowser => 'Xeris web4 ブラウザ';

  @override
  String connectedTo(String publicKey) {
    return '接続済み: $publicKey';
  }

  @override
  String get selectCurrency => '通貨を選択';

  @override
  String get stakeXrs => 'XRS をステーキング';

  @override
  String availableXrs(String balance) {
    return '利用可能: $balance XRS';
  }

  @override
  String get confirmStake => 'ステーキングを確認';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return '流動性を追加: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => '入金を確認';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => '取引を確認';

  @override
  String get youAreSending => '送金内容';

  @override
  String get confirmAndSend => '確認して送信';

  @override
  String get biometricAuthFailed => '認証に失敗しました。生体認証を有効にできません。';

  @override
  String get couldNotOpenLink => 'リンクを開けませんでした';

  @override
  String get recoveryPhraseWarning =>
      'このフレーズを絶対に共有しないでください。これらの単語を知っている人は誰でもあなたの資産を盗むことができます。';

  @override
  String get noWalletFound => 'ウォレットが見つかりません。';

  @override
  String get recoveryPhraseCopied => 'リカバリーフレーズをクリップボードにコピーしました';

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get authFailed => '認証に失敗しました';

  @override
  String get marketCap => '時価総額';

  @override
  String get totalHolders => '総保有者数';

  @override
  String get mintAddress => 'ミントアドレス';

  @override
  String get totalSupply => '総供給量';

  @override
  String get recentActivity => '最近のアクティビティ';

  @override
  String get tokenDecimals => '小数点桁数';

  @override
  String get tokenStandard => 'トークン規格';

  @override
  String get noActivityForToken => 'このトークンの最近のアクティビティはありません。';

  @override
  String get navAgents => 'エージェント';

  @override
  String get agentsTitle => 'AI エージェント';

  @override
  String get yourAgents => 'あなたのエージェント';

  @override
  String get openTasks => 'オープンタスク';

  @override
  String get registerAgentTitle => 'エージェントを登録';

  @override
  String get registerAgentDesc =>
      'エージェントは委任された権限で自律的に動作します。支出制限はオンチェーンで超過できないため、慎重に設定してください。';

  @override
  String get agentNameLabel => 'エージェント名';

  @override
  String get agentNamePlaceholder => '例: Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'エージェント公開鍵';

  @override
  String get agentPubKeyPlaceholder => 'Base58 Ed25519 公開鍵';

  @override
  String get maxPerTxLabel => '取引ごとの最大額 (XRS)';

  @override
  String get dailyBudgetLabel => '1日の予算 (XRS)';

  @override
  String get allowedContractsLabel => '許可されたコントラクト';

  @override
  String get allowedContractsPlaceholder => 'pool_mtk_xrs, ... (カンマ区切り)';

  @override
  String get registerAgentBtn => 'エージェントを登録';

  @override
  String get revokeAgentBtn => '取り消す';

  @override
  String get claimTaskBtn => '請求';

  @override
  String get lastHeartbeatPrefix => '最終ハートビート: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count 件アクティブ';
  }

  @override
  String get sendPrivately => 'プライベート送信';

  @override
  String get sendPrivatelyDesc => 'ZK proof によりオンチェーンで金額が非表示になります';

  @override
  String get zkpInfoBox =>
      '送金額はオンチェーンで非表示になります。あなたと受信者だけが値を確認できます。税務記録のためにブラインドファクターを保存してください。';

  @override
  String get generateProofAndSend => 'Proof を生成して送信';

  @override
  String get quantumShieldTitle => 'クォンタムシールド';

  @override
  String get quantumShieldSubtitle => 'ポスト量子暗号';

  @override
  String get quantumShieldDesc => 'ポスト量子暗号 (ML-DSA-65) でウォレットを保護します';

  @override
  String get quantumProtectionActive => '量子保護が有効';

  @override
  String get notProtected => '保護されていません';

  @override
  String get pqSecurityLevel => 'ML-DSA-65 · 128 ビット PQ セキュリティ';

  @override
  String get vulnerableToQuantum => '量子攻撃に対して脆弱';

  @override
  String get statusActive => '有効';

  @override
  String get statusOff => 'オフ';

  @override
  String get zkProofsUsed => '使用された ZK Proof';

  @override
  String get pqKeysRegistered => '登録された PQ 鍵';

  @override
  String get blockTimeStat => 'ブロック時間';

  @override
  String get quantumProtectedDesc =>
      'あなたのウォレットは量子保護されています。ML-DSA-65 で署名された送金にはエクスプローラーで 🛡 バッジが表示されます。';

  @override
  String get enableQuantumProtectionDesc =>
      '量子保護を有効にすると ML-DSA-65 鍵ペアが生成され、公開鍵がオンチェーンに登録されます。これは一度きりのセットアップです。';

  @override
  String get sendWithQuantumSigning => '量子署名で送信';

  @override
  String get enableQuantumProtectionBtn => '量子保護を有効にする';

  @override
  String get quantumEnabledSuccess => '量子保護が有効になりました！';

  @override
  String failedToEnablePq(String error) {
    return '有効化に失敗しました: $error';
  }

  @override
  String get quantumBackupTitle => '量子アイデンティティをバックアップ';

  @override
  String get quantumBackupWarning =>
      '12単語のニーモニックだけではこのウォレットを復元できなくなります。Quantum Secret Key を必ずバックアップしてください。';

  @override
  String get quantumSecretKeyLabel => 'QUANTUM SECRET KEY';

  @override
  String get backupConfirmedLabel => 'Quantum Secret Key を安全にバックアップしました';

  @override
  String get viewRecoveryKey => 'リカバリーキーを表示';

  @override
  String get pinCodeTitle => 'PIN コード';

  @override
  String get pinCodeSubtitle => '6桁の PIN でウォレットを保護';

  @override
  String get changePinCodeTitle => 'PIN コードを変更';

  @override
  String get changePinCodeSubtitle => 'セキュリティ PIN を更新';

  @override
  String get pinCodeUpdated => 'PIN コードを正常に更新しました';

  @override
  String get noAgentsRegistered => '登録されたエージェントはありません。';

  @override
  String get noOpenTasks => 'オープンタスクはありません。';

  @override
  String get refresh => '更新';

  @override
  String get zkpOnlyXrsError => 'ZKP プライベート送金は現在 XRS のみ対応しています。';

  @override
  String get pqcOnlyXrsError => '量子署名された送金は現在 XRS のみ対応しています。';

  @override
  String get required => '必須';

  @override
  String get enterPinCode => 'PIN コードを入力';

  @override
  String get setNewPin => '新しい PIN を設定';

  @override
  String get confirmPin => 'PIN を確認';

  @override
  String get pinSubtitle => '6桁の PIN で資産を保護します';

  @override
  String get incorrectPin => 'PIN が正しくありません';

  @override
  String get pinsDoNotMatch => 'PIN が一致しません。もう一度お試しください。';

  @override
  String get panicPinTitle => 'パニック PIN（自己破壊）';

  @override
  String get panicPinSubtitle => '入力するとすべてのデータを消去するコード';

  @override
  String get setPanicPin => 'パニック PIN を設定';

  @override
  String get confirmPanicPin => 'パニック PIN を確認';

  @override
  String get panicTriggered => 'パニック PIN がトリガーされました。すべてのデータが削除されました。';

  @override
  String agentMaxPerTx(Object amount) {
    return '取引ごと最大: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return '1日: $amount XRS';
  }

  @override
  String get appLockedTitle => 'Xeris ウォレットはロックされています';

  @override
  String get authenticateToContinue => '続行するには認証してください';

  @override
  String get securityAudit => 'セキュリティ監査';

  @override
  String get biometricLockActive => '生体認証ロックが有効';

  @override
  String get pinProtected6Digit => '6桁 PIN で保護';

  @override
  String get privacyModeEnabled => 'プライバシーモードが有効';

  @override
  String get privacyModeDisabled => 'プライバシーモードが無効';

  @override
  String get fullDiskEncryption => 'フルディスク暗号化';

  @override
  String get zkProofAsyncInfo =>
      'Xeris は非同期 ZK proof 生成を使用し、ウォレットの操作を妨げることなくプライバシーを維持します。';

  @override
  String get unknownToken => '不明なトークン';

  @override
  String get signTransactionTitle => '取引に署名';

  @override
  String get signAndSendTransactionTitle => '署名して取引を送信';

  @override
  String signAllTransactionsTitle(int count) {
    return '$count 件の取引に署名';
  }

  @override
  String get connectToDappDesc => 'このアプリは Xeris ウォレットに接続して公開アドレスを表示しようとしています。';

  @override
  String get signTransactionDesc => 'このアプリは取引への署名を要求しています。承認する前に注意深く確認してください。';

  @override
  String signAllTransactionsDesc(int count) {
    return 'このアプリは $count 件の取引にまとめて署名するよう要求しています。';
  }

  @override
  String get signMessageDesc => 'このアプリは検証のためメッセージへの署名を要求しています。';

  @override
  String get dappRequestUnknown => 'このアプリはウォレットへのアクセスを要求しています。';

  @override
  String get wrapXrs => 'XRS をラップ';

  @override
  String get unwrapXrs => 'XRS をアンラップ';

  @override
  String get swapLabel => 'スワップ';

  @override
  String get interactLabel => '操作';

  @override
  String get noActiveLimitOrders => 'アクティブな指値注文はありません';

  @override
  String get sellingLabel => '売却';

  @override
  String get buyingMinLabel => '購入（最小）';

  @override
  String get targetPriceLabel => '目標価格';

  @override
  String get orderIdLabel => '注文 ID';

  @override
  String get cancelOrderTitle => '注文をキャンセル';

  @override
  String get cancelOrderConfirm => 'この指値注文をキャンセルしてもよろしいですか？資金はウォレットに返却されます。';

  @override
  String get no => 'いいえ';

  @override
  String get yesCancel => 'はい、キャンセル';

  @override
  String get cancelTxSubmitted => 'キャンセル取引が送信されました';

  @override
  String get cancelTxFailed => 'キャンセルの送信に失敗しました';

  @override
  String get noMatchingValidators => '一致するバリデーターはありません';

  @override
  String get searchTokenPlaceholder => 'トークンを検索...';

  @override
  String get zkpTransferSubmitted => 'ZKP 送金が送信されました！';

  @override
  String get paste => '貼り付け';

  @override
  String get myWallet => 'マイウォレット';

  @override
  String get networkFee => 'ネットワーク手数料';

  @override
  String get openStatus => 'オープン';

  @override
  String get toLabel => '宛先';

  @override
  String get networkLabel => 'ネットワーク';

  @override
  String get testnetLabel => 'テストネット';

  @override
  String get mainnetLabel => 'メインネット';

  @override
  String get mainnetSoon => 'メインネットは近日公開予定';

  @override
  String get connectedSitesTitle => '接続済みサイト';

  @override
  String get connectedSitesSubtitle => 'dApp の権限を管理';

  @override
  String get noConnectedSites => '接続済みサイトはありません';

  @override
  String get noConnectedSitesDesc =>
      'ブラウザから接続したサイトがここに表示されます。いつでもアクセスを取り消すことができます。';

  @override
  String get connectedSiteRevoked => 'サイトのアクセスを取り消しました';

  @override
  String get revokeAllSitesTitle => 'すべてのサイトを取り消しますか？';

  @override
  String get revokeAllSitesDesc =>
      'これにより、すべてのウェブサイトがウォレットから切断されます。再度アクセスをリクエストする必要があります。';

  @override
  String get revokeAll => 'すべて取り消す';

  @override
  String get revoke => '取り消す';

  @override
  String get allSitesRevoked => 'すべてのサイトの権限を取り消しました';

  @override
  String get addressBookTitle => 'アドレス帳';

  @override
  String get addressBookSubtitle => '保存した連絡先を管理';

  @override
  String get themeTitle => 'テーマ';

  @override
  String get selectTheme => 'テーマを選択';

  @override
  String get themeDark => 'ダークモード';

  @override
  String get themeLight => 'ライトモード';

  @override
  String get themeSolar => 'ソーラーフレア';

  @override
  String get themeCyberpunk => 'サイバーパンク';

  @override
  String get themeSystem => 'システム設定';

  @override
  String get themeNameDark => 'ダーク';

  @override
  String get themeNameLight => 'ライト';

  @override
  String get themeNameSolar => 'ソーラーフレア';

  @override
  String get themeNameCyberpunk => 'サイバーパンク';

  @override
  String get themeNameSystem => 'システム';
}
