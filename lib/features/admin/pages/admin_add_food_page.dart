import 'package:flutter/material.dart';

class AdminAddFoodPage extends StatelessWidget {
  const AdminAddFoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageUploadHub(),
                  const SizedBox(height: 32),
                  _buildLabel('Food Name'),
                  _buildTextField('Enter food name'),
                  const SizedBox(height: 24),
                  _buildLabel('Price'),
                  _buildTextField('₹0.00'),
                  const SizedBox(height: 24),
                  _buildLabel('Primary Category'),
                  _buildDropdownField('Select category'),
                  const SizedBox(height: 24),
                  _buildLabel('Secondary Category'),
                  _buildDropdownField('Select subcategory'),
                  const SizedBox(height: 24),
                  _buildLabel('Diet'),
                  _buildDietToggle(),
                  const SizedBox(height: 24),
                  _buildLabel('Description'),
                  _buildTextArea('Add a short description for the item', 150),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Food', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A3F))),
              Text('Create a new menu item', style: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.close_rounded, color: Color(0xFF1A1A3F), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadHub() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.black26, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Upload Food Image', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1A1A3F))),
          const SizedBox(height: 4),
          const Text('JPG, PNG up to 5 MB', style: TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.w700)),
          const Text('Square or 4:3 works best', style: TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A3F))),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFBFBFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: TextField(
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.black26, fontSize: 14, fontWeight: FontWeight.w600), border: InputBorder.none),
      ),
    );
  }

  Widget _buildDropdownField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFFBFBFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: const TextStyle(color: Colors.black26, fontSize: 14, fontWeight: FontWeight.w600)),
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildDietToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildToggleOption('Veg', true),
          _buildToggleOption('Non-Veg', false),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)] : null),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: active ? const Color(0xFF1A1A3F) : Colors.black26, fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }

  Widget _buildTextArea(String hint, int maxChars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFFFBFBFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.04))),
          child: TextField(
            maxLines: 4,
            decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.black26, fontSize: 14, fontWeight: FontWeight.w600), border: InputBorder.none),
          ),
        ),
        const SizedBox(height: 4),
        Text('0 / $maxChars characters', style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Text('Save Food', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}