class ShareholderSearchDto {
  final String mcd;
  final String fullName;
  final String? registrationNo;
  final String? phone;
  final num totalShares;
  final bool travelSupportReceived;
  final DateTime? receiveTime;

  const ShareholderSearchDto({
    required this.mcd,
    required this.fullName,
    this.registrationNo,
    this.phone,
    required this.totalShares,
    required this.travelSupportReceived,
    this.receiveTime,
  });

  factory ShareholderSearchDto.fromJson(Map<String, dynamic> json) {
    return ShareholderSearchDto(
      mcd: json['mcd'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      registrationNo: json['registrationNo'] as String?,
      phone: json['phone'] as String?,
      totalShares: json['totalShares'] as num? ?? 0,
      travelSupportReceived: json['travelSupportReceived'] as bool? ?? false,
      receiveTime: json['receiveTime'] != null
          ? DateTime.tryParse(json['receiveTime'] as String)
          : null,
    );
  }
}

class PagedResultDto<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PagedResultDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;
}

class ShareholderSearchPageDto {
  final List<ShareholderSearchDto> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const ShareholderSearchPageDto({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;

  factory ShareholderSearchPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ShareholderSearchPageDto(
      items: rawItems
          .map(
            (item) =>
                ShareholderSearchDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}

class TravelSupportInfoDto {
  final String? receiverName;
  final String? receiverIdentityNo;
  final String? identityType;
  final String attendanceType;
  final String? proxyPersonName;
  final String? proxyIdentityNo;
  final String? proxyIdentityType;
  final num receiveAmount;
  final DateTime receiveTime;
  final String? photoPath;
  final String? operatorName;

  const TravelSupportInfoDto({
    this.receiverName,
    this.receiverIdentityNo,
    this.identityType,
    this.attendanceType = 'Direct',
    this.proxyPersonName,
    this.proxyIdentityNo,
    this.proxyIdentityType,
    required this.receiveAmount,
    required this.receiveTime,
    this.photoPath,
    this.operatorName,
  });

  factory TravelSupportInfoDto.fromJson(Map<String, dynamic> json) {
    final parsed = tryFromJson(json);
    if (parsed == null) {
      throw FormatException('Invalid travelSupport payload');
    }
    return parsed;
  }

  static TravelSupportInfoDto? tryFromJson(Map<String, dynamic> json) {
    final receiveTime = _parseDateTime(json['receiveTime']);
    if (receiveTime == null) return null;

    return TravelSupportInfoDto(
      receiverName: json['receiverName'] as String?,
      receiverIdentityNo: json['receiverIdentityNo'] as String?,
      identityType: json['identityType'] as String?,
      attendanceType: json['attendanceType'] as String? ?? 'Direct',
      proxyPersonName: json['proxyPersonName'] as String?,
      proxyIdentityNo: json['proxyIdentityNo'] as String?,
      proxyIdentityType: json['proxyIdentityType'] as String?,
      receiveAmount: json['receiveAmount'] as num? ?? 0,
      receiveTime: receiveTime,
      photoPath: json['photoPath'] as String?,
      operatorName: json['operatorName'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

class ShareholderDetailDto {
  final String mcd;
  final String fullName;
  final String? registrationNo;
  final num totalShares;
  final int? personId;
  final bool allowanceReceived;
  final TravelSupportInfoDto? travelSupport;

  const ShareholderDetailDto({
    required this.mcd,
    required this.fullName,
    this.registrationNo,
    required this.totalShares,
    this.personId,
    required this.allowanceReceived,
    this.travelSupport,
  });

  factory ShareholderDetailDto.fromJson(Map<String, dynamic> json) {
    final travelSupportJson = json['travelSupport'];
    return ShareholderDetailDto(
      mcd: json['mcd'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      registrationNo: json['registrationNo'] as String?,
      totalShares: json['totalShares'] as num? ?? 0,
      personId: (json['personId'] as num?)?.toInt(),
      allowanceReceived: json['allowanceReceived'] as bool? ?? false,
      travelSupport: travelSupportJson is Map<String, dynamic>
          ? TravelSupportInfoDto.tryFromJson(travelSupportJson)
          : null,
    );
  }
}
