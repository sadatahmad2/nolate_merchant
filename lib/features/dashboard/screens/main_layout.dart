import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/merchant_notification_service.dart';
import 'dashboard_overview_screen.dart';
import '../../products/screens/products_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../profile/screens/profile_screen.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  final List<Widget> _screens = [
    const DashboardOverviewScreen(),
    const ProductsScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Products'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavItem(icon: Icons.store_rounded, label: 'Shop'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await MerchantNotificationService().initialize();
    // Fetch current merchant's shop id and start listening
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final shopRes = await Supabase.instance.client
          .from('shops')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();
      if (shopRes != null) {
        MerchantNotificationService().startListening(shopRes['id'] as String);
        // Listen for in-app banners
        MerchantNotificationService().inAppNotifications.listen((notif) {
          if (mounted) _showInAppBanner(notif);
        });
      }
    }
  }

  OverlayEntry? _overlayEntry;

  void _showInAppBanner(Map<String, dynamic> notif) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            builder: (ctx, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, -24 * (1 - val)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.6),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded,
                        color: AppColors.electricBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(notif['title'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(notif['body'] ?? '',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                      // Switch to Orders tab
                      setState(() => _currentIndex = 2);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('View',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 5), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _overlayEntry?.remove();
    MerchantNotificationService().stopListening();
    super.dispose();
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xCC080C18),
            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (i) => _buildNavItem(i)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.electricBlue.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                item.icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.electricBlue : AppColors.textMuted,
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.electricBlue : AppColors.textMuted,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
