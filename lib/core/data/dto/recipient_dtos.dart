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

class RecipientCheckInDto {
  final String mcd;
  final String shareholderFullName;
  final num totalShares;
  final Map<String, dynamic> travelSupportJson;

  const RecipientCheckInDto({
    required this.mcd,
    required this.shareholderFullName,
    required this.totalShares,
    required this.travelSupportJson,
  });

  factory RecipientCheckInDto.fromJson(Map<String, dynamic> json) {
    return RecipientCheckInDto(
      mcd: json['mcd'] as String? ?? '',
      shareholderFullName: json['shareholderFullName'] as String? ?? '',
      totalShares: json['totalShares'] as num? ?? 0,
      travelSupportJson:
          json['travelSupport'] as Map<String, dynamic>? ?? const {},
    );
  }
}

class RecipientDetailDto {
  final int personId;
  final String personFullName;
  final String? identityNo;
  final String? identityType;
  final List<RecipientCheckInDto> checkIns;

  const RecipientDetailDto({
    required this.personId,
    required this.personFullName,
    this.identityNo,
    this.identityType,
    required this.checkIns,
  });

  factory RecipientDetailDto.fromJson(Map<String, dynamic> json) {
    final rawCheckIns = json['checkIns'] as List<dynamic>? ?? [];
    return RecipientDetailDto(
      personId: RecipientListItemDto._readInt(json['personId']),
      personFullName: json['personFullName'] as String? ?? '',
      identityNo: json['identityNo'] as String?,
      identityType: json['identityType'] as String?,
      checkIns: rawCheckIns
          .map((item) =>
              RecipientCheckInDto.fromJson(item as Map<String, dynamic>))
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
