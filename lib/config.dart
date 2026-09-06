/// Shayan Pharma Guide — central config.
///
/// Paste your two deployed Apps Script Web App URLs here. Both come from
/// "Deploy > New deployment > Web app" in the Apps Script editor.
class AppConfig {
  /// URL of the Drive folder-tree script (Code.gs you already deployed).
  static const String folderTreeApiUrl =
      'https://script.google.com/macros/s/AKfycbzSfIfAQqBkAuLqQtbX-Hfb5Y2rPRAQ4Oye6n2CxM74lIFxQ2tI7gInLlV2imjd69PUMA/exec';

  /// URL of the Sheets-based signup/login script (deployed separately).
  static const String authApiUrl = 'https://script.google.com/macros/s/AKfycbyCRJ7jUI-mUZMOplakv6t1Wu78aoKmaVDyKJLRIaqBu2G2yjZpP5NNaxr36pij0ibe/exec';

  static const String appName = 'Shayan Pharma Guide';
}
