import 'package:drag_mini_window/drag_mini_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragMiniWindowController', () {
    late DragMiniWindowController controller;

    setUp(() => controller = DragMiniWindowController());
    tearDown(() => controller.dispose());

    test('initial state is maximized', () {
      expect(controller.isMinimized, false);
      expect(controller.dragProgress, 0.0);
      expect(controller.miniPosition, isNull);
    });

    test('minimize() sets isMinimized and dragProgress', () {
      controller.minimize();
      expect(controller.isMinimized, true);
      expect(controller.dragProgress, 1.0);
    });

    test('maximize() clears isMinimized and dragProgress', () {
      controller.minimize();
      controller.maximize();
      expect(controller.isMinimized, false);
      expect(controller.dragProgress, 0.0);
    });

    test('toggle() switches state', () {
      controller.toggle();
      expect(controller.isMinimized, true);
      controller.toggle();
      expect(controller.isMinimized, false);
    });

    test('setDragProgress clamps to 0..1', () {
      controller.setDragProgress(1.5);
      expect(controller.dragProgress, 1.0);
      controller.setDragProgress(-0.5);
      expect(controller.dragProgress, 0.0);
    });

    test('setDragProgress notifies listeners', () {
      var called = 0;
      controller.addListener(() => called++);
      controller.setDragProgress(0.5);
      expect(called, 1);
    });

    test('setMiniPosition stores position', () {
      const pos = Offset(100, 200);
      controller.setMiniPosition(pos);
      expect(controller.miniPosition, pos);
    });

    test('confirmMinimize sets state and landing position', () {
      const landing = Offset(50, 600);
      controller.confirmMinimize(landingPosition: landing);
      expect(controller.isMinimized, true);
      expect(controller.dragProgress, 1.0);
      expect(controller.miniPosition, landing);
    });
  });

  group('DragMiniWindow widget', () {
    testWidgets('renders expanded content when maximized', (tester) async {
      final controller = DragMiniWindowController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DragMiniWindow(
                  controller: controller,
                  expandedContent: const Text('expanded'),
                  miniContent: const Text('mini'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('expanded'), findsOneWidget);
      expect(find.text('mini'), findsNothing);
    });

    testWidgets('renders mini content when minimized', (tester) async {
      final controller = DragMiniWindowController()..minimize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DragMiniWindow(
                  controller: controller,
                  expandedContent: const Text('expanded'),
                  miniContent: const Text('mini'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('mini'), findsOneWidget);
      expect(find.text('expanded'), findsNothing);
    });
  });
}
