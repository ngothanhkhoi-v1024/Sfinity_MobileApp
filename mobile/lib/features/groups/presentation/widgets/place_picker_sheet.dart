import 'package:flutter/material.dart';
import 'package:sfinity/features/places/data/models/place_model.dart';

class PlacePickerSheet extends StatefulWidget {
  const PlacePickerSheet({
    super.key,
    required this.myPlaces,
    required this.publicPlaces,
  });

  final List<PlaceModel> myPlaces;
  final List<PlaceModel> publicPlaces;

  @override
  State<PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<PlacePickerSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PlaceModel> _filterList(List<PlaceModel> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((p) {
      final titleMatch = p.title.toLowerCase().contains(_searchQuery);
      final addressMatch = (p.address ?? '').toLowerCase().contains(_searchQuery);
      final descMatch = p.body.toLowerCase().contains(_searchQuery);
      return titleMatch || addressMatch || descMatch;
    }).toList();
  }

  Widget _buildList(List<PlaceModel> places, ColorScheme cs, ThemeData theme) {
    final filtered = _filterList(places);
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy địa điểm nào',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        final place = filtered[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          color: isDarkTheme(cs) ? const Color(0xFF2C2C2C) : cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place_rounded, color: Colors.green.shade700, size: 24),
            ),
            title: Text(
              place.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              place.address ?? 'Không có địa chỉ cụ thể',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant),
            onTap: () => Navigator.pop(context, place),
          ),
        );
      },
    );
  }

  bool isDarkTheme(ColorScheme cs) => cs.brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Chọn địa điểm chia sẻ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm địa điểm...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : cs.surfaceContainerHigh,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar
          TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            tabs: const [
              Tab(text: 'Địa điểm của tôi'),
              Tab(text: 'Địa điểm công cộng'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(widget.myPlaces, cs, theme),
                _buildList(widget.publicPlaces, cs, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
