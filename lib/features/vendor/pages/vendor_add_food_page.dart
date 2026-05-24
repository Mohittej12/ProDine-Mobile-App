import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorAddFoodPage extends StatefulWidget {
  const VendorAddFoodPage({super.key});

  @override
  State<VendorAddFoodPage> createState() => _VendorAddFoodPageState();
}

class _VendorAddFoodPageState extends State<VendorAddFoodPage> {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _deepRed = Color(0xFFC91818);
  static const Color _darkText = Color(0xFF141827);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _fieldBg = Color(0xFFF8F9FB);
  static const Color _softBorder = Color(0xFFE9EDF3);
  static const Color _green = Color(0xFF16A34A);
  static const Color _orange = Color(0xFFFF6A00);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _primaryCategory;
  _DietType _dietType = _DietType.veg;
  bool _imageSelected = false;
  bool _saving = false;

  final List<String> _primaryCategories = const [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Beverages',
  ];

  bool get _canSave {
    return _foodNameController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _primaryCategory != null &&
        !_saving;
  }

  @override
  void initState() {
    super.initState();
    _foodNameController.addListener(_refresh);
    _priceController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
  }

  @override
  void dispose() {
    _foodNameController
      ..removeListener(_refresh)
      ..dispose();
    _priceController
      ..removeListener(_refresh)
      ..dispose();
    _descriptionController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _AddFoodLayout.fromWidth(constraints.maxWidth);
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _SheetHeader(
                    layout: layout,
                    title: 'Add Food',
                    onClose: _closePage,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: layout.maxContentWidth,
                        ),
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                layout.horizontalPadding,
                                layout.contentTopPadding,
                                layout.horizontalPadding,
                                24 + bottomSafe,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: layout.isDesktop
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 9,
                                            child: _LeftPanel(
                                              layout: layout,
                                              imageSelected: _imageSelected,
                                              onImageTap: _pickImage,
                                            ),
                                          ),
                                          SizedBox(width: layout.gridGap),
                                          Expanded(
                                            flex: 11,
                                            child: _FormPanel(
                                              layout: layout,
                                              foodNameController:
                                                  _foodNameController,
                                              priceController: _priceController,
                                              descriptionController:
                                                  _descriptionController,
                                              primaryCategory: _primaryCategory,
                                              primaryCategories:
                                                  _primaryCategories,
                                              dietType: _dietType,
                                              onPrimaryChanged:
                                                  _onPrimaryCategoryChanged,
                                              onDietChanged: (value) {
                                                setState(
                                                  () => _dietType = value,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _LeftPanel(
                                            layout: layout,
                                            imageSelected: _imageSelected,
                                            onImageTap: _pickImage,
                                          ),
                                          SizedBox(height: layout.sectionGap),
                                          _FormPanel(
                                            layout: layout,
                                            foodNameController:
                                                _foodNameController,
                                            priceController: _priceController,
                                            descriptionController:
                                                _descriptionController,
                                            primaryCategory: _primaryCategory,
                                            primaryCategories:
                                                _primaryCategories,
                                            dietType: _dietType,
                                            onPrimaryChanged:
                                                _onPrimaryCategoryChanged,
                                            onDietChanged: (value) {
                                              setState(() => _dietType = value);
                                            },
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: layout.maxContentWidth,
                      ),
                      child: _BottomSaveBar(
                        layout: layout,
                        bottomSafe: bottomSafe,
                        enabled: _canSave,
                        saving: _saving,
                        onSave: _saveFood,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _closePage() {
    Navigator.of(context).pop();
  }

  void _pickImage() {
    HapticFeedback.selectionClick();
    setState(() => _imageSelected = true);
    _showSnack('Food image selected');
  }

  void _onPrimaryCategoryChanged(String? value) {
    setState(() => _primaryCategory = value);
  }

  Future<void> _saveFood() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_primaryCategory == null) {
      _showSnack('Please select a category');
      return;
    }

    setState(() => _saving = true);

    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() => _saving = false);

    _showSnack('Food item saved successfully');
    _closePage();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 90),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
  }
}

class _AddFoodLayout {
  const _AddFoodLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.headerPadding,
    required this.contentTopPadding,
    required this.bottomBarPadding,
    required this.scale,
    required this.sectionGap,
    required this.fieldGap,
    required this.gridGap,
  });

  final bool isDesktop;
  final bool isTablet;
  final double maxContentWidth;
  final double horizontalPadding;
  final double headerPadding;
  final double contentTopPadding;
  final double bottomBarPadding;
  final double scale;
  final double sectionGap;
  final double fieldGap;
  final double gridGap;

  static _AddFoodLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _AddFoodLayout(
        isDesktop: true,
        isTablet: false,
        maxContentWidth: 1120,
        horizontalPadding: 48,
        headerPadding: 34,
        contentTopPadding: 28,
        bottomBarPadding: 48,
        scale: 1.06,
        sectionGap: 28,
        fieldGap: 18,
        gridGap: 26,
      );
    }

    if (width >= 760) {
      return const _AddFoodLayout(
        isDesktop: false,
        isTablet: true,
        maxContentWidth: 720,
        horizontalPadding: 36,
        headerPadding: 30,
        contentTopPadding: 24,
        bottomBarPadding: 36,
        scale: 1.0,
        sectionGap: 24,
        fieldGap: 18,
        gridGap: 20,
      );
    }

    return _AddFoodLayout(
      isDesktop: false,
      isTablet: false,
      maxContentWidth: 430,
      horizontalPadding: width < 370 ? 16 : 22,
      headerPadding: width < 370 ? 18 : 22,
      contentTopPadding: 18,
      bottomBarPadding: width < 370 ? 16 : 22,
      scale: width < 370 ? 0.92 : 1,
      sectionGap: 22,
      fieldGap: width < 370 ? 15 : 18,
      gridGap: 14,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.layout,
    required this.title,
    required this.onClose,
  });

  final _AddFoodLayout layout;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return VendorPageHeader(
      title: title,
      maxContentWidth: layout.maxContentWidth,
      horizontalPadding: layout.horizontalPadding,
      isDesktop: layout.isDesktop,
      scale: layout.scale,
      onMenuTap: () => VendorShell.openDrawer(context),
      trailingIcon: Icons.close_rounded,
      onTrailingTap: onClose,
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.layout,
    required this.imageSelected,
    required this.onImageTap,
  });

  final _AddFoodLayout layout;
  final bool imageSelected;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ImageUploadBox(
          layout: layout,
          imageSelected: imageSelected,
          onTap: onImageTap,
        ),
        if (layout.isDesktop) ...[
          SizedBox(height: layout.sectionGap),
          const _GuidanceCard(),
        ],
      ],
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  const _ImageUploadBox({
    required this.layout,
    required this.imageSelected,
    required this.onTap,
  });

  final _AddFoodLayout layout;
  final bool imageSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final height = layout.isDesktop ? 300.0 : 230.0 * scale;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26 * scale),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: imageSelected
                ? _VendorAddFoodPageState._primaryRed.withOpacity(0.42)
                : const Color(0xFFD6DCE5),
            radius: 26 * scale,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: height,
            padding: EdgeInsets.all(18 * scale),
            decoration: BoxDecoration(
              color: imageSelected
                  ? const Color(0xFFFFF4F4)
                  : const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(26 * scale),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68 * scale,
                  height: 68 * scale,
                  decoration: BoxDecoration(
                    color: imageSelected
                        ? _VendorAddFoodPageState._primaryRed
                        : const Color(0xFFE4E7EC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    imageSelected
                        ? Icons.check_rounded
                        : Icons.camera_alt_rounded,
                    color:
                        imageSelected ? Colors.white : const Color(0xFF667085),
                    size: 30 * scale,
                  ),
                ),
                SizedBox(height: 18 * scale),
                Text(
                  imageSelected ? 'Image Ready' : 'Upload Food Image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _VendorAddFoodPageState._darkText,
                    fontSize: layout.isDesktop ? 21 : 18 * scale,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Text(
                  imageSelected ? 'Tap to change image' : 'JPG, PNG up to 5 MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _VendorAddFoodPageState._mutedText,
                    fontSize: 13 * scale,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  'Square or 4:3 works best',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF98A2B3),
                    fontSize: 12.5 * scale,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _VendorAddFoodPageState._softBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu quality tips',
            style: TextStyle(
              color: _VendorAddFoodPageState._darkText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          _TipRow(text: 'Use clear item names customers recognize.'),
          _TipRow(text: 'Keep description short and useful.'),
          _TipRow(text: 'Confirm price before publishing.'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _VendorAddFoodPageState._primaryRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _VendorAddFoodPageState._mutedText,
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.layout,
    required this.foodNameController,
    required this.priceController,
    required this.descriptionController,
    required this.primaryCategory,
    required this.primaryCategories,
    required this.dietType,
    required this.onPrimaryChanged,
    required this.onDietChanged,
  });

  final _AddFoodLayout layout;
  final TextEditingController foodNameController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  final String? primaryCategory;
  final List<String> primaryCategories;
  final _DietType dietType;
  final ValueChanged<String?> onPrimaryChanged;
  final ValueChanged<_DietType> onDietChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: layout.isDesktop ? const EdgeInsets.all(24) : EdgeInsets.zero,
      decoration: layout.isDesktop
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _VendorAddFoodPageState._softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(layout: layout, label: 'Food Name'),
          _AppTextField(
            layout: layout,
            controller: foodNameController,
            hintText: 'Enter food name',
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Food name is required';
              if (text.length < 2) return 'Enter a valid food name';
              return null;
            },
          ),
          SizedBox(height: layout.fieldGap),
          _FieldLabel(layout: layout, label: 'Price'),
          _AppTextField(
            layout: layout,
            controller: priceController,
            hintText: '₹0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            prefixText: '₹ ',
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Price is required';

              final price = double.tryParse(text);
              if (price == null) return 'Enter a valid price';
              if (price <= 0) return 'Price must be greater than zero';
              if (price > 9999) return 'Price looks too high';
              return null;
            },
          ),
          SizedBox(height: layout.fieldGap),
          _FieldLabel(layout: layout, label: 'Primary Category'),
          _AppDropdown(
            layout: layout,
            value: primaryCategory,
            hintText: 'Select category',
            items: primaryCategories,
            onChanged: onPrimaryChanged,
            validator: (value) {
              if (value == null) return 'Primary category is required';
              return null;
            },
          ),
          SizedBox(height: layout.fieldGap),
          _FieldLabel(layout: layout, label: 'Diet'),
          _DietToggle(
            layout: layout,
            value: dietType,
            onChanged: onDietChanged,
          ),
          SizedBox(height: layout.fieldGap),
          _FieldLabel(layout: layout, label: 'Description'),
          _AppTextField(
            layout: layout,
            controller: descriptionController,
            hintText: 'Add a short description for the item',
            maxLines: 4,
            maxLength: 150,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Description is required';
              if (text.length < 8) return 'Description is too short';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.layout, required this.label});

  final _AddFoodLayout layout;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF344054),
          fontSize: layout.isDesktop ? 14.5 : 13.5 * scale,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.layout,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final _AddFoodLayout layout;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final String? prefixText;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      cursorColor: _VendorAddFoodPageState._primaryRed,
      validator: validator,
      style: TextStyle(
        color: _VendorAddFoodPageState._darkText,
        fontSize: layout.isDesktop ? 15.5 : 15 * scale,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: _VendorAddFoodPageState._darkText,
          fontSize: layout.isDesktop ? 15.5 : 15 * scale,
          fontWeight: FontWeight.w900,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF98A2B3),
          fontWeight: FontWeight.w700,
          fontSize: layout.isDesktop ? 15 : 14.5 * scale,
        ),
        filled: true,
        fillColor: _VendorAddFoodPageState._fieldBg,
        counterStyle: TextStyle(
          color: const Color(0xFF98A2B3),
          fontSize: 12 * scale,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: maxLines > 1 ? 18 * scale : 17 * scale,
        ),
        errorMaxLines: 2,
        border: _inputBorder(Colors.transparent, scale),
        enabledBorder: _inputBorder(Colors.transparent, scale),
        focusedBorder: _inputBorder(
          _VendorAddFoodPageState._primaryRed.withOpacity(0.35),
          scale,
        ),
        errorBorder: _inputBorder(
          _VendorAddFoodPageState._primaryRed.withOpacity(0.65),
          scale,
        ),
        focusedErrorBorder: _inputBorder(
          _VendorAddFoodPageState._primaryRed,
          scale,
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18 * scale),
      borderSide: BorderSide(
        color: color,
        width: color == Colors.transparent ? 0 : 1.4,
      ),
    );
  }
}

class _AppDropdown extends StatelessWidget {
  const _AppDropdown({
    required this.layout,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  final _AddFoodLayout layout;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: onChanged == null
            ? const Color(0xFFC2C7D0)
            : _VendorAddFoodPageState._darkText,
        size: 28 * scale,
      ),
      style: TextStyle(
        color: _VendorAddFoodPageState._darkText,
        fontSize: layout.isDesktop ? 15.5 : 15 * scale,
        height: 1,
        fontWeight: FontWeight.w800,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(18 * scale),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF98A2B3),
          fontSize: layout.isDesktop ? 15 : 14.5 * scale,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: _VendorAddFoodPageState._fieldBg,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: 17 * scale,
        ),
        errorMaxLines: 2,
        border: _inputBorder(Colors.transparent, scale),
        enabledBorder: _inputBorder(Colors.transparent, scale),
        focusedBorder: _inputBorder(
          _VendorAddFoodPageState._primaryRed.withOpacity(0.35),
          scale,
        ),
        disabledBorder: _inputBorder(Colors.transparent, scale),
        errorBorder: _inputBorder(
          _VendorAddFoodPageState._primaryRed.withOpacity(0.65),
          scale,
        ),
        focusedErrorBorder: _inputBorder(
          _VendorAddFoodPageState._primaryRed,
          scale,
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, double scale) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18 * scale),
      borderSide: BorderSide(
        color: color,
        width: color == Colors.transparent ? 0 : 1.4,
      ),
    );
  }
}

class _DietToggle extends StatelessWidget {
  const _DietToggle({
    required this.layout,
    required this.value,
    required this.onChanged,
  });

  final _AddFoodLayout layout;
  final _DietType value;
  final ValueChanged<_DietType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.all(5 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(18 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DietOption(
              label: 'Veg',
              selected: value == _DietType.veg,
              icon: Icons.eco_rounded,
              selectedColor: _VendorAddFoodPageState._green,
              onTap: () => onChanged(_DietType.veg),
              scale: scale,
            ),
          ),
          Expanded(
            child: _DietOption(
              label: 'Non-Veg',
              selected: value == _DietType.nonVeg,
              icon: Icons.restaurant_rounded,
              selectedColor: _VendorAddFoodPageState._orange,
              onTap: () => onChanged(_DietType.nonVeg),
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _DietOption extends StatelessWidget {
  const _DietOption({
    required this.label,
    required this.selected,
    required this.icon,
    required this.selectedColor,
    required this.onTap,
    required this.scale,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final Color selectedColor;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14 * scale),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14 * scale),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? selectedColor
                      : _VendorAddFoodPageState._mutedText,
                  size: 18 * scale,
                ),
                SizedBox(width: 7 * scale),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? _VendorAddFoodPageState._darkText
                          : _VendorAddFoodPageState._mutedText,
                      fontSize: 14.5 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  const _BottomSaveBar({
    required this.layout,
    required this.bottomSafe,
    required this.enabled,
    required this.saving,
    required this.onSave,
  });

  final _AddFoodLayout layout;
  final double bottomSafe;
  final bool enabled;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      padding: EdgeInsets.fromLTRB(
        layout.bottomBarPadding,
        14,
        layout.bottomBarPadding,
        14 + bottomSafe,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: const Border(top: BorderSide(color: Color(0xFFF0F1F3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: layout.isDesktop ? 56 : 54 * scale,
        child: ElevatedButton(
          onPressed: enabled ? onSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _VendorAddFoodPageState._deepRed,
            disabledBackgroundColor: const Color(0xFFE4E7EC),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF98A2B3),
            elevation: enabled ? 10 : 0,
            shadowColor: _VendorAddFoodPageState._deepRed.withOpacity(0.28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18 * scale),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: saving
                ? SizedBox(
                    key: const ValueKey('loader'),
                    width: 22 * scale,
                    height: 22 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save Food',
                    key: const ValueKey('text'),
                    style: TextStyle(
                      fontSize: layout.isDesktop ? 16 : 15.5 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    final metrics = path.computeMetrics();

    const dashWidth = 4.5;
    const dashSpace = 5.5;

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

enum _DietType { veg, nonVeg }
