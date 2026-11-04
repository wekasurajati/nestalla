import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import 'section_card.dart';

class ShippingFormCard extends StatelessWidget {
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController address;

  const ShippingFormCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
  });

  static String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Shipping Information',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'First name',
                  controller: firstName,
                  validator: (v) => _required(v, 'First name'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  label: 'Last name',
                  controller: lastName,
                  validator: (v) => _required(v, 'Last name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Email',
            controller: email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email is required';
              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
              return ok ? null : 'Invalid email';
            },
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Phone number',
            controller: phone,
            keyboardType: TextInputType.phone,
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isEmpty) return 'Phone number is required';
              return digits.length >= 8 && digits.length <= 15
                  ? null
                  : 'Invalid phone number';
            },
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Address',
            controller: address,
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: 4,
            validator: (v) => _required(v, 'Address'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
  });

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppRadius.border,
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: _border(AppColors.backCircle),
            enabledBorder: _border(AppColors.backCircle),
            focusedBorder: _border(AppColors.blue),
            errorBorder: _border(Colors.red),
            focusedErrorBorder: _border(Colors.red),
          ),
        ),
      ],
    );
  }
}