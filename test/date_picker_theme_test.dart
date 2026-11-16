import 'package:flutter_test/flutter_test.dart';

import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('date pickers use the shared Glamora glass palette', () {
    final theme = AppTheme.light;
    final datePicker = theme.datePickerTheme;

    expect(datePicker.backgroundColor, AppColors.glassSurface);
    expect(datePicker.headerBackgroundColor, AppColors.graphite);
    expect(datePicker.rangePickerBackgroundColor, AppColors.glassSurface);
    expect(datePicker.rangePickerHeaderBackgroundColor, AppColors.graphite);
    expect(
      datePicker.cancelButtonStyle?.foregroundColor?.resolve({}),
      AppColors.champagneGold,
    );
    expect(
      datePicker.confirmButtonStyle?.foregroundColor?.resolve({}),
      AppColors.champagneGold,
    );
  });
}
