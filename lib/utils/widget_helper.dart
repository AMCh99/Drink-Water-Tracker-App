import 'package:home_widget/home_widget.dart';
import '../database/database_helper.dart';

class WidgetHelper {
  static Future<void> updateWidget() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final total = await dbHelper.getTotalWaterForDay(DateTime.now());
      final settings = await dbHelper.getDaySettings();

      // Zapisz dane do widgetu
      await HomeWidget.saveWidgetData<int>('water_total', total);
      await HomeWidget.saveWidgetData<int>('water_goal', settings.dailyGoal);
      await HomeWidget.saveWidgetData<String>('water_unit', settings.unit);

      // Zaktualizuj widget
      await HomeWidget.updateWidget(androidName: 'WaterWidgetProvider');
    } catch (e) {
      print('Błąd aktualizacji widgetu: $e');
    }
  }
}
