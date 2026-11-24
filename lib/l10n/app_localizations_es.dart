// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get accountSection => 'Cuenta';

  @override
  String get manageWalletsTitle => 'Administrar Carteras';

  @override
  String get manageWalletsSubtitle => 'Añadir, eliminar o cambiar carteras';

  @override
  String get recoveryPhraseTitle => 'Frase de Recuperación';

  @override
  String get recoveryPhraseSubtitle =>
      'Ver tu frase semilla secreta de forma segura';

  @override
  String get generalSection => 'General';

  @override
  String get currencyTitle => 'Moneda';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsSubtitle => 'Recibir alertas de transacciones';

  @override
  String get privacyModeTitle => 'Modo Privacidad';

  @override
  String get privacyModeSubtitle => 'Ocultar saldos en el tablero';

  @override
  String get securitySection => 'Seguridad';

  @override
  String get biometricTitle => 'Autenticación Biométrica';

  @override
  String get biometricSubtitle => 'Requerir Face ID / Huella digital al inicio';

  @override
  String get supportSection => 'Soporte';

  @override
  String get privacyPolicyTitle => 'Política de Privacidad';

  @override
  String get privacyPolicySubtitle => 'Lee nuestra política de privacidad';

  @override
  String get termsOfServiceTitle => 'Términos de Servicio';

  @override
  String get termsOfServiceSubtitle => 'Lee nuestros términos de servicio';

  @override
  String get aboutWalletTitle => 'Acerca de Xeris Wallet';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get addressCopied => 'Dirección copiada al portapapeles';

  @override
  String get loadingAddress => 'Cargando...';

  @override
  String get errorLoadingAddress => 'Error al cargar la dirección';

  @override
  String get sinceLastMonth => 'Desde el mes pasado';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String comingSoon(String itemName) {
    return '¡Detalles de $itemName próximamente!';
  }

  @override
  String get actionSend => 'Enviar';

  @override
  String get actionReceive => 'Recibir';

  @override
  String get actionSwap => 'Intercambiar';

  @override
  String get actionEarn => 'Ganar';

  @override
  String get actionScan => 'Escanear';

  @override
  String get navWallet => 'Cartera';

  @override
  String get navBrowser => 'Navegador';

  @override
  String get navActivity => 'Actividad';

  @override
  String get balanceHistoryTitle => 'Historial de Saldo';

  @override
  String get totalBalanceTitle => 'Saldo Total';

  @override
  String get noHistoryAvailable => 'No hay historial disponible';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get addWalletTitle => 'Añadir Cartera';

  @override
  String get addWalletSubtitle => '¿Cómo te gustaría añadir una cartera?';

  @override
  String get createNewWallet => 'Crear Nueva Cartera';

  @override
  String get createNewWalletDesc =>
      'Generar una nueva frase semilla secreta de 12 palabras';

  @override
  String get importExistingWallet => 'Importar Cartera Existente';

  @override
  String get importExistingWalletDesc =>
      'Restaurar usando una frase semilla secreta';

  @override
  String get myWalletsTitle => 'Mis Carteras';

  @override
  String get noWallets => 'No hay carteras';

  @override
  String get noWalletsDesc =>
      'Aún no tienes carteras. Crea o importa tu primera cartera para empezar.';

  @override
  String get deleteWalletPromptTitle => '¿Eliminar Cartera?';

  @override
  String deleteWalletPromptDesc(Object walletName) {
    return '¿Estás seguro de que quieres eliminar \"$walletName\"? Esta acción no se puede deshacer a menos que tengas guardada tu frase de recuperación.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get unlockWallet => 'Desbloquear Cartera';

  @override
  String get authRequired => 'Autenticación requerida.';

  @override
  String get verifySecretPhraseTitle => 'Verificar Frase Secreta';

  @override
  String get verifyBackup => 'Verifica tu copia de seguridad';

  @override
  String get verifyBackupDesc =>
      'Introduce las siguientes palabras de tu frase secreta para confirmar que las has guardado.';

  @override
  String wordNumber(String number) {
    return 'Palabra #$number';
  }

  @override
  String enterWordNumber(String number) {
    return 'Introduce la palabra #$number';
  }

  @override
  String get verifyComplete => 'Verificar y Completar';

  @override
  String get walletVerified => '¡Cartera verificada y asegurada!';

  @override
  String failedCreateWallet(String error) {
    return 'Error al crear la cartera: $error';
  }

  @override
  String get incorrectWords =>
      'Palabras incorrectas. Por favor, comprueba tu frase e inténtalo de nuevo.';

  @override
  String get importWalletTitle => 'Importar Cartera';

  @override
  String get enterSecretPhrase => 'Introducir Frase Secreta';

  @override
  String get enterRecoveryPhraseDesc =>
      'Introduce tu frase de recuperación de 12 o 24 palabras para restaurar tu cartera.';

  @override
  String get invalidRecoveryPhrase => 'Frase de recuperación inválida';

  @override
  String get walletImportedSuccess => '¡Cartera importada con éxito!';

  @override
  String failedImportWallet(String error) {
    return 'Error al importar la cartera: $error';
  }

  @override
  String get secretRecoveryPhraseTitle => 'Frase de Recuperación Secreta';

  @override
  String get secretPhraseMasterKeyDesc =>
      'Esta frase secreta es la llave maestra de tu cartera. Escríbela y guárdala en un lugar seguro. Nunca la compartas con nadie.';

  @override
  String get copyToClipboard => 'Copiar al Portapapeles';

  @override
  String get secretPhraseCopied => 'Frase secreta copiada al portapapeles';

  @override
  String get savedSecretPhraseBtn => 'He guardado mi frase secreta';

  @override
  String get welcomeTo => 'Bienvenido a\nXeris Wallet';

  @override
  String get secureWalletForChain => 'La cartera segura para la Cadena Xeris.';

  @override
  String get createANewWallet => 'Crear una Nueva Cartera';

  @override
  String get alreadyHaveWallet => 'Ya tengo una cartera';

  @override
  String get sendAssetsTitle => 'Enviar Activos';

  @override
  String get recipientAddress => 'Dirección del Destinatario';

  @override
  String get pasteAddressOrScan => 'Pega la dirección o escanea el QR';

  @override
  String get amount => 'Cantidad';

  @override
  String get max => 'MÁX';

  @override
  String get review => 'Revisar';

  @override
  String balance(String amount, String symbol) {
    return 'Saldo: $amount $symbol';
  }

  @override
  String get errorEnterRecipient =>
      'Por favor, introduce una dirección de destinatario';

  @override
  String get errorInvalidAddress => 'Dirección de la cadena Xeris inválida';

  @override
  String get errorEnterValidAmount =>
      'Por favor, introduce una cantidad válida';

  @override
  String get errorInsufficientBalance => 'Saldo insuficiente';

  @override
  String get receiveAssetsTitle => 'Recibir Activos';

  @override
  String get scanToReceive => 'Escanear para Recibir';

  @override
  String get sendOnlyXerisAssets =>
      'Envía solo activos de la cadena Xeris a esta dirección.';

  @override
  String get shareAddress => 'Compartir Dirección';

  @override
  String get swapTitle => 'Intercambiar';

  @override
  String get from => 'Desde';

  @override
  String get toEstimated => 'A (Estimado)';

  @override
  String get price => 'Precio';

  @override
  String priceEstimate(String fromSymbol, String rate, String toSymbol) {
    return '1 $fromSymbol ≈ $rate $toSymbol';
  }

  @override
  String get slippageTolerance => 'Tolerancia de Deslizamiento';

  @override
  String get swapping => 'Intercambiando...';

  @override
  String get selectToken => 'Seleccionar Token';

  @override
  String get scanQrCodeTitle => 'Escanear Código QR';

  @override
  String get alignQrCode => 'Alinea el código QR dentro del marco';

  @override
  String get earnRewardsTitle => 'Ganar Recompensas';

  @override
  String get noValidatorsFound =>
      'No se encontraron validadores en la red de prueba.\nAún puedes intentar apostar a la red.';

  @override
  String validatorAddress(String address) {
    return 'Validador $address...';
  }

  @override
  String stakeAmount(String amount) {
    return 'Apostar: $amount XRS';
  }

  @override
  String get stake => 'Apostar';

  @override
  String get unstake => 'Retirar Stake';

  @override
  String get directStake => 'Apuesta Directa';

  @override
  String get stakedBalance => 'Saldo en Staking';

  @override
  String totalStaked(String amount) {
    return 'Total en Staking: $amount XRS';
  }

  @override
  String commissionLabel(String value) {
    return 'Comisión: $value%';
  }

  @override
  String get searchValidators => 'Buscar Validadores';

  @override
  String stakeAmountPercentage(Object percent) {
    return '$percent%';
  }

  @override
  String get confirmStakeTitle => 'Confirmar Staking';

  @override
  String confirmStakeDesc(Object amount, Object validator) {
    return 'Estás a punto de hacer staking de $amount XRS en $validator.';
  }

  @override
  String get confirmUnstakeTitle => 'Confirmar Retiro';

  @override
  String confirmUnstakeDesc(Object amount, Object validator) {
    return 'Estás a punto de retirar $amount XRS de $validator.';
  }

  @override
  String get unbondingNotice =>
      'Se aplica un período de desvinculación de 7 días';

  @override
  String get transactionSubmitted => 'Transacción Enviada';

  @override
  String get transactionFailed => 'Transacción Fallida';

  @override
  String get txSubmittedDesc =>
      'Tu transacción ha sido enviada a la red Xeris.';

  @override
  String hashLabel(String hash) {
    return 'Hash: $hash';
  }

  @override
  String get txHashCopied => 'Hash de la transacción copiado al portapapeles';

  @override
  String get viewInExplorer => 'Ver en el Explorador';

  @override
  String get backToDashboard => 'Volver al Panel Principal';

  @override
  String get shareReceipt => 'Compartir Recibo';

  @override
  String get transactionDetails => 'Detalles de la Transacción';

  @override
  String get receiptTitle => 'Recibo de Transacción Xeris';

  @override
  String get dateLabel => 'Fecha';

  @override
  String get statusLabel => 'Estado';

  @override
  String get successStatus => 'Éxito';

  @override
  String get failedStatus => 'Fallido';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String connectToDapp(String dappName) {
    return '¿Conectar a $dappName?';
  }

  @override
  String get reject => 'Rechazar';

  @override
  String get approve => 'Aprobar';

  @override
  String get details => 'DETALLES';

  @override
  String get activityTitle => 'Actividad';

  @override
  String get noActivityYet => 'Aún no hay actividad';

  @override
  String get noActivityDesc =>
      'Tus transacciones aparecerán aquí una vez que envíes o recibas fondos.';

  @override
  String get errorLoadingActivity => 'Error al cargar la actividad';

  @override
  String get activitySearchHint => 'Buscar dirección, hash o token';

  @override
  String get activityFilterAll => 'Todos';

  @override
  String get activityFilterSent => 'Enviados';

  @override
  String get activityFilterReceived => 'Recibidos';

  @override
  String get activityFilterSwap => 'Intercambio';

  @override
  String get activityFilterFailed => 'Fallidos';

  @override
  String get activityNoMatches => 'Sin coincidencias';

  @override
  String get activityNoMatchesDesc => 'Prueba a ajustar tus filtros o búsqueda';

  @override
  String get unknownAddress => 'Desconocido';

  @override
  String receivedAsset(String symbol) {
    return 'Recibido $symbol';
  }

  @override
  String sentAsset(String symbol) {
    return 'Enviado $symbol';
  }

  @override
  String fromAddress(String address) {
    return 'De: $address';
  }

  @override
  String toAddress(String address) {
    return 'Para: $address';
  }

  @override
  String get execContract => 'Ejec';

  @override
  String todayAt(String time) {
    return 'Hoy $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Ayer $time';
  }

  @override
  String get connectingToDapp => 'Conectando a dApp...';

  @override
  String get signMessageTitle => 'Firmar mensaje';

  @override
  String get messageToSign => 'MENSAJE';

  @override
  String get signBtn => 'Firmar';

  @override
  String get searchOrEnterUrl => 'Buscar o ingresar URL';

  @override
  String get renameWalletTitle => 'Renombrar Cartera';

  @override
  String get renameWalletPromptDesc =>
      'Introduce un nuevo nombre para tu cartera.';

  @override
  String get walletNameLabel => 'Nombre de la Cartera';

  @override
  String get save => 'Guardar';

  @override
  String get rename => 'Renombrar';

  @override
  String get marketOrder => 'Mercado';

  @override
  String get limitOrder => 'Límite';

  @override
  String get limitPriceLabel => 'Precio Límite';

  @override
  String get placeLimitOrder => 'Realizar Orden Límite';

  @override
  String get manageCoins => 'Administrar Monedas';

  @override
  String get dAppBrowser => 'Navegador de dApp';

  @override
  String connectedTo(String publicKey) {
    return 'Conectado a: $publicKey';
  }

  @override
  String get selectCurrency => 'Seleccionar Moneda';

  @override
  String get stakeXrs => 'Apostar XRS';

  @override
  String availableXrs(String balance) {
    return 'Disponible: $balance XRS';
  }

  @override
  String get confirmStake => 'Confirmar Apuesta';

  @override
  String addLiquidityWithTokens(String tokenA, String tokenB) {
    return 'Añadir Liquidez: $tokenA/$tokenB';
  }

  @override
  String get confirmDeposit => 'Confirmar Depósito';

  @override
  String get ok => 'OK';

  @override
  String get reviewTransaction => 'Revisar transacción';

  @override
  String get youAreSending => 'Estás enviando';

  @override
  String get confirmAndSend => 'Confirmar y enviar';

  @override
  String get biometricAuthFailed =>
      'La autenticación falló. No se pueden habilitar los datos biométricos.';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String get recoveryPhraseWarning =>
      'Nunca compartas esta frase. Cualquiera que tenga estas palabras puede robar tus activos.';

  @override
  String get noWalletFound => 'No se encontró ninguna billetera.';

  @override
  String get recoveryPhraseCopied =>
      'Frase de recuperación copiada al portapapeles';

  @override
  String versionLabel(String version) {
    return 'Versie $version';
  }

  @override
  String get authFailed => 'Autenticación fallida';

  @override
  String get marketCap => 'Capitalización de mercado';

  @override
  String get totalHolders => 'Titulares totales';

  @override
  String get mintAddress => 'Dirección de emisión';

  @override
  String get totalSupply => 'Suministro total';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get tokenDecimals => 'Decimales';

  @override
  String get tokenStandard => 'Estándar de token';

  @override
  String get noActivityForToken => 'No hay actividad reciente para este token.';

  @override
  String get navAgents => 'Agentes';

  @override
  String get agentsTitle => 'Agentes de IA';

  @override
  String get yourAgents => 'Sus Agentes';

  @override
  String get openTasks => 'Tareas Abiertas';

  @override
  String get registerAgentTitle => 'Registrar Agente';

  @override
  String get registerAgentDesc =>
      'Los agentes operan de forma autónoma con autoridad delegada. Establezca los límites de gasto con cuidado: no pueden exceder estos en la cadena.';

  @override
  String get agentNameLabel => 'NOMBRE DEL AGENTE';

  @override
  String get agentNamePlaceholder => 'ej. Ari-Trader-v1';

  @override
  String get agentPubKeyLabel => 'CLAVE PÚBLICA DEL AGENTE';

  @override
  String get agentPubKeyPlaceholder => 'Clave pública Ed25519 Base58';

  @override
  String get maxPerTxLabel => 'MÁXIMO POR TRANSACCIÓN (XRS)';

  @override
  String get dailyBudgetLabel => 'PRESUPUESTO DIARIO (XRS)';

  @override
  String get allowedContractsLabel => 'CONTRATOS PERMITIDOS';

  @override
  String get allowedContractsPlaceholder =>
      'pool_mtk_xrs, ... (separados por comas)';

  @override
  String get registerAgentBtn => 'Registrar Agente';

  @override
  String get revokeAgentBtn => 'Revocar';

  @override
  String get claimTaskBtn => 'Reclamar';

  @override
  String get lastHeartbeatPrefix => 'Último latido: ';

  @override
  String activeAgentsStatus(int count) {
    return '$count ACTIVO(S)';
  }

  @override
  String get sendPrivately => 'Enviar en Privado';

  @override
  String get sendPrivatelyDesc =>
      'Monto oculto en la cadena mediante prueba ZK';

  @override
  String get zkpInfoBox =>
      'El monto de la transferencia estará oculto en la cadena. Solo usted y el destinatario pueden verificar el valor. Guarde su factor de ceguera para registros fiscales.';

  @override
  String get generateProofAndSend => 'Generar Prueba y Enviar';

  @override
  String get quantumShieldTitle => 'Escudo Cuántico';

  @override
  String get quantumShieldSubtitle => 'Criptografía post-cuántica';

  @override
  String get quantumShieldDesc =>
      'Proteja su billetera con criptografía post-cuántica (ML-DSA-65)';

  @override
  String get quantumProtectionActive => 'Protección Cuántica Activa';

  @override
  String get notProtected => 'No Protegido';

  @override
  String get pqSecurityLevel => 'ML-DSA-65 · Seguridad PQ de 128 bits';

  @override
  String get vulnerableToQuantum => 'Vulnerable a ataques cuánticos';

  @override
  String get statusActive => 'ACTIVO';

  @override
  String get statusOff => 'APAGADO';

  @override
  String get zkProofsUsed => 'Pruebas ZK usadas';

  @override
  String get pqKeysRegistered => 'Claves PQ registradas';

  @override
  String get blockTimeStat => 'Tiempo de bloque';

  @override
  String get quantumProtectedDesc =>
      'Su billetera está protegida cuánticamente. Las transferencias firmadas con ML-DSA-65 muestran una insignia 🛡 en el explorador.';

  @override
  String get enableQuantumProtectionDesc =>
      'Habilitar la protección cuántica genera un par de claves ML-DSA-65 y registra su clave pública en la cadena. Esta es una configuración única.';

  @override
  String get sendWithQuantumSigning => 'Enviar con firma cuántica';

  @override
  String get enableQuantumProtectionBtn => 'Habilitar Protección Cuántica';

  @override
  String get quantumEnabledSuccess => '¡Protección cuántica habilitada!';

  @override
  String failedToEnablePq(String error) {
    return 'Error al habilitar: $error';
  }

  @override
  String get quantumBackupTitle => 'Respaldar Identidad Cuántica';

  @override
  String get quantumBackupWarning =>
      'Tu frase mnemónica de 12 palabras ya no es suficiente para recuperar esta billetera. DEBES respaldar esta Clave Secreta Cuántica.';

  @override
  String get quantumSecretKeyLabel => 'CLAVE SECRETA CUÁNTICA';

  @override
  String get backupConfirmedLabel =>
      'He respaldado de forma segura mi Clave Secreta Cuántica';

  @override
  String get viewRecoveryKey => 'Ver Clave de Recuperación';

  @override
  String get pinCodeTitle => 'Código PIN';

  @override
  String get pinCodeSubtitle => 'Asegure su billetera con un PIN de 6 dígitos';

  @override
  String get changePinCodeTitle => 'Cambiar código PIN';

  @override
  String get changePinCodeSubtitle => 'Actualice su PIN de seguridad';

  @override
  String get pinCodeUpdated => 'Código PIN actualizado con éxito';

  @override
  String get noAgentsRegistered => 'No hay agentes registrados.';

  @override
  String get noOpenTasks => 'No hay tareas abiertas.';

  @override
  String get refresh => 'Refrescar';

  @override
  String get zkpOnlyXrsError =>
      'Las transferencias privadas ZKP solo admiten XRS en este momento.';

  @override
  String get pqcOnlyXrsError =>
      'Las transferencias con firma cuántica actualmente solo admiten XRS.';

  @override
  String get required => 'Requerido';

  @override
  String get enterPinCode => 'Ingrese el código PIN';

  @override
  String get setNewPin => 'Establecer un nuevo PIN';

  @override
  String get confirmPin => 'Confirme su PIN';

  @override
  String get pinSubtitle => 'Proteja sus activos con un PIN de 6 dígitos';

  @override
  String get incorrectPin => 'PIN incorrecto';

  @override
  String get pinsDoNotMatch => 'Los PIN no coinciden. Inténtelo de nuevo.';

  @override
  String get panicPinTitle => 'PIN de Pánico (Autodestrucción)';

  @override
  String get panicPinSubtitle =>
      'Un código que borra todos los datos al ingresarlo';

  @override
  String get setPanicPin => 'Configurar PIN de Pánico';

  @override
  String get confirmPanicPin => 'Confirmar PIN de Pánico';

  @override
  String get panicTriggered =>
      'PIN de Pánico activado. Todos los datos borrados.';

  @override
  String agentMaxPerTx(Object amount) {
    return 'Máx/tx: $amount XRS';
  }

  @override
  String agentDailyLimit(Object amount) {
    return 'Diario: $amount XRS';
  }

  @override
  String get appLockedTitle => 'Cartera Xeris Bloqueada';

  @override
  String get authenticateToContinue => 'Autentíquese para continuar';

  @override
  String get securityAudit => 'AUDITORÍA DE SEGURIDAD';

  @override
  String get biometricLockActive => 'Bloqueo Biométrico Activo';

  @override
  String get pinProtected6Digit => 'Protegido por PIN de 6 Dígitos';

  @override
  String get privacyModeEnabled => 'Modo Privacidad Activado';

  @override
  String get privacyModeDisabled => 'Modo Privacidad Desactivado';

  @override
  String get fullDiskEncryption => 'Cifrado de Disco Completo';

  @override
  String get zkProofAsyncInfo =>
      'Xeris utiliza la generación de pruebas ZK asíncronas para mantener la privacidad sin bloquear la interacción con su cartera.';

  @override
  String get unknownToken => 'Token Desconocido';

  @override
  String get signTransactionTitle => 'Firmar Transacción';

  @override
  String get signAndSendTransactionTitle => 'Firmar y Enviar Transacción';

  @override
  String signAllTransactionsTitle(int count) {
    return 'Firmar $count Transacciones';
  }

  @override
  String get connectToDappDesc =>
      'Esta aplicación quiere conectarse a tu billetera Xeris y ver tu dirección pública.';

  @override
  String get signTransactionDesc =>
      'Esta aplicación quiere que firmes una transacción. Revisa cuidadosamente antes de aprobar.';

  @override
  String signAllTransactionsDesc(int count) {
    return 'Esta aplicación quiere que firmes $count transacciones a la vez.';
  }

  @override
  String get signMessageDesc =>
      'Esta aplicación quiere que firmes un mensaje para verificación.';

  @override
  String get dappRequestUnknown =>
      'Esta aplicación está solicitando acceso a la billetera.';

  @override
  String get wrapXrs => 'Envolver XRS';

  @override
  String get unwrapXrs => 'Desenvolver XRS';

  @override
  String get swapLabel => 'Intercambio';

  @override
  String get interactLabel => 'Interactuar';

  @override
  String get noActiveLimitOrders => 'No hay órdenes límite activas';

  @override
  String get sellingLabel => 'Vendiendo';

  @override
  String get buyingMinLabel => 'Comprando (Mín)';

  @override
  String get targetPriceLabel => 'Precio Objetivo';

  @override
  String get orderIdLabel => 'ID de Orden';

  @override
  String get cancelOrderTitle => 'Cancelar Orden';

  @override
  String get cancelOrderConfirm =>
      '¿Estás seguro de que quieres cancelar esta orden límite? Los fondos serán devueltos a tu cartera.';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Sí, Cancelar';

  @override
  String get cancelTxSubmitted => 'Transacción de cancelación enviada';

  @override
  String get cancelTxFailed => 'Error al enviar la cancelación';

  @override
  String get noMatchingValidators =>
      'No se encontraron validadores coincidentes';

  @override
  String get searchTokenPlaceholder => 'Buscar token...';

  @override
  String get zkpTransferSubmitted => '¡Transferencia ZKP Enviada!';

  @override
  String get paste => 'Pegar';

  @override
  String get myWallet => 'Mi Cartera';

  @override
  String get networkFee => 'Tarifa de Red';

  @override
  String get openStatus => 'ABIERTA';

  @override
  String get toLabel => 'Para';

  @override
  String get networkLabel => 'Red';

  @override
  String get testnetLabel => 'Red de Prueba';

  @override
  String get mainnetLabel => 'Red Principal';

  @override
  String get mainnetSoon => 'La red principal llegará pronto';

  @override
  String get connectedSitesTitle => 'Sitios Conectados';

  @override
  String get connectedSitesSubtitle => 'Gestionar permisos de dApps';

  @override
  String get noConnectedSites => 'Sin Sitios Conectados';

  @override
  String get noConnectedSitesDesc =>
      'Los sitios a los que te conectes a través del navegador aparecerán aquí. Puedes revocar su acceso en cualquier momento.';

  @override
  String get connectedSiteRevoked => 'Acceso al sitio revocado';

  @override
  String get revokeAllSitesTitle => '¿Revocar todos los sitios?';

  @override
  String get revokeAllSitesDesc =>
      'Esto desconectará todos los sitios web de tu billetera. Tendrán que solicitar acceso nuevamente.';

  @override
  String get revokeAll => 'Revocar Todos';

  @override
  String get revoke => 'Revocar';

  @override
  String get allSitesRevoked => 'Todos los permisos de sitios revocados';

  @override
  String get addressBookTitle => 'Libreta de Direcciones';

  @override
  String get addressBookSubtitle => 'Gestionar contactos guardados';

  @override
  String get themeTitle => 'Tema';

  @override
  String get selectTheme => 'Seleccionar Tema';

  @override
  String get themeDark => 'Modo Oscuro';

  @override
  String get themeLight => 'Modo Claro';

  @override
  String get themeSolar => 'Amber';

  @override
  String get themeCyberpunk => 'Violet';

  @override
  String get themeSystem => 'Predeterminado del Sistema';

  @override
  String get themeNameDark => 'Oscuro';

  @override
  String get themeNameLight => 'Claro';

  @override
  String get themeNameSolar => 'Amber';

  @override
  String get themeNameCyberpunk => 'Violet';

  @override
  String get themeNameSystem => 'Sistema';
}
