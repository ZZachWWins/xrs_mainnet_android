import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeris_wallet/core/models/contact.dart';
import 'package:xeris_wallet/core/models/wallet_meta.dart';
import 'package:xeris_wallet/core/providers/contacts_provider.dart';
import 'package:xeris_wallet/core/providers/wallet_provider.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';

class ContactListScreen extends ConsumerStatefulWidget {
  /// When true, tapping a contact returns its address via [context.pop] instead
  /// of navigating to the detail screen. Used as an inline picker from SendInput.
  final bool pickerMode;

  const ContactListScreen({super.key, this.pickerMode = false});

  @override
  ConsumerState<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends ConsumerState<ContactListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        title: Text(widget.pickerMode ? 'Select Recipient' : 'Address Book'),
        actions: [
          if (!widget.pickerMode)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add contact',
              onPressed: () => context.push('/contacts/add'),
            ),
        ],
      ),
      floatingActionButton: widget.pickerMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/contacts/add'),
              backgroundColor: AppColors.brandBlue,
              child: const Icon(Icons.person_add_alt_1, color: Colors.white),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: contactsAsync.when(
                data: (contacts) => _buildScrollView(contacts),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandVibrant)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => setState(() => _query = val.toLowerCase()),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.brandSpace,
          hintText: 'Search by name or address...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4)),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.4)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildScrollView(List<Contact> contacts) {
    final walletListAsync = ref.watch(walletListProvider);
    final activeWalletAsync = ref.watch(activeWalletProvider);

    final allWallets = walletListAsync.value ?? [];
    final activeId = activeWalletAsync.value?.id;

    // Other wallets = all wallets except the currently active one
    final otherWallets = allWallets.where((w) => w.id != activeId).toList();

    final filteredWallets = _query.isEmpty
        ? otherWallets
        : otherWallets.where((w) =>
            w.name.toLowerCase().contains(_query) ||
            w.address.toLowerCase().contains(_query)).toList();

    final filteredContacts = _query.isEmpty
        ? contacts
        : contacts.where((c) =>
            c.name.toLowerCase().contains(_query) ||
            c.address.toLowerCase().contains(_query)).toList();

    filteredContacts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final hasWallets = widget.pickerMode && filteredWallets.isNotEmpty;
    final hasContacts = filteredContacts.isNotEmpty;

    // Nothing found at all
    if (_query.isNotEmpty && !hasWallets && !hasContacts) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    // Empty address book (no wallets section either)
    if (!widget.pickerMode && contacts.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        // My Wallets section — picker mode only
        if (widget.pickerMode && otherWallets.isNotEmpty) ...[
          _buildSectionHeader('My Wallets'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final wallet = filteredWallets[index];
                  return Column(
                    children: [
                      _buildWalletTile(wallet),
                      if (index < filteredWallets.length - 1)
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    ],
                  );
                },
                childCount: filteredWallets.length,
              ),
            ),
          ),
        ],

        // Contacts section
        if (hasContacts || (!widget.pickerMode && contacts.isNotEmpty)) ...[
          _buildSectionHeader('Contacts'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final contact = filteredContacts[index];
                  return Column(
                    children: [
                      _buildContactTile(contact),
                      if (index < filteredContacts.length - 1)
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    ],
                  );
                },
                childCount: filteredContacts.length,
              ),
            ),
          ),
        ],

        // Contacts empty state (but wallets may still be shown above)
        if (!hasContacts && contacts.isEmpty && widget.pickerMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildContactsEmptyHint(),
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppColors.brandVibrant.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildWalletTile(WalletMeta wallet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.pop(wallet.address),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // Wallet icon avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.brandVibrant, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _truncateAddress(wallet.address),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    return Dismissible(
      key: ValueKey(contact.id),
      direction: widget.pickerMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(contact),
      onDismissed: (_) {
        ref.read(contactsNotifierProvider.notifier).deleteContact(contact.id);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (widget.pickerMode) {
              context.pop(contact.address);
            } else {
              context.push('/contacts/detail', extra: contact);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                _buildAvatar(contact.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _truncateAddress(contact.address),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (contact.note != null && contact.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          contact.note!,
                          style: TextStyle(
                            color: AppColors.brandVibrant.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    final hue = (name.codeUnits.fold(0, (a, b) => a + b) % 360).toDouble();
    final color = HSLColor.fromAHSL(1.0, hue, 0.5, 0.35).toColor();

    return CircleAvatar(
      radius: 22,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_outlined, size: 64, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text(
              'No contacts yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save frequently used addresses\nto send quickly next time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/contacts/add'),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsEmptyHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSpace,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.contacts_outlined, color: Colors.white.withValues(alpha: 0.3), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No saved contacts yet. Add one from the Address Book in Settings.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(Contact contact) {
    return showDialog<bool>(
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
  }
}
