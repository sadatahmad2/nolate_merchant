import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantNotificationService {
  static final MerchantNotificationService _instance =
      MerchantNotificationService._internal();
  factory MerchantNotificationService() => _instance;
  MerchantNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _ordersChannel;
  String? _shopId; // Current merchant's shop id

  // In-app notification stream for UI banners
  final StreamController<Map<String, dynamic>> _inAppController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get inAppNotifications => _inAppController.stream;

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Request iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Call this after the merchant is logged in with their shop id
  void startListening(String shopId) {
    if (_shopId == shopId) return; // Already listening for this shop
    _shopId = shopId;

    _ordersChannel?.unsubscribe();

    _ordersChannel = _supabase
        .channel('merchant-orders-$shopId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'shop_id',
            value: shopId,
          ),
          callback: (payload) {
            _handleNewOrder(payload.newRecord);
          },
        )
        .subscribe();
  }

  void _handleNewOrder(Map<String, dynamic> order) {
    final orderId =
        (order['id'] as String?)?.substring(0, 8).toUpperCase() ?? 'NEW';
    final amount = order['total_amount'];
    final amountStr = amount != null ? '₹${amount.toStringAsFixed(0)}' : '';

    _showLocalNotification(
      id: order['id'].hashCode,
      title: '🛒 New Order Received!',
      body: 'Order #$orderId $amountStr — Tap to prepare it now.',
    );

    _inAppController.add({
      'type': 'new_order',
      'title': '🛒 New Order!',
      'body': 'Order #$orderId $amountStr received — prepare it now!',
      'orderId': order['id'],
    });
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'merchant_orders_channel',
      'New Orders',
      channelDescription: 'Notifications for incoming orders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void stopListening() {
    _ordersChannel?.unsubscribe();
    _ordersChannel = null;
    _shopId = null;
  }

  void dispose() {
    stopListening();
    _inAppController.close();
  }
}
