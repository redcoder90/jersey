class SizeVariant {
  const SizeVariant({required this.price, required this.stock});

  final int price;
  final int stock;
}

const List<String> _letterSizeOrder = ['S', 'M', 'L', 'XL'];

String getSmallestAvailableSize(Map<String, SizeVariant> sizes) {
  final orderedSizes = sortedSizeKeys(sizes);
  for (final size in orderedSizes) {
    if ((sizes[size]?.stock ?? 0) > 0) {
      return size;
    }
  }

  return orderedSizes.isEmpty ? '' : orderedSizes.first;
}

List<String> sortedSizeKeys(Map<String, SizeVariant> sizes) {
  final keys = sizes.keys.toList(growable: false);
  keys.sort(_compareSizes);
  return keys;
}

int _compareSizes(String left, String right) {
  final leftNumber = int.tryParse(left);
  final rightNumber = int.tryParse(right);
  if (leftNumber != null && rightNumber != null) {
    return leftNumber.compareTo(rightNumber);
  }

  final leftLetterIndex = _letterSizeOrder.indexOf(left.toUpperCase());
  final rightLetterIndex = _letterSizeOrder.indexOf(right.toUpperCase());
  if (leftLetterIndex != -1 && rightLetterIndex != -1) {
    return leftLetterIndex.compareTo(rightLetterIndex);
  }
  if (leftLetterIndex != -1) return -1;
  if (rightLetterIndex != -1) return 1;

  return left.compareTo(right);
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double discountedPrice;
  final String category;
  final String brand;
  final String imagePath;
  final int stockQuantity;
  final Map<String, SizeVariant> sizes;
  final bool featured;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.discountedPrice,
    required this.category,
    required this.brand,
    required this.imagePath,
    required this.stockQuantity,
    required this.sizes,
    required this.featured,
    required this.createdAt,
  });

  List<String> get sizeOptions => sortedSizeKeys(sizes);

  SizeVariant? variantForSize(String size) => sizes[size];

  SizeVariant get defaultVariant {
    if (sizes.isEmpty) {
      return SizeVariant(price: discountedPrice.round(), stock: stockQuantity);
    }

    return sizes[defaultSize] ?? sizes.values.first;
  }

  String get defaultSize {
    if (sizes.isEmpty) return 'One Size';
    return getSmallestAvailableSize(sizes);
  }
}
