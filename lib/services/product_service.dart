import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Product>> productsStream() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      final products = snapshot.docs.map(_productFromDocument).toList();
      return _removeDuplicateProducts(products);
    });
  }

  Stream<Product?> productStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return _productFromSnapshot(snapshot.id, data);
    });
  }

  List<Product> _removeDuplicateProducts(List<Product> products) {
    final seenProductKeys = <String>{};
    final uniqueProducts = <Product>[];

    for (final product in products) {
      final productKey = _productIdentityKey(product);

      if (seenProductKeys.contains(productKey)) {
        debugPrint('Duplicate product hidden: ${product.name}');
        continue;
      }

      seenProductKeys.add(productKey);
      uniqueProducts.add(product);
    }

    return uniqueProducts;
  }

  String _productIdentityKey(Product product) {
    final normalizedImagePath = _normalizeImagePath(product.imagePath);

    if (normalizedImagePath.isNotEmpty) {
      return 'image:$normalizedImagePath';
    }

    return 'name:${product.name.trim().toLowerCase()}';
  }

  Product _productFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return _productFromSnapshot(document.id, document.data());
  }

  Product _productFromSnapshot(String documentId, Map<String, dynamic> data) {
    final price = _readDouble(data['price']);
    final stockQuantity = _readInt(
      _readFirstValue(data, const [
        'quantity',
        'stockQuantity',
        'stockquantity',
        'stock_quantity',
        'stock',
      ]),
    );
    final sizes = _readSizeVariants(
      data['sizes'],
      fallbackPrice: price.round(),
      fallbackStock: stockQuantity,
    );
    final originalPrice = _readNullableDouble(
      _readFirstValue(data, const [
        'originalPrice',
        'originalprice',
        'original_price',
        'original price',
      ]),
    );
    final imagePath = _normalizeImagePath(
      _readFirstValue(data, const [
        'imagePath',
        'imagepath',
        'image_path',
        'image path',
        'image',
        'assetPath',
        'asset_path',
        'asset path',
        'path',
        'imageUrl',
        'imageURL',
      ]),
    );

    if (imagePath.isEmpty) {
      debugPrint('PRODUCT IMAGE PATH MISSING');
      debugPrint('Product document id: $documentId');
      debugPrint('Available fields: ${data.keys.join(', ')}');
    }

    return Product(
      id: documentId,
      name: _readString(data['name'], fallback: 'Unnamed Product'),
      description: _readString(data['description']),
      price: originalPrice ?? price,
      discountedPrice: price,
      category: _normalizeCategory(data['category']),
      brand: _readString(data['brand']),
      imagePath: imagePath,
      stockQuantity: stockQuantity,
      sizes: sizes,
      featured: data['featured'] == true,
      createdAt: _readDateTime(data['createdAt']),
    );
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }

  Object? _readFirstValue(Map<String, dynamic> data, List<String> keys) {
    final normalizedDataKeys = {
      for (final key in data.keys) _normalizeFieldName(key): key,
    };

    for (final key in keys) {
      final dataKey = data.containsKey(key)
          ? key
          : normalizedDataKeys[_normalizeFieldName(key)];
      if (dataKey == null) {
        continue;
      }

      final value = data[dataKey];
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String _normalizeFieldName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  double _readDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  double? _readNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  Map<String, SizeVariant> _readSizeVariants(
    Object? value, {
    required int fallbackPrice,
    required int fallbackStock,
  }) {
    if (value is Map) {
      final variants = <String, SizeVariant>{};
      for (final entry in value.entries) {
        final size = entry.key.toString().trim();
        if (size.isEmpty) continue;

        final rawVariant = entry.value;
        if (rawVariant is Map) {
          variants[size] = SizeVariant(
            price: _readInt(rawVariant['price'], fallback: fallbackPrice),
            stock: _readInt(rawVariant['stock'], fallback: fallbackStock),
          );
        }
      }
      if (variants.isNotEmpty) return variants;
    }

    if (value is Iterable) {
      final labels = value
          .whereType<String>()
          .map((size) => size.trim())
          .where((size) => size.isNotEmpty)
          .toList();
      if (labels.isNotEmpty) {
        return {
          for (final size in labels)
            size: SizeVariant(price: fallbackPrice, stock: fallbackStock),
        };
      }
    }

    return const <String, SizeVariant>{};
  }

  DateTime _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _normalizeCategory(Object? value) {
    final category = _readString(value).toLowerCase();

    const categories = {
      'jersey': 'jersey',
      'jerseys': 'jersey',
      'socks': 'socks',
      'trainers': 'trainers',
      'accessories': 'accessories',
    };

    return categories[category] ?? category;
  }

  String _normalizeImagePath(Object? value) {
    var path = _readString(value).replaceAll(r'\', '/');

    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.startsWith('assets/')) {
      path = path.substring('assets/'.length);
    }

    return path;
  }
}
