import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:xeris_wallet/core/models/browser_bookmark.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';
import 'package:xeris_wallet/core/theme/app_theme.dart';
import 'package:xeris_wallet/l10n/app_localizations.dart';

class BrowserHomepage extends StatefulWidget {
  final Function(String) onUrlSelected;

  const BrowserHomepage({super.key, required this.onUrlSelected});

  @override
  State<BrowserHomepage> createState() => _BrowserHomepageState();
}

class _BrowserHomepageState extends State<BrowserHomepage> {
  List<BrowserBookmark> _bookmarks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await StorageService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBookmark(BrowserBookmark bookmark) async {
    if (bookmark.isDefault) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.brandMidnight,
        title: const Text('Delete Bookmark', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${bookmark.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.removeBookmark(bookmark.url);
      _loadBookmarks();
    }
  }

  Future<void> _showAddBookmarkDialog() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.brandMidnight,
        title: const Text('Add Bookmark', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'URL',
                labelStyle: TextStyle(color: Colors.white54),
                hintText: 'https://...',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              var url = urlController.text.trim();
              if (url.isEmpty || titleController.text.isEmpty) return;
              if (!url.startsWith('http')) url = 'https://$url';
              
              final bookmark = BrowserBookmark(
                title: titleController.text,
                url: url,
              );
              await StorageService.saveBookmark(bookmark);
              _loadBookmarks();
              if (mounted && context.mounted) Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppColors.brandVibrant)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    var url = value.trim();
    if (url.isEmpty) return;
    if (!url.contains('.') && !url.startsWith('http')) {
      // Search on Google if not a URL
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
    } else if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    widget.onUrlSelected(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      color: AppColors.brandNavy,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              child: Column(
                children: [
                  // Logo or Title
                  const Text(
                    'Xeris web4 browser',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Explore the decentralized world',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Search Bar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.brandSpace,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandVibrant.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.brandVibrant, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: l10n.searchOrEnterUrl,
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: _onSearch,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bookmarks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.white.withValues(alpha: 0.6)),
                    onPressed: _showAddBookmarkDialog,
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.brandVibrant)),
            )
          else if (_bookmarks.isEmpty)
             SliverFillRemaining(
              child: Center(
                child: Text(
                  'No bookmarks yet',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final bookmark = _bookmarks[index];
                    return _BookmarkItem(
                      bookmark: bookmark,
                      onTap: () => widget.onUrlSelected(bookmark.url),
                      onLongPress: () => _deleteBookmark(bookmark),
                    ).animate(delay: (100 * index).ms).fadeIn().scale();
                  },
                  childCount: _bookmarks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookmarkItem extends StatelessWidget {
  final BrowserBookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BookmarkItem({
    required this.bookmark,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: bookmark.isDefault ? null : onLongPress,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brandSpace,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Center(
              child: bookmark.iconUrl != null
                  ? Image.network(
                      bookmark.iconUrl!,
                      width: 28,
                      height: 28,
                      errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bookmark.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return Text(
      bookmark.title.isNotEmpty ? bookmark.title[0].toUpperCase() : '?',
      style: const TextStyle(
        color: AppColors.brandVibrant,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
