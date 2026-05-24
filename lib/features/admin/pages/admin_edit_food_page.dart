import 'package:flutter/material.dart';

class AdminEditFoodPage extends StatelessWidget {
  const AdminEditFoodPage({super.key});

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
                  _buildLabel('Food Image'),
                  _buildImagePreview(),
                  const SizedBox(height: 12),
                  _buildChangeImageBtn(),
                  const SizedBox(height: 32),
                  _buildLabel('Food Name'),
                  _buildTextField('Margherita Pizza'),
                  const SizedBox(height: 24),
                  _buildLabel('Price'),
                  _buildTextField('\$ 12.99'),
                  const SizedBox(height: 24),
                  _buildLabel('Primary Category'),
                  _buildTextField(''),
                  const SizedBox(height: 24),
                  _buildLabel('Secondary Category'),
                  _buildTextField('Main Course'),
                  const SizedBox(height: 24),
                  _buildLabel('Diet'),
                  _buildDietToggle(),
                  const SizedBox(height: 24),
                  _buildLabel('Description'),
                  _buildTextArea('Classic pizza with fresh tomatoes and basil', 150),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                  _buildDeleteAction(),
                  const SizedBox(height: 32),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Edit Food', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A3F))),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black26)),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/auth_login_header.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildChangeImageBtn() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: () {},
        style: TextButton.styleFrom(backgroundColor: const Color(0xFFF1F3F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A1A3F), size: 18),
        label: const Text('Change Image', style: TextStyle(color: Color(0xFF1A1A3F), fontWeight: FontWeight.w900, fontSize: 13)),
      ),
    );
  }

  Widget _buildTextField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.08))),
      child: TextField(
        controller: TextEditingController(text: value),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A3F)),
        decoration: const InputDecoration(border: InputBorder.none),
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

  Widget _buildTextArea(String value, int maxChars) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.08))),
      child: TextField(
        maxLines: 4,
        controller: TextEditingController(text: value),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A3F), height: 1.5),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
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
        child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Widget _buildDeleteAction() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text('Delete Food', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w900, fontSize: 14)),
      ),
    );
  }
}