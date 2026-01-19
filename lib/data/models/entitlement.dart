/// 課金状態を表すEnum
enum Entitlement {
  free,
  pro,
}

/// 課金状態の詳細を保持するクラス
class EntitlementState {
  final Entitlement entitlement;
  final DateTime? expiresAt;
  final String? subscriptionType; // 'monthly' | 'yearly' | null

  const EntitlementState({
    this.entitlement = Entitlement.free,
    this.expiresAt,
    this.subscriptionType,
  });

  /// Proプランかどうか
  bool get isPro => entitlement == Entitlement.pro;

  /// Freeプランかどうか
  bool get isFree => entitlement == Entitlement.free;

  /// 有効期限切れかどうか（nullの場合はfalse）
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 有効なProプランかどうか（期限切れでないPro）
  bool get isActivePro => isPro && !isExpired;

  EntitlementState copyWith({
    Entitlement? entitlement,
    DateTime? expiresAt,
    String? subscriptionType,
  }) {
    return EntitlementState(
      entitlement: entitlement ?? this.entitlement,
      expiresAt: expiresAt ?? this.expiresAt,
      subscriptionType: subscriptionType ?? this.subscriptionType,
    );
  }

  @override
  String toString() {
    return 'EntitlementState(entitlement: $entitlement, expiresAt: $expiresAt, subscriptionType: $subscriptionType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EntitlementState &&
        other.entitlement == entitlement &&
        other.expiresAt == expiresAt &&
        other.subscriptionType == subscriptionType;
  }

  @override
  int get hashCode {
    return entitlement.hashCode ^ expiresAt.hashCode ^ subscriptionType.hashCode;
  }
}
