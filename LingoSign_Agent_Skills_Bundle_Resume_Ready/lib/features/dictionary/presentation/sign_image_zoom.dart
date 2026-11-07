import 'package:flutter/material.dart';

class SignImageZoom extends StatelessWidget {
  const SignImageZoom({
    super.key,
    required this.asset,
    required this.label,
    required this.child,
  });

  final String asset;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Phóng to ảnh $label',
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Ảnh minh họa $label'),
              leading: IconButton(
                tooltip: 'Đóng ảnh',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            body: SafeArea(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: SizedBox.expand(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    semanticLabel: 'Minh họa $label',
                    errorBuilder: (_, _, _) => const Center(
                      child: Text('Ảnh hướng dẫn chưa khả dụng.'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: child,
    ),
  );
}
