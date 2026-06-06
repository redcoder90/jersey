import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'widgets/app_search_bar.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/category_card.dart';
import 'widgets/featured_banner.dart';
import 'widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeCategoryIndex = 0;
  int _activeTabIndex = 0;
  String _searchQuery = '';

  final List<_CategoryOption> _categories = const [
    _CategoryOption(
      label: 'All',
      icon: CategoryIcon(type: CategoryIconType.all),
    ),
    _CategoryOption(
      label: 'Jerseys',
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

  final List<ProductItem> _products = [
    ProductItem(
      name: 'Barcelona Home Jersey',
      category: 'Jerseys',
      price: '\$120',
      imageUrl:
          'https://images.pexels.com/photos/4171652/pexels-photo-4171652.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Real Madrid Away Jersey',
      category: 'Jerseys',
      price: '\$115',
      imageUrl:
          'https://images.pexels.com/photos/208744/pexels-photo-208744.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Manchester City Home Jersey',
      category: 'Jerseys',
      price: '\$125',
      imageUrl:
          'https://images.pexels.com/photos/1183266/pexels-photo-1183266.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Liverpool Home Jersey',
      category: 'Jerseys',
      price: '\$130',
      imageUrl:
          'https://images.pexels.com/photos/1595381/pexels-photo-1595381.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Arsenal Third Kit',
      category: 'Jerseys',
      price: '\$110',
      imageUrl:
          'https://images.pexels.com/photos/77720/pexels-photo-77720.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'PSG Home Jersey',
      category: 'Jerseys',
      price: '\$140',
      imageUrl:
          'https://images.pexels.com/photos/3985325/pexels-photo-3985325.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Velocity Performance Socks',
      category: 'Socks',
      price: '\$18',
      imageUrl:
          'https://images.pexels.com/photos/1250650/pexels-photo-1250650.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Impact Football Boots',
      category: 'Trainers',
      price: '\$220',
      imageUrl:
          'https://images.pexels.com/photos/267111/pexels-photo-267111.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
    ProductItem(
      name: 'Team Essentials Backpack',
      category: 'Accessories',
      price: '\$62',
      imageUrl:
          'https://images.pexels.com/photos/1201820/pexels-photo-1201820.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940',
    ),
  ];

  late final List<bool> _wishlisted;

  @override
  void initState() {
    super.initState();
    _wishlisted = List.filled(_products.length, false);
  }

  List<ProductItem> get _filteredProducts {
    final filteredByCategory = _activeCategoryIndex == 0
        ? _products
        : _products
              .where(
                (product) =>
                    product.category == _categories[_activeCategoryIndex].label,
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

  void _toggleWishlist(int index) {
    setState(() {
      _wishlisted[index] = !_wishlisted[index];
    });
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

  Widget _buildSectionHeader(
    String title, {
    required VoidCallback onRightTap,
    required String rightLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.backgroundDark,
          ),
        ),
        GestureDetector(
          onTap: onRightTap,
          child: Text(
            rightLabel,
            style: AppTextStyles.body.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
              _buildSectionHeader(
                'Categories',
                onRightTap: () {},
                rightLabel: 'See All',
              ),
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
              const FeaturedBanner(),
              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(
                'Top Products',
                onRightTap: () {},
                rightLabel: 'See All',
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final maxItemWidth = availableWidth < 760
                        ? availableWidth / 2.1
                        : availableWidth < 1000
                        ? 240.0
                        : 270.0;
                    final childAspectRatio = availableWidth >= 760 ? 0.7 : 0.62;
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      itemCount: _filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxItemWidth,
                        mainAxisSpacing: AppSpacing.lg,
                        crossAxisSpacing: AppSpacing.lg,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final item = _filteredProducts[index];
                        final originalIndex = _products.indexOf(item);
                        return ProductCard(
                          imageUrl: item.imageUrl,
                          name: item.name,
                          price: item.price,
                          wishlisted: _wishlisted[originalIndex],
                          onWishlistToggle: () =>
                              _toggleWishlist(originalIndex),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
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

class ProductItem {
  ProductItem({
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
  });

  final String name;
  final String category;
  final String price;
  final String imageUrl;
}
