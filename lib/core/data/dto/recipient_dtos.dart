class RecipientListItemDto {
  final int personId;
  final String displayName;
  final String? identityNo;
  final String? identityType;
  final String primaryMcd;
  final num receiveAmount;
  final DateTime receiveTime;
  final String attendanceType;
  final String? proxyPersonName;
  final int linkedMcdCount;

  const RecipientListItemDto({
    required this.personId,
    required this.displayName,
    this.identityNo,
    this.identityType,
    required this.primaryMcd,
    required this.receiveAmount,
    required this.receiveTime,
    this.attendanceType = 'Direct',
    this.proxyPersonName,
    this.linkedMcdCount = 1,
  });

  factory RecipientListItemDto.fromJson(Map<String, dynamic> json) {
    return RecipientListItemDto(
      personId: _readInt(json['personId']),
      displayName: json['displayName'] as String? ?? '',
      identityNo: json['identityNo'] as String?,
      identityType: json['identityType'] as String?,
      primaryMcd: json['primaryMcd'] as String? ?? '',
      receiveAmount: json['receiveAmount'] as num? ?? 0,
      receiveTime: DateTime.parse(json['receiveTime'] as String),
      attendanceType: json['attendanceType'] as String? ?? 'Direct',
      proxyPersonName: json['proxyPersonName'] as String?,
      linkedMcdCount: _readInt(json['linkedMcdCount']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class LinkedShareholderDto {
  final String mcd;
  final String fullName;
  final num totalShares;
  final bool isReceiveMcd;

  const LinkedShareholderDto({
    required this.mcd,
    required this.fullName,
    required this.totalShares,
    this.isReceiveMcd = false,
  });

  factory LinkedShareholderDto.fromJson(Map<String, dynamic> json) {
    return LinkedShareholderDto(
      mcd: json['mcd'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      totalShares: json['totalShares'] as num? ?? 0,
      isReceiveMcd: json['isReceiveMcd'] as bool? ?? false,
    );
  }
}

class RecipientDetailDto {
  final int personId;
  final String personFullName;
  final Map<String, dynamic> travelSupportJson;
  final List<LinkedShareholderDto> linkedShareholders;

  const RecipientDetailDto({
    required this.personId,
    required this.personFullName,
    required this.travelSupportJson,
    required this.linkedShareholders,
  });

  factory RecipientDetailDto.fromJson(Map<String, dynamic> json) {
    final rawLinked = json['linkedShareholders'] as List<dynamic>? ?? [];
    return RecipientDetailDto(
      personId: RecipientListItemDto._readInt(json['personId']),
      personFullName: json['personFullName'] as String? ?? '',
      travelSupportJson:
          json['travelSupport'] as Map<String, dynamic>? ?? const {},
      linkedShareholders: rawLinked
          .map(
            (item) =>
                LinkedShareholderDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class RecipientSearchPageDto {
  final List<RecipientListItemDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const RecipientSearchPageDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;

  factory RecipientSearchPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return RecipientSearchPageDto(
      items: rawItems
          .map(
            (item) =>
                RecipientListItemDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalCount: RecipientListItemDto._readInt(json['totalCount']),
      page: RecipientListItemDto._readInt(json['page']),
      pageSize: RecipientListItemDto._readInt(json['pageSize']),
    );
  }
}
