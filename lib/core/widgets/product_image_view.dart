// Dart Imports
import 'dart:io';

// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';

/// High-performance, memory-efficient product image renderer.
/// Handles remote URLs via [CachedNetworkImage], local files, and assets with
/// smooth loading placeholders, error fallbacks, and memory cache constraints.
class ProductImageView extends StatelessWidget {
  final String? imageUrl;
  final ItemCategory? category;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool enableZoomOnTap;

  const ProductImageView({
    super.key,
    required this.imageUrl,
    this.category,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.enableZoomOnTap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.zero;

    Widget content;
    final url = imageUrl?.trim() ?? '';

    if (url.isEmpty) {
      content = _buildPlaceholder(context, theme);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: 600,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, _, error) => _buildPlaceholder(context, theme),
      );
    } else if (url.startsWith('assets/')) {
      content = Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildPlaceholder(context, theme),
      );
    } else {
      // Local device file path
      final file = File(url);
      if (file.existsSync()) {
        content = Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildPlaceholder(context, theme),
        );
      } else {
        content = _buildPlaceholder(context, theme);
      }
    }

    if (radius != BorderRadius.zero) {
      content = ClipRRect(borderRadius: radius, child: content);
    }

    if (enableZoomOnTap && url.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openZoomViewer(context, url),
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder(BuildContext context, ThemeData theme) {
    IconData icon = Symbols.category;
    if (category != null) {
      switch (category!) {
        case ItemCategory.tools:
          icon = Symbols.build;
          break;
        case ItemCategory.electronics:
          icon = Symbols.devices;
          break;
        case ItemCategory.books:
          icon = Symbols.menu_book;
          break;
        case ItemCategory.sports:
          icon = Symbols.sports_tennis;
          break;
        case ItemCategory.household:
          icon = Symbols.home;
          break;
        case ItemCategory.travel:
          icon = Symbols.camping;
          break;
        case ItemCategory.calculators:
          icon = Symbols.calculate;
          break;
        case ItemCategory.creative:
          icon = Symbols.photo_camera;
          break;
        case ItemCategory.games:
          icon = Symbols.casino;
          break;
        case ItemCategory.gaming:
          icon = Symbols.sports_esports;
          break;
        case ItemCategory.furniture:
          icon = Symbols.chair;
          break;
        case ItemCategory.kitchen:
          icon = Symbols.kitchen;
          break;
        case ItemCategory.accessories:
          icon = Symbols.watch;
          break;
        case ItemCategory.educational:
          icon = Symbols.school;
          break;
        default:
          icon = Symbols.inventory_2;
          break;
      }
    }

    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.primaryContainer.withAlpha(45),
      child: Center(
        child: Icon(
          icon,
          size: (height != null && height! < 70) ? 28 : 44,
          color: theme.colorScheme.primary.withAlpha(160),
        ),
      ),
    );
  }

  void _openZoomViewer(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, _, _) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: ProductImageView(
                  imageUrl: url,
                  category: category,
                  fit: BoxFit.contain,
                  enableZoomOnTap: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Swipeable image gallery with page indicator dots and pinch-to-zoom support.
class ProductImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final ItemCategory category;
  final double height;

  const ProductImageGallery({
    super.key,
    required this.imageUrls,
    required this.category,
    this.height = 250.0,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urls = widget.imageUrls;

    if (urls.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        color: theme.colorScheme.primaryContainer.withAlpha(40),
        child: ProductImageView(
          imageUrl: null,
          category: widget.category,
          height: widget.height,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              return ProductImageView(
                imageUrl: urls[index],
                category: widget.category,
                fit: BoxFit.cover,
                enableZoomOnTap: true,
              );
            },
          ),

          // Page counter pill (e.g. 1/3)
          if (urls.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${_currentPage + 1}/${urls.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Dots Indicator
          if (urls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  urls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withAlpha(120),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
