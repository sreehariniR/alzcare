import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();
player.play(UrlSource('http://127.0.0.1:5000/voice'));


class CaretakerHomePage extends StatelessWidget {
  Future<void> fetchData(BuildContext context, String endpoint) async {
    final url = Uri.parse('http://127.0.0.1:5000/$endpoint'); // Use IP if real device

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Response'),
            content: Text(data.values.first.toString()),
          ),
        );
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
        ),
      );
    }
  }
  Widget buildCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4))],
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AIzCare Caretaker'),
        backgroundColor: Colors.deepPurple.shade300,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            buildCard(icon: Icons.alarm, label: 'Reminders', onTap: () => showReminderDialog(context)),

            buildCard(icon: Icons.notifications, label: 'Notifications', onTap: () => print('Notifications')),
            buildCard(icon: Icons.location_on, label: 'Patient Location', onTap: () => print('Location')),
            buildCard(icon: Icons.health_and_safety, label: 'Health Insights', onTap: () => print('Insights')),
            buildCard(icon: Icons.folder_shared, label: 'Health Records', onTap: () => print('Records')),
          ],
        ),
      ),
    );
  }


  void showReminderDialog(BuildContext context) {
    TimeOfDay? selectedTime;
    DateTime? selectedDate;
    TextEditingController noteController = TextEditingController();
    bool isDaily = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Reminder Note',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),

                    /// TIME PICKER
                    Row(
                      children: [
                        Text("Select Time: "),
                        TextButton(
                          child: Text(selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Choose'),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    /// DAILY CHECKBOX
                    Row(
                      children: [
                        Checkbox(
                          value: isDaily,
                          onChanged: (value) {
                            setState(() {
                              isDaily = value ?? false;
                            });
                          },
                        ),
                        Text("Repeat Daily"),
                      ],
                    ),

                    /// DATE PICKER (only if not daily)
                    if (!isDaily)
                      Row(
                        children: [
                          Text("Select Date: "),
                          TextButton(
                            child: Text(selectedDate != null
                                ? '${selectedDate!.toLocal()}'.split(' ')[0]
                                : 'Choose'),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  child: Text('Set Reminder'),
                  onPressed: () async {
                    if (selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a time')),
                      );
                      return;
                    }

                    String timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                    String? dateStr = selectedDate != null
                        ? selectedDate!.toIso8601String().split('T')[0]
                        : null;

                    final url = Uri.parse('http://127.0.0.1:5000/set_reminder'); // replace with your IP if needed

                    final response = await http.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'time': timeStr,
                        'daily': isDaily,
                        'note': noteController.text,
                        'date': isDaily ? null : dateStr,
                      }),
                    );

                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reminder set successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${response.body}')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

}
