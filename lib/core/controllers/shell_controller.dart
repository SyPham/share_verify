import 'package:get/get.dart';

class ShellController extends GetxController {
  final tabIndex = 0.obs;

  void switchTab(int index) => tabIndex.value = index;
}
