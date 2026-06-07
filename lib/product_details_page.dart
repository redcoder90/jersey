import 'package:flutter/material.dart';

import 'order_setup_page.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'models/cart_item.dart';
import 'models/product.dart';
import 'services/cart_service.dart';
import 'services/product_service.dart';
import 'services/wishlist_service.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();
  final WishlistService _wishlistService = WishlistService();

  late final Stream<Set<String>> _wishlistProductIdsStream = _wishlistService
      .wishlistProductIdsStream();
  late final Stream<Product?> _productStream = _productService.productStream(
    product.id,
  );

  late String _selectedSize = _initialSelectedSize();
  int _buyNowQuantity = 1;

  Product get product => widget.product;

  SizeVariant _selectedVariant(Product currentProduct) {
    return currentProduct.variantForSize(_selectedSize) ??
        currentProduct.defaultVariant;
  }

  int _selectedSizePrice(Product currentProduct) {
    return _selectedVariant(currentProduct).price;
  }

  int _selectedSizeStock(Product currentProduct) {
    return _selectedVariant(currentProduct).stock;
  }

  bool _selectedSizeAvailable(Product currentProduct) {
    if (currentProduct.sizes.isEmpty) return false;
    return currentProduct.isSizeAvailable(_selectedSize);
  }

  String _initialSelectedSize() {
    return product.defaultSize;
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

  void _syncSelectionWithProduct(Product currentProduct) {
    if (currentProduct.sizes.isEmpty) return;
    final selectedVariant = currentProduct.variantForSize(_selectedSize);
    if (selectedVariant != null && selectedVariant.stock > 0) {
      if (_buyNowQuantity > selectedVariant.stock) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _buyNowQuantity = selectedVariant.stock;
          });
        });
      }
      return;
    }

    final nextSize = currentProduct.defaultSize;
    final nextStock = currentProduct.variantForSize(nextSize)?.stock ?? 0;
    if (nextSize == _selectedSize && _buyNowQuantity <= nextStock) return;
    if (nextStock <= 0 && nextSize == _selectedSize && _buyNowQuantity == 1) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedSize = nextSize;
        _buyNowQuantity = nextStock > 0
            ? _buyNowQuantity.clamp(1, nextStock).toInt()
            : 1;
      });
    });
  }

  void _selectSize(Product currentProduct, String size) {
    final variant = currentProduct.variantForSize(size);
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
    final currentProduct = await _cartService.currentProduct(product.id);
    if (currentProduct == null || !currentProduct.isAvailable) {
      _showMessage('Product is out of stock');
      return;
    }
    if (!currentProduct.isSizeAvailable(_selectedSize)) {
      _showMessage('Selected size is out of stock');
      return;
    }
    final selectedVariant = currentProduct.variantForSize(_selectedSize)!;

    try {
      await _cartService.addItem(
        productId: currentProduct.id,
        size: _selectedSize,
        name: currentProduct.name,
        price: selectedVariant.price,
        imagePath: currentProduct.imagePath,
      );
      if (!mounted) return;
      _showMessage('${product.name} added to cart');
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Bad state: ', '');
      _showMessage(message.isEmpty ? 'Unable to add product to cart' : message);
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

  void _updateBuyNowQuantity(Product currentProduct, int delta) {
    final nextQuantity = _buyNowQuantity + delta;
    final selectedStock = _selectedSizeStock(currentProduct);
    if (nextQuantity < 1 || nextQuantity > selectedStock) return;

    setState(() {
      _buyNowQuantity = nextQuantity;
    });
  }

  void _buyNow(Product currentProduct) {
    if (!currentProduct.isAvailable) {
      _showMessage('Product is out of stock');
      return;
    }
    final selectedStock = _selectedSizeStock(currentProduct);
    if (!_selectedSizeAvailable(currentProduct)) {
      _showMessage('Selected size is out of stock');
      return;
    }
    if (_buyNowQuantity > selectedStock) {
      _showMessage('Only $selectedStock left in stock');
      return;
    }

    final item = CartItem(
      id: currentProduct.id,
      productId: currentProduct.id,
      size: _selectedSize,
      name: currentProduct.name,
      price: _selectedSizePrice(currentProduct),
      imagePath: currentProduct.imagePath,
      quantity: _buyNowQuantity,
      totalPrice: _selectedSizePrice(currentProduct) * _buyNowQuantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSetupPage(
          items: [item],
          isBuyNow: true,
          sizes: currentProduct.sizes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return StreamBuilder<Product?>(
      stream: _productStream,
      builder: (context, productSnapshot) {
        final currentProduct = productSnapshot.data ?? product;
        _syncSelectionWithProduct(currentProduct);
        final productAvailable = currentProduct.isAvailable;
        final selectedSizeAvailable = _selectedSizeAvailable(currentProduct);
        final selectedSizeStock = _selectedSizeStock(currentProduct);
        final selectedSizePrice = _selectedSizePrice(currentProduct);

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
                    onPressed: selectedSizeAvailable ? _addToCart : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.backgroundDark,
                      disabledForegroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: AppTextStyles.label.copyWith(
                        color: selectedSizeAvailable
                            ? AppColors.backgroundDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedSizeAvailable
                        ? () => _buyNow(currentProduct)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.border,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppColors.textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Buy Now',
                      style: AppTextStyles.label.copyWith(
                        color: selectedSizeAvailable
                            ? Colors.white
                            : AppColors.textSecondary,
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
                          snapshot.data?.contains(currentProduct.id) ?? false;

                      return _ProductImageSection(
                        imagePath: currentProduct.imagePath,
                        wishlisted: isWishlisted,
                        outOfStock: !productAvailable,
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
                          currentProduct.name,
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
                            _formatPrice(selectedSizePrice.toDouble()),
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.backgroundDark,
                              fontSize: 24,
                            ),
                          ),
                          if (selectedSizePrice < currentProduct.price) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _formatPrice(currentProduct.price),
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
                    productAvailable
                        ? _categoryLabel(currentProduct.category)
                        : 'OUT OF STOCK',
                    style: AppTextStyles.label.copyWith(
                      color: productAvailable
                          ? AppColors.textSecondary
                          : AppColors.error,
                      fontWeight: productAvailable
                          ? FontWeight.w400
                          : FontWeight.w800,
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
                    sizes: currentProduct.sizes,
                    onChanged: (size) => _selectSize(currentProduct, size),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    currentProduct.sizes.isEmpty
                        ? 'Size information unavailable'
                        : selectedSizeStock == 0
                        ? 'Out of stock'
                        : 'Only $selectedSizeStock left in stock',
                    style: AppTextStyles.label.copyWith(
                      color:
                          currentProduct.sizes.isEmpty || selectedSizeStock == 0
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
                        ? () => _updateBuyNowQuantity(currentProduct, -1)
                        : null,
                    onIncrease:
                        selectedSizeAvailable &&
                            _buyNowQuantity < selectedSizeStock
                        ? () => _updateBuyNowQuantity(currentProduct, 1)
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
                    currentProduct.description.trim().isNotEmpty
                        ? currentProduct.description
                        : _description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    required this.outOfStock,
    required this.onWishlistToggle,
  });

  final String imagePath;
  final bool wishlisted;
  final bool outOfStock;
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
            left: AppSpacing.md,
            child: outOfStock
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OUT OF STOCK',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
