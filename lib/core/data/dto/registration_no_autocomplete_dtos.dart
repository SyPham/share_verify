class RegistrationNoAutocompleteItemDto {
  final String registrationNo;
  final String identityType;
  final String mcd;
  final String fullName;

  const RegistrationNoAutocompleteItemDto({
    required this.registrationNo,
    required this.identityType,
    required this.mcd,
    required this.fullName,
  });

  factory RegistrationNoAutocompleteItemDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return RegistrationNoAutocompleteItemDto(
      registrationNo: json['registrationNo'] as String? ?? '',
      identityType: json['identityType'] as String? ?? '',
      mcd: json['mcd'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }
}

class RegistrationNoAutocompletePageDto {
  final List<RegistrationNoAutocompleteItemDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const RegistrationNoAutocompletePageDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;

  factory RegistrationNoAutocompletePageDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return RegistrationNoAutocompletePageDto(
      items: rawItems
          .map(
            (item) => RegistrationNoAutocompleteItemDto.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}

typedef RegistrationNoAutocompleteSearchCallback
    = Future<RegistrationNoAutocompletePageDto> Function(
  String query,
  int page,
);

typedef RegistrationNoAutocompleteSelectedCallback = void Function(
  RegistrationNoAutocompleteItemDto item,
);
