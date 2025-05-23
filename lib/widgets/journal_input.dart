import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // No longer needed here
import '../controller/journal_controller.dart'; // Added controller import
import '../utils/mood_utils.dart';
import '../utils/date_formatter.dart';
import 'package:genesis_f1/services/user_profile_service.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class JournalInputWidget extends StatefulWidget {
  final JournalController journalController;

  const JournalInputWidget({super.key, required this.journalController});

  @override
  State<JournalInputWidget> createState() => _JournalInputWidgetState();
}

class _JournalInputWidgetState extends State<JournalInputWidget>
    with TickerProviderStateMixin {
  late AnimationController _emojiBarController;  bool _isEmojiBarExpanded = false;  // File? _pickedImageFile; // Removed, will use widget.journalController.pickedImageFile
  // final ImagePicker _picker = ImagePicker(); // Removed, logic in JournalController
  bool _isRecording = false;
  
  // Camera related variables
  CameraController? _cameraController;
  bool _showCameraPreview = false;
  bool _isCameraInitialized = false;
  bool _isVideoRecording = false;
  Timer? _recordingTimer;
  File? _generatedGif;  @override
  void initState() {
    super.initState();
    _emojiBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Set up callback to clear GIF when image is picked
    widget.journalController.onClearGif = () {
      if (mounted) {
        setState(() {
          _generatedGif = null;
        });
      }
    };
  }  @override
  void dispose() {
    _emojiBarController.dispose();
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.low,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  void _startRecording() async {
    setState(() {
      _isRecording = true;
    });
    
    // Wait for button to finish ascending (150ms)
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (_isRecording) {
      // Initialize camera if not already done
      if (_cameraController == null) {
        await _initializeCamera();
      }
      
      if (_isCameraInitialized && mounted) {
        setState(() {
          _showCameraPreview = true;
        });
        
        // Start video recording
        await _startVideoRecording();
      }
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        await _cameraController!.startVideoRecording();
        
        setState(() {
          _isVideoRecording = true;
        });
        
        // Auto-stop recording after 5 seconds (configurable between 3-7s)
        _recordingTimer = Timer(const Duration(seconds: 5), () {
          _stopRecording();
        });
      }
    } catch (e) {
      print('Error starting video recording: $e');
      _stopRecording();
    }
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    
    if (_isVideoRecording && _cameraController != null) {
      try {        final XFile videoFile = await _cameraController!.stopVideoRecording();
        // Convert video to GIF using ffmpeg_kit_flutter_new
        await _convertVideoToGif(videoFile);
        
      } catch (e) {
        print('Error stopping video recording: $e');
      }
    }
    
    setState(() {
      _isRecording = false;
      _showCameraPreview = false;
      _isVideoRecording = false;
    });
    
    //dispose camera usage
    _cameraController?.dispose();
    _cameraController = null;
  }
  Future<void> _convertVideoToGif(XFile videoFile) async {
    try {
      // Get temporary directory for GIF storage
      final Directory tempDir = await getTemporaryDirectory();
      final String gifPath = path.join(
        tempDir.path,
        'journal_gif_${DateTime.now().millisecondsSinceEpoch}.gif',
      );
      
      // FFmpeg command to convert video to GIF
      // Scale to 320px width, optimize for file size, and set frame rate to 10fps
      final String command = '-i "${videoFile.path}" -vf "scale=320:-1:flags=lanczos,fps=10" -loop 0 "$gifPath"';
      
      print('Starting GIF conversion...');
      
      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          print('GIF conversion successful: $gifPath');
          
          final File gifFile = File(gifPath);
          if (await gifFile.exists()) {            setState(() {
              _generatedGif = gifFile;
              // Clear any selected image since only one media type is allowed
              widget.journalController.clearImage();
            });
            print('GIF file size: ${await gifFile.length()} bytes');
          }
        } else {
          print('GIF conversion failed with return code: $returnCode');
        }
      });
      
    } catch (e) {
      print('Error converting video to GIF: $e');
    }
  }

  // Future<void> _pickImage() async { // Moved to JournalController
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     setState(() {
  //       _pickedImageFile = File(image.path);
  //     });
  //   }
  // }

  // void _clearImage() { // Moved to JournalController
  //   setState(() {
  //     _pickedImageFile = null;
  //   });
  // }

  void _toggleEmojiBar() {
    setState(() {
      _isEmojiBarExpanded = !_isEmojiBarExpanded;
      if (_isEmojiBarExpanded) {
        _emojiBarController.forward();
      } else {
        _emojiBarController.reverse();
      }
    });
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
  String _getHintText() {
    final profile = UserProfileService.instance.profile;
    if (profile != null) {
      final firstWord = profile.firstName.split(" ")[0];
      return "${_getTimeOfDayGreeting()}, ${firstWord.toLowerCase()}...";
    }
    return "Write your thoughts...";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    final fadeValue = (1 +
            (widget.journalController.dragOffsetY /
                widget.journalController.swipeThreshold))
        .clamp(0.0, 1.0);
    final scaleValue = (1 -
            (widget.journalController.dragOffsetY.abs() /
                (widget.journalController.swipeThreshold * 1.5)))
        .clamp(0.8, 1.0);

    final bool isSaving = widget.journalController.isSavingEntry;

    return IgnorePointer(
      // Ignore all pointer events if saving
      ignoring: isSaving,
      child: AnimatedOpacity(
        // Wrap with AnimatedOpacity
        duration: const Duration(milliseconds: 200),
        opacity: isSaving ? 0.5 : 1.0, // Grey out if saving
        child: Transform.translate(
          offset: Offset(0, widget.journalController.dragOffsetY),
          child: Transform.scale(
            scale: scaleValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  child: Opacity(
                    // This opacity is for the drag fade effect
                    opacity: fadeValue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 1),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormatter.formatTime(now),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.hintColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ), // Standardized spacing
                                IconButton(
                                  icon:
                                      widget.journalController.selectedMood !=
                                              null
                                          ? Text(
                                            widget
                                                .journalController
                                                .selectedMood!,
                                            style: const TextStyle(
                                              fontSize: 16, // Consistent size
                                            ),
                                          )
                                          : Icon(
                                            Icons.mood,
                                            size: 18, // Consistent icon size
                                            color: theme.iconTheme.color
                                                ?.withOpacity(
                                                  0.7,
                                                ), // Consistent color
                                          ),
                                  onPressed: _toggleEmojiBar,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(
                                  width: 4,
                                ), // Standardized spacing
                                IconButton(
                                  icon: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 18, // Consistent icon size
                                    color: theme.iconTheme.color?.withOpacity(
                                      0.7,
                                    ), // Consistent color
                                  ),
                                  onPressed: widget.journalController.pickImage,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Spacer(),
                                Text(
                                  DateFormatter.formatFullDate(now),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.hintColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            IgnorePointer(
                              ignoring: true,
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                size: 18, // Consistent icon size
                                color: theme.iconTheme.color?.withOpacity(
                                  0.5,
                                ), // Consistent color
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Standardized spacing
                        Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        cursorColor: theme.brightness == Brightness.dark
                                            ? Colors.white70
                                            : Colors.black54,
                                        controller: widget.journalController.controller,
                                        focusNode: widget.journalController.focusNode,
                                        enabled: !isSaving,
                                        maxLines: null,
                                        style: theme.textTheme.bodyMedium,
                                        decoration: InputDecoration(
                                          hintText: isSaving ? "Saving entry..." : _getHintText(),
                                          hintStyle: TextStyle(color: theme.hintColor),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),                                    GestureDetector(
                                      onTapDown: (details) {
                                        _startRecording();
                                      },
                                      onTapUp: (details) {
                                        _stopRecording();
                                      },
                                      onTapCancel: () {
                                        _stopRecording();
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            curve: Curves.easeInOut,
                                            transform: _isRecording
                                                ? Matrix4.translationValues(0, -55, 0)
                                                : Matrix4.identity(),
                                            child: Icon(
                                              Icons.radio_button_checked,
                                              size: 28,
                                              color: _isRecording ? Colors.red : theme.iconTheme.color?.withOpacity(0.7),
                                            ),
                                          ),
                                          // Camera preview positioned above the button
                                          if (_showCameraPreview && _isCameraInitialized && _cameraController != null)
                                            Positioned(
                                              bottom: 90, // Position above the button
                                              left: -90, // Center horizontally
                                              child: Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.red, width: 3),
                                                ),
                                                child: ClipOval(
                                                  child: CameraPreview(_cameraController!),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        if (widget.journalController.pickedImageFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 100,
                                    maxWidth: 150,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3.5),
                                    child: Image.file(
                                      widget.journalController.pickedImageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      widget
                                          .journalController
                                          .clearImage, // Individual disabling handled by IgnorePointer
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(128),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),                          ),
                        // GIF preview (similar to image preview)
                        if (_generatedGif != null && widget.journalController.pickedImageFile == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 100,
                                    maxWidth: 150,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3.5),
                                    child: Image.file(
                                      _generatedGif!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _generatedGif = null;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(128),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: _isEmojiBarExpanded ? 33 : 0,
                  margin: const EdgeInsets.only(top: 4),
                  child: ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        children:
                            availableMoods.map((emoji) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  // Individual disabling handled by IgnorePointer
                                  widget.journalController.selectedMood = emoji;
                                  _toggleEmojiBar();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    emoji,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color:
                                          widget
                                                      .journalController
                                                      .selectedMood ==
                                                  emoji
                                              ? theme.textTheme.bodyLarge?.color
                                              : theme.textTheme.bodyLarge?.color
                                                  ?.withAlpha(
                                                    (0.8 * 255).round(),
                                                  ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
