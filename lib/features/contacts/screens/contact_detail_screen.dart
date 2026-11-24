import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/contact.dart';
import 'package:xeris_wallet/core/providers/contacts_provider.dart';
import 'package:xeris_wallet/core/services/notification_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/features/contacts/screens/add_edit_contact_screen.dart';

class ContactDetailScreen extends ConsumerWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = contact.name.trim().isEmpty
        ? '?'
        : contact.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    final hue = (contact.name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final avatarColor = HSLColor.fromAHSL(1.0, hue, 0.5, 0.35).toColor();

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: const Text('Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _openEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                contact.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (contact.note != null && contact.note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  contact.note!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Address card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.brandSpace,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WALLET ADDRESS',
                      style: TextStyle(
                        color: AppColors.brandVibrant.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      contact.address,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _actionChip(
                          icon: Icons.copy_outlined,
                          label: 'Copy',
                          onTap: () => _copyAddress(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Send button
              ElevatedButton.icon(
                onPressed: () => _sendTo(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Send to this Contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brandBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.brandVibrant),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.brandVibrant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: contact.address));
    NotificationService.show(context, 'Address copied');
  }

  void _sendTo(BuildContext context) {
    context.push('/send/input', extra: {'initialAddress': contact.address});
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditContactScreen(existing: contact),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.brandSpace,
        title: const Text('Delete Contact', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${contact.name} from your address book?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(contactsNotifierProvider.notifier).deleteContact(contact.id);
      if (context.mounted) context.pop();
    }
  }
}
