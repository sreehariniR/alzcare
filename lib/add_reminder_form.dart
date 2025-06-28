import 'package:flutter/material.dart';

class AddReminderForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddReminderForm({super.key, required this.onSave});

  @override
  State<AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<AddReminderForm> {
  final _formKey = GlobalKey<FormState>();
  String note = '';
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();
  bool isDaily = false;

  void _submit() {
    if (note.trim().isEmpty) return;

    final timeStr = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
    final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    widget.onSave({
      "note": note,
      "time": timeStr,
      "date": dateStr,
      "daily": isDaily,
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text("New Reminder", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextFormField(
              decoration: const InputDecoration(labelText: "Note"),
              onChanged: (val) => note = val,
            ),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text("Time: ${selectedTime.format(context)}"),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: selectedTime);
                    if (picked != null) setState(() => selectedTime = picked);
                  },
                  child: const Text("Pick Time"),
                )
              ],
            ),
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: const Text("Pick Date"),
                )
              ],
            ),
            Row(
              children: [
                const Icon(Icons.repeat),
                const SizedBox(width: 8),
                const Text("Repeat daily"),
                const Spacer(),
                Switch(
                  value: isDaily,
                  onChanged: (val) => setState(() => isDaily = val),
                )
              ],
            ),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Reminder"),
            )
          ],
        ),
      ),
    );
  }
}
