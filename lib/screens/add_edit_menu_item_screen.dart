import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';

class AddEditMenuItemScreen extends StatefulWidget {
  const AddEditMenuItemScreen({
    super.key,
    this.item,
    this.token,
  });

  /// The item to edit. If null, this screen operates in "Add New Item" mode.
  final MenuItem? item;
  final String? token;

  bool get isEditing => item != null;

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _imageUrlController;
  late String _selectedCategory;
  late bool _available;
  bool _isSaving = false;
  bool _isDeleting = false;

  static const List<String> _categories = [
    'Meals',
    'Snacks',
    'Drinks',
    'Beverages',
    'Desserts',
    'Combos',
  ];

  static const List<String> _prepPresets = [
    '3 min',
    '5 min',
    '8 min',
    '10 min',
    '12 min',
    '15 min',
  ];

  static const List<Map<String, String>> _sampleImages = [
    {
      'label': 'Burger / Wrap',
      'url': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
    },
    {
      'label': 'Rice Bowl',
      'url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
    },
    {
      'label': 'Sandwich',
      'url': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400',
    },
    {
      'label': 'Samosa / Snack',
      'url': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
    },
    {
      'label': 'Cold Coffee',
      'url': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
    },
    {
      'label': 'Dessert / Brownie',
      'url': 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    _prepTimeController = TextEditingController(text: item?.prepTime ?? '10 min');
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    _selectedCategory = item != null && _categories.contains(item.category)
        ? item.category
        : 'Meals';
    _available = item?.available ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid non-negative price.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final menuProvider = context.read<MenuProvider>();

    try {
      if (widget.isEditing) {
        final updated = widget.item!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          price: price,
          prepTime: _prepTimeController.text.trim().isEmpty
              ? '10 min'
              : _prepTimeController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          available: _available,
        );
        await menuProvider.updateItem(updated, token: widget.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${updated.name}" updated successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        final newItem = MenuItem(
          id: '',
          name: _nameController.text.trim(),
          category: _selectedCategory,
          price: price,
          prepTime: _prepTimeController.text.trim().isEmpty
              ? '10 min'
              : _prepTimeController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          available: _available,
        );
        final created = await menuProvider.addItem(newItem, token: widget.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${created.name}" added to menu!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem() async {
    if (widget.item == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text(
          'Are you sure you want to permanently delete "${widget.item!.name}" from the canteen menu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await context.read<MenuProvider>().deleteItem(widget.item!.id, token: widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.item!.name}" deleted.'),
          backgroundColor: Colors.grey.shade800,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Menu Item' : 'Add New Menu Item'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete item',
              onPressed: _isSaving || _isDeleting ? null : _deleteItem,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primaryContainer),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isEditing ? Icons.edit_note : Icons.add_circle_outline,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isEditing
                              ? 'Modify item details and prices'
                              : 'Add delicious new food or drink to the canteen menu',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Masala Dosa, Paneer Roll',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name.';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category & Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Dropdown
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price Field
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price (\$) *',
                          hintText: '3.50',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter price';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prep Time Field & Presets
                TextFormField(
                  controller: _prepTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Prep Time',
                    hintText: 'e.g. 8 min',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _prepPresets.map((preset) {
                    final selected = _prepTimeController.text == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: selected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _prepTimeController.text = preset);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Image URL Field
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.image_outlined),
                    suffixIcon: _imageUrlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _imageUrlController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),

                // Quick image samples selector
                Text(
                  'Quick Image Presets:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sampleImages.map((sample) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: const Icon(Icons.photo_size_select_actual_outlined, size: 16),
                          label: Text(sample['label']!, style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _imageUrlController.text = sample['url']!;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Live Image Preview Card
                if (_imageUrlController.text.trim().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text('Invalid image URL', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Preview',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Available Switch Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Available for Ordering', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _available
                          ? 'Item is visible and students can order it.'
                          : 'Item is marked Out of Stock and cannot be added to cart.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _available,
                    onChanged: (val) => setState(() => _available = val),
                  ),
                ),
                const SizedBox(height: 28),

                // Save Submit Button
                FilledButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _saveItem,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(widget.isEditing ? Icons.save : Icons.add_circle),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : widget.isEditing
                            ? 'Update Menu Item'
                            : 'Add Menu Item',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSaving || _isDeleting ? null : _deleteItem,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text('Delete Menu Item', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
