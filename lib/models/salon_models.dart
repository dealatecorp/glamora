class Admin {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime createdAt;

  const Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  });
}

class Employee {
  final String id;
  final String fullName;
  final String role;
  final String? specialty;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int experienceYears;
  final List<String> serviceIds;
  final int rewardXp;
  final DateTime? pinLastResetAt;

  const Employee({
    required this.id,
    required this.fullName,
    required this.role,
    this.specialty,
    this.phone,
    this.email,
    required this.isActive,
    required this.createdAt,
    DateTime? updatedAt,
    this.experienceYears = 0,
    this.serviceIds = const [],
    this.rewardXp = 0,
    this.pinLastResetAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Employee copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? role,
    String? specialty,
    bool? isActive,
    int? experienceYears,
    List<String>? serviceIds,
    int? rewardXp,
    DateTime? pinLastResetAt,
  }) {
    return Employee(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      experienceYears: experienceYears ?? this.experienceYears,
      serviceIds: List.unmodifiable(serviceIds ?? this.serviceIds),
      rewardXp: rewardXp ?? this.rewardXp,
      pinLastResetAt: pinLastResetAt ?? this.pinLastResetAt,
    );
  }
}

class EmployeeRewardTransaction {
  const EmployeeRewardTransaction({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.reason,
    required this.performedBy,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final int amount;
  final String reason;
  final String performedBy;
  final DateTime createdAt;
}

class Client {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastVisitAt;
  final int loyaltyPoints;
  final int visitCount;
  final bool isVip;
  final bool isArchived;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.notes,
    required this.createdAt,
    this.lastVisitAt,
    this.loyaltyPoints = 0,
    this.visitCount = 0,
    this.isVip = false,
    this.isArchived = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  int get loyaltyXpBalance => loyaltyPoints;

  Client copyWith({
    String? fullName,
    String? phone,
    String? email,
    int? loyaltyPoints,
    DateTime? updatedAt,
    bool? isArchived,
    int? visitCount,
    bool? isVip,
  }) {
    return Client(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes,
      createdAt: createdAt,
      lastVisitAt: lastVisitAt,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      visitCount: visitCount ?? this.visitCount,
      isVip: isVip ?? this.isVip,
      isArchived: isArchived ?? this.isArchived,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class ClientHistory {
  const ClientHistory({
    required this.appointments,
    required this.payments,
    required this.invoices,
  });

  final List<Appointment> appointments;
  final List<Payment> payments;
  final List<Invoice> invoices;

  Iterable<AppointmentService> get services => appointments
      .where((appointment) => appointment.status == AppointmentStatus.completed)
      .expand((appointment) => appointment.services);
}

enum ServiceCategory {
  face,
  hair,
  bodyWaxing,
  nails,
  wellness,
  grooming,
  makeUp,
  events,
}

extension ServiceCategoryX on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.face:
        return 'Face';
      case ServiceCategory.hair:
        return 'Hair';
      case ServiceCategory.bodyWaxing:
        return 'Body/Waxing';
      case ServiceCategory.nails:
        return 'Nails';
      case ServiceCategory.wellness:
        return 'Wellness';
      case ServiceCategory.grooming:
        return 'Grooming';
      case ServiceCategory.makeUp:
        return 'Makeup';
      case ServiceCategory.events:
        return 'Events';
    }
  }
}

class Service {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final String? priceLabel;
  final String? durationLabel;
  final ServiceCategory category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> assignedEmployeeIds;
  final String? historicalName;
  final ServiceCategory? historicalCategory;
  final int? historicalDurationMinutes;
  final double? historicalPrice;

  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.priceLabel,
    this.durationLabel,
    required this.category,
    required this.isActive,
    required this.createdAt,
    DateTime? updatedAt,
    this.assignedEmployeeIds = const [],
    this.historicalName,
    this.historicalCategory,
    this.historicalDurationMinutes,
    this.historicalPrice,
  }) : updatedAt = updatedAt ?? createdAt;

  Service copyWith({
    required String name,
    required ServiceCategory category,
    required int durationMinutes,
    required double price,
    required String description,
    required List<String> assignedEmployeeIds,
    bool? isActive,
  }) {
    return Service(
      id: id,
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      price: price,
      priceLabel: priceLabel,
      durationLabel: durationLabel,
      category: category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      assignedEmployeeIds: List.unmodifiable(assignedEmployeeIds),
      historicalName: historicalName,
      historicalCategory: historicalCategory,
      historicalDurationMinutes: historicalDurationMinutes,
      historicalPrice: historicalPrice,
    );
  }
}

class AppointmentService {
  final String id;
  final String serviceId;
  final String serviceName;
  final ServiceCategory? category;
  final int durationMinutes;
  final double price;
  final String? employeeId;
  final String? employeeName;
  final String? historicalServiceName;
  final ServiceCategory? historicalCategory;
  final int? historicalDurationMinutes;
  final double? historicalPrice;

  /// True only when an administrator deliberately assigned a staff member
  /// outside their recorded service capabilities.
  final bool isCapabilityOverride;

  const AppointmentService({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    this.category,
    required this.durationMinutes,
    required this.price,
    this.employeeId,
    this.employeeName,
    this.historicalServiceName,
    this.historicalCategory,
    this.historicalDurationMinutes,
    this.historicalPrice,
    this.isCapabilityOverride = false,
  });
}

enum AppointmentStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  noShow,
}

class Appointment {
  final String id;
  final String clientId;
  final String clientName;
  final String? employeeId;
  final String? employeeName;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatus status;
  final PaymentStatus paymentStatus;
  final List<AppointmentService> services;
  final String? notes;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final Reminder? reminder;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.employeeId,
    this.employeeName,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.paymentStatus = PaymentStatus.pending,
    required this.services,
    this.notes,
    this.source,
    required this.createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.reminder,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
  }) : updatedAt = updatedAt ?? createdAt;

  double get totalPrice => services.fold(0, (sum, item) => sum + item.price);
}

enum PaymentMethod { razorpay, upi, cash, card, manual }

enum PaymentStatus { pending, authorized, paid, failed, refunded }

class Payment {
  final String id;
  final String appointmentId;
  final String invoiceId;
  final String clientId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? receiptNumber;
  final String? transactionId;
  final DateTime? paidAt;
  final String? failureReason;
  final DateTime? refundedAt;
  final String? refundReference;

  const Payment({
    required this.id,
    required this.appointmentId,
    this.invoiceId = '',
    required this.clientId,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.receiptNumber,
    this.transactionId,
    this.paidAt,
    this.failureReason,
    this.refundedAt,
    this.refundReference,
  });

  Payment copyWith({
    PaymentStatus? status,
    String? transactionId,
    DateTime? paidAt,
    String? failureReason,
    DateTime? refundedAt,
    String? refundReference,
  }) {
    return Payment(
      id: id,
      appointmentId: appointmentId,
      invoiceId: invoiceId,
      clientId: clientId,
      amount: amount,
      method: method,
      status: status ?? this.status,
      createdAt: createdAt,
      receiptNumber: receiptNumber,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
      failureReason: failureReason ?? this.failureReason,
      refundedAt: refundedAt ?? this.refundedAt,
      refundReference: refundReference ?? this.refundReference,
    );
  }
}

class Invoice {
  final String id;
  final String appointmentId;
  final String clientId;
  final double subtotal;
  final double tax;
  final double total;
  final DateTime issuedAt;
  final bool isPaid;
  final String invoiceNumber;
  final String salonName;
  final String clientName;
  final List<InvoiceLineItem> lineItems;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final String? transactionId;
  final double amountPaid;
  final double balance;
  final DateTime? paymentDate;

  const Invoice({
    required this.id,
    required this.appointmentId,
    required this.clientId,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.issuedAt,
    required this.isPaid,
    String? invoiceNumber,
    this.salonName = 'Glamora',
    this.clientName = '',
    this.lineItems = const [],
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    this.transactionId,
    this.amountPaid = 0,
    double? balance,
    this.paymentDate,
  }) : invoiceNumber = invoiceNumber ?? id,
       balance = balance ?? total;

  Invoice copyWithPayment({
    required PaymentStatus paymentStatus,
    required PaymentMethod paymentMethod,
    required String transactionId,
    required double amountPaid,
    required DateTime paymentDate,
  }) {
    return Invoice(
      id: id,
      appointmentId: appointmentId,
      clientId: clientId,
      subtotal: subtotal,
      tax: tax,
      total: total,
      issuedAt: issuedAt,
      isPaid: paymentStatus == PaymentStatus.paid,
      invoiceNumber: invoiceNumber,
      salonName: salonName,
      clientName: clientName,
      lineItems: lineItems,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      amountPaid: amountPaid,
      balance: total - amountPaid,
      paymentDate: paymentDate,
    );
  }
}

enum DiscountType { none, percentage, fixed }

class InvoiceLineItem {
  const InvoiceLineItem({
    required this.serviceName,
    required this.employeeName,
    required this.durationMinutes,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalAmount,
  });

  final String serviceName;
  final String employeeName;
  final int durationMinutes;
  final double originalPrice;
  final double discountAmount;
  final double finalAmount;
}

class LoyaltyAccount {
  final String id;
  final String clientId;
  final int points;
  final DateTime lastUpdatedAt;
  final int tier;

  const LoyaltyAccount({
    required this.id,
    required this.clientId,
    required this.points,
    required this.lastUpdatedAt,
    required this.tier,
  });
}

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final bool isActive;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.isActive,
  });
}

class InventoryProduct {
  final String id;
  final String name;
  final String category;
  final int quantityOnHand;
  final double unitPrice;
  final DateTime updatedAt;
  final DateTime createdAt;
  final String? sku;
  final int lowStockThreshold;
  final bool isActive;

  const InventoryProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.quantityOnHand,
    required this.unitPrice,
    required this.updatedAt,
    DateTime? createdAt,
    this.sku,
    this.lowStockThreshold = 0,
    this.isActive = true,
  }) : createdAt = createdAt ?? updatedAt;

  InventoryStockStatus get stockStatus {
    if (quantityOnHand == 0) return InventoryStockStatus.outOfStock;
    if (quantityOnHand <= lowStockThreshold) {
      return InventoryStockStatus.lowStock;
    }
    return InventoryStockStatus.inStock;
  }

  InventoryProduct copyWith({
    String? name,
    String? category,
    double? unitPrice,
    int? quantityOnHand,
    int? lowStockThreshold,
    bool? isActive,
  }) => InventoryProduct(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    quantityOnHand: quantityOnHand ?? this.quantityOnHand,
    unitPrice: unitPrice ?? this.unitPrice,
    updatedAt: DateTime.now(),
    createdAt: createdAt,
    sku: sku,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    isActive: isActive ?? this.isActive,
  );
}

enum InventoryStockStatus { inStock, lowStock, outOfStock }

extension InventoryStockStatusX on InventoryStockStatus {
  String get label => switch (this) {
    InventoryStockStatus.inStock => 'In Stock',
    InventoryStockStatus.lowStock => 'Low Stock',
    InventoryStockStatus.outOfStock => 'Out of Stock',
  };
}

enum InventoryTransactionType { stockIn, stockOut, adjustment }

extension InventoryTransactionTypeX on InventoryTransactionType {
  String get label => switch (this) {
    InventoryTransactionType.stockIn => 'Stock in',
    InventoryTransactionType.stockOut => 'Stock out',
    InventoryTransactionType.adjustment => 'Adjustment',
  };
}

class InventoryTransaction {
  final String id;
  final String productId;
  final InventoryTransactionType type;
  final int quantity;
  final String productName;
  final int previousQuantity;
  final int newQuantity;
  final String reason;
  final String performedBy;
  final DateTime createdAt;

  const InventoryTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.productName,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    required this.performedBy,
    required this.createdAt,
  });
}

class BusinessProfile {
  final String id;
  final String salonName;
  final String tagline;
  final String address;
  final String phone;
  final String email;
  final String? logoUrl;
  final DateTime createdAt;
  final String currency;

  const BusinessProfile({
    required this.id,
    required this.salonName,
    required this.tagline,
    required this.address,
    required this.phone,
    required this.email,
    this.logoUrl,
    this.currency = 'INR',
    required this.createdAt,
  });
}

class ApplicationSettings {
  const ApplicationSettings({
    this.defaultAppointmentDuration = 60,
    this.reminderHours = 2,
    this.notificationsEnabled = true,
    this.customerBookingUrl = 'https://glamora.example.com/book',
  });
  final int defaultAppointmentDuration;
  final int reminderHours;
  final bool notificationsEnabled;
  final String customerBookingUrl;
}

class BusinessHours {
  final String id;
  final String dayName;
  final String openTime;
  final String closeTime;
  final bool isClosed;

  const BusinessHours({
    required this.id,
    required this.dayName,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
  });
}

class SalonBreak {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final DateTime date;

  const SalonBreak({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.date,
  });
}

class Reminder {
  final String id;
  final String title;
  final String message;
  final DateTime scheduledFor;
  final bool isSent;

  const Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.scheduledFor,
    required this.isSent,
  });
}
