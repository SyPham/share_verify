import 'package:share_verify/core/data/dto/shareholder_dtos.dart';
import 'package:share_verify/core/data/dto/registration_no_autocomplete_dtos.dart';
import 'package:share_verify/core/data/dto/photo_dtos.dart';
import 'package:share_verify/core/data/dto/travel_support_dtos.dart';
import 'package:share_verify/core/network/api_exception.dart';
import 'package:share_verify/core/models/attendance_type.dart';
import 'package:share_verify/core/models/dashboard_stats.dart';
import 'package:share_verify/core/models/identity_verification.dart';
import 'package:share_verify/core/models/payment_status.dart';
import 'package:share_verify/core/models/recipient_check_in.dart';
import 'package:share_verify/core/models/recipient_detail.dart';
import 'package:share_verify/core/models/recipient_list_item.dart';
import 'package:share_verify/core/models/shareholder.dart';
import 'package:share_verify/core/repositories/dashboard_repository.dart';
import 'package:share_verify/core/repositories/recipient_repository.dart';
import 'package:share_verify/core/repositories/shareholder_repository.dart';
import 'package:share_verify/core/repositories/travel_support_repository.dart';
import 'package:share_verify/core/utils/allowance_amount.dart';
import 'package:share_verify/core/utils/identity_type_utils.dart';
import '../fixtures/test_data.dart';

class FakeShareholderRepository implements ShareholderRepository {
  final Map<String, Shareholder?> results;

  FakeShareholderRepository({Map<String, Shareholder?>? results})
      : results = results ?? {};

  @override
  Future<Shareholder?> findByKeyword(String keyword) async {
    if (results.containsKey(keyword)) {
      return results[keyword];
    }
    return TestData.findByIdNumber(keyword);
  }

  @override
  Future<Shareholder?> findByMcd(String mcd) async {
    if (results.containsKey(mcd)) {
      return results[mcd];
    }
    return TestData.findByMcd(mcd);
  }

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

    final all = <ShareholderSearchDto>[];
    for (final entry in results.entries) {
      final sh = entry.value;
      if (sh == null) continue;
      if (_matchesKeyword(sh, normalized)) {
        all.add(_toSearchDto(sh));
      }
    }

    for (final sh in TestData.shareholders) {
      if (_matchesKeyword(sh, normalized) &&
          !all.any((item) => item.mcd == sh.code)) {
        all.add(_toSearchDto(sh));
      }
    }

    all.sort((a, b) => a.fullName.compareTo(b.fullName));
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, all.length);
    final items =
        start < all.length ? all.sublist(start, end) : <ShareholderSearchDto>[];

    return ShareholderSearchPageDto(
      items: items,
      totalCount: all.length,
      page: page,
      pageSize: pageSize,
    );
  }

  bool _matchesReceived(Shareholder sh, bool received) {
    final isReceived = sh.status == PaymentStatus.received;
    return isReceived == received;
  }

  bool _matchesKeywordOptional(Shareholder sh, String keyword) {
    if (keyword.isEmpty) return true;
    return _matchesKeyword(sh, keyword);
  }

  bool _matchesKeyword(Shareholder sh, String keyword) {
    final lower = keyword.toLowerCase();
    return sh.code.toLowerCase().contains(lower) ||
        sh.fullName.toLowerCase().contains(lower) ||
        sh.idNumber.toLowerCase().contains(lower);
  }

  ShareholderSearchDto _toSearchDto(Shareholder sh) {
    return ShareholderSearchDto(
      mcd: sh.code,
      fullName: sh.fullName,
      registrationNo: sh.idNumber.isNotEmpty ? sh.idNumber : null,
      totalShares: sh.shares,
      travelSupportReceived: sh.status == PaymentStatus.received,
    );
  }

  @override
  Future<ShareholderSearchPageDto> listShareholders({
    required bool received,
    String keyword = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final normalized = keyword.trim().toLowerCase();

    final all = <ShareholderSearchDto>[];
    for (final entry in results.entries) {
      final sh = entry.value;
      if (sh == null) continue;
      if (_matchesReceived(sh, received) &&
          _matchesKeywordOptional(sh, normalized)) {
        all.add(_toSearchDto(sh));
      }
    }

    for (final sh in TestData.shareholders) {
      if (_matchesReceived(sh, received) &&
          _matchesKeywordOptional(sh, normalized) &&
          !all.any((item) => item.mcd == sh.code)) {
        all.add(_toSearchDto(sh));
      }
    }

    all.sort((a, b) => a.fullName.compareTo(b.fullName));
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, all.length);
    final items =
        start < all.length ? all.sublist(start, end) : <ShareholderSearchDto>[];

    return ShareholderSearchPageDto(
      items: items,
      totalCount: all.length,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<RegistrationNoAutocompletePageDto> searchRegistrationNumbers(
    String keyword, {
    int page = 1,
    int pageSize = 20,
    String? identityType,
  }) async {
    final pageResult = await searchShareholders(
      keyword,
      page: page,
      pageSize: pageSize,
    );
    return RegistrationNoAutocompletePageDto(
      items: pageResult.items
          .where(
            (item) =>
                item.registrationNo != null && item.registrationNo!.isNotEmpty,
          )
          .map(
            (item) => RegistrationNoAutocompleteItemDto(
              registrationNo: item.registrationNo!,
              identityType: identityType ?? 'CCCD',
              mcd: item.mcd,
              fullName: item.fullName,
            ),
          )
          .toList(),
      totalCount: pageResult.totalCount,
      page: pageResult.page,
      pageSize: pageResult.pageSize,
    );
  }

  @override
  Future<RegistrationNoAutocompleteItemDto?> lookupRegistrationNumber(
    String registrationNo, {
    String? identityType,
  }) async {
    final normalized = registrationNo.trim();
    if (normalized.isEmpty) return null;

    final page = await searchRegistrationNumbers(
      normalized,
      identityType: identityType,
    );
    final compactInput = compactIdentityNumber(normalized);
    for (final item in page.items) {
      if (compactIdentityNumber(item.registrationNo) == compactInput) {
        return item;
      }
    }
    return null;
  }
}

class FakeRecipientRepository implements RecipientRepository {
  RecipientSearchPage searchResult = const RecipientSearchPage(
    items: [],
    totalCount: 0,
    page: 1,
    pageSize: 20,
  );
  RecipientDetail? detailResult;
  Object? searchError;
  Object? detailError;

  String lastKeyword = '';
  int lastPage = 1;
  int lastPageSize = 20;
  bool lastGroupByPerson = false;
  int? lastMinLinkedMcd;
  int? lastPersonId;

  @override
  Future<RecipientSearchPage> search({
    String keyword = '',
    int page = 1,
    int pageSize = 20,
    bool groupByPerson = false,
    int? minLinkedMcd,
  }) async {
    lastKeyword = keyword;
    lastPage = page;
    lastPageSize = pageSize;
    lastGroupByPerson = groupByPerson;
    lastMinLinkedMcd = minLinkedMcd;

    if (searchError != null) throw searchError!;
    return searchResult;
  }

  @override
  Future<RecipientDetail> getDetail(int personId) async {
    lastPersonId = personId;
    if (detailError != null) throw detailError!;
    return detailResult ??
        const RecipientDetail(
          personId: 0,
          personFullName: '',
          checkIns: <RecipientCheckIn>[],
        );
  }
}

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getSummary() async => TestData.dashboardStats;
}

class FakeTravelSupportRepository implements TravelSupportRepository {
  bool shouldThrowConflict = false;
  int receiveCallCount = 0;
  int checkIdentityCallCount = 0;
  IdentityCheckResultDto checkIdentityResult =
      const IdentityCheckResultDto(alreadyUsed: false);
  Shareholder? lastShareholder;
  IdentityVerification? lastIdentity;
  AttendanceType? lastAttendanceType;
  String? lastProxyPersonName;
  String? lastProxyIdentityNo;
  String? lastProxyIdentityType;
  String? lastPhotoPath;
  List<int>? lastUploadedBytes;
  String? lastUploadedFileName;
  num lastReceiveAmount = 0;

  @override
  Future<void> receive({
    required Shareholder shareholder,
    required IdentityVerification identity,
    required AttendanceType attendanceType,
    String? proxyPersonName,
    String? proxyIdentityNo,
    String? proxyIdentityType,
    String? photoPath,
    num receiveAmount = 0,
  }) async {
    receiveCallCount++;
    lastShareholder = shareholder;
    lastIdentity = identity;
    lastAttendanceType = attendanceType;
    lastProxyPersonName = proxyPersonName;
    lastProxyIdentityNo = proxyIdentityNo;
    lastProxyIdentityType = proxyIdentityType;
    lastPhotoPath = photoPath;
    lastReceiveAmount = receiveAmount > 0
        ? receiveAmount
        : AllowanceAmount.forShareholder(shareholder);

    if (shouldThrowConflict) {
      throw const ApiException(
        message: 'Travel support has already been received.',
        statusCode: 409,
      );
    }
  }

  @override
  Future<PhotoUploadResultDto?> uploadPhoto({
    required List<int> bytes,
    required String fileName,
  }) async {
    lastUploadedBytes = List<int>.from(bytes);
    lastUploadedFileName = fileName;
    return const PhotoUploadResultDto(photoPath: 'uploads/test.jpg');
  }

  @override
  Future<IdentityCheckResultDto> checkIdentity({
    required String identityNo,
    required String identityType,
    String? fullName,
    String? dateOfBirth,
  }) async {
    checkIdentityCallCount++;
    return checkIdentityResult;
  }
}
