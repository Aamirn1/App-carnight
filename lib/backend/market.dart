import 'social.dart';

const currencyDigits = {
  'USD': 2,
  'PKR': 2,
  'AED': 2,
  'EUR': 2,
  'GBP': 2,
  'SAR': 2,
  'INR': 2,
  'JPY': 0,
  'KWD': 3,
  'BHD': 3,
};
int? parseMarketPrice(String text, String currency) {
  final digits = currencyDigits[currency];
  if (digits == null || !RegExp(r'^\d+(\.\d+)?$').hasMatch(text.trim()))
    return null;
  final parts = text.trim().split('.');
  final fraction = parts.length == 2 ? parts[1] : '';
  if (fraction.length > digits) return null;
  final value = int.tryParse(parts[0] + fraction.padRight(digits, '0'));
  return value != null && value > 0 && value <= 999999999999 ? value : null;
}

String marketPrice(Map<String, dynamic> row) {
  final currency = row['currency'] as String;
  final digits = currencyDigits[currency];
  if (digits == null) return 'Price unavailable';
  final raw = (row['price_minor'] as num).toInt().toString().padLeft(
    digits + 1,
    '0',
  );
  final number = digits == 0
      ? raw
      : '${raw.substring(0, raw.length - digits)}.${raw.substring(raw.length - digits)}';
  return '$currency $number${row['kind'] == 'rental' ? ' / day' : ''}';
}

extension LiveMarket on SocialRepository {
  Future<List<Map<String, dynamic>>> market({
    required String kind,
    String country = '',
    String city = '',
    String query = '',
    String category = 'All',
    Map<String, dynamic>? before,
  }) async {
    final rows = await client.rpc<List<dynamic>>(
      'cn_market',
      params: {
        'listing_kind': kind,
        'country_filter': country,
        'city_filter': city.trim(),
        'query_text': query.trim(),
        'category_filter': category,
        'before_time': before?['created_at'],
        'before_id': before?['id'],
      },
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> publishListing(Map<String, dynamic> params) async {
    await client.rpc<String>('cn_publish_listing', params: params);
  }

  Future<void> archiveListing(String id) async {
    await client
        .from('cn_listings')
        .update({'status': 'archived'})
        .eq('id', id)
        .eq('owner_id', me);
  }
}
