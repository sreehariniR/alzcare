from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, time as dt_time
import os
import torch
import io
from PIL import Image
from ultralytics import YOLO


app=Flask(__name__)
CORS(app)
reminders={}
scheduler=BackgroundScheduler()
scheduler.start()

# Function to generate a voice file from a custom message
def generate_voice(note,filename="voice_prompt.mp3"):
    tts=gTTS(note)
    tts.save(filename)
    print(f"Voice Reminder is {note}")
    

@app.route('/set_reminder',methods=['POST'])
def set_reminder():
    data=request.get_json()
    note=data.get("note","This is the reminder")
    date_str=data.get("date")
    time_str=data.get("time")
    is_daily=data.get("daily",False)
    if not time_str:
        return jsonify({'error':'Time is required'}),400
    try:
        hour,minute=map(int,time_str.split(':'))
    except:
        return jsonify({'error':'Invalid Time format'}),400
    for id,rem in reminders.items():
        if rem["time"]==time_str and rem["date"]==date_str and not rem["daily"]:
            return jsonify({'error':'Reminder already exists for the scheduled time'}),409
    reminder_id=len(reminders)+1
    job_id=f'reminder_{datetime.now().strftime("%Y%m%d%H%M%S")}'
    if is_daily:
        scheduler.add_job(
            generate_voice,
            'cron',
            hour=hour,
            minute=minute,
            args=[note],
            id=job_id
        )
    else:
        if not date_str:
            return jsonify({"error":"Date is required for one-time reminder"}),400
        try:
            run_dt = datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
        except:
            return jsonify({"error": "Invalid date/time format."}), 400
        scheduler.add_job(
            generate_voice,
            'date',
            run_date=run_dt,
            args=[note],
            id=job_id
        )

    reminders[reminder_id]={
        'note':note,
        'time':time_str,
        'date':date_str,
        'daily':is_daily,
        'job_id':job_id
    }
    return jsonify({'message':'Reminder set','id':reminder_id}),200
@app.route('/alert')
def get_alert():
    return jsonify({'alert': 'Emergency alert sent'})



model = YOLO("yolov8n.pt")

@app.route('/detect',methods=["POST"])
def detect_objects():
    print("Image received!")
    if 'image' not in request.files:
       return jsonify({'error':'Image not detected'}),400
    image_file=request.files['image']
    image=Image.open(image_file.stream)
    results=model(image)
    names=results[0].names
    detections=results[0].boxes.cls.tolist()
    labels=[names[int(cls)] for cls in detections]
    unique_labels = list(set(labels))[:3]
    return jsonify({'objects': unique_labels})




if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

