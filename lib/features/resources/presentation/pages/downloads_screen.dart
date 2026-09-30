import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/services/current_user_service.dart';
import '../../../../core/constants/worksheet_languages.dart';
import '../../../../core/database/account_scope.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/remote_content_data_source.dart';
import '../../../../core/sync/worksheet_download_store.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/worksheet_template/worksheet_template.dart';
import '../widgets/worksheet_print_preview.dart';
import '../widgets/worksheet_template_view.dart';
import 'generated_flashcard_deck_screen.dart';

String _typeTitle(String code) {
  switch (code) {
    case 'practice':
      return 'Practice';
    case 'matching':
      return 'Matching';
    case 'fill_blank':
      return 'Fill in the Blanks';
    case 'multiple_choice':
      return 'Multiple Choice';
    case 'counting':
      return 'Counting';
    case 'counting_objects':
      return 'Counting Objects';
    case 'writing':
      return 'Writing';
    case 'reading':
      return 'Reading';
    default:
      return code;
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDateTime(DateTime dt) {
  return DateFormat('d MMM yyyy • h:mm a').format(dt);
}

/// Authenticated Supabase user UUID, or null when signed out / unavailable.
/// Ownership is always derived from this — never email, name, or device id.
String? _currentOwnerId() {
  try {
    if (getIt.isRegistered<CurrentUserService>()) {
      return getIt<CurrentUserService>().currentUserId;
    }
  } catch (_) {}
  return null;
}

Future<WorksheetDownloadStore> _store() async {
  if (getIt.isRegistered<WorksheetDownloadStore>()) {
    return getIt<WorksheetDownloadStore>();
  }
  AppDatabase? db;
  try {
    db = getIt.isRegistered<AppDatabase>() ? getIt<AppDatabase>() : null;
  } catch (_) {
    db = null;
  }
  if (db != null) {
    // Degraded boot (DI store missing): still scope by account instead of
    // falling back to global visibility.
    try {
      if (getIt.isRegistered<CurrentUserService>()) {
        final svc = getIt<CurrentUserService>();
        return DriftWorksheetDownloadStore(db,
            currentUserIdProvider: () => svc.currentUserId);
      }
    } catch (_) {}
  }
  return resolveDownloadStore(database: db);
}

// SCREEN: Downloads — worksheets saved on this device for offline use.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<WorksheetDownload> _all = [];
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String _search = '';
  String? _classFilter;
  String? _sectionFilter;
  String? _subjectFilter;
  String? _languageFilter;
  String? _typeFilter;
  String? _resourceTypeFilter;
  String _dateFilter = 'All';
  String? _downloadingId;

  final TextEditingController _searchController = TextEditingController();

  /// Owner captured when [_all]/[_pending] were loaded. State objects can
  /// outlive an account switch (logout → login without app restart), so a
  /// change here clears the previous teacher's rows before reloading —
  /// Account B never flashes Account A's downloads.
  String? _ownerAtLoad;

  @override
  void initState() {
    super.initState();
    _ownerAtLoad = _currentOwnerId();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = _currentOwnerId();
    if (owner != _ownerAtLoad) {
      _ownerAtLoad = owner;
      // Drop the previous account's rows immediately (no flash of the
      // previous teacher's data), then reload scoped to the new account.
      setState(() {
        _all = [];
        _pending = [];
        _loading = true;
      });
      _reload();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    // Owner at load start: if the account switches mid-load, the results
    // belong to the wrong teacher and must be discarded, not displayed.
    final loadOwner = _currentOwnerId();
    _ownerAtLoad = loadOwner;
    setState(() => _loading = true);
    try {
      final store = await _store();
      final items = await store.listDownloads();
      // Storage check: verify each local file still exists. Metadata alone
      // never counts as offline-available.
      for (final d in items) {
        // Flashcard sets without a stored file are rebuilt from their
        // saved payload on open/print — always available offline.
        if (d.localFilePath.startsWith(kRegeneratedFilePrefix) &&
            isRegenerableFlashcard(d.resourceType, d.contentJson)) {
          if (!d.offlineAvailable) {
            try {
              await store.setOfflineAvailable(d.resourceId, true);
            } catch (_) {}
          }
          continue;
        }
        List<int>? bytes;
        try {
          bytes = await readDownloadBytes(d);
        } catch (_) {
          bytes = null;
        }
        final exists = bytes != null && bytes.isNotEmpty;
        if (!exists && d.offlineAvailable) {
          try {
            await store.setOfflineAvailable(d.resourceId, false);
          } catch (_) {}
        } else if (exists && !d.offlineAvailable) {
          try {
            await store.setOfflineAvailable(d.resourceId, true);
          } catch (_) {}
        }
      }
      final verified = await store.listDownloads();
      final downloadedIds = verified.map((d) => d.resourceId).toSet();
      // Generated-but-not-downloaded worksheets (server completions from
      // online generation or Sync Now), scoped to the CURRENT teacher:
      // only owned saved-materials are candidates, minus this account's
      // own downloads. GENERATED + NOT DOWNLOADED => Ready to download;
      // GENERATED + DOWNLOADED => Downloaded (never both).
      final pending = <Map<String, dynamic>>[];
      try {
        if (getIt.isRegistered<AppDatabase>()) {
          final db = getIt<AppDatabase>();
          final ownerId = _currentOwnerId();
          await ensureAccountIsolation(db);
          final owned = await ownedEntityIds(
            db,
            entityType: 'saved_material',
            ownerId: ownerId,
          );
          final saved = await db.resourceDao.getOwnedSavedMaterials(
            type: 'worksheet',
            ownedIds: owned,
          );
          for (final row in saved) {
            if (downloadedIds.contains(row.id)) continue;
            try {
              final decoded = jsonDecode(row.contentJson);
              if (decoded is Map<String, dynamic>) {
                final questions = decoded['questions'];
                if (questions is List && questions.isNotEmpty) {
                  pending.add({
                    'content_id': row.id,
                    'payload': decoded,
                  });
                }
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
      // Account switched while loading (logout → login): discard stale
      // results instead of flashing the previous teacher's data.
      if (_currentOwnerId() != loadOwner) return;
      if (mounted) {
        setState(() {
          _all = verified;
          _pending = pending;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadPending(
      String contentId, Map<String, dynamic> payload) async {
    setState(() => _downloadingId = contentId);
    try {
      final store = await _store();
      RemoteContentDataSource? remote;
      try {
        remote = getIt<RemoteContentDataSource>();
      } catch (_) {
        remote = null;
      }
      await downloadWorksheet(
        store: store,
        remote: remote,
        contentId: contentId,
        contentPayload: payload,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Worksheet downloaded and ready for offline use.')),
        );
      }
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  List<WorksheetDownload> get _visible {
    final q = _search.trim().toLowerCase();
    final now = DateTime.now();
    return _all.where((d) {
      if (_classFilter != null && d.grade.toString() != _classFilter) {
        return false;
      }
      if (_sectionFilter != null && d.section != _sectionFilter) return false;
      if (_subjectFilter != null && d.subject != _subjectFilter) return false;
      if (_resourceTypeFilter != null && d.resourceType != _resourceTypeFilter) {
        return false;
      }
      if (_languageFilter != null &&
          d.language1 != _languageFilter &&
          d.language2 != _languageFilter) {
        return false;
      }
      if (_typeFilter != null && !d.worksheetTypes.contains(_typeFilter)) {
        return false;
      }
      if (_dateFilter == 'Today') {
        if (!_isSameDay(d.downloadedAt, now)) return false;
      } else if (_dateFilter == 'Last 7 days') {
        if (now.difference(d.downloadedAt).inDays > 7) return false;
      } else if (_dateFilter == 'Last 30 days') {
        if (now.difference(d.downloadedAt).inDays > 30) return false;
      }
      if (q.isNotEmpty) {
        // Search across title, topic, subject, class and language pair.
        final langNames =
            '${WorksheetLanguages.byCode(d.language1).displayName} ${WorksheetLanguages.byCode(d.language2).displayName} ${d.language1} ${d.language2}';
        final hay =
            '${d.title} ${d.topic} ${d.subject} Class ${d.grade} ${d.section} $langNames'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final classes = _all.map((d) => d.grade.toString()).toSet().toList()
      ..sort();
    final sections = _all.map((d) => d.section).toSet().toList()..sort();
    final subjects = _all.map((d) => d.subject).where((s) => s.isNotEmpty).toSet().toList()
      ..sort();
    final languages = {
      for (final d in _all) ...[d.language1, d.language2]
    }.toList()
      ..sort();
    final types = {for (final d in _all) ...d.worksheetTypes}.toList()..sort();
    final resourceTypes = _all.map((d) => d.resourceType).toSet().toList()..sort();

    return AppScaffold(
      title: 'Downloads',
      subtitle: 'Worksheets, flashcards and teaching materials saved on this device.',
      breadcrumb: 'Resources > Downloads',
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search downloads',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip('Class', classes, _classFilter,
                  (v) => setState(() => _classFilter = v)),
              _filterChip('Section', sections, _sectionFilter,
                  (v) => setState(() => _sectionFilter = v)),
              _filterChip('Subject', subjects, _subjectFilter,
                  (v) => setState(() => _subjectFilter = v)),
              _languageChip(languages),
              _filterChip('Resource', resourceTypes, _resourceTypeFilter,
                  (v) => setState(() => _resourceTypeFilter = v)),
              _filterChip('Type', types.map(_typeTitle).toList(), _typeFilter == null ? null : _typeTitle(_typeFilter!),
                  (label) {
                if (label == null) {
                  setState(() => _typeFilter = null);
                  return;
                }
                final code = types.firstWhere((c) => _typeTitle(c) == label,
                    orElse: () => label);
                setState(() => _typeFilter = code);
              }, codes: types),
              _dateChip(),
            ],
          ),
          const SizedBox(height: 14),
          if (!_loading && _pending.isNotEmpty) ...[
            Text('Ready to download',
                style:
                    AppTypography.sectionTitle.copyWith(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Generated worksheets that are not saved for offline use yet.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 8),
            ..._pending.map((p) {
              final contentId = p['content_id'].toString();
              final payload =
                  Map<String, dynamic>.from(p['payload'] as Map);
              final busy = _downloadingId == contentId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomCard(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.accentAmber
                                .withValues(alpha: 0.15),
                            borderRadius: AppRadius.radiusMd),
                        child: const Icon(Icons.cloud_done_rounded,
                            color: AppColors.accentAmber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                (payload['title'] ?? 'Worksheet')
                                    .toString(),
                                style: AppTypography.cardTitle
                                    .copyWith(fontSize: 14)),
                            Text(
                              'Class ${payload['grade'] ?? ''} • '
                              '${payload['subject'] ?? ''} • '
                              'Generated, not yet offline',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      SecondaryButton(
                        label: busy ? 'Saving...' : 'Download',
                        icon: Icons.download_rounded,
                        onPressed: busy
                            ? null
                            : () => _downloadPending(contentId, payload),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            Text('On this device',
                style:
                    AppTypography.sectionTitle.copyWith(fontSize: 15)),
            const SizedBox(height: 8),
          ],
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                        color: AppColors.primary)))
          else if (_visible.isEmpty)
            _emptyState()
          else
            ..._visible.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DownloadCard(
                    download: d,
                    onChanged: _reload,
                  ),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _filterChip(String label, List<String> options, String? selected,
      void Function(String?) onPick,
      {List<String>? codes}) {
    return PopupMenuButton<String?>(
      child: Chip(
        label: Text(selected ?? label),
        deleteIcon:
            selected != null ? const Icon(Icons.close_rounded, size: 14) : null,
        onDeleted: selected != null ? () => onPick(null) : null,
        backgroundColor:
            selected != null ? AppColors.greenSurface : Colors.white,
      ),
      onSelected: onPick,
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: null, child: Text('All')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
    );
  }

  Widget _languageChip(List<String> codes) {
    final selected = _languageFilter == null
        ? null
        : WorksheetLanguages.byCode(_languageFilter!).displayName;
    return PopupMenuButton<String?>(
      child: Chip(
        label: Text(selected ?? 'Language'),
        deleteIcon: selected != null
            ? const Icon(Icons.close_rounded, size: 14)
            : null,
        onDeleted: selected != null
            ? () => setState(() => _languageFilter = null)
            : null,
        backgroundColor:
            selected != null ? AppColors.greenSurface : Colors.white,
      ),
      onSelected: (v) => setState(() => _languageFilter = v),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: null, child: Text('All')),
        ...codes.map((c) => PopupMenuItem(
              value: c,
              child: Text(WorksheetLanguages.byCode(c).displayName),
            )),
      ],
    );
  }

  Widget _dateChip() {
    const options = ['All', 'Today', 'Last 7 days', 'Last 30 days'];
    return PopupMenuButton<String>(
      child: Chip(
        label: Text(_dateFilter == 'All' ? 'Date' : _dateFilter),
        backgroundColor:
            _dateFilter == 'All' ? Colors.white : AppColors.greenSurface,
      ),
      onSelected: (v) => setState(() => _dateFilter = v),
      itemBuilder: (ctx) =>
          options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
    );
  }

  Widget _emptyState() {
    return CustomCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.download_done_rounded,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text('No downloads yet', style: AppTypography.cardTitle),
          const SizedBox(height: 4),
          Text(
            'Downloaded worksheets, flashcards and teaching materials will appear here for offline classroom use.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          const SizedBox(height: 4),
          Text(
            'Download a worksheet or teaching resource to access it without internet.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Create a Worksheet',
            onPressed: () => context.push(AppRoutes.worksheetGenerator),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final WorksheetDownload download;
  final Future<void> Function() onChanged;

  const _DownloadCard({required this.download, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final d = download;
    final available = d.offlineAvailable;
    return CustomCard(
      width: double.infinity,
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusMd),
                child: Icon(
                    d.resourceType == 'flashcard'
                        ? Icons.style_rounded
                        : d.resourceType == 'activity'
                            ? Icons.sports_esports_outlined
                            : Icons.assignment_rounded,
                    color: AppColors.primary,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title.isNotEmpty ? d.title : d.topic,
                        style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Class ${d.grade} • Section ${d.section} • ${d.subject.isNotEmpty ? d.subject : d.resourceType}',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 2),
                    if (d.topic.isNotEmpty)
                      Text('Topic: ${d.topic}',
                          style: AppTypography.caption),
                    Text(
                      'Language: ${WorksheetLanguages.displayPair(d.language1, d.language2)}',
                      style: AppTypography.caption,
                    ),
                    if (d.worksheetTypes.isNotEmpty &&
                        d.resourceType != 'flashcard')
                      Text(
                        'Type: ${d.worksheetTypes.map(_typeTitle).join(' + ')}',
                        style: AppTypography.caption,
                      ),
                    if (d.questionCount > 0)
                      Text(
                          d.resourceType == 'flashcard'
                              ? 'Cards: ${d.questionCount}'
                              : 'Questions: ${d.questionCount}',
                          style: AppTypography.caption),
                    Text(
                      'Downloaded: ${_formatDateTime(d.downloadedAt)}',
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    if (available)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.greenSurface,
                            borderRadius: AppRadius.radiusPill),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.offline_pin_rounded,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Available Offline',
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.accentAmber
                                .withValues(alpha: 0.15),
                            borderRadius: AppRadius.radiusPill),
                        child: Text('File missing — Download again',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) => _action(context, v),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'open', child: Text('Open')),
                  PopupMenuItem(value: 'print', child: Text('Print')),
                  PopupMenuItem(value: 'share', child: Text('Share')),
                  PopupMenuItem(value: 'details', child: Text('View Details')),
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    try {
      final store = await _store();
      await store.markOpened(download.resourceId);
    } catch (_) {}
    if (context.mounted) {
      context.push('${AppRoutes.downloads}/${download.resourceId}/read');
    }
  }

  Future<void> _action(BuildContext context, String action) async {
    switch (action) {
      case 'open':
        await _open(context);
        break;
      case 'details':
        if (context.mounted) {
          context.push('${AppRoutes.downloads}/${download.resourceId}');
        }
        break;
      case 'print':
        await _print(context);
        break;
      case 'share':
        await _share(context);
        break;
      case 'rename':
        await _rename(context);
        break;
      case 'delete':
        await _delete(context);
        break;
    }
  }

  Future<List<int>?> _bytes(BuildContext context) async {
    final bytes = await readDownloadBytes(download);
    if (bytes == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'File is missing on this device. Please download it again.')),
      );
    }
    return bytes;
  }

  Future<void> _print(BuildContext context) async {
    final bytes = await _bytes(context);
    if (bytes == null || bytes.isEmpty) return;
    try {
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
        name: download.fileName,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Printing is not available on this device.')),
        );
      }
    }
  }

  Future<void> _share(BuildContext context) async {
    final bytes = await _bytes(context);
    if (bytes == null || bytes.isEmpty) return;
    try {
      if (kIsWeb) {
        await Share.shareXFiles([
          XFile.fromData(Uint8List.fromList(bytes),
              name: download.fileName, mimeType: 'application/pdf'),
        ], text: download.title);
      } else {
        await Share.shareXFiles([XFile(download.localFilePath)],
            text: download.title);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sharing is not available on this device.')),
        );
      }
    }
  }

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: download.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename download'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          maxLength: 80,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != download.title) {
      try {
        final store = await _store();
        await store.rename(download.resourceId, result);
        await onChanged();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rename failed. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete download?'),
        content: const Text(
            'This removes the offline file from this device only. '
            'The worksheet on the server is kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final store = await _store();
      await store.deleteDownload(download.resourceId);
      await onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Offline copy deleted. Server copy is kept.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed. Please try again.')),
        );
      }
    }
  }
}

// SCREEN: Download details — every field from actual metadata.
class DownloadDetailsScreen extends StatefulWidget {
  final String resourceId;
  const DownloadDetailsScreen({super.key, required this.resourceId});

  @override
  State<DownloadDetailsScreen> createState() => _DownloadDetailsScreenState();
}

class _DownloadDetailsScreenState extends State<DownloadDetailsScreen> {
  WorksheetDownload? _download;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = await _store();
      final d = await store.getByResourceId(widget.resourceId);
      if (mounted) setState(() {
        _download = d;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _download;
    return AppScaffold(
      title: 'Download Details',
      subtitle: d?.title ?? 'Offline worksheet details.',
      breadcrumb: 'Downloads > Details',
      isScrollable: true,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : d == null
              ? CustomCard(
                  child: Text('Download not found on this device.',
                      style: AppTypography.bodySmall))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Title', d.title),
                    _row('Resource type', d.resourceType),
                    _row('Class', d.grade > 0 ? 'Class ${d.grade}' : '—'),
                    _row('Section', d.section),
                    _row('Subject', d.subject.isNotEmpty ? d.subject : '—'),
                    _row('Topic', d.topic.isNotEmpty ? d.topic : '—'),
                    _row('Topic source', d.topicSource),
                    _row('Topic input language',
                        d.topicInputLanguage == 'hi' ? 'Hindi' : 'English'),
                    _row('NIPUN outcome', d.nipunOutcome ?? 'Custom topic'),
                    _row('Language 1',
                        WorksheetLanguages.byCode(d.language1).displayName),
                    _row('Language 2',
                        WorksheetLanguages.byCode(d.language2).displayName),
                    _row('Question count', '${d.questionCount}'),
                    _row('Worksheet types',
                        d.worksheetTypes.map(_typeTitle).join(', ')),
                    _row('Difficulty', d.difficulty),
                    _row('Generated',
                        d.generatedAt != null
                            ? _formatDateTime(d.generatedAt!)
                            : '—'),
                    _row('Downloaded', _formatDateTime(d.downloadedAt)),
                    _row('File format', d.format),
                    _row('File size', _formatBytes(d.fileSize)),
                    _row('Version', '${d.version}'),
                    _row('Offline status',
                        d.offlineAvailable ? 'Available Offline' : 'Missing file'),
                    _row('Local file', d.fileName),
                    if (d.lastOpenedAt != null)
                      _row('Last opened', _formatDateTime(d.lastOpenedAt!)),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Open Offline',
                      icon: Icons.offline_pin_rounded,
                      onPressed: () => context.push(
                          '${AppRoutes.downloads}/${d.resourceId}/read'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Proportional (not fixed-pixel) label column so the row fits
            // narrow phones; long unbreakable values (e.g. file names)
            // ellipsize instead of overflowing the Row on the right.
            Flexible(
                flex: 2,
                child: Text(label,
                    style: AppTypography.caption
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Expanded(
                flex: 5,
                child: Text(value,
                    style: AppTypography.bodySmall,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

// SCREEN: Offline worksheet reader — renders the LOCALLY stored worksheet.
// No FastAPI, no provider, no network calls of any kind.
class DownloadReaderScreen extends StatefulWidget {
  final String resourceId;
  const DownloadReaderScreen({super.key, required this.resourceId});

  @override
  State<DownloadReaderScreen> createState() => _DownloadReaderScreenState();
}

class _DownloadReaderScreenState extends State<DownloadReaderScreen> {
  final Future<WorksheetTemplate> _template = WorksheetTemplate.load();
  WorksheetDownload? _download;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = await _store();
      final d = await store.getByResourceId(widget.resourceId);
      if (d != null) {
        try {
          await store.markOpened(d.resourceId);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _download = d;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _download;
    final content = d?.contentJson;
    if (d != null && isRegenerableFlashcard(d.resourceType, content)) {
      return GeneratedFlashcardDeckScreen(
        payload: content,
        contentId: d.resourceId,
        openedFromDownloads: true,
      );
    }
    final questions = (content?['questions'] as List?) ?? [];
    return AppScaffold(
      title: d?.title ?? 'Worksheet',
      subtitle: d == null
          ? ''
          : 'Class ${d.grade} • Section ${d.section} • ${d.subject} • Available Offline',
      breadcrumb: 'Downloads > Open',
      isScrollable: true,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : d == null
              ? CustomCard(
                  child: Text(
                      'This download is not on this device. '
                      'Generate and download it again when online.',
                      style: AppTypography.bodySmall))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCard(
                      color: AppColors.greenSurface,
                      child: Row(
                        children: [
                          const Icon(Icons.offline_pin_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Opened from this device — no internet used.',
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (questions.isEmpty)
                      CustomCard(
                          child: Text(
                              'No question content stored for this download.',
                              style: AppTypography.bodySmall))
                    else
                      // Same template-driven worksheet as the Preview
                      // screen (Home / Teach > Worksheets).
                      FutureBuilder<WorksheetTemplate>(
                        future: _template,
                        builder: (context, snap) {
                          final template = snap.data;
                          if (snap.hasError) {
                            return CustomCard(
                                child: Text(
                                    'Worksheet layout could not be loaded.',
                                    style: AppTypography.bodySmall));
                          }
                          if (template == null) {
                            return const Center(
                                child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary)));
                          }
                          final document =
                              WorksheetDocument.fromPayload(content!, template);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: SecondaryButton(
                                  label: 'Print',
                                  icon: Icons.print_outlined,
                                  onPressed: () => showWorksheetPrintPreview(
                                    context,
                                    template: template,
                                    document: document,
                                    fileName: d.resourceId,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: AppRadius.radiusLg,
                                child: WorksheetTemplateView(
                                  template: template,
                                  document: document,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}
