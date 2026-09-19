class NumberToWords {
  static const _units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen'
  ];

  static const _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety'
  ];

  static String convert(double amount) {
    if (amount <= 0) return 'Rupees Zero Only';

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    String result = 'Rupees ${_convertInteger(rupees)}';

    if (paise > 0) {
      result += ' and ${_convertInteger(paise)} Paise';
    }

    result += ' Only';
    return result;
  }

  static String _convertInteger(int number) {
    if (number == 0) return 'Zero';
    if (number < 20) return _units[number];
    if (number < 100) {
      return _tens[number ~/ 10] + (number % 10 != 0 ? ' ${_units[number % 10]}' : '');
    }
    if (number < 1000) {
      return '${_units[number ~/ 100]} Hundred${number % 100 != 0 ? " ${_convertInteger(number % 100)}" : ""}';
    }
    if (number < 100000) {
      return '${_convertInteger(number ~/ 1000)} Thousand${number % 1000 != 0 ? " ${_convertInteger(number % 1000)}" : ""}';
    }
    if (number < 10000000) {
      return '${_convertInteger(number ~/ 100000)} Lakh${number % 100000 != 0 ? " ${_convertInteger(number % 100000)}" : ""}';
    }
    return '${_convertInteger(number ~/ 10000000)} Crore${number % 10000000 != 0 ? " ${_convertInteger(number % 10000000)}" : ""}';
  }
}
