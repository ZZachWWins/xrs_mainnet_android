// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '设置';

  @override
  String get accountSection => '账户';

  @override
  String get manageWalletsTitle => '管理钱包';

  @override
  String get manageWalletsSubtitle => '添加、删除或切换钱包';

  @override
  String get recoveryPhraseTitle => '恢复短语';

  @override
  String get recoveryPhraseSubtitle => '安全地查看您的秘密助记词';

  @override
  String get generalSection => '常规';

  @override
  String get currencyTitle => '货币';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsSubtitle => '接收交易警报';

  @override
  String get privacyModeTitle => 'Privacy Mode';

  @override
  String get privacyModeSubtitle => 'Obscure balances on the dashboard';

  @override
  String get securitySection => '安全';

  @override
  String get biometricTitle => '生物识别认证';

  @override
  String get biometricSubtitle => '启动时需要面部ID / 指纹';

  @override
  String get supportSection => '支持';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get privacyPolicySubtitle => '阅读我们的隐私政策';

  @override
  String get termsOfServiceTitle => '服务条款';

  @override
  String get termsOfServiceSubtitle => '阅读我们的服务条款';

  @override
  String get aboutWalletTitle => '关于 Xeris Wallet';

  @override
  String get languageTitle => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get addressCopied => '地址已复制到剪贴板';

  @override
  String get loadingAddress => '加载中...';

  @override
  String get errorLoadingAddress => '加载地址出错';

  @override
  String get sinceLastMonth => '自上个月以来';

  @override
  String get tokensTitle => '代币';

  @override
  String comingSoon(String itemName) {
    return '$itemName 详情即将推出！';
  }

  @override
  String get actionSend => '发送';

  @override
  String get actionReceive => '接收';

  @override
  String get actionSwap => '交换';

  @override
  String get actionEarn => '赚钱';

  @override
  String get actionScan => '扫描';

  @override
  String get navWallet => '钱包';

  @override
  String get navBrowser => '浏览器';

  @override
  String get navActivity => '活动';

  @override
  String get balanceHistoryTitle => '余额历史';

  @override
  String get totalBalanceTitle => '总余额';

  @override
  String get noHistoryAvailable => '无历史记录可用';

  @override
  String errorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String get addWalletTitle => '添加钱包';

  @override
  String get addWalletSubtitle => '您想如何添加钱包？';

  @override
  String get createNewWallet => '创建新钱包';

  @override
  String get createNewWalletDesc => '生成新的12字恢复短语';

  @override
  String get importExistingWallet => '导入现有钱包';

  @override
  String get importExistingWalletDesc => '使用秘密恢复短语恢复';

  @override
  String get myWalletsTitle => '我的钱包';

  @override
  String get noWallets => '没有钱包';

  @override
  String get noWalletsDesc => '您目前没有任何钱包。创建或导入您的第一个钱包即可开始。';

  @override
  String get deleteWalletPromptTitle => '删除钱包？';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return '您确定要删除 \"$walletName\" 吗？除非您已保存恢复短语，否则此操作无法撤消。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get unlockWallet => '解锁钱包';

  @override
  String get authRequired => '需要身份验证。';

  @override
  String get verifySecretPhraseTitle => '验证秘密短语';

  @override
  String get verifyBackup => '验证您的备份';

  @override
  String get verifyBackupDesc => '输入秘密短语中的以下单词以确认您已保存它们。';

  @override
  String wordNumber(String number) {
    return '第 $number 个单词';
  }

  @override
  String enterWordNumber(String number) {
    return '输入第 $number 个单词';
  }

  @override
  String get verifyComplete => '验证并完成';

  @override
  String get walletVerified => '钱包已验证并受到保护！';

  @override
  String failedCreateWallet(String error) {
    return '创建钱包失败：$error';
  }

  @override
  String get incorrectWords => '单词不正确。请检查您的短语并重试。';

  @override
  String get importWalletTitle => '导入钱包';

  @override
  String get enterSecretPhrase => '输入秘密短语';

  @override
  String get enterRecoveryPhraseDesc => '输入您的 12 或 24 字恢复短语以恢复您的钱包。';

  @override
  String get invalidRecoveryPhrase => '恢复短语无效';

  @override
  String get walletImportedSuccess => '成功导入钱包！';

  @override
  String failedImportWallet(String error) {
    return '导入钱包失败：$error';
  }

  @override
  String get secretRecoveryPhraseTitle => '秘密恢复短语';

  @override
  String get secretPhraseMasterKeyDesc =>
      '这个秘密短语是您钱包的万能钥匙。把它写下来并保存在安全的地方。切勿与任何人分享。';

  @override
  String get copyToClipboard => '复制到剪贴板';

  @override
  String get secretPhraseCopied => '秘密短语已复制到剪贴板';

  @override
  String get savedSecretPhraseBtn => '我已保存我的秘密短语';

  @override
  String get welcomeTo => '欢迎来到\nXeris 钱包';

  @override
  String get secureWalletForChain => 'Xeris 链的安全钱包。';

  @override
  String get createANewWallet => '创建一个新钱包';

  @override
  String get alreadyHaveWallet => '我已经有一个钱包';

  @override
  String get sendAssetsTitle => '发送资产';

  @override
  String get recipientAddress => '收件人地址';

  @override
  String get pasteAddressOrScan => '粘贴地址或扫描二维码';

  @override
  String get amount => '金额';

  @override
  String get max => '最大';

  @override
  String get review => '审查';

  @override
  String balance(String amount, String symbol) {
    return '余额：$amount $symbol';
  }

  @override
  String get errorEnterRecipient => '请输入收件人地址';

  @override
  String get errorInvalidAddress => '无效的 Xeris 链地址';

  @override
  String get errorEnterValidAmount => '请输入有效金额';

  @override
  String get errorInsufficientBalance => '余额不足';

  @override
  String get receiveAssetsTitle => '接收资产';

  @override
  String get scanToReceive => '扫描接收';

  @override
  String get sendOnlyXerisAssets => '仅向此地址发送 Xeris 链资产。';

  @override
  String get shareAddress => '分享地址';

  @override
  String get swapTitle => '交换';

  @override
  String get from => '从';

  @override
  String get toEstimated => '到（估计）';

  @override
  String get price => '价格';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => '滑点容忍度';

  @override
  String get swapping => '交换中...';

  @override
  String get selectToken => '选择代币';

  @override
  String get scanQrCodeTitle => '扫描二维码';

  @override
  String get alignQrCode => '将二维码对准框内';

  @override
  String get earnRewardsTitle => '赚取奖励';

  @override
  String get noValidatorsFound => '测试网络上未找到验证者。\n您仍然可以尝试质押到网络。';

  @override
  String validatorAddress(String address) {
    return '验证者 $address...';
  }

  @override
  String stakeAmount(String amount) {
    return '质押：$amount XRS';
  }

  @override
  String get stake => '质押';

  @override
  String get unstake => '解除质押';

  @override
  String get directStake => '直接质押';

  @override
  String get stakedBalance => '质押余额';

  @override
  String totalStaked(String amount) {
    return '总质押：$amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return '佣金：$value%';
  }

  @override
  String get searchValidators => '搜索验证者';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => '确认质押';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return '您即将向 $validator 质押 $amount XRS。';
  }

  @override
  String get confirmUnstakeTitle => '确认解除质押';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return '您即将从 $validator 解除质押 $amount XRS。';
  }

  @override
  String get unbondingNotice => '适用 7 天解除质押期';

  @override
  String get transactionSubmitted => '交易已提交';

  @override
  String get transactionFailed => '交易失败';

  @override
  String get txSubmittedDesc => '您的交易已提交到 Xeris 网络。';

  @override
  String hashLabel(String hash) {
    return '哈希：$hash';
  }

  @override
  String get txHashCopied => '交易哈希已复制到剪贴板';

  @override
  String get viewInExplorer => '在浏览器中查看';

  @override
  String get backToDashboard => '返回仪表板';

  @override
  String get shareReceipt => 'Share Receipt';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get receiptTitle => 'Xeris Transaction Receipt';

  @override
  String get dateLabel => 'Date';

  @override
  String get statusLabel => 'Status';

  @override
  String get successStatus => 'Success';

  @override
  String get failedStatus => '失败';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String connectToDapp(String dappName) {
    return '连接到 $dappName 吗？';
  }

  @override
  String get reject => '拒绝';

  @override
  String get approve => '批准';

  @override
  String get details => '详细信息';

  @override
  String get activityTitle => '活动';

  @override
  String get noActivityYet => '暂无活动';

  @override
  String get noActivityDesc => '一旦您发送或接收资金，您的交易就会出现在这里。';

  @override
  String get errorLoadingActivity => '加载活动时出错';

  @override
  String get activitySearchHint => '搜索地址、交易哈希或代币';

  @override
  String get activityFilterAll => '全部';

  @override
  String get activityFilterSent => '发送';

  @override
  String get activityFilterReceived => '接收';

  @override
  String get activityFilterSwap => '兑换';

  @override
  String get activityFilterFailed => '失败';

  @override
  String get activityNoMatches => '无匹配项';

  @override
  String get activityNoMatchesDesc => '尝试调整筛选条件或搜索';

  @override
  String get unknownAddress => '未知';

  @override
  String receivedAsset(String symbol) {
    return '收到 $symbol';
  }

  @override
  String sentAsset(String symbol) {
    return '发送 $symbol';
  }

  @override
  String fromAddress(String address) {
    return '来自：$address';
  }

  @override
  String toAddress(String address) {
    return '发往：$address';
  }

  @override
  String get execContract => '执行';

  @override
  String todayAt(String time) {
    return '今天 $time';
  }

  @override
  String yesterdayAt(String time) {
    return '昨天 $time';
  }

  @override
  String get connectingToDapp => '正在连接到dApp...';

  @override
  String get signMessageTitle => '签名消息';

  @override
  String get messageToSign => '消息';

  @override
  String get signBtn => '签名';

  @override
  String get searchOrEnterUrl => '搜索或输入URL';

  @override
  String get renameWalletTitle => '重命名钱包';

  @override
  String get renameWalletPromptDesc => '输入钱包的新名称。';

  @override
  String get walletNameLabel => '钱包名称';

  @override
  String get save => '保存';

  @override
  String get rename => '重命名';

  @override
  String get marketOrder => '市价';

  @override
  String get limitOrder => '限价';

  @override
  String get limitPriceLabel => '限价价格';

  @override
  String get placeLimitOrder => '下限价单';

  @override
  String get manageCoins => '管理代币';

  @override
  String get dAppBrowser => 'dApp 浏览器';

  @override
  String connectedTo(String publicKey) {
    return '已连接到：$publicKey';
  }

  @override
  String get selectCurrency => '选择货币';

  @override
  String get stakeXrs => '质押 XRS';

  @override
  String availableXrs(String balance) {
    return '可用余额：$balance XRS';
  }

  @override
  String get confirmStake => '确认质押';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return '添加流动性：$tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => '确认存款';

  @override
  String get ok => '确定';

  @override
  String get reviewTransaction => '检查交易';

  @override
  String get youAreSending => '您正在发送';

  @override
  String get confirmAndSend => '确认并发送';

  @override
  String get biometricAuthFailed => '身份验证失败。无法启用生物识别。';

  @override
  String get couldNotOpenLink => '无法打开链接';

  @override
  String get recoveryPhraseWarning => '切勿分享此助记词。任何拥有这些单词的人都可以窃取您的资产。';

  @override
  String get noWalletFound => '未找到钱包。';

  @override
  String get recoveryPhraseCopied => '助记词已复制到剪贴板';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get authFailed => '身份验证失败';

  @override
  String get marketCap => 'Market Cap';

  @override
  String get totalHolders => 'Total Holders';

  @override
  String get mintAddress => 'Mint Address';

  @override
  String get totalSupply => 'Total Supply';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get tokenDecimals => 'Decimals';

  @override
  String get tokenStandard => 'Token Standard';

  @override
  String get noActivityForToken => 'No recent activity for this token.';

  @override
  String get navAgents => 'Agents';

  @override
  String get agentsTitle => 'AI Agents';

  @override
  String get yourAgents => 'Your Agents';

  @override
  String get openTasks => 'Open Tasks';

  @override
  String get registerAgentTitle => 'Register Agent';

  @override
  String get registerAgentDesc =>
      'Agents operate autonomously with delegated authority. Set spending limits carefully — they cannot exceed these on-chain.';

  @override
  String get agentNameLabel => 'AGENT NAME';

  @override
  String get agentNamePlaceholder => 'e.g. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'AGENT PUBLIC KEY';

  @override
  String get agentPubKeyPlaceholder => 'Base58 Ed25519 pubkey';

  @override
  String get maxPerTxLabel => 'MAX PER TRANSACTION (XRS)';

  @override
  String get dailyBudgetLabel => 'DAILY BUDGET (XRS)';

  @override
  String get allowedContractsLabel => 'ALLOWED CONTRACTS';

  @override
  String get allowedContractsPlaceholder =>
      'pool_mtk_xrs, ... (comma-separated)';

  @override
  String get registerAgentBtn => 'Register Agent';

  @override
  String get revokeAgentBtn => 'Revoke';

  @override
  String get claimTaskBtn => 'Claim';

  @override
  String get lastHeartbeatPrefix => 'Last heartbeat: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count ACTIVE';
  }

  @override
  String get sendPrivately => '私密发送';

  @override
  String get sendPrivatelyDesc => '通过 ZK 证明在链上隐藏金额';

  @override
  String get zkpInfoBox => '转账金额将在链上隐藏。只有您和收款人可以验证该值。请保存您的盲化因子以备税务记录。';

  @override
  String get generateProofAndSend => '生成证明并发送';

  @override
  String get quantumShieldTitle => 'Quantum Shield';

  @override
  String get quantumShieldSubtitle => 'Post-quantum cryptography';

  @override
  String get quantumShieldDesc =>
      'Protect your wallet with post-quantum cryptography (ML-DSA-65)';

  @override
  String get quantumProtectionActive => 'Quantum Protection Active';

  @override
  String get notProtected => 'Not Protected';

  @override
  String get pqSecurityLevel => 'ML-DSA-65 · 128-bit PQ security';

  @override
  String get vulnerableToQuantum => 'Vulnerable to quantum attacks';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusOff => 'OFF';

  @override
  String get zkProofsUsed => 'ZK Proofs Used';

  @override
  String get pqKeysRegistered => 'PQ Keys Registered';

  @override
  String get blockTimeStat => 'Block Time';

  @override
  String get quantumProtectedDesc =>
      'Your wallet is quantum-protected. Transfers signed with ML-DSA-65 show a 🛡 badge in the explorer.';

  @override
  String get enableQuantumProtectionDesc =>
      'Enabling quantum protection generates a ML-DSA-65 keypair and registers your public key on-chain. This is a one-time setup.';

  @override
  String get sendWithQuantumSigning => 'Send with Quantum Signing';

  @override
  String get enableQuantumProtectionBtn => 'Enable Quantum Protection';

  @override
  String get quantumEnabledSuccess => 'Quantum Protection Enabled!';

  @override
  String failedToEnablePq(String error) {
    return 'Failed to enable: $error';
  }

  @override
  String get quantumBackupTitle => '备份量子身份';

  @override
  String get quantumBackupWarning => '您的 12 词助记词已不足以恢复此钱包。您必须备份此量子密钥。';

  @override
  String get quantumSecretKeyLabel => '量子密钥';

  @override
  String get backupConfirmedLabel => '我已安全备份我的量子密钥';

  @override
  String get viewRecoveryKey => '查看恢复密钥';

  @override
  String get pinCodeTitle => 'PIN Code';

  @override
  String get pinCodeSubtitle => 'Secure wallet with a 6-digit PIN';

  @override
  String get changePinCodeTitle => 'Change PIN Code';

  @override
  String get changePinCodeSubtitle => 'Update your security PIN';

  @override
  String get pinCodeUpdated => 'PIN 码更新成功';

  @override
  String get noAgentsRegistered => '没有注册的代理。';

  @override
  String get noOpenTasks => '没有待办任务。';

  @override
  String get refresh => '刷新';

  @override
  String get zkpOnlyXrsError => 'ZKP 隐私转账目前仅支持 XRS。';

  @override
  String get pqcOnlyXrsError => '量子签名转账目前仅支持 XRS。';

  @override
  String get required => '必填';

  @override
  String get enterPinCode => '输入 PIN 码';

  @override
  String get setNewPin => '设置新 PIN 码';

  @override
  String get confirmPin => '确认 PIN 码';

  @override
  String get pinSubtitle => '使用 6 位 PIN 码保护您的资产';

  @override
  String get incorrectPin => 'PIN 码不正确';

  @override
  String get pinsDoNotMatch => 'PIN 码不匹配。请重试。';

  @override
  String get panicPinTitle => 'Panic PIN (Self-Destruct)';

  @override
  String get panicPinSubtitle => 'A code that wipes all data when entered';

  @override
  String get setPanicPin => 'Set Panic PIN';

  @override
  String get confirmPanicPin => 'Confirm Panic PIN';

  @override
  String get panicTriggered => 'Panic PIN triggered. All data cleared.';

  @override
  String agentMaxPerTx(Object amount) {
    return '最大单笔: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return '每日限额: $amount XRS';
  }

  @override
  String get appLockedTitle => 'Xeris Wallet Locked';

  @override
  String get authenticateToContinue => 'Authenticate to continue';

  @override
  String get securityAudit => 'SECURITY AUDIT';

  @override
  String get biometricLockActive => 'Biometric Lock Active';

  @override
  String get pinProtected6Digit => '6-Digit PIN Protected';

  @override
  String get privacyModeEnabled => 'Privacy Mode Enabled';

  @override
  String get privacyModeDisabled => 'Privacy Mode Disabled';

  @override
  String get fullDiskEncryption => 'Full Disk Encryption';

  @override
  String get zkProofAsyncInfo =>
      'Xeris uses asynchronous ZK proof generation to maintain privacy without blocking your wallet interaction.';

  @override
  String get unknownToken => 'Unknown Token';

  @override
  String get signTransactionTitle => '签署交易';

  @override
  String get signAndSendTransactionTitle => '签署并发送交易';

  @override
  String signAllTransactionsTitle(int count) {
    return '签署 $count 笔交易';
  }

  @override
  String get connectToDappDesc => '此应用想要连接到您的 Xeris 钱包并查看您的公共地址。';

  @override
  String get signTransactionDesc => '此应用希望您签署一笔交易。请在批准前仔细检查。';

  @override
  String signAllTransactionsDesc(int count) {
    return '此应用希望您一次签署 $count 笔交易。';
  }

  @override
  String get signMessageDesc => '此应用希望您签署一条消息以进行验证。';

  @override
  String get dappRequestUnknown => '此应用正在请求钱包访问权限。';

  @override
  String get wrapXrs => '包装 XRS';

  @override
  String get unwrapXrs => '解包 XRS';

  @override
  String get swapLabel => '兑换';

  @override
  String get interactLabel => '交互';

  @override
  String get noActiveLimitOrders => '无活动的限价单';

  @override
  String get sellingLabel => '卖出';

  @override
  String get buyingMinLabel => '买入（最低）';

  @override
  String get targetPriceLabel => '目标价格';

  @override
  String get orderIdLabel => '订单 ID';

  @override
  String get cancelOrderTitle => '取消订单';

  @override
  String get cancelOrderConfirm => '确定要取消此限价单吗？资金将返回到您的钱包。';

  @override
  String get no => '否';

  @override
  String get yesCancel => '是，取消';

  @override
  String get cancelTxSubmitted => '取消交易已提交';

  @override
  String get cancelTxFailed => '提交取消失败';

  @override
  String get noMatchingValidators => '无匹配的验证者';

  @override
  String get searchTokenPlaceholder => '搜索代币...';

  @override
  String get zkpTransferSubmitted => 'ZKP 转账已提交！';

  @override
  String get paste => '粘贴';

  @override
  String get myWallet => '我的钱包';

  @override
  String get networkFee => '网络费用';

  @override
  String get openStatus => '未成交';

  @override
  String get toLabel => '至';

  @override
  String get networkLabel => '网络';

  @override
  String get testnetLabel => '测试网';

  @override
  String get mainnetLabel => '主网';

  @override
  String get mainnetSoon => '主网即将上线';

  @override
  String get connectedSitesTitle => '已连接站点';

  @override
  String get connectedSitesSubtitle => '管理 dApp 权限';

  @override
  String get noConnectedSites => '无已连接站点';

  @override
  String get noConnectedSitesDesc => '通过浏览器连接的站点将显示在此处。您可以随时撤销其访问权限。';

  @override
  String get connectedSiteRevoked => '站点访问已撤销';

  @override
  String get revokeAllSitesTitle => '撤销所有站点？';

  @override
  String get revokeAllSitesDesc => '这将断开所有网站与您钱包的连接。它们需要重新请求访问权限。';

  @override
  String get revokeAll => '全部撤销';

  @override
  String get revoke => '撤销';

  @override
  String get allSitesRevoked => '所有站点权限已撤销';

  @override
  String get addressBookTitle => '通讯录';

  @override
  String get addressBookSubtitle => '管理已保存的联系人';

  @override
  String get themeTitle => '主题';

  @override
  String get selectTheme => '选择主题';

  @override
  String get themeDark => '深色模式';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeSolar => '太阳耀斑';

  @override
  String get themeCyberpunk => '赛博朋克';

  @override
  String get themeSystem => '系统默认';

  @override
  String get themeNameDark => '深色';

  @override
  String get themeNameLight => '浅色';

  @override
  String get themeNameSolar => '太阳耀斑';

  @override
  String get themeNameCyberpunk => '赛博朋克';

  @override
  String get themeNameSystem => '系统';
}
