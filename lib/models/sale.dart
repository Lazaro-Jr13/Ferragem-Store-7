import 'sale_item.dart';

class Sale {
  final String id;
  final DateTime date;
  final List<SaleItem> items;

  Sale({
    required this.id,
    required this.date,
    required this.items,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List)
          .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
