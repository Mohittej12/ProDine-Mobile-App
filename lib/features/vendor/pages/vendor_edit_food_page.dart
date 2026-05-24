import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_page_header.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

class VendorEditFoodPage extends StatefulWidget {
  const VendorEditFoodPage({super.key});

  @override
  State<VendorEditFoodPage> createState() => _VendorEditFoodPageState();
}

class _VendorEditFoodPageState extends State<VendorEditFoodPage> {
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

  final TextEditingController _foodNameController = TextEditingController(
    text: 'Margherita Pizza',
  );
  final TextEditingController _priceController = TextEditingController(
    text: '12.99',
  );
  final TextEditingController _descriptionController = TextEditingController(
    text: 'Classic pizza with fresh tomatoes and basil',
  );

  String? _primaryCategory = 'Lunch';
  _DietType _dietType = _DietType.veg;

  bool _imageChanged = false;
  bool _saving = false;
  bool _deleting = false;

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
        !_saving &&
        !_deleting;
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
          final layout = _EditFoodLayout.fromWidth(constraints.maxWidth);
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _SheetHeader(
                    layout: layout,
                    title: 'Edit Food',
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
                                            child: _ImagePanel(
                                              layout: layout,
                                              imageChanged: _imageChanged,
                                              onImageTap: _changeImage,
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
                                          _ImagePanel(
                                            layout: layout,
                                            imageChanged: _imageChanged,
                                            onImageTap: _changeImage,
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
                      child: _BottomActionBar(
                        layout: layout,
                        bottomSafe: bottomSafe,
                        canSave: _canSave,
                        saving: _saving,
                        deleting: _deleting,
                        onSave: _saveChanges,
                        onDelete: _confirmDelete,
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

  void _changeImage() {
    HapticFeedback.selectionClick();
    setState(() => _imageChanged = true);
    _showSnack('Food image updated');
  }

  void _onPrimaryCategoryChanged(String? value) {
    setState(() => _primaryCategory = value);
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_primaryCategory == null) {
      _showSnack('Please select a category');
      return;
    }

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() => _saving = false);
    _showSnack('Food item updated successfully');
    _closePage();
  }

  Future<void> _confirmDelete() async {
    FocusScope.of(context).unfocus();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteFoodSheet(
        itemName: _foodNameController.text.trim().isEmpty
            ? 'this item'
            : _foodNameController.text.trim(),
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() => _deleting = false);
    _showSnack('Food item deleted');
    _closePage();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkText,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 92),
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

class _EditFoodLayout {
  const _EditFoodLayout({
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

  static _EditFoodLayout fromWidth(double width) {
    if (width >= 1180) {
      return const _EditFoodLayout(
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
      return const _EditFoodLayout(
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

    return _EditFoodLayout(
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

  final _EditFoodLayout layout;
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

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.layout,
    required this.imageChanged,
    required this.onImageTap,
  });

  final _EditFoodLayout layout;
  final bool imageChanged;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final imageHeight = layout.isDesktop ? 320.0 : 230.0 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(layout: layout, label: 'Food Image'),
        ClipRRect(
          borderRadius: BorderRadius.circular(24 * scale),
          child: Stack(
            children: [
              Image.asset(
                'assets/images/auth_login_header.png',
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.02),
                        Colors.black.withOpacity(0.12),
                      ],
                    ),
                  ),
                ),
              ),
              if (imageChanged)
                Positioned(
                  top: 14 * scale,
                  right: 14 * scale,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale,
                      vertical: 7 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16 * scale,
                          color: _VendorEditFoodPageState._green,
                        ),
                        SizedBox(width: 5 * scale),
                        Text(
                          'Updated',
                          style: TextStyle(
                            color: _VendorEditFoodPageState._darkText,
                            fontSize: 11.5 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
        SizedBox(
          width: double.infinity,
          height: layout.isDesktop ? 52 : 50 * scale,
          child: OutlinedButton.icon(
            onPressed: onImageTap,
            icon: Icon(Icons.camera_alt_rounded, size: 19 * scale),
            label: Text(imageChanged ? 'Change Again' : 'Change Image'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _VendorEditFoodPageState._darkText,
              backgroundColor: const Color(0xFFF4F5F7),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17 * scale),
              ),
              textStyle: TextStyle(
                fontSize: layout.isDesktop ? 14.5 : 14 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        if (layout.isDesktop) ...[
          SizedBox(height: layout.sectionGap),
          const _GuidanceCard(),
        ],
      ],
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
        border: Border.all(color: _VendorEditFoodPageState._softBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit checklist',
            style: TextStyle(
              color: _VendorEditFoodPageState._darkText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          _TipRow(text: 'Confirm the item name and category.'),
          _TipRow(text: 'Use ₹ pricing for Pro Dine menus.'),
          _TipRow(text: 'Keep description short and customer-friendly.'),
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
              color: _VendorEditFoodPageState._primaryRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _VendorEditFoodPageState._mutedText,
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

  final _EditFoodLayout layout;
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
              border: Border.all(color: _VendorEditFoodPageState._softBorder),
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
            hintText: '0.00',
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

  final _EditFoodLayout layout;
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

  final _EditFoodLayout layout;
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
      cursorColor: _VendorEditFoodPageState._primaryRed,
      validator: validator,
      style: TextStyle(
        color: _VendorEditFoodPageState._darkText,
        fontSize: layout.isDesktop ? 15.5 : 15 * scale,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: _VendorEditFoodPageState._darkText,
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
        fillColor: _VendorEditFoodPageState._fieldBg,
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
          _VendorEditFoodPageState._primaryRed.withOpacity(0.35),
          scale,
        ),
        errorBorder: _inputBorder(
          _VendorEditFoodPageState._primaryRed.withOpacity(0.65),
          scale,
        ),
        focusedErrorBorder: _inputBorder(
          _VendorEditFoodPageState._primaryRed,
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

  final _EditFoodLayout layout;
  final String? value;
  final String hintText;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
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
            : _VendorEditFoodPageState._darkText,
        size: 28 * scale,
      ),
      style: TextStyle(
        color: _VendorEditFoodPageState._darkText,
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
        fillColor: _VendorEditFoodPageState._fieldBg,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18 * scale,
          vertical: 17 * scale,
        ),
        errorMaxLines: 2,
        border: _inputBorder(Colors.transparent, scale),
        enabledBorder: _inputBorder(Colors.transparent, scale),
        focusedBorder: _inputBorder(
          _VendorEditFoodPageState._primaryRed.withOpacity(0.35),
          scale,
        ),
        disabledBorder: _inputBorder(Colors.transparent, scale),
        errorBorder: _inputBorder(
          _VendorEditFoodPageState._primaryRed.withOpacity(0.65),
          scale,
        ),
        focusedErrorBorder: _inputBorder(
          _VendorEditFoodPageState._primaryRed,
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

  final _EditFoodLayout layout;
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
              selectedColor: _VendorEditFoodPageState._green,
              onTap: () => onChanged(_DietType.veg),
              scale: scale,
            ),
          ),
          Expanded(
            child: _DietOption(
              label: 'Non-Veg',
              selected: value == _DietType.nonVeg,
              icon: Icons.restaurant_rounded,
              selectedColor: _VendorEditFoodPageState._orange,
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
                      : _VendorEditFoodPageState._mutedText,
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
                          ? _VendorEditFoodPageState._darkText
                          : _VendorEditFoodPageState._mutedText,
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.layout,
    required this.bottomSafe,
    required this.canSave,
    required this.saving,
    required this.deleting,
    required this.onSave,
    required this.onDelete,
  });

  final _EditFoodLayout layout;
  final double bottomSafe;
  final bool canSave;
  final bool saving;
  final bool deleting;
  final VoidCallback onSave;
  final VoidCallback onDelete;

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
        color: Colors.white.withOpacity(0.97),
        border: const Border(top: BorderSide(color: Color(0xFFF0F1F3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: layout.isDesktop ? 56 : 54 * scale,
            child: ElevatedButton(
              onPressed: canSave ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _VendorEditFoodPageState._deepRed,
                disabledBackgroundColor: const Color(0xFFE4E7EC),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF98A2B3),
                elevation: canSave ? 10 : 0,
                shadowColor: _VendorEditFoodPageState._deepRed.withOpacity(
                  0.28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18 * scale),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: saving
                    ? SizedBox(
                        key: const ValueKey('save-loader'),
                        width: 22 * scale,
                        height: 22 * scale,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Changes',
                        key: const ValueKey('save-text'),
                        style: TextStyle(
                          fontSize: layout.isDesktop ? 16 : 15.5 * scale,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 10 * scale),
          TextButton(
            onPressed: deleting || saving ? null : onDelete,
            style: TextButton.styleFrom(
              foregroundColor: _VendorEditFoodPageState._primaryRed,
              disabledForegroundColor: const Color(0xFF98A2B3),
              padding: EdgeInsets.symmetric(
                horizontal: 18 * scale,
                vertical: 10 * scale,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: deleting
                  ? SizedBox(
                      key: const ValueKey('delete-loader'),
                      width: 18 * scale,
                      height: 18 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _VendorEditFoodPageState._primaryRed,
                        ),
                      ),
                    )
                  : Text(
                      'Delete Food',
                      key: const ValueKey('delete-text'),
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteFoodSheet extends StatelessWidget {
  const _DeleteFoodSheet({required this.itemName});

  final String itemName;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: EdgeInsets.fromLTRB(22, 16, 22, 22 + bottomSafe),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: _VendorEditFoodPageState._primaryRed,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete food item?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _VendorEditFoodPageState._darkText,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '$itemName will be removed from the vendor menu. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _VendorEditFoodPageState._mutedText,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: _VendorEditFoodPageState._darkText,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: _VendorEditFoodPageState._primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DietType { veg, nonVeg }
