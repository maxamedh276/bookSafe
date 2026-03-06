import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// All app strings in one place — Somali (so) and English (en)
// ─────────────────────────────────────────────────────────────────────────────
class AppStrings {
  final String locale;
  AppStrings(this.locale);

  bool get isSomali => locale == 'so';

  // Navigation
  String get dashboard    => isSomali ? 'Hoyga'            : 'Dashboard';
  String get sales        => isSomali ? 'Iibka & POS'      : 'Sales & POS';
  String get inventory    => isSomali ? 'Alaabta'          : 'Inventory';
  String get customers    => isSomali ? 'Macaamiisha'      : 'Customers';
  String get debts        => isSomali ? 'Deynta'           : 'Debts';
  String get reports      => isSomali ? 'Warbixinada'      : 'Reports';
  String get users        => isSomali ? 'Shaqaalaha'       : 'Users';
  String get branches     => isSomali ? 'Laamaha'          : 'Branches';
  String get adminPanel   => isSomali ? 'Maamulka IT'      : 'IT Admin Panel';
  String get logout       => isSomali ? 'Ka bax'           : 'Logout';
  String get settings     => isSomali ? 'Dejinnada'        : 'Settings';

  // Auth
  String get login        => isSomali ? 'Gal'              : 'Login';
  String get register     => isSomali ? 'Diiwaangeli'      : 'Register';
  String get email        => isSomali ? 'Iimaylka'         : 'Email';
  String get password     => isSomali ? 'Furaha sirta'     : 'Password';
  String get forgotPassword => isSomali ? 'Waan illaaway?' : 'Forgot Password?';
  String get loginError   => isSomali ? 'Iimaylka ama furaha sirta waa khalad.' : 'Invalid email or password.';

  // Sales
  String get newSale          => isSomali ? 'Iib Cusub'        : 'New Sale';
  String get selectCustomer   => isSomali ? 'Dooro Macmiil'    : 'Select Customer';
  String get addProduct       => isSomali ? '+ Alaab'          : '+ Product';
  String get addCustomer      => isSomali ? '+ Macmiil Cusub'  : '+ New Customer';
  String get paid             => isSomali ? 'Kash'             : 'Paid';
  String get credit           => isSomali ? 'Deyn'             : 'Credit';
  String get totalAmount      => isSomali ? 'Wadarta Guud'     : 'Total Amount';
  String get checkoutBtn      => isSomali ? 'Gudbi Iibka'      : 'Complete Sale';
  String get cartEmpty        => isSomali ? 'Cart-ku waa madhan yahay.' : 'Cart is empty.';
  String get saleSuccess      => isSomali ? 'Iibka si guul leh ayaa loo gudbiyey!' : 'Sale completed successfully!';
  String get selectCustomerForCredit => isSomali
      ? 'Fadlan dooro macmiilka marka iibku yahay Deyn.'
      : 'Please select a customer for credit sales.';

  // Products
  String get productName    => isSomali ? 'Magaca Alaabta'   : 'Product Name';
  String get price          => isSomali ? 'Qiimaha'          : 'Price';
  String get stock          => isSomali ? 'Tirada (Stock)'   : 'Stock';
  String get category       => isSomali ? 'Nooca'            : 'Category';
  String get lowStock       => isSomali ? 'Stock hooseeye!'  : 'Low stock!';
  String get noProducts     => isSomali ? 'Alaab ma jirto weli.' : 'No products found.';

  // Customers
  String get customerName   => isSomali ? 'Magaca Macmiilka' : 'Customer Name';
  String get phone          => isSomali ? 'Telefoonka'        : 'Phone';
  String get address        => isSomali ? 'Cinwaanka'         : 'Address';
  String get debtBalance    => isSomali ? 'Reesada Deynta'   : 'Debt Balance';
  String get noCustomers    => isSomali ? 'Macaamiil ma jiraan.' : 'No customers found.';
  String get newCustomer    => isSomali ? 'Macmiil Cusub'    : 'New Customer';

  // Common
  String get save           => isSomali ? 'Keydi'            : 'Save';
  String get cancel         => isSomali ? 'Jooji'            : 'Cancel';
  String get delete         => isSomali ? 'Tirtir'           : 'Delete';
  String get edit           => isSomali ? 'Wax ka beddel'    : 'Edit';
  String get search         => isSomali ? 'Raadi...'         : 'Search...';
  String get refresh        => isSomali ? 'Cusboonee'        : 'Refresh';
  String get loading        => isSomali ? 'Soo raraya...'    : 'Loading...';
  String get tryAgain       => isSomali ? 'Isku day mar kale' : 'Try Again';
  String get noData         => isSomali ? 'Xog ma jirto weli.' : 'No data yet.';
  String get add            => isSomali ? 'Ku dar'           : 'Add';

  // Reports
  String get totalSales     => isSomali ? 'Wadarta Iibka'    : 'Total Sales';
  String get totalPaid      => isSomali ? 'La Bixiyey'       : 'Total Paid';
  String get totalDebt      => isSomali ? 'Deynta'           : 'Total Debt';
  String get salesCount     => isSomali ? 'Tirada Iibka'     : 'Sales Count';
  String get topProducts    => isSomali ? 'Alaabta Ugu Badan' : 'Top Selling Products';
  String get exportCsv      => isSomali ? 'Dhoofin CSV'      : 'Export CSV';
  String get selectDateRange => isSomali ? 'Dooro Taariikhda' : 'Select Date Range';

  // Branches
  String get branchName     => isSomali ? 'Magaca Laanta'   : 'Branch Name';
  String get location       => isSomali ? 'Goobta'          : 'Location';
  String get newBranch      => isSomali ? 'Laanta Cusub'    : 'New Branch';
  String get branchLimitMsg => isSomali
      ? 'Waxaad gaartay xadka laamaha. Casri subscription-kaaga.'
      : 'Branch limit reached. Please upgrade your plan.';

  // Offline
  String get offlineBanner      => isSomali ? '⚠ Xiriirka kuma jirto — Offline mode' : '⚠ No Internet — Offline Mode';
  String get syncingPending     => isSomali ? 'Iibka la is-duwayaa...'                : 'Syncing pending sales...';
  String get syncSuccess        => isSomali ? '✓ Is-duwayntu waa guulusatay!'         : '✓ Sync successful!';
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Provider for locale + strings
// ─────────────────────────────────────────────────────────────────────────────
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('so')) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'so';
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  void toggle() {
    setLocale(state.languageCode == 'so' ? const Locale('en') : const Locale('so'));
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale.languageCode);
});
