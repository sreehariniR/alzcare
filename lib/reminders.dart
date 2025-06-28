import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart'; // Needed for the 'add' functionality
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:collection'; // For SplayTreeMap

class AppColors {
  static const Color background = Color(0xFFF5F3EF);
  static const Color primaryText = Color(0xFF1E1E1E);
  static const Color secondaryText = Color(0xFF6B6B6B);
  static const Color accent = Color(0xFF4A43E8);
  static const Color cardRed = Color(0xFFAC5A5A);
  static const Color cardOrange = Color(0xFFD67359);
  static const Color cardBlue = Color(0xFF3C3E5A);
  static const Color cardDarkGrey = Color(0xFF474747);
  static const Color cardLightBlue = Color(0xFFA5B4CB);
  static const Color cardLightGreen = Color(0xFFB3C5B4);
}

// --- Data Model for a Reminder ---
class Reminder {
  final String note;
  final DateTime dateTime;
  final bool isDaily;

  Reminder({
    required this.note,
    required this.dateTime,
    this.isDaily = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final String dateStr = json['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String timeStr = json['time'] ?? '00:00';
    final String fullTimeStr = timeStr.length == 5 ? '$timeStr:00' : timeStr;

    return Reminder(
      note: json['note'] ?? 'No Note',
      dateTime: DateTime.parse('$dateStr $fullTimeStr'),
      isDaily: json['daily'] ?? false,
    );
  }
}

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // For voice prompt on add
  bool _isLoading = true;
  String _selectedView = 'Today';

  List<Reminder> _allReminders = [];
  Map<DateTime, List<Reminder>> _groupedReminders = {};

  @override
  void initState() {
    super.initState();
    fetchAndProcessReminders();
  }

  // --- DATA HANDLING ---
  Future<void> fetchAndProcessReminders() async {
    setState(() => _isLoading = true);
    try {
      // *** IMPORTANT: Replace with your actual IP address ***
      final response = await http.get(Uri.parse("http://192.168.0.102:5000/all_reminders"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reminders = data.values.map((item) => Reminder.fromJson(item as Map<String, dynamic>)).toList();
        reminders.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        setState(() {
          _allReminders = reminders;
          _groupRemindersByDay();
        });
      } else {
        _showErrorSnackBar("Could not fetch reminders from server.");
      }
    } catch (e) {
      print("Error fetching reminders: $e");
      _showErrorSnackBar("Network error. Check connection and IP address.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _groupRemindersByDay() {
    final Map<DateTime, List<Reminder>> grouped = {};
    for (var reminder in _allReminders) {
      final dateKey = DateTime(reminder.dateTime.year, reminder.dateTime.month, reminder.dateTime.day);
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(reminder);
      grouped[dateKey]!.sort((a,b) => a.dateTime.compareTo(b.dateTime));
    }
    _groupedReminders = SplayTreeMap.from(grouped, (a, b) => a.compareTo(b));
  }

  Future<void> playVoicePrompt() async {
    try {
      // *** IMPORTANT: Replace with your actual IP address ***
      const url = 'http://192.168.0.102:5000/voice';
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print("Error playing voice: $e");
      _showErrorSnackBar("Could not play voice prompt.");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- UI & WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        // FIX #3: Back arrow is now a functional button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reminders', // Changed title to be more generic
          style: GoogleFonts.poppins(
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchAndProcessReminders,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // FIX #2: Removed the personalized header here
              const SizedBox(height: 16), // Added space for balance
              _buildViewNavigator(),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryText,))
                    : _buildCurrentView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewNavigator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton('Today'),
          _buildNavButton('Tomorrow'),
          _buildNavButton('All'),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildNavButton(String title) {
    final bool isSelected = _selectedView == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: InkWell(
        // FIX #1: Plus button now opens the 'add reminder' form
        onTap: () => _showAddReminderModalSheet(context),
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.background,
          child: Icon(Icons.add, color: AppColors.primaryText),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_allReminders.isEmpty) return _buildEmptyState();

    switch (_selectedView) {
      case 'Today':
        return _buildTodayView();
      case 'All':
        return _buildAllView();
      case 'Tomorrow':
      default:
        return _buildEmptyState(message: "No reminders for tomorrow.");
    }
  }

  Widget _buildTodayView() {
    final now = DateTime.now();
    final todayReminders = _allReminders
        .where((r) =>
    r.dateTime.year == now.year &&
        r.dateTime.month == now.month &&
        r.dateTime.day == now.day)
        .toList();

    if (todayReminders.isEmpty) return _buildEmptyState(message: "Nothing scheduled for today.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Text(
                  DateFormat('EEEE').format(now),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.secondaryText),
                ),
                Text(
                  DateFormat('dd').format(now),
                  style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryText, height: 1.1),
                ),
                Text(
                  DateFormat('MMMM').format(now).toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.primaryText, letterSpacing: 1.5),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('HH.mm').format(now),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Local Time',
                    style: GoogleFonts.poppins(color: AppColors.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: todayReminders.length,
            itemBuilder: (context, index) {
              final reminder = todayReminders[index];
              final color = [AppColors.cardRed, AppColors.cardOrange, AppColors.cardBlue][index % 3];
              return _TodayReminderCard(reminder: reminder, cardColor: color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllView() {
    if (_groupedReminders.isEmpty) return _buildEmptyState();

    final dateKeys = _groupedReminders.keys.toList();

    return ListView.builder(
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final date = dateKeys[index];
        final remindersForDay = _groupedReminders[date]!;
        final color = [AppColors.cardDarkGrey, AppColors.cardRed, AppColors.cardLightBlue, AppColors.cardLightGreen][index % 4];

        return _DailyScheduleCard(
          date: date,
          reminders: remindersForDay,
          cardColor: color,
        );
      },
    );
  }

  Widget _buildEmptyState({String message = "No reminders yet."}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap '+' to add a reminder.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }


  // --- ADD REMINDER MODAL SHEET (Restored from your original code) ---
  void _showAddReminderModalSheet(BuildContext context) {
    final noteController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime selectedDate = DateTime.now();
    bool isDaily = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {

            Future<void> pickTime() async {
              final picked = await showTimePicker(context: context, initialTime: selectedTime);
              if (picked != null) setModalState(() => selectedTime = picked);
            }

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setModalState(() => selectedDate = picked);
            }

            Future<void> submitReminder() async {
              if (noteController.text.isEmpty) {
                _showErrorSnackBar("Please enter a reminder note.");
                return;
              }
              Navigator.pop(context);

              // *** IMPORTANT: Replace with your actual IP address ***
              final url = Uri.parse('http://192.168.0.102:5000/set_reminder');
              final String formattedTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
              final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

              final body = jsonEncode({
                "note": noteController.text,
                "time": formattedTime, // Use the guaranteed 24-hour format
                "date": formattedDate, // Use the guaranteed YYYY-MM-DD format
                "daily": isDaily
              });

              try {
                // STEP 1: Tell the backend to create the audio file
                final response = await http.post(
                  url,
                  headers: {"Content-Type": "application/json"},
                  body: body,
                );

                if (response.statusCode == 200) {
                  // SUCCESS from Step 1! The file is now ready.
                  print("Backend confirmed voice file is ready.");

                  // STEP 2: Now that we know the file exists, ask for it.
                  await playVoicePrompt();

                  // Optional: Refresh the list of reminders
                  // await fetchReminders();

                } else {
                  final errorData = jsonDecode(response.body);
                  _showErrorSnackBar("Error from server: ${errorData['error']}");
                }
              } catch (e) {
                _showErrorSnackBar("Network error. Could not set reminder.");
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("New Reminder", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: "What to remember?",
                        labelStyle: GoogleFonts.poppins(),
                        prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _DateTimePickerChip(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat('MMM d, yyyy').format(selectedDate),
                          onTap: pickDate,
                        ),
                        const SizedBox(width: 12),
                        _DateTimePickerChip(
                          icon: Icons.access_time_outlined,
                          label: selectedTime.format(context),
                          onTap: pickTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Repeat Daily", style: GoogleFonts.poppins()),
                      value: isDaily,
                      onChanged: (val) => setModalState(() => isDaily = val),
                      activeColor: const Color(0xff2c2b3d),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2c2b3d),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "Set Reminder",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- EXTRACTED WIDGETS FOR CLEANLINESS ---

class _TodayReminderCard extends StatelessWidget {
  final Reminder reminder;
  final Color cardColor;

  const _TodayReminderCard({Key? key, required this.reminder, required this.cardColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible( // Added to prevent text overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.note,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder Location', // Placeholder
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH.mm').format(reminder.dateTime),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyScheduleCard extends StatelessWidget {
  final DateTime date;
  final List<Reminder> reminders;
  final Color cardColor;

  const _DailyScheduleCard({
    Key? key,
    required this.date,
    required this.reminders,
    required this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  DateFormat('EEE').format(date).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  DateFormat('dd').format(date),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(date).toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20)
                ),
                child: Column(
                  children: reminders.map((reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible( // Added to prevent text overflow
                          child: Text(
                            reminder.note,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(reminder.dateTime),
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  )).toList(),
                )
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget restored from your original code for the modal sheet
class _DateTimePickerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimePickerChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}