import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/receipt_generator.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];

  bool _isLoadingPending = true;
  bool _isLoadingHistory = false;
  bool _isRefreshing = false;

  late TabController _tabController;
  Timer? _autoRefreshTimer;

  static const _autoRefreshSeconds = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchPendingOrders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _autoRefreshSeconds),
      (_) => _silentRefresh(),
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && _historyOrders.isEmpty) {
      _fetchHistoryOrders();
    }
  }

  /// Silent background refresh (no loading spinner)
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final pending = await _supabaseService.getOrders('pending');
      final placed = await _supabaseService.getOrders('placed');
      final all = [...pending, ...placed];
      all.sort((a, b) {
        final aT = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bT = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bT.compareTo(aT);
      });
      if (mounted) setState(() => _pendingOrders = all);

      if (_tabController.index == 1) {
        final history = await _fetchHistoryFromDB();
        if (mounted) setState(() => _historyOrders = history);
      }
    } catch (_) {}
  }

  Future<void> _fetchPendingOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingPending = true);
    try {
      final pending = await _supabaseService.getOrders('pending');
      final placed = await _supabaseService.getOrders('placed');
      final all = [...pending, ...placed];
      all.sort((a, b) {
        final aT = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
        final bT = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
        return bT.compareTo(aT);
      });
      if (mounted) setState(() => _pendingOrders = all);
    } catch (e) {
      _showError('Failed to load orders: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistoryFromDB() async {
    final statuses = ['ready', 'out_for_delivery', 'delivered', 'cancelled'];
    List<Map<String, dynamic>> all = [];
    for (final status in statuses) {
      try {
        final res = await _supabaseService.getOrders(status);
        all.addAll(res);
      } catch (_) {}
    }
    // Sort by created_at descending
    all.sort((a, b) {
      final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime(2000);
      final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return all;
  }

  Future<void> _fetchHistoryOrders() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final results = await _fetchHistoryFromDB();
      if (mounted) setState(() => _historyOrders = results);
    } catch (e) {
      _showError('Failed to load history: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _fetchPendingOrders();
      if (_tabController.index == 1) await _fetchHistoryOrders();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Orders refreshed'),
            ],
          ),
          backgroundColor: AppColors.emeraldGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await _supabaseService.updateOrderStatus(orderId, newStatus);
      await _fetchPendingOrders();
      // Refresh history too so it shows up immediately
      final history = await _fetchHistoryFromDB();
      if (mounted) setState(() => _historyOrders = history);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'ready'
                  ? '✅ Order marked as Ready! Admin will assign delivery.'
                  : '❌ Order cancelled.',
            ),
            backgroundColor: newStatus == 'ready'
                ? AppColors.emeraldGreen
                : AppColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showError('Failed: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────── Bottom Sheet ───────────────
  void _showOrderDetailsBottomSheet(
      BuildContext context, Map<String, dynamic> order,
      {bool isHistory = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        Map<String, dynamic>? customerProfile;
        List<Map<String, dynamic>> orderItems = [];
        bool isLoadingDetails = true;
        bool loadStarted = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!loadStarted) {
              loadStarted = true;
              Future.wait([
                _supabaseService
                    .getCustomerProfile(order['customer_id'].toString()),
                _supabaseService.getOrderItems(order['id'].toString()),
              ]).then((results) {
                if (context.mounted) {
                  setModalState(() {
                    customerProfile = results[0] as Map<String, dynamic>?;
                    orderItems = results[1] as List<Map<String, dynamic>>;
                    isLoadingDetails = false;
                  });
                }
              }).catchError((e) {
                if (context.mounted) {
                  setModalState(() => isLoadingDetails = false);
                }
              });
            }

            final shortId =
                order['id'].toString().substring(0, 6).toUpperCase();
            String address = 'No address provided';
            if (order['customer_location'] is Map) {
              address = order['customer_location']['address'] ?? address;
            }
            final status = order['status']?.toString() ?? 'pending';

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                          color: AppColors.glassBorder, width: 1.5),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #$shortId',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (isLoadingDetails)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.electricBlue,
                                strokeWidth: 2),
                          ),
                        )
                      else ...[
                        // Customer
                        const Text('CUSTOMER & DELIVERY',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        GlassContainer(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.electricBlue
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_rounded,
                                        color: AppColors.electricBlue,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    customerProfile?['name'] ??
                                        'Unknown Customer',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (customerProfile?['phone'] != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_rounded,
                                        color: AppColors.electricBlue,
                                        size: 16),
                                    const SizedBox(width: 10),
                                    Text(customerProfile!['phone'],
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: AppColors.coral, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(address,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Items
                        const Text('ITEMS',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        if (orderItems.isEmpty)
                          GlassContainer(
                            padding: const EdgeInsets.all(20),
                            child: const Center(
                              child: Text('No items found.',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13)),
                            ),
                          )
                        else
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 14),
                            child: Column(
                              children: List.generate(orderItems.length,
                                  (idx) {
                                final item = orderItems[idx];
                                final product = item['products']
                                    as Map<String, dynamic>?;
                                final prodName = product?['name'] ?? 'Item';
                                final imageUrl =
                                    product?['image_url'] as String?;
                                final qty = item['quantity'] ?? 1;
                                final price =
                                    (item['price'] as num?)?.toDouble() ??
                                        0.0;
                                final isLast = idx == orderItems.length - 1;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: AppColors.glassWhite,
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: imageUrl != null &&
                                                    imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx,
                                                            err,
                                                            stack) =>
                                                        const Icon(
                                                            Icons
                                                                .fastfood_rounded,
                                                            color: AppColors
                                                                .textMuted,
                                                            size: 28),
                                                    loadingBuilder: (ctx,
                                                        child,
                                                        progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: AppColors
                                                              .electricBlue,
                                                          strokeWidth: 1.5,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : const Icon(
                                                    Icons.fastfood_rounded,
                                                    color: AppColors.textMuted,
                                                    size: 28),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(prodName,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                const SizedBox(height: 4),
                                                Text(
                                                    '₹${price.toStringAsFixed(0)} × $qty',
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.electricBlue
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text('Qty: $qty',
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .electricBlue,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '₹${(price * qty).toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isLast)
                                      const Divider(
                                          color: Colors.white10, height: 1),
                                  ],
                                );
                              }),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Bill
                        const Text('BILL DETAILS',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        GlassContainer(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _billRow(
                                  'Delivery Fee',
                                  '₹${(order['delivery_fee'] as num?)?.toDouble() ?? 0.0}'),
                              const SizedBox(height: 6),
                              _billRow(
                                  'Taxes',
                                  '₹${(order['tax'] as num?)?.toDouble() ?? 0.0}'),
                              const Divider(
                                  color: Colors.white12, height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Amount',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  Text('₹${order['total_amount']}',
                                      style: const TextStyle(
                                          color: AppColors.premiumGold,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Actions — only for pending orders
                        if (!isHistory) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.electricBlue
                                      .withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: AppColors.electricBlue, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'After marking Ready, admin will assign a delivery partner.',
                                    style: TextStyle(
                                        color: AppColors.electricBlue,
                                        fontSize: 12),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        if (isHistory && order['status']?.toString().toLowerCase() == 'delivered')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final custLoc = order['customer_location'] as Map<String, dynamic>? ?? {};
                                final customer = order['customers'] as Map<String, dynamic>? ?? {};
                                final total = (order['total_amount'] as num?)?.toDouble() ?? 0;
                                final tax = (order['tax'] as num?)?.toDouble() ?? 0;
                                final fee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;
                                final subtotal = total - tax - fee;
                                await ReceiptGenerator.generateAndDownloadReceipt(
                                  orderId: order['id'].toString(),
                                  customerName: customer['name'] ?? 'Unknown',
                                  customerPhone: customer['phone'] ?? '',
                                  customerAddress: custLoc['address'] ?? '',
                                  shopName: 'Your Shop',
                                  items: orderItems,
                                  subtotal: subtotal,
                                  tax: tax,
                                  deliveryFee: fee,
                                  total: total,
                                  date: DateTime.tryParse(order['created_at']?.toString() ?? '') ?? DateTime.now(),
                                  riderName: custLoc['rider_name'] as String?,
                                );
                              },
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Download Receipt',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),

                        if (!isHistory && order['status']?.toString().toLowerCase() != 'ready')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _updateStatus(
                                        order['id'].toString(), 'cancelled');
                                  },
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16),
                                  label: const Text('Reject'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.coral,
                                    side: BorderSide(
                                        color: AppColors.coral
                                            .withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _updateStatus(
                                        order['id'].toString(), 'ready');
                                  },
                                  icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18),
                                  label: const Text('Order Ready',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.emeraldGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
  }

  // ─────────────── Helpers ───────────────

  Widget _statusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'pending':
        color = AppColors.premiumGold;
        label = 'NEW';
        icon = Icons.fiber_new_rounded;
        break;
      case 'ready':
        color = AppColors.electricBlue;
        label = 'READY';
        icon = Icons.done_all_rounded;
        break;
      case 'out_for_delivery':
        color = Colors.deepPurpleAccent;
        label = 'DELIVERING';
        icon = Icons.delivery_dining_rounded;
        break;
      case 'delivered':
        color = AppColors.emeraldGreen;
        label = 'DELIVERED';
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        color = AppColors.coral;
        label = 'CANCELLED';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.textSecondary;
        label = status.toUpperCase();
        icon = Icons.info_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  // ─────────────── Build ───────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Orders',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        SizedBox(height: 3),
                        Text('Auto-refreshes every 30s',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  // Auto-refresh indicator
                  _AutoRefreshRing(seconds: _autoRefreshSeconds),
                  const SizedBox(width: 10),
                  // Manual refresh
                  GestureDetector(
                    onTap: _manualRefresh,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.electricBlue
                                .withValues(alpha: 0.3)),
                      ),
                      child: _isRefreshing
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: AppColors.electricBlue,
                                  strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded,
                              color: AppColors.electricBlue, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.electricBlue.withValues(alpha: 0.4)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_rounded, size: 15),
                          const SizedBox(width: 6),
                          const Text('New Orders'),
                          if (_pendingOrders.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.premiumGold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_pendingOrders.length}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 15),
                          SizedBox(width: 6),
                          Text('History'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── New Orders ──
                  _isLoadingPending
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.electricBlue, strokeWidth: 2))
                      : _buildPendingList(),

                  // ── History ──
                  _isLoadingHistory
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.electricBlue, strokeWidth: 2))
                      : _buildHistoryList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── Pending List ───────────────
  Widget _buildPendingList() {
    if (_pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.inbox_rounded,
                  color: AppColors.textMuted, size: 38),
            ),
            const SizedBox(height: 18),
            const Text('No pending orders',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Auto-refreshing every 30s',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) =>
          _buildOrderCard(_pendingOrders[index], isHistory: false),
    );
  }

  // ─────────────── History List ───────────────
  Widget _buildHistoryList() {
    if (_historyOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.glassWhite,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.history_rounded,
                  color: AppColors.textMuted, size: 38),
            ),
            const SizedBox(height: 18),
            const Text('No order history',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _fetchHistoryOrders,
              child: const Text('Tap to load',
                  style: TextStyle(
                      color: AppColors.electricBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: _historyOrders.length,
      itemBuilder: (context, index) =>
          _buildOrderCard(_historyOrders[index], isHistory: true),
    );
  }

  // ─────────────── Order Card ───────────────
  Widget _buildOrderCard(Map<String, dynamic> order,
      {required bool isHistory}) {
    final shortId = order['id'].toString().substring(0, 6).toUpperCase();
    String address = 'No address provided';
    if (order['customer_location'] is Map) {
      address = order['customer_location']['address'] ?? address;
    }
    final status = order['status']?.toString() ?? 'pending';

    final createdAt = order['created_at'] != null
        ? DateTime.tryParse(order['created_at'].toString())?.toLocal()
        : null;
    final dateStr = createdAt != null
        ? '${createdAt.day}/${createdAt.month}  ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => _showOrderDetailsBottomSheet(context, order,
            isHistory: isHistory),
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isHistory
                              ? AppColors.textSecondary
                              : AppColors.premiumGold)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isHistory
                          ? Icons.receipt_long_rounded
                          : Icons.receipt_long_rounded,
                      color: isHistory
                          ? AppColors.textSecondary
                          : AppColors.premiumGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$shortId',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.textMuted, size: 12),
                            const SizedBox(width: 4),
                            Text(dateStr,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusBadge(status),
                      const SizedBox(height: 4),
                      Text('₹${order['total_amount']}',
                          style: const TextStyle(
                              color: AppColors.premiumGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.coral, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(address,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.textMuted, size: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── Auto-Refresh Ring Widget ───────────────
class _AutoRefreshRing extends StatefulWidget {
  final int seconds;
  const _AutoRefreshRing({required this.seconds});

  @override
  State<_AutoRefreshRing> createState() => _AutoRefreshRingState();
}

class _AutoRefreshRingState extends State<_AutoRefreshRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Auto-refreshing every ${widget.seconds}s',
      child: SizedBox(
        width: 36,
        height: 36,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _ctrl.value,
                strokeWidth: 2.5,
                backgroundColor: Colors.white10,
                color: AppColors.electricBlue.withValues(alpha: 0.6),
              ),
              const Icon(Icons.autorenew_rounded,
                  color: AppColors.electricBlue, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
