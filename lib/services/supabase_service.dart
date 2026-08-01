import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Authentication
  Future<void> sendOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.merchantapp://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Shop Registration
  Future<void> registerShop(Map<String, dynamic> shopData) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      shopData['owner_id'] = user.id;
      await _client.from('shops').insert(shopData);
    } else {
      throw Exception('User must be logged in to register a shop');
    }
  }

  // Product Management
  Future<String?> uploadProductImage(String filePath, String fileName) async {
    try {
      await _client.storage.from('products').upload(fileName, File(filePath));
      return _client.storage.from('products').getPublicUrl(fileName);
    } catch (e) {
      // Return null or rethrow based on preference.
      // If bucket doesn't exist, this will throw.
      throw Exception('Failed to upload image: $e');
    }
  }
  Future<void> addProduct(Map<String, dynamic> productData) async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      // Testing fallback: pick first shop
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId != null) {
      productData['shop_id'] = shopId;
      await _client.from('products').insert(productData);
    } else {
      throw Exception('No shop found to add product');
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      // Testing fallback
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return [];
      
    final response = await _client.from('products')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    await _client.from('products').update(productData).eq('id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }

  Future<List<Map<String, dynamic>>> getOrders(String status) async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      // Testing fallback
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return [];
      
    final response = await _client.from('orders')
        .select('*')
        .eq('shop_id', shopId)
        .eq('status', status)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({'status': newStatus}).eq('id', orderId);
  }

  // Fetch details of a customer
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select('*')
          .eq('id', customerId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Fetch items for an order along with product info
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final itemsResponse = await _client
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);
      
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(itemsResponse);
      if (items.isEmpty) return [];

      // Extract unique product IDs
      final productIds = items.map((item) => item['product_id']).toSet().toList();
      
      // Fetch matching products
      final productsResponse = await _client
          .from('products')
          .select('*')
          .inFilter('id', productIds);
      
      final productsList = List<Map<String, dynamic>>.from(productsResponse);
      final Map<String, Map<String, dynamic>> productsMap = {
        for (var prod in productsList) prod['id'].toString(): prod
      };

      // Merge product information into each item
      for (var item in items) {
        final prodId = item['product_id'].toString();
        item['products'] = productsMap[prodId];
      }

      return items;
    } catch (e) {
      return [];
    }
  }

  // Fetch Dashboard Metrics (Dynamic)
  Future<Map<String, dynamic>> fetchDashboardMetrics() async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return _defaultMetrics();

    // Fetch all products
    final productsRes = await _client.from('products').select('id, stock, created_at').eq('shop_id', shopId);
    final productsList = productsRes as List;
    final productsCount = productsList.length;

    // Fetch all orders
    final ordersRes = await _client.from('orders').select('id, total_amount, status, created_at, customer_id').eq('shop_id', shopId);
    final ordersList = ordersRes as List;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    int ordersToday = 0;
    int ordersYesterday = 0;
    double salesToday = 0.0;
    double salesYesterday = 0.0;
    double salesThisWeek = 0.0;
    double salesThisMonth = 0.0;
    double totalSales = 0.0;

    int productsToday = 0;
    int productsYesterday = 0;
    
    Set<String> customersTotal = {};
    Set<String> customersToday = {};
    Set<String> customersYesterday = {};

    for (var product in productsList) {
      final createdAt = DateTime.parse(product['created_at']);
      if (createdAt.isAfter(today)) {
        productsToday++;
      } else if (createdAt.isAfter(yesterday) && createdAt.isBefore(today)) {
        productsYesterday++;
      }
    }

    for (var order in ordersList) {
      final createdAt = DateTime.parse(order['created_at']);
      final amount = (order['total_amount'] as num).toDouble();
      final status = order['status'];
      final customerId = order['customer_id'].toString();
      
      customersTotal.add(customerId);

      if (createdAt.isAfter(today)) {
        ordersToday++;
        customersToday.add(customerId);
        if (status == 'delivered' || status == 'ready' || status == 'placed' || status == 'accepted') {
          salesToday += amount;
        }
      } else if (createdAt.isAfter(yesterday) && createdAt.isBefore(today)) {
        ordersYesterday++;
        customersYesterday.add(customerId);
        if (status == 'delivered' || status == 'ready' || status == 'placed' || status == 'accepted') {
           salesYesterday += amount;
        }
      }

      if (createdAt.isAfter(startOfWeek)) {
        if (status == 'delivered' || status == 'ready' || status == 'placed' || status == 'accepted') salesThisWeek += amount;
      }
      if (createdAt.isAfter(startOfMonth)) {
        if (status == 'delivered' || status == 'ready' || status == 'placed' || status == 'accepted') salesThisMonth += amount;
      }

      if (status == 'delivered' || status == 'ready' || status == 'placed' || status == 'accepted') {
          totalSales += amount;
      }
    }
    
    // Percentages
    double salesPercent = salesYesterday == 0 ? (salesToday > 0 ? 100 : 0) : ((salesToday - salesYesterday) / salesYesterday) * 100;
    double ordersPercent = ordersYesterday == 0 ? (ordersToday > 0 ? 100 : 0) : ((ordersToday - ordersYesterday) / ordersYesterday) * 100;
    double productsPercent = productsYesterday == 0 ? (productsToday > 0 ? 100 : 0) : ((productsToday - productsYesterday) / productsYesterday) * 100;
    double customersPercent = customersYesterday.isEmpty ? (customersToday.isNotEmpty ? 100 : 0) : ((customersToday.length - customersYesterday.length) / customersYesterday.length) * 100;

    return {
      'totalSales': totalSales.toStringAsFixed(0),
      'salesPercent': salesPercent.toStringAsFixed(1),
      'orders': ordersList.length.toString(),
      'ordersPercent': ordersPercent.toStringAsFixed(1),
      'products': productsCount.toString(),
      'productsPercent': productsPercent.toStringAsFixed(1),
      'customers': customersTotal.length.toString(),
      'customersPercent': customersPercent.toStringAsFixed(1),
      'salesToday': salesToday.toStringAsFixed(0),
      'salesThisWeek': salesThisWeek.toStringAsFixed(0),
      'salesThisMonth': salesThisMonth.toStringAsFixed(0),
    };
  }

  Future<Map<String, int>> getTodayOrderCounts() async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return {'pending': 0, 'preparing': 0, 'ready': 0, 'delivered': 0, 'cancelled': 0};

    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final ordersRes = await _client.from('orders')
        .select('status')
        .eq('shop_id', shopId)
        .gte('created_at', todayStr);
        
    final ordersList = ordersRes as List;
    Map<String, int> counts = {'pending': 0, 'preparing': 0, 'ready': 0, 'delivered': 0, 'cancelled': 0};
    
    for(var order in ordersList) {
      final status = order['status'];
      if(status == 'placed' || status == 'accepted') counts['pending'] = (counts['pending'] ?? 0) + 1;
      else if (status == 'preparing') counts['preparing'] = (counts['preparing'] ?? 0) + 1;
      else if (status == 'packed' || status == 'ready') counts['ready'] = (counts['ready'] ?? 0) + 1;
      else if (status == 'delivered') counts['delivered'] = (counts['delivered'] ?? 0) + 1;
      else if (status == 'cancelled') counts['cancelled'] = (counts['cancelled'] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<double>> getRevenueChartData() async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return List.filled(7, 0.0);

    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    
    final ordersRes = await _client.from('orders')
        .select('total_amount, created_at, status')
        .eq('shop_id', shopId)
        .gte('created_at', sevenDaysAgo.toIso8601String());
        
    List<double> dailyRevenue = List.filled(7, 0.0);
    
    for (var order in (ordersRes as List)) {
      final status = order['status'];
      if (status == 'delivered' || status == 'ready' || status == 'placed' || status == 'accepted') {
        final createdAt = DateTime.parse(order['created_at']);
        final daysAgo = now.difference(createdAt).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          dailyRevenue[6 - daysAgo] += (order['total_amount'] as num).toDouble();
        }
      }
    }
    return dailyRevenue;
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return [];

    final productsRes = await _client.from('products').select('*').eq('shop_id', shopId);
    final products = productsRes as List;
    final Map<String, Map<String, dynamic>> productMap = {
      for (var p in products) p['id'].toString(): {...p, 'orderCount': 0, 'revenue': 0.0}
    };
    
    final ordersRes = await _client.from('orders').select('id').eq('shop_id', shopId);
    final orderIds = (ordersRes as List).map((o) => o['id']).toList();
    
    if (orderIds.isNotEmpty) {
      final orderItemsRes = await _client.from('order_items').select('*').inFilter('order_id', orderIds);
      for (var item in (orderItemsRes as List)) {
        final prodId = item['product_id'].toString();
        if (productMap.containsKey(prodId)) {
           productMap[prodId]!['orderCount'] = (productMap[prodId]!['orderCount'] as int) + (item['quantity'] as int);
           productMap[prodId]!['revenue'] = (productMap[prodId]!['revenue'] as double) + ((item['quantity'] as int) * (item['price'] as num).toDouble());
        }
      }
    }
    
    final result = productMap.values.toList();
    result.sort((a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int));
    return result.take(3).toList();
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
     final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return [];

    final response = await _client.from('products')
      .select('*')
      .eq('shop_id', shopId)
      .lt('stock', 10)
      .order('stock', ascending: true)
      .limit(3);
      
    return List<Map<String, dynamic>>.from(response);
  }
  
  Future<Map<String, dynamic>> getStorePerformance() async {
    final user = _client.auth.currentUser;
    String? shopId;
    
    if (user != null) {
      final shopRes = await _client.from('shops').select('id').eq('owner_id', user.id).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    } else {
      final shopRes = await _client.from('shops').select('id').limit(1).maybeSingle();
      if (shopRes != null) shopId = shopRes['id'];
    }

    if (shopId == null) return {'health': 0, 'accepted': 0, 'prepTime': 0, 'rating': 0.0, 'cancelled': 0};

    final shopRes = await _client.from('shops').select('rating, delivery_time_minutes').eq('id', shopId).maybeSingle();
    double rating = (shopRes?['rating'] ?? 5.0).toDouble();
    int prepTime = shopRes?['delivery_time_minutes'] ?? 15;

    final ordersRes = await _client.from('orders').select('status').eq('shop_id', shopId);
    final orders = ordersRes as List;
    
    int total = orders.length;
    int cancelled = 0;
    int accepted = 0;
    
    for (var o in orders) {
      if (o['status'] == 'cancelled') cancelled++;
      if (o['status'] != 'placed' && o['status'] != 'cancelled') accepted++;
    }
    
    double cancelRate = total == 0 ? 0 : (cancelled / total) * 100;
    double acceptRate = total == 0 ? 100 : (accepted / total) * 100;
    double healthScore = total == 0 ? 100 : ((acceptRate + (100 - cancelRate) + (rating/5.0 * 100)) / 3.0);

    return {
      'health': healthScore.toInt(),
      'accepted': acceptRate.toInt(),
      'prepTime': prepTime,
      'rating': rating,
      'cancelled': cancelRate.toInt(),
    };
  }

  Map<String, dynamic> _defaultMetrics() {
    return {
      'totalSales': '0',
      'salesPercent': '0',
      'orders': '0',
      'ordersPercent': '0',
      'products': '0',
      'productsPercent': '0',
      'customers': '0',
      'customersPercent': '0',
      'salesToday': '0',
      'salesThisWeek': '0',
      'salesThisMonth': '0',
    };
  }
}
