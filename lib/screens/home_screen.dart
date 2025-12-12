import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:magicslides/screens/login_screen.dart';
import 'package:magicslides/screens/presentation_preview_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:magicslides/features/theme/presentation/theme_provider.dart';
import 'package:magicslides/features/generator/presentation/generator_provider.dart';
import 'package:magicslides/features/generator/domain/presentation_request_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'Default';
  String? _selectedTemplate;
  String _topic = '';

  double _slideCount = 10;
  String _language = 'en';
  bool _aiImages = false;
  bool _imageOnEachSlide = false;
  bool _googleImages = false;
  bool _googleText = false;
  String _selectedModel = 'gpt-4';
  String _presentationFor = '';

  String _watermarkWidth = '';
  String _watermarkHeight = '';
  String _brandUrl = '';
  String _watermarkPosition = '';

  final List<String> _defaultTemplates = [
    'bullet-point1',
    'bullet-point2',
    'bullet-point4',
    'bullet-point5',
    'bullet-point6',
    'bullet-point7',
    'bullet-point8',
    'bullet-point9',
    'bullet-point10',

    for (var i = 2; i <= 9; i++) 'custom$i',
    'verticalBulletPoint1',
    'verticalCustom1',
  ];

  final List<String> _editableTemplates = [
    'ed-bullet-point9',
    'ed-bullet-point7',
    'ed-bullet-point6',
    'ed-bullet-point5',
    'ed-bullet-point2',
    'ed-bullet-point4',
    'custom gold 1',
    'custom Dark 1',

    for (var i = 1; i <= 6; i++) 'custom sync $i',

    for (var i = 7; i <= 12; i++) 'custom-ed-$i',
    'pitchdeckorignal',
    'pitch-deck-2',
    'pitch-deck-3',
    'ed-bullet-point1',
  ];

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _toggleTheme() {
    ref.read(themeProvider.notifier).toggleTheme(context);
  }

  Future<void> _generatePresentation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User email not found. Please login again.'),
        ),
      );
      return;
    }
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a template.')),
      );
      return;
    }
    if (_topic.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a topic.')));
      return;
    }

    final accessId = dotenv.env['ACCESS_ID'];
    if (accessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access ID not found in environment.')),
      );
      return;
    }

    final request = PresentationRequest(
      topic: _topic,
      email: user.email!,
      accessId: accessId,
      template: _selectedTemplate!,
      slideCount: _slideCount.toInt(),
      language: _language,
      aiImages: _aiImages,
      imageForEachSlide: _imageOnEachSlide,
      googleImage: _googleImages,
      googleText: _googleText,
      model: _selectedModel,
      presentationFor: _presentationFor,
      watermark:
          (_watermarkWidth.isNotEmpty ||
              _watermarkHeight.isNotEmpty ||
              _brandUrl.isNotEmpty ||
              _watermarkPosition.isNotEmpty)
          ? WatermarkRequest(
              width: _watermarkWidth,
              height: _watermarkHeight,
              brandUrl: _brandUrl,
              position: _watermarkPosition,
            )
          : null,
    );

    await ref.read(generatorProvider.notifier).generate(request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Map<String, dynamic>?>>(generatorProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (data) {
          if (data != null) {
            showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Select File Type'),
                  content: const Text(
                    'The presentation was generated successfully. Please select the format to view.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('PPT'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('PDF'),
                    ),
                  ],
                );
              },
            ).then((isPdf) {
              if (isPdf != null) {
                final url = isPdf
                    ? "https://getsamplefiles.com/download/pdf/sample-1.pdf"
                    : "https://samples-files.com/samples/documents/pptx/sample1.ppt";

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PresentationPreviewScreen(url: url),
                  ),
                );
              }
              // Reset state after handling success
              ref.read(generatorProvider.notifier).reset();
            });
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        loading: () {},
      );
    });

    final generatorState = ref.watch(generatorProvider);
    final _isGenerating = generatorState.isLoading;

    final user = Supabase.instance.client.auth.currentUser;
    final currentTemplates = _selectedCategory == 'Default'
        ? _defaultTemplates
        : _editableTemplates;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeProvider);

    // Helper text style for section headers
    final sectionHeaderStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.primary,
    );

    // Common input decoration
    InputDecoration inputDecoration(String label, {IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: colorScheme.primary)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor, // Contrasts with Card color
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'MagicSlides',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleTheme,
            icon: Icon(
              themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : MediaQuery.platformBrightnessOf(context) == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      // ... body ...
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Welcome Card ---
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      radius: 24,
                      child: Icon(Icons.person, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? 'User',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Template Section ---
            Text("Design", style: sectionHeaderStyle),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Template Type", style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'Default',
                            label: Text('Default'),
                            icon: Icon(Icons.dashboard_outlined),
                          ),
                          ButtonSegment<String>(
                            value: 'Editable',
                            label: Text('Editable'),
                            icon: Icon(Icons.edit_outlined),
                          ),
                        ],
                        selected: {_selectedCategory},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedCategory = newSelection.first;
                            _selectedTemplate = null;
                          });
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.comfortable,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: MaterialStateProperty.all(
                            BorderSide(
                              color: colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: inputDecoration(
                        'Choose a Template',
                        icon: Icons.layers_outlined,
                      ),
                      value: _selectedTemplate,
                      isExpanded: true,
                      items: currentTemplates.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) =>
                          setState(() => _selectedTemplate = newValue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Content Settings ---
            Text("Content", style: sectionHeaderStyle),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: inputDecoration(
                        'Topic',
                        icon: Icons.topic_outlined,
                      ),
                      onChanged: (val) => setState(() => _topic = val),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _language,
                            decoration: inputDecoration(
                              'Language',
                              icon: Icons.language,
                            ),
                            onChanged: (val) => setState(() => _language = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: inputDecoration(
                              'Audience',
                              icon: Icons.people_outline,
                            ),
                            onChanged: (val) =>
                                setState(() => _presentationFor = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: inputDecoration(
                        'AI Model',
                        icon: Icons.psychology,
                      ),
                      value: _selectedModel,
                      items: ['gpt-4', 'gpt-3.5'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null)
                          setState(() => _selectedModel = newValue);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Slide Configuration ---
            Text("Configuration", style: sectionHeaderStyle),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Slide Count"),
                      subtitle: Text(
                        "Total slides: ${_slideCount.toInt()}",
                        style: TextStyle(color: colorScheme.primary),
                      ),
                      trailing: Icon(Icons.slideshow, color: theme.hintColor),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colorScheme.primary,
                        thumbColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.primary.withOpacity(
                          0.2,
                        ),
                      ),
                      child: Slider(
                        value: _slideCount,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: _slideCount.toInt().toString(),
                        onChanged: (value) =>
                            setState(() => _slideCount = value),
                      ),
                    ),
                    const Divider(),
                    SwitchListTile(
                      activeColor: colorScheme.primary,
                      title: const Text('AI Images'),
                      secondary: const Icon(Icons.auto_awesome),
                      value: _aiImages,
                      onChanged: (val) => setState(() => _aiImages = val),
                    ),
                    SwitchListTile(
                      activeColor: colorScheme.primary,
                      title: const Text('Image on each slide'),
                      secondary: const Icon(Icons.image_outlined),
                      value: _imageOnEachSlide,
                      onChanged: (val) =>
                          setState(() => _imageOnEachSlide = val),
                    ),
                    SwitchListTile(
                      activeColor: colorScheme.primary,
                      title: const Text('Google Images'),
                      secondary: const Icon(Icons.search),
                      value: _googleImages,
                      onChanged: (val) => setState(() => _googleImages = val),
                    ),
                    SwitchListTile(
                      activeColor: colorScheme.primary,
                      title: const Text('Google Text'),
                      secondary: const Icon(Icons.text_fields),
                      value: _googleText,
                      onChanged: (val) => setState(() => _googleText = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Watermark (Expansion Tile to save space) ---
            Card(
              elevation: 2,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Watermark Settings (Optional)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                leading: Icon(
                  Icons.branding_watermark,
                  color: colorScheme.primary,
                ),
                iconColor: colorScheme.primary,
                childrenPadding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: inputDecoration('Width'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              setState(() => _watermarkWidth = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: inputDecoration('Height'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              setState(() => _watermarkHeight = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: inputDecoration('Brand URL', icon: Icons.link),
                    onChanged: (val) => setState(() => _brandUrl = val),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: inputDecoration(
                      'Position',
                      icon: Icons.format_align_center,
                    ),
                    onChanged: (val) =>
                        setState(() => _watermarkPosition = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- Generate Button ---
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generatePresentation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isGenerating
                    ? const SizedBox.shrink()
                    : const Icon(Icons.rocket_launch),
                label: _isGenerating
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Generate Presentation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
