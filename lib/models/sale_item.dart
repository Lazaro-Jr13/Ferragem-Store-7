class SaleItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  SaleItem copyWith({int? quantity}) {
    return SaleItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
    };
  }
}
