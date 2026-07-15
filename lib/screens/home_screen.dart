import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/store_controller.dart';

final _currency = NumberFormat.currency(locale: 'pt_MZ', symbol: 'MT ', decimalDigits: 2);
final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

class HomeScreen extends StatefulWidget {
  final StoreController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ProductsTab(controller: widget.controller),
      CaixaTab(controller: widget.controller),
      StockTab(controller: widget.controller),
      ReportsTab(controller: widget.controller),
    ];
    final titles = ['Produtos', 'Caixa', 'Stock', 'Relatorios'];

    return Scaffold(
      appBar: AppBar(title: Text('Ferragem Store - ${titles[_tabIndex]}')),
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: 'Caixa'),
          NavigationDestination(icon: Icon(Icons.warehouse_outlined), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Relatorios'),
        ],
      ),
    );
  }
}

// ==================== PRODUTOS ====================

class ProductsTab extends StatefulWidget {
  final StoreController controller;
  const ProductsTab({super.key, required this.controller});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  String _query = '';
  String _category = 'Todas';

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.products;
    final categories = ['Todas', ...widget.controller.categories];
    final filtered = all.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = _category == 'Todas' || p.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar produto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  final selected = c == _category;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhum produto encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${p.category} • ${p.stock} ${p.unit} • ${_currency.format(p.price)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.isLowStock)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(context, product: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(context, p),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover produto'),
        content: Text('Tem a certeza que deseja remover "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              widget.controller.deleteProduct(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProductFormSheet(controller: widget.controller, product: product),
    );
  }
}

class ProductFormSheet extends StatefulWidget {
  final StoreController controller;
  final Product? product;
  const ProductFormSheet({super.key, required this.controller, this.product});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _category;
  late TextEditingController _unit;
  late TextEditingController _price;
  late TextEditingController _stock;
  late TextEditingController _minStock;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _unit = TextEditingController(text: p?.unit ?? 'un');
    _price = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '');
    _stock = TextEditingController(text: p != null ? p.stock.toString() : '0');
    _minStock = TextEditingController(text: p != null ? p.minStock.toString() : '5');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _unit.dispose();
    _price.dispose();
    _stock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditing ? 'Editar Produto' : 'Novo Produto',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _field(_name, 'Nome'),
              const SizedBox(height: 8),
              _field(_category, 'Categoria'),
              const SizedBox(height: 8),
              _field(_unit, 'Unidade (un, kg, saco...)'),
              const SizedBox(height: 8),
              _field(_price, 'Preco (MT)', number: true),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _field(_stock, 'Stock atual', number: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_minStock, 'Stock minimo', number: true)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Guardar alteracoes' : 'Adicionar produto'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return TextFormField(
      controller: c,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatorio' : null,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;
    final stock = int.tryParse(_stock.text) ?? 0;
    final minStock = int.tryParse(_minStock.text) ?? 0;

    if (widget.product == null) {
      await widget.controller.addProduct(
        name: _name.text.trim(),
        category: _category.text.trim(),
        unit: _unit.text.trim(),
        price: price,
        stock: stock,
        minStock: minStock,
      );
    } else {
      await widget.controller.updateProduct(
        widget.product!.id,
        name: _name.text.trim(),
        category: _category.text.trim(),
        unit: _unit.text.trim(),
        price: price,
        stock: stock,
        minStock: minStock,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
// ==================== CAIXA ====================

class CaixaTab extends StatefulWidget {
  final StoreController controller;
  const CaixaTab({super.key, required this.controller});

  @override
  State<CaixaTab> createState() => _CaixaTabState();
}

class _CaixaTabState extends State<CaixaTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final products = widget.controller.products.where((p) {
      return _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    final cart = widget.controller.cart;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Pesquisar para adicionar...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              IconButton(
                tooltip: 'Historico de vendas',
                icon: const Icon(Icons.history),
                onPressed: () => _showHistory(context),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: products.isEmpty
              ? const Center(child: Text('Nenhum produto.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    final inCart = cart[p.id] ?? 0;
                    final outOfStock = p.stock <= 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${_currency.format(p.price)} • ${p.stock} ${p.unit} disp.'),
                        trailing: outOfStock
                            ? const Text('Sem stock', style: TextStyle(color: Colors.redAccent))
                            : FilledButton(
                                onPressed: inCart >= p.stock
                                    ? null
                                    : () => widget.controller.addToCart(p.id),
                                child: Text(inCart > 0 ? '+ ($inCart)' : 'Adicionar'),
                              ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black.withAlpha(6),
            padding: const EdgeInsets.all(12),
            child: cart.isEmpty
                ? const Center(child: Text('Carrinho vazio'))
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: cart.entries.map((entry) {
                            final p = widget.controller.productById(entry.key);
                            if (p == null) return const SizedBox.shrink();
                            final qty = entry.value;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(_currency.format(p.price * qty)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => widget.controller.setCartQuantity(p.id, qty - 1),
                                  ),
                                  Text('$qty'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: qty >= p.stock
                                        ? null
                                        : () => widget.controller.setCartQuantity(p.id, qty + 1),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.titleMedium),
                          Text(_currency.format(widget.controller.cartTotal),
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.controller.clearCart,
                              child: const Text('Limpar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: () => _finalizeSale(context),
                              child: const Text('Finalizar venda'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _finalizeSale(BuildContext context) async {
    final sale = await widget.controller.finalizeSale();
    if (!context.mounted) return;
    if (sale != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venda registada: ${_currency.format(sale.total)}')),
      );
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final sales = widget.controller.sales;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Historico de Vendas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: sales.isEmpty
                      ? const Center(child: Text('Sem vendas registadas.'))
                      : ListView.builder(
                          itemCount: sales.length,
                          itemBuilder: (context, i) {
                            final Sale s = sales[i];
                            return ExpansionTile(
                              title: Text(_dateFmt.format(s.date)),
                              subtitle: Text('${s.itemCount} itens • ${_currency.format(s.total)}'),
                              children: s.items
                                  .map((it) => ListTile(
                                        dense: true,
                                        title: Text(it.productName),
                                        trailing: Text('${it.quantity} x ${_currency.format(it.unitPrice)}'),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
// ==================== STOCK ====================

class StockTab extends StatelessWidget {
  final StoreController controller;
  const StockTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final products = [...controller.products]
      ..sort((a, b) => a.isLowStock == b.isLowStock ? 0 : (a.isLowStock ? -1 : 1));

    return products.isEmpty
        ? const Center(child: Text('Nenhum produto.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Minimo: ${p.minStock} ${p.unit} • Valor: ${_currency.format(p.stockValue)}'),
                  leading: CircleAvatar(
                    backgroundColor: p.isLowStock ? Colors.redAccent : Colors.green,
                    child: Text('${p.stock}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => _showRestock(context, p),
                    child: const Text('Ajustar'),
                  ),
                ),
              );
            },
          );
  }

  void _showRestock(BuildContext context, Product p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajustar stock: ${p.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Quantidade (use - para retirar)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text) ?? 0;
              controller.restock(p.id, v);
              Navigator.pop(ctx);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

// ==================== RELATORIOS ====================

class ReportsTab extends StatelessWidget {
  final StoreController controller;
  const ReportsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final lowStock = controller.lowStockProducts;
    final bestSellers = controller.bestSellers;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Vendas hoje', _currency.format(controller.todaySalesTotal))),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Vendas (7 dias)', _currency.format(controller.weekSalesTotal))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _metricCard('Valor em stock', _currency.format(controller.totalStockValue))),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Stock baixo', '${lowStock.length} produtos')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Mais vendidos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (bestSellers.isEmpty)
          const Text('Ainda sem vendas registadas.')
        else
          Card(
            child: Column(
              children: bestSellers
                  .map((e) => ListTile(
                        dense: true,
                        title: Text(e.key),
                        trailing: Text('${e.value} vendidos'),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),
        Text('Alertas de stock baixo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (lowStock.isEmpty)
          const Text('Sem alertas no momento.')
        else
          Card(
            child: Column(
              children: lowStock
                  .map((p) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        title: Text(p.name),
                        trailing: Text('${p.stock} ${p.unit}'),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _metricCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
