class RecipientListItem {
  final int personId;
  final String displayName;
  final String? identityNo;
  final String? identityType;
  final String primaryMcd;
  final num receiveAmount;
  final DateTime receiveTime;
  final bool isProxy;
  final String? proxyPersonName;
  final int linkedMcdCount;

  const RecipientListItem({
    required this.personId,
    required this.displayName,
    this.identityNo,
    this.identityType,
    required this.primaryMcd,
    required this.receiveAmount,
    required this.receiveTime,
    this.isProxy = false,
    this.proxyPersonName,
    this.linkedMcdCount = 1,
  });
}
