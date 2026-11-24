// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get accountSection => 'Account';

  @override
  String get manageWalletsTitle => 'Beheer Wallets';

  @override
  String get manageWalletsSubtitle =>
      'Wallets toevoegen, verwijderen of wisselen';

  @override
  String get recoveryPhraseTitle => 'Herstelzin';

  @override
  String get recoveryPhraseSubtitle => 'Bekijk uw geheime herstelzin veilig';

  @override
  String get generalSection => 'Algemeen';

  @override
  String get currencyTitle => 'Valuta';

  @override
  String get notificationsTitle => 'Meldingen';

  @override
  String get notificationsSubtitle => 'Ontvang waarschuwingen voor transacties';

  @override
  String get privacyModeTitle => 'Privacy Modus';

  @override
  String get privacyModeSubtitle => 'Saldo\'s op het dashboard verbergen';

  @override
  String get securitySection => 'Beveiliging';

  @override
  String get biometricTitle => 'Biometrische Authenticatie';

  @override
  String get biometricSubtitle => 'Vereis Face ID / Vingerafdruk bij opstarten';

  @override
  String get supportSection => 'Ondersteuning';

  @override
  String get privacyPolicyTitle => 'Privacybeleid';

  @override
  String get privacyPolicySubtitle => 'Lees ons privacybeleid';

  @override
  String get termsOfServiceTitle => 'Servicevoorwaarden';

  @override
  String get termsOfServiceSubtitle => 'Lees onze servicevoorwaarden';

  @override
  String get aboutWalletTitle => 'Over Xeris Wallet';

  @override
  String get languageTitle => 'Taal';

  @override
  String get selectLanguage => 'Selecteer Taal';

  @override
  String get addressCopied => 'Adres gekopieerd naar klembord';

  @override
  String get loadingAddress => 'Laden...';

  @override
  String get errorLoadingAddress => 'Fout bij laden adres';

  @override
  String get sinceLastMonth => 'Sinds Vorige Maand';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String comingSoon(String itemName) {
    return '$itemName details binnenkort beschikbaar!';
  }

  @override
  String get actionSend => 'Verzenden';

  @override
  String get actionReceive => 'Ontvangen';

  @override
  String get actionSwap => 'Wisselen';

  @override
  String get actionEarn => 'Verdienen';

  @override
  String get actionScan => 'Scannen';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navBrowser => 'Browser';

  @override
  String get navActivity => 'Activiteit';

  @override
  String get balanceHistoryTitle => 'Saldogeschiedenis';

  @override
  String get totalBalanceTitle => 'Totaal Saldo';

  @override
  String get noHistoryAvailable => 'Geen geschiedenis beschikbaar';

  @override
  String errorPrefix(String error) {
    return 'Fout: $error';
  }

  @override
  String get addWalletTitle => 'Wallet Toevoegen';

  @override
  String get addWalletSubtitle => 'Hoe wilt u een wallet toevoegen?';

  @override
  String get createNewWallet => 'Nieuwe Wallet Aanmaken';

  @override
  String get createNewWalletDesc => 'Genereer een nieuwe 12-woorden herstelzin';

  @override
  String get importExistingWallet => 'Bestaande Wallet Importeren';

  @override
  String get importExistingWalletDesc =>
      'Herstellen met een geheime herstelzin';

  @override
  String get myWalletsTitle => 'Mijn Wallets';

  @override
  String get noWallets => 'Geen Wallets';

  @override
  String get noWalletsDesc =>
      'U heeft nog geen wallets. Maak of importeer uw eerste wallet om te beginnen.';

  @override
  String get deleteWalletPromptTitle => 'Wallet Verwijderen?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return 'Weet u zeker dat u \"$walletName\" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt, tenzij u uw herstelzin heeft opgeslagen.';
  }

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get unlockWallet => 'Wallet Ontgrendelen';

  @override
  String get authRequired => 'Authenticatie vereist.';

  @override
  String get verifySecretPhraseTitle => 'Verifieer Geheime Herstelzin';

  @override
  String get verifyBackup => 'Verifieer uw back-up';

  @override
  String get verifyBackupDesc =>
      'Voer de volgende woorden van uw herstelzin in om te bevestigen dat u ze heeft opgeslagen.';

  @override
  String wordNumber(String number) {
    return 'Woord #$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Voer woord #$number in';
  }

  @override
  String get verifyComplete => 'Verifiëren en Voltooien';

  @override
  String get walletVerified => 'Wallet geverifieerd en beveiligd!';

  @override
  String failedCreateWallet(String error) {
    return 'Kan wallet niet aanmaken: $error';
  }

  @override
  String get incorrectWords =>
      'Onjuiste woorden. Controleer uw herstelzin en probeer het opnieuw.';

  @override
  String get importWalletTitle => 'Wallet Importeren';

  @override
  String get enterSecretPhrase => 'Voer Geheime Herstelzin in';

  @override
  String get enterRecoveryPhraseDesc =>
      'Voer uw 12 of 24-woorden herstelzin in om uw wallet te herstellen.';

  @override
  String get invalidRecoveryPhrase => 'Ongeldige herstelzin';

  @override
  String get walletImportedSuccess => 'Wallet succesvol geïmporteerd!';

  @override
  String failedImportWallet(String error) {
    return 'Kan wallet niet importeren: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Geheime Herstelzin';

  @override
  String get secretPhraseMasterKeyDesc =>
      'Deze herstelzin is de hoofdsleutel van uw wallet. Schrijf de herstelzin op een stuk papier en bewaar het op een veilige plek. Deel het met niemand.';

  @override
  String get copyToClipboard => 'Kopiëren naar klembord';

  @override
  String get secretPhraseCopied =>
      'Geheime herstelzin naar klembord gekopieerd';

  @override
  String get savedSecretPhraseBtn => 'Ik heb mijn herstelzin opgeslagen';

  @override
  String get welcomeTo => 'Welkom bij\nXeris Wallet';

  @override
  String get secureWalletForChain => 'De veilige wallet voor de Xeris Chain.';

  @override
  String get createANewWallet => 'Nieuwe Wallet Aanmaken';

  @override
  String get alreadyHaveWallet => 'Ik heb al een wallet';

  @override
  String get sendAssetsTitle => 'Activa Verzenden';

  @override
  String get recipientAddress => 'Ontvangstadres';

  @override
  String get pasteAddressOrScan => 'Plak adres of scan QR';

  @override
  String get amount => 'Bedrag';

  @override
  String get max => 'MAX';

  @override
  String get review => 'Beoordelen';

  @override
  String balance(String amount, String symbol) {
    return 'Saldo: $amount $symbol';
  }

  @override
  String get errorEnterRecipient => 'Voer een ontvangstadres in';

  @override
  String get errorInvalidAddress => 'Ongeldig Xeris Chain adres';

  @override
  String get errorEnterValidAmount => 'Voer een geldig bedrag in';

  @override
  String get errorInsufficientBalance => 'Onvoldoende saldo';

  @override
  String get receiveAssetsTitle => 'Activa Ontvangen';

  @override
  String get scanToReceive => 'Scan om te Ontvangen';

  @override
  String get sendOnlyXerisAssets =>
      'Stuur alleen Xeris Chain activa naar dit adres.';

  @override
  String get shareAddress => 'Adres Delen';

  @override
  String get swapTitle => 'Wisselen';

  @override
  String get from => 'Van';

  @override
  String get toEstimated => 'Naar (Geschat)';

  @override
  String get price => 'Prijs';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Slippage Tolerantie';

  @override
  String get swapping => 'Wisselen...';

  @override
  String get selectToken => 'Selecteer Token';

  @override
  String get scanQrCodeTitle => 'Scan QR Code';

  @override
  String get alignQrCode => 'Plaats QR code in het kader';

  @override
  String get earnRewardsTitle => 'Beloningen Verdienen';

  @override
  String get noValidatorsFound =>
      'Geen validators gevonden op testnet.\nU kunt nog steeds proberen te staken naar het netwerk.';

  @override
  String validatorAddress(String address) {
    return 'Validator $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'Staken: $amount XRS';
  }

  @override
  String get stake => 'Staken';

  @override
  String get unstake => 'Unstaken';

  @override
  String get directStake => 'Direct Staken';

  @override
  String get stakedBalance => 'Gestaked Saldo';

  @override
  String totalStaked(String amount) {
    return 'Totaal Gestaked: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Commissie: $value%';
  }

  @override
  String get searchValidators => 'Validators Zoeken';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Stake Bevestigen';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'Je staat op het punt $amount XRS te staken op $validator.';
  }

  @override
  String get confirmUnstakeTitle => 'Unstake Bevestigen';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'Je staat op het punt $amount XRS te unstaken van $validator.';
  }

  @override
  String get unbondingNotice => 'Er geldt een ontbindingsperiode van 7 dagen';

  @override
  String get transactionSubmitted => 'Transactie Ingediend';

  @override
  String get transactionFailed => 'Transactie Mislukt';

  @override
  String get txSubmittedDesc =>
      'Uw transactie is ingediend bij het Xeris netwerk.';

  @override
  String hashLabel(String hash) {
    return 'Hash: $hash';
  }

  @override
  String get txHashCopied => 'Transactie hash naar klembord gekopieerd';

  @override
  String get viewInExplorer => 'Bekijk in Explorer';

  @override
  String get backToDashboard => 'Terug naar Dashboard';

  @override
  String get shareReceipt => 'Bewijs Delen';

  @override
  String get transactionDetails => 'Transactie Details';

  @override
  String get receiptTitle => 'Xeris Transactiebewijs';

  @override
  String get dateLabel => 'Datum';

  @override
  String get statusLabel => 'Status';

  @override
  String get successStatus => 'Succes';

  @override
  String get failedStatus => 'Mislukt';

  @override
  String get copiedToClipboard => 'Gekopieerd naar klembord';

  @override
  String connectToDapp(String dappName) {
    return 'Verbinden met $dappName?';
  }

  @override
  String get reject => 'Weigeren';

  @override
  String get approve => 'Goedkeuren';

  @override
  String get details => 'DETAILS';

  @override
  String get activityTitle => 'Activiteit';

  @override
  String get noActivityYet => 'Nog geen activiteit';

  @override
  String get noActivityDesc =>
      'Je transacties verschijnen hier zodra je geld verzendt of ontvangt.';

  @override
  String get errorLoadingActivity => 'Fout bij laden van activiteit';

  @override
  String get activitySearchHint => 'Zoek adres, tx-hash of token';

  @override
  String get activityFilterAll => 'Alle';

  @override
  String get activityFilterSent => 'Verzonden';

  @override
  String get activityFilterReceived => 'Ontvangen';

  @override
  String get activityFilterSwap => 'Swap';

  @override
  String get activityFilterFailed => 'Mislukt';

  @override
  String get activityNoMatches => 'Geen resultaten';

  @override
  String get activityNoMatchesDesc => 'Pas je filters of zoekopdracht aan';

  @override
  String get unknownAddress => 'Onbekend';

  @override
  String receivedAsset(String symbol) {
    return 'Ontvangen $symbol';
  }

  @override
  String sentAsset(String symbol) {
    return 'Verzonden $symbol';
  }

  @override
  String fromAddress(String address) {
    return 'Van: $address';
  }

  @override
  String toAddress(String address) {
    return 'Aan: $address';
  }

  @override
  String get execContract => 'Uitv';

  @override
  String todayAt(String time) {
    return 'Vandaag $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Gisteren $time';
  }

  @override
  String get connectingToDapp => 'Verbinden met dApp...';

  @override
  String get signMessageTitle => 'Onderteken bericht';

  @override
  String get messageToSign => 'BERICHT';

  @override
  String get signBtn => 'Ondertekenen';

  @override
  String get searchOrEnterUrl => 'Zoeken of URL invoeren';

  @override
  String get renameWalletTitle => 'Wallet hernoemen';

  @override
  String get renameWalletPromptDesc =>
      'Voer een nieuwe naam in voor uw wallet.';

  @override
  String get walletNameLabel => 'Wallet naam';

  @override
  String get save => 'Opslaan';

  @override
  String get rename => 'Hernoemen';

  @override
  String get marketOrder => 'Markt';

  @override
  String get limitOrder => 'Limiet';

  @override
  String get limitPriceLabel => 'Limietprijs';

  @override
  String get placeLimitOrder => 'Limietorder plaatsen';

  @override
  String get manageCoins => 'Munten beheren';

  @override
  String get dAppBrowser => 'dApp Browser';

  @override
  String connectedTo(String publicKey) {
    return 'Verbonden met: $publicKey';
  }

  @override
  String get selectCurrency => 'Valuta selecteren';

  @override
  String get stakeXrs => 'Stake XRS';

  @override
  String availableXrs(String balance) {
    return 'Beschikbaar: $balance XRS';
  }

  @override
  String get confirmStake => 'Staking bevestigen';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Liquiditeit toevoegen: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'Storting bevestigen';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Transactie beoordelen';

  @override
  String get youAreSending => 'Je verstuurt';

  @override
  String get confirmAndSend => 'Bevestigen & verzenden';

  @override
  String get biometricAuthFailed =>
      'Authenticatie mislukt. Kan biometrie niet inschakelen.';

  @override
  String get couldNotOpenLink => 'Kon link niet openen';

  @override
  String get recoveryPhraseWarning =>
      'Deel deze zin nooit. Iedereen met deze woorden kan uw activa stelen.';

  @override
  String get noWalletFound => 'Geen wallet gevonden.';

  @override
  String get recoveryPhraseCopied => 'Herstelzin gekopieerd naar klembord';

  @override
  String versionLabel(String version) {
    return 'Versie $version';
  }

  @override
  String get authFailed => 'Authenticatie mislukt';

  @override
  String get marketCap => 'Marktkapitalisatie';

  @override
  String get totalHolders => 'Totaal aantal houders';

  @override
  String get mintAddress => 'Mint-adres';

  @override
  String get totalSupply => 'Totale voorraad';

  @override
  String get recentActivity => 'Recente activiteit';

  @override
  String get tokenDecimals => 'Decimalen';

  @override
  String get tokenStandard => 'Tokenstandaard';

  @override
  String get noActivityForToken => 'Geen recente activiteit voor deze token.';

  @override
  String get navAgents => 'Agenten';

  @override
  String get agentsTitle => 'AI Agenten';

  @override
  String get yourAgents => 'Uw Agenten';

  @override
  String get openTasks => 'Open Taken';

  @override
  String get registerAgentTitle => 'Agent Registreren';

  @override
  String get registerAgentDesc =>
      'Agenten werken autonoom met gedelegeerde bevoegdheid. Stel uitgavenlimieten zorgvuldig in — ze kunnen deze on-chain niet overschrijden.';

  @override
  String get agentNameLabel => 'AGENT NAAM';

  @override
  String get agentNamePlaceholder => 'bijv. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'AGENT PUBLIEKE SLEUTEL';

  @override
  String get agentPubKeyPlaceholder => 'Base58 Ed25519 pubkey';

  @override
  String get maxPerTxLabel => 'MAX PER TRANSACTIE (XRS)';

  @override
  String get dailyBudgetLabel => 'DAGELIJKS BUDGET (XRS)';

  @override
  String get allowedContractsLabel => 'TOEGESTANE CONTRACTEN';

  @override
  String get allowedContractsPlaceholder =>
      'pool_mtk_xrs, ... (gescheiden door komma\'s)';

  @override
  String get registerAgentBtn => 'Agent Registreren';

  @override
  String get revokeAgentBtn => 'Intrekken';

  @override
  String get claimTaskBtn => 'Claimen';

  @override
  String get lastHeartbeatPrefix => 'Laatste hartslag: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count ACTIEF';
  }

  @override
  String get sendPrivately => 'Privé Verzenden';

  @override
  String get sendPrivatelyDesc => 'Bedrag verborgen on-chain via ZK bewijs';

  @override
  String get zkpInfoBox =>
      'Het overboekingsbedrag wordt on-chain verborgen. Alleen u en de ontvanger kunnen de waarde verifiëren. Bewaar uw blindingsfactor voor belastingdossiers.';

  @override
  String get generateProofAndSend => 'Bewijs Genereren & Verzenden';

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
  String get quantumBackupTitle => 'Quantum Identiteit Back-uppen';

  @override
  String get quantumBackupWarning =>
      'Je 12-woorden mnemonic is niet langer genoeg om deze wallet te herstellen. Je MOET deze Quantum Geheime Sleutel back-uppen.';

  @override
  String get quantumSecretKeyLabel => 'QUANTUM GEHEIME SLEUTEL';

  @override
  String get backupConfirmedLabel =>
      'Ik heb mijn Quantum Geheime Sleutel veilig geback-upt';

  @override
  String get viewRecoveryKey => 'Herstelsleutel Bekijken';

  @override
  String get pinCodeTitle => 'PIN Code';

  @override
  String get pinCodeSubtitle => 'Secure wallet with a 6-digit PIN';

  @override
  String get changePinCodeTitle => 'Change PIN Code';

  @override
  String get changePinCodeSubtitle => 'Update your security PIN';

  @override
  String get pinCodeUpdated => 'PIN-code succesvol bijgewerkt';

  @override
  String get noAgentsRegistered => 'Geen agenten geregistreerd.';

  @override
  String get noOpenTasks => 'Geen open taken.';

  @override
  String get refresh => 'Vernieuwen';

  @override
  String get zkpOnlyXrsError =>
      'ZKP privé overboekingen ondersteunen momenteel alleen XRS.';

  @override
  String get pqcOnlyXrsError =>
      'Quantum ondertekende overboekingen ondersteunen momenteel alleen XRS.';

  @override
  String get required => 'Vereist';

  @override
  String get enterPinCode => 'PIN-code invoeren';

  @override
  String get setNewPin => 'Nieuwe PIN instellen';

  @override
  String get confirmPin => 'Bevestig uw PIN';

  @override
  String get pinSubtitle => 'Beveilig uw activa met een 6-cijferige PIN';

  @override
  String get incorrectPin => 'Onjuiste PIN';

  @override
  String get pinsDoNotMatch => 'PINs komen niet overeen. Probeer het opnieuw.';

  @override
  String get panicPinTitle => 'Paniek PIN (Zelfvernietiging)';

  @override
  String get panicPinSubtitle => 'Een code die alle gegevens wist bij invoer';

  @override
  String get setPanicPin => 'Paniek PIN instellen';

  @override
  String get confirmPanicPin => 'Paniek PIN bevestigen';

  @override
  String get panicTriggered => 'Paniek PIN geactiveerd. Alle gegevens gewist.';

  @override
  String agentMaxPerTx(Object amount) {
    return 'Max/tx: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return 'Dagelijks: $amount XRS';
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
  String get signTransactionTitle => 'Transactie Ondertekenen';

  @override
  String get signAndSendTransactionTitle =>
      'Transactie Ondertekenen en Verzenden';

  @override
  String signAllTransactionsTitle(int count) {
    return '$count Transacties Ondertekenen';
  }

  @override
  String get connectToDappDesc =>
      'Deze app wil verbinding maken met je Xeris wallet en je openbare adres bekijken.';

  @override
  String get signTransactionDesc =>
      'Deze app wil dat je een transactie ondertekent. Controleer zorgvuldig voordat je goedkeurt.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'Deze app wil dat je $count transacties tegelijk ondertekent.';
  }

  @override
  String get signMessageDesc =>
      'Deze app wil dat je een bericht ondertekent voor verificatie.';

  @override
  String get dappRequestUnknown => 'Deze app vraagt toegang tot de wallet.';

  @override
  String get wrapXrs => 'XRS Wrappen';

  @override
  String get unwrapXrs => 'XRS Unwrappen';

  @override
  String get swapLabel => 'Swap';

  @override
  String get interactLabel => 'Interactie';

  @override
  String get noActiveLimitOrders => 'Geen actieve limietorders';

  @override
  String get sellingLabel => 'Verkopen';

  @override
  String get buyingMinLabel => 'Kopen (Min)';

  @override
  String get targetPriceLabel => 'Doelprijs';

  @override
  String get orderIdLabel => 'Order-ID';

  @override
  String get cancelOrderTitle => 'Order Annuleren';

  @override
  String get cancelOrderConfirm =>
      'Weet je zeker dat je deze limietorder wilt annuleren? Het geld wordt teruggestort naar je wallet.';

  @override
  String get no => 'Nee';

  @override
  String get yesCancel => 'Ja, annuleren';

  @override
  String get cancelTxSubmitted => 'Annuleringstransactie verzonden';

  @override
  String get cancelTxFailed => 'Annulering verzenden mislukt';

  @override
  String get noMatchingValidators => 'Geen overeenkomende validators';

  @override
  String get searchTokenPlaceholder => 'Zoek token...';

  @override
  String get zkpTransferSubmitted => 'ZKP Overdracht Verzonden!';

  @override
  String get paste => 'Plakken';

  @override
  String get myWallet => 'Mijn Wallet';

  @override
  String get networkFee => 'Netwerkkosten';

  @override
  String get openStatus => 'OPEN';

  @override
  String get toLabel => 'Aan';

  @override
  String get networkLabel => 'Netwerk';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String get mainnetSoon => 'Mainnet komt binnenkort';

  @override
  String get connectedSitesTitle => 'Verbonden Sites';

  @override
  String get connectedSitesSubtitle => 'Beheer dApp-machtigingen';

  @override
  String get noConnectedSites => 'Geen Verbonden Sites';

  @override
  String get noConnectedSitesDesc =>
      'Sites waarmee je verbinding maakt via de browser verschijnen hier. Je kunt hun toegang op elk moment intrekken.';

  @override
  String get connectedSiteRevoked => 'Sitetoegang ingetrokken';

  @override
  String get revokeAllSitesTitle => 'Alle sites intrekken?';

  @override
  String get revokeAllSitesDesc =>
      'Dit verbreekt de verbinding van alle websites met je wallet. Ze moeten opnieuw toegang aanvragen.';

  @override
  String get revokeAll => 'Alles Intrekken';

  @override
  String get revoke => 'Intrekken';

  @override
  String get allSitesRevoked => 'Alle sitemachtigingen ingetrokken';

  @override
  String get addressBookTitle => 'Adresboek';

  @override
  String get addressBookSubtitle => 'Beheer opgeslagen contacten';

  @override
  String get themeTitle => 'Thema';

  @override
  String get selectTheme => 'Thema selecteren';

  @override
  String get themeDark => 'Donkere modus';

  @override
  String get themeLight => 'Lichte modus';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'Systeemstandaard';

  @override
  String get themeNameDark => 'Donker';

  @override
  String get themeNameLight => 'Licht';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'Systeem';
}
