// Flutter Imports
import 'package:flutter/material.dart';

// Package Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Project Imports
import 'package:lendnborrow/core/models/marketplace_item.dart';
import 'package:lendnborrow/core/services/auth_service.dart';
import 'package:lendnborrow/core/services/marketplace_service.dart';
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

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text("Share an Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Basic Information",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Item Name & Model *",
                  hintText: "e.g., Bosch Cordless Drill, Casio fx-991EX",
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemCategory.values
                    .where((c) => c != ItemCategory.all)
                    .map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name.toUpperCase()),
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
                  labelText: "Description & What's Included *",
                  hintText:
                      "Describe accessories, bits, manuals, or chargers included...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Description is required"
                    : null,
              ),
              const SizedBox(height: 20),

              Text(
                "Condition & Lending Terms",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Condition Dropdown
              DropdownButtonFormField<ItemCondition>(
                initialValue: _selectedCondition,
                decoration: InputDecoration(
                  labelText: "Item Condition *",
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) =>
                          val == null || int.tryParse(val) == null
                          ? "Enter valid days"
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _depositController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Deposit (₹, optional)",
                        hintText: "0",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Terms
              TextFormField(
                controller: _termsController,
                decoration: InputDecoration(
                  labelText: "Owner Terms / Care Instructions (optional)",
                  hintText: "e.g., Please return dry; keep away from water.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _submitListing,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Publish Listing to Marketplace"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitListing() {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final newItem = MarketplaceItem(
        id: "item_${const Uuid().v4().substring(0, 8)}",
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
        imageUrls: [],
        availability: ItemAvailability.available,
      );

      ref.read(marketplaceServiceProvider).addListing(newItem);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[800],
          content: Text("Published '${newItem.title}' to the community!"),
        ),
      );
    }
  }
}
