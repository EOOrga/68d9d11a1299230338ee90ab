import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const String appName = 'ASS ANIMATION D YZEURE ET DU B';
const String companyName = 'ASS ANIMATION D YZEURE ET DU BOURBONNAIS';
const String supportEmail = 'support@ass-animation-yzeure.fr';

void main() {
  runApp(const AssOpsApp());
}

class AssOpsApp extends StatelessWidget {
  const AssOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF234A57);
    const secondary = Color(0xFFB86A3E);
    const surface = Color(0xFFF6F8F5);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: Colors.white,
          surface: surface,
          surfaceContainerHighest: const Color(0xFFE8EFE8),
          tertiary: const Color(0xFF2F7D6B),
          error: const Color(0xFFB3261E),
        );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: surface,
          foregroundColor: Color(0xFF12323D),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFD7E2DC)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD7E8DE),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const OperationsHome(),
    );
  }
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({super.key});

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  final OperationStore _store = OperationStore(screenshotMode: kScreenshotMode);
  int _index = 0;
  bool _loading = true;
  List<OperationRecord> _records = <OperationRecord>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _store.load();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  Future<void> _saveRecords(List<OperationRecord> records) async {
    setState(() => _records = records);
    await _store.save(records);
  }

  Future<void> _upsertRecord(OperationRecord record) async {
    final records = [..._records];
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.insert(0, record);
    } else {
      records[index] = record;
    }
    await _saveRecords(records);
  }

  Future<void> _deleteRecord(String id) async {
    await _saveRecords(_records.where((item) => item.id != id).toList());
  }

  void _openEditor({OperationRecord? record, OperationType? type}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestEditorPage(
          initial: record,
          initialType: type,
          onSave: _upsertRecord,
        ),
      ),
    );
  }

  void _openDetail(OperationRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailPage(
          record: record,
          onSave: _upsertRecord,
          onEdit: () => _openEditor(record: record),
          onDelete: () => _deleteRecord(record.id),
        ),
      ),
    );
  }

  String get _title {
    return switch (_index) {
      0 => 'Operations',
      1 => 'Requests',
      2 => 'Assets',
      3 => 'Bookings',
      _ => 'Settings',
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        records: _records,
        onCreate: () => _openEditor(),
        onOpen: _openDetail,
      ),
      RequestsScreen(
        records: _records,
        onCreate: () => _openEditor(),
        onOpen: _openDetail,
      ),
      AssetsScreen(
        records: _records,
        onCreateAsset: () => _openEditor(type: OperationType.asset),
        onOpen: _openDetail,
      ),
      BookingsScreen(
        records: _records,
        onCreateBooking: () => _openEditor(type: OperationType.appointment),
        onOpen: _openDetail,
      ),
      SettingsScreen(recordCount: _records.length),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Text(
              appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New record',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.records,
    required this.onCreate,
    required this.onOpen,
    super.key,
  });

  final List<OperationRecord> records;
  final VoidCallback onCreate;
  final ValueChanged<OperationRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final open = records
        .where((item) => item.status != WorkStatus.closed)
        .length;
    final incidents = records
        .where((item) => item.type == OperationType.incident)
        .length;
    final booked = records
        .where((item) => item.type == OperationType.appointment)
        .length;
    final assets = records
        .where((item) => item.type == OperationType.asset)
        .length;
    final urgent = records
        .where((item) => item.priority == Priority.high)
        .toList();
    final next = records.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Daily command center',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF12323D),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Coordinate resources, incidents, assets, and appointments from one local workspace.',
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 680 ? 4 : 2,
          childAspectRatio: 1.45,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricCard(
              label: 'Open work',
              value: '$open',
              icon: Icons.pending_actions,
            ),
            MetricCard(
              label: 'Incidents',
              value: '$incidents',
              icon: Icons.report_problem,
            ),
            MetricCard(
              label: 'Bookings',
              value: '$booked',
              icon: Icons.event_available,
            ),
            MetricCard(
              label: 'Assets',
              value: '$assets',
              icon: Icons.inventory_2,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ActionPanel(onCreate: onCreate),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Priority attention',
          actionLabel: urgent.isEmpty ? null : '${urgent.length} active',
        ),
        if (urgent.isEmpty)
          const EmptyPanel(
            icon: Icons.task_alt,
            title: 'No high priority items',
            body: 'New incidents or allocation issues will appear here.',
          )
        else
          ...urgent
              .take(3)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OperationCard(
                    record: record,
                    onTap: () => onOpen(record),
                  ),
                ),
              ),
        const SizedBox(height: 6),
        const SectionHeader(title: 'Recent activity'),
        ...next.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OperationCard(record: record, onTap: () => onOpen(record)),
          ),
        ),
      ],
    );
  }
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({
    required this.records,
    required this.onCreate,
    required this.onOpen,
    super.key,
  });

  final List<OperationRecord> records;
  final VoidCallback onCreate;
  final ValueChanged<OperationRecord> onOpen;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  OperationType? _type;

  @override
  Widget build(BuildContext context) {
    final records = _type == null
        ? widget.records
        : widget.records.where((item) => item.type == _type).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onCreate,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All work'),
                selected: _type == null,
                onSelected: (_) => setState(() => _type = null),
              ),
              for (final type in OperationType.values)
                FilterChip(
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const EmptyPanel(
              icon: Icons.assignment_outlined,
              title: 'No matching records',
              body:
                  'Create a request to track the next resource, incident, asset, or booking task.',
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OperationCard(
                  record: record,
                  onTap: () => widget.onOpen(record),
                ),
              ),
            ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({
    required this.records,
    required this.onCreateAsset,
    required this.onOpen,
    super.key,
  });

  final List<OperationRecord> records;
  final VoidCallback onCreateAsset;
  final ValueChanged<OperationRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final assetRecords = records
        .where((item) => item.type == OperationType.asset)
        .toList();
    final resources = records
        .where((item) => item.type == OperationType.resource)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'Asset board',
          actionLabel: '${assetRecords.length} tracked',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleIcon(icon: Icons.qr_code_scanner),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Track rooms, equipment, keys, and support resources without cloud sync.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onCreateAsset,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Add asset record'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Allocation status'),
        if (assetRecords.isEmpty && resources.isEmpty)
          const EmptyPanel(
            icon: Icons.inventory_2_outlined,
            title: 'No asset activity yet',
            body:
                'Asset checks and resource allocation records will appear here.',
          )
        else
          ...[...assetRecords, ...resources].map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OperationCard(record: record, onTap: () => onOpen(record)),
            ),
          ),
      ],
    );
  }
}

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({
    required this.records,
    required this.onCreateBooking,
    required this.onOpen,
    super.key,
  });

  final List<OperationRecord> records;
  final VoidCallback onCreateBooking;
  final ValueChanged<OperationRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final appointments =
        records.where((item) => item.type == OperationType.appointment).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleIcon(icon: Icons.event_available),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment booking',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Plan visits, room handovers, and operational checkpoints.',
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'New booking',
                  onPressed: onCreateBooking,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Upcoming'),
        if (appointments.isEmpty)
          const EmptyPanel(
            icon: Icons.event_busy,
            title: 'No bookings saved',
            body:
                'Create a booking to reserve time for teams, rooms, or equipment.',
          )
        else
          ...appointments.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OperationCard(record: record, onTap: () => onOpen(record)),
            ),
          ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.recordCount, super.key});

  final int recordCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('$recordCount local records stored on this device.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SettingsTile(
          icon: Icons.lock_outline,
          title: 'Privacy',
          body:
              'Records stay on the device. The app has no account system, analytics, ads, or cloud sync.',
        ),
        const SizedBox(height: 10),
        const SettingsTile(
          icon: Icons.wifi_off_outlined,
          title: 'Offline operation',
          body: 'All workflows work locally and do not call external services.',
        ),
        const SizedBox(height: 10),
        const SettingsTile(
          icon: Icons.mail_outline,
          title: 'Support',
          body: supportEmail,
        ),
      ],
    );
  }
}

class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({
    required this.record,
    required this.onSave,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final OperationRecord record;
  final ValueChanged<OperationRecord> onSave;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record detail'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OperationCard(record: record, onTap: () {}),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: record.location,
                  ),
                  DetailRow(
                    icon: Icons.person_outline,
                    label: 'Owner',
                    value: record.owner,
                  ),
                  DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Target date',
                    value: record.formattedDate,
                  ),
                  DetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Notes',
                    value: record.note,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Status actions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in WorkStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: record.status == status,
                  onSelected: (_) {
                    onSave(record.copyWith(status: status));
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete local record'),
          ),
        ],
      ),
    );
  }
}

class RequestEditorPage extends StatefulWidget {
  const RequestEditorPage({
    required this.onSave,
    this.initial,
    this.initialType,
    super.key,
  });

  final OperationRecord? initial;
  final OperationType? initialType;
  final ValueChanged<OperationRecord> onSave;

  @override
  State<RequestEditorPage> createState() => _RequestEditorPageState();
}

class _RequestEditorPageState extends State<RequestEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _owner;
  late final TextEditingController _note;
  late OperationType _type;
  late Priority _priority;
  late WorkStatus _status;
  late int _daysOut;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _location = TextEditingController(text: initial?.location ?? '');
    _owner = TextEditingController(text: initial?.owner ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _type = initial?.type ?? widget.initialType ?? OperationType.resource;
    _priority = initial?.priority ?? Priority.medium;
    _status = initial?.status ?? WorkStatus.planned;
    _daysOut = initial == null
        ? 1
        : initial.dueDate
              .difference(DateTime.now())
              .inDays
              .clamp(0, 30)
              .toInt();
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _owner.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final initial = widget.initial;
    final record = OperationRecord(
      id: initial?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      type: _type,
      priority: _priority,
      status: _status,
      location: _location.text.trim(),
      owner: _owner.text.trim(),
      note: _note.text.trim(),
      dueDate: DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: _daysOut)),
      createdAt: initial?.createdAt ?? now,
    );
    widget.onSave(record);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'New record' : 'Edit record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const ValueKey('titleField'),
              controller: _title,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Enter a useful title';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<OperationType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Workflow',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: OperationType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: Priority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _priority = value ?? _priority),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WorkStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.timeline_outlined),
              ),
              items: WorkStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _daysOut,
              decoration: const InputDecoration(
                labelText: 'Target date',
                prefixIcon: Icon(Icons.today_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Today')),
                DropdownMenuItem(value: 1, child: Text('Tomorrow')),
                DropdownMenuItem(value: 3, child: Text('In 3 days')),
                DropdownMenuItem(value: 7, child: Text('Next week')),
                DropdownMenuItem(value: 14, child: Text('In 2 weeks')),
                DropdownMenuItem(value: 30, child: Text('In 30 days')),
              ],
              onChanged: (value) =>
                  setState(() => _daysOut = value ?? _daysOut),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Location or resource',
                prefixIcon: Icon(Icons.place_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Add a location or resource';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _owner,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Responsible team',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Add a team or owner';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Operational notes',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'Add a short note';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('saveRecordButton'),
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save local record'),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  const ActionPanel({required this.onCreate, super.key});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleIcon(icon: Icons.add_task),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start a work record',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Allocate resources, report an incident, check an asset, or book a time slot.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create record'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF12323D),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class OperationCard extends StatelessWidget {
  const OperationCard({required this.record, required this.onTap, super.key});

  final OperationRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleIcon(icon: record.type.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.type.label} in ${record.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label: record.status.label,
                    color: record.status.color,
                  ),
                  StatusPill(
                    label: record.priority.label,
                    color: record.priority.color,
                  ),
                  StatusPill(
                    label: record.formattedDate,
                    color: const Color(0xFF2F7D6B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.actionLabel, super.key});

  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          if (actionLabel != null)
            Text(
              actionLabel!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleIcon(icon: icon),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleIcon extends StatelessWidget {
  const CircleIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OperationStore {
  OperationStore({required this.screenshotMode});

  final bool screenshotMode;
  static const _key = 'operation_records_v1';

  Future<List<OperationRecord>> load() async {
    if (screenshotMode) return OperationRecord.samples();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return OperationRecord.starterRecords();
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => OperationRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<OperationRecord> records) async {
    if (screenshotMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }
}

class OperationRecord {
  const OperationRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.status,
    required this.location,
    required this.owner,
    required this.note,
    required this.dueDate,
    required this.createdAt,
  });

  final String id;
  final String title;
  final OperationType type;
  final Priority priority;
  final WorkStatus status;
  final String location;
  final String owner;
  final String note;
  final DateTime dueDate;
  final DateTime createdAt;

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dueDate.month - 1]} ${dueDate.day}';
  }

  OperationRecord copyWith({
    String? id,
    String? title,
    OperationType? type,
    Priority? priority,
    WorkStatus? status,
    String? location,
    String? owner,
    String? note,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return OperationRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      location: location ?? this.location,
      owner: owner ?? this.owner,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'location': location,
      'owner': owner,
      'note': note,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OperationRecord.fromJson(Map<String, dynamic> json) {
    return OperationRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      type: OperationType.values.byName(json['type'] as String),
      priority: Priority.values.byName(json['priority'] as String),
      status: WorkStatus.values.byName(json['status'] as String),
      location: json['location'] as String,
      owner: json['owner'] as String,
      note: json['note'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<OperationRecord> starterRecords() {
    final today = DateTime.now();
    return [
      OperationRecord(
        id: 'starter-resource',
        title: 'Prepare multipurpose room allocation',
        type: OperationType.resource,
        priority: Priority.medium,
        status: WorkStatus.planned,
        location: 'Maison des associations',
        owner: 'Operations team',
        note:
            'Confirm tables, access badges, and setup window before the appointment.',
        dueDate: DateTime(
          today.year,
          today.month,
          today.day,
        ).add(const Duration(days: 1)),
        createdAt: today,
      ),
    ];
  }

  static List<OperationRecord> samples() {
    final base = DateTime(2026, 5, 12);
    return [
      OperationRecord(
        id: 'sample-incident',
        title: 'Resolve hall lighting incident',
        type: OperationType.incident,
        priority: Priority.high,
        status: WorkStatus.active,
        location: 'Salle Bourbonnais',
        owner: 'Maintenance',
        note:
            'Two fixtures are unstable before evening access. Assign technician and confirm closure.',
        dueDate: base,
        createdAt: base.subtract(const Duration(days: 1)),
      ),
      OperationRecord(
        id: 'sample-resource',
        title: 'Allocate chairs for workshop',
        type: OperationType.resource,
        priority: Priority.medium,
        status: WorkStatus.planned,
        location: 'Storage A',
        owner: 'Reception',
        note:
            'Reserve 36 chairs and one mobile screen for the afternoon workshop.',
        dueDate: base.add(const Duration(days: 1)),
        createdAt: base.subtract(const Duration(days: 2)),
      ),
      OperationRecord(
        id: 'sample-asset',
        title: 'Check projector return',
        type: OperationType.asset,
        priority: Priority.low,
        status: WorkStatus.active,
        location: 'Equipment desk',
        owner: 'Logistics',
        note:
            'Verify cable kit, remote control, and case condition before closing inventory.',
        dueDate: base.add(const Duration(days: 2)),
        createdAt: base.subtract(const Duration(days: 3)),
      ),
      OperationRecord(
        id: 'sample-appointment',
        title: 'Book access handover',
        type: OperationType.appointment,
        priority: Priority.high,
        status: WorkStatus.planned,
        location: 'Front office',
        owner: 'Administration',
        note:
            'Prepare keys, site rules, and room checklist for the association coordinator.',
        dueDate: base.add(const Duration(days: 3)),
        createdAt: base.subtract(const Duration(days: 1)),
      ),
      OperationRecord(
        id: 'sample-closed',
        title: 'Archive weekly supply request',
        type: OperationType.resource,
        priority: Priority.low,
        status: WorkStatus.closed,
        location: 'Office',
        owner: 'Admin',
        note: 'Paper stock and badge sleeves were counted and logged locally.',
        dueDate: base.subtract(const Duration(days: 1)),
        createdAt: base.subtract(const Duration(days: 5)),
      ),
    ];
  }
}

enum OperationType {
  resource,
  incident,
  asset,
  appointment;

  String get label {
    return switch (this) {
      OperationType.resource => 'Resources',
      OperationType.incident => 'Incidents',
      OperationType.asset => 'Assets',
      OperationType.appointment => 'Appointments',
    };
  }

  IconData get icon {
    return switch (this) {
      OperationType.resource => Icons.groups_2_outlined,
      OperationType.incident => Icons.report_problem_outlined,
      OperationType.asset => Icons.inventory_2_outlined,
      OperationType.appointment => Icons.event_available_outlined,
    };
  }
}

enum Priority {
  low,
  medium,
  high;

  String get label {
    return switch (this) {
      Priority.low => 'Low',
      Priority.medium => 'Medium',
      Priority.high => 'High',
    };
  }

  Color get color {
    return switch (this) {
      Priority.low => const Color(0xFF2F7D6B),
      Priority.medium => const Color(0xFF8A6A20),
      Priority.high => const Color(0xFFB3261E),
    };
  }
}

enum WorkStatus {
  planned,
  active,
  waiting,
  closed;

  String get label {
    return switch (this) {
      WorkStatus.planned => 'Planned',
      WorkStatus.active => 'Active',
      WorkStatus.waiting => 'Waiting',
      WorkStatus.closed => 'Closed',
    };
  }

  Color get color {
    return switch (this) {
      WorkStatus.planned => const Color(0xFF234A57),
      WorkStatus.active => const Color(0xFFB86A3E),
      WorkStatus.waiting => const Color(0xFF6D5E99),
      WorkStatus.closed => const Color(0xFF2F7D6B),
    };
  }
}
