import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/core/app_theme.dart';
import 'package:mklat/data/models/news_item.dart';

void main() {
  group('AppTheme', () {
    test('colorForNewsSource uses supported news source enum values', () {
      expect(
        AppTheme.colorForNewsSource(NewsSource.ynet),
        const Color(0xFFE53935),
      );
      expect(
        AppTheme.colorForNewsSource(NewsSource.maariv),
        const Color(0xFF1565C0),
      );
      expect(
        AppTheme.colorForNewsSource(NewsSource.haaretz),
        const Color(0xFF2E7D32),
      );
    });
  });
}
