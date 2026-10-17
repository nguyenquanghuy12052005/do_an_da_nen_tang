import 'package:flutter/material.dart';
import 'package:lingosign_ai/app/feature_notice.dart';

class DictionaryPage extends StatelessWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureNotice(
      icon: Icons.menu_book,
      message: 'Từ điển chưa có nội dung được xác minh.',
    );
  }
}
