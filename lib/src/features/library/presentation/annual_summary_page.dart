import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class AnnualSummaryPage extends StatelessWidget {
  const AnnualSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, int>>(
      future: _loadCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('暂时无法读取年度播放数据'));
        }

        final counts = snapshot.data ?? const <int, int>{};
        final currentYear = DateTime.now().year;
        final currentCount = counts[currentYear] ?? 0;
        final total = counts.values.fold<int>(0, (sum, count) => sum + count);
        final years = counts.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
          children: [
            Text('年度总结', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '记录每一次播放，让音乐留下可以回看的轨迹。',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: '$currentYear 年播放',
                    value: '$currentCount',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SummaryCard(label: '累计播放', value: '$total'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('年度记录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (years.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('播放真实本地歌曲后，这里会显示年度记录。'),
                ),
              )
            else
              for (final year in years)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text('$year 年'),
                  trailing: Text('${counts[year]} 次'),
                ),
          ],
        );
      },
    );
  }

  Future<Map<int, int>> _loadCounts() async {
    final database = await sharedLinglunDatabase();
    return database.yearlyPlayCounts();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
