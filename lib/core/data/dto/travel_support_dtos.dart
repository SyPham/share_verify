class RecentTravelSupportDto {
  final String mcd;
  final String? receiverName;
  final num receiveAmount;
  final DateTime receiveTime;
  final String? operatorName;

  const RecentTravelSupportDto({
    required this.mcd,
    this.receiverName,
    required this.receiveAmount,
    required this.receiveTime,
    this.operatorName,
  });

  factory RecentTravelSupportDto.fromJson(Map<String, dynamic> json) {
    return RecentTravelSupportDto(
      mcd: json['mcd'] as String? ?? '',
      receiverName: json['receiverName'] as String?,
      receiveAmount: json['receiveAmount'] as num? ?? 0,
      receiveTime: DateTime.parse(json['receiveTime'] as String),
      operatorName: json['operatorName'] as String?,
    );
  }
}


class IdentityCheckUsedShareholderDto {
  final String mcd;
  final String? fullName;
  final int shares;

  const IdentityCheckUsedShareholderDto({
    required this.mcd,
    this.fullName,
    this.shares = 0,
  });

  factory IdentityCheckUsedShareholderDto.fromJson(Map<String, dynamic> json) {
    final sharesRaw = json['shares'] ?? json['totalShares'];
    return IdentityCheckUsedShareholderDto(
      mcd: json['mcd'] as String? ?? '',
      fullName: json['fullName'] as String?,
      shares: sharesRaw is num ? sharesRaw.round() : 0,
    );
  }
}

class IdentityCheckResultDto {
  final bool alreadyUsed;
  final String? usedForMcd;
  final List<String> usedForMcds;
  final List<IdentityCheckUsedShareholderDto> usedForShareholders;
  final String? receiverName;
  final String? usedIdentityType;
  final String? usedIdentityNo;
  final String? usedDateOfBirth;
  final DateTime? receiveTime;
  final String? message;

  const IdentityCheckResultDto({
    required this.alreadyUsed,
    this.usedForMcd,
    this.usedForMcds = const [],
    this.usedForShareholders = const [],
    this.receiverName,
    this.usedIdentityType,
    this.usedIdentityNo,
    this.usedDateOfBirth,
    this.receiveTime,
    this.message,
  });

  factory IdentityCheckResultDto.fromJson(Map<String, dynamic> json) {
    final receiveTimeRaw = json['receiveTime'] as String?;
    final usedForMcd = json['usedForMcd'] as String?;
    final rawMcds = json['usedForMcds'] as List<dynamic>?;
    final usedForMcds = rawMcds != null
        ? rawMcds.map((e) => e as String).toList()
        : (usedForMcd != null ? [usedForMcd] : <String>[]);
    final rawShareholders = json['usedForShareholders'] as List<dynamic>?;
    final usedForShareholders = rawShareholders != null
        ? rawShareholders
            .map((e) => IdentityCheckUsedShareholderDto.fromJson(
                  e as Map<String, dynamic>,
                ))
            .toList()
        : <IdentityCheckUsedShareholderDto>[];

    return IdentityCheckResultDto(
      alreadyUsed: json['alreadyUsed'] as bool? ?? false,
      usedForMcd: usedForMcd,
      usedForMcds: usedForMcds,
      usedForShareholders: usedForShareholders,
      receiverName: json['receiverName'] as String?,
      usedIdentityType: json['usedIdentityType'] as String?,
      usedIdentityNo: json['usedIdentityNo'] as String?,
      usedDateOfBirth: json['usedDateOfBirth'] as String?,
      receiveTime:
          receiveTimeRaw == null ? null : DateTime.parse(receiveTimeRaw),
      message: json['message'] as String?,
    );
  }

  static List<IdentityCheckUsedShareholderDto> mergeUsedShareholders(
    IdentityCheckResultDto primary,
    IdentityCheckResultDto legacy,
  ) {
    final map = <String, IdentityCheckUsedShareholderDto>{};
    for (final item in [
      ...primary.usedForShareholders,
      ...legacy.usedForShareholders,
    ]) {
      if (item.mcd.isEmpty) continue;
      map.putIfAbsent(item.mcd.toUpperCase(), () => item);
    }
    return map.values.toList();
  }
}

class ReceiveTravelSupportRequest {
  final String mcd;
  final String? receiverName;
  final String? receiverIdentityNo;
  final String? identityType;
  final String? attendanceType;
  final String? proxyPersonName;
  final String? proxyIdentityNo;
  final String? proxyIdentityType;
  final String? receiverDateOfBirth;
  final String? receiverLegacyIdentityNo;
  final String? proxyDateOfBirth;
  final num receiveAmount;
  final String? operatorName;
  final String? deviceId;
  final String? photoPath;

  const ReceiveTravelSupportRequest({
    required this.mcd,
    this.receiverName,
    this.receiverIdentityNo,
    this.identityType,
    this.attendanceType,
    this.proxyPersonName,
    this.proxyIdentityNo,
    this.proxyIdentityType,
    this.receiverDateOfBirth,
    this.receiverLegacyIdentityNo,
    this.proxyDateOfBirth,
    required this.receiveAmount,
    this.operatorName,
    this.deviceId,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
        'mcd': mcd,
        if (receiverName != null) 'receiverName': receiverName,
        if (receiverIdentityNo != null)
          'receiverIdentityNo': receiverIdentityNo,
        if (identityType != null) 'identityType': identityType,
        if (attendanceType != null) 'attendanceType': attendanceType,
        if (proxyPersonName != null) 'proxyPersonName': proxyPersonName,
        if (proxyIdentityNo != null) 'proxyIdentityNo': proxyIdentityNo,
        if (proxyIdentityType != null) 'proxyIdentityType': proxyIdentityType,
        if (receiverDateOfBirth != null)
          'receiverDateOfBirth': receiverDateOfBirth,
        if (receiverLegacyIdentityNo != null)
          'receiverLegacyIdentityNo': receiverLegacyIdentityNo,
        if (proxyDateOfBirth != null) 'proxyDateOfBirth': proxyDateOfBirth,
        'receiveAmount': receiveAmount,
        if (operatorName != null) 'operatorName': operatorName,
        if (deviceId != null) 'deviceId': deviceId,
        if (photoPath != null) 'photoPath': photoPath,
      };
}
