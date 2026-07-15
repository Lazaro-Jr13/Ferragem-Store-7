class Product {
  final String id;
  String name;
  String category;
  String unit;
  double price;
  int stock;
  int minStock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.stock,
    required this.minStock,
  });

  bool get isLowStock => stock <= minStock;

  double get stockValue => price * stock;

  Product copyWith({
    String? name,
    String? category,
    String? unit,
    double? price,
    int? stock,
    int? minStock,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      minStock: json['minStock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'price': price,
      'stock': stock,
      'minStock': minStock,
    };
  }
}
