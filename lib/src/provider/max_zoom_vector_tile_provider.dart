import 'dart:typed_data';

import '../../vector_map_tiles.dart';

/// A tile provider that reuses tiles from a lower zoom level when the requested
/// zoom exceeds the [maxZoom]. This is useful when the server doesn't provide
/// tiles beyond a certain zoom level, allowing you to reuse cached tiles from
/// the maximum available zoom level for higher zoom requests.
///
/// This is commonly known as "overzooming" - the map will continue to display
/// tiles at higher zoom levels by reusing the tiles from [maxZoom], which the
/// rendering engine will scale up appropriately.
///
/// Example:
/// ```dart
/// final provider = MaxZoomVectorTileProvider(
///   maxZoom: 14, // Server only provides tiles up to zoom 14
///   maximumZoom: 20, // But allow map to zoom to 20
///   delegate: CachingVectorTileProvider(
///     cache: storageCache,
///     cacheKey: (tile) => 'tiles-${tile.z}-${tile.x}-${tile.y}.pbf',
///     delegate: NetworkVectorTileProvider(
///       urlTemplate: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
///       maximumZoom: 14,
///     ),
///   ),
/// );
/// ```
class MaxZoomVectorTileProvider extends VectorTileProvider {
  /// The maximum zoom level that the server provides.
  /// Requests for zoom levels higher than this will be redirected to
  /// fetch the tile at this zoom level instead.
  final int maxZoom;

  /// The delegate provider that actually fetches/provides the tiles.
  /// This is typically a CachingVectorTileProvider wrapping a
  /// NetworkVectorTileProvider.
  final VectorTileProvider delegate;

  /// The maximum zoom level that the map can display.
  /// If not specified, defaults to 22 to allow overzooming.
  final int? _overrideMaximumZoom;

  MaxZoomVectorTileProvider({
    required this.maxZoom,
    required this.delegate,
    int? maximumZoom,
  }) : _overrideMaximumZoom = maximumZoom;

  @override
  int get maximumZoom => _overrideMaximumZoom ?? 22;

  @override
  int get minimumZoom => delegate.minimumZoom;

  /// The actual maximum zoom level that has tile data.
  /// This is used by the translation system to calculate correct tile positioning.
  int get actualMaximumZoom => maxZoom;

  @override
  TileOffset get tileOffset => delegate.tileOffset;

  @override
  TileProviderType get type => delegate.type;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    // If the requested zoom is within the available range, fetch normally
    if (tile.z <= maxZoom) {
      return delegate.provide(tile);
    }

    // For zoom levels beyond maxZoom, calculate the parent tile at maxZoom
    // that contains this tile
    final zoomDifference = tile.z - maxZoom;
    final divisor = 1 << zoomDifference; // equivalent to pow(2, zoomDifference)

    final parentX = tile.x ~/ divisor;
    final parentY = tile.y ~/ divisor;
    final parentTile = TileIdentity(maxZoom, parentX, parentY);

    // Fetch the parent tile - this will come from cache if available
    return delegate.provide(parentTile);
  }
}
