import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'My Shop';
  String? _profilePicUrl;
  String _email = '';
  Map<String, dynamic>? _shopData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _name = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'My Shop';
        _profilePicUrl = user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
        _email = user.email ?? user.phone ?? '';

        final shopRes = await Supabase.instance.client
            .from('shops')
            .select()
            .eq('owner_id', user.id)
            .maybeSingle();
        if (mounted) setState(() => _shopData = shopRes);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 28),
              ),
              const SizedBox(height: 20),
              const Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to sign out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.glassBorder),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        shadowColor: AppColors.coral.withValues(alpha: 0.4),
                        elevation: 8,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 2))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildShopInfo()),
                SliverToBoxAdapter(child: _buildMenuSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.purpleAccent.withValues(alpha: 0.1), Colors.transparent],
            ),
          ),
          child: Column(
            children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.electricBlue, AppColors.purpleAccent, AppColors.emeraldGreen],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
              ),
              child: _profilePicUrl != null
                  ? CircleAvatar(
                      radius: 46,
                      backgroundImage: NetworkImage(_profilePicUrl!),
                      backgroundColor: AppColors.surface,
                    )
                  : CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.surface,
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _name,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          if (_email.isNotEmpty)
            Text(_email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: AppColors.emeraldGreen, size: 16),
                SizedBox(width: 6),
                Text('Verified Merchant', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
            ],
          ),
        ),
        if (Navigator.of(context).canPop())
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShopInfo() {
    if (_shopData == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: AppColors.electricBlue, size: 20),
                    SizedBox(width: 10),
                    Text('Shop Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.electricBlue, size: 18),
                  onPressed: () => _showEditShopSheet(),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.store_rounded, 'Shop Name', _shopData!['shop_name'] ?? 'N/A'),
            const Divider(color: AppColors.glassBorder, height: 24),
            _infoRow(Icons.category_rounded, 'Category', _shopData!['category'] ?? 'N/A'),
            if (_shopData!['owner_name'] != null) ...[
              const Divider(color: AppColors.glassBorder, height: 24),
              _infoRow(Icons.person_rounded, 'Owner', _shopData!['owner_name']),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditShopSheet() {
    if (_shopData == null) return;
    
    final nameController = TextEditingController(text: _shopData!['shop_name']);
    final ownerController = TextEditingController(text: _shopData!['owner_name']);
    List<String> selectedCategories = (_shopData!['category'] ?? 'Grocery').toString().split(', ').map((e) => e.trim()).toList();
    if (selectedCategories.isEmpty) selectedCategories.add('Grocery');
    
    final List<String> categories = [
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
    // Ensure valid categories
    selectedCategories.removeWhere((c) => !categories.contains(c));
    if (selectedCategories.isEmpty) selectedCategories.add('Grocery');
    
    bool isSaving = false;
    File? shopImageFile;
    String? shopImageUrl = _shopData!['image_url'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24, right: 24, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Shop Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // Shop Image Picker
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library_rounded, color: AppColors.electricBlue),
                                title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                                  if (img != null) setSheetState(() => shopImageFile = File(img.path));
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.purpleAccent),
                                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
                                  if (img != null) setSheetState(() => shopImageFile = File(img.path));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.background,
                            border: Border.all(color: AppColors.electricBlue, width: 2),
                            image: shopImageFile != null
                                ? DecorationImage(image: FileImage(shopImageFile!), fit: BoxFit.cover)
                                : (shopImageUrl != null && shopImageUrl!.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(shopImageUrl!), fit: BoxFit.cover)
                                    : null),
                          ),
                          child: (shopImageFile == null && (shopImageUrl == null || shopImageUrl!.isEmpty))
                              ? const Icon(Icons.storefront_rounded, color: AppColors.electricBlue, size: 44)
                              : null,
                        ),
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.electricBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(child: Text('Tap to change shop photo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                const SizedBox(height: 20),
                _buildTextField('Shop Name', nameController),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text('Categories', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13)),
                      selected: isSelected,
                      selectedColor: AppColors.electricBlue,
                      backgroundColor: AppColors.background,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
                      onSelected: (selected) {
                        setSheetState(() {
                          if (selected) {
                            selectedCategories.add(cat);
                          } else {
                            if (selectedCategories.length > 1) {
                              selectedCategories.remove(cat);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildTextField('Owner Name', ownerController),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setSheetState(() => isSaving = true);
                    try {
                      // Try uploading image (non-blocking if it fails)
                      if (shopImageFile != null) {
                        try {
                          final fileName = 'shop_${_shopData!['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          await Supabase.instance.client.storage
                              .from('products')
                              .upload(fileName, shopImageFile!, fileOptions: const FileOptions(upsert: true));
                          shopImageUrl = Supabase.instance.client.storage
                              .from('products')
                              .getPublicUrl(fileName);
                        } catch (imgErr) {
                          // Image upload failed — still continue saving other details
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Image upload failed: $imgErr')),
                            );
                          }
                          shopImageUrl = null;
                        }
                      }
                      // Save shop details
                      final updates = <String, dynamic>{
                        'shop_name': nameController.text.trim(),
                        'category': selectedCategories.join(', '),
                        'owner_name': ownerController.text.trim(),
                      };
                      if (shopImageUrl != null) updates['image_url'] = shopImageUrl;

                      await Supabase.instance.client
                          .from('shops')
                          .update(updates)
                          .eq('id', _shopData!['id']);
                      
                      if (mounted) {
                        setState(() {
                          _shopData!['shop_name'] = updates['shop_name'];
                          _shopData!['category'] = updates['category'];
                          _shopData!['owner_name'] = updates['owner_name'];
                          if (shopImageUrl != null) _shopData!['image_url'] = shopImageUrl;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shop details updated successfully ✅')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      setSheetState(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electricBlue)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.electricBlue, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.notifications_rounded,
                  color: AppColors.premiumGold,
                  title: 'Notifications',
                  subtitle: 'Manage order alerts',
                  onTap: () {},
                ),
                const Divider(color: AppColors.glassBorder, height: 1, indent: 68),
                _menuTile(
                  icon: Icons.location_on_rounded,
                  color: AppColors.emeraldGreen,
                  title: 'Shop Location',
                  subtitle: 'Update your address',
                  onTap: () {},
                ),
                const Divider(color: AppColors.glassBorder, height: 1, indent: 68),
                _menuTile(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.purpleAccent,
                  title: 'Help & Support',
                  subtitle: 'Get help from our team',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: _menuTile(
              icon: Icons.logout_rounded,
              color: AppColors.coral,
              title: 'Sign Out',
              subtitle: 'Logout from your account',
              onTap: _signOut,
              showArrow: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
