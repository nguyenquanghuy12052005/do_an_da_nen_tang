import 'package:flutter/material.dart';
import 'package:lingosign_ai/app/feature_notice.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureNotice(
      icon: Icons.history,
      message:
          'Lịch sử sẽ xuất hiện sau khi bạn xác nhận một kết quả nhận diện.',
    );
  }
}
