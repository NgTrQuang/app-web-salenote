import '../database/database_helper.dart';
import '../utils/constants.dart';

class ShopSettings {
  final String shopName;
  final String shopPhone;

  const ShopSettings({required this.shopName, required this.shopPhone});
}

class ShopSettingsService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<ShopSettings> getSettings() async {
    final name = await _db.getSetting(AppConstants.keyShopName);
    final phone = await _db.getSetting(AppConstants.keyShopPhone);
    return ShopSettings(
      shopName: name?.trim().isNotEmpty == true ? name!.trim() : AppConstants.appName,
      shopPhone: phone?.trim() ?? '',
    );
  }

  Future<void> saveSettings({required String shopName, required String shopPhone}) async {
    await _db.setSetting(AppConstants.keyShopName, shopName.trim());
    await _db.setSetting(AppConstants.keyShopPhone, shopPhone.trim());
  }
}
