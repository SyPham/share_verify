class PhotoUploadResultDto {
  final String photoPath;

  const PhotoUploadResultDto({required this.photoPath});

  factory PhotoUploadResultDto.fromJson(Map<String, dynamic> json) {
    return PhotoUploadResultDto(
      photoPath: json['photoPath'] as String? ?? '',
    );
  }
}
