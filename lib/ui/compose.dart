import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'components.dart';

class ComposePage extends StatefulWidget {
  const ComposePage({super.key, required this.session});
  final DemoSession session;
  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  final _caption = TextEditingController();
  final _form = GlobalKey<FormState>();
  final Set<String> _selected = {};
  String? _imageError;
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Create',
    children: [
      Text(
        'Share your car story',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      SizedBox(height: 8),
      Text(
        'A great drive deserves a great photo.',
        style: TextStyle(color: NightTheme.secondaryText(context)),
      ),
      InfoNote(
        'Offline preview: select bundled sample photos. Device photo selection '
        'and online publishing will be connected in the media phase. No videos.',
      ),
      Form(
        key: _form,
        child: TextFormField(
          key: ValueKey('post-caption'),
          controller: _caption,
          maxLength: 500,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: 'What’s the story?'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Add a caption.' : null,
        ),
      ),
      SizedBox(height: 12),
      Text(
        '${_selected.length} / ${UploadPolicy.maxImages} images selected',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: NightAssets.photos.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, index) {
          final asset = NightAssets.photos[index];
          final selected = _selected.contains(asset);
          return Semantics(
            button: true,
            selected: selected,
            label: 'Sample image ${index + 1}',
            child: InkWell(
              key: ValueKey('sample-image-$index'),
              onTap: () => setState(() {
                if (!_selected.remove(asset)) _selected.add(asset);
                _imageError = null;
              }),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.primary : NightTheme.line(context),
                    width: selected ? 3 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetPhoto(asset: asset, dataSaver: true),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      if (_imageError != null)
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            _imageError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      SizedBox(height: 24),
      GradientButton(
        label: 'Add to demo feed',
        onPressed: () {
          final valid = _form.currentState!.validate();
          if (_selected.isEmpty)
            setState(() => _imageError = 'Select at least one image.');
          if (!valid || _selected.isEmpty) return;
          widget.session.addDemoPost(_caption.text, _selected.toList());
          Navigator.pop(context, true);
        },
      ),
      InfoNote(
        'This adds a local sample post only. It disappears when you exit the demo.',
      ),
      Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.sell_outlined),
        title: Text('Sell a car'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => pushPage<void>(
          context,
          const ListingDraftPage(kind: ListingKind.sale),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.car_rental),
        title: Text('List a rental'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => pushPage<void>(
          context,
          const ListingDraftPage(kind: ListingKind.rental),
        ),
      ),
    ],
  );
}

class ListingDraftPage extends StatefulWidget {
  const ListingDraftPage({super.key, required this.kind});
  final ListingKind kind;
  @override
  State<ListingDraftPage> createState() => _ListingDraftPageState();
}

class _ListingDraftPageState extends State<ListingDraftPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _price = TextEditingController();
  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: widget.kind == ListingKind.sale ? 'Sell a car' : 'List a rental',
    children: [
      InfoNote(
        'Form preview only. Your listing will not be published or saved.',
      ),
      Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: InputDecoration(labelText: 'Make and model'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter the make and model.' : null,
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _city,
              maxLength: 80,
              decoration: InputDecoration(labelText: 'City'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a city.' : null,
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.kind == ListingKind.sale
                    ? 'Price (USD)'
                    : 'Daily price (USD)',
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(value) ||
                    (double.tryParse(value) ?? 0) <= 0)
                  return 'Enter a positive price with up to 2 decimal places.';
                return null;
              },
            ),
          ],
        ),
      ),
      SizedBox(height: 24),
      GradientButton(
        label: 'Preview details',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          pushPage<void>(
            context,
            PageFrame(
              title: 'Listing preview',
              children: [
                Text(
                  _title.text.trim(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 12),
                Text(_city.text.trim()),
                Text(
                  'USD ${_price.text.trim()}${widget.kind == ListingKind.rental ? ' / day' : ''}',
                ),
                InfoNote(
                  'Not published. Photos, specifications, ownership verification '
                  'and a connected seller account are required before launch.',
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
