import 'package:flutter/foundation.dart';
import '../../data/models/news_item.dart';

class NewsProvider extends ChangeNotifier {
  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<NewsItem> get newsItems => List.unmodifiable(_newsItems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNews => _newsItems.isNotEmpty;

  /// Called by polling manager with fresh news data.
  void onNewsData(List<NewsItem> items) {
    _newsItems = items;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Called by polling manager on error.
  void onError(String source, Object error) {
    if (_newsItems.isEmpty) {
      _errorMessage = 'שגיאה בטעינת חדשות';
    }
    // If we have existing news, keep showing them (don't show error)
    notifyListeners();
  }
}
