// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get manageWalletsTitle => 'Manage Wallets';

  @override
  String get manageWalletsSubtitle => 'Add, remove, or switch wallets';

  @override
  String get recoveryPhraseTitle => 'Recovery Phrase';

  @override
  String get recoveryPhraseSubtitle => 'View your secret seed phrase secured';

  @override
  String get generalSection => 'General';

  @override
  String get currencyTitle => 'Currency';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle => 'Receive alerts for transactions';

  @override
  String get privacyModeTitle => 'Privacy Mode';

  @override
  String get privacyModeSubtitle => 'Obscure balances on the dashboard';

  @override
  String get securitySection => 'Security';

  @override
  String get biometricTitle => 'Biometric Authentication';

  @override
  String get biometricSubtitle => 'Require Face ID / Fingerprint on startup';

  @override
  String get supportSection => 'Support';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsOfServiceSubtitle => 'Read our terms of service';

  @override
  String get aboutWalletTitle => 'About Xeris Wallet';

  @override
  String get languageTitle => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get addressCopied => 'Address copied to clipboard';

  @override
  String get loadingAddress => 'Loading...';

  @override
  String get errorLoadingAddress => 'Error loading address';

  @override
  String get sinceLastMonth => 'Since Last Month';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String comingSoon(String itemName) {
    return '$itemName details coming soon!';
  }

  @override
  String get actionSend => 'Send';

  @override
  String get actionReceive => 'Receive';

  @override
  String get actionSwap => 'Swap';

  @override
  String get actionEarn => 'Earn';

  @override
  String get actionScan => 'Scan';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navBrowser => 'Browser';

  @override
  String get navActivity => 'Activity';

  @override
  String get balanceHistoryTitle => 'Balance History';

  @override
  String get totalBalanceTitle => 'Total Balance';

  @override
  String get noHistoryAvailable => 'No history available';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get addWalletTitle => 'Add Wallet';

  @override
  String get addWalletSubtitle => 'How would you like to add a wallet?';

  @override
  String get createNewWallet => 'Create New Wallet';

  @override
  String get createNewWalletDesc =>
      'Generate a new 12-word secret recovery phrase';

  @override
  String get importExistingWallet => 'Import Existing Wallet';

  @override
  String get importExistingWalletDesc =>
      'Restore using a secret recovery phrase';

  @override
  String get myWalletsTitle => 'My Wallets';

  @override
  String get noWallets => 'No Wallets';

  @override
  String get noWalletsDesc =>
      'You don\'t have any wallets yet. Create or import your first wallet to get started.';

  @override
  String get deleteWalletPromptTitle => 'Delete Wallet?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return 'Are you sure you want to delete \"$walletName\"? This action cannot be undone unless you have your recovery phrase saved.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get unlockWallet => 'Unlock Wallet';

  @override
  String get authRequired => 'Authentication required.';

  @override
  String get verifySecretPhraseTitle => 'Verify Secret Phrase';

  @override
  String get verifyBackup => 'Verify your backup';

  @override
  String get verifyBackupDesc =>
      'Enter the following words from your secret phrase to confirm you have saved them.';

  @override
  String wordNumber(String number) {
    return 'Word #$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Enter word #$number';
  }

  @override
  String get verifyComplete => 'Verify & Complete';

  @override
  String get walletVerified => 'Wallet verified and secured!';

  @override
  String failedCreateWallet(String error) {
    return 'Failed to create wallet: $error';
  }

  @override
  String get incorrectWords =>
      'Incorrect words. Please check your phrase and try again.';

  @override
  String get importWalletTitle => 'Import Wallet';

  @override
  String get enterSecretPhrase => 'Enter Secret Phrase';

  @override
  String get enterRecoveryPhraseDesc =>
      'Enter your 12 or 24-word recovery phrase to restore your wallet.';

  @override
  String get invalidRecoveryPhrase => 'Invalid recovery phrase';

  @override
  String get walletImportedSuccess => 'Wallet imported successfully!';

  @override
  String failedImportWallet(String error) {
    return 'Failed to import wallet: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Secret Recovery Phrase';

  @override
  String get secretPhraseMasterKeyDesc =>
      'This secret phrase is the master key to your wallet. Write it down and store it in a secure place. Never share it with anyone.';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get secretPhraseCopied => 'Secret phrase copied to clipboard';

  @override
  String get savedSecretPhraseBtn => 'I have saved my secret phrase';

  @override
  String get welcomeTo => 'Welcome to\nXeris Wallet';

  @override
  String get secureWalletForChain => 'The secure wallet for the Xeris Chain.';

  @override
  String get createANewWallet => 'Create a New Wallet';

  @override
  String get alreadyHaveWallet => 'I already have a wallet';

  @override
  String get sendAssetsTitle => 'Send Assets';

  @override
  String get recipientAddress => 'Recipient Address';

  @override
  String get pasteAddressOrScan => 'Paste address or scan QR';

  @override
  String get amount => 'Amount';

  @override
  String get max => 'MAX';

  @override
  String get review => 'Review';

  @override
  String balance(String amount, String symbol) {
    return 'Balance: $amount $symbol';
  }

  @override
  String get errorEnterRecipient => 'Please enter a recipient address';

  @override
  String get errorInvalidAddress => 'Invalid Xeris Chain address';

  @override
  String get errorEnterValidAmount => 'Please enter a valid amount';

  @override
  String get errorInsufficientBalance => 'Insufficient balance';

  @override
  String get receiveAssetsTitle => 'Receive Assets';

  @override
  String get scanToReceive => 'Scan to Receive';

  @override
  String get sendOnlyXerisAssets =>
      'Send only Xeris Chain assets to this address.';

  @override
  String get shareAddress => 'Share Address';

  @override
  String get swapTitle => 'Swap';

  @override
  String get from => 'From';

  @override
  String get toEstimated => 'To (Estimated)';

  @override
  String get price => 'Price';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Slippage Tolerance';

  @override
  String get swapping => 'Swapping...';

  @override
  String get selectToken => 'Select Token';

  @override
  String get scanQrCodeTitle => 'Scan QR Code';

  @override
  String get alignQrCode => 'Align QR code within the frame';

  @override
  String get earnRewardsTitle => 'Earn Rewards';

  @override
  String get noValidatorsFound =>
      'No validators found on testnet.\nYou can still try staking to network.';

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
  String get directStake => 'Direct Stake';

  @override
  String get stakedBalance => 'Staked Balance';

  @override
  String totalStaked(String amount) {
    return 'Total Staked: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Commission: $value%';
  }

  @override
  String get searchValidators => 'Search Validators';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Confirm Stake';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'You are about to stake $amount XRS to $validator.';
  }

  @override
  String get confirmUnstakeTitle => 'Confirm Unstake';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'You are about to unstake $amount XRS from $validator.';
  }

  @override
  String get unbondingNotice => '7-day unbonding period applies';

  @override
  String get transactionSubmitted => 'Transaction Submitted';

  @override
  String get transactionFailed => 'Transaction Failed';

  @override
  String get txSubmittedDesc =>
      'Your transaction has been submitted to the Xeris network.';

  @override
  String hashLabel(String hash) {
    return 'Hash: $hash';
  }

  @override
  String get txHashCopied => 'Transaction hash copied to clipboard';

  @override
  String get viewInExplorer => 'View in Explorer';

  @override
  String get backToDashboard => 'Back to Dashboard';

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
  String get failedStatus => 'Failed';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String connectToDapp(String dappName) {
    return 'Connect to $dappName?';
  }

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String get details => 'DETAILS';

  @override
  String get activityTitle => 'Activity';

  @override
  String get noActivityYet => 'No Activity Yet';

  @override
  String get noActivityDesc =>
      'Your transactions will appear here once you send or receive funds.';

  @override
  String get errorLoadingActivity => 'Error loading activity';

  @override
  String get activitySearchHint => 'Search address, tx hash, or token';

  @override
  String get activityFilterAll => 'All';

  @override
  String get activityFilterSent => 'Sent';

  @override
  String get activityFilterReceived => 'Received';

  @override
  String get activityFilterSwap => 'Swap';

  @override
  String get activityFilterFailed => 'Failed';

  @override
  String get activityNoMatches => 'No matches';

  @override
  String get activityNoMatchesDesc => 'Try adjusting your filters or search';

  @override
  String get unknownAddress => 'Unknown';

  @override
  String receivedAsset(String symbol) {
    return 'Received $symbol';
  }

  @override
  String sentAsset(String symbol) {
    return 'Sent $symbol';
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
  String get execContract => 'Exec';

  @override
  String todayAt(String time) {
    return 'Today $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday $time';
  }

  @override
  String get connectingToDapp => 'Connecting to dApp...';

  @override
  String get signMessageTitle => 'Sign Message';

  @override
  String get messageToSign => 'MESSAGE';

  @override
  String get signBtn => 'Sign';

  @override
  String get searchOrEnterUrl => 'Search or enter URL';

  @override
  String get renameWalletTitle => 'Rename Wallet';

  @override
  String get renameWalletPromptDesc => 'Enter a new name for your wallet.';

  @override
  String get walletNameLabel => 'Wallet Name';

  @override
  String get save => 'Save';

  @override
  String get rename => 'Rename';

  @override
  String get marketOrder => 'Market';

  @override
  String get limitOrder => 'Limit';

  @override
  String get limitPriceLabel => 'Limit Price';

  @override
  String get placeLimitOrder => 'Place Limit Order';

  @override
  String get manageCoins => 'Manage Coins';

  @override
  String get dAppBrowser => 'Xeris web4 browser';

  @override
  String connectedTo(String publicKey) {
    return 'Connected: $publicKey';
  }

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get stakeXrs => 'Stake XRS';

  @override
  String availableXrs(String balance) {
    return 'Available: $balance XRS';
  }

  @override
  String get confirmStake => 'Confirm Stake';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Add Liquidity: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'Confirm Deposit';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Review Transaction';

  @override
  String get youAreSending => 'You are sending';

  @override
  String get confirmAndSend => 'Confirm & Send';

  @override
  String get biometricAuthFailed =>
      'Authentication failed. Cannot enable biometrics.';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get recoveryPhraseWarning =>
      'Never share this phrase. Anyone with these words can steal your assets.';

  @override
  String get noWalletFound => 'No wallet found.';

  @override
  String get recoveryPhraseCopied => 'Recovery phrase copied to clipboard';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get authFailed => 'Authentication failed';

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
  String get sendPrivately => 'Send Privately';

  @override
  String get sendPrivatelyDesc => 'Amount hidden on-chain via ZK proof';

  @override
  String get zkpInfoBox =>
      'The transfer amount will be hidden on-chain. Only you and the recipient can verify the value. Save your blinding factor for tax records.';

  @override
  String get generateProofAndSend => 'Generate Proof & Send';

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
  String get quantumBackupTitle => 'Backup Quantum Identity';

  @override
  String get quantumBackupWarning =>
      'Your 12-word mnemonic is no longer enough to recover this wallet. You MUST back up this Quantum Secret Key.';

  @override
  String get quantumSecretKeyLabel => 'QUANTUM SECRET KEY';

  @override
  String get backupConfirmedLabel =>
      'I have securely backed up my Quantum Secret Key';

  @override
  String get viewRecoveryKey => 'View Recovery Key';

  @override
  String get pinCodeTitle => 'PIN Code';

  @override
  String get pinCodeSubtitle => 'Secure wallet with a 6-digit PIN';

  @override
  String get changePinCodeTitle => 'Change PIN Code';

  @override
  String get changePinCodeSubtitle => 'Update your security PIN';

  @override
  String get pinCodeUpdated => 'PIN Code updated successfully';

  @override
  String get noAgentsRegistered => 'No agents registered.';

  @override
  String get noOpenTasks => 'No open tasks.';

  @override
  String get refresh => 'Refresh';

  @override
  String get zkpOnlyXrsError =>
      'ZKP private transfers only support XRS at this time.';

  @override
  String get pqcOnlyXrsError =>
      'Quantum Signed transfers currently only support XRS.';

  @override
  String get required => 'Required';

  @override
  String get enterPinCode => 'Enter PIN Code';

  @override
  String get setNewPin => 'Set a New PIN';

  @override
  String get confirmPin => 'Confirm Your PIN';

  @override
  String get pinSubtitle => 'Secure your assets with a 6-digit PIN';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get pinsDoNotMatch => 'PINs do not match. Try again.';

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
    return 'Daily: $amount XRS';
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
  String get signTransactionTitle => 'Sign Transaction';

  @override
  String get signAndSendTransactionTitle => 'Sign & Send Transaction';

  @override
  String signAllTransactionsTitle(int count) {
    return 'Sign $count Transactions';
  }

  @override
  String get connectToDappDesc =>
      'This app wants to connect to your Xeris wallet and view your public address.';

  @override
  String get signTransactionDesc =>
      'This app wants you to sign a transaction. Review carefully before approving.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'This app wants you to sign $count transactions at once.';
  }

  @override
  String get signMessageDesc =>
      'This app wants you to sign a message for verification.';

  @override
  String get dappRequestUnknown => 'This app is requesting wallet access.';

  @override
  String get wrapXrs => 'Wrap XRS';

  @override
  String get unwrapXrs => 'Unwrap XRS';

  @override
  String get swapLabel => 'Swap';

  @override
  String get interactLabel => 'Interact';

  @override
  String get noActiveLimitOrders => 'No active limit orders';

  @override
  String get sellingLabel => 'Selling';

  @override
  String get buyingMinLabel => 'Buying (Min)';

  @override
  String get targetPriceLabel => 'Target Price';

  @override
  String get orderIdLabel => 'Order ID';

  @override
  String get cancelOrderTitle => 'Cancel Order';

  @override
  String get cancelOrderConfirm =>
      'Are you sure you want to cancel this limit order? Funds will be returned to your wallet.';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get cancelTxSubmitted => 'Cancellation transaction submitted';

  @override
  String get cancelTxFailed => 'Failed to submit cancellation';

  @override
  String get noMatchingValidators => 'No matching validators';

  @override
  String get searchTokenPlaceholder => 'Search token...';

  @override
  String get zkpTransferSubmitted => 'ZKP Transfer Submitted!';

  @override
  String get paste => 'Paste';

  @override
  String get myWallet => 'My Wallet';

  @override
  String get networkFee => 'Network Fee';

  @override
  String get openStatus => 'OPEN';

  @override
  String get toLabel => 'To';

  @override
  String get networkLabel => 'Network';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String get mainnetSoon => 'Mainnet is coming soon';

  @override
  String get connectedSitesTitle => 'Connected Sites';

  @override
  String get connectedSitesSubtitle => 'Manage dApp permissions';

  @override
  String get noConnectedSites => 'No Connected Sites';

  @override
  String get noConnectedSitesDesc =>
      'Sites you connect to via the browser will appear here. You can revoke their access at any time.';

  @override
  String get connectedSiteRevoked => 'Site access revoked';

  @override
  String get revokeAllSitesTitle => 'Revoke All Sites?';

  @override
  String get revokeAllSitesDesc =>
      'This will disconnect all websites from your wallet. They will need to request access again.';

  @override
  String get revokeAll => 'Revoke All';

  @override
  String get revoke => 'Revoke';

  @override
  String get allSitesRevoked => 'All site permissions revoked';

  @override
  String get addressBookTitle => 'Address Book';

  @override
  String get addressBookSubtitle => 'Manage saved contacts';

  @override
  String get themeTitle => 'Theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeNameDark => 'Dark';

  @override
  String get themeNameLight => 'Light';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'System';
}
