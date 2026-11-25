/// Modelos que espelham as respostas da API core-catalog (NestJS + Prisma).
library;

int _int(dynamic value) => value is num ? value.toInt() : int.parse('$value');

/// GET /components
class CatalogComponent {
  final int id;
  final String name;
  final String category;
  final int priceCents;
  final int powerWatts;
  final String manufacturerName;

  const CatalogComponent({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    required this.powerWatts,
    required this.manufacturerName,
  });

  factory CatalogComponent.fromJson(Map<String, dynamic> json) {
    final manufacturer = json['manufacturer'];
    return CatalogComponent(
      id: _int(json['id']),
      name: json['name'] as String,
      category: json['category'] as String,
      priceCents: _int(json['priceCents']),
      powerWatts: _int(json['powerWatts']),
      manufacturerName: manufacturer is Map ? '${manufacturer['name']}' : '',
    );
  }
}

/// GET /manufacturers
class Manufacturer {
  final int id;
  final String name;

  const Manufacturer({required this.id, required this.name});

  factory Manufacturer.fromJson(Map<String, dynamic> json) =>
      Manufacturer(id: _int(json['id']), name: json['name'] as String);
}

/// GET /builds/mine e POST /builds
class BuildListItem {
  final int id;
  final String name;
  final int maxBudgetCents;

  const BuildListItem({
    required this.id,
    required this.name,
    required this.maxBudgetCents,
  });

  factory BuildListItem.fromJson(Map<String, dynamic> json) => BuildListItem(
        id: _int(json['id']),
        name: json['name'] as String,
        maxBudgetCents: _int(json['maxBudgetCents']),
      );
}

/// Item de GET /builds/:id/summary
class BuildSummaryItem {
  final int componentId;
  final String name;
  final String category;
  final String manufacturer;
  final int unitPriceCents;
  final int powerWatts;
  final int quantity;
  final int subtotalCents;

  const BuildSummaryItem({
    required this.componentId,
    required this.name,
    required this.category,
    required this.manufacturer,
    required this.unitPriceCents,
    required this.powerWatts,
    required this.quantity,
    required this.subtotalCents,
  });

  factory BuildSummaryItem.fromJson(Map<String, dynamic> json) =>
      BuildSummaryItem(
        componentId: _int(json['componentId']),
        name: json['name'] as String,
        category: json['category'] as String,
        manufacturer: '${json['manufacturer'] ?? ''}',
        unitPriceCents: _int(json['unitPriceCents']),
        powerWatts: _int(json['powerWatts']),
        quantity: _int(json['quantity']),
        subtotalCents: _int(json['subtotalCents']),
      );
}

/// GET /builds/:id/summary
class BuildSummary {
  final String name;
  final String owner;
  final int totalCents;
  final int totalWatts;
  final int maxBudgetCents;
  final bool overBudget;
  final List<BuildSummaryItem> items;

  const BuildSummary({
    required this.name,
    required this.owner,
    required this.totalCents,
    required this.totalWatts,
    required this.maxBudgetCents,
    required this.overBudget,
    required this.items,
  });

  int get remainingCents => maxBudgetCents - totalCents;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  factory BuildSummary.fromJson(Map<String, dynamic> json) => BuildSummary(
        name: json['name'] as String,
        owner: '${json['owner'] ?? ''}',
        totalCents: _int(json['totalCents']),
        totalWatts: _int(json['totalWatts']),
        maxBudgetCents: _int(json['maxBudgetCents']),
        overBudget: json['overBudget'] == true,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => BuildSummaryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// GET /profiles/me (sem `user`) e GET /profiles (com `user`)
class Profile {
  final int id;
  final int userId;
  final String fullName;

  /// ISO vindo da API, ex.: "1990-01-15T00:00:00.000Z".
  final String? birthDate;
  final String? avatarUrl;
  final String? userName;
  final String? userEmail;

  const Profile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.birthDate,
    this.avatarUrl,
    this.userName,
    this.userEmail,
  });

  /// "AAAA-MM-DD" para preencher o formulário.
  String? get birthDateOnly =>
      birthDate != null && birthDate!.length >= 10
          ? birthDate!.substring(0, 10)
          : null;

  factory Profile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return Profile(
      id: _int(json['id']),
      userId: _int(json['userId']),
      fullName: json['fullName'] as String,
      birthDate: json['birthDate'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      userName: user is Map ? user['name'] as String? : null,
      userEmail: user is Map ? user['email'] as String? : null,
    );
  }
}

/// GET /users
class AppUser {
  final int id;
  final String name;
  final String email;

  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: _int(json['id']),
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

/// Dados de quem está logado, lidos do payload do JWT ({ sub, email, name }).
class SessionUser {
  final int id;
  final String name;
  final String email;

  const SessionUser({required this.id, required this.name, required this.email});
}
