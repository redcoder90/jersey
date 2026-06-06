import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'product_details_page.dart';
import 'widgets/app_search_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/category_card.dart';
import 'widgets/featured_banner.dart';
import 'widgets/product_card.dart';
import 'package:jerseyapp/models/product.dart';
import 'package:jerseyapp/services/product_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final Set<String> _wishlistedProductIds = {};
  late final Stream<List<Product>> _productsStream = _productService
      .productsStream();

  int _activeCategoryIndex = 0;
  int _activeTabIndex = 0;
  String _searchQuery = '';

  final List<_CategoryOption> _categories = const [
    _CategoryOption(
      label: 'All',
      icon: CategoryIcon(type: CategoryIconType.all),
    ),
    _CategoryOption(
      label: 'Jersey',
      icon: CategoryIcon(type: CategoryIconType.jerseys),
    ),
    _CategoryOption(
      label: 'Socks',
      icon: CategoryIcon(type: CategoryIconType.socks),
    ),
    _CategoryOption(
      label: 'Trainers',
      icon: CategoryIcon(type: CategoryIconType.boots),
    ),
    _CategoryOption(
      label: 'Accessories',
      icon: CategoryIcon(type: CategoryIconType.accessories),
    ),
  ];

  List<Product> _filteredProducts(List<Product> products) {
    final filteredByCategory = _activeCategoryIndex == 0
        ? products
        : products
              .where(
                (product) => _categoryMatches(
                  product,
                  _categories[_activeCategoryIndex].label,
                ),
              )
              .toList();
    if (_searchQuery.isEmpty) {
      return filteredByCategory;
    }
    return filteredByCategory
        .where(
          (product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  bool _categoryMatches(Product product, String categoryLabel) {
    const categoryByLabel = {
      'Jersey': 'jersey',
      'Socks': 'socks',
      'Trainers': 'trainers',
      'Accessories': 'accessories',
    };

    return product.category == categoryByLabel[categoryLabel];
  }

  void _toggleWishlist(String productId) {
    setState(() {
      if (_wishlistedProductIds.contains(productId)) {
        _wishlistedProductIds.remove(productId);
      } else {
        _wishlistedProductIds.add(productId);
      }
    });
  }

  String _formatPrice(double amount) {
    return '৳${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  void _setCategory(int index) {
    setState(() {
      _activeCategoryIndex = index;
    });
  }

  void _setActiveTab(int index) {
    setState(() {
      _activeTabIndex = index;
    });
  }

  void _openProductDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.backgroundDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: BottomNavBar(
        activeIndex: _activeTabIndex,
        onTap: _setActiveTab,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md +
                kBottomNavigationBarHeight +
                MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hey, Jordan',
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.backgroundDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Welcome back to Jersey Drip',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      'J',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSearchBar(
                onChanged: (text) {
                  setState(() {
                    _searchQuery = text;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader('Categories'),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth / 3.6).clamp(
                    100.0,
                    140.0,
                  );
                  return SizedBox(
                    height: 142,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xs,
                        right: AppSpacing.lg,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return SizedBox(
                          width: itemWidth,
                          child: GestureDetector(
                            onTap: () => _setCategory(index),
                            child: CategoryCard(
                              icon: category.icon,
                              label: category.label,
                              active: index == _activeCategoryIndex,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: const FeaturedBanner(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader('Top Products'),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder<List<Product>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Unable to load products',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredProducts = _filteredProducts(snapshot.data!);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final maxItemWidth = availableWidth < 760
                          ? availableWidth / 2.1
                          : availableWidth < 1000
                          ? 240.0
                          : 270.0;
                      final childAspectRatio = availableWidth >= 760
                          ? 0.7
                          : 0.62;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filteredProducts.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxItemWidth,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.lg,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final item = filteredProducts[index];
                          return GestureDetector(
                            key: ValueKey(item.id),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openProductDetails(item),
                            child: ProductCard(
                              imagePath: item.imagePath,
                              name: item.name,
                              price: _formatPrice(item.discountedPrice),
                              originalPrice: item.discountedPrice < item.price
                                  ? _formatPrice(item.price)
                                  : null,
                              wishlisted: _wishlistedProductIds.contains(
                                item.id,
                              ),
                              onWishlistToggle: () => _toggleWishlist(item.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption({required this.label, required this.icon});

  final String label;
  final Widget icon;
}
