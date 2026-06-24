class NameAutocompleteItemDto {
  final String name;
  final String type;
  final String? mcd;
  final num? totalShares;

  const NameAutocompleteItemDto({
    required this.name,
    required this.type,
    this.mcd,
    this.totalShares,
  });

  bool get hasShareholderMeta =>
      mcd != null && mcd!.isNotEmpty && totalShares != null;

  factory NameAutocompleteItemDto.fromJson(Map<String, dynamic> json) {
    return NameAutocompleteItemDto(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'full_name',
      mcd: json['mcd'] as String?,
      totalShares: json['totalShares'] as num?,
    );
  }
}

class NameAutocompletePageDto {
  final List<NameAutocompleteItemDto> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const NameAutocompletePageDto({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory NameAutocompletePageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return NameAutocompletePageDto(
      items: rawItems
          .map(
            (item) =>
                NameAutocompleteItemDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

typedef NameAutocompleteSearchCallback = Future<NameAutocompletePageDto> Function(
  String query,
  int page,
);
