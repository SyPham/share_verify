import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/models/open_ai_stats.dart';
import 'package:share_verify/core/models/open_ai_usage_info.dart';
import 'package:share_verify/core/services/open_ai_usage_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('buildLocalOpenAiStats aggregates records', () {
    final stats = buildLocalOpenAiStats([
      OpenAiUsageRecord.fromUsage(
        usage: const OpenAiUsageInfo(
          model: 'gpt-4o-mini',
          promptTokens: 100,
          completionTokens: 20,
          totalTokens: 120,
          costUsd: 0.000027,
          costVnd: 1,
        ),
        docType: 'CMND',
      ),
      OpenAiUsageRecord.fromUsage(
        usage: const OpenAiUsageInfo(
          model: 'gpt-4o-mini',
          promptTokens: 200,
          completionTokens: 30,
          totalTokens: 230,
          costUsd: 0.000050,
          costVnd: 2,
        ),
        docType: 'CMND',
      ),
    ]);

    expect(stats.source, 'device');
    expect(stats.summary.requestCount, 2);
    expect(stats.summary.totalTokens, 350);
    expect(stats.summary.totalCostUsd, closeTo(0.000077, 0.000001));
    expect(stats.byModel.single.requestCount, 2);
  });

  test('OpenAiUsageStore persists and loads records', () async {
    final store = OpenAiUsageStore();
    await store.addUsage(
      usage: const OpenAiUsageInfo(
        model: 'gpt-4o',
        promptTokens: 850,
        completionTokens: 42,
        totalTokens: 892,
        costUsd: 0.000153,
        costVnd: 4,
      ),
      docType: 'CMND',
      identityNo: '174324001',
      fullName: 'NGUYỄN HOÀI LINH',
    );

    final stats = await store.loadLocalStats();
    expect(stats.summary.requestCount, 1);
    expect(stats.recent.single.idNumber, '174324001');
    expect(stats.recent.single.fullName, 'NGUYỄN HOÀI LINH');

    await store.clear();
    final cleared = await store.loadLocalStats();
    expect(cleared.summary.requestCount, 0);
  });
}
