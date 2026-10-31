// Dart Imports
import 'dart:io';

// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/services/storage_service.dart';
import 'package:lendnborrow/core/utils/responsive.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';
import 'package:lendnborrow/feature/auth/auth_screen.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _durationController = TextEditingController(text: "7");
  final _depositController = TextEditingController();
  final _termsController = TextEditingController();

  ItemCategory _selectedCategory = ItemCategory.tools;
  ItemCondition _selectedCondition = ItemCondition.good;

  // Product Photos state
  final List<File> _selectedPhotos = [];
  int _coverPhotoIndex = 0;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusMessage = "";

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupLocationController.dispose();
    _durationController.dispose();
    _depositController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  // Pick photos from device gallery
  Future<void> _pickFromGallery() async {
    final storage = StorageService();
    final picked = await storage.pickImagesFromGallery(
      currentCount: _selectedPhotos.length,
    );

    if (picked.isNotEmpty && mounted) {
      setState(() {
        _selectedPhotos.addAll(picked);
        if (_coverPhotoIndex >= _selectedPhotos.length) {
          _coverPhotoIndex = 0;
        }
      });
    }
  }

  // Capture photo from camera
  Future<void> _captureFromCamera() async {
    if (_selectedPhotos.length >= StorageService.maxImagesPerListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum of 5 photos reached")),
      );
      return;
    }

    final storage = StorageService();
    final photo = await storage.captureImageFromCamera();

    if (photo != null && mounted) {
      setState(() {
        _selectedPhotos.add(photo);
      });
    }
  }

  // Remove photo
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      if (_coverPhotoIndex >= _selectedPhotos.length) {
        _coverPhotoIndex = (_selectedPhotos.length - 1).clamp(0, _selectedPhotos.length);
      }
    });
  }

  // Set as cover photo
  void _setAsCover(int index) {
    setState(() {
      _coverPhotoIndex = index;
    });
  }

  // Move photo left/right for reordering
  void _movePhoto(int fromIndex, int toIndex) {
    if (toIndex < 0 || toIndex >= _selectedPhotos.length) return;
    setState(() {
      final file = _selectedPhotos.removeAt(fromIndex);
      _selectedPhotos.insert(toIndex, file);

      // Track cover index
      if (_coverPhotoIndex == fromIndex) {
        _coverPhotoIndex = toIndex;
      } else if (_coverPhotoIndex == toIndex) {
        _coverPhotoIndex = fromIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Share an Item")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Authentication Required",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please sign in or register with any personal email to list items in the marketplace.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AuthScreen.path),
                  icon: const Icon(Icons.login),
                  label: const Text("Sign In or Register"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Share an Item",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: Responsive.horizontalPadding(context).copyWith(
          top: 16.0,
          bottom: 32.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================================================
              // SECTION 1: PRODUCT PHOTOS UPLOAD
              // ===============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Product Photos *",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedPhotos.isNotEmpty
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_selectedPhotos.length}/${StorageService.maxImagesPerListing} photos",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedPhotos.isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Upload up to 5 clear photographs. The first image or designated cover photo will appear in the marketplace.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),

              // Upload Dropzone & Action Buttons
              if (_selectedPhotos.isEmpty)
                _buildEmptyUploadCard(theme)
              else
                _buildPhotoCarousel(theme),

              const SizedBox(height: 24),

              // ===============================================================
              // SECTION 2: BASIC INFORMATION
              // ===============================================================
              Text(
                "Item Details",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Item Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Item Name & Model *",
                  hintText: "e.g., Bosch 18V Cordless Drill, Casio fx-991EX",
                  prefixIcon: const Icon(Symbols.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Item name is required"
                    : null,
              ),
              const SizedBox(height: 14),

              // Category Selector
              DropdownButtonFormField<ItemCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Category *",
                  prefixIcon: const Icon(Symbols.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemCategory.values
                    .where((c) => c != ItemCategory.all)
                    .map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          MarketplaceItem(
                            id: "",
                            ownerId: "",
                            ownerName: "",
                            title: "",
                            description: "",
                            category: cat,
                            condition: ItemCondition.good,
                            pickupLocation: "",
                            imageUrls: const [],
                            createdAt: DateTime.now(),
                          ).categoryDisplay,
                        ),
                      );
                    })
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description & Included Accessories *",
                  hintText:
                      "Describe condition, accessories, bits, chargers, or user manuals included...",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Description is required"
                    : null,
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // SECTION 3: CONDITION & LENDING CONDITIONS
              // ===============================================================
              Text(
                "Condition & Lending Terms",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Condition Dropdown
              DropdownButtonFormField<ItemCondition>(
                initialValue: _selectedCondition,
                decoration: InputDecoration(
                  labelText: "Item Condition *",
                  prefixIcon: const Icon(Symbols.verified),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemCondition.values.map((cond) {
                  return DropdownMenuItem(
                    value: cond,
                    child: Text(cond.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
              const SizedBox(height: 14),

              // Pickup Location
              TextFormField(
                controller: _pickupLocationController,
                decoration: InputDecoration(
                  labelText: "General Pickup Location / Landmark *",
                  hintText: "e.g., Koramangala 4th Block, Campus Gate 2",
                  prefixIcon: const Icon(Symbols.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Location is required"
                    : null,
              ),
              const SizedBox(height: 14),

              // Duration & Deposit Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Max Days *",
                        hintText: "7",
                        prefixIcon: const Icon(Symbols.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) {
                        final d = int.tryParse(val ?? "");
                        if (d == null || d <= 0) return "Min 1 day";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depositController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Deposit (₹, optional)",
                        hintText: "0 if free loan",
                        prefixIcon: const Icon(Symbols.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Terms & Care Instructions
              TextFormField(
                controller: _termsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Owner Terms / Care Instructions (optional)",
                  hintText: "e.g., Please return dry; keep away from water.",
                  prefixIcon: const Icon(Symbols.gavel),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Upload progress feedback
              if (_isUploading) ...[
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _uploadStatusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Publish Button
              FilledButton.icon(
                onPressed: _isUploading ? null : _submitListing,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isUploading ? "Uploading & Publishing..." : "Publish Listing to Marketplace",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty upload area with Camera and Gallery buttons
  Widget _buildEmptyUploadCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Symbols.add_photo_alternate,
            size: 48,
            color: theme.colorScheme.primary.withAlpha(180),
          ),
          const SizedBox(height: 12),
          const Text(
            "Add Product Photographs",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            "Listings with clear photos are 4x more likely to be borrowed.",
            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _captureFromCamera,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text("Camera"),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text("Gallery"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Carousel of selected photos
  Widget _buildPhotoCarousel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedPhotos.length + (_selectedPhotos.length < StorageService.maxImagesPerListing ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _selectedPhotos.length) {
                // Add more card
                return Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickFromGallery,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: theme.colorScheme.primary),
                        const SizedBox(height: 6),
                        const Text("Add Photo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }

              final file = _selectedPhotos[index];
              final isCover = index == _coverPhotoIndex;

              return Stack(
                children: [
                  Container(
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCover ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(60),
                        width: isCover ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ProductImageView(
                        imageUrl: file.path,
                        category: _selectedCategory,
                        fit: BoxFit.cover,
                        height: 170,
                        enableZoomOnTap: true,
                      ),
                    ),
                  ),

                  // Cover Badge
                  if (isCover)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Cover",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Actions Overlay (Bottom)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isCover)
                            GestureDetector(
                              onTap: () => _setAsCover(index),
                              child: const Tooltip(
                                message: "Set as Cover",
                                child: Icon(Icons.star_border, color: Colors.amber, size: 18),
                              ),
                            )
                          else
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                          if (index > 0)
                            GestureDetector(
                              onTap: () => _movePhoto(index, index - 1),
                              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                            ),
                          if (index < _selectedPhotos.length - 1)
                            GestureDetector(
                              onTap: () => _movePhoto(index, index + 1),
                              child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            ),
                          GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: const Tooltip(
                              message: "Remove Photo",
                              child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.05;
      _uploadStatusMessage = "Preparing product photographs...";
    });

    final itemId = "item_${const Uuid().v4().substring(0, 8)}";

    try {
      // Re-order photos so the chosen cover photo is at index 0
      final List<File> orderedFiles = List.from(_selectedPhotos);
      if (_coverPhotoIndex > 0 && _coverPhotoIndex < orderedFiles.length) {
        final coverFile = orderedFiles.removeAt(_coverPhotoIndex);
        orderedFiles.insert(0, coverFile);
      }

      // Upload photos to Firebase Storage
      List<String> uploadedUrls = [];
      if (orderedFiles.isNotEmpty) {
        final storage = StorageService();
        uploadedUrls = await storage.uploadListingImages(
          userId: currentUser.id,
          itemId: itemId,
          files: orderedFiles,
          onProgress: (progress, current, total) {
            if (mounted) {
              setState(() {
                _uploadProgress = 0.1 + (progress * 0.8);
                _uploadStatusMessage = "Uploading photo $current of $total (${(progress * 100).toInt()}%)...";
              });
            }
          },
        );
      }

      setState(() {
        _uploadProgress = 0.95;
        _uploadStatusMessage = "Finalizing listing in marketplace...";
      });

      final newItem = MarketplaceItem(
        id: itemId,
        ownerId: currentUser.id,
        ownerName: currentUser.name,
        ownerRating: currentUser.rating,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
        pickupLocation: _pickupLocationController.text.trim(),
        maxDurationDays: int.parse(_durationController.text.trim()),
        depositAmount: double.tryParse(_depositController.text.trim()),
        terms: _termsController.text.trim().isNotEmpty
            ? _termsController.text.trim()
            : null,
        createdAt: DateTime.now(),
        imageUrls: uploadedUrls,
        availability: ItemAvailability.available,
      );

      ref.read(marketplaceServiceProvider).addListing(newItem);

      if (mounted) {
        setState(() => _isUploading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[800],
            content: Text("Published '${newItem.title}' with ${uploadedUrls.length} photos!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text("Failed to publish listing: $e"),
          ),
        );
      }
    }
  }
}
