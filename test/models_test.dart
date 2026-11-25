import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:core_catalog_mobile/models/models.dart';
import 'package:core_catalog_mobile/services/session.dart';

void main() {
  test('CatalogComponent.fromJson (GET /components)', () {
    final c = CatalogComponent.fromJson({
      'id': 1,
      'name': 'Ryzen 7 7800X3D',
      'category': 'CPU',
      'priceCents': 189900,
      'powerWatts': 120,
      'manufacturer': {'name': 'AMD'},
    });
    expect(c.manufacturerName, 'AMD');
    expect(c.priceCents, 189900);
  });

  test('BuildSummary.fromJson (GET /builds/:id/summary)', () {
    final s = BuildSummary.fromJson({
      'name': 'PC Gamer 2026',
      'owner': 'João',
      'totalCents': 619800,
      'totalWatts': 340,
      'maxBudgetCents': 800000,
      'overBudget': false,
      'items': [
        {
          'componentId': 1,
          'name': 'Ryzen 7 7800X3D',
          'category': 'CPU',
          'manufacturer': 'AMD',
          'unitPriceCents': 189900,
          'powerWatts': 120,
          'quantity': 1,
          'subtotalCents': 189900,
        },
      ],
    });
    expect(s.items.single.category, 'CPU');
    expect(s.remainingCents, 180200);
    expect(s.totalQuantity, 1);
  });

  test('Profile.fromJson com e sem user', () {
    final me = Profile.fromJson({
      'id': 3,
      'userId': 7,
      'fullName': 'João da Silva',
      'birthDate': '2003-05-10T00:00:00.000Z',
      'avatarUrl': null,
    });
    expect(me.birthDateOnly, '2003-05-10');
    expect(me.userName, isNull);

    final admin = Profile.fromJson({
      'id': 3,
      'userId': 7,
      'fullName': 'João da Silva',
      'birthDate': null,
      'avatarUrl': null,
      'user': {'name': 'João', 'email': 'joao@exemplo.com'},
    });
    expect(admin.userEmail, 'joao@exemplo.com');
  });

  test('Session.decodeJwtPayload lê { sub, email, name }', () {
    String part(Map<String, dynamic> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final token = [
      part({'alg': 'HS256', 'typ': 'JWT'}),
      part({'sub': 7, 'email': 'joao@exemplo.com', 'name': 'João'}),
      'assinatura',
    ].join('.');
    final payload = Session.decodeJwtPayload(token);
    expect(payload?['sub'], 7);
    expect(payload?['name'], 'João');
  });
}
