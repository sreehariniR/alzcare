import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package.intl/intl.dart';

// We import your original screen to navigate to it
import 'reminders.dart';

// --- DATA MODELS ---
// This is a local model for displaying the timeline. It can be created from the
// same data that your ReminderScreen uses.

enum ActivityType { medication, meal, appointment, activity, hygiene, other }

class ScheduledActivity {
  final String title;
  final TimeOfDay time;
  final ActivityType type;
  bool isCompleted; // Changed to non-final to allow toggling

  ScheduledActivity({
    required this.title,
    required this.time,
    required this.type,
    this.isCompleted = false,
  });

  // A helper to create this visual object from your existing Reminder data
  factory ScheduledActivity.fromReminder(Map<String, dynamic> reminderJson) {
    final String note = reminderJson['note'] ?? 'No Note';
    final String timeStr = reminderJson['time'] ?? '00:00';
    final timeParts = timeStr.split(':').map(int.parse).toList();

    return ScheduledActivity(
      title: note,
      time: TimeOfDay(hour: timeParts[0], minute: timeParts[1]),
      type: _inferTypeFromNote(note),
    );
  }

  // Helper to guess the category from the reminder note
  static ActivityType _inferTypeFromNote(String note) {
    final lowerNote = note.toLowerCase();
    if (lowerNote.contains('pill') || lowerNote.contains('meds') || lowerNote.contains('tablet')) return ActivityType.medication;
    if (lowerNote.contains('eat') || lowerNote.contains('lunch') || lowerNote.contains('breakfast') || lowerNote.contains('dinner')) return ActivityType.meal;
    if (lowerNote.contains('dr.') || lowerNote.contains('doctor') || lowerNote.contains('appt')) return ActivityType.appointment;
    if (lowerNote.contains('walk') || lowerNote.contains('read') || lowerNote.contains('garden')) return ActivityType.activity;
    if (lowerNote.contains('bath') || lowerNote.contains('shower') || lowerNote.contains('brush')) return ActivityType.hygiene;
    return ActivityType.other;
  }
}

// --- MAIN PAGE WIDGET ---

class RoutineSchedulingPage extends StatefulWidget {
  const RoutineSchedulingPage({Key? key}) : super(key: key);

  @override
  _RoutineSchedulingPageState createState() => _RoutineSchedulingPageState();
}

class _RoutineSchedulingPageState extends State<RoutineSchedulingPage> {
  DateTime _selectedDate = DateTime.now();
  List<ScheduledActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScheduleForDay(_selectedDate);
  }

  Future<void> _fetchScheduleForDay(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      // NOTE: Update this IP address to your computer's IP
      final response = await http.get(Uri.parse("http://192.168.1.124:5000/all_reminders"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final allReminders = data.values.toList();

        final formatter = DateFormat('yyyy-MM-dd');
        final selectedDateStr = formatter.format(date);

        // Filter reminders for the selected day and convert them to ScheduledActivity
        final activitiesForDay = allReminders
            .where((r) => r['date'] == selectedDateStr)
            .map((r) => ScheduledActivity.fromReminder(r as Map<String, dynamic>))
            .toList();

        // Sort activities by time of day
        activitiesForDay.sort((a,b) => (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));

        setState(() {
          _activities = activitiesForDay;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching schedule from server.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network Error. Is the server running?")));
      print("Error fetching schedule: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _fetchScheduleForDay(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      appBar: AppBar(
        title: Text('Daily Routine', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.black54),
            tooltip: 'Manage All Reminders',
            onPressed: () {
              // This navigates to your original reminders.dart screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderScreen()),
              ).then((_) {
                // When we come back, refresh the schedule for today
                _fetchScheduleForDay(_selectedDate);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _DateNavigator(
            selectedDate: _selectedDate,
            onDateChanged: _changeDate,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activities.isEmpty
                ? _EmptyScheduleView()
                : _TimelineView(activities: _activities),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigates to your ReminderScreen and tells it to open the 'add' dialog
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReminderScreen(openAddReminder: true)),
          ).then((_) => _fetchScheduleForDay(_selectedDate));
        },
        backgroundColor: const Color(0xFF5B67CA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("New Task", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

// --- WIDGETS FOR THIS PAGE (Timeline, Cards, etc.) ---

class _DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final Function(int) onDateChanged;

  const _DateNavigator({required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20),
            onPressed: () => onDateChanged(-1),
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDate),
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                DateFormat('EEEE').format(selectedDate),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
            onPressed: () => onDateChanged(1),
          ),
        ],
      ),
    );
  }
}

class _EmptyScheduleView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_month_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'No routine scheduled for this day.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap '+' to add an activity.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _TimelineView extends StatelessWidget {
  final List<ScheduledActivity> activities;
  const _TimelineView({required this.activities});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _TimelineTile(
          activity: activity,
          isFirst: index == 0,
          isLast: index == activities.length - 1,
        );
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final ScheduledActivity activity;
  final bool isFirst;
  final bool isLast;

  const _TimelineTile({
    required this.activity,
    required this.isFirst,
    required this.isLast,
  });

  Color _getCategoryColor(ActivityType type) {
    switch (type) {
      case ActivityType.medication: return const Color(0xFFE57373);
      case ActivityType.meal: return const Color(0xFFFFB74D);
      case ActivityType.appointment: return const Color(0xFF64B5F6);
      case ActivityType.activity: return const Color(0xFF81C784);
      case ActivityType.hygiene: return const Color(0xFFBA68C8);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  activity.time.format(context),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
                _TimelineConnector(isFirst: isFirst, isLast: isLast, color: _getCategoryColor(activity.type)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _ActivityCard(activity: activity)),
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Color color;
  const _TimelineConnector({required this.isFirst, required this.isLast, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Top line (only visible if not the first item)
          if (!isFirst) Expanded(child: Container(width: 2, color: color.withOpacity(0.3))),
          // The center dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          // Bottom line (only visible if not the last item)
          if (!isLast) Expanded(child: Container(width: 2, color: color.withOpacity(0.3))),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  final ScheduledActivity activity;
  const _ActivityCard({required this.activity});

  @override
  __ActivityCardState createState() => __ActivityCardState();
}

class __ActivityCardState extends State<_ActivityCard> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.activity.isCompleted;
  }

  Color _getCategoryColor(ActivityType type) {
    switch (type) {
      case ActivityType.medication: return const Color(0xFFE57373);
      case ActivityType.meal: return const Color(0xFFFFB74D);
      case ActivityType.appointment: return const Color(0xFF64B5F6);
      case ActivityType.activity: return const Color(0xFF81C784);
      case ActivityType.hygiene: return const Color(0xFFBA68C8);
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ActivityType type) {
    switch (type) {
      case ActivityType.medication: return Icons.medication_liquid_outlined;
      case ActivityType.meal: return Icons.restaurant_menu_outlined;
      case ActivityType.appointment: return Icons.calendar_month_outlined;
      case ActivityType.activity: return Icons.directions_walk_outlined;
      case ActivityType.hygiene: return Icons.clean_hands_outlined;
      default: return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(widget.activity.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCompleted ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Icon(_getCategoryIcon(widget.activity.type), color: _isCompleted ? Colors.grey.shade400 : color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.activity.title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isCompleted ? Colors.grey.shade500 : Colors.black87,
                decoration: _isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          Checkbox(
            value: _isCompleted,
            onChanged: (val) {
              setState(() {
                _isCompleted = val ?? false;
                // TODO: In a real app, you would also want to send this status update to the backend.
              });
            },
            activeColor: color,
            shape: const CircleBorder(),
          ),
        ],
      ),
    );
  }
}