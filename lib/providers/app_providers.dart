import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/bill.dart';
import '../models/shop_profile.dart';
import 'sample_data.dart';

// Gemini API Key State Notifier
class GeminiApiKeyNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setApiKey(String key) => state = key;
}

final geminiApiKeyProvider = NotifierProvider<GeminiApiKeyNotifier, String>(GeminiApiKeyNotifier.new);

// Authentication State
class AuthState {
  final bool isAuthenticated;
  final String companyName;
  final String username;

  const AuthState({
    required this.isAuthenticated,
    required this.companyName,
    required this.username,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? companyName,
    String? username,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      companyName: companyName ?? this.companyName,
      username: username ?? this.username,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState(
      isAuthenticated: false,
      companyName: 'Apex Digital & Electronics Ltd.',
      username: 'admin@apexdigital.in',
    );
  }

  void login({required String company, required String username}) {
    state = AuthState(
      isAuthenticated: true,
      companyName: company,
      username: username,
    );
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Navigation state
class ActiveTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  set state(int value) => super.state = value;
}

final activeTabProvider = NotifierProvider<ActiveTabNotifier, int>(ActiveTabNotifier.new);

// Qt Theme Mode (Dark/Light)
class QtThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // true = Qt Dark, false = Qt Light

  set state(bool value) => super.state = value;
}

final qtThemeModeProvider = NotifierProvider<QtThemeModeNotifier, bool>(QtThemeModeNotifier.new);

// Selected Bill for Detail View / Modal
class SelectedBillNotifier extends Notifier<Bill?> {
  @override
  Bill? build() => null;

  set state(Bill? value) => super.state = value;
}

final selectedBillProvider = NotifierProvider<SelectedBillNotifier, Bill?>(SelectedBillNotifier.new);

// Shop Profile Notifier
class ShopProfileNotifier extends Notifier<ShopProfile> {
  @override
  ShopProfile build() => SampleData.initialShop;

  void updateProfile(ShopProfile newProfile) {
    state = newProfile;
  }
}

final shopProfileProvider = NotifierProvider<ShopProfileNotifier, ShopProfile>(ShopProfileNotifier.new);

// Parties Notifier
class PartiesNotifier extends Notifier<List<Party>> {
  @override
  List<Party> build() => SampleData.initialParties;

  void addParty(Party party) {
    state = [party, ...state];
  }

  void updateParty(Party updatedParty) {
    state = state.map((p) => p.id == updatedParty.id ? updatedParty : p).toList();
  }

  void deleteParty(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void reloadFromList(List<Party> newList) {
    state = newList;
  }
}

final partiesProvider = NotifierProvider<PartiesNotifier, List<Party>>(PartiesNotifier.new);

// Items Notifier
class ItemsNotifier extends Notifier<List<Item>> {
  @override
  List<Item> build() => SampleData.initialItems;

  void addItem(Item item) {
    state = [item, ...state];
  }

  void updateItem(Item updatedItem) {
    state = state.map((i) => i.id == updatedItem.id ? updatedItem : i).toList();
  }

  void deleteItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void reloadFromList(List<Item> newList) {
    state = newList;
  }
}

final itemsProvider = NotifierProvider<ItemsNotifier, List<Item>>(ItemsNotifier.new);

// Bills Notifier
class BillsNotifier extends Notifier<List<Bill>> {
  @override
  List<Bill> build() => SampleData.getInitialBills();

  void addBill(Bill bill) {
    state = [bill, ...state];
  }

  void updatePaymentStatus(String billId, String newStatus) {
    state = state.map((b) => b.id == billId ? b.copyWith(paymentStatus: newStatus) : b).toList();
  }

  void reloadFromList(List<Bill> newList) {
    state = newList;
  }
}

final billsProvider = NotifierProvider<BillsNotifier, List<Bill>>(BillsNotifier.new);
