import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';

typedef ShareholderSearchCallback = Future<ShareholderSearchPageDto> Function(
  String keyword,
  int page,
);

class ShareholderPickerField extends StatelessWidget {
  final ShareholderSearchDto? selected;
  final bool isLoading;
  final ShareholderSearchCallback onSearch;
  final ValueChanged<ShareholderSearchDto> onSelected;
  final VoidCallback? onClear;

  const ShareholderPickerField({
    super.key,
    this.selected,
    this.isLoading = false,
    required this.onSearch,
    required this.onSelected,
    this.onClear,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<ShareholderSearchDto>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: SvPalette.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SvSpacing.radiusLg),
        ),
      ),
      builder: (_) => _ShareholderPickerSheet(onSearch: onSearch),
    );

    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selected != null;

    return InkWell(
      onTap: isLoading ? null : () => _openPicker(context),
      borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Chọn cổ đông',
          hintText: 'Tìm theo mã, họ tên, Số ĐKSH, SĐT',
          filled: true,
          fillColor: SvPalette.surface,
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(SvSpacing.sm),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : hasSelection && onClear != null
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                    )
                  : const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            borderSide: const BorderSide(color: SvPalette.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            borderSide: const BorderSide(color: SvPalette.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            borderSide: const BorderSide(color: SvPalette.primary, width: 2),
          ),
        ),
        child: hasSelection
            ? _SelectedShareholderSummary(item: selected!)
            : Text(
                'Nhấn để tìm và chọn cổ đông',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: SvPalette.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _SelectedShareholderSummary extends StatelessWidget {
  final ShareholderSearchDto item;

  const _SelectedShareholderSummary({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.mcd} · ${item.fullName}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: SvPalette.onSurface,
          ),
        ),
        if (item.registrationNo != null && item.registrationNo!.isNotEmpty ||
            item.phone != null && item.phone!.isNotEmpty) ...[
          const SizedBox(height: SvSpacing.xs),
          Text(
            [
              if (item.registrationNo != null && item.registrationNo!.isNotEmpty)
                'ĐKSH: ${item.registrationNo}',
              if (item.phone != null && item.phone!.isNotEmpty)
                'SĐT: ${item.phone}',
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: SvPalette.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ShareholderPickerSheet extends StatefulWidget {
  final ShareholderSearchCallback onSearch;

  const _ShareholderPickerSheet({required this.onSearch});

  @override
  State<_ShareholderPickerSheet> createState() =>
      _ShareholderPickerSheetState();
}

class _ShareholderPickerSheetState extends State<_ShareholderPickerSheet> {
  static const _minQueryLength = 2;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final _items = <ShareholderSearchDto>[];
  var _page = 1;
  var _hasMore = false;
  var _isLoading = false;
  var _isLoadingMore = false;
  String? _errorMessage;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _loadPage(_lastQuery, page: _page + 1, append: true);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = value.trim();
      if (query.length < _minQueryLength) {
        setState(() {
          _items.clear();
          _page = 1;
          _hasMore = false;
          _errorMessage = query.isEmpty
              ? null
              : 'Nhập ít nhất $_minQueryLength ký tự để tìm kiếm';
          _lastQuery = query;
        });
        return;
      }
      _loadPage(query);
    });
  }

  Future<void> _loadPage(
    String query, {
    int page = 1,
    bool append = false,
  }) async {
    if (append) {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await widget.onSearch(query, page);
      if (!mounted) return;

      setState(() {
        _lastQuery = query;
        _page = result.page;
        _hasMore = result.hasMore;
        if (append) {
          _items.addAll(result.items);
        } else {
          _items
            ..clear()
            ..addAll(result.items);
        }
        if (_items.isEmpty) {
          _errorMessage = 'Không tìm thấy cổ đông phù hợp';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!append) _items.clear();
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SvSpacing.sm),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SvPalette.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SvSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tìm cổ đông',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.xs),
                  Text(
                    'Tìm theo mã MCD, họ tên, Số ĐKSH hoặc số điện thoại',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SvPalette.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.sm),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      hintText: 'Nhập từ khóa tìm kiếm...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: SvPalette.surface,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(color: SvPalette.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(color: SvPalette.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(SvSpacing.radiusLg),
                        borderSide: const BorderSide(
                          color: SvPalette.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SvSpacing.md),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: SvPalette.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Nhập ít nhất $_minQueryLength ký tự để bắt đầu tìm kiếm',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: SvPalette.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        SvSpacing.md,
        0,
        SvSpacing.md,
        SvSpacing.md,
      ),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: SvSpacing.xs),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(SvSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[index];
        return Material(
          color: SvPalette.surfaceContainerLow,
          borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
            onTap: () => Navigator.of(context).pop(item),
            child: Padding(
              padding: const EdgeInsets.all(SvSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SvSpacing.xs),
                  Text(
                    'MCD: ${item.mcd}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (item.registrationNo != null &&
                      item.registrationNo!.isNotEmpty)
                    Text(
                      'Số ĐKSH: ${item.registrationNo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SvPalette.onSurfaceVariant,
                      ),
                    ),
                  if (item.phone != null && item.phone!.isNotEmpty)
                    Text(
                      'SĐT: ${item.phone}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: SvPalette.onSurfaceVariant,
                      ),
                    ),
                  if (item.travelSupportReceived)
                    Padding(
                      padding: const EdgeInsets.only(top: SvSpacing.xs),
                      child: Text(
                        'Đã nhận phụ cấp',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: SvPalette.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
