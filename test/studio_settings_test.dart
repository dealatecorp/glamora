import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  test('Studio settings persist through a new repository instance', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = DemoRepository();

    final originalProfile = await repository.getBusinessProfile();
    final originalHours = await repository.getBusinessHours();
    final originalBreaks = await repository.getSalonBreaks();
    final originalSettings = await repository.getApplicationSettings();

    await repository.updateBusinessProfile(
      BusinessProfile(
        id: originalProfile.id,
        salonName: 'Glamora Demo Studio',
        tagline: originalProfile.tagline,
        address: originalProfile.address,
        phone: originalProfile.phone,
        email: originalProfile.email,
        logoUrl: originalProfile.logoUrl,
        createdAt: originalProfile.createdAt,
        currency: originalProfile.currency,
      ),
    );
    await repository.updateBusinessHours([
      ...originalHours,
      const BusinessHours(
        id: 'hours_demo_extra',
        dayName: 'Demo Day',
        openTime: '10:00',
        closeTime: '17:00',
        isClosed: false,
      ),
    ]);
    await repository.updateSalonBreaks([
      ...originalBreaks,
      SalonBreak(
        id: 'break_demo_extra',
        title: 'Demo break',
        startTime: '15:00',
        endTime: '15:30',
        date: DateTime(2026, 9, 23),
      ),
    ]);
    await repository.updateApplicationSettings(
      ApplicationSettings(
        defaultAppointmentDuration:
            originalSettings.defaultAppointmentDuration + 5,
        reminderHours: originalSettings.reminderHours + 1,
        notificationsEnabled: !originalSettings.notificationsEnabled,
        customerBookingUrl: originalSettings.customerBookingUrl,
      ),
    );

    final restoredRepository = DemoRepository();
    expect(
      (await restoredRepository.getBusinessProfile()).salonName,
      'Glamora Demo Studio',
    );
    expect(
      (await restoredRepository.getBusinessHours()).last.dayName,
      'Demo Day',
    );
    expect(
      (await restoredRepository.getSalonBreaks()).last.title,
      'Demo break',
    );
    expect(
      (await restoredRepository.getApplicationSettings()).notificationsEnabled,
      !originalSettings.notificationsEnabled,
    );
  });
}
