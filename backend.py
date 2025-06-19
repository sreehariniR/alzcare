from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, time as dt_time
import os

app = Flask(__name__)
CORS(app)

scheduler = BackgroundScheduler()
scheduler.start()

# Function to generate a voice file from a custom message
def generate_voice(note, filename="voice_prompt.mp3"):
    tts = gTTS(note)
    tts.save(filename)
    print(f"Voice prompt generated: {note}")

@app.route('/set_reminder', methods=['POST'])
def set_reminder():
    data = request.get_json()

    reminder_time = data.get("time")         # format: "HH:MM"
    reminder_note = data.get("note", "This is your reminder.")
    is_daily = data.get("daily", False)
    reminder_date = data.get("date")         # format: "YYYY-MM-DD" if provided

    try:
        hour, minute = map(int, reminder_time.split(":"))
    except:
        return jsonify({"error": "Invalid time format"}), 400

    job_id = f"reminder_{hour}_{minute}_{datetime.now().timestamp()}"

    if is_daily:
        scheduler.add_job(
            generate_voice,
            'cron',
            hour=hour,
            minute=minute,
            args=[reminder_note],
            id=job_id
        )
        return jsonify({"message": "Daily reminder scheduled."})
    else:
        if not reminder_date:
            return jsonify({"error": "Date is required for one-time reminder"}), 400
        try:
            run_datetime = datetime.strptime(f"{reminder_date} {reminder_time}", "%Y-%m-%d %H:%M")
        except ValueError:
            return jsonify({"error": "Invalid date/time format"}), 400

        scheduler.add_job(
            generate_voice,
            'date',
            run_date=run_datetime,
            args=[reminder_note],
            id=job_id
        )
        return jsonify({"message": "One-time reminder scheduled."})

@app.route('/voice')
def get_voice():
    filename = "voice_prompt.mp3"
    if os.path.exists(filename):
        return send_file(filename, mimetype='audio/mp3')
    else:
        return jsonify({"error": "Voice file not generated yet."}), 404

@app.route('/alert')
def get_alert():
    return jsonify({'alert': 'Emergency alert sent'})

if __name__ == '__main__':
    app.run(debug=True)
