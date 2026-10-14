import 'dart:async';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:uuid/uuid.dart';
import '../backend/market.dart';
import '../backend/social.dart';
import '../backend/session.dart';
import '../backend/supabase_repositories.dart';
import 'components.dart';
import 'remote_photo.dart';
import 'auth.dart';
import 'messages.dart';

class LiveMarketplace extends StatefulWidget {
  const LiveMarketplace({super.key, required this.api, required this.kind});
  final SocialRepository api;
  final String kind;
  @override
  State<LiveMarketplace> createState() => _LiveMarketplaceState();
}

class _LiveMarketplaceState extends State<LiveMarketplace> {
  final _search = TextEditingController(), _city = TextEditingController();
  String _country = '', _category = 'All';
  List<Map<String, dynamic>> _rows = [];
  bool _busy = false, _more = true, _started = false;
  int _generation = 0;
  String? _error;
  Timer? _debounce;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final a = BackendScope.of(context)?.account;
      _country = a?.countryCode ?? '';
      _city.text = a?.city ?? '';
      _load();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _city.dispose();
    super.dispose();
  }

  void _changed() {
    _generation++;
    _debounce?.cancel();
    setState(() {
      _rows = [];
      _busy = true;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () => _load());
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await widget.api.market(
        kind: widget.kind,
        country: _country,
        city: _city.text,
        query: _search.text,
        category: _category,
        before: more && _rows.isNotEmpty ? _rows.last : null,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _rows = more ? [..._rows, ...rows] : rows;
        _more = rows.length == 20;
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() => _error = serviceError(e));
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => _load(),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.kind == 'sale' ? 'Find Your Dream Car' : 'Rent a Car',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          widget.kind == 'sale'
              ? 'Buy your next car. Find your next adventure.'
              : 'For special events, trips or daily use',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => _changed(),
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Search make, model or keyword',
            prefixIcon: Icon(Icons.search),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.public),
                label: Text(_country.isEmpty ? 'All countries' : _country),
                onPressed: () => showCountryPicker(
                  context: context,
                  onSelect: (c) {
                    _country = c.countryCode;
                    _city.clear();
                    _changed();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 155,
                child: TextField(
                  controller: _city,
                  onChanged: (_) => _changed(),
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Car category',
                onSelected: (v) {
                  _category = v;
                  _changed();
                },
                itemBuilder: (_) => [
                  'All',
                  'Luxury',
                  'SUV',
                  'Sports',
                  'Sedan',
                  'Other',
                ].map((c) => PopupMenuItem(value: c, child: Text(c))).toList(),
                child: Chip(
                  label: Text('Type · $_category'),
                  avatar: const Icon(Icons.tune),
                ),
              ),
              TextButton(
                onPressed: () {
                  _country = '';
                  _category = 'All';
                  _city.clear();
                  _search.clear();
                  _changed();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create listing'),
            onPressed: () async {
              if (BackendScope.of(context)?.account == null) {
                await pushPage<void>(context, const AuthPage());
                return;
              }
              await pushPage<void>(
                context,
                PublishListingPage(api: widget.api, kind: widget.kind),
              );
              if (mounted) _load();
            },
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) ...[
          InfoNote(_error!),
          TextButton(onPressed: () => _load(), child: const Text('Retry')),
        ],
        if (!_busy && _error == null && _rows.isEmpty)
          const EmptyState(
            title: 'No matching listings yet',
            message:
                'Try another country or city, or be the first to list your car.',
          ),
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NightCard(
              child: InkWell(
                onTap: () async {
                  await pushPage<void>(
                    context,
                    LiveListingDetail(api: widget.api, row: row),
                  );
                  if (mounted) _load();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.7,
                      child: RemotePhoto(
                        url: widget.api.imageUrl(
                          row['thumbnail_path'] as String,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(marketPrice(row)),
                          Text('${row['city']} · ${row['country_code']}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_more && _rows.isNotEmpty)
          TextButton(
            onPressed: _busy ? null : () => _load(more: true),
            child: const Text('Load more listings'),
          ),
      ],
    ),
  );
}

class LiveListingDetail extends StatefulWidget {
  const LiveListingDetail({super.key, required this.api, required this.row});
  final SocialRepository api;
  final Map<String, dynamic> row;
  @override
  State<LiveListingDetail> createState() => _LiveListingDetailState();
}

class _LiveListingDetailState extends State<LiveListingDetail> {
  bool _busy = false;
  String? _error;
  Future<void> _contact() async {
    final owner = BackendScope.of(context)?.account?.id;
    if (owner == null) {
      await pushPage<void>(context, const AuthPage());
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await widget.api.request(
        widget.row['owner_id'] as String,
        listingId: widget.row['id'] as String,
      );
      final chat = await widget.api.conversation(id);
      if (!mounted || BackendScope.of(context)?.account?.id != owner) return;
      await pushPage<void>(
        context,
        ConversationPage(
          conversation: chat,
          name: widget.row['title'] as String,
          owner: owner,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final mine = BackendScope.of(context)?.account?.id == row['owner_id'];
    return PageFrame(
      title: row['title'] as String,
      children: [
        AspectRatio(
          aspectRatio: 1.4,
          child: RemotePhoto(
            url: widget.api.imageUrl(row['image_path'] as String),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          marketPrice(row),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('${row['city']} · ${row['country_code']} · ${row['category']}'),
        const SizedBox(height: 16),
        Text(row['description'] as String),
        if (row['kind'] == 'rental')
          const InfoNote(
            'Daily asking price. Agree dates, availability, deposit and any fees directly with the seller. Sending an enquiry does not reserve a car.',
          ),
        if (_error != null) InfoNote(_error!),
        const SizedBox(height: 20),
        if (!mine)
          GradientButton(
            label: 'Contact seller',
            onPressed: _busy ? null : _contact,
          ),
        if (mine)
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Remove this offer?'),
                        content: const Text(
                          'It will stop appearing in Marketplace. Existing conversations remain.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    if (yes != true || !mounted) return;
                    setState(() => _busy = true);
                    try {
                      await widget.api.archiveListing(row['id'] as String);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) setState(() => _error = serviceError(e));
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: const Text('Remove listing'),
          ),
      ],
    );
  }
}

class PublishListingPage extends StatefulWidget {
  const PublishListingPage({super.key, required this.api, required this.kind});
  final SocialRepository api;
  final String kind;
  @override
  State<PublishListingPage> createState() => _PublishListingPageState();
}

class _PublishListingPageState extends State<PublishListingPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _price = TextEditingController(),
      _city = TextEditingController();
  final _request = const Uuid().v4();
  String _country = '', _currency = 'USD', _category = 'Sedan';
  String? _photo, _error, _owner;
  List<CommunityPost> _photos = [];
  bool _busy = false, _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final account = BackendScope.of(context)?.account;
      _owner = account?.id;
      _country = account?.countryCode ?? '';
      _city.text = account?.city ?? '';
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final photos = await widget.api.collection(author: _owner);
      if (mounted)
        setState(
          () => _photos = photos.where((p) => p.images.isNotEmpty).toList(),
        );
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    if (_photo == null || _country.isEmpty) {
      setState(
        () => _error = 'Choose a country and one of your published photos.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.publishListing({
        'request_id': _request,
        'photo_post': _photo,
        'listing_kind': widget.kind,
        'listing_title': _title.text.trim(),
        'listing_description': _description.text.trim(),
        'listing_country': _country,
        'listing_city': _city.text.trim(),
        'listing_category': _category,
        'listing_currency': _currency,
        'listing_price': parseMarketPrice(_price.text, _currency),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_owner == null || BackendScope.of(context)?.account?.id != _owner)
      return const AuthPage();
    return PageFrame(
      title: widget.kind == 'sale' ? 'Sell a car' : 'List a rental',
      children: [
        const InfoNote(
          'Use one of your published car photos. This reuses the image without another upload. Removing its post also removes the listing.',
        ),
        if (_error != null) InfoNote(_error!),
        if (_busy) const LinearProgressIndicator(),
        if (_photos.isEmpty && !_busy)
          const InfoNote(
            'Publish a car photo from Create first, then return here.',
          ),
        Form(
          key: _form,
          child: AbsorbPointer(
            absorbing: _busy,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _photo,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Your published photo',
                  ),
                  items: _photos
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _photo = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Make and model',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter make and model' : null,
                ),
                TextFormField(
                  controller: _description,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Condition, specifications and offer details',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Describe your offer' : null,
                ),
                OutlinedButton.icon(
                  onPressed: () => showCountryPicker(
                    context: context,
                    onSelect: (c) => setState(() => _country = c.countryCode),
                  ),
                  icon: const Icon(Icons.public),
                  label: Text(_country.isEmpty ? 'Choose country' : _country),
                ),
                TextFormField(
                  controller: _city,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter city' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Luxury', 'SUV', 'Sports', 'Sedan', 'Other']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: currencyDigits.keys
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.kind == 'sale'
                        ? 'Asking price'
                        : 'Daily asking price',
                  ),
                  validator: (v) => parseMarketPrice(v ?? '', _currency) == null
                      ? 'Enter a positive price with up to ${currencyDigits[_currency]} decimal places'
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Publish listing',
          onPressed: _busy || _photos.isEmpty ? null : _publish,
        ),
      ],
    );
  }
}
