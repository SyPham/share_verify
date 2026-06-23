import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/sources/shareholder_remote_source.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';

void main() {
  test(
      'listShareholders delegates to remote list endpoint with trimmed keyword',
      () async {
    final remote = _FakeShareholderRemoteSource();
    final repository = ShareholderRepositoryImpl(remoteSource: remote);

    final result = await repository.listShareholders(
      received: true,
      keyword: '  nguyen van a  ',
      page: 2,
      pageSize: 15,
    );

    expect(remote.received, isTrue);
    expect(remote.keyword, 'nguyen van a');
    expect(remote.page, 2);
    expect(remote.pageSize, 15);
    expect(result.totalCount, 1);
    expect(result.page, 2);
    expect(result.pageSize, 15);
    expect(result.items.single.mcd, 'MCD001');
  });
}

class _FakeShareholderRemoteSource extends ShareholderRemoteSource {
  _FakeShareholderRemoteSource() : super(ApiClient(dio: Dio()));

  bool? received;
  String? keyword;
  int? page;
  int? pageSize;

  @override
  Future<ShareholderSearchPageDto> list({
    required bool received,
    String keyword = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    this.received = received;
    this.keyword = keyword;
    this.page = page;
    this.pageSize = pageSize;

    return ShareholderSearchPageDto(
      items: const [
        ShareholderSearchDto(
          mcd: 'MCD001',
          fullName: 'Nguyen Van A',
          registrationNo: '079090001234',
          totalShares: 100,
          travelSupportReceived: true,
        ),
      ],
      totalCount: 1,
      page: page,
      pageSize: pageSize,
    );
  }
}
