import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../dashboard/screens/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopRegistrationScreen extends StatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> with TickerProviderStateMixin {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  List<String> _selectedCategories = ['Grocery'];
  final List<String> _categories = [
    'Grocery',
    'Sweets & Bakery',
    'Snacks & Chips',
    'Dairy & Breakfast',
    'Gifts & Toys',
    'Beverages',
    'Personal Care',
    'Home & Kitchen',
    'Books & Notebooks',
  ];
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final _categoryIcons = {
    'Grocery': Icons.local_grocery_store_rounded,
    'Sweets & Bakery': Icons.cake_rounded,
    'Snacks & Chips': Icons.fastfood_rounded,
    'Dairy & Breakfast': Icons.egg_rounded,
    'Gifts & Toys': Icons.card_giftcard_rounded,
    'Beverages': Icons.local_cafe_rounded,
    'Personal Care': Icons.clean_hands_rounded,
    'Home & Kitchen': Icons.kitchen_rounded,
    'Books & Notebooks': Icons.menu_book_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shopNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    if (_shopNameController.text.isEmpty || _ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [Icon(Icons.warning_rounded, color: Colors.white), SizedBox(width: 10), Text('Please fill all fields')]),
          backgroundColor: AppColors.premiumGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('shops').insert({
          'owner_id': user.id,
          'shop_name': _shopNameController.text.trim(),
          'owner_name': _ownerNameController.text.trim(),
          'category': _selectedCategories.join(', '),
        });
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainLayout(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.emeraldGreen.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Top indicator
                    Center(
                      child: Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.electricBlue, AppColors.emeraldGreen]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Set Up Your Shop',
                      style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tell us about your store to get started on the Nolate platform.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                    ),

                    const SizedBox(height: 40),

                    // Logo Upload
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.glassBorder, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.electricBlue.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.electricBlue, size: 46),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.electricBlue, AppColors.purpleAccent]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.electricBlue.withValues(alpha: 0.4), blurRadius: 10)],
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: Text('Upload Shop Logo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),

                    const SizedBox(height: 36),

                    // Form
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTextField(
                            controller: _shopNameController,
                            hint: 'Shop Name',
                            icon: Icons.storefront_rounded,
                            iconColor: AppColors.electricBlue,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _ownerNameController,
                            hint: 'Owner Full Name',
                            icon: Icons.person_rounded,
                            iconColor: AppColors.purpleAccent,
                          ),
                          const SizedBox(height: 16),

                          // Category Picker
                          const Padding(
                            padding: EdgeInsets.only(left: 8, bottom: 8),
                            child: Text('Select Categories', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategories.contains(cat);
                              return FilterChip(
                                label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13)),
                                avatar: Icon(_categoryIcons[cat] ?? Icons.store, color: isSelected ? Colors.white : AppColors.textSecondary, size: 16),
                                selected: isSelected,
                                selectedColor: AppColors.electricBlue,
                                backgroundColor: AppColors.glassWhite,
                                checkmarkColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(cat);
                                    } else {
                                      if (_selectedCategories.length > 1) {
                                        _selectedCategories.remove(cat);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one category is required.')));
                                      }
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // GPS
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.my_location_rounded, color: AppColors.emeraldGreen, size: 18),
                            label: const Text('Detect GPS Location', style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.glassBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // CTA Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 2.5))
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.emeraldGreen, Color(0xFF059669)]),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emeraldGreen.withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _completeRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Complete Registration', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
