#!/usr/bin/env dart
// Setup script for test data generation and injection

import 'dart:io';

void main() async {
  print('🚀 Setting up comprehensive test data for Collective app...\n');

  // Check if we're in the right directory
  final currentDir = Directory.current;
  if (!File('${currentDir.path}/pubspec.yaml').existsSync()) {
    print('❌ Error: Please run this script from the root directory of the Collective project');
    exit(1);
  }

  // Step 1: Generate test data
  print('📝 Step 1: Generating comprehensive test data...');
  final generateResult = await Process.run(
    'dart',
    ['run', 'scripts/generate_test_data_comprehensive.dart'],
    workingDirectory: currentDir.path,
  );

  if (generateResult.exitCode != 0) {
    print('❌ Error generating test data:');
    print(generateResult.stderr);
    exit(1);
  }

  print(generateResult.stdout);

  // Step 2: Check if test_data.json was created
  final testDataFile = File('${currentDir.path}/test_data.json');
  if (!testDataFile.existsSync()) {
    print('❌ Error: test_data.json was not created');
    exit(1);
  }

  print('✅ Test data generation completed successfully!');
  print('📊 File created: ${testDataFile.path}');
  print('📏 File size: ${(testDataFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB\n');

  // Step 3: Instructions
  print('🎯 Next steps:');
  print('1. Run the app: flutter run');
  print('2. Navigate to: Settings → Test Data Management');
  print('3. Click: "Inject Comprehensive Data (2 Years)"');
  print('4. Enjoy exploring 1500+ realistic journal entries!\n');

  // Step 4: Show statistics preview
  print('📈 Quick Preview:');
  final content = await testDataFile.readAsString();
  final lines = content.split('\n').length;
  print('   • JSON lines: ${lines.toString().padLeft(6)}');
  print('   • File size: ${(testDataFile.lengthSync() / 1024).toStringAsFixed(1).padLeft(6)} KB');
  print('   • Ready for injection into the app!\n');

  print('🎉 Setup complete! Happy journaling!');
}
