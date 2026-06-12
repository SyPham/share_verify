class LinkedShareholder {
  final String mcd;
  final String fullName;
  final num totalShares;
  final bool isReceiveMcd;

  const LinkedShareholder({
    required this.mcd,
    required this.fullName,
    required this.totalShares,
    this.isReceiveMcd = false,
  });
}
