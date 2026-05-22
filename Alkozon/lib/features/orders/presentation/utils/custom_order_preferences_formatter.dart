class CustomOrderPreferencesFormatter {
  CustomOrderPreferencesFormatter._();

  static const Set<String> _hiddenKeys = {'clientOrderNumber'};

  static const Map<String, String> _labels = {
    'delivery': 'Dostawa',
    'recipientName': 'Odbiorca',
    'streetAddress': 'Ulica',
    'city': 'Miasto',
    'postalCode': 'Kod pocztowy',
    'country': 'Kraj',
    'deliveryNotes': 'Uwagi do dostawy',
    'paymentMethod': 'Płatność',
    'smokiness': 'Intensywność dymu',
    'sweetness': 'Słodycz',
    'strength': 'Moc',
    'volumeMl': 'Objętość (ml)',
    'abv': 'Zawartość alkoholu (%)',
    'alcoholType': 'Rodzaj alkoholu',
    'notes': 'Uwagi',
    'comment': 'Komentarz',
    'comments': 'Komentarze',
  };

  static List<MapEntry<String, String>> displayRows(
    Map<String, dynamic>? preferences,
  ) {
    if (preferences == null || preferences.isEmpty) {
      return const [];
    }

    final rows = <MapEntry<String, String>>[];
    final keys = preferences.keys.map((key) => key.toString()).toList()
      ..sort();

    for (final key in keys) {
      if (_hiddenKeys.contains(key)) {
        continue;
      }
      final value = preferences[key];
      if (value == null) {
        continue;
      }
      rows.add(MapEntry(_label(key), _formatValue(value)));
    }

    return rows;
  }

  static String _label(String key) {
    if (_labels.containsKey(key)) {
      return _labels[key]!;
    }
    return _humanizeKey(key);
  }

  static String _humanizeKey(String key) {
    if (key.isEmpty) {
      return key;
    }
    final buffer = StringBuffer();
    for (var i = 0; i < key.length; i++) {
      final char = key[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (i > 0 && isUpper) {
        buffer.write(' ');
      }
      buffer.write(i == 0 ? char.toUpperCase() : char);
    }
    return buffer.toString().replaceAll('_', ' ');
  }

  static String _formatValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is Map) {
      final lines = <String>[];
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      for (final entry in entries) {
        final nested = _formatValue(entry.value);
        if (nested == '-') {
          continue;
        }
        lines.add('${_label(entry.key.toString())}: $nested');
      }
      return lines.isEmpty ? '-' : lines.join('\n');
    }

    if (value is List) {
      final items = value
          .map(_formatValue)
          .where((item) => item != '-')
          .toList();
      return items.isEmpty ? '-' : items.join('\n');
    }

    if (value is bool) {
      return value ? 'Tak' : 'Nie';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }
}
