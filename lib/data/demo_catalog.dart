import '../core/assets.dart';
import '../domain/models.dart';

/// Illustrative fixtures, including AI-generated images. Not genuine offers.
abstract final class DemoCatalog {
  static const listings = <CarListing>[
    CarListing(
      id: 'sale-1',
      title: 'Lamborghini Huracán',
      kind: ListingKind.sale,
      category: 'Sports',
      year: 2022,
      distanceKm: 12000,
      priceMinor: 28500000,
      currency: 'USD',
      city: 'Dubai',
      countryCode: 'AE',
      imageAsset: NightAssets.violet,
    ),
    CarListing(
      id: 'sale-2',
      title: 'BMW M4 Competition',
      kind: ListingKind.sale,
      category: 'Sports',
      year: 2021,
      distanceKm: 18000,
      priceMinor: 7200000,
      currency: 'USD',
      city: 'London',
      countryCode: 'GB',
      imageAsset: NightAssets.hero,
    ),
    CarListing(
      id: 'rent-1',
      title: 'Ferrari 488 Spider',
      kind: ListingKind.rental,
      category: 'Sports',
      year: 2022,
      distanceKm: 9000,
      priceMinor: 129900,
      currency: 'USD',
      city: 'Dubai',
      countryCode: 'AE',
      imageAsset: NightAssets.red,
    ),
    CarListing(
      id: 'rent-2',
      title: 'Range Rover Sport',
      kind: ListingKind.rental,
      category: 'SUV',
      year: 2023,
      distanceKm: 7000,
      priceMinor: 45000,
      currency: 'USD',
      city: 'Dubai',
      countryCode: 'AE',
      imageAsset: NightAssets.suv,
    ),
  ];
  static const posts = <SocialPost>[
    SocialPost(
      id: 'post-1',
      author: 'Alex Carter',
      city: 'Dubai',
      caption: 'Night drives hit different. ✨ What’s your dream car?',
      imageAssets: [NightAssets.hero],
    ),
    SocialPost(
      id: 'post-2',
      author: 'Sophia M.',
      city: 'London',
      caption:
          'Weekend plans: good roads, great company and a car worth the journey.',
      imageAssets: [NightAssets.violet],
    ),
  ];
}

List<CarListing> filterListings(
  Iterable<CarListing> listings, {
  required ListingKind kind,
  String query = '',
  String category = 'All',
  String city = '',
  String countryCode = '',
}) {
  final normalized = query.trim().toLowerCase();
  final location = city.trim().toLowerCase();
  return listings
      .where(
        (car) =>
            car.kind == kind &&
            (countryCode.isEmpty || car.countryCode == countryCode.toUpperCase()) &&
            (category == 'All' || car.category == category) &&
            car.city.toLowerCase().contains(location) &&
            '${car.title} ${car.city} ${car.year}'.toLowerCase().contains(
              normalized,
            ),
      )
      .toList(growable: false);
}
