import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_diet/main.dart';
import 'package:my_diet/services/theme_provider.dart';

void main() {
  testWidgets('Приложение запускается на онбординге если нет профиля',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyDietApp(
          disclaimerAccepted: true,
          profileExists: false,
        ),
      ),
    );

    expect(find.text('Добро пожаловать!'), findsOneWidget);
  });
}
