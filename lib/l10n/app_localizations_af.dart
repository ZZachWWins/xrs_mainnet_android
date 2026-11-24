// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Afrikaans (`af`).
class AppLocalizationsAf extends AppLocalizations {
  AppLocalizationsAf([String locale = 'af']) : super(locale);

  @override
  String get settingsTitle => 'Instellings';

  @override
  String get accountSection => 'Rekening';

  @override
  String get manageWalletsTitle => 'Bestuur Beursies';

  @override
  String get manageWalletsSubtitle => 'Voeg by, verwyder of wissel beursies';

  @override
  String get recoveryPhraseTitle => 'Herstelfrase';

  @override
  String get recoveryPhraseSubtitle => 'Bekyk jou geheime saadfrase veilig';

  @override
  String get generalSection => 'Algemeen';

  @override
  String get currencyTitle => 'Geldeenheid';

  @override
  String get notificationsTitle => 'Kennisgewings';

  @override
  String get notificationsSubtitle => 'Ontvang waarskuwings vir transaksies';

  @override
  String get privacyModeTitle => 'Privaatheidsmodus';

  @override
  String get privacyModeSubtitle => 'Verberg balanse op die paneelbord';

  @override
  String get securitySection => 'Sekuriteit';

  @override
  String get biometricTitle => 'Biometriese Verifikasie';

  @override
  String get biometricSubtitle => 'Vereis Face ID / Vingerafdruk by aanvang';

  @override
  String get supportSection => 'Ondersteuning';

  @override
  String get privacyPolicyTitle => 'Privaatheidsbeleid';

  @override
  String get privacyPolicySubtitle => 'Lees ons privaatheidsbeleid';

  @override
  String get termsOfServiceTitle => 'Diensbepalings';

  @override
  String get termsOfServiceSubtitle => 'Lees ons diensbepalings';

  @override
  String get aboutWalletTitle => 'Oor Xeris Wallet';

  @override
  String get languageTitle => 'Taal';

  @override
  String get selectLanguage => 'Kies Taal';

  @override
  String get addressCopied => 'Adres na knipbord gekopieer';

  @override
  String get loadingAddress => 'Laai...';

  @override
  String get errorLoadingAddress => 'Fout met laai van adres';

  @override
  String get sinceLastMonth => 'Sedert Verlede Maand';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String comingSoon(String itemName) {
    return '$itemName besonderhede kom binnekort!';
  }

  @override
  String get actionSend => 'Stuur';

  @override
  String get actionReceive => 'Ontvang';

  @override
  String get actionSwap => 'Ruil';

  @override
  String get actionEarn => 'Verdien';

  @override
  String get actionScan => 'Skandeer';

  @override
  String get navWallet => 'Beursie';

  @override
  String get navBrowser => 'Blaaier';

  @override
  String get navActivity => 'Aktiwiteit';

  @override
  String get balanceHistoryTitle => 'Balansgeskiedenis';

  @override
  String get totalBalanceTitle => 'Totale Balans';

  @override
  String get noHistoryAvailable => 'Geen geskiedenis beskikbaar';

  @override
  String errorPrefix(String error) {
    return 'Fout: $error';
  }

  @override
  String get addWalletTitle => 'Voeg Beursie By';

  @override
  String get addWalletSubtitle => 'Hoe wil jy \'n beursie byvoeg?';

  @override
  String get createNewWallet => 'Skep Nuwe Beursie';

  @override
  String get createNewWalletDesc =>
      'Genereer \'n nuwe 12-woord geheime herstelfrase';

  @override
  String get importExistingWallet => 'Voer Bestaande Beursie In';

  @override
  String get importExistingWalletDesc => 'Herstel met \'n geheime herstelfrase';

  @override
  String get myWalletsTitle => 'My Beursies';

  @override
  String get noWallets => 'Geen Beursies';

  @override
  String get noWalletsDesc =>
      'Jy het nog geen beursies nie. Skep of voer jou eerste beursie in om te begin.';

  @override
  String get deleteWalletPromptTitle => 'Vee Beursie Uit?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return 'Is jy seker jy wil \"$walletName\" uitvee? Hierdie aksie kan nie ongedaan gemaak word nie tensy jy jou herstelfrase gestoor het.';
  }

  @override
  String get cancel => 'Kanselleer';

  @override
  String get delete => 'Vee Uit';

  @override
  String get unlockWallet => 'Sluit Beursie Oop';

  @override
  String get authRequired => 'Verifikasie vereis.';

  @override
  String get verifySecretPhraseTitle => 'Verifieer Geheime Frase';

  @override
  String get verifyBackup => 'Verifieer jou rugsteun';

  @override
  String get verifyBackupDesc =>
      'Voer die volgende woorde van jou geheime frase in om te bevestig dat jy hulle gestoor het.';

  @override
  String wordNumber(String number) {
    return 'Woord #$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Voer woord #$number in';
  }

  @override
  String get verifyComplete => 'Verifieer & Voltooi';

  @override
  String get walletVerified => 'Beursie geverifieer en beveilig!';

  @override
  String failedCreateWallet(String error) {
    return 'Kon nie beursie skep nie: $error';
  }

  @override
  String get incorrectWords =>
      'Verkeerde woorde. Kontroleer asseblief jou frase en probeer weer.';

  @override
  String get importWalletTitle => 'Voer Beursie In';

  @override
  String get enterSecretPhrase => 'Voer Geheime Frase In';

  @override
  String get enterRecoveryPhraseDesc =>
      'Voer jou 12 of 24-woord herstelfrase in om jou beursie te herstel.';

  @override
  String get invalidRecoveryPhrase => 'Ongeldige herstelfrase';

  @override
  String get walletImportedSuccess => 'Beursie suksesvol ingevoer!';

  @override
  String failedImportWallet(String error) {
    return 'Kon nie beursie invoer nie: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Geheime Herstelfrase';

  @override
  String get secretPhraseMasterKeyDesc =>
      'Hierdie geheime frase is die meestersleutel tot jou beursie. Skryf dit neer en bêre dit op \'n veilige plek. Deel dit nooit met enigiemand nie.';

  @override
  String get copyToClipboard => 'Kopieer na Knipbord';

  @override
  String get secretPhraseCopied => 'Geheime frase na knipbord gekopieer';

  @override
  String get savedSecretPhraseBtn => 'Ek het my geheime frase gestoor';

  @override
  String get welcomeTo => 'Welkom by\nXeris Wallet';

  @override
  String get secureWalletForChain => 'Die veilige beursie vir die Xeris Chain.';

  @override
  String get createANewWallet => 'Skep \'n Nuwe Beursie';

  @override
  String get alreadyHaveWallet => 'Ek het reeds \'n beursie';

  @override
  String get sendAssetsTitle => 'Stuur Bates';

  @override
  String get recipientAddress => 'Ontvanger se Adres';

  @override
  String get pasteAddressOrScan => 'Plak adres of skandeer QR';

  @override
  String get amount => 'Bedrag';

  @override
  String get max => 'MAKS';

  @override
  String get review => 'Hersien';

  @override
  String balance(String amount, String symbol) {
    return 'Balans: $amount $symbol';
  }

  @override
  String get errorEnterRecipient => 'Voer asseblief \'n ontvanger se adres in';

  @override
  String get errorInvalidAddress => 'Ongeldige Xeris Chain adres';

  @override
  String get errorEnterValidAmount => 'Voer asseblief \'n geldige bedrag in';

  @override
  String get errorInsufficientBalance => 'Onvoldoende balans';

  @override
  String get receiveAssetsTitle => 'Ontvang Bates';

  @override
  String get scanToReceive => 'Skandeer om te Ontvang';

  @override
  String get sendOnlyXerisAssets =>
      'Stuur slegs Xeris Chain bates na hierdie adres.';

  @override
  String get shareAddress => 'Deel Adres';

  @override
  String get swapTitle => 'Ruil';

  @override
  String get from => 'Van';

  @override
  String get toEstimated => 'Na (Geskat)';

  @override
  String get price => 'Prys';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Glytoleransie';

  @override
  String get swapping => 'Ruil tans...';

  @override
  String get selectToken => 'Kies Token';

  @override
  String get scanQrCodeTitle => 'Skandeer QR Kode';

  @override
  String get alignQrCode => 'Belyn QR kode binne die raam';

  @override
  String get earnRewardsTitle => 'Verdien Belonings';

  @override
  String get noValidatorsFound =>
      'Geen valideerders op testnet gevind nie.\nJy kan steeds probeer om aan die netwerk te staak.';

  @override
  String validatorAddress(String address) {
    return 'Valideerder $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'Staak: $amount XRS';
  }

  @override
  String get stake => 'Staak';

  @override
  String get unstake => 'Onstaak';

  @override
  String get directStake => 'Direkte Staak';

  @override
  String get stakedBalance => 'Gestaakte Balans';

  @override
  String totalStaked(String amount) {
    return 'Totaal Gestaak: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Kommissie: $value%';
  }

  @override
  String get searchValidators => 'Soek Valideerders';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Bevestig Staak';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'Jy is op die punt om $amount XRS aan $validator te staak.';
  }

  @override
  String get confirmUnstakeTitle => 'Bevestig Onstaak';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'Jy is op die punt om $amount XRS van $validator te onstaak.';
  }

  @override
  String get unbondingNotice => '7-dae ontbindingsperiode geld';

  @override
  String get transactionSubmitted => 'Transaksie Ingedien';

  @override
  String get transactionFailed => 'Transaksie Misluk';

  @override
  String get txSubmittedDesc =>
      'Jou transaksie is by die Xeris netwerk ingedien.';

  @override
  String hashLabel(String hash) {
    return 'Hash: $hash';
  }

  @override
  String get txHashCopied => 'Transaksie hash na knipbord gekopieer';

  @override
  String get viewInExplorer => 'Bekyk in Verkenner';

  @override
  String get backToDashboard => 'Terug na Paneelbord';

  @override
  String get shareReceipt => 'Deel Kwitansie';

  @override
  String get transactionDetails => 'Transaksiebesonderhede';

  @override
  String get receiptTitle => 'Xeris Transaksie Kwitansie';

  @override
  String get dateLabel => 'Datum';

  @override
  String get statusLabel => 'Status';

  @override
  String get successStatus => 'Suksesvol';

  @override
  String get failedStatus => 'Misluk';

  @override
  String get copiedToClipboard => 'Na knipbord gekopieer';

  @override
  String connectToDapp(String dappName) {
    return 'Koppel aan $dappName?';
  }

  @override
  String get reject => 'Verwerp';

  @override
  String get approve => 'Keur Goed';

  @override
  String get details => 'BESONDERHEDE';

  @override
  String get activityTitle => 'Aktiwiteit';

  @override
  String get noActivityYet => 'Nog Geen Aktiwiteit';

  @override
  String get noActivityDesc =>
      'Jou transaksies sal hier verskyn sodra jy fondse stuur of ontvang.';

  @override
  String get errorLoadingActivity => 'Fout met laai van aktiwiteit';

  @override
  String get activitySearchHint => 'Soek adres, tx hash, of token';

  @override
  String get activityFilterAll => 'Alles';

  @override
  String get activityFilterSent => 'Gestuur';

  @override
  String get activityFilterReceived => 'Ontvang';

  @override
  String get activityFilterSwap => 'Ruil';

  @override
  String get activityFilterFailed => 'Misluk';

  @override
  String get activityNoMatches => 'Geen passings';

  @override
  String get activityNoMatchesDesc =>
      'Probeer om jou filters of soektog aan te pas';

  @override
  String get unknownAddress => 'Onbekend';

  @override
  String receivedAsset(String symbol) {
    return '$symbol Ontvang';
  }

  @override
  String sentAsset(String symbol) {
    return '$symbol Gestuur';
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
  String get execContract => 'Voer Uit';

  @override
  String todayAt(String time) {
    return 'Vandag $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Gister $time';
  }

  @override
  String get connectingToDapp => 'Koppel aan dApp...';

  @override
  String get signMessageTitle => 'Teken Boodskap';

  @override
  String get messageToSign => 'BOODSKAP';

  @override
  String get signBtn => 'Teken';

  @override
  String get searchOrEnterUrl => 'Soek of voer URL in';

  @override
  String get renameWalletTitle => 'Hernoem Beursie';

  @override
  String get renameWalletPromptDesc => 'Voer \'n nuwe naam vir jou beursie in.';

  @override
  String get walletNameLabel => 'Beursie Naam';

  @override
  String get save => 'Stoor';

  @override
  String get rename => 'Hernoem';

  @override
  String get marketOrder => 'Mark';

  @override
  String get limitOrder => 'Limiet';

  @override
  String get limitPriceLabel => 'Limietprys';

  @override
  String get placeLimitOrder => 'Plaas Limietbestelling';

  @override
  String get manageCoins => 'Bestuur Munte';

  @override
  String get dAppBrowser => 'Xeris web4 blaaier';

  @override
  String connectedTo(String publicKey) {
    return 'Gekoppel: $publicKey';
  }

  @override
  String get selectCurrency => 'Kies Geldeenheid';

  @override
  String get stakeXrs => 'Staak XRS';

  @override
  String availableXrs(String balance) {
    return 'Beskikbaar: $balance XRS';
  }

  @override
  String get confirmStake => 'Bevestig Staak';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Voeg Likiditeit By: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'Bevestig Deposito';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Hersien Transaksie';

  @override
  String get youAreSending => 'Jy stuur';

  @override
  String get confirmAndSend => 'Bevestig & Stuur';

  @override
  String get biometricAuthFailed =>
      'Verifikasie misluk. Kan nie biometrika aktiveer nie.';

  @override
  String get couldNotOpenLink => 'Kon nie skakel oopmaak nie';

  @override
  String get recoveryPhraseWarning =>
      'Deel hierdie frase nooit nie. Enigiemand met hierdie woorde kan jou bates steel.';

  @override
  String get noWalletFound => 'Geen beursie gevind nie.';

  @override
  String get recoveryPhraseCopied => 'Herstelfrase na knipbord gekopieer';

  @override
  String versionLabel(String version) {
    return 'Weergawe $version';
  }

  @override
  String get authFailed => 'Verifikasie misluk';

  @override
  String get marketCap => 'Markkapitalisasie';

  @override
  String get totalHolders => 'Totale Houers';

  @override
  String get mintAddress => 'Mint Adres';

  @override
  String get totalSupply => 'Totale Voorraad';

  @override
  String get recentActivity => 'Onlangse Aktiwiteit';

  @override
  String get tokenDecimals => 'Desimale';

  @override
  String get tokenStandard => 'Token Standaard';

  @override
  String get noActivityForToken =>
      'Geen onlangse aktiwiteit vir hierdie token nie.';

  @override
  String get navAgents => 'Agente';

  @override
  String get agentsTitle => 'KI Agente';

  @override
  String get yourAgents => 'Jou Agente';

  @override
  String get openTasks => 'Oop Take';

  @override
  String get registerAgentTitle => 'Registreer Agent';

  @override
  String get registerAgentDesc =>
      'Agente werk outonoom met gedelegeerde gesag. Stel besteperke versigtig — hulle kan dit nie op-ketting oorskry nie.';

  @override
  String get agentNameLabel => 'AGENT NAAM';

  @override
  String get agentNamePlaceholder => 'bv. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'AGENT PUBLIEKE SLEUTEL';

  @override
  String get agentPubKeyPlaceholder => 'Base58 Ed25519 publieke sleutel';

  @override
  String get maxPerTxLabel => 'MAKS PER TRANSAKSIE (XRS)';

  @override
  String get dailyBudgetLabel => 'DAAGLIKSE BEGROTING (XRS)';

  @override
  String get allowedContractsLabel => 'TOEGELATE KONTRAKTE';

  @override
  String get allowedContractsPlaceholder => 'pool_mtk_xrs, ... (komma-geskei)';

  @override
  String get registerAgentBtn => 'Registreer Agent';

  @override
  String get revokeAgentBtn => 'Herroep';

  @override
  String get claimTaskBtn => 'Eis';

  @override
  String get lastHeartbeatPrefix => 'Laaste hartklop: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count AKTIEF';
  }

  @override
  String get sendPrivately => 'Stuur Privaat';

  @override
  String get sendPrivatelyDesc => 'Bedrag op-ketting versteek via ZK proof';

  @override
  String get zkpInfoBox =>
      'Die oorplasingsbedrag sal op-ketting versteek word. Slegs jy en die ontvanger kan die waarde verifieer. Stoor jou verblindingsfaktor vir belastingrekords.';

  @override
  String get generateProofAndSend => 'Genereer Proof & Stuur';

  @override
  String get quantumShieldTitle => 'Kwantumskild';

  @override
  String get quantumShieldSubtitle => 'Post-kwantum kriptografie';

  @override
  String get quantumShieldDesc =>
      'Beskerm jou beursie met post-kwantum kriptografie (ML-DSA-65)';

  @override
  String get quantumProtectionActive => 'Kwantumbeskerming Aktief';

  @override
  String get notProtected => 'Nie Beskerm Nie';

  @override
  String get pqSecurityLevel => 'ML-DSA-65 · 128-bit PQ sekuriteit';

  @override
  String get vulnerableToQuantum => 'Kwesbaar vir kwantumaanvalle';

  @override
  String get statusActive => 'AKTIEF';

  @override
  String get statusOff => 'AF';

  @override
  String get zkProofsUsed => 'ZK Proofs Gebruik';

  @override
  String get pqKeysRegistered => 'PQ Sleutels Geregistreer';

  @override
  String get blockTimeStat => 'Blok Tyd';

  @override
  String get quantumProtectedDesc =>
      'Jou beursie is kwantum-beskerm. Oorplasings geteken met ML-DSA-65 wys \'n 🛡 kenteken in die verkenner.';

  @override
  String get enableQuantumProtectionDesc =>
      'Aktivering van kwantumbeskerming genereer \'n ML-DSA-65 sleutelpaar en registreer jou publieke sleutel op-ketting. Dit is \'n eenmalige opstelling.';

  @override
  String get sendWithQuantumSigning => 'Stuur met Kwantum Tekening';

  @override
  String get enableQuantumProtectionBtn => 'Aktiveer Kwantumbeskerming';

  @override
  String get quantumEnabledSuccess => 'Kwantumbeskerming Geaktiveer!';

  @override
  String failedToEnablePq(String error) {
    return 'Kon nie aktiveer nie: $error';
  }

  @override
  String get quantumBackupTitle => 'Rugsteun Kwantum Identiteit';

  @override
  String get quantumBackupWarning =>
      'Jou 12-woord mnemoniek is nie meer genoeg om hierdie beursie te herstel nie. Jy MOET hierdie Kwantum Geheime Sleutel rugsteun.';

  @override
  String get quantumSecretKeyLabel => 'KWANTUM GEHEIME SLEUTEL';

  @override
  String get backupConfirmedLabel =>
      'Ek het my Kwantum Geheime Sleutel veilig gerugsteun';

  @override
  String get viewRecoveryKey => 'Bekyk Herstelsleutel';

  @override
  String get pinCodeTitle => 'PIN Kode';

  @override
  String get pinCodeSubtitle => 'Beveilig beursie met \'n 6-syfer PIN';

  @override
  String get changePinCodeTitle => 'Verander PIN Kode';

  @override
  String get changePinCodeSubtitle => 'Werk jou sekuriteits-PIN by';

  @override
  String get pinCodeUpdated => 'PIN Kode suksesvol opgedateer';

  @override
  String get noAgentsRegistered => 'Geen agente geregistreer nie.';

  @override
  String get noOpenTasks => 'Geen oop take nie.';

  @override
  String get refresh => 'Verfris';

  @override
  String get zkpOnlyXrsError =>
      'ZKP private oorplasings ondersteun tans slegs XRS.';

  @override
  String get pqcOnlyXrsError =>
      'Kwantum Getekende oorplasings ondersteun tans slegs XRS.';

  @override
  String get required => 'Vereis';

  @override
  String get enterPinCode => 'Voer PIN Kode In';

  @override
  String get setNewPin => 'Stel \'n Nuwe PIN';

  @override
  String get confirmPin => 'Bevestig Jou PIN';

  @override
  String get pinSubtitle => 'Beveilig jou bates met \'n 6-syfer PIN';

  @override
  String get incorrectPin => 'Verkeerde PIN';

  @override
  String get pinsDoNotMatch => 'PIN-kodes stem nie ooreen nie. Probeer weer.';

  @override
  String get panicPinTitle => 'Paniek PIN (Self-Vernietig)';

  @override
  String get panicPinSubtitle =>
      '\'n Kode wat alle data uitvee wanneer dit ingevoer word';

  @override
  String get setPanicPin => 'Stel Paniek PIN';

  @override
  String get confirmPanicPin => 'Bevestig Paniek PIN';

  @override
  String get panicTriggered => 'Paniek PIN geaktiveer. Alle data uitgevee.';

  @override
  String agentMaxPerTx(Object amount) {
    return 'Maks/tx: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return 'Daagliks: $amount XRS';
  }

  @override
  String get appLockedTitle => 'Xeris Wallet Gesluit';

  @override
  String get authenticateToContinue => 'Verifieer om voort te gaan';

  @override
  String get securityAudit => 'SEKURITEITSOUDIT';

  @override
  String get biometricLockActive => 'Biometriese Slot Aktief';

  @override
  String get pinProtected6Digit => '6-Syfer PIN Beskerm';

  @override
  String get privacyModeEnabled => 'Privaatheidsmodus Geaktiveer';

  @override
  String get privacyModeDisabled => 'Privaatheidsmodus Gedeaktiveer';

  @override
  String get fullDiskEncryption => 'Volle Skyf Enkripsie';

  @override
  String get zkProofAsyncInfo =>
      'Xeris gebruik asinchrone ZK proof generering om privaatheid te handhaaf sonder om jou beursie-interaksie te blokkeer.';

  @override
  String get unknownToken => 'Onbekende Token';

  @override
  String get signTransactionTitle => 'Teken Transaksie';

  @override
  String get signAndSendTransactionTitle => 'Teken & Stuur Transaksie';

  @override
  String signAllTransactionsTitle(int count) {
    return 'Teken $count Transaksies';
  }

  @override
  String get connectToDappDesc =>
      'Hierdie program wil aan jou Xeris beursie koppel en jou publieke adres bekyk.';

  @override
  String get signTransactionDesc =>
      'Hierdie program wil hê jy moet \'n transaksie teken. Hersien noukeurig voor goedkeuring.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'Hierdie program wil hê jy moet $count transaksies op een slag teken.';
  }

  @override
  String get signMessageDesc =>
      'Hierdie program wil hê jy moet \'n boodskap teken vir verifikasie.';

  @override
  String get dappRequestUnknown =>
      'Hierdie program versoek toegang tot die beursie.';

  @override
  String get wrapXrs => 'Verpak XRS';

  @override
  String get unwrapXrs => 'Ontpak XRS';

  @override
  String get swapLabel => 'Ruil';

  @override
  String get interactLabel => 'Interaksie';

  @override
  String get noActiveLimitOrders => 'Geen aktiewe limietbestellings nie';

  @override
  String get sellingLabel => 'Verkoop';

  @override
  String get buyingMinLabel => 'Koop (Min)';

  @override
  String get targetPriceLabel => 'Teikenprys';

  @override
  String get orderIdLabel => 'Bestelling ID';

  @override
  String get cancelOrderTitle => 'Kanselleer Bestelling';

  @override
  String get cancelOrderConfirm =>
      'Is jy seker jy wil hierdie limietbestelling kanselleer? Fondse sal aan jou beursie terugbesorg word.';

  @override
  String get no => 'Nee';

  @override
  String get yesCancel => 'Ja, Kanselleer';

  @override
  String get cancelTxSubmitted => 'Kansellasie transaksie ingedien';

  @override
  String get cancelTxFailed => 'Kon nie kansellasie indien nie';

  @override
  String get noMatchingValidators => 'Geen passende valideerders nie';

  @override
  String get searchTokenPlaceholder => 'Soek token...';

  @override
  String get zkpTransferSubmitted => 'ZKP Oorplasing Ingedien!';

  @override
  String get paste => 'Plak';

  @override
  String get myWallet => 'My Beursie';

  @override
  String get networkFee => 'Netwerkfooi';

  @override
  String get openStatus => 'OOP';

  @override
  String get toLabel => 'Aan';

  @override
  String get networkLabel => 'Netwerk';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String get mainnetSoon => 'Mainnet kom binnekort';

  @override
  String get connectedSitesTitle => 'Gekoppelde Webwerwe';

  @override
  String get connectedSitesSubtitle => 'Bestuur dApp toestemmings';

  @override
  String get noConnectedSites => 'Geen Gekoppelde Webwerwe';

  @override
  String get noConnectedSitesDesc =>
      'Webwerwe waarmee jy via die blaaier koppel sal hier verskyn. Jy kan hul toegang te eniger tyd herroep.';

  @override
  String get connectedSiteRevoked => 'Webwerf toegang herroep';

  @override
  String get revokeAllSitesTitle => 'Herroep Alle Webwerwe?';

  @override
  String get revokeAllSitesDesc =>
      'Dit sal alle webwerwe van jou beursie ontkoppel. Hulle sal weer toegang moet versoek.';

  @override
  String get revokeAll => 'Herroep Alles';

  @override
  String get revoke => 'Herroep';

  @override
  String get allSitesRevoked => 'Alle webwerf toestemmings herroep';

  @override
  String get addressBookTitle => 'Adresboek';

  @override
  String get addressBookSubtitle => 'Bestuur gestoorde kontakte';

  @override
  String get themeTitle => 'Tema';

  @override
  String get selectTheme => 'Kies Tema';

  @override
  String get themeDark => 'Donker Modus';

  @override
  String get themeLight => 'Lig Modus';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'Stelsel Verstek';

  @override
  String get themeNameDark => 'Donker';

  @override
  String get themeNameLight => 'Lig';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'Stelsel';
}
