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
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Informasi Pengiriman',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'Nama depan',
                  controller: firstName,
                  validator: (v) => _required(v, 'Nama depan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  label: 'Nama belakang',
                  controller: lastName,
                  validator: (v) => _required(v, 'Nama belakang'),
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
              if (value.isEmpty) return 'Email wajib diisi';
              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
              return ok ? null : 'Email tidak valid';
            },
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Nomor telepon',
            controller: phone,
            keyboardType: TextInputType.phone,
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isEmpty) return 'Nomor telepon wajib diisi';
              return digits.length >= 8 && digits.length <= 15
                  ? null
                  : 'Nomor telepon tidak valid';
            },
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Alamat',
            controller: address,
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: 4,
            validator: (v) => _required(v, 'Alamat'),
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