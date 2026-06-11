class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? traceId;

  const ApiException({
    required this.message,
    this.statusCode,
    this.traceId,
  });

  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isBadRequest => statusCode == 400;

  factory ApiException.fromResponse({
    required int statusCode,
    required dynamic data,
  }) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return ApiException(
          statusCode: statusCode,
          message: message,
          traceId: data['traceId'] as String?,
        );
      }

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final messages = errors.map((e) => e.toString()).toList();
        return ApiException(
          statusCode: statusCode,
          message: messages.join('\n'),
          traceId: data['traceId'] as String?,
        );
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: 'Request failed with status $statusCode',
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
