import '../models/models.dart';
import 'api_client.dart';
import 'session.dart';

class CoreCatalogApi {
  CoreCatalogApi._(this._client);

  static final CoreCatalogApi instance =
      CoreCatalogApi._(ApiClient(Session.instance));

  final ApiClient _client;

  Session get session => _client.session;

  List<Map<String, dynamic>> _list(dynamic data) =>
      (data as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  Future<void> login(String email, String password) async {
    final data = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
    await session.signIn(data['access_token'] as String);
  }

  Future<void> register(String name, String email, String password) async {
    final data = await _client.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    await session.signIn(data['access_token'] as String);
  }

  Future<List<CatalogComponent>> components() async =>
      _list(await _client.get('/components'))
          .map(CatalogComponent.fromJson)
          .toList();

  Future<void> createComponent({
    required String name,
    required String category,
    required int priceCents,
    required int powerWatts,
    required int manufacturerId,
  }) async {
    await _client.post('/components', {
      'name': name,
      'category': category,
      'priceCents': priceCents,
      'powerWatts': powerWatts,
      'manufacturerId': manufacturerId,
    });
  }

  Future<void> updateComponent(
    int id, {
    required String name,
    required String category,
    required int priceCents,
    required int powerWatts,
    required int manufacturerId,
  }) async {
    await _client.patch('/components/$id', {
      'name': name,
      'category': category,
      'priceCents': priceCents,
      'powerWatts': powerWatts,
      'manufacturerId': manufacturerId,
    });
  }

  Future<void> deleteComponent(int id) async {
    await _client.delete('/components/$id');
  }

  Future<List<Manufacturer>> manufacturers() async =>
      _list(await _client.get('/manufacturers'))
          .map(Manufacturer.fromJson)
          .toList();

  Future<void> createManufacturer(String name) async {
    await _client.post('/manufacturers', {'name': name});
  }

  Future<void> updateManufacturer(int id, String name) async {
    await _client.patch('/manufacturers/$id', {'name': name});
  }

  Future<void> deleteManufacturer(int id) async {
    await _client.delete('/manufacturers/$id');
  }

  Future<List<BuildListItem>> myBuilds() async =>
      _list(await _client.get('/builds/mine'))
          .map(BuildListItem.fromJson)
          .toList();

  Future<BuildListItem> createBuild(String name, int maxBudgetCents) async {
    final data = await _client.post('/builds', {
      'name': name,
      'maxBudgetCents': maxBudgetCents,
    });
    return BuildListItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBuild(int id) async {
    await _client.delete('/builds/$id');
  }

  Future<void> addBuildItem(int buildId, int componentId,
      {int quantity = 1}) async {
    await _client.post('/builds/$buildId/items', {
      'componentId': componentId,
      'quantity': quantity,
    });
  }

  Future<BuildSummary> buildSummary(int buildId) async {
    final data = await _client.get('/builds/$buildId/summary');
    return BuildSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<Profile?> myProfile() async {
    final data = await _client.get('/profiles/me');
    if (data is Map<String, dynamic>) return Profile.fromJson(data);
    return null;
  }

  Map<String, dynamic> _profileFields({
    required String fullName,
    String? birthDate,
    String? avatarUrl,
  }) {
    return {
      'fullName': fullName,
      if (birthDate != null && birthDate.isNotEmpty) 'birthDate': birthDate,
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
    };
  }

  Future<Profile> createMyProfile({
    required String fullName,
    String? birthDate,
    String? avatarUrl,
  }) async {
    final data = await _client.post(
      '/profiles/me',
      _profileFields(
          fullName: fullName, birthDate: birthDate, avatarUrl: avatarUrl),
    );
    return Profile.fromJson(data as Map<String, dynamic>);
  }

  Future<Profile> updateProfile(
    int id, {
    required String fullName,
    String? birthDate,
    String? avatarUrl,
  }) async {
    final data = await _client.patch(
      '/profiles/$id',
      _profileFields(
          fullName: fullName, birthDate: birthDate, avatarUrl: avatarUrl),
    );
    return Profile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Profile>> profiles() async =>
      _list(await _client.get('/profiles')).map(Profile.fromJson).toList();

  Future<void> createProfile({
    required int userId,
    required String fullName,
    String? birthDate,
    String? avatarUrl,
  }) async {
    await _client.post('/profiles', {
      'userId': userId,
      ..._profileFields(
          fullName: fullName, birthDate: birthDate, avatarUrl: avatarUrl),
    });
  }

  Future<void> deleteProfile(int id) async {
    await _client.delete('/profiles/$id');
  }

  Future<List<AppUser>> users() async =>
      _list(await _client.get('/users')).map(AppUser.fromJson).toList();

  Future<void> createUser(String name, String email, String password) async {
    await _client.post('/users', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> updateUser(int id, String name, String email) async {
    await _client.patch('/users/$id', {'name': name, 'email': email});
  }

  Future<void> deleteUser(int id) async {
    await _client.delete('/users/$id');
  }
}
