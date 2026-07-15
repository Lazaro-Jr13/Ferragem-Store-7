import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class StoreController extends ChangeNotifier {
  static const _productsKey = 'ferragem_products_v1';
  static const _salesKey = 'ferragem_sales_v1';
  static const _counterKey = 'ferragem_id_counter_v1';

  final List<Product> _products = [];
  final List<Sale> _sales = [];
  final Map<String, int> _cart = {}; // productId -> quantity

  SharedPreferences? _prefs;
  int _idCounter = 0;
  bool _loading = true;

  List<Product> get products => List.unmodifiable(_products);
  List<Sale> get sales => List.unmodifiable(_sales);
  Map<String, int> get cart => Map.unmodifiable(_cart);
  bool get isLoading => _loading;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _idCounter = _prefs!.getInt(_counterKey) ?? 0;

    final productsRaw = _prefs!.getString(_productsKey);
    if (productsRaw == null) {
      _seedProducts();
      await _saveProducts();
    } else {
      final list = jsonDecode(productsRaw) as List;
      _products
        ..clear()
        ..addAll(list.map((e) => Product.fromJson(e as Map<String, dynamic>)));
    }

    final salesRaw = _prefs!.getString(_salesKey);
    if (salesRaw != null) {
      final list = jsonDecode(salesRaw) as List;
      _sales
        ..clear()
        ..addAll(list.map((e) => Sale.fromJson(e as Map<String, dynamic>)));
    }

    _loading = false;
    notifyListeners();
  }

  void _seedProducts() {
    final seeds = [
      {'name': 'Cimento 50kg', 'category': 'Construcao', 'unit': 'saco', 'price': 550.0, 'stock': 40, 'min': 10},
      {'name': 'Prego 3"', 'category': 'Ferragem', 'unit': 'kg', 'price': 120.0, 'stock': 25, 'min': 5},
      {'name': 'Tinta Branca 5L', 'category': 'Pintura', 'unit': 'lata', 'price': 1350.0, 'stock': 12, 'min': 3},
      {'name': 'Tubo PVC 1"', 'category': 'Canalizacao', 'unit': 'un', 'price': 280.0, 'stock': 30, 'min': 8},
      {'name': 'Chapa Zinco', 'category': 'Cobertura', 'unit': 'un', 'price': 950.0, 'stock': 18, 'min': 5},
      {'name': 'Fita Isoladora', 'category': 'Eletrica', 'unit': 'un', 'price': 45.0, 'stock': 3, 'min': 5},
    ];
    for (final s in seeds) {
      _products.add(Product(
        id: _generateId(),
        name: s['name'] as String,
        category: s['category'] as String,
        unit: s['unit'] as String,
        price: s['price'] as double,
        stock: s['stock'] as int,
        minStock: s['min'] as int,
      ));
    }
  }

  String _generateId() {
    _idCounter += 1;
    _prefs?.setInt(_counterKey, _idCounter);
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  Future<void> _saveProducts() async {
    final raw = jsonEncode(_products.map((e) => e.toJson()).toList());
    await _prefs?.setString(_productsKey, raw);
  }

  Future<void> _saveSales() async {
    final raw = jsonEncode(_sales.map((e) => e.toJson()).toList());
    await _prefs?.setString(_salesKey, raw);
  }

  // ---------------- Products CRUD ----------------

  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      set.add(p.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required String unit,
    required double price,
    required int stock,
    required int minStock,
  }) async {
    _products.add(Product(
      id: _generateId(),
      name: name,
      category: category,
      unit: unit,
      price: price,
      stock: stock,
      minStock: minStock,
    ));
    await _saveProducts();
    notifyListeners();
  }

  Future<void> updateProduct(String id, {
    required String name,
    required String category,
    required String unit,
    required double price,
    required int stock,
    required int minStock,
  }) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _products[idx] = _products[idx].copyWith(
      name: name,
      category: category,
      unit: unit,
      price: price,
      stock: stock,
      minStock: minStock,
    );
    await _saveProducts();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    _cart.remove(id);
    await _saveProducts();
    notifyListeners();
  }

  Future<void> restock(String id, int amount) async {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1 || amount == 0) return;
    final p = _products[idx];
    final newStock = (p.stock + amount).clamp(0, 1 << 30);
    _products[idx] = p.copyWith(stock: newStock);
    await _saveProducts();
    notifyListeners();
  }

  Product? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------- Cart / Caixa ----------------

  bool addToCart(String productId, {int quantity = 1}) {
    final product = productById(productId);
    if (product == null) return false;
    final current = _cart[productId] ?? 0;
    if (current + quantity > product.stock) return false;
    _cart[productId] = current + quantity;
    notifyListeners();
    return true;
  }

  void setCartQuantity(String productId, int quantity) {
    final product = productById(productId);
    if (product == null) return;
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      _cart[productId] = quantity > product.stock ? product.stock : quantity;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartTotal {
    double total = 0;
    _cart.forEach((id, qty) {
      final p = productById(id);
      if (p != null) total += p.price * qty;
    });
    return total;
  }

  Future<Sale?> finalizeSale() async {
    if (_cart.isEmpty) return null;
    final items = <SaleItem>[];
    _cart.forEach((id, qty) {
      final p = productById(id);
      if (p != null) {
        items.add(SaleItem(
          productId: p.id,
          productName: p.name,
          unitPrice: p.price,
          quantity: qty,
        ));
      }
    });
    if (items.isEmpty) return null;

    for (final item in items) {
      final idx = _products.indexWhere((p) => p.id == item.productId);
      if (idx != -1) {
        final p = _products[idx];
        final newStock = (p.stock - item.quantity).clamp(0, 1 << 30);
        _products[idx] = p.copyWith(stock: newStock);
      }
    }

    final sale = Sale(id: _generateId(), date: DateTime.now(), items: items);
    _sales.insert(0, sale);
    _cart.clear();

    await _saveProducts();
    await _saveSales();
    notifyListeners();
    return sale;
  }

  // ---------------- Reports ----------------

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  double get totalStockValue =>
      _products.fold(0.0, (sum, p) => sum + p.stockValue);

  double salesTotalSince(DateTime since) {
    return _sales
        .where((s) => s.date.isAfter(since))
        .fold(0.0, (sum, s) => sum + s.total);
  }

  double get todaySalesTotal {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return salesTotalSince(start);
  }

  double get weekSalesTotal {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    return salesTotalSince(start);
  }

  List<MapEntry<String, int>> get bestSellers {
    final Map<String, int> counts = {};
    for (final sale in _sales) {
      for (final item in sale.items) {
        counts[item.productName] = (counts[item.productName] ?? 0) + item.quantity;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }
}
