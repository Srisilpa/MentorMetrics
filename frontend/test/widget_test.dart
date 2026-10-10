import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/main.dart';
import 'package:frontend/widgets/star_rating_bar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MentorMetricsApp loads and displays WelcomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MentorMetricsApp());
    // Pump frames to let session check resolve
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MentorMetrics'), findsOneWidget);
    expect(find.text('Student Portal'), findsOneWidget);
    expect(find.text('Administrator Portal'), findsOneWidget);
  });

  testWidgets('StarRatingBar displays 5 stars and responds to tap', (WidgetTester tester) async {
    int currentRating = 3;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return StarRatingBar(
                title: 'Teaching Quality',
                rating: currentRating,
                onRatingChanged: (newRating) {
                  setState(() {
                    currentRating = newRating;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Teaching Quality'), findsOneWidget);
    expect(find.text('3 / 5 (Good)'), findsOneWidget);

    final starIcons = find.byType(Icon);
    expect(starIcons, findsNWidgets(5));
    await tester.tap(starIcons.last);
    await tester.pumpAndSettle();

    expect(currentRating, 5);
    expect(find.text('5 / 5 (Excellent)'), findsOneWidget);
  });
}
