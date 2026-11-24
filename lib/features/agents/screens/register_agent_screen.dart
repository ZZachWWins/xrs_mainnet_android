import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/services/xeris_api_service.dart';
import 'package:xeris_wallet/core/services/auth_service.dart';
import 'package:xeris_wallet/core/models/agent_models.dart';
import 'package:xeris_wallet/core/services/agent_key_service.dart';
import 'package:xeris_wallet/core/utils/amount_utils.dart';

class RegisterAgentScreen extends ConsumerStatefulWidget {
  const RegisterAgentScreen({super.key});

  @override
  ConsumerState<RegisterAgentScreen> createState() => _RegisterAgentScreenState();
}

class _RegisterAgentScreenState extends ConsumerState<RegisterAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pubkeyController = TextEditingController();
  final _maxPerTxController = TextEditingController();
  final _dailyBudgetController = TextEditingController();
  final _contractsController = TextEditingController();
  bool _isLoading = false;
  bool _keyGenerated = false;
  AgentTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    // Default to Custom
    _selectedTemplate = AgentTemplate.available.last;
  }

  void _applyTemplate(AgentTemplate template) {
    setState(() {
      _selectedTemplate = template;
      if (template.id != 'custom') {
        _nameController.text = template.name;
        _maxPerTxController.text = template.defaultMaxPerTx.toString();
        _dailyBudgetController.text = template.defaultDailyBudget.toString();
        _contractsController.text = template.allowedContracts.join(', ');
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pubkeyController.dispose();
    _maxPerTxController.dispose();
    _dailyBudgetController.dispose();
    _contractsController.dispose();
    super.dispose();
  }

  Future<void> _generateAgentKey() async {
    try {
      final walletId = await StorageService.getActiveWalletId();
      if (walletId == null) throw Exception('No wallet found');

      final keyPair = await AgentKeyService.generateAndSave(walletId);
      setState(() {
        _pubkeyController.text = keyPair.address;
        _keyGenerated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Key generation failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authenticated = await AuthService.authenticate(context);
    if (!authenticated) return;
    
    setState(() => _isLoading = true);
    
    try {
      final mnemonic = await StorageService.getMnemonic();
      if (mnemonic == null) throw Exception('No wallet found');

      final keyPair = await WalletService.getKeyPair(mnemonic);

      final ixData = XerisApiService.buildRegisterAgent(
        agentName: _nameController.text,
        agentPubkey: _pubkeyController.text,
        maxPerTxLamports: ((parseAmount(_maxPerTxController.text) ?? 5.0) * 1e9).round(),
        maxDailyLamports: ((parseAmount(_dailyBudgetController.text) ?? 10.0) * 1e9).round(),
        allowedContracts: _contractsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );

      final txHash = await XerisApiService.submitXerisInstruction(
        keyPair: keyPair,
        instructionData: ixData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Agent registered: $txHash')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(l10n.registerAgentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textBody),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology, color: AppColors.brandBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.registerAgentDesc,
                        style: TextStyle(color: AppColors.brandLight.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildLabel('CHOOSE A TEMPLATE'),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AgentTemplate.available.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final template = AgentTemplate.available[index];
                    final isSelected = _selectedTemplate?.id == template.id;
                    return GestureDetector(
                      onTap: () => _applyTemplate(template),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandBlue.withValues(alpha: 0.1) : AppColors.brandMidnight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.brandVibrant : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(template.icon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 8),
                            Text(
                              template.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? AppColors.brandLight : AppColors.textBody,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedTemplate != null && _selectedTemplate!.id != 'custom') ...[
                const SizedBox(height: 12),
                Text(
                  _selectedTemplate!.description,
                  style: TextStyle(color: AppColors.textBody.withValues(alpha: 0.6), fontSize: 11, height: 1.4),
                ),
              ],
              
              const SizedBox(height: 32),
              Divider(color: Colors.white.withValues(alpha: 0.05)),
              const SizedBox(height: 32),
              
              _buildLabel(l10n.agentNameLabel),
              _buildTextField(
                controller: _nameController,
                hintText: l10n.agentNamePlaceholder,
                validator: (val) => val == null || val.isEmpty ? l10n.required : null,
              ),
              
              _buildLabel(l10n.agentPubKeyLabel),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pubkeyController,
                      hintText: l10n.agentPubKeyPlaceholder,
                      validator: (val) => val == null || val.isEmpty ? l10n.required : null,
                      readOnly: _keyGenerated,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: Icon(_keyGenerated ? Icons.check : Icons.vpn_key, size: 18),
                        label: Text(_keyGenerated ? 'Done' : 'Generate'),
                        onPressed: _keyGenerated ? null : _generateAgentKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _keyGenerated ? Colors.green.withValues(alpha: 0.2) : AppColors.brandBlue.withValues(alpha: 0.3),
                          foregroundColor: _keyGenerated ? Colors.greenAccent : AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: _keyGenerated ? Colors.green.withValues(alpha: 0.5) : AppColors.brandBlue.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              _buildLabel(l10n.maxPerTxLabel),
              _buildTextField(
                controller: _maxPerTxController,
                hintText: '5.0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.isEmpty ? l10n.required : null,
              ),
              
              _buildLabel(l10n.dailyBudgetLabel),
              _buildTextField(
                controller: _dailyBudgetController,
                hintText: '10.0',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.isEmpty ? l10n.required : null,
              ),
              
              _buildLabel(l10n.allowedContractsLabel),
              _buildTextField(
                controller: _contractsController,
                hintText: l10n.allowedContractsPlaceholder,
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: AppColors.brandLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandLight))
                      : Text(l10n.registerAgentBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textBody,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        style: TextStyle(color: readOnly ? AppColors.brandLight.withValues(alpha: 0.6) : AppColors.brandLight),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.textBody.withValues(alpha: 0.5)),
          filled: true,
          fillColor: AppColors.brandMidnight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.brandVibrant.withValues(alpha: 0.5)),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
