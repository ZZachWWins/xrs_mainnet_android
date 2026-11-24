import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/contact.dart';
import 'package:xeris_wallet/core/providers/contacts_provider.dart';
import 'package:xeris_wallet/core/services/wallet_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';

class AddEditContactScreen extends ConsumerStatefulWidget {
  /// If provided, the screen is in edit mode.
  final Contact? existing;

  const AddEditContactScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends ConsumerState<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _addressController = TextEditingController(text: widget.existing?.address ?? '');
    _noteController = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(contactsNotifierProvider.notifier);

      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
        await notifier.updateContact(updated);
      } else {
        final contact = Contact.create(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        );
        await notifier.addContact(contact);
      }

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name
                  _buildLabel('Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(hint: 'e.g. Alice'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Address
                  _buildLabel('Wallet Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: _inputDecoration(
                      hint: 'Base58 address',
                      suffix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppColors.brandVibrant),
                            tooltip: 'Scan QR',
                            onPressed: _scanQr,
                          ),
                        ],
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Address is required';
                      if (!WalletService.isValidAddress(v.trim())) return 'Invalid wallet address';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Note (optional)
                  _buildLabel('Note (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: _inputDecoration(hint: 'e.g. Work wallet'),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandDeep),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Contact'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.brandSpace,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(color: AppColors.error),
      suffixIcon: suffix,
    );
  }

  Future<void> _scanQr() async {
    final result = await context.push<String>('/scan');
    if (result != null && mounted) {
      _addressController.text = result.trim();
    }
  }
}
