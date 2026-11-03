class Constants {
  Constants._();

  // Hive Box Constants
  static const String metadataBoxName = "metadata_box";
  static const String playlistBoxName = "playlist_box";
  static const String excludedDirectoriesBoxName = "excluded_directories_box";
  static const String excludedNameFiltersBoxName = "excluded_name_filters_box";

  static const String defaultLanguageLocaleCode = "en";
  static const String androidDefaultMusicFolderPath =
      "/storage/emulated/0/Music";
  static const String defaultNotificationAlbumArtImageUrl =
      "'https://files.radio.co/humorous-skink/staging/default-artwork.png'";

  // Click Wheel Acceleration Constants
  static const double clickWheelAccelerationMinVelocityDegreesPerSecond = 90;
  static const double clickWheelMaxAngularVelocityDegreesPerSecond = 1080;
  static const int clickWheelMaxStepsPerPointerEvent = 8;

  static const double screenHeight = 300;
  static const double deviceClickWheelSmallRadiusRatio = 0.45;
  static const double deviceClickWheelMediumRadiusRatio = 0.61;
  static const double deviceClickWheelLargeRadiusRatio = 0.80;
  static const double deviceSelectButtonSmallRadiusRatio = 0.1500;
  static const double deviceSelectButtonMediumRadiusRatio = 0.2175;
  static const double deviceSelectButtonLargeRadiusRatio = 0.3000;

  static const double inputTextAlphabetContainerWidth = 180;
  static const double inputTextAlphabetSize = 15;

  // Note Reader Font Size Constants (points)
  static const int minNoteFontSize = 11;
  static const int maxNoteFontSize = 20;
  static const int defaultNoteFontSize = 12;
}
