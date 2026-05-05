import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ==========================================
// 1. CORE SERVICES & INITIALIZATION
// ==========================================
const Uuid uuid = Uuid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlannerState()..initializeSystem()),
      ],
      child: const ProPlannerApp(),
    ),
  );
}

// ==========================================
// 2. THEME & BRUTALIST UI COMPONENTS
// ==========================================
class BrutalistColors {
  static const Color paperBg = Color(0xFFE5DDF0);
  static const Color inkBlack = Color(0xFF1E1E1E);
  static const Color brassAccent = Color(0xFFB58840);
  static const Color rustRed = Color(0xFF9E3C27);
  static const Color steamGreen = Color(0xFF385E38);
  static const Color neutralGray = Color(0xFF9E9E9E);
}

final ThemeData brutalistTheme = ThemeData(
  fontFamily: 'Courier',
  scaffoldBackgroundColor: BrutalistColors.paperBg,
  colorScheme: const ColorScheme.light(
    primary: BrutalistColors.inkBlack,
    secondary: BrutalistColors.brassAccent,
    surface: BrutalistColors.paperBg,
    error: BrutalistColors.rustRed,
    onPrimary: BrutalistColors.paperBg,
    onSecondary: BrutalistColors.inkBlack,
    onSurface: BrutalistColors.inkBlack,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: BrutalistColors.paperBg,
    foregroundColor: BrutalistColors.inkBlack,
    elevation: 0,
    centerTitle: true,
    shape: Border(bottom: BorderSide(color: BrutalistColors.inkBlack, width: 4)),
    iconTheme: IconThemeData(color: BrutalistColors.inkBlack, size: 28),
    titleTextStyle: TextStyle(color: BrutalistColors.inkBlack, fontFamily: 'Courier', fontSize: 20, fontWeight: FontWeight.bold),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: BrutalistColors.inkBlack, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: BrutalistColors.inkBlack),
    titleLarge: TextStyle(color: BrutalistColors.inkBlack, fontWeight: FontWeight.w900, fontSize: 24),
  ),
  dividerTheme: const DividerThemeData(color: BrutalistColors.inkBlack, thickness: 3),
);

// Custom Brutalist Container
class BrutalistBox extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const BrutalistBox({super.key, required this.child, this.backgroundColor, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? BrutalistColors.paperBg,
        border: Border.all(color: BrutalistColors.inkBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: BrutalistColors.inkBlack, offset: Offset(4, 4), blurRadius: 0)
        ],
      ),
      child: child,
    );
  }
}

// Custom Brutalist Button
class BrutalistButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? colorOverride;
  final IconData? icon;

  const BrutalistButton({super.key, required this.label, required this.onPressed, this.isPrimary = true, this.colorOverride, this.icon});

  @override
  Widget build(BuildContext context) {
    final bgColor = colorOverride ?? (isPrimary ? BrutalistColors.inkBlack : BrutalistColors.paperBg);
    final fgColor = isPrimary && colorOverride == null ? BrutalistColors.paperBg : BrutalistColors.inkBlack;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: BrutalistColors.inkBlack, width: 3),
          boxShadow: isPrimary ? const [BoxShadow(color: BrutalistColors.inkBlack, offset: Offset(4, 4))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: fgColor), const SizedBox(width: 8)],
            Text(label.toUpperCase(), style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// Custom Brutalist TextField
class BrutalistTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int maxLines;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;

  const BrutalistTextField({super.key, required this.controller, required this.labelText, this.hintText, this.maxLines = 1, this.keyboardType = TextInputType.text, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: labelText.toUpperCase(),
        hintText: hintText,
        labelStyle: const TextStyle(color: BrutalistColors.inkBlack, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: BrutalistColors.paperBg,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.inkBlack, width: 3)),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.inkBlack, width: 3)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.brassAccent, width: 4)),
      ),
    );
  }
}

// ==========================================
// 3. DATA MODELS
// ==========================================
class Goal {
  String id;
  String text;
  bool isFinished;

  Goal({required this.id, required this.text, this.isFinished = false});

  Goal copyWith({String? id, String? text, bool? isFinished}) {
    return Goal(id: id ?? this.id, text: text ?? this.text, isFinished: isFinished ?? this.isFinished);
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'isFinished': isFinished};
  factory Goal.fromJson(Map<String, dynamic> json) => Goal(id: json['id'], text: json['text'], isFinished: json['isFinished']);
}

class Remark {
  String id;
  String text;
  String relativeTime;
  int timestamp;
  String category; 

  Remark({required this.id, required this.text, required this.relativeTime, required this.timestamp, this.category = 'GENERAL'});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'relativeTime': relativeTime, 'timestamp': timestamp, 'category': category};
  factory Remark.fromJson(Map<String, dynamic> json) => Remark(id: json['id'], text: json['text'], relativeTime: json['relativeTime'], timestamp: json['timestamp'], category: json['category'] ?? 'GENERAL');
}

class SessionPreset {
  String id;
  String name;
  String description;
  String subject;
  String type;
  List<String> goalTemplates;

  SessionPreset({required this.id, required this.name, required this.description, required this.subject, required this.type, required this.goalTemplates});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'subject': subject, 'type': type, 'goalTemplates': goalTemplates};
  factory SessionPreset.fromJson(Map<String, dynamic> json) => SessionPreset(id: json['id'], name: json['name'], description: json['description'], subject: json['subject'], type: json['type'], goalTemplates: List<String>.from(json['goalTemplates']));
}

class StudySession {
  String id;
  String name;
  String description;
  String subject;
  String type;
  int scheduledDate; 
  int expectedDurationMins;
  int actualDurationSecs;
  bool isCompleted;
  List<Goal> goals;
  List<Remark> remarks;

  StudySession({required this.id, required this.name, required this.description, required this.subject, required this.type, required this.scheduledDate, required this.expectedDurationMins, this.actualDurationSecs = 0, this.isCompleted = false, required this.goals, required this.remarks});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'subject': subject, 'type': type,
    'scheduledDate': scheduledDate, 'expectedDurationMins': expectedDurationMins,
    'actualDurationSecs': actualDurationSecs, 'isCompleted': isCompleted,
    'goals': goals.map((g) => g.toJson()).toList(), 'remarks': remarks.map((r) => r.toJson()).toList()
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'], name: json['name'], description: json['description'], subject: json['subject'], type: json['type'],
    scheduledDate: json['scheduledDate'], expectedDurationMins: json['expectedDurationMins'],
    actualDurationSecs: json['actualDurationSecs'], isCompleted: json['isCompleted'],
    goals: (json['goals'] as List).map((g) => Goal.fromJson(g)).toList(),
    remarks: (json['remarks'] as List).map((r) => Remark.fromJson(r)).toList()
  );
}

class PlanBlock {
  String id;
  String name;
  List<Goal> goals;
  List<Remark> remarks;

  PlanBlock({required this.id, this.name = '', required this.goals, required this.remarks});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'goals': goals.map((g) => g.toJson()).toList(), 'remarks': remarks.map((r) => r.toJson()).toList()};
  factory PlanBlock.fromJson(Map<String, dynamic> json) => PlanBlock(id: json['id'], name: json['name'], goals: (json['goals'] as List).map((g) => Goal.fromJson(g)).toList(), remarks: (json['remarks'] as List).map((r) => Remark.fromJson(r)).toList());
}

class AppUser {
  String id;
  String name;
  List<String> subjects;
  List<String> customTypes;

  AppUser({required this.id, required this.name, required this.subjects, required this.customTypes});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'subjects': subjects, 'customTypes': customTypes};
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(id: json['id'], name: json['name'], subjects: List<String>.from(json['subjects']), customTypes: List<String>.from(json['customTypes'] ?? []));
}

// ==========================================
// 4. STATE MANAGEMENT (PROVIDER)
// ==========================================
class PlannerState extends ChangeNotifier {
  List<AppUser> users = [];
  AppUser? currentUser;
  
  List<StudySession> sessions = [];
  List<SessionPreset> presets = [];
  Map<String, PlanBlock> dayPlans = {};
  Map<String, PlanBlock> weekPlans = {};
  
  bool isLoading = true;

  final List<String> defaultSubjects = ['MATHEMATICS', 'PHYSICS', 'CHEMISTRY', 'BIOLOGY'];
  final List<String> defaultSessionTypes = ['NORMAL', 'IMPORTANT', 'INTENSE'];

  List<String> get activeSubjects => currentUser?.subjects ?? defaultSubjects;
  List<String> get activeTypes => [...defaultSessionTypes, ...(currentUser?.customTypes ?? [])];

  Future<void> initializeSystem() async {
    final prefs = await SharedPreferences.getInstance();
    
    final usersJson = prefs.getString('sys_users_v2');
    if (usersJson != null) {
      try {
        users = (jsonDecode(usersJson) as List).map((u) => AppUser.fromJson(u)).toList();
      } catch (e) {
        debugPrint('Error parsing users: $e');
      }
    }
    
    if (users.isEmpty) {
      users.add(AppUser(id: uuid.v4(), name: 'OPERATOR_PRIMARY', subjects: defaultSubjects, customTypes: []));
    }
    
    await prefs.setString('sys_users_v2', jsonEncode(users.map((u) => u.toJson()).toList()));
    
    final lastUserId = prefs.getString('last_active_user') ?? users.first.id;
    currentUser = users.firstWhere((u) => u.id == lastUserId, orElse: () => users.first);
    
    await loadUserData();
  }

  Future<void> loadUserData() async {
    isLoading = true;
    notifyListeners();
    
    if (currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final uid = currentUser!.id;
    
    try {
      sessions = (jsonDecode(prefs.getString('data_sessions_$uid') ?? '[]') as List).map((s) => StudySession.fromJson(s)).toList();
      presets = (jsonDecode(prefs.getString('data_presets_$uid') ?? '[]') as List).map((p) => SessionPreset.fromJson(p)).toList();
      
      Map<String, dynamic> dMap = jsonDecode(prefs.getString('data_days_$uid') ?? '{}');
      dayPlans = dMap.map((k, v) => MapEntry(k, PlanBlock.fromJson(v)));
      
      Map<String, dynamic> wMap = jsonDecode(prefs.getString('data_weeks_$uid') ?? '{}');
      weekPlans = wMap.map((k, v) => MapEntry(k, PlanBlock.fromJson(v)));
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserData() async {
    if (currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final uid = currentUser!.id;
    
    await prefs.setString('sys_users_v2', jsonEncode(users.map((u) => u.toJson()).toList()));
    await prefs.setString('data_sessions_$uid', jsonEncode(sessions.map((s) => s.toJson()).toList()));
    await prefs.setString('data_presets_$uid', jsonEncode(presets.map((p) => p.toJson()).toList()));
    await prefs.setString('data_days_$uid', jsonEncode(dayPlans.map((k, v) => MapEntry(k, v.toJson()))));
    await prefs.setString('data_weeks_$uid', jsonEncode(weekPlans.map((k, v) => MapEntry(k, v.toJson()))));
    
    notifyListeners();
  }

  // --- User Management ---
  void switchUser(String id) {
    currentUser = users.firstWhere((u) => u.id == id);
    SharedPreferences.getInstance().then((p) => p.setString('last_active_user', id));
    loadUserData();
  }

  void createNewUser(String name) {
    users.add(AppUser(id: uuid.v4(), name: name, subjects: defaultSubjects, customTypes: []));
    saveUserData();
  }

  void addCustomSubject(String subject) {
    if (!currentUser!.subjects.contains(subject.toUpperCase())) {
      currentUser!.subjects.add(subject.toUpperCase());
      saveUserData();
    }
  }

  void addCustomType(String type) {
    if (!currentUser!.customTypes.contains(type.toUpperCase())) {
      currentUser!.customTypes.add(type.toUpperCase());
      saveUserData();
    }
  }

  // --- Session CRUD ---
  void saveSession(StudySession session) {
    int index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    saveUserData();
  }

  void deleteSession(String id) {
    sessions.removeWhere((s) => s.id == id);
    saveUserData();
  }

  // --- Block CRUD (Days/Weeks) ---
  PlanBlock getDayPlan(String dateKey) {
    dayPlans.putIfAbsent(dateKey, () => PlanBlock(id: dateKey, goals: [], remarks: []));
    return dayPlans[dateKey]!;
  }

  void saveDayPlan(PlanBlock block) {
    dayPlans[block.id] = block;
    saveUserData();
  }

  PlanBlock getWeekPlan(String weekKey) {
    weekPlans.putIfAbsent(weekKey, () => PlanBlock(id: weekKey, goals: [], remarks: []));
    return weekPlans[weekKey]!;
  }

  void saveWeekPlan(PlanBlock block) {
    weekPlans[block.id] = block;
    saveUserData();
  }

  // --- Presets ---
  void savePreset(SessionPreset preset) {
    presets.add(preset);
    saveUserData();
  }

  void deletePreset(String id) {
    presets.removeWhere((p) => p.id == id);
    saveUserData();
  }

  // --- Aggregation & Stats ---
  List<StudySession> getSessionsForDate(String dateKey) {
    return sessions.where((s) {
      final sd = DateTime.fromMillisecondsSinceEpoch(s.scheduledDate);
      return DateFormat('yyyy-MM-dd').format(sd) == dateKey;
    }).toList();
  }

  Map<String, dynamic> getStatsForDateRange(DateTime start, DateTime end) {
    final filtered = sessions.where((s) {
      final sd = DateTime.fromMillisecondsSinceEpoch(s.scheduledDate);
      return sd.isAfter(start.subtract(const Duration(days: 1))) && sd.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    int totalSecs = 0;
    int totalGoals = 0;
    int finishedGoals = 0;
    Map<String, int> subjectTime = {};

    for (var s in filtered) {
      if (s.isCompleted) totalSecs += s.actualDurationSecs;
      totalGoals += s.goals.length;
      finishedGoals += s.goals.where((g) => g.isFinished).length;
      
      if (s.isCompleted) {
        subjectTime[s.subject] = (subjectTime[s.subject] ?? 0) + s.actualDurationSecs;
      }
    }

    return {
      'totalSessions': filtered.length,
      'completedSessions': filtered.where((s) => s.isCompleted).length,
      'totalHours': totalSecs / 3600,
      'goalCompletionRate': totalGoals == 0 ? 0.0 : (finishedGoals / totalGoals) * 100,
      'subjectBreakdown': subjectTime,
    };
  }
}

// ==========================================
// 5. MAIN NAVIGATION SCAFFOLD
// ==========================================
class ProPlannerApp extends StatelessWidget {
  const ProPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRO PLANNER CORE',
      debugShowCheckedModeBanner: false,
      theme: brutalistTheme,
      home: const MainNavigationHandler(),
    );
  }
}

class MainNavigationHandler extends StatefulWidget {
  const MainNavigationHandler({super.key});

  @override
  State<MainNavigationHandler> createState() => _MainNavigationHandlerState();
}

class _MainNavigationHandlerState extends State<MainNavigationHandler> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    DailyScheduleView(),
    WeeklyOverviewScreen(),
    PresetsManagementView(),
    DataExportAnalyticsView(),
    UserProfileSettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: BrutalistColors.inkBlack, strokeWidth: 4),
              SizedBox(height: 24),
              Text('INITIALIZING SYSTEMS...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _views,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: BrutalistColors.inkBlack, width: 4)),
        ),
        child: NavigationBar(
          backgroundColor: BrutalistColors.paperBg,
          indicatorColor: BrutalistColors.brassAccent.withOpacity(0.5),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.today), label: 'DAY'),
            NavigationDestination(icon: Icon(Icons.calendar_view_week), label: 'WEEK'),
            NavigationDestination(icon: Icon(Icons.bookmark_added), label: 'PRESETS'),
            NavigationDestination(icon: Icon(Icons.data_exploration), label: 'STATS'),
            NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'SYS'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. DAILY SCHEDULE VIEW
// ==========================================
class DailyScheduleView extends StatefulWidget {
  const DailyScheduleView({super.key});

  @override
  State<DailyScheduleView> createState() => _DailyScheduleViewState();
}

class _DailyScheduleViewState extends State<DailyScheduleView> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      builder: (context, child) => Theme(data: brutalistTheme, child: child!),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final dayPlan = state.getDayPlan(_dateKey);
    final sessions = state.getSessionsForDate(_dateKey);

    return Scaffold(
      appBar: AppBar(
        title: Text('LOG: $_dateKey'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_calendar), onPressed: () => _selectDate(context)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrutalistColors.inkBlack,
        foregroundColor: BrutalistColors.paperBg,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionConfigurationScreen(initialDate: _selectedDate))),
        icon: const Icon(Icons.add),
        label: const Text('NEW SESSION', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistColors.inkBlack, width: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: BrutalistButton(
                    label: 'EDIT DAY PLAN',
                    icon: Icons.assignment,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanEditorScreen(block: dayPlan, typeLabel: 'DAY', onSave: () => state.saveDayPlan(dayPlan)))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            BrutalistBox(
              backgroundColor: BrutalistColors.brassAccent.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAY SUMMARY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('TOTAL SESSIONS: ${sessions.length}'),
                  Text('COMPLETED: ${sessions.where((s) => s.isCompleted).length}'),
                  Text('UNFULFILLED GOALS: ${dayPlan.goals.where((g) => !g.isFinished).length} (OVERALL)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('TIMELINE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Divider(),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('NO SESSIONS SCHEDULED. INITIATE ADDITION.', style: TextStyle(fontWeight: FontWeight.bold, color: BrutalistColors.neutralGray))),
              )
            else
              ...sessions.map((session) => _buildSessionCard(context, session)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, StudySession session) {
    final bool isFinished = session.isCompleted;
    final bool isIntense = session.type == 'INTENSE';
    
    final Color bgColor = isFinished ? BrutalistColors.steamGreen.withOpacity(0.2) : (isIntense ? BrutalistColors.rustRed.withOpacity(0.1) : BrutalistColors.paperBg);

    return BrutalistBox(
      backgroundColor: bgColor,
      padding: const EdgeInsets.all(0),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionConfigurationScreen(session: session, initialDate: _selectedDate))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BrutalistColors.inkBlack, width: 2))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(session.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  Text(DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(session.scheduledDate)), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SUBJ: ${session.subject}'),
                        Text('TYPE: ${session.type}'),
                        Text('EST: ${session.expectedDurationMins} MIN | ACT: ${session.actualDurationSecs ~/ 60} MIN'),
                        const SizedBox(height: 8),
                        Text('GOALS: ${session.goals.where((g) => g.isFinished).length}/${session.goals.length} COMPLETED', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (isFinished)
                    const Icon(Icons.verified, color: BrutalistColors.steamGreen, size: 48)
                  else
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, size: 48, color: BrutalistColors.inkBlack),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTimerScreen(session: session))),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. WEEKLY OVERVIEW SCREEN
// ==========================================
class WeeklyOverviewScreen extends StatefulWidget {
  const WeeklyOverviewScreen({super.key});

  @override
  State<WeeklyOverviewScreen> createState() => _WeeklyOverviewScreenState();
}

class _WeeklyOverviewScreenState extends State<WeeklyOverviewScreen> {
  DateTime _referenceDate = DateTime.now();

  String get _weekKey {
    int dayOfYear = int.parse(DateFormat('D').format(_referenceDate));
    int weekNum = ((dayOfYear - _referenceDate.weekday + 10) / 7).floor();
    return '${_referenceDate.year}-W$weekNum';
  }

  void _shiftWeek(int days) {
    setState(() {
      _referenceDate = _referenceDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final weekPlan = state.getWeekPlan(_weekKey);

    DateTime startOfWeek = _referenceDate.subtract(Duration(days: _referenceDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    final stats = state.getStatsForDateRange(startOfWeek, endOfWeek);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WEEKLY BATCH'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => _shiftWeek(-7)),
                Text(_weekKey, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => _shiftWeek(7)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            
            BrutalistButton(
              label: 'CONFIGURE WEEK PLAN',
              icon: Icons.account_tree,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanEditorScreen(block: weekPlan, typeLabel: 'WEEK', onSave: () => state.saveWeekPlan(weekPlan)))),
            ),
            const SizedBox(height: 24),

            BrutalistBox(
              backgroundColor: BrutalistColors.steamGreen.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WEEKLY PERFORMANCE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('TOTAL SESSIONS LOGGED: ${stats['totalSessions']}'),
                  Text('SUCCESSFULLY COMPLETED: ${stats['completedSessions']}'),
                  Text('HOURS INVESTED: ${(stats['totalHours'] as double).toStringAsFixed(2)} HRS'),
                  Text('GOAL COMPLETION RATE: ${(stats['goalCompletionRate'] as double).toStringAsFixed(1)}%'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('DAYS OVERVIEW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...List.generate(7, (index) {
              DateTime day = startOfWeek.add(Duration(days: index));
              String dayKey = DateFormat('yyyy-MM-dd').format(day);
              List<StudySession> daySessions = state.getSessionsForDate(dayKey);
              
              return BrutalistBox(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('EEEE, MMM dd').format(day).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${daySessions.length} SESSIONS', style: const TextStyle(color: BrutalistColors.rustRed, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. PLAN EDITOR (For Days and Weeks)
// ==========================================
class PlanEditorScreen extends StatefulWidget {
  final PlanBlock block;
  final String typeLabel;
  final VoidCallback onSave;

  const PlanEditorScreen({super.key, required this.block, required this.typeLabel, required this.onSave});

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.block.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _addGoal() {
    if (_goalCtrl.text.trim().isNotEmpty) {
      setState(() {
        widget.block.goals.add(Goal(id: uuid.v4(), text: _goalCtrl.text.trim()));
        _goalCtrl.clear();
      });
      widget.onSave();
    }
  }

  void _addRemark() {
    if (_remarkCtrl.text.trim().isNotEmpty) {
      setState(() {
        widget.block.remarks.add(Remark(
          id: uuid.v4(),
          text: _remarkCtrl.text.trim(),
          relativeTime: 'PLAN_LOG',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
        _remarkCtrl.clear();
      });
      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EDIT ${widget.typeLabel} ARCHITECTURE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrutalistTextField(
              controller: _nameCtrl,
              labelText: 'CUSTOM DESIGNATION (OPTIONAL)',
              onChanged: (val) {
                widget.block.name = val;
                widget.onSave();
              },
            ),
            const SizedBox(height: 32),
            
            const Text('OVERALL GOALS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...widget.block.goals.map((g) => CheckboxListTile(
              title: Text(g.text, style: TextStyle(decoration: g.isFinished ? TextDecoration.lineThrough : null)),
              value: g.isFinished,
              activeColor: BrutalistColors.steamGreen,
              checkColor: BrutalistColors.paperBg,
              onChanged: (val) {
                setState(() => g.isFinished = val!);
                widget.onSave();
              },
              secondary: IconButton(icon: const Icon(Icons.delete), onPressed: () {
                setState(() => widget.block.goals.remove(g));
                widget.onSave();
              }),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: _goalCtrl, labelText: 'NEW GOAL', hintText: 'Enter specific measurable target')),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.add_box, size: 48), onPressed: _addGoal),
              ],
            ),
            const SizedBox(height: 48),

            const Text('PLAN REMARKS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...widget.block.remarks.map((r) => BrutalistBox(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.text, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(r.timestamp)), style: const TextStyle(fontSize: 10, color: BrutalistColors.neutralGray)),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: _remarkCtrl, labelText: 'NEW REMARK', maxLines: 2)),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.comment, size: 48), onPressed: _addRemark),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 9. SESSION CONFIGURATION SCREEN
// ==========================================
class SessionConfigurationScreen extends StatefulWidget {
  final StudySession? session;
  final DateTime initialDate;
  final SessionPreset? templatePreset;

  const SessionConfigurationScreen({super.key, this.session, required this.initialDate, this.templatePreset});

  @override
  State<SessionConfigurationScreen> createState() => _SessionConfigurationScreenState();
}

class _SessionConfigurationScreenState extends State<SessionConfigurationScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  
  late String _selectedSubject;
  late String _selectedType;
  late DateTime _scheduledTime;
  List<Goal> _goals = [];
  List<Remark> _remarks = [];
  bool _isCompleted = false;
  int _actualSecs = 0;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<PlannerState>(context, listen: false);
    
    if (widget.session != null) {
      final s = widget.session!;
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description;
      _durationCtrl.text = s.expectedDurationMins.toString();
      _selectedSubject = s.subject;
      _selectedType = s.type;
      _scheduledTime = DateTime.fromMillisecondsSinceEpoch(s.scheduledDate);
      _goals = s.goals.map((g) => g.copyWith()).toList(); 
      _remarks = List.from(s.remarks);
      _isCompleted = s.isCompleted;
      _actualSecs = s.actualDurationSecs;
    } else if (widget.templatePreset != null) {
      final p = widget.templatePreset!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description;
      _durationCtrl.text = '60';
      _selectedSubject = p.subject;
      _selectedType = p.type;
      _scheduledTime = widget.initialDate;
      _goals = p.goalTemplates.map((t) => Goal(id: uuid.v4(), text: t)).toList();
    } else {
      _nameCtrl.text = '';
      _descCtrl.text = '';
      _durationCtrl.text = '60';
      _selectedSubject = state.activeSubjects.first;
      _selectedType = state.activeTypes.first;
      _scheduledTime = widget.initialDate;
    }
  }

  void _pickTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      builder: (context, child) => Theme(data: brutalistTheme, child: child!),
    );
    if (time != null) {
      setState(() {
        _scheduledTime = DateTime(_scheduledTime.year, _scheduledTime.month, _scheduledTime.day, time.hour, time.minute);
      });
    }
  }

  void _saveData() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NAME IS REQUIRED')));
      return;
    }

    final state = Provider.of<PlannerState>(context, listen: false);
    final session = StudySession(
      id: widget.session?.id ?? uuid.v4(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      subject: _selectedSubject,
      type: _selectedType,
      scheduledDate: _scheduledTime.millisecondsSinceEpoch,
      expectedDurationMins: int.tryParse(_durationCtrl.text.trim()) ?? 60,
      actualDurationSecs: _actualSecs,
      isCompleted: _isCompleted,
      goals: _goals,
      remarks: _remarks,
    );

    state.saveSession(session);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: const Text('CONFIGURE SESSION')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrutalistBox(
              child: Column(
                children: [
                  BrutalistTextField(controller: _nameCtrl, labelText: 'SESSION NOMENCLATURE'),
                  const SizedBox(height: 16),
                  BrutalistTextField(controller: _descCtrl, labelText: 'DESCRIPTION / PARAMETERS', maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: const InputDecoration(labelText: 'SUBJECT', filled: true, fillColor: BrutalistColors.paperBg, border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.inkBlack, width: 2))),
                          items: state.activeSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _selectedSubject = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'TYPE', filled: true, fillColor: BrutalistColors.paperBg, border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.inkBlack, width: 2))),
                          items: state.activeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: BrutalistTextField(controller: _durationCtrl, labelText: 'TARGET DUR. (MIN)', keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BrutalistButton(
                          label: DateFormat('HH:mm').format(_scheduledTime),
                          icon: Icons.access_time,
                          isPrimary: false,
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('SPECIFIC SESSION GOALS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ..._goals.map((g) => ListTile(
              title: Text(g.text, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _goals.remove(g))),
            )),
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: _goalCtrl, labelText: 'ADD TARGET')),
                IconButton(icon: const Icon(Icons.add_box, size: 48), onPressed: () {
                  if (_goalCtrl.text.isNotEmpty) {
                    setState(() => _goals.add(Goal(id: uuid.v4(), text: _goalCtrl.text.trim())));
                    _goalCtrl.clear();
                  }
                }),
              ],
            ),
            const SizedBox(height: 48),
            
            BrutalistButton(label: 'COMMIT SCHEDULE', onPressed: _saveData),
            if (widget.session != null) ...[
              const SizedBox(height: 16),
              BrutalistButton(
                label: 'PURGE SESSION',
                isPrimary: false,
                colorOverride: BrutalistColors.rustRed.withOpacity(0.2),
                onPressed: () {
                  state.deleteSession(widget.session!.id);
                  Navigator.pop(context);
                },
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 10. ACTIVE SESSION TIMER & LOG
// ==========================================
class ActiveTimerScreen extends StatefulWidget {
  final StudySession session;

  const ActiveTimerScreen({super.key, required this.session});

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  final _remarkCtrl = TextEditingController();
  late DateTime _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = widget.session.actualDurationSecs;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _sessionStartTime = DateTime.now();
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _elapsedSeconds++);
      });
    }
  }

  String _calculateRelativeTime() {
    if (!_isRunning) return 'PAUSED/BEFORE_START';
    int hours = _elapsedSeconds ~/ 3600;
    int mins = (_elapsedSeconds % 3600) ~/ 60;
    return 'ACTIVE (+${hours}H ${mins}M)';
  }

  void _addRemark() {
    if (_remarkCtrl.text.trim().isEmpty) return;
    
    setState(() {
      widget.session.remarks.add(Remark(
        id: uuid.v4(),
        text: _remarkCtrl.text.trim(),
        relativeTime: _calculateRelativeTime(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        category: 'IN_SESSION'
      ));
      _remarkCtrl.clear();
    });
    Provider.of<PlannerState>(context, listen: false).saveSession(widget.session);
  }

  void _initiateSessionEnd() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    
    List<Goal> dialogGoals = widget.session.goals.map((g) => g.copyWith()).toList();
    final postRemarkCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: BrutalistColors.paperBg,
          shape: const RoundedRectangleBorder(side: BorderSide(color: BrutalistColors.inkBlack, width: 4)),
          title: const Text('POST-SESSION REVIEW', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('VALIDATE GOAL COMPLETION:'),
                const Divider(),
                ...dialogGoals.map((g) => CheckboxListTile(
                  title: Text(g.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  value: g.isFinished,
                  activeColor: BrutalistColors.steamGreen,
                  checkColor: BrutalistColors.paperBg,
                  onChanged: (val) => setDialogState(() => g.isFinished = val!),
                )),
                const SizedBox(height: 16),
                BrutalistTextField(controller: postRemarkCtrl, labelText: 'POST-MORTEM REMARK', maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('RESUME SESSION', style: TextStyle(color: BrutalistColors.inkBlack, fontWeight: FontWeight.bold)),
            ),
            BrutalistButton(
              label: 'FINALIZE & SAVE',
              onPressed: () {
                widget.session.goals = dialogGoals;
                widget.session.actualDurationSecs = _elapsedSeconds;
                widget.session.isCompleted = true;
                
                if (postRemarkCtrl.text.trim().isNotEmpty) {
                  widget.session.remarks.add(Remark(
                    id: uuid.v4(),
                    text: postRemarkCtrl.text.trim(),
                    relativeTime: 'POST-COMPLETION',
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    category: 'POST_MORTEM'
                  ));
                }

                Provider.of<PlannerState>(context, listen: false).saveSession(widget.session);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EXECUTION PHASE'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.session.name.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            Text('${widget.session.subject} | ${widget.session.type}', style: const TextStyle(fontSize: 16, color: BrutalistColors.neutralGray), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: _isRunning ? BrutalistColors.steamGreen.withOpacity(0.1) : BrutalistColors.paperBg,
                border: Border.all(color: BrutalistColors.inkBlack, width: 4),
              ),
              child: Center(
                child: Text(_formatDuration(_elapsedSeconds), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: 4)),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: BrutalistButton(
                    label: _isRunning ? 'PAUSE CLOCK' : 'START CLOCK',
                    colorOverride: _isRunning ? BrutalistColors.rustRed : BrutalistColors.steamGreen,
                    onPressed: _toggleTimer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BrutalistButton(
                    label: 'CONCLUDE',
                    isPrimary: false,
                    onPressed: _initiateSessionEnd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text('LIVE REMARK LOG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.session.remarks.length,
                itemBuilder: (context, index) {
                  final r = widget.session.remarks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('[${r.relativeTime}] ${r.text}', style: const TextStyle(fontSize: 14)),
                  );
                },
              ),
            ),
            
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: _remarkCtrl, labelText: 'INSERT LOG ENTRY')),
                IconButton(icon: const Icon(Icons.send, size: 48), onPressed: _addRemark),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 11. PRESETS MANAGEMENT
// ==========================================
class PresetsManagementView extends StatelessWidget {
  const PresetsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: const Text('TEMPLATE ARCHIVE')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: BrutalistColors.inkBlack,
        foregroundColor: BrutalistColors.paperBg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: BrutalistColors.inkBlack, width: 2)),
        onPressed: () => _showCreatePresetDialog(context),
        child: const Icon(Icons.add),
      ),
      body: state.presets.isEmpty
          ? const Center(child: Text('NO TEMPLATES DEFINED', style: TextStyle(fontWeight: FontWeight.bold)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.presets.length,
              itemBuilder: (context, index) {
                final preset = state.presets[index];
                return BrutalistBox(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(preset.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    subtitle: Text('SUBJ: ${preset.subject} | TYPE: ${preset.type}\nGOALS PRE-CONFIGURED: ${preset.goalTemplates.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.schedule_send),
                          tooltip: 'SCHEDULE FROM TEMPLATE',
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionConfigurationScreen(initialDate: DateTime.now(), templatePreset: preset))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: BrutalistColors.rustRed),
                          onPressed: () => state.deletePreset(preset.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreatePresetDialog(BuildContext context) {
    final state = Provider.of<PlannerState>(context, listen: false);
    final nameCtrl = TextEditingController();
    String selectedSubject = state.activeSubjects.first;
    String selectedType = state.activeTypes.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: BrutalistColors.paperBg,
          shape: const RoundedRectangleBorder(side: BorderSide(color: BrutalistColors.inkBlack, width: 4)),
          title: const Text('GENERATE NEW TEMPLATE'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrutalistTextField(controller: nameCtrl, labelText: 'TEMPLATE NAME'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: const InputDecoration(labelText: 'DEFAULT SUBJECT', filled: true, fillColor: BrutalistColors.paperBg, border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.inkBlack, width: 2))),
                items: state.activeSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setDialogState(() => selectedSubject = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'DEFAULT TYPE', filled: true, fillColor: BrutalistColors.paperBg, border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: BrutalistColors.inkBlack, width: 2))),
                items: state.activeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            BrutalistButton(
              label: 'SAVE TEMPLATE',
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  state.savePreset(SessionPreset(
                    id: uuid.v4(),
                    name: nameCtrl.text.trim(),
                    description: '',
                    subject: selectedSubject,
                    type: selectedType,
                    goalTemplates: [], 
                  ));
                  Navigator.pop(ctx);
                }
              },
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 12. ADVANCED DATA EXPORT & ANALYTICS
// ==========================================
class DataExportAnalyticsView extends StatefulWidget {
  const DataExportAnalyticsView({super.key});

  @override
  State<DataExportAnalyticsView> createState() => _DataExportAnalyticsViewState();
}

class _DataExportAnalyticsViewState extends State<DataExportAnalyticsView> {
  String _exportTarget = 'GOALS'; 
  String _subjectFilter = 'ALL';
  String _typeFilter = 'ALL';
  String _completionFilter = 'UNFINISHED'; 

  List<String> _generateExportData(PlannerState state) {
    List<String> lines = [];
    
    List<StudySession> sortedSessions = List.from(state.sessions);
    sortedSessions.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    for (var session in sortedSessions) {
      if (_subjectFilter != 'ALL' && session.subject != _subjectFilter) continue;
      if (_typeFilter != 'ALL' && session.type != _typeFilter) continue;

      String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(session.scheduledDate));
      
      if (_exportTarget == 'GOALS') {
        for (var goal in session.goals) {
          bool passComp = _completionFilter == 'ALL' || 
                         (_completionFilter == 'FINISHED' && goal.isFinished) || 
                         (_completionFilter == 'UNFINISHED' && !goal.isFinished);
          if (passComp) {
            lines.add('[$dateStr | ${session.subject} | ${session.type}] ${session.name} - GOAL: ${goal.text} (${goal.isFinished ? 'COMPLETED' : 'PENDING'})');
          }
        }
      } else if (_exportTarget == 'REMARKS') {
        for (var remark in session.remarks) {
          String logTime = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(remark.timestamp));
          lines.add('[$dateStr $logTime | ${session.name}] (${remark.relativeTime}) ${remark.text}');
        }
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    List<String> exportLines = _generateExportData(state);

    return Scaffold(
      appBar: AppBar(title: const Text('DATA EXTRACTION')),
      body: Column(
        children: [
          BrutalistBox(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _exportTarget,
                        decoration: const InputDecoration(labelText: 'TARGET ENTITY'),
                        items: const [DropdownMenuItem(value: 'GOALS', child: Text('GOALS')), DropdownMenuItem(value: 'REMARKS', child: Text('REMARKS'))],
                        onChanged: (v) => setState(() => _exportTarget = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _subjectFilter,
                        decoration: const InputDecoration(labelText: 'SUBJECT FILTER'),
                        items: ['ALL', ...state.activeSubjects].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _subjectFilter = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _typeFilter,
                        decoration: const InputDecoration(labelText: 'TYPE FILTER'),
                        items: ['ALL', ...state.activeTypes].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _typeFilter = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _completionFilter,
                        decoration: const InputDecoration(labelText: 'STATUS FILTER'),
                        items: const [DropdownMenuItem(value: 'ALL', child: Text('ALL')), DropdownMenuItem(value: 'FINISHED', child: Text('FINISHED')), DropdownMenuItem(value: 'UNFINISHED', child: Text('UNFINISHED'))],
                        onChanged: _exportTarget == 'REMARKS' ? null : (v) => setState(() => _completionFilter = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                BrutalistButton(
                  label: 'COPY ${exportLines.length} RECORDS TO CLIPBOARD',
                  icon: Icons.copy_all,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: exportLines.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DATA COPIED TO SYSTEM CLIPBOARD', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: BrutalistColors.inkBlack));
                  },
                )
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrutalistColors.inkBlack,
                border: Border.all(color: BrutalistColors.brassAccent, width: 3),
              ),
              child: ListView(
                children: exportLines.map((e) => Text(e, style: const TextStyle(color: BrutalistColors.steamGreen, fontFamily: 'Courier', fontSize: 12, height: 1.5))).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 13. USER SETTINGS AND PROFILE
// ==========================================
class UserProfileSettingsView extends StatelessWidget {
  const UserProfileSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final newSubCtrl = TextEditingController();
    final newTypeCtrl = TextEditingController();
    final newUserCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('SYSTEM PREFERENCES')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrutalistBox(
              backgroundColor: BrutalistColors.brassAccent.withOpacity(0.2),
              child: Column(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 64),
                  const SizedBox(height: 8),
                  Text('ACTIVE PROFILE: ${state.currentUser?.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('CUSTOM SUBJECT CATEGORIES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.activeSubjects.map((s) => Chip(
                label: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, color: BrutalistColors.paperBg)),
                backgroundColor: BrutalistColors.inkBlack,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: newSubCtrl, labelText: 'ADD SUBJECT')),
                IconButton(icon: const Icon(Icons.add_circle, size: 48), onPressed: () {
                  if (newSubCtrl.text.isNotEmpty) state.addCustomSubject(newSubCtrl.text);
                  newSubCtrl.clear();
                }),
              ],
            ),
            const SizedBox(height: 32),

            const Text('CUSTOM SESSION TYPES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.activeTypes.map((t) => Chip(
                label: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: BrutalistColors.paperBg)),
                backgroundColor: BrutalistColors.rustRed,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: newTypeCtrl, labelText: 'ADD TYPE')),
                IconButton(icon: const Icon(Icons.add_circle, size: 48), onPressed: () {
                  if (newTypeCtrl.text.isNotEmpty) state.addCustomType(newTypeCtrl.text);
                  newTypeCtrl.clear();
                }),
              ],
            ),
            const SizedBox(height: 32),

            const Text('OPERATOR PROFILES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...state.users.map((u) => ListTile(
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: u.id == state.currentUser?.id 
                ? const Icon(Icons.verified, color: BrutalistColors.steamGreen) 
                : BrutalistButton(label: 'SWITCH', isPrimary: false, onPressed: () => state.switchUser(u.id)),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: BrutalistTextField(controller: newUserCtrl, labelText: 'NEW OPERATOR NAME')),
                IconButton(icon: const Icon(Icons.person_add, size: 48), onPressed: () {
                  if (newUserCtrl.text.isNotEmpty) state.createNewUser(newUserCtrl.text);
                  newUserCtrl.clear();
                }),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
