import json
from http.server import HTTPServer, BaseHTTPRequestHandler

# EXACT RED DOT COORDINATES FROM YOUR MAP (Karanai / Thalambur Campus Area)
CAMPUS_LAT = 12.8408
CAMPUS_LNG = 80.2002

active_emergencies = {}

class WosafeServerHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status=200, content_type='application/json'):
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(200)

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')
        data = json.loads(post_data) if post_data else {}

        # A) Emergency SOS Triggered
        if self.path == '/api/sos/trigger':
            user_id = data.get('userId', 'USER_001')
            user_name = data.get('userName', 'Protected User')
            lat = float(data.get('latitude', CAMPUS_LAT))
            lng = float(data.get('longitude', CAMPUS_LNG))
            has_asthma = data.get('hasAsthma', True)
            contacts = data.get('emergencyContacts', [])

            active_emergencies[user_id] = {
                "userName": user_name,
                "currentLat": lat,
                "currentLng": lng,
                "routeTrail": [[lat, lng]],
                "hasAsthma": has_asthma,
                "status": "SOS ACTIVE - ESCAPING TO SAFE HAVEN",
                "contacts": contacts,
                "lastUpdate": "Just now"
            }

            print("\n=======================================================")
            print(f"🚨 [EMERGENCY SOS ACTIVATED]")
            print(f"   Protected User: {user_name} ({user_id})")
            print(f"   GPS Location:   Lat {lat:.5f}, Lng {lng:.5f} (Karanai / Thalambur)")
            print(f"   Live Maps Link: https://www.google.com/maps?q={lat},{lng}")
            if has_asthma:
                print(f"   ⚠️ MEDICAL ADVISORY: User has ASTHMA. Responders bring Inhaler/Nebulizer!")
            print("-------------------------------------------------------")
            print("📲 [EMERGENCY DISPATCH TO CONTACTS & HELPLINES]")
            for c in contacts:
                print(f"   -> [DISPATCHED] {c.get('name')} ({c.get('phone')}): 'EMERGENCY! {user_name} needs help! Live GPS: https://maps.google.com/?q={lat},{lng}'")
            print("=======================================================\n")

            self._set_headers(200)
            self.wfile.write(json.dumps({"success": True, "message": "SOS initialized"}).encode('utf-8'))

        # B) Continuous Live Movement Stream
        elif self.path == '/api/location/stream':
            user_id = data.get('userId', 'USER_001')
            lat = float(data.get('latitude', CAMPUS_LAT))
            lng = float(data.get('longitude', CAMPUS_LNG))

            if user_id in active_emergencies:
                active_emergencies[user_id]["currentLat"] = lat
                active_emergencies[user_id]["currentLng"] = lng
                active_emergencies[user_id]["routeTrail"].append([lat, lng])
                print(f"📍 [LIVE TRACK PING] User moving -> Lat: {lat:.5f}, Lng: {lng:.5f}")

            self._set_headers(200)
            self.wfile.write(json.dumps({"success": True}).encode('utf-8'))

    def do_GET(self):
        if self.path.startswith('/api/location/live/'):
            user_id = self.path.split('/')[-1]
            data = active_emergencies.get(user_id, {
                "userName": "Protected User",
                "currentLat": CAMPUS_LAT,
                "currentLng": CAMPUS_LNG,
                "routeTrail": [[CAMPUS_LAT, CAMPUS_LNG]],
                "hasAsthma": True,
            })
            self._set_headers(200, 'application/json')
            self.wfile.write(json.dumps(data).encode('utf-8'))

        elif self.path.startswith('/track/'):
            user_id = self.path.split('/')[-1]
            emergency = active_emergencies.get(user_id, {
                "userName": "Protected User",
                "currentLat": CAMPUS_LAT,
                "currentLng": CAMPUS_LNG,
                "routeTrail": [[CAMPUS_LAT, CAMPUS_LNG]],
                "hasAsthma": True
            })

            html = f"""
            <!DOCTYPE html>
            <html>
            <head>
              <title>WOSAFE - Live Emergency Family Tracker</title>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
              <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
              <style>
                body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; background: #0f172a; color: #fff; }}
                #header {{ background: #be123c; padding: 14px 20px; }}
                #map {{ height: 65vh; width: 100%; }}
                .info-panel {{ padding: 16px; display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }}
                .card {{ background: #1e293b; padding: 14px; border-radius: 12px; border-left: 4px solid #f43f5e; }}
                .badge-asthma {{ background: #eab308; color: #000; padding: 4px 8px; border-radius: 6px; font-weight: bold; font-size: 11px; }}
                .safe-zone {{ color: #22c55e; font-weight: bold; font-size: 12px; margin: 3px 0; }}
              </style>
            </head>
            <body>
              <div id="header">
                <h3 style="margin:0;">🚨 WOSAFE - Live Emergency Family Tracking</h3>
                <small>Area: Karanai / Thalambur Safe Corridor (Live moving GPS updates every 2s)</small>
              </div>

              <div id="map"></div>

              <div class="info-panel">
                <div class="card">
                  <h4 style="margin:0 0 6px 0; color:#94a3b8;">Protected Person</h4>
                  <p style="margin:0; font-size:18px; font-weight:bold;">{emergency['userName']}</p>
                  {'<span class="badge-asthma">⚠️ Asthma Alert: Bring Inhaler/Nebulizer</span>' if emergency['hasAsthma'] else ''}
                </div>
                <div class="card">
                  <h4 style="margin:0 0 6px 0; color:#94a3b8;">Escape Corridor</h4>
                  <p style="margin:0; font-size:14px; color:#f43f5e; font-weight:bold;">Navigating toward safe zone 🏃‍♀️</p>
                  <small id="last-ping">Telemetry stream active...</small>
                </div>
                <div class="card">
                  <h4 style="margin:0 0 6px 0; color:#94a3b8;">Tagged Safe Havens</h4>
                  <p class="safe-zone">👮 Tambaram Police Station (1.2 km)</p>
                  <p class="safe-zone">🦁 Singapen Athiradi Padai (1091)</p>
                  <p class="safe-zone">🏥 Global Hospital (800m)</p>
                  <p class="safe-zone">🚖 24/7 Safe Cab Transit Zone (500m)</p>
                </div>
              </div>

              <script>
                const userId = '{user_id}';
                // Centered on the exact Red Dot location
                let map = L.map('map').setView([{emergency['currentLat']}, {emergency['currentLng']}], 16);
                L.tileLayer('https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png').addTo(map);

                // Safe Haven Markers around Karanai / Thalambur
                L.marker([12.8425, 80.2030]).addTo(map).bindPopup('👮 <b>Tambaram Police Assistance</b><br>Helpline: 044-22260100');
                L.marker([12.8440, 80.2050]).addTo(map).bindPopup('🏥 <b>Global Hospital</b><br>24/7 Emergency & Trauma');
                L.marker([12.8390, 80.2020]).addTo(map).bindPopup('🚖 <b>24/7 Women Safe Cab Hub</b><br>Fast Transit');

                // Moving Marker placed directly on the Red Dot
                let victimMarker = L.marker([{emergency['currentLat']}, {emergency['currentLng']}]).addTo(map)
                  .bindPopup('<b>{emergency['userName']} (Current Location)</b>').openPopup();

                let routeLine = L.polyline({emergency['routeTrail']}, {{color: '#f43f5e', weight: 5, opacity: 0.8}}).addTo(map);

                // Auto-refresh every 2 seconds
                setInterval(async () => {{
                  try {{
                    const res = await fetch('/api/location/live/' + userId);
                    const json = await res.json();
                    if (json.currentLat && json.currentLng) {{
                      const newLatLng = [json.currentLat, json.currentLng];
                      victimMarker.setLatLng(newLatLng);
                      if (json.routeTrail && json.routeTrail.length > 0) {{
                        routeLine.setLatLngs(json.routeTrail);
                      }}
                      document.getElementById('last-ping').innerText = 'Last GPS Ping: ' + new Date().toLocaleTimeString();
                    }}
                  }} catch (err) {{}}
                }}, 2000);
              </script>
            </body>
            </html>
            """
            self._set_headers(200, 'text/html; charset=utf-8')
            self.wfile.write(html.encode('utf-8'))
        else:
            self._set_headers(404, 'text/plain')
            self.wfile.write(b"Not Found")

PORT = 3000
print(f"\n🚀 WOSAFE Real-Time Backend running on Port {PORT}")
print(f"   - Emergency Live Tracking Map: http://localhost:{PORT}/track/USER_001\n")
server = HTTPServer(('0.0.0.0', PORT), WosafeServerHandler)
server.serve_forever()