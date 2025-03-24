abstract final class Routes {
  static const home = '/';
  static const homeName = 'home';
  static const headlinesFeed = '/headlines-feed';
  static const headlinesFeedName = 'headlinesFeed';
  static const search = '/search';
  static const searchName = 'search';
  static const settings = '/settings';
  static const settingsName = 'settings';
  static const articleDetailsName = 'articleDetails'; // For the sub-route

  static String getRouteNameByIndex(int index) {
    switch (index) {
      case 0:
        return headlinesFeedName;
      case 1:
        return settingsName;
      default:
        throw ArgumentError('Invalid index: $index');
    }
  }
}
