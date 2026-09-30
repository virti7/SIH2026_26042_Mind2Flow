import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/audio_play_button.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/chips.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/translation_bloc.dart';

// SCREEN 47: New Sentence Translation Result
class NewSentenceTranslationScreen extends StatefulWidget {
  const NewSentenceTranslationScreen({super.key});

  @override
  State<NewSentenceTranslationScreen> createState() => _NewSentenceTranslationScreenState();
}

class _NewSentenceTranslationScreenState extends State<NewSentenceTranslationScreen> {
  final TextEditingController _textController = TextEditingController(
    text: 'कल विद्यालय में सरहुल पर्व का अवकाश रहेगा।',
  );
  TribalLanguage _targetLanguage = TribalLanguage.mundari;
  bool _isTranslating = false;
  String _translatedText = 'गापा स्कूल रे सरहुल परोब रेयाः छुट्टी ताहेंना।';
  int _latencyMs = 280;

  final List<String> _samplePrompts = [
    'कल विद्यालय में सरहुल पर्व का अवकाश रहेगा।',
    'सभी बच्चे अपनी कॉपी और पेंसिल निकालें।',
    'आज हम मिलकर पेड़-पौधों के बारे में सीखेंगे।',
    'अपनी बारी का इंतजार करें और ध्यान से सुनें।',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _translateSentence() {
    setState(() {
      _isTranslating = true;
    });

    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        String result;
        if (_targetLanguage == TribalLanguage.mundari) {
          result = 'गापा स्कूल रे सरहुल परोब रेयाः छुट्टी ताहेंना।';
        } else if (_targetLanguage == TribalLanguage.ho) {
          result = 'गापा स्कूल रे बाः परोब रेयाः छुट्टी ताइना।';
        } else {
          result = 'गापा बिरदॉगाड़ रे बाहा पोरब रेनाः छुट्टी ताहेंना।';
        }

        setState(() {
          _translatedText = result;
          _isTranslating = false;
          _latencyMs = 260 + (_textController.text.length % 50);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'New Sentence Translation',
      subtitle: 'Type any Hindi sentence and hear it instantly in Ho, Mundari or Santali.',
      breadcrumb: 'Translate > New Sentence',
      isScrollable: true,
      bottomActionBar: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Flag Translation',
              icon: Icons.flag_outlined,
              onPressed: () => context.push(AppRoutes.translationFeedback),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Broadcast to Class',
              icon: Icons.volume_up_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Broadcasting translation in ${_targetLanguage.displayName} to classroom speaker.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offline readiness banner — white card, green icon wash
          CustomCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Works Offline on This Device',
                        style: AppTypography.cardTitle.copyWith(fontSize: 13, color: AppColors.primaryDark),
                      ),
                      Text(
                        'Type in Hindi • Hear it in your classroom language',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const OfflineBadge(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Target Language Selector
          Text('Select Target Mother Tongue (लक्ष्य भाषा):', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LanguageChip(
                language: TribalLanguage.mundari,
                isSelected: _targetLanguage == TribalLanguage.mundari,
                onTap: () {
                  setState(() => _targetLanguage = TribalLanguage.mundari);
                  _translateSentence();
                },
              ),
              LanguageChip(
                language: TribalLanguage.ho,
                isSelected: _targetLanguage == TribalLanguage.ho,
                onTap: () {
                  setState(() => _targetLanguage = TribalLanguage.ho);
                  _translateSentence();
                },
              ),
              LanguageChip(
                language: TribalLanguage.santali,
                isSelected: _targetLanguage == TribalLanguage.santali,
                onTap: () {
                  setState(() => _targetLanguage = TribalLanguage.santali);
                  _translateSentence();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Unseen Input Box
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Enter Any Hindi Sentence (शिक्षक कथन):', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () {
                        _textController.text = _samplePrompts[(_samplePrompts.indexOf(_textController.text) + 1) % _samplePrompts.length];
                        _translateSentence();
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 14),
                      label: const Text('Try Another Prompt', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type any classroom instruction or concept...',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.radiusMd,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    label: 'Translate to Mother Tongue',
                    icon: Icons.translate_rounded,
                    isLoading: _isTranslating,
                    onPressed: _translateSentence,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Context used for this translation
          CustomCard(
            color: AppColors.accentBlueLight,
            border: const BorderSide(color: AppColors.accentBlue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Context used (why this wording was chosen)',
                    style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentBlue)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in [
                      'Class 2-A',
                      'Numbers up to 100',
                      'M2.1.4',
                      'Mahua seed activity',
                      'Previous: attendance call',
                      'Vocab: छुट्टी • परोब',
                    ])
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: AppColors.accentBlue),
                        ),
                        child: Text(c,
                            style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Detected meaning: school-holiday announcement for the whole class (informative tone). Works with brand-new sentences offline — not limited to saved phrases.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Translation Result Card
          CustomCard(
            color: AppColors.greenSurface,
            border: const BorderSide(color: AppColors.greenBorder),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${_targetLanguage.displayName} (${_targetLanguage.hindiName})',
                          style: AppTypography.cardTitle.copyWith(color: AppColors.primary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: AppRadius.radiusPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, size: 10, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text('$_latencyMs ms', style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const AudioPlayButton(compact: true),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _translatedText,
                  style: AppTypography.tribalVernacular.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.statusAchieved),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Ready to play in class', style: AppTypography.caption.copyWith(color: AppColors.statusAchieved, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SecondaryButton(
                      label: 'Copy',
                      icon: Icons.copy_rounded,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _translatedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Translation copied.')),
                        );
                      },
                    ),
                    SecondaryButton(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      onPressed: _translateSentence,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Options Card
          CustomCard(
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved to Verified Classroom Phrase Bank.')),
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Save to Phrase Bank'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.languageRouter),
                  icon: const Icon(Icons.alt_route_rounded, size: 18),
                  label: const Text('Open 3-Way Router'),
                ),
                TextButton.icon(
                  onPressed: () {
                    try {
                      context.read<TranslationBloc>().add(
                          SendTeacherCustomUtterance(_textController.text));
                    } catch (_) {}
                    context.push(AppRoutes.twoWayConversation);
                  },
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text('Use in conversation'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
