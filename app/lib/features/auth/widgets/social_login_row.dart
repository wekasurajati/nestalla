import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Atau lanjutkan dengan', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              // TODO minggu 2: Google sign-in
              onPressed: () {},
              icon: const FaIcon(FontAwesomeIcons.google,
                  size: 26, color: Color(0xFFDB4437)),
            ),
            const SizedBox(width: 12),
            IconButton(
              // TODO minggu 2: Facebook sign-in
              onPressed: () {},
              icon: const FaIcon(FontAwesomeIcons.facebook,
                  size: 26, color: Color(0xFF1877F2)),
            ),
          ],
        ),
      ],
    );
  }
}