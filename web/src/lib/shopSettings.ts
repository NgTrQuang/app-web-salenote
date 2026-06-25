import { getSetting, setSetting } from './db';
import { APP_NAME, SETTING_KEYS } from './constants';

export interface ShopSettings {
  shopName: string;
  shopPhone: string;
}

export async function getShopSettings(): Promise<ShopSettings> {
  const [shopName, shopPhone] = await Promise.all([
    getSetting(SETTING_KEYS.shopName),
    getSetting(SETTING_KEYS.shopPhone),
  ]);
  return {
    shopName: shopName?.trim() || APP_NAME,
    shopPhone: shopPhone?.trim() || '',
  };
}

export async function saveShopSettings(settings: ShopSettings): Promise<void> {
  await setSetting(SETTING_KEYS.shopName, settings.shopName.trim());
  await setSetting(SETTING_KEYS.shopPhone, settings.shopPhone.trim());
}
