import 'package:url_launcher/url_launcher.dart';

abstract class UrlOpener {
  Future<void> openExternal(Uri uri);
}

class UrlLauncherOpener implements UrlOpener {
  const UrlLauncherOpener();

  @override
  Future<void> openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
