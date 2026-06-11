import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/data/mappers/shareholder_mapper.dart';
import 'package:share_verify/core/data/sources/shareholder_remote_source.dart';
import 'package:share_verify/core/models/shareholder.dart';

abstract class ShareholderRepository {
  Future<Shareholder?> findByKeyword(String keyword);
  Future<ShareholderSearchPageDto> searchShareholders(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  });
  Future<Shareholder?> findByMcd(String mcd);
  Future<RegistrationNoAutocompletePageDto> searchRegistrationNumbers(
    String keyword, {
    int page = 1,
    int pageSize = 20,
    String? identityType,
  });
}

class ShareholderRepositoryImpl implements ShareholderRepository {
  final ShareholderRemoteSource _remoteSource;

  ShareholderRepositoryImpl({required ShareholderRemoteSource remoteSource})
      : _remoteSource = remoteSource;

  @override
  Future<ShareholderSearchPageDto> searchShareholders(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return const ShareholderSearchPageDto(
        items: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
      );
    }

    return _remoteSource.search(
      normalized,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Shareholder?> findByKeyword(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return null;

    final page = await _remoteSource.search(normalized);
    final results = page.items;
    if (results.isEmpty) return null;

    final exactRegistration = results.where(
      (item) =>
          item.registrationNo != null &&
          item.registrationNo!.trim() == normalized,
    );
    if (exactRegistration.isNotEmpty) {
      final match = exactRegistration.first;
      if (match.travelSupportReceived) {
        final detail = await _remoteSource.getDetail(match.mcd);
        return ShareholderMapper.fromDetailDto(detail);
      }
      return ShareholderMapper.fromSearchDto(
        match,
        idNumberOverride: normalized,
      );
    }

    final exactMcd = results.where(
      (item) => item.mcd.toLowerCase() == normalized.toLowerCase(),
    );
    if (exactMcd.isNotEmpty) {
      final match = exactMcd.first;
      if (match.travelSupportReceived) {
        final detail = await _remoteSource.getDetail(match.mcd);
        return ShareholderMapper.fromDetailDto(detail);
      }
      if (match.registrationNo != null && match.registrationNo!.isNotEmpty) {
        return ShareholderMapper.fromSearchDto(match);
      }
      final detail = await _remoteSource.getDetail(match.mcd);
      return ShareholderMapper.fromDetailDto(detail);
    }

    if (results.length == 1) {
      final match = results.first;
      if (match.travelSupportReceived) {
        final detail = await _remoteSource.getDetail(match.mcd);
        return ShareholderMapper.fromDetailDto(detail);
      }
      if (match.registrationNo != null && match.registrationNo!.isNotEmpty) {
        return ShareholderMapper.fromSearchDto(
          match,
          idNumberOverride: normalized,
        );
      }
      final detail = await _remoteSource.getDetail(match.mcd);
      return ShareholderMapper.fromDetailDto(detail);
    }

    return null;
  }

  @override
  Future<Shareholder?> findByMcd(String mcd) async {
    final normalized = mcd.trim();
    if (normalized.isEmpty) return null;
    final dto = await _remoteSource.getDetail(normalized);
    return ShareholderMapper.fromDetailDto(dto);
  }

  @override
  Future<RegistrationNoAutocompletePageDto> searchRegistrationNumbers(
    String keyword, {
    int page = 1,
    int pageSize = 20,
    String? identityType,
  }) {
    return _remoteSource.searchRegistrationNumbers(
      keyword.trim(),
      page: page,
      pageSize: pageSize,
      identityType: identityType,
    );
  }
}
