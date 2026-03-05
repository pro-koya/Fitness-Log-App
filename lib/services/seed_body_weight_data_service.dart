import 'dart:math';
import '../data/dao/body_weight_dao.dart';
import '../data/database/unit_converter.dart';
import '../data/entities/body_weight_entity.dart';

/// 体重記録のグラフ・動作確認用に、テスト用の体重データを登録するサービス。
/// デバッグビルドでのみ利用想定。
class SeedBodyWeightDataService {
  SeedBodyWeightDataService({BodyWeightDao? bodyWeightDao})
      : _bodyWeightDao = bodyWeightDao ?? BodyWeightDao();

  final BodyWeightDao _bodyWeightDao;
  final _random = Random(123); // 固定シードで再現可能に

  /// 過去約6ヶ月分の体重記録を登録する（週2〜3回程度の記録を想定）
  /// 返り値は登録した件数
  Future<int> seed() async {
    const recordsCount = 52; // 約6ヶ月で週2回ペース
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 180));

    double baseKg = 68.0 + _random.nextDouble() * 4; // 68〜72kg 付近から開始
    int count = 0;

    for (int i = 0; i < recordsCount; i++) {
      final daysOffset = (i * 180 / (recordsCount - 1)).round();
      final recordDate = startDate.add(Duration(days: daysOffset));
      final dateOnly = DateTime(recordDate.year, recordDate.month, recordDate.day);
      final recordedAt = dateOnly.millisecondsSinceEpoch ~/ 1000;

      // わずかな変動と緩やかなトレンド
      final trend = (i / recordsCount) * 2.0 - 1.0; // -1〜+1 kg の変化
      final noise = (_random.nextDouble() - 0.5) * 1.5;
      final weightKg = (baseKg + trend + noise).clamp(64.0, 76.0);
      final weightKgRounded = (weightKg * 10).round() / 10.0;
      final weightLb = UnitConverter.kgToLb(weightKgRounded);

      final entity = BodyWeightEntity(
        id: null,
        weightKg: weightKgRounded,
        weightLb: weightLb,
        memo: i % 7 == 0 ? '朝・空腹時' : null,
        recordedAt: recordedAt,
        createdAt: recordedAt,
        updatedAt: recordedAt,
      );

      await _bodyWeightDao.insert(entity);
      count++;
    }

    return count;
  }
}
