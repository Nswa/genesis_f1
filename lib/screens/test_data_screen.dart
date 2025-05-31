import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/test_data_injection_service.dart';
import '../controller/journal_controller.dart';class TestDataScreen extends StatefulWidget {  final JournalController journalController;  const TestDataScreen({    super.key,    required this.journalController,  });  @override  State<TestDataScreen> createState() => _TestDataScreenState();}class _TestDataScreenState extends State<TestDataScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  String _status = '';
  Map<String, dynamic>? _stats;
  late TestDataInjectionService _injectionService;

  @override
  void initState() {
    super.initState();
    _injectionService = TestDataInjectionService(vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _injectionService.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _injectionService.getDatabaseStats();
      setState(() {
        _stats = stats;
        _status = 'Database stats loaded';
      });
    } catch (e) {
      setState(() => _status = 'Error loading stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndInjectData() async {
    setState(() {
      _isLoading = true;
      _status = 'Injecting test data...';
    });

    try {
      // Check if test_data.json exists in the app directory
      final testDataPath = 'c:\\Users\\Administrator\\genesis_f1\\test_data.json';
      final testDataFile = File(testDataPath);
      
      if (!await testDataFile.exists()) {
        setState(() => _status = 'Error: test_data.json not found at $testDataPath');
        return;
      }

      setState(() => _status = 'Injecting test data from JSON...');
      
      final success = await _injectionService.injectFromJsonFile(testDataPath);
      
      if (success) {
        setState(() => _status = 'Reloading journal entries...');
        
        // Force reload entries from database to show injected data
        await widget.journalController.reloadEntriesFromDatabase();
        
        setState(() => _status = 'Test data injected successfully!');
        await _loadStats(); // Refresh stats
      } else {
        setState(() => _status = 'Failed to inject test data');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _injectFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isLoading = true;
          _status = 'Injecting data from file...';
        });

        final filePath = result.files.single.path!;
        final success = await _injectionService.injectFromJsonFile(filePath);
        
        if (success) {
          setState(() => _status = 'Reloading journal entries...');
          
          // Force reload entries from database to show injected data
          await widget.journalController.reloadEntriesFromDatabase();
          
          setState(() => _status = 'Data injected successfully from file!');
          await _loadStats(); // Refresh stats
        } else {
          setState(() => _status = 'Failed to inject data from file');
        }
      }
    } catch (e) {
      setState(() => _status = 'Error injecting from file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearTestData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Data'),
        content: const Text('Are you sure you want to delete all test entries? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _status = 'Clearing test data...';
      });

      try {
        final success = await _injectionService.flushDatabase();
        
        if (success) {
          setState(() => _status = 'Reloading journal entries...');
          
          // Force reload entries from database to show cleared data
          await widget.journalController.reloadEntriesFromDatabase();
          
          setState(() => _status = 'Test data cleared successfully!');
          await _loadStats(); // Refresh stats
        } else {
          setState(() => _status = 'Failed to clear test data');
        }
      } catch (e) {
        setState(() => _status = 'Error clearing data: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToFirebase() async {
    setState(() {
      _isLoading = true;
      _status = 'Syncing test data to Firebase...';
    });

    try {
      await TestDataInjectionService.syncTestDataToFirebase();
      
      setState(() => _status = 'Reloading journal entries...');
      
      // Force reload entries from database to show updated sync status
      await widget.journalController.reloadEntriesFromDatabase();
      
      setState(() => _status = 'Test data synced to Firebase successfully!');
      await _loadStats(); // Refresh stats to show updated sync counts
    } catch (e) {
      setState(() => _status = 'Error syncing to Firebase: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatsCard() {
    if (_stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Loading stats...'),
        ),
      );
    }

    final totalEntries = _stats!['totalEntries'] ?? 0;
    final syncedEntries = _stats!['syncedEntries'] ?? 0;
    final unsyncedEntries = _stats!['unsyncedEntries'] ?? 0;
    final oldestEntry = _stats!['oldestEntry'];
    final newestEntry = _stats!['newestEntry'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total Entries', totalEntries.toString()),
            _buildStatRow('Synced Entries', syncedEntries.toString()),
            _buildStatRow('Unsynced Entries', unsyncedEntries.toString()),
            if (oldestEntry != null)
              _buildStatRow('Oldest Entry', _formatDate(oldestEntry)),
            if (newestEntry != null)
              _buildStatRow('Newest Entry', _formatDate(newestEntry)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatsCard(),
              const SizedBox(height: 20),
              
              // Status display
              if (_status.isNotEmpty)
                Card(
                  color: _status.startsWith('Error') 
                      ? Colors.red.shade50 
                      : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: _status.startsWith('Error') 
                            ? Colors.red.shade700 
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateAndInjectData,
                icon: const Icon(Icons.auto_graph),
                label: const Text('Inject Comprehensive Test Data (2 Years)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                ),
              ),
              
              const SizedBox(height: 12),              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _injectFromFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Import from JSON File'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _syncToFirebase,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Sync Test Data to Firebase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                ),
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Stats'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                ),
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearTestData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear All Test Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}