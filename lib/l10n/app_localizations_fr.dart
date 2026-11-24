// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get accountSection => 'Compte';

  @override
  String get manageWalletsTitle => 'Gérer les portefeuilles';

  @override
  String get manageWalletsSubtitle =>
      'Ajouter, supprimer ou changer de portefeuilles';

  @override
  String get recoveryPhraseTitle => 'Phrase de récupération';

  @override
  String get recoveryPhraseSubtitle =>
      'Afficher votre phrase secrète en toute sécurité';

  @override
  String get generalSection => 'Général';

  @override
  String get currencyTitle => 'Devise';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Recevoir des alertes pour les transactions';

  @override
  String get privacyModeTitle => 'Mode Privé';

  @override
  String get privacyModeSubtitle => 'Masquer les soldes sur le tableau de bord';

  @override
  String get securitySection => 'Sécurité';

  @override
  String get biometricTitle => 'Authentification Biométrique';

  @override
  String get biometricSubtitle =>
      'Nécessite Face ID / Empreinte digitale au démarrage';

  @override
  String get supportSection => 'Assistance';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get privacyPolicySubtitle =>
      'Lisez notre politique de confidentialité';

  @override
  String get termsOfServiceTitle => 'Conditions générales';

  @override
  String get termsOfServiceSubtitle => 'Lisez nos conditions de service';

  @override
  String get aboutWalletTitle => 'À propos de Xeris Wallet';

  @override
  String get languageTitle => 'Langue';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get addressCopied => 'Adresse copiée dans le presse-papiers';

  @override
  String get loadingAddress => 'Chargement...';

  @override
  String get errorLoadingAddress => 'Erreur lors du chargement de l\'adresse';

  @override
  String get sinceLastMonth => 'Depuis le mois dernier';

  @override
  String get tokensTitle => 'Jetons';

  @override
  String comingSoon(String itemName) {
    return 'Détails de $itemName bientôt disponibles !';
  }

  @override
  String get actionSend => 'Envoyer';

  @override
  String get actionReceive => 'Recevoir';

  @override
  String get actionSwap => 'Échanger';

  @override
  String get actionEarn => 'Gagner';

  @override
  String get actionScan => 'Scanner';

  @override
  String get navWallet => 'Portefeuille';

  @override
  String get navBrowser => 'Navigateur';

  @override
  String get navActivity => 'Activité';

  @override
  String get balanceHistoryTitle => 'Historique du solde';

  @override
  String get totalBalanceTitle => 'Solde Total';

  @override
  String get noHistoryAvailable => 'Aucun historique disponible';

  @override
  String errorPrefix(String error) {
    return 'Erreur : $error';
  }

  @override
  String get addWalletTitle => 'Ajouter un portefeuille';

  @override
  String get addWalletSubtitle =>
      'Comment souhaitez-vous ajouter un portefeuille ?';

  @override
  String get createNewWallet => 'Créer un nouveau portefeuille';

  @override
  String get createNewWalletDesc =>
      'Générer une nouvelle phrase secrète de 12 mots';

  @override
  String get importExistingWallet => 'Importer un portefeuille existant';

  @override
  String get importExistingWalletDesc =>
      'Restaurer à l\'aide d\'une phrase secrète';

  @override
  String get myWalletsTitle => 'Mes portefeuilles';

  @override
  String get noWallets => 'Aucun portefeuille';

  @override
  String get noWalletsDesc =>
      'Vous n\'avez pas encore de portefeuille. Créez ou importez votre premier portefeuille pour commencer.';

  @override
  String get deleteWalletPromptTitle => 'Supprimer le portefeuille ?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$walletName\" ? Cette action ne peut pas être annulée à moins que vous ayez sauvegardé votre phrase de récupération.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get unlockWallet => 'Déverrouiller le portefeuille';

  @override
  String get authRequired => 'Authentification requise.';

  @override
  String get verifySecretPhraseTitle => 'Vérifier la phrase secrète';

  @override
  String get verifyBackup => 'Vérifiez votre sauvegarde';

  @override
  String get verifyBackupDesc =>
      'Saisissez les mots suivants de votre phrase secrète pour confirmer que vous les avez enregistrés.';

  @override
  String wordNumber(String number) {
    return 'Mot n°$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Saisir le mot n°$number';
  }

  @override
  String get verifyComplete => 'Vérifier et terminer';

  @override
  String get walletVerified => 'Portefeuille vérifié et sécurisé !';

  @override
  String failedCreateWallet(String error) {
    return 'Échec de la création du portefeuille : $error';
  }

  @override
  String get incorrectWords =>
      'Mots incorrects. Veuillez vérifier votre phrase et réessayer.';

  @override
  String get importWalletTitle => 'Importer un portefeuille';

  @override
  String get enterSecretPhrase => 'Entrez la phrase secrète';

  @override
  String get enterRecoveryPhraseDesc =>
      'Entrez votre phrase de récupération de 12 ou 24 mots pour restaurer votre portefeuille.';

  @override
  String get invalidRecoveryPhrase => 'Phrase de récupération invalide';

  @override
  String get walletImportedSuccess => 'Portefeuille importé avec succès !';

  @override
  String failedImportWallet(String error) {
    return 'Échec de l\'importation du portefeuille : $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Phrase de récupération secrète';

  @override
  String get secretPhraseMasterKeyDesc =>
      'Cette phrase secrète est la clé maîtresse de votre portefeuille. Notez-la et conservez-la en lieu sûr. Ne la partagez jamais avec personne.';

  @override
  String get copyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get secretPhraseCopied =>
      'Phrase secrète copiée dans le presse-papiers';

  @override
  String get savedSecretPhraseBtn => 'J\'ai sauvegardé ma phrase secrète';

  @override
  String get welcomeTo => 'Bienvenue sur\nXeris Wallet';

  @override
  String get secureWalletForChain =>
      'Le portefeuille sécurisé pour la chaîne Xeris.';

  @override
  String get createANewWallet => 'Créer un nouveau portefeuille';

  @override
  String get alreadyHaveWallet => 'J\'ai déjà un portefeuille';

  @override
  String get sendAssetsTitle => 'Envoyer des actifs';

  @override
  String get recipientAddress => 'Adresse du destinataire';

  @override
  String get pasteAddressOrScan => 'Coller l\'adresse ou scanner le QR';

  @override
  String get amount => 'Montant';

  @override
  String get max => 'MAX';

  @override
  String get review => 'Vérifier';

  @override
  String balance(String amount, String symbol) {
    return 'Solde : $amount $symbol';
  }

  @override
  String get errorEnterRecipient =>
      'Veuillez entrer une adresse de destinataire';

  @override
  String get errorInvalidAddress => 'Adresse de la chaîne Xeris invalide';

  @override
  String get errorEnterValidAmount => 'Veuillez entrer un montant valide';

  @override
  String get errorInsufficientBalance => 'Solde insuffisant';

  @override
  String get receiveAssetsTitle => 'Recevoir des actifs';

  @override
  String get scanToReceive => 'Scanner pour recevoir';

  @override
  String get sendOnlyXerisAssets =>
      'N\'envoyez que des actifs de la chaîne Xeris à cette adresse.';

  @override
  String get shareAddress => 'Partager l\'adresse';

  @override
  String get swapTitle => 'Échanger';

  @override
  String get from => 'De';

  @override
  String get toEstimated => 'À (Estimé)';

  @override
  String get price => 'Prix';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Tolérance de glissement';

  @override
  String get swapping => 'Échange en cours...';

  @override
  String get selectToken => 'Sélectionner un jeton';

  @override
  String get scanQrCodeTitle => 'Scanner le code QR';

  @override
  String get alignQrCode => 'Alignez le code QR dans le cadre';

  @override
  String get earnRewardsTitle => 'Gagner des récompenses';

  @override
  String get noValidatorsFound =>
      'Aucun validateur trouvé sur le réseau de test.\nVous pouvez toujours essayer de miser sur le réseau.';

  @override
  String validatorAddress(String address) {
    return 'Validateur $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'Mise : $amount XRS';
  }

  @override
  String get stake => 'Miser';

  @override
  String get unstake => 'Unstake';

  @override
  String get directStake => 'Mise directe';

  @override
  String get stakedBalance => 'Solde Staké';

  @override
  String totalStaked(String amount) {
    return 'Total Staké : $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Commission : $value%';
  }

  @override
  String get searchValidators => 'Rechercher des Validateurs';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Confirmer le Stake';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'Vous êtes sur le point de staker $amount XRS sur $validator.';
  }

  @override
  String get confirmUnstakeTitle => 'Confirmer le Unstake';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'Vous êtes sur le point de retirer $amount XRS de $validator.';
  }

  @override
  String get unbondingNotice =>
      'Une période de dévalidation de 7 jours s\'applique';

  @override
  String get transactionSubmitted => 'Transaction soumise';

  @override
  String get transactionFailed => 'Échec de la transaction';

  @override
  String get txSubmittedDesc =>
      'Votre transaction a été soumise au réseau Xeris.';

  @override
  String hashLabel(String hash) {
    return 'Hachage : $hash';
  }

  @override
  String get txHashCopied =>
      'Hachage de la transaction copié dans le presse-papiers';

  @override
  String get viewInExplorer => 'Voir dans l\'explorateur';

  @override
  String get backToDashboard => 'Retour au tableau de bord';

  @override
  String get shareReceipt => 'Partager le Reçu';

  @override
  String get transactionDetails => 'Détails de la Transaction';

  @override
  String get receiptTitle => 'Reçu de Transaction Xeris';

  @override
  String get dateLabel => 'Date';

  @override
  String get statusLabel => 'Statut';

  @override
  String get successStatus => 'Succès';

  @override
  String get failedStatus => 'Échec';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String connectToDapp(String dappName) {
    return 'Se connecter à $dappName ?';
  }

  @override
  String get reject => 'Rejeter';

  @override
  String get approve => 'Approuver';

  @override
  String get details => 'DÉTAILS';

  @override
  String get activityTitle => 'Activité';

  @override
  String get noActivityYet => 'Pas encore d\'activité';

  @override
  String get noActivityDesc =>
      'Vos transactions apparaîtront ici une fois que vous aurez envoyé ou reçu des fonds.';

  @override
  String get errorLoadingActivity => 'Erreur lors du chargement de l\'activité';

  @override
  String get activitySearchHint => 'Rechercher adresse, hash ou jeton';

  @override
  String get activityFilterAll => 'Tous';

  @override
  String get activityFilterSent => 'Envoyés';

  @override
  String get activityFilterReceived => 'Reçus';

  @override
  String get activityFilterSwap => 'Échange';

  @override
  String get activityFilterFailed => 'Échoués';

  @override
  String get activityNoMatches => 'Aucun résultat';

  @override
  String get activityNoMatchesDesc =>
      'Essayez d\'ajuster vos filtres ou votre recherche';

  @override
  String get unknownAddress => 'Inconnu';

  @override
  String receivedAsset(String symbol) {
    return 'Reçu $symbol';
  }

  @override
  String sentAsset(String symbol) {
    return 'Envoyé $symbol';
  }

  @override
  String fromAddress(String address) {
    return 'De : $address';
  }

  @override
  String toAddress(String address) {
    return 'À : $address';
  }

  @override
  String get execContract => 'Exéc';

  @override
  String todayAt(String time) {
    return 'Aujourd\'hui $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Hier $time';
  }

  @override
  String get connectingToDapp => 'Connexion à dApp...';

  @override
  String get signMessageTitle => 'Signer le message';

  @override
  String get messageToSign => 'MESSAGE';

  @override
  String get signBtn => 'Signer';

  @override
  String get searchOrEnterUrl => 'Rechercher ou entrer l\'URL';

  @override
  String get renameWalletTitle => 'Renommer le portefeuille';

  @override
  String get renameWalletPromptDesc =>
      'Entrez un nouveau nom pour votre portefeuille.';

  @override
  String get walletNameLabel => 'Nom du portefeuille';

  @override
  String get save => 'Sauvegarder';

  @override
  String get rename => 'Renommer';

  @override
  String get marketOrder => 'Marché';

  @override
  String get limitOrder => 'Limite';

  @override
  String get limitPriceLabel => 'Prix limite';

  @override
  String get placeLimitOrder => 'Placer un ordre limite';

  @override
  String get manageCoins => 'Gérer les pièces';

  @override
  String get dAppBrowser => 'Navigateur dApp';

  @override
  String connectedTo(String publicKey) {
    return 'Connecté à : $publicKey';
  }

  @override
  String get selectCurrency => 'Sélectionner la devise';

  @override
  String get stakeXrs => 'Staker XRS';

  @override
  String availableXrs(String balance) {
    return 'Disponible : $balance XRS';
  }

  @override
  String get confirmStake => 'Confirmer le staking';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Ajouter de la liquidité : $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'Confirmer le dépôt';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Réviser la transaction';

  @override
  String get youAreSending => 'Vous envoyez';

  @override
  String get confirmAndSend => 'Confirmer et envoyer';

  @override
  String get biometricAuthFailed =>
      'L\'authentification a échoué. Impossible d\'activer la biométrie.';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get recoveryPhraseWarning =>
      'Ne partagez jamais cette phrase. Quiconque possède ces mots peut voler vos actifs.';

  @override
  String get noWalletFound => 'Aucun portefeuille trouvé.';

  @override
  String get recoveryPhraseCopied =>
      'Phrase de récupération copiée dans le presse-papiers';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get authFailed => 'Échec de l\'authentification';

  @override
  String get marketCap => 'Capitalisation boursière';

  @override
  String get totalHolders => 'Nombre total de détenteurs';

  @override
  String get mintAddress => 'Adresse de frappe';

  @override
  String get totalSupply => 'Offre totale';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get tokenDecimals => 'Décimales';

  @override
  String get tokenStandard => 'Standard de jeton';

  @override
  String get noActivityForToken => 'Aucune activité récente pour ce jeton.';

  @override
  String get navAgents => 'Agents';

  @override
  String get agentsTitle => 'Agents IA';

  @override
  String get yourAgents => 'Vos Agents';

  @override
  String get openTasks => 'Tâches Ouvertes';

  @override
  String get registerAgentTitle => 'Enregistrer l\'Agent';

  @override
  String get registerAgentDesc =>
      'Les agents opèrent de manière autonome avec une autorité déléguée. Définissez soigneusement les limites de dépenses — ils ne peuvent pas les dépasser sur la chaîne.';

  @override
  String get agentNameLabel => 'NOM DE L\'AGENT';

  @override
  String get agentNamePlaceholder => 'ex. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'CLÉ PUBLIQUE DE L\'AGENT';

  @override
  String get agentPubKeyPlaceholder => 'Clé publique Ed25519 Base58';

  @override
  String get maxPerTxLabel => 'MAX PAR TRANSACTION (XRS)';

  @override
  String get dailyBudgetLabel => 'BUDGET QUOTIDIEN (XRS)';

  @override
  String get allowedContractsLabel => 'CONTRATS AUTORISÉS';

  @override
  String get allowedContractsPlaceholder =>
      'pool_mtk_xrs, ... (séparés par des virgules)';

  @override
  String get registerAgentBtn => 'Enregistrer l\'Agent';

  @override
  String get revokeAgentBtn => 'Révoquer';

  @override
  String get claimTaskBtn => 'Réclamer';

  @override
  String get lastHeartbeatPrefix => 'Dernier battement de cœur : ';

  @override
  String activeAgentsStatus(int count) {
    return '$count ACTIF(S)';
  }

  @override
  String get sendPrivately => 'Envoyer en Privé';

  @override
  String get sendPrivatelyDesc => 'Montant masqué sur la chaîne via preuve ZK';

  @override
  String get zkpInfoBox =>
      'Le montant du transfert sera masqué sur la chaîne. Seuls vous et le destinataire pouvez vérifier la valeur. Conservez votre facteur d\'aveuglement pour les dossiers fiscaux.';

  @override
  String get generateProofAndSend => 'Générer la Preuve et Envoyer';

  @override
  String get quantumShieldTitle => 'Bouclier Quantique';

  @override
  String get quantumShieldSubtitle => 'Cryptographie post-quantique';

  @override
  String get quantumShieldDesc =>
      'Protégez votre portefeuille avec la cryptographie post-quantique (ML-DSA-65)';

  @override
  String get quantumProtectionActive => 'Protection Quantique Active';

  @override
  String get notProtected => 'Non Protégé';

  @override
  String get pqSecurityLevel => 'ML-DSA-65 · Sécurité PQ 128 bits';

  @override
  String get vulnerableToQuantum => 'Vulnérable aux attaques quantiques';

  @override
  String get statusActive => 'ACTIVO';

  @override
  String get statusOff => 'DÉSACTIVÉ';

  @override
  String get zkProofsUsed => 'Preuves ZK utilisées';

  @override
  String get pqKeysRegistered => 'Clés PQ enregistrées';

  @override
  String get blockTimeStat => 'Temps de bloc';

  @override
  String get quantumProtectedDesc =>
      'Votre portefeuille est protégé contre le quantique. Les transferts signés avec ML-DSA-65 affichent un badge 🛡 dans l\'explorateur.';

  @override
  String get enableQuantumProtectionDesc =>
      'L\'activation de la protection quantique génère une paire de clés ML-DSA-65 et enregistre votre clé publique sur la chaîne. Il s\'agit d\'une configuration unique.';

  @override
  String get sendWithQuantumSigning => 'Envoyer avec signature quantique';

  @override
  String get enableQuantumProtectionBtn => 'Activer la Protection Quantique';

  @override
  String get quantumEnabledSuccess => 'Protection Quantique Activée !';

  @override
  String failedToEnablePq(String error) {
    return 'Échec de l\'activation : $error';
  }

  @override
  String get quantumBackupTitle => 'Sauvegarder l\'Identité Quantique';

  @override
  String get quantumBackupWarning =>
      'Votre mnémonique de 12 mots ne suffit plus à récupérer ce portefeuille. Vous DEVEZ sauvegarder cette Clé Secrète Quantique.';

  @override
  String get quantumSecretKeyLabel => 'CLÉ SECRÈTE QUANTIQUE';

  @override
  String get backupConfirmedLabel =>
      'J\'ai sauvegardé en toute sécurité ma Clé Secrète Quantique';

  @override
  String get viewRecoveryKey => 'Voir la Clé de Récupération';

  @override
  String get pinCodeTitle => 'Code PIN';

  @override
  String get pinCodeSubtitle =>
      'Sécurisez votre portefeuille avec un PIN à 6 chiffres';

  @override
  String get changePinCodeTitle => 'Changer le code PIN';

  @override
  String get changePinCodeSubtitle => 'Mettez à jour votre PIN de sécurité';

  @override
  String get pinCodeUpdated => 'Code PIN mis à jour avec succès';

  @override
  String get noAgentsRegistered => 'Aucun agent enregistré.';

  @override
  String get noOpenTasks => 'Aucune tâche ouverte.';

  @override
  String get refresh => 'Rafraîchir';

  @override
  String get zkpOnlyXrsError =>
      'Les transferts privés ZKP ne prennent en charge que le XRS pour le moment.';

  @override
  String get pqcOnlyXrsError =>
      'Les transferts signés quantiquement ne prennent actuellement en charge que le XRS.';

  @override
  String get required => 'Requis';

  @override
  String get enterPinCode => 'Entrez le code PIN';

  @override
  String get setNewPin => 'Définir un nouveau PIN';

  @override
  String get confirmPin => 'Confirmez votre PIN';

  @override
  String get pinSubtitle => 'Sécurisez vos actifs avec un PIN à 6 chiffres';

  @override
  String get incorrectPin => 'Code PIN incorrect';

  @override
  String get pinsDoNotMatch => 'Les codes PIN ne correspondent pas. Réessayez.';

  @override
  String get panicPinTitle => 'Code PIN Panique (Auto-destruction)';

  @override
  String get panicPinSubtitle =>
      'Un code qui efface toutes les données lors de la saisie';

  @override
  String get setPanicPin => 'Définir le PIN Panique';

  @override
  String get confirmPanicPin => 'Confirmer le PIN Panique';

  @override
  String get panicTriggered =>
      'PIN Panique déclenché. Toutes les données ont été effacées.';

  @override
  String agentMaxPerTx(Object amount) {
    return 'Max/tx : $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return 'Quotidien : $amount XRS';
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
  String get signTransactionTitle => 'Signer la Transaction';

  @override
  String get signAndSendTransactionTitle => 'Signer et Envoyer la Transaction';

  @override
  String signAllTransactionsTitle(int count) {
    return 'Signer $count Transactions';
  }

  @override
  String get connectToDappDesc =>
      'Cette application souhaite se connecter à votre portefeuille Xeris et voir votre adresse publique.';

  @override
  String get signTransactionDesc =>
      'Cette application souhaite que vous signiez une transaction. Vérifiez attentivement avant d\'approuver.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'Cette application souhaite que vous signiez $count transactions en une fois.';
  }

  @override
  String get signMessageDesc =>
      'Cette application souhaite que vous signiez un message pour vérification.';

  @override
  String get dappRequestUnknown =>
      'Cette application demande l\'accès au portefeuille.';

  @override
  String get wrapXrs => 'Wrap XRS';

  @override
  String get unwrapXrs => 'Unwrap XRS';

  @override
  String get swapLabel => 'Échange';

  @override
  String get interactLabel => 'Interagir';

  @override
  String get noActiveLimitOrders => 'Aucun ordre limite actif';

  @override
  String get sellingLabel => 'Vente';

  @override
  String get buyingMinLabel => 'Achat (Min)';

  @override
  String get targetPriceLabel => 'Prix Cible';

  @override
  String get orderIdLabel => 'ID de l\'ordre';

  @override
  String get cancelOrderTitle => 'Annuler l\'ordre';

  @override
  String get cancelOrderConfirm =>
      'Êtes-vous sûr de vouloir annuler cet ordre limite ? Les fonds seront renvoyés à votre portefeuille.';

  @override
  String get no => 'Non';

  @override
  String get yesCancel => 'Oui, annuler';

  @override
  String get cancelTxSubmitted => 'Transaction d\'annulation envoyée';

  @override
  String get cancelTxFailed => 'Échec de l\'envoi de l\'annulation';

  @override
  String get noMatchingValidators => 'Aucun validateur correspondant';

  @override
  String get searchTokenPlaceholder => 'Rechercher un jeton...';

  @override
  String get zkpTransferSubmitted => 'Transfert ZKP Envoyé !';

  @override
  String get paste => 'Coller';

  @override
  String get myWallet => 'Mon Portefeuille';

  @override
  String get networkFee => 'Frais de Réseau';

  @override
  String get openStatus => 'OUVERT';

  @override
  String get toLabel => 'À';

  @override
  String get networkLabel => 'Réseau';

  @override
  String get testnetLabel => 'Testnet';

  @override
  String get mainnetLabel => 'Mainnet';

  @override
  String get mainnetSoon => 'Le Mainnet arrive bientôt';

  @override
  String get connectedSitesTitle => 'Sites Connectés';

  @override
  String get connectedSitesSubtitle => 'Gérer les permissions des dApps';

  @override
  String get noConnectedSites => 'Aucun Site Connecté';

  @override
  String get noConnectedSitesDesc =>
      'Les sites auxquels vous vous connectez via le navigateur apparaîtront ici. Vous pouvez révoquer leur accès à tout moment.';

  @override
  String get connectedSiteRevoked => 'Accès au site révoqué';

  @override
  String get revokeAllSitesTitle => 'Révoquer tous les sites ?';

  @override
  String get revokeAllSitesDesc =>
      'Cela déconnectera tous les sites web de votre portefeuille. Ils devront demander l\'accès à nouveau.';

  @override
  String get revokeAll => 'Tout Révoquer';

  @override
  String get revoke => 'Révoquer';

  @override
  String get allSitesRevoked => 'Tous les permissions de sites révoquées';

  @override
  String get addressBookTitle => 'Carnet d\'adresses';

  @override
  String get addressBookSubtitle => 'Gérer les contacts enregistrés';

  @override
  String get themeTitle => 'Thème';

  @override
  String get selectTheme => 'Sélectionner le thème';

  @override
  String get themeDark => 'Mode Sombre';

  @override
  String get themeLight => 'Mode Clair';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'Paramètre du système';

  @override
  String get themeNameDark => 'Sombre';

  @override
  String get themeNameLight => 'Clair';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'Système';
}
