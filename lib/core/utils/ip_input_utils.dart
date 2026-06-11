bool isValidIpv4(String value) {
  final parts = value.trim().split('.');
  if (parts.length != 4) return false;

  for (final part in parts) {
    if (part.isEmpty) return false;
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) return false;
  }

  return true;
}
