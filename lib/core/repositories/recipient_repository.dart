import 'package:share_verify/core/data/mappers/recipient_mapper.dart';
import 'package:share_verify/core/data/sources/recipient_remote_source.dart';
import 'package:share_verify/core/models/recipient_detail.dart';
import 'package:share_verify/core/models/recipient_list_item.dart';

class RecipientSearchPage {
  final List<RecipientListItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const RecipientSearchPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < totalCount;
}

abstract class RecipientRepository {
  Future<RecipientSearchPage> search({
    String keyword = '',
    int page = 1,
    int pageSize = 20,
  });

  Future<RecipientDetail> getDetail(int personId);
}

class RecipientRepositoryImpl implements RecipientRepository {
  final RecipientRemoteSource _remoteSource;

  RecipientRepositoryImpl({required RecipientRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<RecipientSearchPage> search({
    String keyword = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final pageDto = await _remoteSource.search(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
    );
    return RecipientSearchPage(
      items: pageDto.items.map(RecipientMapper.fromListDto).toList(),
      totalCount: pageDto.totalCount,
      page: pageDto.page,
      pageSize: pageDto.pageSize,
    );
  }

  @override
  Future<RecipientDetail> getDetail(int personId) async {
    final dto = await _remoteSource.getDetail(personId);
    return RecipientMapper.fromDetailDto(dto);
  }
}
