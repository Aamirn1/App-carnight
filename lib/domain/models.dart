enum ListingKind { sale, rental }

class CarListing {
  const CarListing(
      {required this.id,
      required this.title,
      required this.kind,
      required this.category,
      required this.year,
      required this.distanceKm,
      required this.priceMinor,
      required this.currency,
      required this.city,
      required this.imageAsset});
  final String id;
  final String title;
  final ListingKind kind;
  final String category;
  final int year;
  final int distanceKm;
  final int priceMinor;
  final String currency;
  final String city;
  final String imageAsset;
}

class SocialPost {
  const SocialPost(
      {required this.id,
      required this.author,
      required this.city,
      required this.caption,
      required this.imageAssets});
  final String id;
  final String author;
  final String city;
  final String caption;
  final List<String> imageAssets;
}

/// UTC date components avoid daylight-saving changes corrupting calendar days.
class RentalPeriod {
  RentalPeriod(DateTime pickup, DateTime dropoff)
      : pickup = DateTime.utc(pickup.year, pickup.month, pickup.day),
        dropoff = DateTime.utc(dropoff.year, dropoff.month, dropoff.day) {
    if (!this.dropoff.isAfter(this.pickup)) {
      throw ArgumentError('Drop-off must be after pickup.');
    }
  }
  final DateTime pickup;
  final DateTime dropoff;
  int get days => dropoff.difference(pickup).inDays;

  int estimateMinor(int dailyRateMinor) {
    if (dailyRateMinor < 0) throw ArgumentError('Rate cannot be negative.');
    return days * dailyRateMinor;
  }
}

/// Client guidance only. Phase 3 must enforce this again on the server,
/// decode uploaded bytes and reject files that only claim an image MIME type.
abstract final class UploadPolicy {
  static const maxImages = 4;
  static const maxInputBytes = 8 * 1024 * 1024;
  static const allowedMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

  static String? validate(
      {required String mimeType, required int bytes, required int imageCount}) {
    if (!allowedMimeTypes.contains(mimeType.toLowerCase().trim())) {
      return 'Choose a JPEG, PNG or WebP image. Videos are not supported.';
    }
    if (bytes <= 0 || bytes > maxInputBytes) {
      return 'Each source image must be nonempty and at most 8 MiB.';
    }
    if (imageCount < 1 || imageCount > maxImages) {
      return 'Choose between 1 and 4 images.';
    }
    return null;
  }
}
