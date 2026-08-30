import 'package:autospot/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('onboarding is shown for a new player', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: AutoSpotApp()));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Дальше').evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('AUTOSPOT'), findsOneWidget);
    expect(find.text('Дальше'), findsOneWidget);
  });
}
