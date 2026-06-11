class TravelSupportInfo {
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

  const TravelSupportInfo({
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

  bool get isProxy => attendanceType.toLowerCase() == 'proxy';
}
