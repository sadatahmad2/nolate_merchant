import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_service.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _hsnController = TextEditingController();

  final _costPriceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  final _stockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();

  final _shortDescController = TextEditingController();
  final _fullDescController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'Grocery';
  final List<String> _categories = ['Grocery', 'Electronics', 'Clothing', 'Food', 'Other'];

  String _selectedStockUnit = 'PCS';
  final List<String> _stockUnits = ['PCS', 'KG', 'L', 'Box', 'Other'];

  String _selectedCountry = 'India';
  final List<String> _countries = ['India', 'China', 'USA', 'Other'];

  bool _isActive = true;
  bool _isLoading = false;
  
  List<File> _imageFiles = [];
  List<String> _imageUrls = [];
  int _currentImageIndex = 0;
  
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _fullDescController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _stockController.text = widget.product!['stock']?.toString() ?? '';
      _selectedCategory = widget.product!['category'] ?? 'Grocery';
      _isActive = widget.product!['is_available'] ?? true;
      
      _brandController.text = widget.product!['brand'] ?? '';
      _subCategoryController.text = widget.product!['sub_category'] ?? '';
      _unitController.text = widget.product!['unit'] ?? '';
      _hsnController.text = widget.product!['hsn_code'] ?? '';
      _costPriceController.text = widget.product!['cost_price']?.toString() ?? '';
      _mrpController.text = widget.product!['mrp']?.toString() ?? '';
      _discountController.text = widget.product!['discount']?.toString() ?? '';
      _lowStockController.text = widget.product!['low_stock_alert']?.toString() ?? '';
      _selectedStockUnit = widget.product!['stock_unit'] ?? 'PCS';
      _skuController.text = widget.product!['sku'] ?? '';
      _barcodeController.text = widget.product!['barcode'] ?? '';
      _shortDescController.text = widget.product!['short_description'] ?? '';
      _tagsController.text = widget.product!['tags'] ?? '';
      _selectedCountry = widget.product!['country_of_origin'] ?? 'India';

      if (widget.product!['image_urls'] != null && (widget.product!['image_urls'] as List).isNotEmpty) {
        _imageUrls = List<String>.from(widget.product!['image_urls']);
      } else if (widget.product!['image_url'] != null && widget.product!['image_url'].toString().isNotEmpty) {
        _imageUrls = [widget.product!['image_url']];
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.electricBlue),
                title: const Text('Photo Library', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
                  if (images.isNotEmpty) {
                    setState(() {
                      _imageFiles.addAll(images.map((img) => File(img.path)));
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.emeraldGreen),
                title: const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                  if (image != null) {
                    setState(() {
                      _imageFiles.add(File(image.path));
                    });
                  }
                },
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Selling Price are required')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> finalImageUrls = List.from(_imageUrls);
      
      for (int i = 0; i < _imageFiles.length; i++) {
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _supabaseService.uploadProductImage(_imageFiles[i].path, fileName);
        if (url != null) finalImageUrls.add(url);
      }

      final data = {
        'name': _nameController.text,
        'description': _fullDescController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'category': _selectedCategory,
        'image_urls': finalImageUrls,
        // Optional: save first image to legacy image_url for compatibility
        if (finalImageUrls.isNotEmpty) 'image_url': finalImageUrls.first,
        'is_available': _isActive,
        'brand': _brandController.text,
        'sub_category': _subCategoryController.text,
        'unit': _unitController.text,
        'hsn_code': _hsnController.text,
        'cost_price': double.tryParse(_costPriceController.text),
        'mrp': double.tryParse(_mrpController.text),
        'discount': double.tryParse(_discountController.text),
        'low_stock_alert': int.tryParse(_lowStockController.text),
        'stock_unit': _selectedStockUnit,
        'sku': _skuController.text,
        'barcode': _barcodeController.text,
        'short_description': _shortDescController.text,
        'tags': _tagsController.text,
        'country_of_origin': _selectedCountry,
      };

      if (widget.product != null) {
        await _supabaseService.updateProduct(widget.product!['id'].toString(), data);
      } else {
        await _supabaseService.addProduct(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error Saving Product'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.electricBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    String? hintText,
    bool isNumber = false,
    int maxLines = 1,
    Widget? trailing,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161D35).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.electricBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title + (isRequired ? ' *' : ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String title,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161D35).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.electricBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title + (isRequired ? ' *' : ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              isExpanded: true,
              isDense: true,
              items: items.map((String item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.product != null ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image Section
              _buildSectionTitle('Product Images'),
              if (_imageFiles.isEmpty && _imageUrls.isEmpty)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161D35).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate, color: AppColors.electricBlue, size: 48),
                        const SizedBox(height: 12),
                        const Text('Upload Product Images', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('JPG, PNG or WebP (Max 5MB)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        children: [
                          PageView.builder(
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemCount: _imageUrls.length + _imageFiles.length,
                            itemBuilder: (context, index) {
                              final isNetwork = index < _imageUrls.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: isNetwork
                                      ? Image.network(_imageUrls[index], fit: BoxFit.cover)
                                      : Image.file(_imageFiles[index - _imageUrls.length], fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                          // Remove Image Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_currentImageIndex < _imageUrls.length) {
                                    _imageUrls.removeAt(_currentImageIndex);
                                  } else {
                                    _imageFiles.removeAt(_currentImageIndex - _imageUrls.length);
                                  }
                                  if (_currentImageIndex > 0) {
                                    _currentImageIndex--;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dots and Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            children: List.generate(
                              _imageUrls.length + _imageFiles.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index ? AppColors.electricBlue : Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate, color: AppColors.electricBlue, size: 18),
                          label: const Text('Add More', style: TextStyle(color: AppColors.electricBlue, fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),

              // Basic Information Section
              _buildSectionTitle('Basic Information'),
              Row(
                children: [
                  Expanded(child: _buildCustomTextField(title: 'Product Name', icon: Icons.inventory_2, controller: _nameController, isRequired: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCustomTextField(title: 'Brand Name', icon: Icons.branding_watermark, controller: _brandController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      title: 'Category',
                      icon: Icons.category,
                      value: _selectedCategory,
                      items: _categories,
                      isRequired: true,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCustomTextField(title: 'Sub Category', icon: Icons.sell, controller: _subCategoryController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(title: 'Unit / Size', icon: Icons.straighten, controller: _unitController, hintText: 'e.g. 500g, 1kg, 1L'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomTextField(title: 'HSN / SAC Code', icon: Icons.shield, controller: _hsnController, hintText: 'Optional'),
                  ),
                ],
              ),

              // Pricing Section
              _buildSectionTitle('Pricing'),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'Cost Price (₹)',
                      icon: Icons.currency_rupee,
                      controller: _costPriceController,
                      hintText: 'Your purchase price',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'MRP (₹)',
                      icon: Icons.account_balance_wallet,
                      controller: _mrpController,
                      hintText: 'Maximum Retail Price',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'Selling Price (₹)',
                      icon: Icons.percent,
                      controller: _priceController,
                      hintText: 'Customer price',
                      isNumber: true,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161D35).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_offer, color: AppColors.electricBlue, size: 18),
                              SizedBox(width: 8),
                              Text('Discount (%)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _discountController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: 'Discount percentage',
                              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: 'You Save: ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            children: [
                              TextSpan(text: '₹0.00', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: const TextSpan(
                            text: 'Final Price: ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            children: [
                              TextSpan(text: '₹0.00', style: TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // Inventory Section
              _buildSectionTitle('Inventory'),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'Stock Quantity',
                      icon: Icons.layers,
                      controller: _stockController,
                      hintText: 'Total available stock',
                      isNumber: true,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'Low Stock Alert',
                      icon: Icons.notifications,
                      controller: _lowStockController,
                      hintText: 'Alert when stock below',
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      title: 'Stock Unit',
                      icon: Icons.inventory,
                      value: _selectedStockUnit,
                      items: _stockUnits,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStockUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'SKU / Product Code',
                      icon: Icons.qr_code,
                      controller: _skuController,
                      hintText: 'Enter unique SKU / code',
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'Barcode (EAN / UPC)',
                      icon: Icons.view_column,
                      controller: _barcodeController,
                      hintText: 'Scan or enter barcode',
                      trailing: const Icon(Icons.qr_code_scanner, color: AppColors.emeraldGreen, size: 20),
                    ),
                  ),
                ],
              ),

              // Product Details Section
              _buildSectionTitle('Product Details'),
              _buildCustomTextField(
                title: 'Short Description',
                icon: Icons.description,
                controller: _shortDescController,
                hintText: 'Enter short description',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildCustomTextField(
                title: 'Full Description',
                icon: Icons.article,
                controller: _fullDescController,
                hintText: 'Enter full product description',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomTextField(
                      title: 'Tags / Keywords',
                      icon: Icons.tag,
                      controller: _tagsController,
                      hintText: 'e.g. organic, best seller, new',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      title: 'Country of Origin',
                      icon: Icons.public,
                      value: _selectedCountry,
                      items: _countries,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCountry = val);
                      },
                    ),
                  ),
                ],
              ),

              // Status Section
              _buildSectionTitle('Status'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isActive = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _isActive ? const Color(0xFF161D35).withOpacity(0.8) : const Color(0xFF161D35).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isActive ? AppColors.emeraldGreen : AppColors.glassBorder,
                            width: _isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: _isActive ? AppColors.emeraldGreen : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Active', style: TextStyle(color: _isActive ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  Text('Product will be visible to customers', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isActive = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: !_isActive ? const Color(0xFF161D35).withOpacity(0.8) : const Color(0xFF161D35).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isActive ? AppColors.coral : AppColors.glassBorder,
                            width: !_isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !_isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: !_isActive ? AppColors.coral : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Inactive', style: TextStyle(color: !_isActive ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  Text('Product will be hidden', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Bottom Buttons
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueGlow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Save Product', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 32), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
