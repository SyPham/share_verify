enum CropAspectMode {
  free,
  square,
  landscape,
  portrait;

  double? get aspectRatio => switch (this) {
        CropAspectMode.free => null,
        CropAspectMode.square => 1,
        CropAspectMode.landscape => 4 / 3,
        CropAspectMode.portrait => 3 / 4,
      };

  String get label => switch (this) {
        CropAspectMode.free => 'Tự do',
        CropAspectMode.square => 'Vuông',
        CropAspectMode.landscape => 'Ngang',
        CropAspectMode.portrait => 'Dọc',
      };
}
