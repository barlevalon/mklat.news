import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';

@GenerateMocks([Connectivity])
import 'connectivity_provider_test.mocks.dart';

void main() {
  group('ConnectivityProvider', () {
    late MockConnectivity mockConnectivity;
    late ConnectivityProvider provider;

    setUp(() {
      mockConnectivity = MockConnectivity();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state: not offline', () {
      provider = ConnectivityProvider(connectivity: mockConnectivity);
      expect(provider.isOffline, isFalse);
    });

    test('initialize: checks current status', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => ConnectivityResult.wifi);
      when(
        mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => Stream<ConnectivityResult>.empty());

      provider = ConnectivityProvider(connectivity: mockConnectivity);
      await provider.initialize();

      expect(provider.isOffline, isFalse);
      verify(mockConnectivity.checkConnectivity()).called(1);
    });

    test('Connectivity change to none: sets offline', () async {
      final controller = StreamController<ConnectivityResult>.broadcast();

      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => ConnectivityResult.wifi);
      when(
        mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      provider = ConnectivityProvider(connectivity: mockConnectivity);
      await provider.initialize();

      expect(provider.isOffline, isFalse);

      // Simulate going offline
      controller.add(ConnectivityResult.none);
      await Future.delayed(Duration.zero);

      expect(provider.isOffline, isTrue);

      await controller.close();
    });

    test('Connectivity change from none: sets online', () async {
      final controller = StreamController<ConnectivityResult>.broadcast();

      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => ConnectivityResult.none);
      when(
        mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      provider = ConnectivityProvider(connectivity: mockConnectivity);
      await provider.initialize();

      expect(provider.isOffline, isTrue);

      // Simulate coming back online
      controller.add(ConnectivityResult.wifi);
      await Future.delayed(Duration.zero);

      expect(provider.isOffline, isFalse);

      await controller.close();
    });

    test('Only notifies on actual change', () async {
      final controller = StreamController<ConnectivityResult>.broadcast();

      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => ConnectivityResult.wifi);
      when(
        mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => controller.stream);

      provider = ConnectivityProvider(connectivity: mockConnectivity);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.initialize();
      final initialNotifyCount = notifyCount;

      // Same status - should not notify
      controller.add(ConnectivityResult.wifi);
      await Future.delayed(Duration.zero);
      expect(notifyCount, initialNotifyCount);

      // Different status - should notify
      controller.add(ConnectivityResult.none);
      await Future.delayed(Duration.zero);
      expect(notifyCount, initialNotifyCount + 1);

      // Same status again - should not notify
      controller.add(ConnectivityResult.none);
      await Future.delayed(Duration.zero);
      expect(notifyCount, initialNotifyCount + 1);

      await controller.close();
    });
  });
}
