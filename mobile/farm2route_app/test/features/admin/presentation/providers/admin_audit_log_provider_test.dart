import 'package:farm2route_app/core/network/api_client.dart';
import 'package:farm2route_app/core/storage/secure_storage.dart';
import 'package:farm2route_app/features/admin/data/models/audit_log_model.dart';
import 'package:farm2route_app/features/admin/data/repositories/admin_repository.dart';
import 'package:farm2route_app/features/admin/presentation/providers/admin_audit_log_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService extends Fake implements SecureStorageService {}

class MockApiClient extends ApiClient {
  MockApiClient() : super(storage: FakeSecureStorageService());

  Map<String, dynamic>? lastQueryParams;
  String? lastPath;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    return {
      'status': 'success',
      'data': {
        'content': [
          {
            'id': 'log-001',
            'actorId': 'actor-123',
            'actorRole': 'ROLE_ADMIN',
            'action': 'KycReviewed',
            'entityName': 'VehicleProfile',
            'entityId': 'vehicle-999',
            'oldValue': '{"kycStatus": "PENDING"}',
            'newValue': '{"kycStatus": "APPROVED"}',
            'ipAddress': '127.0.0.1',
            'userAgent': 'Chrome/128.0',
            'createdAt': '2026-09-15T10:00:00Z',
          }
        ],
        'pageNumber': 0,
        'pageSize': 20,
        'totalElements': 1,
        'totalPages': 1,
        'last': true,
      },
    };
  }
}

void main() {
  late MockApiClient mockApiClient;
  late AdminRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = AdminRepository(mockApiClient);
  });

  test('getAuditLogs builds query parameters and parses PagedAuditLogModel correctly', () async {
    final result = await repository.getAuditLogs(
      action: 'KycReviewed',
      entityName: 'VehicleProfile',
      actorId: 'actor-123',
      fromDate: '2026-09-01T00:00:00Z',
      toDate: '2026-09-15T23:59:59Z',
      page: 1,
      size: 15,
    );

    expect(mockApiClient.lastPath, equals('/admin/audit-logs'));
    expect(mockApiClient.lastQueryParams?['action'], equals('KycReviewed'));
    expect(mockApiClient.lastQueryParams?['entityName'], equals('VehicleProfile'));
    expect(mockApiClient.lastQueryParams?['actorId'], equals('actor-123'));
    expect(mockApiClient.lastQueryParams?['fromDate'], equals('2026-09-01T00:00:00Z'));
    expect(mockApiClient.lastQueryParams?['toDate'], equals('2026-09-15T23:59:59Z'));
    expect(mockApiClient.lastQueryParams?['page'], equals(1));
    expect(mockApiClient.lastQueryParams?['size'], equals(15));

    expect(result.content.length, equals(1));
    final item = result.content.first;
    expect(item.id, equals('log-001'));
    expect(item.action, equals('KycReviewed'));
    expect(item.entityName, equals('VehicleProfile'));
    expect(item.oldValue, contains('PENDING'));
    expect(item.newValue, contains('APPROVED'));
  });

  test('AdminAuditLogNotifier manages filters and pagination state correctly', () async {
    final container = ProviderContainer(
      overrides: [
        adminAuditLogProvider.overrideWith(
          (ref) => AdminAuditLogNotifier(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(adminAuditLogProvider.notifier);
    await notifier.fetchLogs(page: 0);

    var state = container.read(adminAuditLogProvider);
    expect(state.isLoading, isFalse);
    expect(state.logs.length, equals(1));

    notifier.setActionFilter('RESOLVED');
    state = container.read(adminAuditLogProvider);
    expect(state.actionFilter, equals('RESOLVED'));
    expect(mockApiClient.lastQueryParams?['action'], equals('RESOLVED'));

    notifier.resetFilters();
    state = container.read(adminAuditLogProvider);
    expect(state.actionFilter, isNull);
  });
}
