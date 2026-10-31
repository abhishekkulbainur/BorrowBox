// Dart Imports
import 'dart:io';

// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project Imports
import 'package:lendnborrow/core/cfg/cloudinary_config.dart';
import 'package:lendnborrow/core/models/listing_image.dart';
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/cloudinary_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
import 'package:lendnborrow/core/utils/responsive.dart';
import 'package:lendnborrow/core/widgets/product_image_view.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  final MarketplaceItem item;

  const EditListingScreen({super.key, required this.item});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _durationController;
  late final TextEditingController _depositController;
  late final TextEditingController _termsController;

  late ItemCategory _category;
  late ItemCondition _condition;
  late bool _isActive;
  bool _isLoading = false;

  // Photo management state
  late List<String> _currentPhotoUrls;
  final List<File> _newPhotoFiles = [];
  int _coverIndex = 0;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item.title);
    _descController = TextEditingController(text: item.description);
    _locationController = TextEditingController(text: item.pickupLocation);
    _durationController = TextEditingController(
      text: item.maxDurationDays.toString(),
    );
    _depositController = TextEditingController(
      text: item.depositAmount != null
          ? item.depositAmount!.toInt().toString()
          : "",
    );
    _termsController = TextEditingController(text: item.terms ?? "");
    _category = item.category;
    _condition = item.condition;
    _isActive = item.isActive;
    _currentPhotoUrls = List.from(item.photoUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _depositController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  int get _totalPhotoCount => _currentPhotoUrls.length + _newPhotoFiles.length;

  Future<void> _pickFromGallery() async {
    final cloudinary = CloudinaryService();
    final picked = await cloudinary.pickImagesFromGallery(
      currentCount: _totalPhotoCount,
    );

    if (picked.isNotEmpty && mounted) {
      setState(() {
        _newPhotoFiles.addAll(picked);
      });
    }
  }

  Future<void> _captureFromCamera() async {
    if (_totalPhotoCount >= CloudinaryConfig.maxImagesPerListing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum of 5 photos reached")),
      );
      return;
    }

    final cloudinary = CloudinaryService();
    final photo = await cloudinary.captureImageFromCamera();

    if (photo != null && mounted) {
      setState(() {
        _newPhotoFiles.add(photo);
      });
    }
  }

  void _showAddPhotoModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo with Camera"),
              onTap: () {
                Navigator.of(ctx).pop();
                _captureFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _currentPhotoUrls.removeAt(index);
      if (_coverIndex >= _totalPhotoCount) {
        _coverIndex = (_totalPhotoCount - 1).clamp(0, _totalPhotoCount);
      }
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotoFiles.removeAt(index);
      if (_coverIndex >= _totalPhotoCount) {
        _coverIndex = (_totalPhotoCount - 1).clamp(0, _totalPhotoCount);
      }
    });
  }

  void _setCover(int index) {
    setState(() {
      _coverIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser?.id != widget.item.ownerId) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Listing")),
        body: const Center(
          child: Text("You are not authorized to edit this listing."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Listing",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: "Delete Listing",
            onPressed: _confirmDelete,
          ),
        ],
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
              // Active / Paused Switch Card
              Card(
                elevation: 0,
                color: _isActive
                    ? Colors.green.withAlpha(20)
                    : Colors.grey.withAlpha(30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _isActive
                        ? Colors.green.withAlpha(70)
                        : Colors.grey.withAlpha(60),
                  ),
                ),
                child: SwitchListTile(
                  value: _isActive,
                  title: Text(
                    _isActive ? "Listing is Active" : "Listing is Paused",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  subtitle: Text(
                    _isActive
                        ? "Peers in the community can discover and request to borrow this item."
                        : "Hidden from search. Existing loans are unaffected.",
                    style: const TextStyle(fontSize: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _isActive = val);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ===============================================================
              // PRODUCT PHOTOS MANAGEMENT
              // ===============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Product Photos",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$_totalPhotoCount/${CloudinaryConfig.maxImagesPerListing} photos",
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Horizontal photos list
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing remote URLs
                    ..._currentPhotoUrls.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      final isCover = idx == _coverIndex;

                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCover ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(60),
                            width: isCover ? 2.5 : 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ProductImageView(
                                  imageUrl: url,
                                  category: _category,
                                  fit: BoxFit.cover,
                                  enableZoomOnTap: true,
                                ),
                              ),
                            ),
                            if (isCover)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text("Cover", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 14),
                                  onPressed: () => _removeExistingPhoto(idx),
                                ),
                              ),
                            ),
                            if (!isCover)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.star_border, color: Colors.amber, size: 14),
                                    onPressed: () => _setCover(idx),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    // Newly picked files
                    ..._newPhotoFiles.asMap().entries.map((entry) {
                      final idx = _currentPhotoUrls.length + entry.key;
                      final file = entry.value;
                      final isCover = idx == _coverIndex;

                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCover ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withAlpha(60),
                            width: isCover ? 2.5 : 1.0,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ProductImageView(
                                  imageUrl: file.path,
                                  category: _category,
                                  fit: BoxFit.cover,
                                  enableZoomOnTap: true,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete, color: Colors.white, size: 14),
                                  onPressed: () => _removeNewPhoto(entry.key),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add more button if space permits
                    if (_totalPhotoCount < CloudinaryConfig.maxImagesPerListing)
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(70)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _showAddPhotoModal,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: theme.colorScheme.primary, size: 24),
                              const SizedBox(height: 4),
                              const Text("Add Photo", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Item Title *",
                  hintText: "e.g., Bosch 18V Cordless Drill Kit",
                  prefixIcon: const Icon(Symbols.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Title required" : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<ItemCategory>(
                initialValue: _category == ItemCategory.all
                    ? ItemCategory.tools
                    : _category,
                decoration: InputDecoration(
                  labelText: "Category *",
                  prefixIcon: const Icon(Symbols.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemCategory.values
                    .where((c) => c != ItemCategory.all)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          MarketplaceItem(
                            id: "",
                            ownerId: "",
                            ownerName: "",
                            title: "",
                            description: "",
                            category: c,
                            condition: ItemCondition.good,
                            pickupLocation: "",
                            imageUrls: const [],
                            createdAt: DateTime.now(),
                          ).categoryDisplay,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<ItemCondition>(
                initialValue: _condition,
                decoration: InputDecoration(
                  labelText: "Item Condition *",
                  prefixIcon: const Icon(Symbols.verified),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemCondition.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          MarketplaceItem(
                            id: "",
                            ownerId: "",
                            ownerName: "",
                            title: "",
                            description: "",
                            category: ItemCategory.tools,
                            condition: c,
                            pickupLocation: "",
                            imageUrls: const [],
                            createdAt: DateTime.now(),
                          ).conditionDisplay,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _condition = val);
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Detailed Description *",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Description required"
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Pickup & Return Location *",
                  hintText: "e.g., Campus Library or Tower 3 Gate",
                  prefixIcon: const Icon(Symbols.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Location required"
                    : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Max Days",
                        prefixIcon: const Icon(Symbols.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        final parsed = int.tryParse(v ?? "");
                        if (parsed == null || parsed <= 0) {
                          return "Min 1 day";
                        }
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
                        labelText: "Deposit (₹)",
                        hintText: "0 if free",
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

              TextFormField(
                controller: _termsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Special Lending Conditions / Instructions",
                  hintText:
                      "e.g., Pack completely dry, wear protective eyewear during use.",
                  prefixIcon: const Icon(Symbols.gavel),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isLoading ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? "Saving & Uploading..." : "Save Listing Changes"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final deposit = double.tryParse(_depositController.text.trim());
      final duration = int.parse(_durationController.text.trim());

      // If new photos were added, upload them to Cloudinary
      final List<String> finalUrls = List.from(_currentPhotoUrls);
      List<ListingImage> updatedImagesMeta = List.from(widget.item.images);
      updatedImagesMeta.removeWhere(
          (img) => !_currentPhotoUrls.contains(img.secureUrl));

      if (_newPhotoFiles.isNotEmpty) {
        final cloudinary = CloudinaryService();
        final newUploaded = await cloudinary.uploadListingImages(
          userId: widget.item.ownerId,
          itemId: widget.item.id,
          files: _newPhotoFiles,
          coverIndex: 0,
        );
        updatedImagesMeta.addAll(newUploaded);
        finalUrls.addAll(newUploaded.map((img) => img.secureUrl));
      }

      // Ensure cover photo is placed at index 0 if cover was changed
      if (_coverIndex > 0 && _coverIndex < finalUrls.length) {
        final coverUrl = finalUrls.removeAt(_coverIndex);
        finalUrls.insert(0, coverUrl);
      }

      // Update cover flag in metadata
      updatedImagesMeta = updatedImagesMeta.asMap().entries.map((e) {
        return e.value.copyWith(
          order: e.key,
          isCover: e.key == 0,
        );
      }).toList();

      final updated = widget.item.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        condition: _condition,
        pickupLocation: _locationController.text.trim(),
        maxDurationDays: duration,
        depositAmount: deposit,
        terms: _termsController.text.trim().isNotEmpty
            ? _termsController.text.trim()
            : null,
        imageUrls: finalUrls,
        imagesMeta: updatedImagesMeta,
        isActive: _isActive,
        availability: _isActive
            ? (widget.item.availability == ItemAvailability.deactivated
                ? ItemAvailability.available
                : widget.item.availability)
            : ItemAvailability.deactivated,
      );

      ref.read(marketplaceServiceProvider).updateListing(updated);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Listing updated successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Failed to update listing: $e"),
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: Text(
          "Are you sure you want to permanently delete \"${widget.item.title}\"? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              final currentUserId = ref.read(currentUserProvider)?.id;
              ref.read(marketplaceServiceProvider).deleteListing(
                    widget.item.id,
                    actorId: currentUserId,
                  );
              // Clean up associated images via CloudinaryService
              CloudinaryService().deleteListingImages(
                itemId: widget.item.id,
                publicIds: widget.item.images
                    .map((i) => i.publicId)
                    .where((id) => id.isNotEmpty)
                    .toList(),
                imageUrls: widget.item.photoUrls,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Listing deleted from BorrowBox."),
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
