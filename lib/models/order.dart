import 'cart_item.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  handedOver,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.handedOver:
        return 'Handed Over';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool canTransitionTo(OrderStatus next) {
    if (this == next) return true;
    if (this == OrderStatus.handedOver || this == OrderStatus.cancelled) return false;
    switch (this) {
      case OrderStatus.pending:
        return next == OrderStatus.accepted || next == OrderStatus.cancelled;
      case OrderStatus.accepted:
        return next == OrderStatus.preparing || next == OrderStatus.cancelled;
      case OrderStatus.preparing:
        return next == OrderStatus.ready || next == OrderStatus.cancelled;
      case OrderStatus.ready:
        return next == OrderStatus.handedOver;
      default:
        return false;
    }
  }
}

class OrderStatusLog {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  const OrderStatusLog({
    required this.status,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory OrderStatusLog.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    final status = OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => OrderStatus.pending,
    );
    return OrderStatusLog(
      status: status,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }
}

class OrderModel {
  final String id;
  final String idempotencyKey;
  final String orderNumber;
  final String customerName;
  final String? customerNotes;
  final List<CartItem> items;
  final int subtotalCents;
  final int feeCents;
  final int totalCents;
  final OrderStatus status;
  final int estimatedPrepMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderStatusLog> history;

  const OrderModel({
    required this.id,
    required this.idempotencyKey,
    required this.orderNumber,
    required this.customerName,
    this.customerNotes,
    required this.items,
    required this.subtotalCents,
    required this.feeCents,
    required this.totalCents,
    required this.status,
    this.estimatedPrepMinutes = 20,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
  });

  OrderModel copyWith({
    String? id,
    String? idempotencyKey,
    String? orderNumber,
    String? customerName,
    String? customerNotes,
    List<CartItem>? items,
    int? subtotalCents,
    int? feeCents,
    int? totalCents,
    OrderStatus? status,
    int? estimatedPrepMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderStatusLog>? history,
  }) {
    return OrderModel(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerNotes: customerNotes ?? this.customerNotes,
      items: items ?? this.items,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      feeCents: feeCents ?? this.feeCents,
      totalCents: totalCents ?? this.totalCents,
      status: status ?? this.status,
      estimatedPrepMinutes: estimatedPrepMinutes ?? this.estimatedPrepMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'orderNumber': orderNumber,
        'customerName': customerName,
        'customerNotes': customerNotes,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotalCents': subtotalCents,
        'feeCents': feeCents,
        'totalCents': totalCents,
        'status': status.name,
        'estimatedPrepMinutes': estimatedPrepMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    final status = OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => OrderStatus.pending,
    );
    return OrderModel(
      id: json['id'] as String? ?? 'ord-unknown',
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      orderNumber: (json['orderNumber'] ?? '').toString(),
      customerName: json['customerName'] as String? ?? 'Guest Customer',
      customerNotes: json['customerNotes'] as String?,
      items: ((json['items'] as List<dynamic>?) ?? [])
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotalCents: json['subtotalCents'] as int? ?? 0,
      feeCents: json['feeCents'] as int? ?? 250,
      totalCents: json['totalCents'] as int? ?? 0,
      status: status,
      estimatedPrepMinutes: json['estimatedPrepMinutes'] as int? ?? 20,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      history: ((json['history'] as List<dynamic>?) ?? [])
          .map((e) => OrderStatusLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
