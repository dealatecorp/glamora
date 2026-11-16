import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'inventory_details_screen.dart';
import 'inventory_form_screen.dart';

enum _ProductScope { active, archived }
enum _InventorySort { name, quantity, updated }

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key, required this.repository, required this.session});
  final DemoRepository repository;
  final AuthSession session;
  @override State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _search = TextEditingController();
  List<InventoryProduct> _products = [];
  _ProductScope _scope = _ProductScope.active;
  _InventorySort _sort = _InventorySort.name;
  String? _category;
  InventoryStockStatus? _status;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await widget.repository.getProducts(includeArchived: true);
    if (mounted) setState(() { _products = products; _loading = false; });
  }
  Future<void> _form([InventoryProduct? product]) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => InventoryFormScreen(repository: widget.repository, performedBy: widget.session.displayName, product: product)));
    if (changed == true) _load();
  }
  List<InventoryProduct> get _visible {
    final query = _search.text.trim().toLowerCase();
    final items = _products.where((p) => p.isActive == (_scope == _ProductScope.active) && (query.isEmpty || p.name.toLowerCase().contains(query)) && (_category == null || p.category == _category) && (_status == null || p.stockStatus == _status)).toList();
    items.sort((a, b) => switch (_sort) { _InventorySort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()), _InventorySort.quantity => a.quantityOnHand.compareTo(b.quantityOnHand), _InventorySort.updated => b.updatedAt.compareTo(a.updatedAt) });
    return items;
  }
  @override Widget build(BuildContext context) {
    final active = _products.where((p) => p.isActive).toList();
    final categories = _products.map((p) => p.category).toSet().toList()..sort();
    return Scaffold(backgroundColor: AppColors.warmIvory, appBar: AppBar(title: const Text('Salon Products'), actions: [IconButton(tooltip: 'Add product', onPressed: _form, icon: const Icon(Icons.add_box_outlined))]), body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [Text('Inventory', style: AppTextStyles.displaySmall), const SizedBox(height: 6), Text('Keep stock levels clear and ready for every service.', style: AppTextStyles.bodyMedium), const SizedBox(height: 16), _Summary(products: active), const SizedBox(height: 16), SearchField(controller: _search, hintText: 'Search products', onChanged: (_) => setState(() {})), const SizedBox(height: 10), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [ChoiceChip(label: const Text('Active'), selected: _scope == _ProductScope.active, onSelected: (_) => setState(() => _scope = _ProductScope.active)), const SizedBox(width: 8), ChoiceChip(label: const Text('Archived'), selected: _scope == _ProductScope.archived, onSelected: (_) => setState(() => _scope = _ProductScope.archived)), const SizedBox(width: 8), ChoiceChip(label: const Text('All categories'), selected: _category == null, onSelected: (_) => setState(() => _category = null)), ...categories.map((c) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = _category == c ? null : c)))), ...InventoryStockStatus.values.map((s) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = _status == s ? null : s))))])), const SizedBox(height: 8), Row(children: [Text('Sort by', style: AppTextStyles.bodySmall), const SizedBox(width: 8), DropdownButton<_InventorySort>(value: _sort, underline: const SizedBox(), items: const [DropdownMenuItem(value: _InventorySort.name, child: Text('Name')), DropdownMenuItem(value: _InventorySort.quantity, child: Text('Quantity')), DropdownMenuItem(value: _InventorySort.updated, child: Text('Recently updated'))], onChanged: (v) => setState(() => _sort = v!))]), const SizedBox(height: 14), if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) else if (_visible.isEmpty) EmptyState(title: _scope == _ProductScope.archived ? 'No archived products found.' : 'No products found.') else ..._visible.map((p) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ProductCard(product: p, onTap: () async { final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => InventoryDetailsScreen(productId: p.id, repository: widget.repository, performedBy: widget.session.displayName))); if (changed == true) _load(); }))), if (_scope == _ProductScope.active) ...[const SizedBox(height: 8), PrimaryButton(label: 'Add product', onPressed: _form)]])));
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.products}); final List<InventoryProduct> products;
  @override Widget build(BuildContext context) { int count(InventoryStockStatus s) => products.where((p) => p.stockStatus == s).length; final items = [('Products', products.length), ('In stock', count(InventoryStockStatus.inStock)), ('Low stock', count(InventoryStockStatus.lowStock)), ('Out of stock', count(InventoryStockStatus.outOfStock))]; return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: items.map((item) => SizedBox(width: 116, child: Padding(padding: const EdgeInsets.only(right: 8), child: AppCard(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item.$2}', style: AppTextStyles.titleLarge), Text(item.$1, style: AppTextStyles.caption)]))))).toList())); }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap}); final InventoryProduct product; final VoidCallback onTap;
  @override Widget build(BuildContext context) => AppCard(padding: EdgeInsets.zero, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: AppTextStyles.titleLarge), Text(product.category, style: AppTextStyles.bodySmall), const SizedBox(height: 4), Text('${product.quantityOnHand} units · Rs ${product.unitPrice.toStringAsFixed(0)}', style: AppTextStyles.caption)])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [StatusPill(label: product.isActive ? product.stockStatus.label : 'Archived'), const SizedBox(height: 6), const Icon(Icons.chevron_right_rounded, color: AppColors.mutedTaupe)])]))));
}
