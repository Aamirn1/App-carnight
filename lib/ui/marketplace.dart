import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../backend/session.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../data/demo_catalog.dart';
import '../domain/models.dart';
import 'components.dart';

/// Demo fixtures use USD (two minor-unit digits). Locale-aware currency
/// formatting and currencies with other exponents are a production requirement.
String formatDemoMoney(int minor, String currency) {
  final whole = (minor ~/ 100).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final cents = minor % 100;
  return '$currency $whole${cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}'}';
}

String displayPrice(CarListing car) =>
    '${formatDemoMoney(car.priceMinor, car.currency)}'
    '${car.kind == ListingKind.rental ? ' / day' : ''}';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key, required this.kind, required this.session});
  final ListingKind kind;
  final DemoSession session;
  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _search = TextEditingController();
  final _location = TextEditingController(text: 'Dubai');
  String _category = 'All';
  String _countryCode = '';
  bool _locationInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationInitialized) {
      _locationInitialized = true;
      final account = BackendScope.of(context)?.account;
      _countryCode = account?.countryCode ?? '';
      if (account != null) _location.text = account.city;
      else if (widget.kind == ListingKind.sale) _location.clear();
    }
  }
  RentalPeriod? _period;
  @override
  void dispose() {
    _search.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      initialDateRange:
          _period == null ||
              _period!.pickup.isBefore(
                DateTime.utc(today.year, today.month, today.day),
              )
          ? null
          : DateTimeRange(start: _period!.pickup, end: _period!.dropoff),
      helpText: 'Choose pickup and drop-off',
      saveText: 'Use dates',
    );
    if (!mounted || result == null) return;
    if (!result.end.isAfter(result.start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drop-off must be at least one day after pickup.'),
        ),
      );
      return;
    }
    setState(() => _period = RentalPeriod(result.start, result.end));
  }

  void _reset() => setState(() {
    _search.clear();
    _location.clear();
    _category = 'All';
    _countryCode = '';
    _period = null;
  });

  @override
  Widget build(BuildContext context) {
    final rent = widget.kind == ListingKind.rental;
    final cars = filterListings(
      DemoCatalog.listings,
      kind: widget.kind,
      query: _search.text,
      category: _category,
      city: _location.text,
      countryCode: _countryCode,
    );
    final localizations = MaterialLocalizations.of(context);
    return CustomScrollView(
      key: PageStorageKey<String>('market-${widget.kind.name}'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rent ? 'Rent a Car' : 'Find Your Dream Car',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rent
                      ? 'For special events, trips or daily use'
                      : 'Buy your next car. Find your next adventure.',
                  style: const TextStyle(color: NightTheme.muted),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => showCountryPicker(context: context, showPhoneCode: false,
                    onSelect: (country) => setState(() { _countryCode = country.countryCode; _location.clear(); })),
                  icon: const Icon(Icons.public),
                  label: Text(_countryCode.isEmpty ? 'All countries' : 'Country · $_countryCode'),
                ),
                const SizedBox(height: 10),
                  TextField(
                    key: ValueKey(rent ? 'rental-location' : 'sale-location'),
                    controller: _location,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                if (rent) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fields = [
                        Expanded(
                          child: _DateControl(
                            label: 'Pick-up date',
                            value: _period == null
                                ? 'Choose date'
                                : localizations.formatCompactDate(
                                    _period!.pickup,
                                  ),
                            onTap: _pickDates,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateControl(
                            label: 'Drop-off date',
                            value: _period == null
                                ? 'Choose date'
                                : localizations.formatCompactDate(
                                    _period!.dropoff,
                                  ),
                            onTap: _pickDates,
                          ),
                        ),
                      ];
                      if (MediaQuery.textScalerOf(context).scale(14) > 20) {
                        return Column(
                          children: [
                            _DateControl(
                              label: 'Pick-up date',
                              value: _period == null
                                  ? 'Choose date'
                                  : localizations.formatCompactDate(
                                      _period!.pickup,
                                    ),
                              onTap: _pickDates,
                            ),
                            const SizedBox(height: 10),
                            _DateControl(
                              label: 'Drop-off date',
                              value: _period == null
                                  ? 'Choose date'
                                  : localizations.formatCompactDate(
                                      _period!.dropoff,
                                    ),
                              onTap: _pickDates,
                            ),
                          ],
                        );
                      }
                      return Row(children: fields);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  key: ValueKey('search-${widget.kind.name}'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Search make, model or keyword',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Luxury', 'SUV', 'Sports', 'Sedan']
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selectedColor: const Color(0xFF493388),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${cars.length} sample listings',
                  style: const TextStyle(color: NightTheme.muted, fontSize: 12),
                ),
                if (rent && _period != null)
                  InfoNote(
                    '${_period!.days} rental days selected. Dates provide a sample '
                    'estimate; they do not check availability.',
                  ),
              ],
            ),
          ),
        ),
        if (cars.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              title: 'No matching cars',
              message: 'Try another search, city or category.',
              action: OutlinedButton(
                onPressed: _reset,
                child: const Text('Reset filters'),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListingCard(
                  car: cars[index],
                  session: widget.session,
                  compact: rent,
                  period: _period,
                ),
              ),
              childCount: cars.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateControl extends StatelessWidget {
  const _DateControl({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => NightCard(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: NightTheme.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: NightTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    Text(value, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.car,
    required this.session,
    this.compact = false,
    this.period,
  });
  final CarListing car;
  final DemoSession session;
  final bool compact;
  final RentalPeriod? period;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => NightCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal =
              compact &&
              constraints.maxWidth >= 310 &&
              MediaQuery.textScalerOf(context).scale(14) <= 20;
          final details = Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  displayPrice(car),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  horizontal
                      ? car.city
                      : '${car.year} · ${car.distanceKm} km · ${car.city}',
                  style: const TextStyle(color: NightTheme.muted, fontSize: 12),
                ),
              ],
            ),
          );
          final photo = AssetPhoto(
            asset: car.imageAsset,
            ratio: horizontal ? 1.1 : 1.7,
            dataSaver: session.dataSaver,
            label: '${car.title}, sample image',
          );
          final content = horizontal
              ? Row(
                  children: [
                    SizedBox(width: 108, child: photo),
                    Expanded(child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [photo, details],
                );
          return Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => pushPage<void>(
                    context,
                    ListingDetail(car: car, session: session, period: period),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(right: horizontal ? 42 : 0),
                    child: content,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton.filledTonal(
                  key: ValueKey('save-${car.id}'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xC0070A1B),
                  ),
                  tooltip: session.isSaved(car.id) ? 'Unsave car' : 'Save car',
                  onPressed: () => session.toggleSaved(car.id),
                  icon: Icon(
                    session.isSaved(car.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: session.isSaved(car.id)
                        ? NightTheme.magenta
                        : Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class ListingDetail extends StatelessWidget {
  const ListingDetail({
    super.key,
    required this.car,
    required this.session,
    this.period,
  });
  final CarListing car;
  final DemoSession session;
  final RentalPeriod? period;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: car.title,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AssetPhoto(asset: car.imageAsset, dataSaver: session.dataSaver),
      ),
      const SizedBox(height: 20),
      Text(displayPrice(car), style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text('${car.year}')),
          Chip(label: Text('${car.distanceKm} km')),
          Chip(label: Text(car.category)),
          Chip(label: Text(car.city)),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'About this car',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Explore the listing layout, save this car and try the enquiry flow. '
        'This is a sample offer with illustrative generated photography.',
      ),
      if (car.kind == ListingKind.rental && period != null) ...[
        const SizedBox(height: 20),
        NightCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${period!.days} days · sample base estimate'),
              const SizedBox(height: 8),
              Text(
                formatDemoMoney(
                  period!.estimateMinor(car.priceMinor),
                  car.currency,
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const InfoNote(
                'Excludes fees, deposits and taxes. Availability is unverified. '
                'This is not a booking or a guaranteed quote.',
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      GradientButton(
        label: car.kind == ListingKind.rental
            ? 'Enquire about rental'
            : 'Contact seller',
        onPressed: () => showUnavailable(
          context,
          'Enquiries are not connected',
          'This listing is a demo. No message will be sent and no reservation will be made.',
        ),
      ),
      ListenableBuilder(
        listenable: session,
        builder: (context, _) => TextButton.icon(
          onPressed: () => session.toggleSaved(car.id),
          icon: Icon(
            session.isSaved(car.id) ? Icons.favorite : Icons.favorite_border,
          ),
          label: Text(
            session.isSaved(car.id)
                ? 'Saved to your collection'
                : 'Save this car',
          ),
        ),
      ),
      TextButton(
        onPressed: () => showUnavailable(
          context,
          'Report listing',
          'Reporting and moderation will be connected before real listings are accepted.',
        ),
        child: const Text('Report listing'),
      ),
    ],
  );
}

class MarketplaceHub extends StatelessWidget {
  const MarketplaceHub({super.key, required this.session});
  final DemoSession session;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Marketplace',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        const TabBar(
          tabs: [
            Tab(key: ValueKey('market-buy'), text: 'Buy'),
            Tab(key: ValueKey('market-rent'), text: 'Rent'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              MarketplacePage(kind: ListingKind.sale, session: session),
              MarketplacePage(kind: ListingKind.rental, session: session),
            ],
          ),
        ),
      ],
    ),
  );
}
