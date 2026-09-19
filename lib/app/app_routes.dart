abstract final class AppRoutes {
  static const home = '/home';
  static const learning = '/learning';
  static const culture = '/culture';
  static const profile = '/profile';
  static const history = '/history';

  static const characterPattern = '/character/:value';
  static const indexPattern = '/index/:type';
  static const cultureDetailPattern = '/culture/:id';
  static const poetryDetailPattern = '/poetry/:id';
  static const settingsPattern = '/settings/:kind';
  static const informationPattern = '/info/:kind';

  static const learningToday = '/learning/today';
  static const learningFavorites = '/learning/favorites';
  static const learningGuess = '/learning/guess';
  static const learningSentence = '/learning/sentence';
  static const learningPolyphonic = '/learning/polyphonic';

  static const settingsGeneral = '/settings/general';
  static const settingsSkin = '/settings/skin';
  static const settingsDaily = '/settings/daily';
  static const settingsData = '/settings/data';

  static const informationAbout = '/info/about';
  static const informationHelp = '/info/help';
  static const informationFeedback = '/info/feedback';
  static const informationPrivacy = '/info/privacy';

  static String character(String value) =>
      '/character/${Uri.encodeComponent(value)}';
  static String index(String type) => '/index/${Uri.encodeComponent(type)}';
  static String cultureDetail(String id) =>
      '/culture/${Uri.encodeComponent(id)}';
  static String poetryDetail(String id) => '/poetry/${Uri.encodeComponent(id)}';
}
