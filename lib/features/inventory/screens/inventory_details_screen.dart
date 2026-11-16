import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';
import 'inventory_form_screen.dart';

class InventoryDetailsScreen extends StatefulWidget {
  const InventoryDetailsScreen({super.key, required this.productId, required this.repository, required this.performedBy});
  final String productId;
  final DemoRepository repository;
  final String performedBy;
  @override State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  InventoryProduct? _product;
  List<InventoryTransaction> _history = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final product = await widget.repository.getProductById(widget.productId);
    final history = await widget.repository.getInventoryTransactions(widget.productId);
    if (mounted) setState(() { _product = product; _history = history; _loading = false; });
  }
  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => InventoryFormScreen(repository: widget.repository, performedBy: widget.performedBy, product: _product)));
    if (changed == true) _load();
  }
  Future<void> _archive() async {
    final product = _product!;
    if (product.isActive) { await widget.repository.archiveProduct(product.id); } else { await widget.repository.restoreProduct(product.id); }
    await _load();
    if (mounted) Navigator.pop(context, true);
  }
  Future<void> _stock(InventoryTransactionType type) async {
    final quantity = TextEditingController();
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(type == InventoryTransactionType.stockIn ? 'Add stock' : type == InventoryTransactionType.stockOut ? 'Remove stock' : 'Adjust stock', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          TextFormField(controller: quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: type == InventoryTransactionType.adjustment ? 'New total quantity' : 'Quantity'), validator: (value) { final amount = int.tryParse(value?.trim() ?? ''); if (amount == null || amount < 0 || (type != InventoryTransactionType.adjustment && amount == 0)) return 'Enter a valid quantity.'; return null; }),
          const SizedBox(height: 12),
          TextFormField(controller: reason, decoration: const InputDecoration(labelText: 'Reason'), validator: (value) => value == null || value.trim().isEmpty ? 'A reason is required.' : null),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save stock movement', onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(sheetContext, true); }),
        ])),
      ),
    );
    final amount = int.tryParse(quantity.text.trim());
    final note = reason.text.trim();
    quantity.dispose(); reason.dispose();
    if (result != true || amount == null) return;
    try { await widget.repository.changeStock(productId: widget.productId, type: type, quantity: amount, reason: note, performedBy: widget.performedBy); await _load(); } on RepositoryException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message))); }
  }
  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final product = _product;
    if (product == null) return const Scaffold(body: EmptyState(title: 'Product not found.'));
    return Scaffold(backgroundColor: AppColors.warmIvory, appBar: AppBar(title: const Text('Product details'), actions: [IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)), IconButton(onPressed: _archive, icon: Icon(product.isActive ? Icons.archive_outlined : Icons.unarchive_outlined))]), body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(product.name, style: AppTextStyles.headlineMedium)), StatusPill(label: product.isActive ? product.stockStatus.label : 'Archived')]), const SizedBox(height: 12), Text(product.category, style: AppTextStyles.bodyMedium), const SizedBox(height: 8), Text('${product.quantityOnHand} units', style: AppTextStyles.displaySmall), Text('Rs ${product.unitPrice.toStringAsFixed(0)} cost  ·  Low-stock threshold: ${product.lowStockThreshold}', style: AppTextStyles.bodySmall)])),
      const SizedBox(height: 16),
      if (product.isActive) Row(children: [Expanded(child: OutlinedButton(onPressed: () => _stock(InventoryTransactionType.stockIn), child: const Text('Add stock'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => _stock(InventoryTransactionType.stockOut), child: const Text('Remove stock'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => _stock(InventoryTransactionType.adjustment), child: const Text('Adjust')))]),
      const SizedBox(height: 20), Text('Transaction history', style: AppTextStyles.titleLarge), const SizedBox(height: 8),
      AppCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: _history.isEmpty ? const Padding(padding: EdgeInsets.all(10), child: Text('No stock movements yet.')) : Column(children: _history.reversed.map((transaction) => ListTile(contentPadding: EdgeInsets.zero, title: Text('${transaction.type == InventoryTransactionType.stockIn ? '+' : ''}${transaction.quantity} · ${transaction.type.name}'), subtitle: Text('${transaction.reason}  ·  ${transaction.performedBy}\n${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}'), trailing: Text('${transaction.previousQuantity} → ${transaction.newQuantity}'))).toList())),
    ]));
  }
}
