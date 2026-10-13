import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract final class PhotoCache {
  static final manager = CacheManager(
    Config(
      'cars-night-public-photos-v1',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );
}

class RemotePhoto extends StatelessWidget {
  const RemotePhoto({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.decodeWidth = 720,
    this.label = 'Car community photo',
  });
  final String url, label;
  final BoxFit fit;
  final int decodeWidth;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: CachedNetworkImage(
      imageUrl: url,
      cacheManager: PhotoCache.manager,
      fit: fit,
      memCacheWidth: decodeWidth,
      placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    ),
  );
}

class PhotoDetailPage extends StatelessWidget {
  const PhotoDetailPage({super.key, required this.url, required this.caption});
  final String url, caption;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Photo')),
    body: Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            child: RemotePhoto(url: url, decodeWidth: 1600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(caption, maxLines: 4, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
