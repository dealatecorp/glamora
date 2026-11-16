import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({super.key, required this.repository, required this.performedBy, this.product});
  final DemoRepository repository;
  final String performedBy;
  final InventoryProduct? product;
  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _categoryController;
  late final TextEditingController _cost;
  late final TextEditingController _quantity;
  late final TextEditingController _threshold;
  late final TextEditingController _reason;
  bool _saving = false;
  bool get _editing => widget.product != null;
  static const _categories = ['Hair', 'Skin / Face', 'Body / Waxing', 'Nails', 'Makeup', 'Wellness', 'Grooming', 'General / Other'];
  @override
  void initState() { super.initState(); final p = widget.product; _name = TextEditingController(text: p?.name); _categoryController = TextEditingController(text: p?.category ?? 'Hair'); _cost = TextEditingController(text: p?.unitPrice.toString()); _quantity = TextEditingController(text: p?.quantityOnHand.toString()); _threshold = TextEditingController(text: p?.lowStockThreshold.toString()); _reason = TextEditingController(); }
  @override
  void dispose() { _name.dispose(); _categoryController.dispose(); _cost.dispose(); _quantity.dispose(); _threshold.dispose(); _reason.dispose(); super.dispose(); }
  String? _number(String? value, String label, {bool decimal = false}) { final n = decimal ? double.tryParse(value ?? '') : int.tryParse(value ?? ''); return n == null || (n is num && n < 0) ? 'Enter a valid non-negative $label.' : null; }
  Future<void> _save() async { if (!(_key.currentState?.validate() ?? false)) return; final quantity = int.parse(_quantity.text); if (_editing && quantity != widget.product!.quantityOnHand && _reason.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give a reason for the quantity adjustment.'))); return; } setState(() => _saving = true); try { if (_editing) { await widget.repository.updateProduct(id: widget.product!.id, name: _name.text, category: _categoryController.text, cost: double.parse(_cost.text), lowStockThreshold: int.parse(_threshold.text), quantity: quantity, adjustmentReason: _reason.text, performedBy: widget.performedBy); } else { await widget.repository.createProduct(name: _name.text, category: _categoryController.text, cost: double.parse(_cost.text), quantity: quantity, lowStockThreshold: int.parse(_threshold.text), performedBy: widget.performedBy); } if (mounted) Navigator.pop(context, true); } on RepositoryException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } finally { if (mounted) setState(() => _saving = false); } }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.warmIvory, appBar: AppBar(title: Text(_editing ? 'Edit product' : 'Add product')), body: Form(key: _key, child: ListView(padding: const EdgeInsets.all(20), children: [TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Product name'), validator: (v) => v == null || v.trim().isEmpty ? 'Product name is required.' : null), const SizedBox(height: 16), TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category / purpose', helperText: 'Select a suggestion or enter a custom category.'), validator: (v) => v == null || v.trim().isEmpty ? 'Category is required.' : null), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 4, children: _categories.map((category) => ActionChip(label: Text(category), onPressed: () => setState(() => _categoryController.text = category))).toList()), const SizedBox(height: 16), TextFormField(controller: _cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cost (Rs)'), validator: (v) => _number(v, 'cost', decimal: true)), const SizedBox(height: 16), TextFormField(controller: _quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _editing ? 'Current quantity' : 'Opening quantity'), validator: (v) => _number(v, 'quantity')), if (_editing) ...[const SizedBox(height: 16), TextFormField(controller: _reason, decoration: const InputDecoration(labelText: 'Adjustment reason (required if quantity changes)'))], const SizedBox(height: 16), TextFormField(controller: _threshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low-stock threshold'), validator: (v) => _number(v, 'threshold')), const SizedBox(height: 28), PrimaryButton(label: _editing ? 'Save changes' : 'Add product', isLoading: _saving, disabled: _saving, onPressed: _save)])));
}
