import '../models/models.dart';
import 'api_client.dart';
import 'session.dart';

/// Todas as rotas da API core-catalog usadas pelo app.
class CoreCatalogApi {
  CoreCatalogApi._(this._client);

  static final CoreCatalogApi instance =
      CoreCatalogApi._(ApiClient(Session.instance));

  final ApiClient _client;

  Session get session => _client.session;

  List<Map<String, dynamic>> _list(dynamic data) =>
      (data as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  // ---------------------------------------------------------------- auth

  /// POST /auth/login -> { access_token, user }
  Future<void> login(String email, String password) async {
    final data = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
    await session.signIn(data['access_token'] as String);
  }

  /// POST /auth/register -> já devolve o token, então o usuário entra direto.
  Future<void> register(String name, String email, String password) async {
    final data = await _client.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    await session.signIn(data['access_token'] as String);
  }

  // ---------------------------------------------------------- catálogo

  /// GET /components (público)
  Future<List<CatalogComponent>> components() async =>
      _list(await _client.get('/components'))
          .map(CatalogComponent.fromJson)
          .toList();

  /// POST /components
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

  /// PATCH /components/:id — só os campos enviados são alterados.
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

  /// DELETE /components/:id — a API recusa (409) se a peça estiver em alguma build.
  Future<void> deleteComponent(int id) async {
    await _client.delete('/components/$id');
  }

  /// GET /manufacturers (público)
  Future<List<Manufacturer>> manufacturers() async =>
      _list(await _client.get('/manufacturers'))
          .map(Manufacturer.fromJson)
          .toList();

  /// POST /manufacturers
  Future<void> createManufacturer(String name) async {
    await _client.post('/manufacturers', {'name': name});
  }

  /// PATCH /manufacturers/:id
  Future<void> updateManufacturer(int id, String name) async {
    await _client.patch('/manufacturers/$id', {'name': name});
  }

  /// DELETE /manufacturers/:id — a API recusa (409) se ainda houver peças dele.
  Future<void> deleteManufacturer(int id) async {
    await _client.delete('/manufacturers/$id');
  }

  // ------------------------------------------------------------ builds

  /// GET /builds/mine
  Future<List<BuildListItem>> myBuilds() async =>
      _list(await _client.get('/builds/mine'))
          .map(BuildListItem.fromJson)
          .toList();

  /// POST /builds (o perfil é o do dono do token)
  Future<BuildListItem> createBuild(String name, int maxBudgetCents) async {
    final data = await _client.post('/builds', {
      'name': name,
      'maxBudgetCents': maxBudgetCents,
    });
    return BuildListItem.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /builds/:id — só o dono da build pode excluir.
  Future<void> deleteBuild(int id) async {
    await _client.delete('/builds/$id');
  }

  /// POST /builds/:id/items — a API recusa se passar do orçamento.
  Future<void> addBuildItem(int buildId, int componentId,
      {int quantity = 1}) async {
    await _client.post('/builds/$buildId/items', {
      'componentId': componentId,
      'quantity': quantity,
    });
  }

  /// GET /builds/:id/summary
  Future<BuildSummary> buildSummary(int buildId) async {
    final data = await _client.get('/builds/$buildId/summary');
    return BuildSummary.fromJson(data as Map<String, dynamic>);
  }

  // ----------------------------------------------------------- perfis

  /// GET /profiles/me — null quando o usuário ainda não tem perfil.
  Future<Profile?> myProfile() async {
    final data = await _client.get('/profiles/me');
    if (data is Map<String, dynamic>) return Profile.fromJson(data);
    return null;
  }

  /// Só envia os campos preenchidos (no web, vazio vira undefined).
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

  /// POST /profiles/me
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

  /// PATCH /profiles/:id
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

  /// GET /profiles (admin)
  Future<List<Profile>> profiles() async =>
      _list(await _client.get('/profiles')).map(Profile.fromJson).toList();

  /// POST /profiles (admin, escolhendo o usuário)
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

  /// DELETE /profiles/:id
  Future<void> deleteProfile(int id) async {
    await _client.delete('/profiles/$id');
  }

  // ---------------------------------------------------------- usuários

  /// GET /users
  Future<List<AppUser>> users() async =>
      _list(await _client.get('/users')).map(AppUser.fromJson).toList();

  /// POST /users (a senha vai em texto puro; o back-end gera o hash)
  Future<void> createUser(String name, String email, String password) async {
    await _client.post('/users', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// PATCH /users/:id (nome e e-mail; a senha não muda aqui)
  Future<void> updateUser(int id, String name, String email) async {
    await _client.patch('/users/$id', {'name': name, 'email': email});
  }

  /// DELETE /users/:id
  Future<void> deleteUser(int id) async {
    await _client.delete('/users/$id');
  }
}
