import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/services/widgets/category_video_background.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  test('demo service catalogue contains original and required services', () {
    final services = DemoData.services;
    expect(services.length, 74);
    expect(
      services.where((service) => service.id.startsWith('svc_')).length,
      9,
    );
    expect(
      services.map((service) => service.id).toSet().length,
      services.length,
    );
    expect(
      services
          .map((service) => '${service.category.name}:${service.name}')
          .toSet()
          .length,
      services.length,
    );
    expect(
      services.map((service) => service.category).toSet(),
      containsAll(ServiceCategory.values),
    );
  });

  test(
    'every demo service has eligible employees and package labels are preserved',
    () {
      final employeeIds = DemoData.employees
          .map((employee) => employee.id)
          .toSet();
      expect(
        DemoData.services.every(
          (service) => service.assignedEmployeeIds.every(employeeIds.contains),
        ),
        isTrue,
      );

      final preBridal = DemoData.services.firstWhere(
        (service) => service.name == 'Pre-Bridal Package',
      );
      expect(preBridal.priceLabel, '₹10,000–₹20,000');
      expect(preBridal.durationLabel, 'Multiple sessions');
      expect(
        DemoData.services
            .where((service) => service.name == 'Keratin Treatment')
            .single
            .price,
        4000,
      );
    },
  );

  test('category video mapping uses hair video for Keratin Treatment', () {
    final keratin = DemoData.services.firstWhere(
      (service) => service.name == 'Keratin Treatment',
    );
    expect(keratin.category.videoAsset, 'assets/videos/hair.mp4');
    expect(
      ServiceCategory.bodyWaxing.videoAsset,
      'assets/videos/body_waxing.mp4',
    );
    expect(ServiceCategory.events.videoAsset, 'assets/videos/event.mp4');
  });

  test('requested category videos use the supplied asset mappings', () {
    expect(
      ServiceCategory.bodyWaxing.videoAsset,
      'assets/videos/body_waxing.mp4',
    );
    expect(ServiceCategory.grooming.videoAsset, 'assets/videos/grooming.mp4');
    expect(ServiceCategory.makeUp.videoAsset, 'assets/videos/makeup.mp4');
    expect(ServiceCategory.events.videoAsset, 'assets/videos/event.mp4');
    expect(ServiceCategory.nails.videoAsset, 'assets/videos/nails.mp4');
  });
}
