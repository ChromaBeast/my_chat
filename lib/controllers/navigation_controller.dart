import 'package:get/get.dart';

class NavigationController extends GetxController {
  static NavigationController get to => Get.find();

  final _selectedIndex = 0.obs;
  int get selectedIndex => _selectedIndex.value;

  void changePage(int index) {
    if (index >= 0 && index < 2) {
      // We only have 2 pages now
      _selectedIndex.value = index;
    }
  }
}
