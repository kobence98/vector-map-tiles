# MaxZoomVectorTileProvider Usage Guide

## Overview

The `MaxZoomVectorTileProvider` allows you to reuse cached tiles from a lower zoom level when the requested zoom exceeds a specified maximum. This is useful when your tile server doesn't provide tiles beyond a certain zoom level (e.g., zoom 14), but you want your map to continue working at higher zoom levels (e.g., zoom 15, 16, 17, etc.).

## How It Works

When a tile is requested at a zoom level higher than `maxZoom`:
1. The provider calculates which parent tile at `maxZoom` contains the requested tile
2. It fetches that parent tile instead (which will come from cache if available)
3. The rendering engine automatically scales up the tile to display at the higher zoom level

This technique is called "overzooming" and is commonly used in web mapping applications.

## Basic Usage

### Example 1: Simple Network Provider with Max Zoom

```dart
import 'package:vector_map_tiles/vector_map_tiles.dart';

// Create a provider that stops fetching new tiles after zoom 14
final provider = MaxZoomVectorTileProvider(
  maxZoom: 14,
  delegate: NetworkVectorTileProvider(
    urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf',
    maximumZoom: 14,
  ),
);
```

### Example 2: With Caching (Recommended)

This is the most common use case - combining max zoom with caching:

```dart
import 'package:vector_map_tiles/vector_map_tiles.dart';

// Assuming you have a storage cache set up
final provider = MaxZoomVectorTileProvider(
  maxZoom: 14,
  delegate: CachingVectorTileProvider(
    cache: storageCache,
    cacheKey: (tile) => 'tiles-${tile.z}-${tile.x}-${tile.y}.pbf',
    delegate: NetworkVectorTileProvider(
      urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf',
      maximumZoom: 14,
    ),
  ),
);
```

### Example 3: Complete Setup with TileProviders

```dart
import 'package:vector_map_tiles/vector_map_tiles.dart';

// Create your tile providers map
final tileProviders = TileProviders({
  'openmaptiles': MaxZoomVectorTileProvider(
    maxZoom: 14,
    delegate: CachingVectorTileProvider(
      cache: storageCache,
      cacheKey: (tile) => 'openmaptiles-${tile.z}-${tile.x}-${tile.y}.pbf',
      delegate: NetworkVectorTileProvider(
        urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf',
        maximumZoom: 14,
        minimumZoom: 0,
      ),
    ),
  ),
});

// Use in your VectorTileLayer
VectorTileLayer(
  tileProviders: tileProviders,
  theme: myTheme,
  // ... other parameters
)
```

## Benefits

1. **Reduced Server Load**: No requests are made for zoom levels beyond `maxZoom`
2. **Faster Performance**: Higher zoom tiles are served from cache instantly
3. **Cost Savings**: If you're paying per tile request, this reduces your costs
4. **Offline Support**: Once tiles are cached at `maxZoom`, higher zooms work offline

## Important Notes

- The `maxZoom` should match the maximum zoom level your tile server provides
- The visual quality at higher zoom levels will be the same as at `maxZoom` (tiles are scaled up)
- Make sure to use this with a caching provider to get the full benefit
- The `maximumZoom` property on the delegate provider can be higher than `maxZoom` to allow the map to zoom further

## Comparison: Before vs After

### Before (Without MaxZoomVectorTileProvider)
```dart
// Requests tiles at every zoom level, even if server doesn't provide them
final provider = NetworkVectorTileProvider(
  urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf',
  maximumZoom: 14,
);
// At zoom 15: Makes network request → Server returns 404 or empty tile
// At zoom 16: Makes network request → Server returns 404 or empty tile
```

### After (With MaxZoomVectorTileProvider)
```dart
// Reuses cached tiles from zoom 14 for higher zoom levels
final provider = MaxZoomVectorTileProvider(
  maxZoom: 14,
  delegate: CachingVectorTileProvider(
    cache: storageCache,
    cacheKey: (tile) => 'tiles-${tile.z}-${tile.x}-${tile.y}.pbf',
    delegate: NetworkVectorTileProvider(
      urlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.pbf',
      maximumZoom: 14,
    ),
  ),
);
// At zoom 15: Uses cached tile from zoom 14 → Instant, no network request
// At zoom 16: Uses cached tile from zoom 14 → Instant, no network request
```

## Technical Details

When you request a tile at zoom 16 with `maxZoom: 14`:
- Requested tile: `z=16, x=12345, y=23456`
- Zoom difference: `16 - 14 = 2`
- Divisor: `2^2 = 4`
- Parent tile: `z=14, x=12345/4=3086, y=23456/4=5864`
- The provider fetches tile `z=14, x=3086, y=5864` instead

The rendering engine knows how to scale this tile appropriately for display at zoom 16.
