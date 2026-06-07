import 'package:flutter/material.dart';

import 'order_setup_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/cart_item.dart';
import 'models/product.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();

  late final Stream<Set<String>> _wishlistProductIdsStream = _wishlistService
      .wishlistProductIdsStream();

  late String _selectedSize = _initialSelectedSize();
  int _buyNowQuantity = 1;

  Product get product => widget.product;

  SizeVariant get _selectedVariant =>
      product.variantForSize(_selectedSize) ?? product.defaultVariant;

  int get _selectedSizePrice => _selectedVariant.price;

  int get _selectedSizeStock => _selectedVariant.stock;

  bool get _selectedSizeAvailable => _selectedSizeStock > 0;

  String _initialSelectedSize() {
    final defaultSize = product.defaultSize;
    return defaultSize.isNotEmpty ? defaultSize : 'One Size';
  }

  String _formatPrice(double amount) {
    return '৳${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  String get _description {
    if (product.description.trim().isNotEmpty) {
      return product.description;
    }

    return 'Premium match-day style with a comfortable fit, clean finish, and everyday-ready feel for Jersey Drip shoppers.';
  }

  void _selectSize(String size) {
    final variant = product.variantForSize(size);
    final stock = variant?.stock ?? 0;
    if (stock <= 0) {
      _showMessage('Selected size is out of stock');
      return;
    }

    setState(() {
      _selectedSize = size;
      _buyNowQuantity = _buyNowQuantity.clamp(1, stock).toInt();
    });
  }

  Future<void> _addToCart() async {
    if (!_selectedSizeAvailable) {
      _showMessage('Selected size is out of stock');
      return;
    }

    try {
      await _cartService.addItem(
        productId: product.id,
        size: _selectedSize,
        name: product.name,
        price: _selectedSizePrice,
        imagePath: product.imagePath,
      );
      if (!mounted) return;
      _showMessage('${product.name} added to cart');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to add product to cart');
    }
  }

  Future<void> _toggleWishlist(bool isWishlisted) async {
    try {
      await _wishlistService.toggleProduct(product, isWishlisted: isWishlisted);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to update wishlist');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.backgroundDark,
      ),
    );
  }

  void _updateBuyNowQuantity(int delta) {
    final nextQuantity = _buyNowQuantity + delta;
    if (nextQuantity < 1 || nextQuantity > _selectedSizeStock) return;

    setState(() {
      _buyNowQuantity = nextQuantity;
    });
  }

  void _buyNow() {
    if (!_selectedSizeAvailable) {
      _showMessage('Selected size is out of stock');
      return;
    }
    if (_buyNowQuantity > _selectedSizeStock) {
      _showMessage('Only $_selectedSizeStock left in stock');
      return;
    }

    final item = CartItem(
      id: product.id,
      productId: product.id,
      size: _selectedSize,
      name: product.name,
      price: _selectedSizePrice,
      imagePath: product.imagePath,
      quantity: _buyNowQuantity,
      totalPrice: _selectedSizePrice * _buyNowQuantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OrderSetupPage(items: [item], isBuyNow: true, sizes: product.sizes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: AppColors.backgroundDark,
        centerTitle: true,
        title: Text(
          'Details',
          style: AppTextStyles.label.copyWith(
            color: AppColors.backgroundDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + bottomPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedSizeAvailable ? _addToCart : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.backgroundDark,
                  disabledForegroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Add to Cart',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.backgroundDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedSizeAvailable ? _buyNow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Buy Now',
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<Set<String>>(
                stream: _wishlistProductIdsStream,
                builder: (context, snapshot) {
                  final isWishlisted =
                      snapshot.data?.contains(product.id) ?? false;

                  return _ProductImageSection(
                    imagePath: product.imagePath,
                    wishlisted: isWishlisted,
                    onWishlistToggle: () => _toggleWishlist(isWishlisted),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.backgroundDark,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(_selectedSizePrice.toDouble()),
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.backgroundDark,
                          fontSize: 24,
                        ),
                      ),
                      if (_selectedSizePrice < product.price) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _formatPrice(product.price),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _categoryLabel(product.category),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Select Size',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProductSizeDropdown(
                value: _selectedSize,
                sizes: product.sizes,
                onChanged: _selectSize,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _selectedSizeStock == 0
                    ? 'Out of stock'
                    : 'Only $_selectedSizeStock left in stock',
                style: AppTextStyles.label.copyWith(
                  color: _selectedSizeStock == 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quantity',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuantitySelector(
                quantity: _buyNowQuantity,
                onDecrease: _buyNowQuantity > 1
                    ? () => _updateBuyNowQuantity(-1)
                    : null,
                onIncrease:
                    _selectedSizeAvailable &&
                        _buyNowQuantity < _selectedSizeStock
                    ? () => _updateBuyNowQuantity(1)
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Description',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.backgroundDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _description,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    if (category.isEmpty) {
      return 'Product';
    }

    return category[0].toUpperCase() + category.substring(1);
  }
}

class _ProductImageSection extends StatelessWidget {
  const _ProductImageSection({
    required this.imagePath,
    required this.wishlisted,
    required this.onWishlistToggle,
  });

  final String imagePath;
  final bool wishlisted;
  final VoidCallback onWishlistToggle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 56),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Material(
              color: AppColors.surface.withAlpha(230),
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: AppColors.shadow,
              child: IconButton(
                tooltip: 'Wishlist',
                onPressed: onWishlistToggle,
                icon: Icon(
                  wishlisted ? Icons.favorite : Icons.favorite_border,
                  color: wishlisted ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSizeDropdown extends StatelessWidget {
  const _ProductSizeDropdown({
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

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(icon: Icons.remove, onPressed: onDecrease),
        SizedBox(
          width: 48,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: AppColors.backgroundDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _QuantityButton(icon: Icons.add, onPressed: onIncrease),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.backgroundDark,
          disabledForegroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}
