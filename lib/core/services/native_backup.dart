import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// Project Imports
import 'package:lendnborrow/core/db/db.dart';

enum BackupStatus { success, cancelled, error }

class BackupResult {
  final BackupStatus status;
  final String message;

  const BackupResult._(this.status, this.message);

  factory BackupResult.success([
    String message = "Operation completed successfully.",
  ]) => BackupResult._(BackupStatus.success, message);

  factory BackupResult.cancelled([
    String message = "Operation cancelled by user.",
  ]) => BackupResult._(BackupStatus.cancelled, message);

  factory BackupResult.error(String message) =>
      BackupResult._(BackupStatus.error, message);

  bool get isSuccess => status == BackupStatus.success;
  bool get isCancelled => status == BackupStatus.cancelled;
  bool get isError => status == BackupStatus.error;
}

class NativeBackup {
  static const MethodChannel _ch = MethodChannel('app.backup');
  static bool _inProgress = false;

  static bool get isInProgress => _inProgress;

  /// Opens system save dialog and writes the local SQLite DB to the chosen location.
  /// Returns a [BackupResult] indicating success, cancellation, or error.
  static Future<BackupResult> exportWithPicker() async {
    if (_inProgress) {
      return BackupResult.error(
        "Another backup operation is already in progress.",
      );
    }
    _inProgress = true;
    try {
      final dbPath = await Db.getDbPath();
      final dbFile = File(dbPath);
      if (!await dbFile.exists() || await dbFile.length() == 0) {
        // Ensure database file is initialized before export
        await Db.getInstance();
      }
      await Db.close();

      final ok = await _ch.invokeMethod<bool>('exportDb', {
        'dbPath': dbPath,
        'suggestedName': 'borrowbox_offline_ledger.db',
      });

      // Always restore database connection after export
      await Db.getInstance();

      if (ok == true) {
        return BackupResult.success("Offline ledger exported successfully.");
      } else {
        return BackupResult.cancelled("Export cancelled.");
      }
    } on PlatformException catch (pe) {
      await Db.getInstance();
      if (pe.code == 'CANCELLED') {
        return BackupResult.cancelled("Export cancelled.");
      }
      return BackupResult.error(
        pe.message ?? "Export failed due to platform error.",
      );
    } catch (e) {
      await Db.getInstance();
      return BackupResult.error(e.toString());
    } finally {
      _inProgress = false;
    }
  }

  /// Opens system open dialog, reads chosen file into a temp file, validates it,
  /// creates a safety backup of existing DB, and safely replaces the active DB.
  /// Returns a [BackupResult] indicating success, cancellation, or error.
  static Future<BackupResult> importWithPicker() async {
    if (_inProgress) {
      return BackupResult.error(
        "Another backup operation is already in progress.",
      );
    }
    _inProgress = true;
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempRestorePath = join(
        tempDir.path,
        "restore_temp_${DateTime.now().millisecondsSinceEpoch}.db",
      );
      tempFile = File(tempRestorePath);

      // Instruct platform code to write user-selected file into tempRestorePath
      final ok = await _ch.invokeMethod<bool>('importDb', {
        'dbPath': tempRestorePath,
      });

      if (ok != true || !await tempFile.exists()) {
        if (await tempFile.exists()) await tempFile.delete();
        return BackupResult.cancelled("Import cancelled.");
      }

      final fileSize = await tempFile.length();
      if (fileSize < 100) {
        if (await tempFile.exists()) await tempFile.delete();
        return BackupResult.error("Selected file is empty or corrupted.");
      }

      // Step 1: Validate SQLite header and schema integrity
      Database? testDb;
      try {
        testDb = await openDatabase(tempRestorePath, readOnly: true);
        final tables = await testDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();
        await testDb.close();
        testDb = null;

        // Ensure this is an authentic BorrowBox SQLite ledger database
        if (!tableNames.contains('items')) {
          if (await tempFile.exists()) await tempFile.delete();
          return BackupResult.error(
            "Selected file is not a valid BorrowBox offline ledger backup (missing items table).",
          );
        }
      } catch (validationErr) {
        if (testDb != null && testDb.isOpen) await testDb.close();
        if (await tempFile.exists()) await tempFile.delete();
        return BackupResult.error(
          "Invalid database file format: Could not read SQLite structure ($validationErr).",
        );
      }

      // Step 2: Create safety backup of current active database first
      await Db.backupToAppFolder();

      // Step 3: Safely replace active database with validated backup
      await Db.restoreFromFile(tempFile);
      if (await tempFile.exists()) await tempFile.delete();

      // Step 4: Re-initialize the active database instance
      await Db.getInstance();

      return BackupResult.success("Offline ledger restored successfully.");
    } on PlatformException catch (pe) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      await Db.getInstance();
      if (pe.code == 'CANCELLED') {
        return BackupResult.cancelled("Import cancelled.");
      }
      return BackupResult.error(
        pe.message ?? "Import failed due to platform error.",
      );
    } catch (e) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      await Db.getInstance();
      return BackupResult.error(e.toString());
    } finally {
      _inProgress = false;
    }
  }
}
