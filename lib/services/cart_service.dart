import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  CartService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<List<CartItem>> cartStream() {
    final uid = _requireUid();

    return _cartCollection(uid).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(CartItem.fromDocument).toList(growable: false),
    );
  }

  Future<void> addProduct(Product product) async {
    final variant = product.defaultVariant;
    return addItem(
      productId: product.id,
      size: product.defaultSize,
      name: product.name,
      price: variant.price,
      imagePath: product.imagePath,
    );
  }

  Future<void> addItem({
    required String productId,
    required String size,
    required String name,
    required int price,
    required String imagePath,
    int quantity = 1,
  }) async {
    final uid = _requireUid();
    final normalizedSize = size.trim();
    final document = _cartCollection(
      uid,
    ).doc(_cartDocumentId(productId, normalizedSize));
    final productDocument = _firestore.collection('products').doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      final stock = productData == null
          ? null
          : _stockForProductSelection(productData, normalizedSize);

      if (snapshot.exists) {
        final data = snapshot.data();
        final currentQuantity = _readInt(data?['quantity'], fallback: 1);
        final cartPrice = _readInt(data?['price'], fallback: price);
        final nextQuantity = currentQuantity + quantity;
        if (stock != null && nextQuantity > stock) {
          throw StateError('Only $stock left in stock');
        }

        transaction.update(document, {
          'quantity': nextQuantity,
          'totalPrice': cartPrice * nextQuantity,
        });
        return;
      }

      if (stock != null && quantity > stock) {
        throw StateError('Only $stock left in stock');
      }

      transaction.set(document, {
        'productId': productId,
        'size': normalizedSize,
        'name': name,
        'price': price,
        'imagePath': imagePath,
        'quantity': quantity,
        'totalPrice': price * quantity,
      });
    });
  }

  Future<void> updateQuantity(
    String productId,
    int quantity, {
    String size = '',
  }) async {
    final uid = _requireUid();
    final nextQuantity = quantity < 1 ? 1 : quantity;
    final document = _cartCollection(uid).doc(_cartDocumentId(productId, size));
    final productDocument = _firestore.collection('products').doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();
      final price = _readInt(data?['price']);
      final cartSize = _readString(data?['size'], fallback: size);
      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      final stock = productData == null
          ? null
          : _stockForProductSelection(productData, cartSize);
      if (stock != null && nextQuantity > stock) {
        throw StateError('Only $stock left in stock');
      }

      transaction.update(document, {
        'quantity': nextQuantity,
        'totalPrice': price * nextQuantity,
      });
    });
  }

  Future<void> updateSize(CartItem item, String size) async {
    final uid = _requireUid();
    final nextSize = size.trim();
    if (nextSize.isEmpty || nextSize == item.size) return;

    final currentDocument = _cartCollection(
      uid,
    ).doc(_cartDocumentId(item.productId, item.size));
    final nextDocument = _cartCollection(
      uid,
    ).doc(_cartDocumentId(item.productId, nextSize));
    final productDocument = _firestore
        .collection('products')
        .doc(item.productId);

    await _firestore.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentDocument);
      if (!currentSnapshot.exists) return;

      final productSnapshot = await transaction.get(productDocument);
      final productData = productSnapshot.data();
      if (productData == null) return;

      final variant = _variantForProductSelection(productData, nextSize);
      if (variant == null || variant.stock <= 0) {
        throw StateError('Selected size is out of stock');
      }

      final targetSnapshot = await transaction.get(nextDocument);
      final targetQuantity = targetSnapshot.exists
          ? _readInt(targetSnapshot.data()?['quantity'], fallback: 1)
          : 0;
      final nextQuantity = targetQuantity + item.quantity;
      if (nextQuantity > variant.stock) {
        throw StateError('Only ${variant.stock} left in stock');
      }

      if (targetSnapshot.exists) {
        transaction.update(nextDocument, {
          'quantity': nextQuantity,
          'price': variant.price,
          'totalPrice': variant.price * nextQuantity,
        });
        transaction.delete(currentDocument);
        return;
      }

      transaction.update(currentDocument, {
        'size': nextSize,
        'price': variant.price,
        'totalPrice': variant.price * item.quantity,
      });
    });
  }

  Stream<Map<String, SizeVariant>> productSizesStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) return const <String, SizeVariant>{};

      return _readSizeVariants(
        data['sizes'],
        fallbackPrice: _readInt(data['price']),
        fallbackStock: _readInt(
          data['quantity'] ??
              data['stockQuantity'] ??
              data['stockquantity'] ??
              data['stock_quantity'] ??
              data['stock'],
        ),
        category: _readString(data['category']),
      );
    });
  }

  Future<void> removeItem(String productId, {String size = ''}) {
    final uid = _requireUid();
    return _cartCollection(uid).doc(_cartDocumentId(productId, size)).delete();
  }

  Future<void> validateItemsInStock(List<CartItem> items) async {
    for (final item in items) {
      final snapshot = await _firestore
          .collection('products')
          .doc(item.productId)
          .get();
      final data = snapshot.data();
      if (data == null) continue;

      final stock = _stockForCartItem(data, item);
      if (item.quantity > stock) {
        final sizeText = item.size.isEmpty ? '' : ' (${item.size})';
        throw StateError('Only $stock ${item.name}$sizeText left in stock');
      }
    }
  }

  CollectionReference<Map<String, dynamic>> _cartCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('cart');
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('A signed-in user is required to access the cart.');
    }
    return uid;
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

  int _stockForCartItem(Map<String, dynamic> data, CartItem item) {
    final sizes = data['sizes'];
    if (sizes is Map && item.size.isNotEmpty) {
      final variant = sizes[item.size];
      if (variant is Map) {
        return _readInt(variant['stock']);
      }
    }

    return _readInt(
      data['quantity'] ??
          data['stockQuantity'] ??
          data['stockquantity'] ??
          data['stock_quantity'] ??
          data['stock'],
    );
  }

  int? _stockForProductSelection(Map<String, dynamic> data, String size) {
    final variant = _variantForProductSelection(data, size);
    if (variant != null) return variant.stock;

    final stock =
        data['quantity'] ??
        data['stockQuantity'] ??
        data['stockquantity'] ??
        data['stock_quantity'] ??
        data['stock'];
    return stock == null ? null : _readInt(stock);
  }

  SizeVariant? _variantForProductSelection(
    Map<String, dynamic> data,
    String size,
  ) {
    final sizes = data['sizes'];
    if (sizes is Map && size.isNotEmpty) {
      final variant = sizes[size];
      if (variant is Map) {
        return SizeVariant(
          price: _readInt(variant['price'], fallback: _readInt(data['price'])),
          stock: _readInt(variant['stock']),
        );
      }
    }

    return _readSizeVariants(
      sizes,
      fallbackPrice: _readInt(data['price']),
      fallbackStock: _readInt(
        data['quantity'] ??
            data['stockQuantity'] ??
            data['stockquantity'] ??
            data['stock_quantity'] ??
            data['stock'],
      ),
      category: _readString(data['category']),
    )[size];
  }

  Map<String, SizeVariant> _readSizeVariants(
    Object? value, {
    required int fallbackPrice,
    required int fallbackStock,
    required String category,
  }) {
    if (value is Map) {
      final variants = value.map((key, rawVariant) {
        final size = key.toString().trim();
        if (rawVariant is Map) {
          return MapEntry(
            size,
            SizeVariant(
              price: _readInt(rawVariant['price'], fallback: fallbackPrice),
              stock: _readInt(rawVariant['stock'], fallback: fallbackStock),
            ),
          );
        }

        return MapEntry(
          size,
          SizeVariant(price: fallbackPrice, stock: fallbackStock),
        );
      })..removeWhere((key, _) => key.isEmpty);
      if (variants.isNotEmpty) return variants;
    }

    return _defaultSizeVariantsForCategory(
      category,
      price: fallbackPrice,
      stock: fallbackStock,
    );
  }

  Map<String, SizeVariant> _defaultSizeVariantsForCategory(
    String category, {
    required int price,
    required int stock,
  }) {
    final normalizedCategory = category.toLowerCase();
    final labels = switch (normalizedCategory) {
      'jersey' => const ['S', 'M', 'L', 'XL'],
      'socks' => const ['S', 'M', 'L'],
      'trainers' || 'boots' || 'shoes' => const ['40', '41', '42', '43', '44'],
      _ => const ['One Size'],
    };

    return {
      for (final size in labels) size: SizeVariant(price: price, stock: stock),
    };
  }

  String _cartDocumentId(String productId, String size) {
    final trimmedSize = size.trim();
    if (trimmedSize.isEmpty) return productId;
    return '${productId}_${Uri.encodeComponent(trimmedSize)}';
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    return fallback;
  }
}
