import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../services/supabase_service.dart';
import '../../../services/supabase_service.dart';
import '../../profile/screens/profile_screen.dart';
import 'notifications_screen.dart';
import '../../products/screens/add_product_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../orders/screens/orders_screen.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic> _metrics = {};
  Map<String, int> _todayCounts = {};
  List<double> _revenueData = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _lowStock = [];
  Map<String, dynamic> _storePerf = {};
  List<Map<String, dynamic>> _recentOrders = [];

  bool _isLoading = true;
  String _shopName = "My Shop";
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = _client.auth.currentUser;
      String shopName = "My Shop";
      String? picUrl;
      String? shopId;

      if (user != null) {
        shopName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? "My Shop";
        picUrl = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
        final shopRes = await _client.from('shops').select('id, shop_name').eq('owner_id', user.id).maybeSingle();
        if (shopRes != null) {
          shopId = shopRes['id'];
          shopName = shopRes['shop_name'];
        }
      } else {
        final shopRes = await _client.from('shops').select('id, shop_name').limit(1).maybeSingle();
        if (shopRes != null) {
           shopId = shopRes['id'];
           shopName = shopRes['shop_name'];
        }
      }

      final metrics = await _supabaseService.fetchDashboardMetrics();
      final counts = await _supabaseService.getTodayOrderCounts();
      final revenue = await _supabaseService.getRevenueChartData();
      final top = await _supabaseService.getTopSellingProducts();
      final low = await _supabaseService.getLowStockProducts();
      final perf = await _supabaseService.getStorePerformance();

      List<Map<String, dynamic>> recent = [];
      if (shopId != null) {
        final ordersRes = await _client.from('orders')
          .select('*')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false)
          .limit(5);
        recent = List<Map<String, dynamic>>.from(ordersRes);
      }

      if (mounted) {
        setState(() {
          _shopName = shopName;
          _profilePicUrl = picUrl;
          _metrics = metrics;
          _todayCounts = counts;
          _revenueData = revenue;
          _topProducts = top;
          _lowStock = low;
          _storePerf = perf;
          _recentOrders = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 2)),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.emeraldGreen,
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildTopNav()),
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildMetricsGrid()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(child: _buildTodaysOrders()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRevenueCard(),
                      const SizedBox(height: 16),
                      _buildEarningsCard(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopSellingProducts(),
                      const SizedBox(height: 16),
                      _buildLowStockAlert(),
                      const SizedBox(height: 16),
                      _buildStorePerformance(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRecentOrdersSection(),
                      const SizedBox(height: 16),
                      _buildCustomerReviews(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  // UI BUILDERS
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.background),
            accountName: Text(_shopName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            accountEmail: const Text('View Profile', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.surface,
              backgroundImage: _profilePicUrl != null ? NetworkImage(_profilePicUrl!) : null,
              child: _profilePicUrl == null ? const Icon(Icons.store, color: AppColors.electricBlue) : null,
            ),
            onDetailsPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: AppColors.electricBlue),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.white),
            title: const Text('Products', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.white),
            title: const Text('Orders', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
          ),
          const Divider(color: AppColors.glassBorder),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white),
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Image.asset('assets/images/logo.png', height: 32),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: _profilePicUrl != null ? NetworkImage(_profilePicUrl!) : null,
                        backgroundColor: AppColors.electricBlue,
                        child: _profilePicUrl == null ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_shopName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.emeraldGreen, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text('Open', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, ${_shopName} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Here's what's happening with your store today.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date filter coming soon!'))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.emeraldGreen, size: 14),
                  const SizedBox(width: 6),
                  Text('Today', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Sales', '₹${_metrics['totalSales']}', _metrics['salesPercent'], Icons.shopping_cart, AppColors.emeraldGreen, AppColors.emeraldGreen.withValues(alpha: 0.1))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Orders', _metrics['orders'], _metrics['ordersPercent'], Icons.shopping_bag, AppColors.electricBlue, AppColors.electricBlue.withValues(alpha: 0.1))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Products', _metrics['products'], _metrics['productsPercent'], Icons.inventory_2, AppColors.purpleAccent, AppColors.purpleAccent.withValues(alpha: 0.1))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Customers', _metrics['customers'], _metrics['customersPercent'], Icons.people, AppColors.premiumGold, AppColors.premiumGold.withValues(alpha: 0.1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String percentStr, IconData icon, Color color, Color bgColor) {
    double percent = double.tryParse(percentStr) ?? 0;
    bool isPositive = percent >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? AppColors.emeraldGreen : AppColors.danger, size: 12),
              Text('${percent.abs().toStringAsFixed(1)}%', style: TextStyle(color: isPositive ? AppColors.emeraldGreen : AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  ' vs yesterday',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All Actions coming soon!'))),
                child: Text('View All', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionItem(Icons.add_circle, 'Add Product', AppColors.emeraldGreen, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()))),
                _buildActionItem(Icons.local_offer, 'Add Offer', AppColors.purpleAccent, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offers coming soon!')))),
                _buildActionItem(Icons.inventory, 'Manage Orders', AppColors.premiumGold, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
                _buildActionItem(Icons.bar_chart, 'View Analytics', AppColors.emeraldGreen, () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analytics coming soon!')))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysOrders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Orders", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                child: Text('View All Orders', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildOrderStatusCard('Pending', _todayCounts['pending'] ?? 0, Icons.inventory, AppColors.premiumGold),
              const SizedBox(width: 6),
              _buildOrderStatusCard('Preparing', _todayCounts['preparing'] ?? 0, Icons.soup_kitchen, AppColors.electricBlue),
              const SizedBox(width: 6),
              _buildOrderStatusCard('Ready', _todayCounts['ready'] ?? 0, Icons.shopping_bag, AppColors.purpleAccent),
              const SizedBox(width: 6),
              _buildOrderStatusCard('Delivered', _todayCounts['delivered'] ?? 0, Icons.check_circle, AppColors.emeraldGreen),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    double maxVal = _revenueData.isEmpty ? 40000 : _revenueData.reduce((curr, next) => curr > next ? curr : next) * 1.2;
    if(maxVal == 0) maxVal = 40000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revenue Overview', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.glassBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Text('This Week', style: TextStyle(color: Colors.white, fontSize: 12)),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹${_metrics['totalSales']}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Total Sales', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.arrow_upward, color: AppColors.emeraldGreen, size: 14),
                      Text('18.7%', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Text('vs last week', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0x15FFFFFF), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxVal / 4,
                      getTitlesWidget: (val, meta) {
                        return Text('${(val / 1000).toInt()}K', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        const labels = ['19 May', '20 May', '21 May', '22 May', '23 May', '24 May', '25 May'];
                        if (val.toInt() >= 0 && val.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(labels[val.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6, minY: 0, maxY: maxVal,
                lineBarsData: [
                  LineChartBarData(
                    spots: _revenueData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.emeraldGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.surface,
                        strokeWidth: 2,
                        strokeColor: AppColors.emeraldGreen,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.emeraldGreen.withValues(alpha: 0.3),
                          AppColors.emeraldGreen.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildEarningRow(Icons.info_outline, 'Today\'s Sale', '₹${_metrics['salesToday']}', AppColors.emeraldGreen),
          const SizedBox(height: 16),
          _buildEarningRow(Icons.calendar_month, 'This Week', '₹${_metrics['salesThisWeek']}', AppColors.purpleAccent),
          const SizedBox(height: 16),
          _buildEarningRow(Icons.date_range, 'This Month', '₹${_metrics['salesThisMonth']}', AppColors.premiumGold),
        ],
      ),
    );
  }

  Widget _buildEarningRow(IconData icon, String title, String amount, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }

  Widget _buildTopSellingProducts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Selling Products', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('View All', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty) const Text('No data yet', style: TextStyle(color: AppColors.textSecondary)),
          ..._topProducts.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    image: p['image_url'] != null ? DecorationImage(image: NetworkImage(p['image_url']), fit: BoxFit.cover) : null,
                  ),
                  child: p['image_url'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${p['orderCount']} Orders', style: const TextStyle(color: AppColors.premiumGold, fontSize: 12)),
                    ],
                  ),
                ),
                Text('₹${p['revenue'].toStringAsFixed(0)}', style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ))
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Low Stock Alert', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                child: Text('View All', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_lowStock.isEmpty) const Text('Stock is healthy', style: TextStyle(color: AppColors.emeraldGreen)),
          ..._lowStock.map((p) {
             bool outOfStock = p['stock'] == 0;
             return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      image: p['image_url'] != null ? DecorationImage(image: NetworkImage(p['image_url']), fit: BoxFit.cover) : null,
                    ),
                    child: p['image_url'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(outOfStock ? 'Out of Stock' : 'Only ${p['stock']} Left', style: TextStyle(color: outOfStock ? AppColors.danger : AppColors.coral, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (outOfStock ? AppColors.danger : AppColors.coral).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(outOfStock ? 'Out' : 'Low Stock', style: TextStyle(color: outOfStock ? AppColors.danger : AppColors.coral, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _buildStorePerformance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Store Performance', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 55,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(color: AppColors.emeraldGreen, value: (_storePerf['health'] ?? 92).toDouble(), radius: 12, showTitle: false),
                      PieChartSectionData(color: AppColors.surfaceLight, value: (100 - (_storePerf['health'] ?? 92)).toDouble(), radius: 12, showTitle: false),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_storePerf['health'] ?? 92}%', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text('Health Score', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPerfRow('Orders Accepted', '${_storePerf['accepted'] ?? 98}%', true),
          const SizedBox(height: 8),
          _buildPerfRow('Avg. Preparation Time', '${_storePerf['prepTime'] ?? 8} min', true),
          const SizedBox(height: 8),
          _buildPerfRow('Customer Rating', '${_storePerf['rating'] ?? 4.9}', true),
          const SizedBox(height: 8),
          _buildPerfRow('Cancellation Rate', '${_storePerf['cancelled'] ?? 1}%', false),
        ],
      ),
    );
  }

  Widget _buildPerfRow(String label, String value, bool good) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(good ? Icons.arrow_upward : Icons.arrow_downward, color: good ? AppColors.emeraldGreen : AppColors.danger, size: 12),
          ],
        )
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                child: Text('View All', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentOrders.isEmpty) const Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)),
          ..._recentOrders.map((order) {
            final shortId = order['id'].toString().substring(0, 6).toUpperCase();
            final status = order['status'] as String;
            final isNew = status == 'placed' || status == 'pending';
            
            Color statusColor;
            String statusText = status.toUpperCase();
            if (status == 'placed' || status == 'pending') { statusColor = AppColors.premiumGold; statusText = 'PENDING'; }
            else if (status == 'preparing') statusColor = AppColors.electricBlue;
            else if (status == 'ready' || status == 'packed') statusColor = AppColors.purpleAccent;
            else if (status == 'delivered') statusColor = AppColors.emeraldGreen;
            else statusColor = AppColors.danger;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '#$shortId',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNew) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.emeraldGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                child: const Text('New', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ]
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('₹ ${order['total_amount']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('5 min ago', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)), // static for now
                      const SizedBox(height: 4),
                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _buildCustomerReviews() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customer Reviews', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reviews coming soon!'))),
                child: Text('View All', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('4.8', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(5, (index) => const Icon(Icons.star, color: AppColors.premiumGold, size: 16)),
                  ),
                  const SizedBox(height: 4),
                  const Text('125 Reviews', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Very good packaging and on time delivery 📦', style: TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 8),
                      const Text('- Salman Khan', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
