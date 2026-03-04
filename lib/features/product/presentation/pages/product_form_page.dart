import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../bloc/product_bloc.dart';

class ProductFormPage extends StatefulWidget {
  final ProductEntity? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  final _newCatCtrl = TextEditingController();

  String? _selectedCategoryId;
  String? _imageUrl;
  File? _pickedImage;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _showNewCatField = false;
  // Auto-select pending category after stream update
  String? _pendingSelectCategoryName;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? CurrencyFormatter.formatRupiah(p.price) : '');
    _costCtrl = TextEditingController(
        text: p != null ? CurrencyFormatter.formatRupiah(p.costPrice) : '');
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '');
    _minStockCtrl = TextEditingController(text: p?.minStock.toString() ?? '0');
    _selectedCategoryId = p?.categoryId;
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _newCatCtrl.dispose();
    super.dispose();
  }

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _isUploadingImage = true;
    });

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final client = Supabase.instance.client;
      await client.storage.from('product-images').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );
      final publicUrl =
          client.storage.from('product-images').getPublicUrl(fileName);
      setState(() {
        _imageUrl = publicUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah gambar: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Category ──────────────────────────────────────────────────────────────

  void _addNewCategory(List<CategoryEntity> existing) {
    final name = _newCatCtrl.text.trim();
    if (name.isEmpty) return;

    if (existing.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori sudah ada')),
      );
      return;
    }

    // Dispatch to bloc; stream will auto-update categories list
    _pendingSelectCategoryName = name;
    context.read<ProductBloc>().add(AddCategory(name));
    setState(() {
      _showNewCatField = false;
      _newCatCtrl.clear();
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit(List<CategoryEntity> categories) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pilih atau buat kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final price = CurrencyFormatter.parseRupiah(_priceCtrl.text);
    final cost = CurrencyFormatter.parseRupiah(_costCtrl.text);
    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    final minStock = int.tryParse(_minStockCtrl.text) ?? 0;

    if (_isEditing) {
      context.read<ProductBloc>().add(
            UpdateProduct(
              UpdateProductParams(
                id: widget.product!.id,
                name: _nameCtrl.text.trim(),
                price: price,
                costPrice: cost,
                stock: stock,
                minStock: minStock,
                categoryId: _selectedCategoryId!,
                imageUrl: _imageUrl,
              ),
            ),
          );
    } else {
      context.read<ProductBloc>().add(
            AddProduct(
              AddProductParams(
                name: _nameCtrl.text.trim(),
                price: price,
                costPrice: cost,
                stock: stock,
                minStock: minStock,
                categoryId: _selectedCategoryId!,
                imageUrl: _imageUrl,
              ),
            ),
          );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductActionSuccess) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing
                  ? 'Produk berhasil diperbarui'
                  : 'Produk berhasil ditambahkan'),
            ),
          );
          Navigator.pop(context);
        } else if (state is ProductError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ProductLoaded && _pendingSelectCategoryName != null) {
          // Auto-select newly added category
          final match = state.categories.where(
            (c) => c.name.toLowerCase() == _pendingSelectCategoryName!.toLowerCase(),
          );
          if (match.isNotEmpty) {
            setState(() {
              _selectedCategoryId = match.first.id;
              _pendingSelectCategoryName = null;
            });
          }
        }
      },
      builder: (context, state) {
        final categories = state is ProductLoaded
            ? state.categories
            : (state is ProductActionSuccess
                ? state.categories
                : <CategoryEntity>[]);

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: () => _submit(categories),
                  child: const Text('Simpan'),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Image ────────────────────────────────────────────────
                _ImagePickerWidget(
                  imageUrl: _imageUrl,
                  pickedFile: _pickedImage,
                  isUploading: _isUploadingImage,
                  onTap: _showImageSourceSheet,
                ),
                const SizedBox(height: 20),

                // ── Nama Produk ──────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    hintText: 'Contoh: Nasi Goreng Spesial',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    if (v.trim().length < 2) {
                      return 'Nama produk minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Kategori ─────────────────────────────────────────────
                _CategorySection(
                  categories: categories,
                  selectedId: _selectedCategoryId,
                  showNewField: _showNewCatField,
                  newCatController: _newCatCtrl,
                  onCategorySelected: (id) =>
                      setState(() => _selectedCategoryId = id),
                  onToggleNewField: () =>
                      setState(() => _showNewCatField = !_showNewCatField),
                  onAddCategory: () => _addNewCategory(categories),
                ),
                const SizedBox(height: 16),

                // ── Harga Jual ───────────────────────────────────────────
                _RupiahField(
                  controller: _priceCtrl,
                  label: 'Harga Jual',
                  validator: (v) {
                    final val = CurrencyFormatter.parseRupiah(v ?? '');
                    if (val <= 0) return 'Harga jual harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Harga Modal ──────────────────────────────────────────
                _RupiahField(
                  controller: _costCtrl,
                  label: 'Harga Modal',
                  validator: (v) {
                    final val = CurrencyFormatter.parseRupiah(v ?? '');
                    if (val < 0) return 'Harga modal tidak boleh negatif';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Stok & Min Stok ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal',
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Stok tidak boleh kosong';
                          }
                          final val = int.tryParse(v);
                          if (val == null || val < 0) {
                            return 'Stok tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Minimal Stok',
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final val = int.tryParse(v);
                          if (val == null || val < 0) {
                            return 'Nilai tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Save Button ──────────────────────────────────────────
                FilledButton(
                  onPressed: _isSaving ? null : () => _submit(categories),
                  child:
                      Text(_isEditing ? 'Perbarui Produk' : 'Simpan Produk'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Image Picker Widget ───────────────────────────────────────────────────────

class _ImagePickerWidget extends StatelessWidget {
  final String? imageUrl;
  final File? pickedFile;
  final bool isUploading;
  final VoidCallback onTap;

  const _ImagePickerWidget({
    this.imageUrl,
    this.pickedFile,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isUploading
              ? const Center(child: CircularProgressIndicator())
              : pickedFile != null
                  ? Image.file(pickedFile!, fit: BoxFit.cover,
                      width: double.infinity)
                  : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(imageUrl!, fit: BoxFit.cover,
                          width: double.infinity)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'Tambah Foto Produk',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}

// ── Rupiah Text Field ─────────────────────────────────────────────────────────

class _RupiahField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;

  const _RupiahField({
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        prefixText: 'Rp ',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [_RupiahInputFormatter()],
      validator: validator,
    );
  }
}

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final value = int.tryParse(digits) ?? 0;
    final formatted = _formatWithDots(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    final remainder = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - remainder) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ── Category Section ──────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;
  final bool showNewField;
  final TextEditingController newCatController;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onToggleNewField;
  final VoidCallback onAddCategory;

  const _CategorySection({
    required this.categories,
    required this.selectedId,
    required this.showNewField,
    required this.newCatController,
    required this.onCategorySelected,
    required this.onToggleNewField,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: categories.any((c) => c.id == selectedId) ? selectedId : null,
          decoration: const InputDecoration(labelText: 'Kategori'),
          hint: const Text('Pilih kategori'),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) onCategorySelected(v);
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onToggleNewField,
          icon: Icon(showNewField ? Icons.close : Icons.add_rounded, size: 18),
          label: Text(showNewField ? 'Batal' : 'Buat Kategori Baru'),
        ),
        if (showNewField) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: newCatController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori Baru',
                    hintText: 'Contoh: Minuman',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (_) => onAddCategory(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAddCategory,
                child: const Text('Tambah'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
