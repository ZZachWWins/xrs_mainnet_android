// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get settingsTitle => 'Mga Setting';

  @override
  String get accountSection => 'Account';

  @override
  String get manageWalletsTitle => 'Pamahalaan ang mga Wallet';

  @override
  String get manageWalletsSubtitle =>
      'Magdagdag, mag-alis, o magpalit ng mga wallet';

  @override
  String get recoveryPhraseTitle => 'Recovery Phrase';

  @override
  String get recoveryPhraseSubtitle =>
      'Tingnan ang iyong sikretong seed phrase nang ligtas';

  @override
  String get generalSection => 'Pangkalahatan';

  @override
  String get currencyTitle => 'Pera';

  @override
  String get notificationsTitle => 'Mga Abiso';

  @override
  String get notificationsSubtitle =>
      'Tumanggap ng mga alerto para sa mga transaksyon';

  @override
  String get privacyModeTitle => 'Privacy Mode';

  @override
  String get privacyModeSubtitle => 'Obscure balances on the dashboard';

  @override
  String get securitySection => 'Seguridad';

  @override
  String get biometricTitle => 'Biometric Authentication';

  @override
  String get biometricSubtitle =>
      'Nangangailangan ng Face ID / Fingerprint sa pagsisimula';

  @override
  String get supportSection => 'Suporta';

  @override
  String get privacyPolicyTitle => 'Patakaran sa Privacy';

  @override
  String get privacyPolicySubtitle => 'Basahin ang aming patakaran sa privacy';

  @override
  String get termsOfServiceTitle => 'Mga Tuntunin ng Serbisyo';

  @override
  String get termsOfServiceSubtitle =>
      'Basahin ang aming mga tuntunin ng serbisyo';

  @override
  String get aboutWalletTitle => 'Tungkol sa Xeris Wallet';

  @override
  String get languageTitle => 'Wika';

  @override
  String get selectLanguage => 'Pumili ng Wika';

  @override
  String get addressCopied => 'Address nakopya sa clipboard';

  @override
  String get loadingAddress => 'Naglo-load...';

  @override
  String get errorLoadingAddress => 'Error sa pag-load ng address';

  @override
  String get sinceLastMonth => 'Mula noong nakaraang buwan';

  @override
  String get tokensTitle => 'Mga Token';

  @override
  String comingSoon(String itemName) {
    return 'Malapit na ang mga detalye ng $itemName!';
  }

  @override
  String get actionSend => 'Magpadala';

  @override
  String get actionReceive => 'Tumanggap';

  @override
  String get actionSwap => 'Ipagpalit';

  @override
  String get actionEarn => 'Kumita';

  @override
  String get actionScan => 'I-scan';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navBrowser => 'Browser';

  @override
  String get navActivity => 'Aktibidad';

  @override
  String get balanceHistoryTitle => 'Kasaysayan ng Balanse';

  @override
  String get totalBalanceTitle => 'Kabuuang Balanse';

  @override
  String get noHistoryAvailable => 'Walang magagamit na kasaysayan';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get addWalletTitle => 'Magdagdag ng Wallet';

  @override
  String get addWalletSubtitle => 'Paano mo gustong magdagdag ng wallet?';

  @override
  String get createNewWallet => 'Lumikha ng Bagong Wallet';

  @override
  String get createNewWalletDesc =>
      'Bumuo ng bagong 12-salitang sikretong recovery phrase';

  @override
  String get importExistingWallet => 'Mag-import ng Umiiral na Wallet';

  @override
  String get importExistingWalletDesc =>
      'I-restore gamit ang sikretong recovery phrase';

  @override
  String get myWalletsTitle => 'Aking Mga Wallet';

  @override
  String get noWallets => 'Walang Mga Wallet';

  @override
  String get noWalletsDesc =>
      'Wala ka pang anumang mga wallet. Lumikha o mag-import ng iyong unang wallet upang makapagsimula.';

  @override
  String get deleteWalletPromptTitle => 'Tanggalin ang Wallet?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return 'Sigurado ka bang gusto mong tanggalin ang \"$walletName\"? Ang pagkilos na ito ay hindi maaaring bawiin maliban kung nai-save mo ang iyong recovery phrase.';
  }

  @override
  String get cancel => 'Kanselahin';

  @override
  String get delete => 'Tanggalin';

  @override
  String get unlockWallet => 'I-unlock ang Wallet';

  @override
  String get authRequired => 'Kailangan ng pagpapatunay.';

  @override
  String get verifySecretPhraseTitle => 'I-verify ang Secret Phrase';

  @override
  String get verifyBackup => 'I-verify ang iyong backup';

  @override
  String get verifyBackupDesc =>
      'Ipasok ang mga sumusunod na salita mula sa iyong secret phrase upang kumpirmahin na na-save mo ito.';

  @override
  String wordNumber(String number) {
    return 'Salita #$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Ipasok ang salita #$number';
  }

  @override
  String get verifyComplete => 'I-verify at Kumpletuhin';

  @override
  String get walletVerified => 'Na-verify at ligtas na ang wallet!';

  @override
  String failedCreateWallet(String error) {
    return 'Nabigo sa paggawa ng wallet: $error';
  }

  @override
  String get incorrectWords =>
      'Maling mga salita. Pakisuri ang iyong phrase at subukan muli.';

  @override
  String get importWalletTitle => 'Mag-import ng Wallet';

  @override
  String get enterSecretPhrase => 'Ipasok ang Secret Phrase';

  @override
  String get enterRecoveryPhraseDesc =>
      'Ipasok ang iyong 12 o 24-salitang recovery phrase upang maibalik ang iyong wallet.';

  @override
  String get invalidRecoveryPhrase => 'Imbalidong recovery phrase';

  @override
  String get walletImportedSuccess => 'Matagumpay na na-import ang wallet!';

  @override
  String failedImportWallet(String error) {
    return 'Nabigo sa pag-import ng wallet: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Secret Recovery Phrase';

  @override
  String get secretPhraseMasterKeyDesc =>
      'Ang sikretong phrase na ito ay ang master key ng iyong wallet. Isulat ito at itago sa ligtas na lugar. Huwag hinding-hindi ibahagi kaninuman.';

  @override
  String get copyToClipboard => 'Kopyahin sa Clipboard';

  @override
  String get secretPhraseCopied => 'Sikretong phrase nakopya sa clipboard';

  @override
  String get savedSecretPhraseBtn =>
      'Nai-save ko na ang aking sikretong phrase';

  @override
  String get welcomeTo => 'Maligayang pagdating sa\nXeris Wallet';

  @override
  String get secureWalletForChain =>
      'Ang ligtas na wallet para sa Xeris Chain.';

  @override
  String get createANewWallet => 'Gumawa ng Bagong Wallet';

  @override
  String get alreadyHaveWallet => 'Mayroon na akong wallet';

  @override
  String get sendAssetsTitle => 'Magpadala ng mga Asset';

  @override
  String get recipientAddress => 'Address ng Tatanggap';

  @override
  String get pasteAddressOrScan => 'Idikit ang address o i-scan ang QR';

  @override
  String get amount => 'Halaga';

  @override
  String get max => 'MAX';

  @override
  String get review => 'Suriin';

  @override
  String balance(String amount, String symbol) {
    return 'Balanse: $amount $symbol';
  }

  @override
  String get errorEnterRecipient =>
      'Mangyaring maglagay ng address ng tatanggap';

  @override
  String get errorInvalidAddress => 'Imbalidong address ng Xeris Chain';

  @override
  String get errorEnterValidAmount => 'Mangyaring maglagay ng wastong halaga';

  @override
  String get errorInsufficientBalance => 'Kulang ang balanse';

  @override
  String get receiveAssetsTitle => 'Makatanggap ng mga Asset';

  @override
  String get scanToReceive => 'I-scan para Makatanggap';

  @override
  String get sendOnlyXerisAssets =>
      'Magpadala lamang ng mga asset ng Xeris Chain sa address na ito.';

  @override
  String get shareAddress => 'Ibahagi ang Address';

  @override
  String get swapTitle => 'Ipagpalit';

  @override
  String get from => 'Mula';

  @override
  String get toEstimated => 'Papunta (Tinatantya)';

  @override
  String get price => 'Presyo';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Slippage Tolerance';

  @override
  String get swapping => 'Nagpapalit...';

  @override
  String get selectToken => 'Pumili ng Token';

  @override
  String get scanQrCodeTitle => 'I-scan ang QR Code';

  @override
  String get alignQrCode => 'Ihanay ang QR code sa loob ng frame';

  @override
  String get earnRewardsTitle => 'Kumita ng Mga Gantimpala';

  @override
  String get noValidatorsFound =>
      'Walang nakitang validators sa testnet.\nMaaari mo pa ring subukang mag-stake sa network.';

  @override
  String validatorAddress(String address) {
    return 'Validator $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'Stake: $amount XRS';
  }

  @override
  String get stake => 'Stake';

  @override
  String get unstake => 'Unstake';

  @override
  String get directStake => 'Direktang Stake';

  @override
  String get stakedBalance => 'Staked Balance';

  @override
  String totalStaked(String amount) {
    return 'Total Staked: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Komisyon: $value%';
  }

  @override
  String get searchValidators => 'Maghanap ng Validators';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Kumpirmahin ang Stake';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'Magsa-stake ka ng $amount XRS sa $validator.';
  }

  @override
  String get confirmUnstakeTitle => 'Kumpirmahin ang Unstake';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'Mag-a-unstake ka ng $amount XRS mula sa $validator.';
  }

  @override
  String get unbondingNotice => 'May 7-araw na unbonding period';

  @override
  String get transactionSubmitted => 'Naipadala ang Transaksyon';

  @override
  String get transactionFailed => 'Nabigo ang Transaksyon';

  @override
  String get txSubmittedDesc =>
      'Ang iyong transaksyon ay naipadala sa Xeris network.';

  @override
  String hashLabel(String hash) {
    return 'Hash: $hash';
  }

  @override
  String get txHashCopied => 'Nakopya ang hash ng transaksyon sa clipboard';

  @override
  String get viewInExplorer => 'Tingnan sa Explorer';

  @override
  String get backToDashboard => 'Bumalik sa Dashboard';

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
  String get failedStatus => 'Nabigo';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String connectToDapp(String dappName) {
    return 'Kumonekta sa $dappName?';
  }

  @override
  String get reject => 'Tanggihan';

  @override
  String get approve => 'Aprubahan';

  @override
  String get details => 'MGA DETALYE';

  @override
  String get activityTitle => 'Aktibidad';

  @override
  String get noActivityYet => 'Wala pang Aktibidad';

  @override
  String get noActivityDesc =>
      'Ang iyong mga transaksyon ay lilitaw dito kapag nagpadala o tumanggap ka ng pondo.';

  @override
  String get errorLoadingActivity => 'Error sa pag-load ng aktibidad';

  @override
  String get activitySearchHint => 'Maghanap ng address, tx hash, o token';

  @override
  String get activityFilterAll => 'Lahat';

  @override
  String get activityFilterSent => 'Naipadala';

  @override
  String get activityFilterReceived => 'Natanggap';

  @override
  String get activityFilterSwap => 'Swap';

  @override
  String get activityFilterFailed => 'Nabigo';

  @override
  String get activityNoMatches => 'Walang katugma';

  @override
  String get activityNoMatchesDesc =>
      'Subukang ayusin ang iyong filter o paghahanap';

  @override
  String get unknownAddress => 'Hindi kilala';

  @override
  String receivedAsset(String symbol) {
    return 'Natanggap $symbol';
  }

  @override
  String sentAsset(String symbol) {
    return 'Ipinadala $symbol';
  }

  @override
  String fromAddress(String address) {
    return 'Mula kay: $address';
  }

  @override
  String toAddress(String address) {
    return 'Para kay: $address';
  }

  @override
  String get execContract => 'Ehek';

  @override
  String todayAt(String time) {
    return 'Ngayon $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Kahapon $time';
  }

  @override
  String get connectingToDapp => 'Kumokonekta sa dApp...';

  @override
  String get signMessageTitle => 'Pirmahan ang Mensahe';

  @override
  String get messageToSign => 'MENSAJE';

  @override
  String get signBtn => 'Pirmahan';

  @override
  String get searchOrEnterUrl => 'Maghanap o ipasok ang URL';

  @override
  String get renameWalletTitle => 'Palitan ang Pangalan ng Wallet';

  @override
  String get renameWalletPromptDesc =>
      'Maglagay ng bagong pangalan para sa iyong wallet.';

  @override
  String get walletNameLabel => 'Pangalan ng Wallet';

  @override
  String get save => 'I-save';

  @override
  String get rename => 'Palitan ang Pangalan';

  @override
  String get marketOrder => 'Market';

  @override
  String get limitOrder => 'Limit';

  @override
  String get limitPriceLabel => 'Presyo ng Limit';

  @override
  String get placeLimitOrder => 'Maglagay ng Limit Order';

  @override
  String get manageCoins => 'Pamahalaan ang mga Coin';

  @override
  String get dAppBrowser => 'dApp Browser';

  @override
  String connectedTo(String publicKey) {
    return 'Nakakonekta sa: $publicKey';
  }

  @override
  String get selectCurrency => 'Pumili ng Currency';

  @override
  String get stakeXrs => 'I-stake ang XRS';

  @override
  String availableXrs(String balance) {
    return 'Available: $balance XRS';
  }

  @override
  String get confirmStake => 'I-kumpirma ang Stake';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Magdagdag ng Liquidity: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'I-kumpirma ang Deposit';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Suriin ang Transaksyon';

  @override
  String get youAreSending => 'Nagpapadala ka ng';

  @override
  String get confirmAndSend => 'Kumpirmahin at Ipadala';

  @override
  String get biometricAuthFailed =>
      'Nabigo ang pagpapatunay. Hindi paganahin ang biometrics.';

  @override
  String get couldNotOpenLink => 'Hindi mabuksan ang link';

  @override
  String get recoveryPhraseWarning =>
      'Huwag kailanman ibahagi ang pariralang ito. Kahit sino na may mga salitang ito ay maaaring magnakaw ng iyong mga asset.';

  @override
  String get noWalletFound => 'Walang natagpuang wallet.';

  @override
  String get recoveryPhraseCopied => 'Kinopya ang recovery phrase sa clipboard';

  @override
  String versionLabel(String version) {
    return 'Bersyon $version';
  }

  @override
  String get authFailed => 'Nabigo ang pagpapatunay';

  @override
  String get marketCap => 'Market Cap';

  @override
  String get totalHolders => 'Kabuuang Holder';

  @override
  String get mintAddress => 'Address ng Mint';

  @override
  String get totalSupply => 'Kabuuang Supply';

  @override
  String get recentActivity => 'Kamakailang Aktibidad';

  @override
  String get tokenDecimals => 'Decimals';

  @override
  String get tokenStandard => 'Token Standard';

  @override
  String get noActivityForToken =>
      'Walang kamakailang aktibidad para sa token na ito.';

  @override
  String get navAgents => 'Mga Ahente';

  @override
  String get agentsTitle => 'AI Ahente';

  @override
  String get yourAgents => 'Ang iyong mga Ahente';

  @override
  String get openTasks => 'Mga Bukas na Gawain';

  @override
  String get registerAgentTitle => 'I-rehistro ang Ahente';

  @override
  String get registerAgentDesc =>
      'Ang mga ahente ay awtonomong gumagana nang may delegadong awtoridad. Magtakda ng limitasyon sa paggastos nang maingat — hindi sila maaaring lumampas dito on-chain.';

  @override
  String get agentNameLabel => 'PANGALAN NG AHENTE';

  @override
  String get agentNamePlaceholder => 'e.g. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'PUBLIC KEY NG AHENTE';

  @override
  String get agentPubKeyPlaceholder => 'Base58 Ed25519 pubkey';

  @override
  String get maxPerTxLabel => 'MAX KADA TRANSAKSYON (XRS)';

  @override
  String get dailyBudgetLabel => 'ARAW-ARAW NA BUDGET (XRS)';

  @override
  String get allowedContractsLabel => 'MGA PINAYAGANG KONTRATA';

  @override
  String get allowedContractsPlaceholder =>
      'pool_mtk_xrs, ... (gamit ang kuwit)';

  @override
  String get registerAgentBtn => 'I-rehistro ang Ahente';

  @override
  String get revokeAgentBtn => 'Bawiin';

  @override
  String get claimTaskBtn => 'Kunin';

  @override
  String get lastHeartbeatPrefix => 'Huling tibay: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count AKTIBO';
  }

  @override
  String get sendPrivately => 'Ipadala nang Pribado';

  @override
  String get sendPrivatelyDesc =>
      'Halaga ay nakatago sa chain sa pamamagitan ng ZK proof';

  @override
  String get zkpInfoBox =>
      'Ang halaga ng padala ay itatago sa chain. Ikaw at ang tatanggap lamang ang makakakita ng halaga. I-save ang iyong blinding factor para sa mga talaan ng buwis.';

  @override
  String get generateProofAndSend => 'Bumuo ng Katibayan at Ipadala';

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
  String get quantumBackupTitle => 'I-backup ang Quantum Identity';

  @override
  String get quantumBackupWarning =>
      'Hindi na sapat ang iyong 12-salitang mnemonic upang ma-recover ang wallet na ito. DAPAT mong i-backup ang Quantum Secret Key na ito.';

  @override
  String get quantumSecretKeyLabel => 'QUANTUM SECRET KEY';

  @override
  String get backupConfirmedLabel =>
      'Ligtas kong na-backup ang aking Quantum Secret Key';

  @override
  String get viewRecoveryKey => 'Tingnan ang Recovery Key';

  @override
  String get pinCodeTitle => 'PIN Code';

  @override
  String get pinCodeSubtitle => 'Secure wallet with a 6-digit PIN';

  @override
  String get changePinCodeTitle => 'Change PIN Code';

  @override
  String get changePinCodeSubtitle => 'Update your security PIN';

  @override
  String get pinCodeUpdated => 'Matagumpay na na-update ang PIN Code';

  @override
  String get noAgentsRegistered => 'Walang rehistradong mga ahente.';

  @override
  String get noOpenTasks => 'Walang mga bukas na gawain.';

  @override
  String get refresh => 'I-refresh';

  @override
  String get zkpOnlyXrsError =>
      'Ang ZKP private transfers ay sumusuporta lamang sa XRS sa ngayon.';

  @override
  String get pqcOnlyXrsError =>
      'Ang Quantum Signed transfers ay kasalukuyang sumusuporta lamang sa XRS.';

  @override
  String get required => 'Kailangan';

  @override
  String get enterPinCode => 'Ipasok ang PIN Code';

  @override
  String get setNewPin => 'Magtakda ng Bagong PIN';

  @override
  String get confirmPin => 'Kumpirmahin ang iyong PIN';

  @override
  String get pinSubtitle =>
      'I-secure ang iyong mga asset gamit ang 6-digit na PIN';

  @override
  String get incorrectPin => 'Maling PIN';

  @override
  String get pinsDoNotMatch => 'Hindi magkatugma ang mga PIN. Subukan muli.';

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
    return 'Max/tx: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return 'Araw-araw: $amount XRS';
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
  String get signTransactionTitle => 'Pirmahan ang Transaksyon';

  @override
  String get signAndSendTransactionTitle =>
      'Pirmahan at Ipadala ang Transaksyon';

  @override
  String signAllTransactionsTitle(int count) {
    return 'Pirmahan ang $count Transaksyon';
  }

  @override
  String get connectToDappDesc =>
      'Gustong kumonekta ng app na ito sa iyong Xeris wallet at tingnan ang iyong public address.';

  @override
  String get signTransactionDesc =>
      'Gusto ng app na ito na pirmahan mo ang isang transaksyon. Suriin nang mabuti bago aprubahan.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'Gusto ng app na ito na pirmahan mo ang $count transaksyon nang sabay-sabay.';
  }

  @override
  String get signMessageDesc =>
      'Gusto ng app na ito na pirmahan mo ang isang mensahe para sa verification.';

  @override
  String get dappRequestUnknown =>
      'Humihiling ang app na ito ng wallet access.';

  @override
  String get wrapXrs => 'I-wrap ang XRS';

  @override
  String get unwrapXrs => 'I-unwrap ang XRS';

  @override
  String get swapLabel => 'Swap';

  @override
  String get interactLabel => 'Makipag-ugnayan';

  @override
  String get noActiveLimitOrders => 'Walang aktibong limit orders';

  @override
  String get sellingLabel => 'Nagbebenta';

  @override
  String get buyingMinLabel => 'Bumibili (Min)';

  @override
  String get targetPriceLabel => 'Target Price';

  @override
  String get orderIdLabel => 'Order ID';

  @override
  String get cancelOrderTitle => 'Kanselahin ang Order';

  @override
  String get cancelOrderConfirm =>
      'Sigurado ka bang kanselahin ang limit order na ito? Ibabalik ang pondo sa iyong wallet.';

  @override
  String get no => 'Hindi';

  @override
  String get yesCancel => 'Oo, Kanselahin';

  @override
  String get cancelTxSubmitted => 'Naisumite ang transaksyon ng kanselasyon';

  @override
  String get cancelTxFailed => 'Nabigo ang pagsumite ng kanselasyon';

  @override
  String get noMatchingValidators => 'Walang tumutugmang validators';

  @override
  String get searchTokenPlaceholder => 'Maghanap ng token...';

  @override
  String get zkpTransferSubmitted => 'Naisumite ang ZKP Transfer!';

  @override
  String get paste => 'I-paste';

  @override
  String get myWallet => 'Aking Wallet';

  @override
  String get networkFee => 'Network Fee';

  @override
  String get openStatus => 'BUKAS';

  @override
  String get toLabel => 'Kay';

  @override
  String get networkLabel => 'Network';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String get mainnetSoon => 'Malapit na ang Mainnet';

  @override
  String get connectedSitesTitle => 'Mga Konektadong Site';

  @override
  String get connectedSitesSubtitle => 'Pamahalaan ang mga pahintulot ng dApp';

  @override
  String get noConnectedSites => 'Walang Konektadong Site';

  @override
  String get noConnectedSitesDesc =>
      'Ang mga site na kinokonekta mo sa pamamagitan ng browser ay lalabas dito. Maaari mong bawiin ang kanilang access anumang oras.';

  @override
  String get connectedSiteRevoked => 'Binawi ang access sa site';

  @override
  String get revokeAllSitesTitle => 'Bawiin ang lahat ng site?';

  @override
  String get revokeAllSitesDesc =>
      'Ididiskonekta nito ang lahat ng website mula sa iyong wallet. Kailangan nilang humiling muli ng access.';

  @override
  String get revokeAll => 'Bawiin Lahat';

  @override
  String get revoke => 'Bawiin';

  @override
  String get allSitesRevoked => 'Lahat ng pahintulot ng site ay binawi';

  @override
  String get addressBookTitle => 'Address Book';

  @override
  String get addressBookSubtitle => 'Pamahalaan ang mga naka-save na contact';

  @override
  String get themeTitle => 'Tema';

  @override
  String get selectTheme => 'Pumili ng Tema';

  @override
  String get themeDark => 'Madilim na Mode';

  @override
  String get themeLight => 'Maliwanag na Mode';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'Default ng Sistema';

  @override
  String get themeNameDark => 'Madilim';

  @override
  String get themeNameLight => 'Maliwanag';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'Sistema';
}
