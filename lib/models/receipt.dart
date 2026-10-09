import 'order.dart';

class ReceiptModel {
  final String receiptNumber;
  final String orderId;
  final String orderNumber;
  final DateTime issuedAt;
  final String customerName;
  final List<ReceiptLineItem> items;
  final int subtotalCents;
  final int taxCents;
  final int serviceFeeCents;
  final int totalCents;
  final OrderStatus status;

  const ReceiptModel({
    required this.receiptNumber,
    required this.orderId,
    required this.orderNumber,
    required this.issuedAt,
    required this.customerName,
    required this.items,
    required this.subtotalCents,
    required this.taxCents,
    required this.serviceFeeCents,
    required this.totalCents,
    required this.status,
  });

  factory ReceiptModel.fromOrder(OrderModel order) {
    final tax = (order.subtotalCents * 0.08).round();
    return ReceiptModel(
      receiptNumber: 'RCP-${order.orderNumber}',
      orderId: order.id,
      orderNumber: order.orderNumber,
      issuedAt: order.updatedAt,
      customerName: order.customerName,
      items: order.items
          .map((item) => ReceiptLineItem(
                dishName: item.dish.name,
                customizationSummary: item.selectedOptionNames.values.join(', '),
                quantity: item.quantity,
                unitPriceCents: item.unitPriceCents,
                totalPriceCents: item.totalPriceCents,
              ))
          .toList(),
      subtotalCents: order.subtotalCents,
      taxCents: tax,
      serviceFeeCents: order.feeCents,
      totalCents: order.subtotalCents + tax + order.feeCents,
      status: order.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'receiptNumber': receiptNumber,
        'orderId': orderId,
        'orderNumber': orderNumber,
        'issuedAt': issuedAt.toIso8601String(),
        'customerName': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotalCents': subtotalCents,
        'taxCents': taxCents,
        'serviceFeeCents': serviceFeeCents,
        'totalCents': totalCents,
        'status': status.name,
      };

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      receiptNumber: json['receiptNumber'] as String,
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      customerName: json['customerName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => ReceiptLineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotalCents: json['subtotalCents'] as int,
      taxCents: json['taxCents'] as int,
      serviceFeeCents: json['serviceFeeCents'] as int,
      totalCents: json['totalCents'] as int,
      status: OrderStatus.values.byName(json['status'] as String),
    );
  }
}

class ReceiptLineItem {
  final String dishName;
  final String customizationSummary;
  final int quantity;
  final int unitPriceCents;
  final int totalPriceCents;

  const ReceiptLineItem({
    required this.dishName,
    required this.customizationSummary,
    required this.quantity,
    required this.unitPriceCents,
    required this.totalPriceCents,
  });

  Map<String, dynamic> toJson() => {
        'dishName': dishName,
        'customizationSummary': customizationSummary,
        'quantity': quantity,
        'unitPriceCents': unitPriceCents,
        'totalPriceCents': totalPriceCents,
      };

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) {
    return ReceiptLineItem(
      dishName: json['dishName'] as String,
      customizationSummary: json['customizationSummary'] as String,
      quantity: json['quantity'] as int,
      unitPriceCents: json['unitPriceCents'] as int,
      totalPriceCents: json['totalPriceCents'] as int,
    );
  }
}
