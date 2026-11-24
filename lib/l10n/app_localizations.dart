import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('af'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('nl'),
    Locale('tl'),
    Locale('zh')
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @manageWalletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Wallets'**
  String get manageWalletsTitle;

  /// No description provided for @manageWalletsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, remove, or switch wallets'**
  String get manageWalletsSubtitle;

  /// No description provided for @recoveryPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase'**
  String get recoveryPhraseTitle;

  /// No description provided for @recoveryPhraseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your secret seed phrase secured'**
  String get recoveryPhraseSubtitle;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts for transactions'**
  String get notificationsSubtitle;

  /// No description provided for @privacyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode'**
  String get privacyModeTitle;

  /// No description provided for @privacyModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Obscure balances on the dashboard'**
  String get privacyModeSubtitle;

  /// No description provided for @securitySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySection;

  /// No description provided for @biometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricTitle;

  /// No description provided for @biometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require Face ID / Fingerprint on startup'**
  String get biometricSubtitle;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportSection;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get termsOfServiceSubtitle;

  /// No description provided for @aboutWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'About Xeris Wallet'**
  String get aboutWalletTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get addressCopied;

  /// No description provided for @loadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingAddress;

  /// No description provided for @errorLoadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Error loading address'**
  String get errorLoadingAddress;

  /// No description provided for @sinceLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Since Last Month'**
  String get sinceLastMonth;

  /// No description provided for @tokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get tokensTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{itemName} details coming soon!'**
  String comingSoon(String itemName);

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @actionReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get actionReceive;

  /// No description provided for @actionSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get actionSwap;

  /// No description provided for @actionEarn.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get actionEarn;

  /// No description provided for @actionScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get actionScan;

  /// No description provided for @navWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// No description provided for @navBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get navBrowser;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @balanceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance History'**
  String get balanceHistoryTitle;

  /// No description provided for @totalBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalanceTitle;

  /// No description provided for @noHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get noHistoryAvailable;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @addWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWalletTitle;

  /// No description provided for @addWalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to add a wallet?'**
  String get addWalletSubtitle;

  /// No description provided for @createNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get createNewWallet;

  /// No description provided for @createNewWalletDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate a new 12-word secret recovery phrase'**
  String get createNewWalletDesc;

  /// No description provided for @importExistingWallet.
  ///
  /// In en, this message translates to:
  /// **'Import Existing Wallet'**
  String get importExistingWallet;

  /// No description provided for @importExistingWalletDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore using a secret recovery phrase'**
  String get importExistingWalletDesc;

  /// No description provided for @myWalletsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallets'**
  String get myWalletsTitle;

  /// No description provided for @noWallets.
  ///
  /// In en, this message translates to:
  /// **'No Wallets'**
  String get noWallets;

  /// No description provided for @noWalletsDesc.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any wallets yet. Create or import your first wallet to get started.'**
  String get noWalletsDesc;

  /// No description provided for @deleteWalletPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet?'**
  String get deleteWalletPromptTitle;

  /// No description provided for @deleteWalletPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{walletName}\"? This action cannot be undone unless you have your recovery phrase saved.'**
  String deleteWalletPromptDesc(Object walletName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @unlockWallet.
  ///
  /// In en, this message translates to:
  /// **'Unlock Wallet'**
  String get unlockWallet;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required.'**
  String get authRequired;

  /// No description provided for @verifySecretPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Secret Phrase'**
  String get verifySecretPhraseTitle;

  /// No description provided for @verifyBackup.
  ///
  /// In en, this message translates to:
  /// **'Verify your backup'**
  String get verifyBackup;

  /// No description provided for @verifyBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the following words from your secret phrase to confirm you have saved them.'**
  String get verifyBackupDesc;

  /// No description provided for @wordNumber.
  ///
  /// In en, this message translates to:
  /// **'Word #{number}'**
  String wordNumber(String number);

  /// No description provided for @enterWordNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter word #{number}'**
  String enterWordNumber(String number);

  /// No description provided for @verifyComplete.
  ///
  /// In en, this message translates to:
  /// **'Verify & Complete'**
  String get verifyComplete;

  /// No description provided for @walletVerified.
  ///
  /// In en, this message translates to:
  /// **'Wallet verified and secured!'**
  String get walletVerified;

  /// No description provided for @failedCreateWallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to create wallet: {error}'**
  String failedCreateWallet(String error);

  /// No description provided for @incorrectWords.
  ///
  /// In en, this message translates to:
  /// **'Incorrect words. Please check your phrase and try again.'**
  String get incorrectWords;

  /// No description provided for @importWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Wallet'**
  String get importWalletTitle;

  /// No description provided for @enterSecretPhrase.
  ///
  /// In en, this message translates to:
  /// **'Enter Secret Phrase'**
  String get enterSecretPhrase;

  /// No description provided for @enterRecoveryPhraseDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12 or 24-word recovery phrase to restore your wallet.'**
  String get enterRecoveryPhraseDesc;

  /// No description provided for @invalidRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Invalid recovery phrase'**
  String get invalidRecoveryPhrase;

  /// No description provided for @walletImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet imported successfully!'**
  String get walletImportedSuccess;

  /// No description provided for @failedImportWallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to import wallet: {error}'**
  String failedImportWallet(String error);

  /// No description provided for @secretRecoveryPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret Recovery Phrase'**
  String get secretRecoveryPhraseTitle;

  /// No description provided for @secretPhraseMasterKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'This secret phrase is the master key to your wallet. Write it down and store it in a secure place. Never share it with anyone.'**
  String get secretPhraseMasterKeyDesc;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @secretPhraseCopied.
  ///
  /// In en, this message translates to:
  /// **'Secret phrase copied to clipboard'**
  String get secretPhraseCopied;

  /// No description provided for @savedSecretPhraseBtn.
  ///
  /// In en, this message translates to:
  /// **'I have saved my secret phrase'**
  String get savedSecretPhraseBtn;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nXeris Wallet'**
  String get welcomeTo;

  /// No description provided for @secureWalletForChain.
  ///
  /// In en, this message translates to:
  /// **'The secure wallet for the Xeris Chain.'**
  String get secureWalletForChain;

  /// No description provided for @createANewWallet.
  ///
  /// In en, this message translates to:
  /// **'Create a New Wallet'**
  String get createANewWallet;

  /// No description provided for @alreadyHaveWallet.
  ///
  /// In en, this message translates to:
  /// **'I already have a wallet'**
  String get alreadyHaveWallet;

  /// No description provided for @sendAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Assets'**
  String get sendAssetsTitle;

  /// No description provided for @recipientAddress.
  ///
  /// In en, this message translates to:
  /// **'Recipient Address'**
  String get recipientAddress;

  /// No description provided for @pasteAddressOrScan.
  ///
  /// In en, this message translates to:
  /// **'Paste address or scan QR'**
  String get pasteAddressOrScan;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get max;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount} {symbol}'**
  String balance(String amount, String symbol);

  /// No description provided for @errorEnterRecipient.
  ///
  /// In en, this message translates to:
  /// **'Please enter a recipient address'**
  String get errorEnterRecipient;

  /// No description provided for @errorInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Xeris Chain address'**
  String get errorInvalidAddress;

  /// No description provided for @errorEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get errorEnterValidAmount;

  /// No description provided for @errorInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get errorInsufficientBalance;

  /// No description provided for @receiveAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive Assets'**
  String get receiveAssetsTitle;

  /// No description provided for @scanToReceive.
  ///
  /// In en, this message translates to:
  /// **'Scan to Receive'**
  String get scanToReceive;

  /// No description provided for @sendOnlyXerisAssets.
  ///
  /// In en, this message translates to:
  /// **'Send only Xeris Chain assets to this address.'**
  String get sendOnlyXerisAssets;

  /// No description provided for @shareAddress.
  ///
  /// In en, this message translates to:
  /// **'Share Address'**
  String get shareAddress;

  /// No description provided for @swapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swapTitle;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @toEstimated.
  ///
  /// In en, this message translates to:
  /// **'To (Estimated)'**
  String get toEstimated;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceEstimate.
  ///
  /// In en, this message translates to:
  /// **'1 {fromSymbol} ≈ {rate} {toSymbol}'**
  String priceEstimate(String fromSymbol, String rate, String toSymbol);

  /// No description provided for @slippageTolerance.
  ///
  /// In en, this message translates to:
  /// **'Slippage Tolerance'**
  String get slippageTolerance;

  /// No description provided for @swapping.
  ///
  /// In en, this message translates to:
  /// **'Swapping...'**
  String get swapping;

  /// No description provided for @selectToken.
  ///
  /// In en, this message translates to:
  /// **'Select Token'**
  String get selectToken;

  /// No description provided for @scanQrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCodeTitle;

  /// No description provided for @alignQrCode.
  ///
  /// In en, this message translates to:
  /// **'Align QR code within the frame'**
  String get alignQrCode;

  /// No description provided for @earnRewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn Rewards'**
  String get earnRewardsTitle;

  /// No description provided for @noValidatorsFound.
  ///
  /// In en, this message translates to:
  /// **'No validators found on testnet.\nYou can still try staking to network.'**
  String get noValidatorsFound;

  /// No description provided for @validatorAddress.
  ///
  /// In en, this message translates to:
  /// **'Validator {address}...'**
  String validatorAddress(String address);

  /// No description provided for @stakeAmount.
  ///
  /// In en, this message translates to:
  /// **'Stake: {amount} XRS'**
  String stakeAmount(String amount);

  /// No description provided for @stake.
  ///
  /// In en, this message translates to:
  /// **'Stake'**
  String get stake;

  /// No description provided for @unstake.
  ///
  /// In en, this message translates to:
  /// **'Unstake'**
  String get unstake;

  /// No description provided for @directStake.
  ///
  /// In en, this message translates to:
  /// **'Direct Stake'**
  String get directStake;

  /// No description provided for @stakedBalance.
  ///
  /// In en, this message translates to:
  /// **'Staked Balance'**
  String get stakedBalance;

  /// No description provided for @totalStaked.
  ///
  /// In en, this message translates to:
  /// **'Total Staked: {amount} XRS'**
  String totalStaked(String amount);

  /// No description provided for @commissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Commission: {value}%'**
  String commissionLabel(String value);

  /// No description provided for @searchValidators.
  ///
  /// In en, this message translates to:
  /// **'Search Validators'**
  String get searchValidators;

  /// No description provided for @stakeAmountPercentage.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String stakeAmountPercentage(Object percent);

  /// No description provided for @confirmStakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Stake'**
  String get confirmStakeTitle;

  /// No description provided for @confirmStakeDesc.
  ///
  /// In en, this message translates to:
  /// **'You are about to stake {amount} XRS to {validator}.'**
  String confirmStakeDesc(Object amount, Object validator);

  /// No description provided for @confirmUnstakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Unstake'**
  String get confirmUnstakeTitle;

  /// No description provided for @confirmUnstakeDesc.
  ///
  /// In en, this message translates to:
  /// **'You are about to unstake {amount} XRS from {validator}.'**
  String confirmUnstakeDesc(Object amount, Object validator);

  /// No description provided for @unbondingNotice.
  ///
  /// In en, this message translates to:
  /// **'7-day unbonding period applies'**
  String get unbondingNotice;

  /// No description provided for @transactionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Transaction Submitted'**
  String get transactionSubmitted;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction Failed'**
  String get transactionFailed;

  /// No description provided for @txSubmittedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your transaction has been submitted to the Xeris network.'**
  String get txSubmittedDesc;

  /// No description provided for @hashLabel.
  ///
  /// In en, this message translates to:
  /// **'Hash: {hash}'**
  String hashLabel(String hash);

  /// No description provided for @txHashCopied.
  ///
  /// In en, this message translates to:
  /// **'Transaction hash copied to clipboard'**
  String get txHashCopied;

  /// No description provided for @viewInExplorer.
  ///
  /// In en, this message translates to:
  /// **'View in Explorer'**
  String get viewInExplorer;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceipt;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Xeris Transaction Receipt'**
  String get receiptTitle;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @successStatus.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successStatus;

  /// No description provided for @failedStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedStatus;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @connectToDapp.
  ///
  /// In en, this message translates to:
  /// **'Connect to {dappName}?'**
  String connectToDapp(String dappName);

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get details;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No Activity Yet'**
  String get noActivityYet;

  /// No description provided for @noActivityDesc.
  ///
  /// In en, this message translates to:
  /// **'Your transactions will appear here once you send or receive funds.'**
  String get noActivityDesc;

  /// No description provided for @errorLoadingActivity.
  ///
  /// In en, this message translates to:
  /// **'Error loading activity'**
  String get errorLoadingActivity;

  /// No description provided for @activitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search address, tx hash, or token'**
  String get activitySearchHint;

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @activityFilterSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get activityFilterSent;

  /// No description provided for @activityFilterReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get activityFilterReceived;

  /// No description provided for @activityFilterSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get activityFilterSwap;

  /// No description provided for @activityFilterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get activityFilterFailed;

  /// No description provided for @activityNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get activityNoMatches;

  /// No description provided for @activityNoMatchesDesc.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search'**
  String get activityNoMatchesDesc;

  /// No description provided for @unknownAddress.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownAddress;

  /// No description provided for @receivedAsset.
  ///
  /// In en, this message translates to:
  /// **'Received {symbol}'**
  String receivedAsset(String symbol);

  /// No description provided for @sentAsset.
  ///
  /// In en, this message translates to:
  /// **'Sent {symbol}'**
  String sentAsset(String symbol);

  /// No description provided for @fromAddress.
  ///
  /// In en, this message translates to:
  /// **'From: {address}'**
  String fromAddress(String address);

  /// No description provided for @toAddress.
  ///
  /// In en, this message translates to:
  /// **'To: {address}'**
  String toAddress(String address);

  /// No description provided for @execContract.
  ///
  /// In en, this message translates to:
  /// **'Exec'**
  String get execContract;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayAt(String time);

  /// No description provided for @connectingToDapp.
  ///
  /// In en, this message translates to:
  /// **'Connecting to dApp...'**
  String get connectingToDapp;

  /// No description provided for @signMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Message'**
  String get signMessageTitle;

  /// No description provided for @messageToSign.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get messageToSign;

  /// No description provided for @signBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get signBtn;

  /// No description provided for @searchOrEnterUrl.
  ///
  /// In en, this message translates to:
  /// **'Search or enter URL'**
  String get searchOrEnterUrl;

  /// No description provided for @renameWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Wallet'**
  String get renameWalletTitle;

  /// No description provided for @renameWalletPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter a new name for your wallet.'**
  String get renameWalletPromptDesc;

  /// No description provided for @walletNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletNameLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @marketOrder.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get marketOrder;

  /// No description provided for @limitOrder.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limitOrder;

  /// No description provided for @limitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit Price'**
  String get limitPriceLabel;

  /// No description provided for @placeLimitOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Limit Order'**
  String get placeLimitOrder;

  /// No description provided for @manageCoins.
  ///
  /// In en, this message translates to:
  /// **'Manage Coins'**
  String get manageCoins;

  /// No description provided for @dAppBrowser.
  ///
  /// In en, this message translates to:
  /// **'Xeris web4 browser'**
  String get dAppBrowser;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected: {publicKey}'**
  String connectedTo(String publicKey);

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @stakeXrs.
  ///
  /// In en, this message translates to:
  /// **'Stake XRS'**
  String get stakeXrs;

  /// No description provided for @availableXrs.
  ///
  /// In en, this message translates to:
  /// **'Available: {balance} XRS'**
  String availableXrs(String balance);

  /// No description provided for @confirmStake.
  ///
  /// In en, this message translates to:
  /// **'Confirm Stake'**
  String get confirmStake;

  /// No description provided for @addLiquidityWithTokens.
  ///
  /// In en, this message translates to:
  /// **'Add Liquidity: {tokenA}/{tokenB}'**
  String addLiquidityWithTokens(String tokenA, String tokenB);

  /// No description provided for @confirmDeposit.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deposit'**
  String get confirmDeposit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reviewTransaction.
  ///
  /// In en, this message translates to:
  /// **'Review Transaction'**
  String get reviewTransaction;

  /// No description provided for @youAreSending.
  ///
  /// In en, this message translates to:
  /// **'You are sending'**
  String get youAreSending;

  /// No description provided for @confirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Send'**
  String get confirmAndSend;

  /// No description provided for @biometricAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Cannot enable biometrics.'**
  String get biometricAuthFailed;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @recoveryPhraseWarning.
  ///
  /// In en, this message translates to:
  /// **'Never share this phrase. Anyone with these words can steal your assets.'**
  String get recoveryPhraseWarning;

  /// No description provided for @noWalletFound.
  ///
  /// In en, this message translates to:
  /// **'No wallet found.'**
  String get noWalletFound;

  /// No description provided for @recoveryPhraseCopied.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase copied to clipboard'**
  String get recoveryPhraseCopied;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authFailed;

  /// No description provided for @marketCap.
  ///
  /// In en, this message translates to:
  /// **'Market Cap'**
  String get marketCap;

  /// No description provided for @totalHolders.
  ///
  /// In en, this message translates to:
  /// **'Total Holders'**
  String get totalHolders;

  /// No description provided for @mintAddress.
  ///
  /// In en, this message translates to:
  /// **'Mint Address'**
  String get mintAddress;

  /// No description provided for @totalSupply.
  ///
  /// In en, this message translates to:
  /// **'Total Supply'**
  String get totalSupply;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @tokenDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get tokenDecimals;

  /// No description provided for @tokenStandard.
  ///
  /// In en, this message translates to:
  /// **'Token Standard'**
  String get tokenStandard;

  /// No description provided for @noActivityForToken.
  ///
  /// In en, this message translates to:
  /// **'No recent activity for this token.'**
  String get noActivityForToken;

  /// No description provided for @navAgents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get navAgents;

  /// No description provided for @agentsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Agents'**
  String get agentsTitle;

  /// No description provided for @yourAgents.
  ///
  /// In en, this message translates to:
  /// **'Your Agents'**
  String get yourAgents;

  /// No description provided for @openTasks.
  ///
  /// In en, this message translates to:
  /// **'Open Tasks'**
  String get openTasks;

  /// No description provided for @registerAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Agent'**
  String get registerAgentTitle;

  /// No description provided for @registerAgentDesc.
  ///
  /// In en, this message translates to:
  /// **'Agents operate autonomously with delegated authority. Set spending limits carefully — they cannot exceed these on-chain.'**
  String get registerAgentDesc;

  /// No description provided for @agentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'AGENT NAME'**
  String get agentNameLabel;

  /// No description provided for @agentNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ari-Trader-v1'**
  String get agentNamePlaceholder;

  /// No description provided for @agentPubKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'AGENT PUBLIC KEY'**
  String get agentPubKeyLabel;

  /// No description provided for @agentPubKeyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Base58 Ed25519 pubkey'**
  String get agentPubKeyPlaceholder;

  /// No description provided for @maxPerTxLabel.
  ///
  /// In en, this message translates to:
  /// **'MAX PER TRANSACTION (XRS)'**
  String get maxPerTxLabel;

  /// No description provided for @dailyBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'DAILY BUDGET (XRS)'**
  String get dailyBudgetLabel;

  /// No description provided for @allowedContractsLabel.
  ///
  /// In en, this message translates to:
  /// **'ALLOWED CONTRACTS'**
  String get allowedContractsLabel;

  /// No description provided for @allowedContractsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'pool_mtk_xrs, ... (comma-separated)'**
  String get allowedContractsPlaceholder;

  /// No description provided for @registerAgentBtn.
  ///
  /// In en, this message translates to:
  /// **'Register Agent'**
  String get registerAgentBtn;

  /// No description provided for @revokeAgentBtn.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeAgentBtn;

  /// No description provided for @claimTaskBtn.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claimTaskBtn;

  /// No description provided for @lastHeartbeatPrefix.
  ///
  /// In en, this message translates to:
  /// **'Last heartbeat: '**
  String get lastHeartbeatPrefix;

  /// No description provided for @activeAgentsStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} ACTIVE'**
  String activeAgentsStatus(int count);

  /// No description provided for @sendPrivately.
  ///
  /// In en, this message translates to:
  /// **'Send Privately'**
  String get sendPrivately;

  /// No description provided for @sendPrivatelyDesc.
  ///
  /// In en, this message translates to:
  /// **'Amount hidden on-chain via ZK proof'**
  String get sendPrivatelyDesc;

  /// No description provided for @zkpInfoBox.
  ///
  /// In en, this message translates to:
  /// **'The transfer amount will be hidden on-chain. Only you and the recipient can verify the value. Save your blinding factor for tax records.'**
  String get zkpInfoBox;

  /// No description provided for @generateProofAndSend.
  ///
  /// In en, this message translates to:
  /// **'Generate Proof & Send'**
  String get generateProofAndSend;

  /// No description provided for @quantumShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Quantum Shield'**
  String get quantumShieldTitle;

  /// No description provided for @quantumShieldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post-quantum cryptography'**
  String get quantumShieldSubtitle;

  /// No description provided for @quantumShieldDesc.
  ///
  /// In en, this message translates to:
  /// **'Protect your wallet with post-quantum cryptography (ML-DSA-65)'**
  String get quantumShieldDesc;

  /// No description provided for @quantumProtectionActive.
  ///
  /// In en, this message translates to:
  /// **'Quantum Protection Active'**
  String get quantumProtectionActive;

  /// No description provided for @notProtected.
  ///
  /// In en, this message translates to:
  /// **'Not Protected'**
  String get notProtected;

  /// No description provided for @pqSecurityLevel.
  ///
  /// In en, this message translates to:
  /// **'ML-DSA-65 · 128-bit PQ security'**
  String get pqSecurityLevel;

  /// No description provided for @vulnerableToQuantum.
  ///
  /// In en, this message translates to:
  /// **'Vulnerable to quantum attacks'**
  String get vulnerableToQuantum;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @statusOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get statusOff;

  /// No description provided for @zkProofsUsed.
  ///
  /// In en, this message translates to:
  /// **'ZK Proofs Used'**
  String get zkProofsUsed;

  /// No description provided for @pqKeysRegistered.
  ///
  /// In en, this message translates to:
  /// **'PQ Keys Registered'**
  String get pqKeysRegistered;

  /// No description provided for @blockTimeStat.
  ///
  /// In en, this message translates to:
  /// **'Block Time'**
  String get blockTimeStat;

  /// No description provided for @quantumProtectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is quantum-protected. Transfers signed with ML-DSA-65 show a 🛡 badge in the explorer.'**
  String get quantumProtectedDesc;

  /// No description provided for @enableQuantumProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Enabling quantum protection generates a ML-DSA-65 keypair and registers your public key on-chain. This is a one-time setup.'**
  String get enableQuantumProtectionDesc;

  /// No description provided for @sendWithQuantumSigning.
  ///
  /// In en, this message translates to:
  /// **'Send with Quantum Signing'**
  String get sendWithQuantumSigning;

  /// No description provided for @enableQuantumProtectionBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable Quantum Protection'**
  String get enableQuantumProtectionBtn;

  /// No description provided for @quantumEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Quantum Protection Enabled!'**
  String get quantumEnabledSuccess;

  /// No description provided for @failedToEnablePq.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable: {error}'**
  String failedToEnablePq(String error);

  /// No description provided for @quantumBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Quantum Identity'**
  String get quantumBackupTitle;

  /// No description provided for @quantumBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'Your 12-word mnemonic is no longer enough to recover this wallet. You MUST back up this Quantum Secret Key.'**
  String get quantumBackupWarning;

  /// No description provided for @quantumSecretKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'QUANTUM SECRET KEY'**
  String get quantumSecretKeyLabel;

  /// No description provided for @backupConfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'I have securely backed up my Quantum Secret Key'**
  String get backupConfirmedLabel;

  /// No description provided for @viewRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'View Recovery Key'**
  String get viewRecoveryKey;

  /// No description provided for @pinCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pinCodeTitle;

  /// No description provided for @pinCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure wallet with a 6-digit PIN'**
  String get pinCodeSubtitle;

  /// No description provided for @changePinCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN Code'**
  String get changePinCodeTitle;

  /// No description provided for @changePinCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your security PIN'**
  String get changePinCodeSubtitle;

  /// No description provided for @pinCodeUpdated.
  ///
  /// In en, this message translates to:
  /// **'PIN Code updated successfully'**
  String get pinCodeUpdated;

  /// No description provided for @noAgentsRegistered.
  ///
  /// In en, this message translates to:
  /// **'No agents registered.'**
  String get noAgentsRegistered;

  /// No description provided for @noOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'No open tasks.'**
  String get noOpenTasks;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @zkpOnlyXrsError.
  ///
  /// In en, this message translates to:
  /// **'ZKP private transfers only support XRS at this time.'**
  String get zkpOnlyXrsError;

  /// No description provided for @pqcOnlyXrsError.
  ///
  /// In en, this message translates to:
  /// **'Quantum Signed transfers currently only support XRS.'**
  String get pqcOnlyXrsError;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterPinCode.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN Code'**
  String get enterPinCode;

  /// No description provided for @setNewPin.
  ///
  /// In en, this message translates to:
  /// **'Set a New PIN'**
  String get setNewPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your PIN'**
  String get confirmPin;

  /// No description provided for @pinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your assets with a 6-digit PIN'**
  String get pinSubtitle;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Try again.'**
  String get pinsDoNotMatch;

  /// No description provided for @panicPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Panic PIN (Self-Destruct)'**
  String get panicPinTitle;

  /// No description provided for @panicPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A code that wipes all data when entered'**
  String get panicPinSubtitle;

  /// No description provided for @setPanicPin.
  ///
  /// In en, this message translates to:
  /// **'Set Panic PIN'**
  String get setPanicPin;

  /// No description provided for @confirmPanicPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm Panic PIN'**
  String get confirmPanicPin;

  /// No description provided for @panicTriggered.
  ///
  /// In en, this message translates to:
  /// **'Panic PIN triggered. All data cleared.'**
  String get panicTriggered;

  /// No description provided for @agentMaxPerTx.
  ///
  /// In en, this message translates to:
  /// **'Max/tx: {amount} XRS'**
  String agentMaxPerTx(Object amount);

  /// No description provided for @agentDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily: {amount} XRS'**
  String agentDailyLimit(Object amount);

  /// No description provided for @appLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Xeris Wallet Locked'**
  String get appLockedTitle;

  /// No description provided for @authenticateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue'**
  String get authenticateToContinue;

  /// No description provided for @securityAudit.
  ///
  /// In en, this message translates to:
  /// **'SECURITY AUDIT'**
  String get securityAudit;

  /// No description provided for @biometricLockActive.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock Active'**
  String get biometricLockActive;

  /// No description provided for @pinProtected6Digit.
  ///
  /// In en, this message translates to:
  /// **'6-Digit PIN Protected'**
  String get pinProtected6Digit;

  /// No description provided for @privacyModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode Enabled'**
  String get privacyModeEnabled;

  /// No description provided for @privacyModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Privacy Mode Disabled'**
  String get privacyModeDisabled;

  /// No description provided for @fullDiskEncryption.
  ///
  /// In en, this message translates to:
  /// **'Full Disk Encryption'**
  String get fullDiskEncryption;

  /// No description provided for @zkProofAsyncInfo.
  ///
  /// In en, this message translates to:
  /// **'Xeris uses asynchronous ZK proof generation to maintain privacy without blocking your wallet interaction.'**
  String get zkProofAsyncInfo;

  /// No description provided for @unknownToken.
  ///
  /// In en, this message translates to:
  /// **'Unknown Token'**
  String get unknownToken;

  /// No description provided for @signTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Transaction'**
  String get signTransactionTitle;

  /// No description provided for @signAndSendTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign & Send Transaction'**
  String get signAndSendTransactionTitle;

  /// No description provided for @signAllTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign {count} Transactions'**
  String signAllTransactionsTitle(int count);

  /// No description provided for @connectToDappDesc.
  ///
  /// In en, this message translates to:
  /// **'This app wants to connect to your Xeris wallet and view your public address.'**
  String get connectToDappDesc;

  /// No description provided for @signTransactionDesc.
  ///
  /// In en, this message translates to:
  /// **'This app wants you to sign a transaction. Review carefully before approving.'**
  String get signTransactionDesc;

  /// No description provided for @signAllTransactionsDesc.
  ///
  /// In en, this message translates to:
  /// **'This app wants you to sign {count} transactions at once.'**
  String signAllTransactionsDesc(int count);

  /// No description provided for @signMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'This app wants you to sign a message for verification.'**
  String get signMessageDesc;

  /// No description provided for @dappRequestUnknown.
  ///
  /// In en, this message translates to:
  /// **'This app is requesting wallet access.'**
  String get dappRequestUnknown;

  /// No description provided for @wrapXrs.
  ///
  /// In en, this message translates to:
  /// **'Wrap XRS'**
  String get wrapXrs;

  /// No description provided for @unwrapXrs.
  ///
  /// In en, this message translates to:
  /// **'Unwrap XRS'**
  String get unwrapXrs;

  /// No description provided for @swapLabel.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swapLabel;

  /// No description provided for @interactLabel.
  ///
  /// In en, this message translates to:
  /// **'Interact'**
  String get interactLabel;

  /// No description provided for @noActiveLimitOrders.
  ///
  /// In en, this message translates to:
  /// **'No active limit orders'**
  String get noActiveLimitOrders;

  /// No description provided for @sellingLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get sellingLabel;

  /// No description provided for @buyingMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Buying (Min)'**
  String get buyingMinLabel;

  /// No description provided for @targetPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Price'**
  String get targetPriceLabel;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdLabel;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this limit order? Funds will be returned to your wallet.'**
  String get cancelOrderConfirm;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @cancelTxSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Cancellation transaction submitted'**
  String get cancelTxSubmitted;

  /// No description provided for @cancelTxFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit cancellation'**
  String get cancelTxFailed;

  /// No description provided for @noMatchingValidators.
  ///
  /// In en, this message translates to:
  /// **'No matching validators'**
  String get noMatchingValidators;

  /// No description provided for @searchTokenPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search token...'**
  String get searchTokenPlaceholder;

  /// No description provided for @zkpTransferSubmitted.
  ///
  /// In en, this message translates to:
  /// **'ZKP Transfer Submitted!'**
  String get zkpTransferSubmitted;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @networkFee.
  ///
  /// In en, this message translates to:
  /// **'Network Fee'**
  String get networkFee;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get openStatus;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @networkLabel.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkLabel;

  /// No description provided for @testnetLabel.
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get testnetLabel;

  /// No description provided for @mainnetLabel.
  ///
  /// In en, this message translates to:
  /// **'Mainnet'**
  String get mainnetLabel;

  /// No description provided for @mainnetSoon.
  ///
  /// In en, this message translates to:
  /// **'Mainnet is coming soon'**
  String get mainnetSoon;

  /// No description provided for @connectedSitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected Sites'**
  String get connectedSitesTitle;

  /// No description provided for @connectedSitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage dApp permissions'**
  String get connectedSitesSubtitle;

  /// No description provided for @noConnectedSites.
  ///
  /// In en, this message translates to:
  /// **'No Connected Sites'**
  String get noConnectedSites;

  /// No description provided for @noConnectedSitesDesc.
  ///
  /// In en, this message translates to:
  /// **'Sites you connect to via the browser will appear here. You can revoke their access at any time.'**
  String get noConnectedSitesDesc;

  /// No description provided for @connectedSiteRevoked.
  ///
  /// In en, this message translates to:
  /// **'Site access revoked'**
  String get connectedSiteRevoked;

  /// No description provided for @revokeAllSitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke All Sites?'**
  String get revokeAllSitesTitle;

  /// No description provided for @revokeAllSitesDesc.
  ///
  /// In en, this message translates to:
  /// **'This will disconnect all websites from your wallet. They will need to request access again.'**
  String get revokeAllSitesDesc;

  /// No description provided for @revokeAll.
  ///
  /// In en, this message translates to:
  /// **'Revoke All'**
  String get revokeAll;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @allSitesRevoked.
  ///
  /// In en, this message translates to:
  /// **'All site permissions revoked'**
  String get allSitesRevoked;

  /// No description provided for @addressBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBookTitle;

  /// No description provided for @addressBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage saved contacts'**
  String get addressBookSubtitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// No description provided for @themeSolar.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themeSolar;

  /// No description provided for @themeCyberpunk.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get themeCyberpunk;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeNameDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeNameDark;

  /// No description provided for @themeNameLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeNameLight;

  /// No description provided for @themeNameSolar.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themeNameSolar;

  /// No description provided for @themeNameCyberpunk.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get themeNameCyberpunk;

  /// No description provided for @themeNameSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeNameSystem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'af',
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'nl',
        'tl',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'nl':
      return AppLocalizationsNl();
    case 'tl':
      return AppLocalizationsTl();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
