class InvoiceNumberGenerator {
  static String generate(int currentCount) {
    final year = DateTime.now().year;
    final seq = (currentCount + 1).toString().padLeft(3, '0');
    return 'INV-$year-$seq';
  }
}
