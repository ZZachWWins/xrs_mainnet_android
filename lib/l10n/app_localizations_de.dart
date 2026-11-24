// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get accountSection => 'Konto';

  @override
  String get manageWalletsTitle => 'Wallets verwalten';

  @override
  String get manageWalletsSubtitle =>
      'Wallets hinzufügen, entfernen oder wechseln';

  @override
  String get recoveryPhraseTitle => 'Wiederherstellungsphrase';

  @override
  String get recoveryPhraseSubtitle => 'Geheime Seed-Phrase sicher anzeigen';

  @override
  String get generalSection => 'Allgemein';

  @override
  String get currencyTitle => 'Währung';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsSubtitle =>
      'Benachrichtigungen für Transaktionen erhalten';

  @override
  String get privacyModeTitle => 'Privatsphäre-Modus';

  @override
  String get privacyModeSubtitle => 'Guthaben auf dem Dashboard verbergen';

  @override
  String get securitySection => 'Sicherheit';

  @override
  String get biometricTitle => 'Biometrische Authentifizierung';

  @override
  String get biometricSubtitle =>
      'Face ID / Fingerabdruck beim Start verlangen';

  @override
  String get supportSection => 'Support';

  @override
  String get privacyPolicyTitle => 'Datenschutzrichtlinie';

  @override
  String get privacyPolicySubtitle => 'Unsere Datenschutzrichtlinie lesen';

  @override
  String get termsOfServiceTitle => 'Nutzungsbedingungen';

  @override
  String get termsOfServiceSubtitle => 'Unsere Nutzungsbedingungen lesen';

  @override
  String get aboutWalletTitle => 'Über Xeris Wallet';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get addressCopied => 'Adresse in die Zwischenablage kopiert';

  @override
  String get loadingAddress => 'Wird geladen...';

  @override
  String get errorLoadingAddress => 'Fehler beim Laden der Adresse';

  @override
  String get sinceLastMonth => 'Seit letztem Monat';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String comingSoon(String itemName) {
    return 'Details zu $itemName folgen in Kürze!';
  }

  @override
  String get actionSend => 'Senden';

  @override
  String get actionReceive => 'Empfangen';

  @override
  String get actionSwap => 'Tauschen';

  @override
  String get actionEarn => 'Verdienen';

  @override
  String get actionScan => 'Scannen';

  @override
  String get navWallet => 'Wallet';

  @override
  String get navBrowser => 'Browser';

  @override
  String get navActivity => 'Aktivität';

  @override
  String get balanceHistoryTitle => 'Guthabenverlauf';

  @override
  String get totalBalanceTitle => 'Gesamtguthaben';

  @override
  String get noHistoryAvailable => 'Kein Verlauf verfügbar';

  @override
  String errorPrefix(String error) {
    return 'Fehler: $error';
  }

  @override
  String get addWalletTitle => 'Wallet hinzufügen';

  @override
  String get addWalletSubtitle => 'Wie möchten Sie ein Wallet hinzufügen?';

  @override
  String get createNewWallet => 'Neues Wallet erstellen';

  @override
  String get createNewWalletDesc =>
      'Eine neue 12-Wörter-Wiederherstellungsphrase erzeugen';

  @override
  String get importExistingWallet => 'Bestehendes Wallet importieren';

  @override
  String get importExistingWalletDesc =>
      'Mit einer Wiederherstellungsphrase wiederherstellen';

  @override
  String get myWalletsTitle => 'Meine Wallets';

  @override
  String get noWallets => 'Keine Wallets';

  @override
  String get noWalletsDesc =>
      'Sie haben noch keine Wallets. Erstellen oder importieren Sie Ihr erstes Wallet, um zu beginnen.';

  @override
  String get deleteWalletPromptTitle => 'Wallet löschen?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return 'Möchten Sie \"$walletName\" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden, es sei denn, Sie haben Ihre Wiederherstellungsphrase gespeichert.';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get unlockWallet => 'Wallet entsperren';

  @override
  String get authRequired => 'Authentifizierung erforderlich.';

  @override
  String get verifySecretPhraseTitle => 'Geheime Phrase bestätigen';

  @override
  String get verifyBackup => 'Backup überprüfen';

  @override
  String get verifyBackupDesc =>
      'Geben Sie die folgenden Wörter aus Ihrer geheimen Phrase ein, um zu bestätigen, dass Sie sie gespeichert haben.';

  @override
  String wordNumber(String number) {
    return 'Wort #$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Wort #$number eingeben';
  }

  @override
  String get verifyComplete => 'Bestätigen & Abschließen';

  @override
  String get walletVerified => 'Wallet bestätigt und gesichert!';

  @override
  String failedCreateWallet(String error) {
    return 'Wallet konnte nicht erstellt werden: $error';
  }

  @override
  String get incorrectWords =>
      'Falsche Wörter. Bitte überprüfen Sie Ihre Phrase und versuchen Sie es erneut.';

  @override
  String get importWalletTitle => 'Wallet importieren';

  @override
  String get enterSecretPhrase => 'Geheime Phrase eingeben';

  @override
  String get enterRecoveryPhraseDesc =>
      'Geben Sie Ihre 12- oder 24-Wörter-Wiederherstellungsphrase ein, um Ihr Wallet wiederherzustellen.';

  @override
  String get invalidRecoveryPhrase => 'Ungültige Wiederherstellungsphrase';

  @override
  String get walletImportedSuccess => 'Wallet erfolgreich importiert!';

  @override
  String failedImportWallet(String error) {
    return 'Wallet konnte nicht importiert werden: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Geheime Wiederherstellungsphrase';

  @override
  String get secretPhraseMasterKeyDesc =>
      'Diese geheime Phrase ist der Hauptschlüssel zu Ihrem Wallet. Schreiben Sie sie auf und bewahren Sie sie an einem sicheren Ort auf. Geben Sie sie niemals weiter.';

  @override
  String get copyToClipboard => 'In Zwischenablage kopieren';

  @override
  String get secretPhraseCopied => 'Geheime Phrase in Zwischenablage kopiert';

  @override
  String get savedSecretPhraseBtn =>
      'Ich habe meine geheime Phrase gespeichert';

  @override
  String get welcomeTo => 'Willkommen bei\nXeris Wallet';

  @override
  String get secureWalletForChain => 'Das sichere Wallet für die Xeris Chain.';

  @override
  String get createANewWallet => 'Neues Wallet erstellen';

  @override
  String get alreadyHaveWallet => 'Ich habe bereits ein Wallet';

  @override
  String get sendAssetsTitle => 'Assets senden';

  @override
  String get recipientAddress => 'Empfängeradresse';

  @override
  String get pasteAddressOrScan => 'Adresse einfügen oder QR scannen';

  @override
  String get amount => 'Betrag';

  @override
  String get max => 'MAX';

  @override
  String get review => 'Überprüfen';

  @override
  String balance(String amount, String symbol) {
    return 'Guthaben: $amount $symbol';
  }

  @override
  String get errorEnterRecipient => 'Bitte geben Sie eine Empfängeradresse ein';

  @override
  String get errorInvalidAddress => 'Ungültige Xeris Chain-Adresse';

  @override
  String get errorEnterValidAmount =>
      'Bitte geben Sie einen gültigen Betrag ein';

  @override
  String get errorInsufficientBalance => 'Unzureichendes Guthaben';

  @override
  String get receiveAssetsTitle => 'Assets empfangen';

  @override
  String get scanToReceive => 'Zum Empfangen scannen';

  @override
  String get sendOnlyXerisAssets =>
      'Senden Sie nur Xeris Chain-Assets an diese Adresse.';

  @override
  String get shareAddress => 'Adresse teilen';

  @override
  String get swapTitle => 'Tauschen';

  @override
  String get from => 'Von';

  @override
  String get toEstimated => 'An (Geschätzt)';

  @override
  String get price => 'Preis';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Slippage-Toleranz';

  @override
  String get swapping => 'Wird getauscht...';

  @override
  String get selectToken => 'Token auswählen';

  @override
  String get scanQrCodeTitle => 'QR-Code scannen';

  @override
  String get alignQrCode => 'QR-Code im Rahmen ausrichten';

  @override
  String get earnRewardsTitle => 'Belohnungen verdienen';

  @override
  String get noValidatorsFound =>
      'Keine Validatoren im Testnet gefunden.\nSie können trotzdem versuchen, im Netzwerk zu staken.';

  @override
  String validatorAddress(String address) {
    return 'Validator $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'Stake: $amount XRS';
  }

  @override
  String get stake => 'Staken';

  @override
  String get unstake => 'Unstaken';

  @override
  String get directStake => 'Direkt staken';

  @override
  String get stakedBalance => 'Gestaktes Guthaben';

  @override
  String totalStaked(String amount) {
    return 'Insgesamt gestakt: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Provision: $value%';
  }

  @override
  String get searchValidators => 'Validatoren suchen';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Stake bestätigen';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'Sie sind dabei, $amount XRS an $validator zu staken.';
  }

  @override
  String get confirmUnstakeTitle => 'Unstake bestätigen';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'Sie sind dabei, $amount XRS von $validator zu unstaken.';
  }

  @override
  String get unbondingNotice => 'Es gilt eine 7-tägige Unbonding-Periode';

  @override
  String get transactionSubmitted => 'Transaktion übermittelt';

  @override
  String get transactionFailed => 'Transaktion fehlgeschlagen';

  @override
  String get txSubmittedDesc =>
      'Ihre Transaktion wurde an das Xeris-Netzwerk übermittelt.';

  @override
  String hashLabel(String hash) {
    return 'Hash: $hash';
  }

  @override
  String get txHashCopied => 'Transaktions-Hash in Zwischenablage kopiert';

  @override
  String get viewInExplorer => 'Im Explorer ansehen';

  @override
  String get backToDashboard => 'Zurück zum Dashboard';

  @override
  String get shareReceipt => 'Beleg teilen';

  @override
  String get transactionDetails => 'Transaktionsdetails';

  @override
  String get receiptTitle => 'Xeris Transaktionsbeleg';

  @override
  String get dateLabel => 'Datum';

  @override
  String get statusLabel => 'Status';

  @override
  String get successStatus => 'Erfolgreich';

  @override
  String get failedStatus => 'Fehlgeschlagen';

  @override
  String get copiedToClipboard => 'In Zwischenablage kopiert';

  @override
  String connectToDapp(String dappName) {
    return 'Mit $dappName verbinden?';
  }

  @override
  String get reject => 'Ablehnen';

  @override
  String get approve => 'Genehmigen';

  @override
  String get details => 'DETAILS';

  @override
  String get activityTitle => 'Aktivität';

  @override
  String get noActivityYet => 'Noch keine Aktivität';

  @override
  String get noActivityDesc =>
      'Ihre Transaktionen erscheinen hier, sobald Sie Geld senden oder empfangen.';

  @override
  String get errorLoadingActivity => 'Fehler beim Laden der Aktivität';

  @override
  String get activitySearchHint => 'Adresse, Tx-Hash oder Token suchen';

  @override
  String get activityFilterAll => 'Alle';

  @override
  String get activityFilterSent => 'Gesendet';

  @override
  String get activityFilterReceived => 'Empfangen';

  @override
  String get activityFilterSwap => 'Tausch';

  @override
  String get activityFilterFailed => 'Fehlgeschlagen';

  @override
  String get activityNoMatches => 'Keine Treffer';

  @override
  String get activityNoMatchesDesc => 'Passen Sie Ihre Filter oder Suche an';

  @override
  String get unknownAddress => 'Unbekannt';

  @override
  String receivedAsset(String symbol) {
    return '$symbol empfangen';
  }

  @override
  String sentAsset(String symbol) {
    return '$symbol gesendet';
  }

  @override
  String fromAddress(String address) {
    return 'Von: $address';
  }

  @override
  String toAddress(String address) {
    return 'An: $address';
  }

  @override
  String get execContract => 'Ausführen';

  @override
  String todayAt(String time) {
    return 'Heute $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Gestern $time';
  }

  @override
  String get connectingToDapp => 'Verbindung zu dApp wird hergestellt...';

  @override
  String get signMessageTitle => 'Nachricht signieren';

  @override
  String get messageToSign => 'NACHRICHT';

  @override
  String get signBtn => 'Signieren';

  @override
  String get searchOrEnterUrl => 'Suchen oder URL eingeben';

  @override
  String get renameWalletTitle => 'Wallet umbenennen';

  @override
  String get renameWalletPromptDesc =>
      'Geben Sie einen neuen Namen für Ihr Wallet ein.';

  @override
  String get walletNameLabel => 'Wallet-Name';

  @override
  String get save => 'Speichern';

  @override
  String get rename => 'Umbenennen';

  @override
  String get marketOrder => 'Markt';

  @override
  String get limitOrder => 'Limit';

  @override
  String get limitPriceLabel => 'Limitpreis';

  @override
  String get placeLimitOrder => 'Limit-Order platzieren';

  @override
  String get manageCoins => 'Coins verwalten';

  @override
  String get dAppBrowser => 'Xeris web4 Browser';

  @override
  String connectedTo(String publicKey) {
    return 'Verbunden: $publicKey';
  }

  @override
  String get selectCurrency => 'Währung auswählen';

  @override
  String get stakeXrs => 'XRS staken';

  @override
  String availableXrs(String balance) {
    return 'Verfügbar: $balance XRS';
  }

  @override
  String get confirmStake => 'Stake bestätigen';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Liquidität hinzufügen: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'Einzahlung bestätigen';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Transaktion überprüfen';

  @override
  String get youAreSending => 'Sie senden';

  @override
  String get confirmAndSend => 'Bestätigen & Senden';

  @override
  String get biometricAuthFailed =>
      'Authentifizierung fehlgeschlagen. Biometrie kann nicht aktiviert werden.';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get recoveryPhraseWarning =>
      'Geben Sie diese Phrase niemals weiter. Jeder mit diesen Wörtern kann Ihre Assets stehlen.';

  @override
  String get noWalletFound => 'Kein Wallet gefunden.';

  @override
  String get recoveryPhraseCopied =>
      'Wiederherstellungsphrase in Zwischenablage kopiert';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get authFailed => 'Authentifizierung fehlgeschlagen';

  @override
  String get marketCap => 'Marktkapitalisierung';

  @override
  String get totalHolders => 'Gesamtanzahl Inhaber';

  @override
  String get mintAddress => 'Mint-Adresse';

  @override
  String get totalSupply => 'Gesamtangebot';

  @override
  String get recentActivity => 'Letzte Aktivität';

  @override
  String get tokenDecimals => 'Dezimalstellen';

  @override
  String get tokenStandard => 'Token-Standard';

  @override
  String get noActivityForToken => 'Keine aktuelle Aktivität für diesen Token.';

  @override
  String get navAgents => 'Agenten';

  @override
  String get agentsTitle => 'KI-Agenten';

  @override
  String get yourAgents => 'Ihre Agenten';

  @override
  String get openTasks => 'Offene Aufgaben';

  @override
  String get registerAgentTitle => 'Agent registrieren';

  @override
  String get registerAgentDesc =>
      'Agenten arbeiten autonom mit delegierter Berechtigung. Setzen Sie Ausgabenlimits sorgfältig — sie können diese on-chain nicht überschreiten.';

  @override
  String get agentNameLabel => 'AGENT-NAME';

  @override
  String get agentNamePlaceholder => 'z. B. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'ÖFFENTLICHER SCHLÜSSEL DES AGENTEN';

  @override
  String get agentPubKeyPlaceholder => 'Base58 Ed25519 öffentlicher Schlüssel';

  @override
  String get maxPerTxLabel => 'MAX. PRO TRANSAKTION (XRS)';

  @override
  String get dailyBudgetLabel => 'TÄGLICHES BUDGET (XRS)';

  @override
  String get allowedContractsLabel => 'ERLAUBTE VERTRÄGE';

  @override
  String get allowedContractsPlaceholder => 'pool_mtk_xrs, ... (kommagetrennt)';

  @override
  String get registerAgentBtn => 'Agent registrieren';

  @override
  String get revokeAgentBtn => 'Widerrufen';

  @override
  String get claimTaskBtn => 'Beanspruchen';

  @override
  String get lastHeartbeatPrefix => 'Letzter Heartbeat: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count AKTIV';
  }

  @override
  String get sendPrivately => 'Privat senden';

  @override
  String get sendPrivatelyDesc => 'Betrag on-chain via ZK proof verborgen';

  @override
  String get zkpInfoBox =>
      'Der Überweisungsbetrag wird on-chain verborgen. Nur Sie und der Empfänger können den Wert verifizieren. Speichern Sie Ihren Blinding-Faktor für Steuerunterlagen.';

  @override
  String get generateProofAndSend => 'Proof generieren & Senden';

  @override
  String get quantumShieldTitle => 'Quantum Shield';

  @override
  String get quantumShieldSubtitle => 'Post-Quanten-Kryptografie';

  @override
  String get quantumShieldDesc =>
      'Schützen Sie Ihr Wallet mit Post-Quanten-Kryptografie (ML-DSA-65)';

  @override
  String get quantumProtectionActive => 'Quantenschutz aktiv';

  @override
  String get notProtected => 'Nicht geschützt';

  @override
  String get pqSecurityLevel => 'ML-DSA-65 · 128-Bit PQ-Sicherheit';

  @override
  String get vulnerableToQuantum => 'Anfällig für Quantenangriffe';

  @override
  String get statusActive => 'AKTIV';

  @override
  String get statusOff => 'AUS';

  @override
  String get zkProofsUsed => 'Verwendete ZK proofs';

  @override
  String get pqKeysRegistered => 'Registrierte PQ-Schlüssel';

  @override
  String get blockTimeStat => 'Blockzeit';

  @override
  String get quantumProtectedDesc =>
      'Ihr Wallet ist quantengeschützt. Mit ML-DSA-65 signierte Überweisungen zeigen ein 🛡 Abzeichen im Explorer.';

  @override
  String get enableQuantumProtectionDesc =>
      'Die Aktivierung des Quantenschutzes erzeugt ein ML-DSA-65-Schlüsselpaar und registriert Ihren öffentlichen Schlüssel on-chain. Dies ist eine einmalige Einrichtung.';

  @override
  String get sendWithQuantumSigning => 'Mit Quantum-Signatur senden';

  @override
  String get enableQuantumProtectionBtn => 'Quantenschutz aktivieren';

  @override
  String get quantumEnabledSuccess => 'Quantenschutz aktiviert!';

  @override
  String failedToEnablePq(String error) {
    return 'Aktivierung fehlgeschlagen: $error';
  }

  @override
  String get quantumBackupTitle => 'Quantum-Identität sichern';

  @override
  String get quantumBackupWarning =>
      'Ihre 12-Wörter-Mnemonic reicht nicht mehr aus, um dieses Wallet wiederherzustellen. Sie MÜSSEN diesen Quantum Secret Key sichern.';

  @override
  String get quantumSecretKeyLabel => 'QUANTUM SECRET KEY';

  @override
  String get backupConfirmedLabel =>
      'Ich habe meinen Quantum Secret Key sicher gesichert';

  @override
  String get viewRecoveryKey => 'Wiederherstellungsschlüssel anzeigen';

  @override
  String get pinCodeTitle => 'PIN-Code';

  @override
  String get pinCodeSubtitle => 'Wallet mit einer 6-stelligen PIN sichern';

  @override
  String get changePinCodeTitle => 'PIN-Code ändern';

  @override
  String get changePinCodeSubtitle => 'Sicherheits-PIN aktualisieren';

  @override
  String get pinCodeUpdated => 'PIN-Code erfolgreich aktualisiert';

  @override
  String get noAgentsRegistered => 'Keine Agenten registriert.';

  @override
  String get noOpenTasks => 'Keine offenen Aufgaben.';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get zkpOnlyXrsError =>
      'ZKP-Privatübertragungen unterstützen derzeit nur XRS.';

  @override
  String get pqcOnlyXrsError =>
      'Quantum-signierte Übertragungen unterstützen derzeit nur XRS.';

  @override
  String get required => 'Erforderlich';

  @override
  String get enterPinCode => 'PIN-Code eingeben';

  @override
  String get setNewPin => 'Neue PIN festlegen';

  @override
  String get confirmPin => 'PIN bestätigen';

  @override
  String get pinSubtitle => 'Sichern Sie Ihre Assets mit einer 6-stelligen PIN';

  @override
  String get incorrectPin => 'Falsche PIN';

  @override
  String get pinsDoNotMatch => 'PINs stimmen nicht überein. Erneut versuchen.';

  @override
  String get panicPinTitle => 'Panic PIN (Selbstzerstörung)';

  @override
  String get panicPinSubtitle => 'Ein Code, der bei Eingabe alle Daten löscht';

  @override
  String get setPanicPin => 'Panic PIN festlegen';

  @override
  String get confirmPanicPin => 'Panic PIN bestätigen';

  @override
  String get panicTriggered => 'Panic PIN ausgelöst. Alle Daten gelöscht.';

  @override
  String agentMaxPerTx(Object amount) {
    return 'Max./Tx: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return 'Täglich: $amount XRS';
  }

  @override
  String get appLockedTitle => 'Xeris Wallet gesperrt';

  @override
  String get authenticateToContinue => 'Authentifizieren, um fortzufahren';

  @override
  String get securityAudit => 'SICHERHEITSAUDIT';

  @override
  String get biometricLockActive => 'Biometrische Sperre aktiv';

  @override
  String get pinProtected6Digit => 'Mit 6-stelliger PIN geschützt';

  @override
  String get privacyModeEnabled => 'Privatsphäre-Modus aktiviert';

  @override
  String get privacyModeDisabled => 'Privatsphäre-Modus deaktiviert';

  @override
  String get fullDiskEncryption => 'Vollständige Festplattenverschlüsselung';

  @override
  String get zkProofAsyncInfo =>
      'Xeris verwendet asynchrone ZK proof-Generierung, um Privatsphäre zu wahren, ohne die Wallet-Interaktion zu blockieren.';

  @override
  String get unknownToken => 'Unbekannter Token';

  @override
  String get signTransactionTitle => 'Transaktion signieren';

  @override
  String get signAndSendTransactionTitle => 'Transaktion signieren & senden';

  @override
  String signAllTransactionsTitle(int count) {
    return '$count Transaktionen signieren';
  }

  @override
  String get connectToDappDesc =>
      'Diese App möchte sich mit Ihrem Xeris Wallet verbinden und Ihre öffentliche Adresse einsehen.';

  @override
  String get signTransactionDesc =>
      'Diese App möchte, dass Sie eine Transaktion signieren. Prüfen Sie sorgfältig, bevor Sie genehmigen.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'Diese App möchte, dass Sie $count Transaktionen auf einmal signieren.';
  }

  @override
  String get signMessageDesc =>
      'Diese App möchte, dass Sie eine Nachricht zur Verifizierung signieren.';

  @override
  String get dappRequestUnknown => 'Diese App fordert Wallet-Zugriff an.';

  @override
  String get wrapXrs => 'XRS wrappen';

  @override
  String get unwrapXrs => 'XRS unwrappen';

  @override
  String get swapLabel => 'Tausch';

  @override
  String get interactLabel => 'Interagieren';

  @override
  String get noActiveLimitOrders => 'Keine aktiven Limit-Orders';

  @override
  String get sellingLabel => 'Verkaufen';

  @override
  String get buyingMinLabel => 'Kaufen (Min.)';

  @override
  String get targetPriceLabel => 'Zielpreis';

  @override
  String get orderIdLabel => 'Order-ID';

  @override
  String get cancelOrderTitle => 'Order stornieren';

  @override
  String get cancelOrderConfirm =>
      'Möchten Sie diese Limit-Order wirklich stornieren? Die Mittel werden in Ihr Wallet zurückgesendet.';

  @override
  String get no => 'Nein';

  @override
  String get yesCancel => 'Ja, stornieren';

  @override
  String get cancelTxSubmitted => 'Stornierungstransaktion übermittelt';

  @override
  String get cancelTxFailed => 'Stornierung konnte nicht übermittelt werden';

  @override
  String get noMatchingValidators => 'Keine passenden Validatoren';

  @override
  String get searchTokenPlaceholder => 'Token suchen...';

  @override
  String get zkpTransferSubmitted => 'ZKP-Übertragung übermittelt!';

  @override
  String get paste => 'Einfügen';

  @override
  String get myWallet => 'Mein Wallet';

  @override
  String get networkFee => 'Netzwerkgebühr';

  @override
  String get openStatus => 'OFFEN';

  @override
  String get toLabel => 'An';

  @override
  String get networkLabel => 'Netzwerk';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String get mainnetSoon => 'Mainnet kommt bald';

  @override
  String get connectedSitesTitle => 'Verbundene Seiten';

  @override
  String get connectedSitesSubtitle => 'dApp-Berechtigungen verwalten';

  @override
  String get noConnectedSites => 'Keine verbundenen Seiten';

  @override
  String get noConnectedSitesDesc =>
      'Seiten, mit denen Sie sich über den Browser verbinden, erscheinen hier. Sie können den Zugriff jederzeit widerrufen.';

  @override
  String get connectedSiteRevoked => 'Seitenzugriff widerrufen';

  @override
  String get revokeAllSitesTitle => 'Alle Seiten widerrufen?';

  @override
  String get revokeAllSitesDesc =>
      'Dies trennt alle Webseiten von Ihrem Wallet. Sie müssen den Zugriff erneut anfordern.';

  @override
  String get revokeAll => 'Alle widerrufen';

  @override
  String get revoke => 'Widerrufen';

  @override
  String get allSitesRevoked => 'Alle Seitenberechtigungen widerrufen';

  @override
  String get addressBookTitle => 'Adressbuch';

  @override
  String get addressBookSubtitle => 'Gespeicherte Kontakte verwalten';

  @override
  String get themeTitle => 'Erscheinungsbild';

  @override
  String get selectTheme => 'Erscheinungsbild wählen';

  @override
  String get themeDark => 'Dunkler Modus';

  @override
  String get themeLight => 'Heller Modus';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'Systemeinstellung';

  @override
  String get themeNameDark => 'Dunkel';

  @override
  String get themeNameLight => 'Hell';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'System';
}
