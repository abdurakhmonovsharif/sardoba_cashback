import 'package:flutter/material.dart';

import 'app_language.dart';

class AppLocalizations extends InheritedWidget {
  final AppLocale locale;
  late final AppStrings strings = AppStrings(locale);

  AppLocalizations({required this.locale, required Widget child, super.key})
      : super(child: child);

  static AppStrings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocalizations>();
    assert(scope != null, 'No AppLocalizations found in context');
    return scope!.strings;
  }

  @override
  bool updateShouldNotify(AppLocalizations oldWidget) =>
      oldWidget.locale != locale;
}

class AppStrings {
  final AppLocale locale;
  const AppStrings(this.locale);

  bool get _isRu => locale == AppLocale.ru;

  // Home
  String get changeBranch => _isRu ? 'Сменить филиал' : 'Filialni tanlang';
  String get changeBranchSubtitle => _isRu ? 'Рядом с вами' : 'Sizga yaqin joy';
  String get searchHint =>
      _isRu ? 'Что хотите заказать?' : 'Nimani buyurtma qilmoqchisiz?';
  String get loyaltyTitle =>
      _isRu ? 'Программа лояльности' : 'Sodiqlik dasturi';
  String get offersTitle => _isRu ? 'Предложения' : 'Takliflar';
  String get cashbackTitle => _isRu ? 'Баланс кешбэка' : 'Keshbek balansi';
  String get cashbackHelper =>
      _isRu ? 'Можно использовать при 75 000 сум' : '75 000 soʻmda ishlating';
  String get membershipTitle => _isRu ? 'Уровень клуба' : 'Klub darajasi';
  String get membershipHelper => _isRu
      ? 'До золота осталось 3 000 баллов'
      : 'Gold darajasi uchun 3 000 ball qolgan';
  String get notificationsTitle => _isRu ? 'Уведомления' : 'Bildirishnomalar';
  String get notificationsEmpty =>
      _isRu ? 'Новых уведомлений нет' : 'Yangi bildirishnoma yoʻq';
  String get birthdayOfferTitle =>
      _isRu ? 'С днём рождения!' : 'Tugʻilgan kun muborak!';
  String get birthdayOfferBody => _isRu
      ? 'Празднуйте у нас и получите скидку 15% на всё меню до конца недели.'
      : 'Biz bilan bayram qiling va hafta oxirigacha barcha menyuga 15% chegirma oling.';
  String get doublePointsBody => _isRu
      ? 'Собирайте двойные баллы за каждую доставку сегодня.'
      : 'Bugun har bir yetkazib berishda ikki baravar koʻp ball toʻplang.';

  String get languageSheetTitle => _isRu ? 'Выберите язык' : 'Tilni tanlang';

  // Locations
  String get locationsTitle => _isRu ? 'Наши филиалы' : 'Filiallarimiz';
  String get locationsMapHeader => _isRu ? 'На карте' : 'Xaritada';
  String get locationsListHeader =>
      _isRu ? 'Список филиалов' : 'Filiallar roʻyxati';
  String get locationsSearchHint =>
      _isRu ? 'Поиск филиала...' : 'Filial qidirish...';
  String get locationsEmpty =>
      _isRu ? 'Филиалы не найдены' : 'Filial topilmadi';
  String get openNow => _isRu ? 'Открыто' : 'Ochiq';
  String get dailySchedule =>
      _isRu ? 'Ежедневно 09:00 - 23:00' : 'Har kuni 09:00 - 23:00';
  String get showOnMap => _isRu ? 'Показать на карте' : 'Xaritada koʻrsatish';

  String languageLabel(AppLocale locale) {
    switch (locale) {
      case AppLocale.ru:
        return _isRu ? 'Русский' : 'Rus tili';
      case AppLocale.uz:
        return _isRu ? 'Узбекский' : 'Oʻzbekcha';
    }
  }
}
