import 'package:drag_mini_window/drag_mini_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragMiniWindowController', () {
    late DragMiniWindowController controller;

    setUp(() => controller = DragMiniWindowController());
    tearDown(() => controller.dispose());

    test('initial state is full', () {
      expect(controller.status, DragMiniStatus.full);
      expect(controller.isMinimized, false);
      expect(controller.isDismissed, false);
      expect(controller.progress, 0.0);
    });

    test('minimize() sets status to mini and progress to 1.0', () {
      controller.minimize();
      expect(controller.status, DragMiniStatus.mini);
      expect(controller.isMinimized, true);
      expect(controller.progress, 1.0);
    });

    test('maximize() sets status to full and progress to 0.0', () {
      controller.minimize();
      controller.maximize();
      expect(controller.status, DragMiniStatus.full);
      expect(controller.isMinimized, false);
      expect(controller.progress, 0.0);
    });

    test('dismiss() sets status to dismissed', () {
      controller.dismiss();
      expect(controller.status, DragMiniStatus.dismissed);
      expect(controller.isDismissed, true);
    });

    test('toggle() switches between full and mini', () {
      controller.toggle();
      expect(controller.status, DragMiniStatus.mini);
      controller.toggle();
      expect(controller.status, DragMiniStatus.full);
    });

    test('updateDragProgress updates progress value', () {
      controller.updateDragProgress(0.5);
      expect(controller.progress, 0.5);
    });

    test('setMiniPosition stores position', () {
      const pos = Offset(100, 200);
      controller.setMiniPosition(pos);
      expect(controller.position, pos);
    });
  });

  group('DragMiniWindow widget', () {
    testWidgets('renders in Overlay', (tester) async {
      final controller = DragMiniWindowController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DragMiniWindow(
              controller: controller,
              expandedContent: const Text('expanded_content'),
              miniContent: const Text('mini_content'),
            ),
          ),
        ),
      );
      await tester.pump(); // Insert overlay

      expect(find.text('expanded_content'), findsOneWidget);
    });

    testWidgets('switches content based on progress', (tester) async {
      final controller = DragMiniWindowController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DragMiniWindow(
              controller: controller,
              expandedContent: const Text('expanded_content'),
              miniContent: const Text('mini_content'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Start minimizing
      controller.updateDragProgress(0.6);
      await tester.pumpAndSettle();

      expect(find.text('mini_content'), findsOneWidget);
    });
  });
}
