import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_verify/core/commons/app_spacing.dart';
import 'package:share_verify/core/commons/palette.dart';
import 'package:share_verify/core/data/dto/name_autocomplete_dtos.dart';

class NameAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool enabled;
  final NameAutocompleteSearchCallback onSearch;
  final VoidCallback? onChanged;
  final TextStyle? style;

  const NameAutocompleteField({
    super.key,
    required this.controller,
    required this.decoration,
    required this.onSearch,
    this.enabled = true,
    this.onChanged,
    this.style,
  });

  @override
  State<NameAutocompleteField> createState() => _NameAutocompleteFieldState();
}

class _NameAutocompleteFieldState extends State<NameAutocompleteField> {
  static const _minQueryLength = 2;
  static const _maxSuggestionsHeight = 220.0;

  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  Timer? _debounce;

  final _items = <NameAutocompleteItemDto>[];
  var _page = 1;
  var _hasMore = false;
  var _isLoading = false;
  var _isLoadingMore = false;
  var _showSuggestions = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() => _showSuggestions = false);
      return;
    }
    _scheduleSearch(widget.controller.text);
  }

  void _onControllerChanged() {
    if (!_focusNode.hasFocus || !widget.enabled) return;
    _scheduleSearch(widget.controller.text);
  }

  void _onScroll() {
    if (!_showSuggestions || !_hasMore || _isLoading || _isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 48) {
      _loadPage(_lastQuery, page: _page + 1, append: true);
    }
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = value.trim();
      if (query.length < _minQueryLength) {
        if (!mounted) return;
        setState(() {
          _items.clear();
          _page = 1;
          _hasMore = false;
          _showSuggestions = query.isNotEmpty;
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
    if (!widget.enabled) return;

    if (append) {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final result = await widget.onSearch(query, page);
      if (!mounted) return;
      if (widget.controller.text.trim() != query && !append) return;

      setState(() {
        _lastQuery = query;
        _page = result.page;
        _hasMore = result.hasMore;
        _showSuggestions = true;
        if (append) {
          _items.addAll(result.items);
        } else {
          _items
            ..clear()
            ..addAll(result.items);
        }
      });
    } catch (_) {
      if (!mounted) return;
      if (!append) {
        setState(() {
          _items.clear();
          _showSuggestions = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _selectItem(NameAutocompleteItemDto item) {
    widget.controller.text = item.name;
    widget.controller.selection = TextSelection.collapsed(
      offset: item.name.length,
    );
    widget.onChanged?.call();
    setState(() {
      _showSuggestions = false;
      _items.clear();
    });
    _focusNode.unfocus();
  }

  void _clearField() {
    widget.controller.clear();
    widget.onChanged?.call();
    setState(() {
      _items.clear();
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.controller.text.isNotEmpty;
    final decoration = widget.decoration.copyWith(
      suffixIcon: widget.enabled && hasText
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(SvSpacing.sm),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: _clearField,
                ),
              ],
            )
          : _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(SvSpacing.sm),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.decoration.suffixIcon,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => widget.onChanged?.call(),
          style: widget.style,
          decoration: decoration,
        ),
        if (_showSuggestions && _focusNode.hasFocus) ...[
          const SizedBox(height: SvSpacing.xs),
          _SuggestionsPanel(
            items: _items,
            isLoading: _isLoading && _items.isEmpty,
            isLoadingMore: _isLoadingMore,
            scrollController: _scrollController,
            minQueryLength: _minQueryLength,
            query: _lastQuery,
            onSelected: _selectItem,
          ),
        ],
      ],
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  final List<NameAutocompleteItemDto> items;
  final bool isLoading;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final int minQueryLength;
  final String query;
  final ValueChanged<NameAutocompleteItemDto> onSelected;

  const _SuggestionsPanel({
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.scrollController,
    required this.minQueryLength,
    required this.query,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 2,
      color: SvPalette.surfaceContainerLow,
      borderRadius: BorderRadius.circular(SvSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: _NameAutocompleteFieldState._maxSuggestionsHeight,
        ),
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(SvSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (query.length < minQueryLength) {
      return Padding(
        padding: const EdgeInsets.all(SvSpacing.sm),
        child: Text(
          'Nhập ít nhất $minQueryLength ký tự để gợi ý họ tên',
          style: theme.textTheme.bodySmall?.copyWith(
            color: SvPalette.onSurfaceVariant,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(SvSpacing.sm),
        child: Text(
          'Không tìm thấy họ tên phù hợp',
          style: theme.textTheme.bodySmall?.copyWith(
            color: SvPalette.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: SvSpacing.xs),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(SvSpacing.sm),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final item = items[index];
        final sharesLabel = item.hasShareholderMeta
            ? NumberFormat('#,###').format(item.totalShares)
            : null;
        return ListTile(
          dense: true,
          title: Text(
            item.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: sharesLabel != null
              ? Text(
                  '${item.mcd} · $sharesLabel CP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SvPalette.onSurfaceVariant,
                  ),
                )
              : null,
          onTap: () => onSelected(item),
        );
      },
    );
  }
}
