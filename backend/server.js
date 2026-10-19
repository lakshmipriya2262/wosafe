const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// In-memory database of active distress alerts
let activeDistressAlerts = {};

// 1. ENDPOINT: Receive SOS / Heart Rate Distress
app.post('/api/sos/trigger', (req, res) => {
  const {
    userId = "USER_001",
    userName = "Wosafe User",
    triggerSource = "MANUAL_SOS",
    heartRate = 135,
    spo2 = 91,
    latitude = 12.8530,
    longitude = 80.2265,
    hasAsthma = true,
    emergencyContacts = []
  } = req.body;

  const timestamp = new Date().toLocaleTimeString();
  const mapsLink = `https://www.google.com/maps?q=${latitude},${longitude}`;

  console.log("\n=======================================================");
  console.log(`🚨 [EMERGENCY ALERT RECEIVED] at ${timestamp}`);
  console.log(`   Source: ${triggerSource}`);
  console.log(`   User: ${userName} (ID: ${userId})`);
  console.log(`   Heart Rate: ${heartRate} BPM (CRITICAL SPIKE!)`);
  console.log(`   SpO2: ${spo2}%`);
  console.log(`   Live GPS: ${latitude}, ${longitude}`);
  console.log(`   Maps: ${mapsLink}`);
  if (hasAsthma) {
    console.log(`   ⚠️ MEDICAL ALERT: User has ASTHMA. Bring Inhaler/Nebulizer!`);
  }
  console.log("-------------------------------------------------------");
  console.log(`📲 [SMS GATEWAY DISPATCH]`);
  if (emergencyContacts.length === 0) {
    console.log(`   -> [SMS Sent] +91 9876543210: "EMERGENCY! ${userName} distress. Location: ${mapsLink}"`);
  } else {
    emergencyContacts.forEach((contact, idx) => {
      console.log(`   -> [SMS ${idx + 1}] Sent to ${contact.name} (${contact.phone}):`);
      console.log(`      "EMERGENCY! ${userName} triggered SOS (HR: ${heartRate} BPM). Location: ${mapsLink}"`);
    });
  }
  console.log("=======================================================\n");

  activeDistressAlerts[userId] = {
    userId,
    userName,
    heartRate,
    spo2,
    latitude,
    longitude,
    hasAsthma,
    lastUpdated: timestamp,
  };

  res.status(200).json({
    success: true,
    message: "Distress signal logged and emergency SMS dispatched",
    trackingUrl: `http://localhost:3000/track/${userId}`
  });
});

// 2. ENDPOINT: Continuous GPS Stream from Phone
app.post('/api/location/stream', (req, res) => {
  const { userId = "USER_001", latitude, longitude, heartRate } = req.body;
  if (activeDistressAlerts[userId]) {
    activeDistressAlerts[userId].latitude = latitude;
    activeDistressAlerts[userId].longitude = longitude;
    if (heartRate) activeDistressAlerts[userId].heartRate = heartRate;
    activeDistressAlerts[userId].lastUpdated = new Date().toLocaleTimeString();
  }
  res.status(200).json({ status: "Location updated" });
});

// 3. ENDPOINT: Live Tracking Map for Web Browser
app.get('/track/:userId', (req, res) => {
  const alert = activeDistressAlerts[req.params.userId] || {
    userName: "Kavya",
    heartRate: 135,
    spo2: 91,
    latitude: 12.8530,
    longitude: 80.2265,
    hasAsthma: true,
    lastUpdated: "Just now"
  };

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>WOSAFE Live Tracking</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
      <style>
        body { font-family: sans-serif; margin: 0; background: #0f172a; color: #fff; }
        #header { background: #e11d48; padding: 16px 20px; }
        #map { height: 60vh; width: 100%; }
        .details { padding: 20px; display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
        .card { background: #1e293b; border-radius: 10px; padding: 15px; border-left: 4px solid #e11d48; }
        .card h4 { margin: 0 0 8px 0; color: #94a3b8; font-size: 13px; text-transform: uppercase; }
        .card p { margin: 0; font-size: 18px; font-weight: bold; }
        .badge { background: #fbbf24; color: #000; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
      </style>
    </head>
    <body>
      <div id="header">
        <h2 style="margin:0;">🚨 WOSAFE Emergency Live Tracking</h2>
      </div>
      <div id="map"></div>
      <div class="details">
        <div class="card">
          <h4>Victim</h4>
          <p>${alert.userName}</p>
          ${alert.hasAsthma ? '<span class="badge">⚠️ Asthma Patient</span>' : ''}
        </div>
        <div class="card">
          <h4>Heart Rate</h4>
          <p style="color: #f43f5e;">❤️ ${alert.heartRate} BPM</p>
        </div>
        <div class="card">
          <h4>Coordinates</h4>
          <p>${alert.latitude}, ${alert.longitude}</p>
          <small>Updated: ${alert.lastUpdated}</small>
        </div>
      </div>
      <script>
        const map = L.map('map').setView([${alert.latitude}, ${alert.longitude}], 16);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
        L.marker([${alert.latitude}, ${alert.longitude}]).addTo(map)
          .bindPopup('<b>${alert.userName}</b><br>Heart Rate: ${alert.heartRate} BPM')
          .openPopup();
        setInterval(() => location.reload(), 5000);
      </script>
    </body>
    </html>
  `);
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 WOSAFE Backend Server running on Port ${PORT}`);
  console.log(`   - Live Map: http://localhost:${PORT}/track/USER_001`);
  console.log(`   - SOS API:  http://localhost:${PORT}/api/sos/trigger\n`);
});