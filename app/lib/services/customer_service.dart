import '../database/database_helper.dart';
import '../models/customer.dart';
import '../models/interaction.dart';
import '../utils/constants.dart';

class CustomerService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? note,
    String? product,
    int? productId,
    String? source,
    String status = 'new',
    DateTime? warrantyEndDate,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final nextAction = now + Customer.followUpDelayMs(status);
    final customer = Customer(
      name: name,
      phone: phone,
      address: address,
      note: note,
      product: product,
      productId: productId,
      source: source,
      status: status,
      createdAt: now,
      lastContactAt: now,
      nextActionAt: nextAction,
      warrantyEndDate: warrantyEndDate?.millisecondsSinceEpoch,
    );
    final id = await _db.insertCustomer(customer);
    return customer.copyWith(id: id);
  }

  Future<void> messageSent(Customer customer) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final nextAction = now + Customer.followUpDelayMs(customer.status);
    final updated = customer.copyWith(
      lastContactAt: now,
      nextActionAt: nextAction,
    );
    await _db.updateCustomer(updated);
    await _db.insertInteraction(Interaction(
      customerId: customer.id!,
      content: 'Đã nhắn tin khách hàng',
      createdAt: now,
    ));
  }

  Future<void> updateStatus(Customer customer, String newStatus) async {
    final updated = customer.copyWith(status: newStatus);
    await _db.updateCustomer(updated);
  }

  Future<void> editCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
  }

  Future<void> deleteCustomer(int id) async {
    await _db.deleteCustomer(id);
  }

  Future<List<Customer>> getNeedsAttention() => _db.getNeedsAttention();
  Future<List<Customer>> getUpcoming() => _db.getUpcoming();
  Future<List<Customer>> getAllCustomers() => _db.getAllCustomers();
  Future<Customer?> getCustomer(int id) => _db.getCustomer(id);
  Future<List<Interaction>> getInteractions(int customerId) =>
      _db.getInteractions(customerId);

  Future<Map<String, dynamic>> getMonthlyStats(int year, int month) =>
      _db.getMonthlyStats(year, month);

  Future<int> getCurrentStreak() => _db.getCurrentStreak();

  Future<String> getMessageTemplate() async {
    final saved = await _db.getSetting(AppConstants.keyMessageTemplate);
    return saved ?? AppConstants.defaultMessage;
  }

  Future<void> saveMessageTemplate(String template) =>
      _db.setSetting(AppConstants.keyMessageTemplate, template);

  String applyMessageTemplate(String template, String name, String product) {
    return template
        .replaceAll('{tên}', name)
        .replaceAll('{sản_phẩm}', product);
  }

  List<Customer> filterCustomers(List<Customer> customers, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false) ||
          (c.address?.toLowerCase().contains(q) ?? false) ||
          (c.product?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Customer> filterBySource(List<Customer> customers, String source) {
    if (source == 'all') return customers;
    if (source == '_none') {
      return customers.where((c) => c.source == null || c.source!.isEmpty).toList();
    }
    return customers.where((c) => c.source == source).toList();
  }
}
