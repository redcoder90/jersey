import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/cart_item.dart';
import 'models/product.dart';
import 'services/cart_service.dart';

class OrderSetupPage extends StatefulWidget {
  const OrderSetupPage({
    super.key,
    required this.items,
    required this.isBuyNow,
    this.sizes,
  });

  final List<CartItem> items;
  final bool isBuyNow;
  final Map<String, SizeVariant>? sizes;

  @override
  State<OrderSetupPage> createState() => _OrderSetupPageState();
}

class _OrderSetupPageState extends State<OrderSetupPage> {
  final _addressController = TextEditingController();
  final _cartService = CartService();
  bool _isLoadingAddress = true;
  String _selectedSize = 'M';

  List<CartItem> get _items => _itemsState;
  late List<CartItem> _itemsState;

  @override
  void initState() {
    super.initState();
    _itemsState = widget.items.map((item) => item).toList(growable: true);
    final firstItemSize = widget.items.isEmpty ? '' : widget.items.first.size;
    final defaultSize = widget.sizes == null
        ? ''
        : getSmallestAvailableSize(widget.sizes!);
    _selectedSize = firstItemSize.isNotEmpty
        ? firstItemSize
        : defaultSize.isNotEmpty
        ? defaultSize
        : 'M';
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingAddress = false;
      });
      return;
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = document.data();
      final address = data != null && data['address'] is String
          ? (data['address'] as String).trim()
          : '';

      if (address.isNotEmpty) {
        _addressController.text = address;
      }
    } catch (_) {
      // Ignore failures: address entry remains manual.
    }

    if (!mounted) return;
    setState(() {
      _isLoadingAddress = false;
    });
  }

  String _formatPrice(int amount) => '৳$amount';

  void _updateQuantity(int index, int delta) {
    final item = _itemsState[index];
    final newQuantity = item.quantity + delta;
    if (newQuantity < 1) return;
    final stockLimit = _stockLimitForItem(item);
    if (stockLimit != null && newQuantity > stockLimit) return;

    setState(() {
      _itemsState[index] = item.copyWith(
        quantity: newQuantity,
        totalPrice: item.price * newQuantity,
      );
    });
  }

  void _selectSize(String size) {
    final variant = widget.sizes?[size];
    if (variant == null || _itemsState.isEmpty) return;
    if (variant.stock <= 0) {
      _showMessage('Selected size is out of stock');
      return;
    }

    final item = _itemsState.first;
    final quantity = item.quantity > variant.stock
        ? variant.stock
        : item.quantity;

    setState(() {
      _selectedSize = size;
      _itemsState[0] = item.copyWith(
        size: size,
        price: variant.price,
        quantity: quantity < 1 ? 1 : quantity,
        totalPrice: variant.price * (quantity < 1 ? 1 : quantity),
      );
    });
  }

  Future<void> _proceedToCheckout() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showMessage('Please enter a delivery address');
      return;
    }
    if (widget.isBuyNow && _itemsState.first.size.isEmpty) {
      _showMessage('Please select a size');
      return;
    }

    try {
      await _cartService.validateItemsInStock(_itemsState);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Bad state: ', ''));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutPage(items: _itemsState)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.backgroundDark,
      ),
    );
  }

  Widget _buildSizeSection() {
    final sizes = widget.sizes ?? const <String, SizeVariant>{};
    if (sizes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Size',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BuyNowSizeDropdown(
          value: _selectedSize,
          sizes: sizes,
          onChanged: _selectSize,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _selectedStock == 0
              ? 'Out of stock'
              : 'Only $_selectedStock left available',
          style: AppTextStyles.label.copyWith(
            color: _selectedStock == 0 ? AppColors.error : AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildBuyNowSummary() {
    final item = _items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  item.imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.backgroundDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _formatPrice(item.price),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.size.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Size ${item.size}',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSizeSection(),
        const SizedBox(height: AppSpacing.lg),
        _buildBuyNowQuantitySelector(item),
      ],
    );
  }

  Widget _buildBuyNowQuantitySelector(CartItem item) {
    final stockLimit = _stockLimitForItem(item) ?? item.quantity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quantity',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: item.quantity > 1
                  ? () => _updateQuantity(0, -1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.accent,
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: item.quantity < stockLimit
                  ? () => _updateQuantity(0, 1)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.accent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCartSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Items Summary',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.backgroundDark,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        item.imagePath,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.backgroundDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _formatPrice(item.price),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (item.size.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Size ${item.size}',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _updateQuantity(index, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.accent,
                        ),
                        Text('${item.quantity}', style: AppTextStyles.body),
                        IconButton(
                          onPressed: () => _updateQuantity(index, 1),
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    Text(
                      _formatPrice(item.totalPrice),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.backgroundDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Delivery Address',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_isLoadingAddress)
          const LinearProgressIndicator()
        else
          TextField(
            controller: _addressController,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: 'Enter your delivery address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        if (!_isLoadingAddress && _addressController.text.isNotEmpty)
          Text(
            'Address loaded from your profile. You can make edits before checkout.',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          )
        else if (!_isLoadingAddress)
          Text(
            'Please add a delivery address to continue.',
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  int get _selectedStock => widget.sizes?[_selectedSize]?.stock ?? 0;

  int? _stockLimitForItem(CartItem item) {
    if (!widget.isBuyNow) return null;
    if (item.size.isEmpty) return null;
    return widget.sizes?[item.size]?.stock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
        title: Text(
          'Order Setup',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.isBuyNow && _items.length == 1) ...[
              _buildBuyNowSummary(),
            ] else ...[
              _buildCartSummary(),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildAddressSection(),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order total',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatPrice(
                            _items.fold(
                              0,
                              (sum, item) => sum + item.totalPrice,
                            ),
                          ),
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _proceedToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Proceed to Checkout',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyNowSizeDropdown extends StatelessWidget {
  const _BuyNowSizeDropdown({
    required this.value,
    required this.sizes,
    required this.onChanged,
  });

  final String value;
  final Map<String, SizeVariant> sizes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = sortedSizeKeys(sizes);
    final dropdownValue = options.contains(value) ? value : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: dropdownValue,
            isExpanded: true,
            hint: Text(
              'Select size',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            items: options.map((size) {
              final stock = sizes[size]?.stock ?? 0;
              return DropdownMenuItem<String>(
                value: size,
                enabled: stock > 0,
                child: Text(
                  stock > 0 ? size : '$size - Out of stock',
                  style: AppTextStyles.label.copyWith(
                    color: stock > 0
                        ? AppColors.backgroundDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
            onChanged: (size) {
              if (size == null || size == value) return;
              onChanged(size);
            },
          ),
        ),
      ),
    );
  }
}
