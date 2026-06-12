import 'dart:async';

import 'package:get/get.dart';
import 'package:share_verify/core/models/recipient_list_item.dart';
import 'package:share_verify/core/network/api_client.dart';
import 'package:share_verify/core/repositories/recipient_repository.dart';

class RecipientsListController extends GetxController {
  final RecipientRepository _recipientRepository;

  RecipientsListController({RecipientRepository? recipientRepository})
      : _recipientRepository =
            recipientRepository ?? Get.find<RecipientRepository>();

  final items = <RecipientListItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;
  final totalCount = 0.obs;

  static const _pageSize = 20;
  int _page = 1;
  bool _hasMore = true;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> loadInitial() async {
    _page = 1;
    _hasMore = true;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final page = await _recipientRepository.search(
        keyword: searchQuery.value,
        page: _page,
        pageSize: _pageSize,
      );
      items.value = page.items;
      totalCount.value = page.totalCount;
      _hasMore = page.hasMore;
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
      items.clear();
      totalCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => loadInitial();

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _page + 1;
      final page = await _recipientRepository.search(
        keyword: searchQuery.value,
        page: nextPage,
        pageSize: _pageSize,
      );
      items.addAll(page.items);
      totalCount.value = page.totalCount;
      _page = nextPage;
      _hasMore = page.hasMore;
    } catch (error) {
      errorMessage.value = ApiClient.messageFrom(error);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), loadInitial);
  }
}
