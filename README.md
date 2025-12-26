# 🚗 Route-Roots: The Trust-Based Carpool Network

> **Winner/Participant of Dev Duel Hackathon 2025**

**Route-Roots** is a geospatial carpooling platform designed exclusively for verified organizations (e.g., Universities, Tech Parks). It addresses the critical "Trust Deficit" in public carpooling by restricting access to verified email domains and using advanced route-matching algorithms to connect drivers and passengers securely.

---

## 🌟 Key Features
* **🔒 Domain-Locked Auth:** Access is strictly restricted to verified organization emails (`@vit.edu`, `@infosys.com`) using Supabase Auth.
* **📍 Intelligent Route Matching:** Uses **PostGIS** spatial queries to match passengers not just to a driver's *start* point, but to any point along their *entire route path* (within a 5km buffer).
* **🗺️ Interactive Mapping:** Custom Location Picker and Polyline visualization using OpenStreetMap (No Paid Google APIs).
* **💬 Instant Connect:** Direct WhatsApp integration for seamless ride coordination.
* **⚡ Real-Time Optimization:** Calculates ride details (Seats, Time, Price) to maximize vehicle occupancy.

---

## 🛠️ Tech Stack
* **Frontend:** Flutter (Dart), `flutter_map`, `latlong2`.
* **Backend:** Python (FastAPI), SQLAlchemy.
* **Database:** PostgreSQL + **PostGIS Extension** (Hosted on Supabase).
* **Geospatial Services:** OpenRouteService (Routing), Nominatim (Geocoding).

---

## ⚠️ Assumptions & Limitations
* **Organization Restriction:** The current build strictly enforces login for users with `@vit.edu` or `@infosys.com` email domains only. Public Gmail/Outlook accounts are blocked by design to ensure safety.
* **Geographic Scope:** The routing engine is currently optimized for the Pune region, though the map supports global coordinates.
* **Route Deviation:** The matching algorithm assumes a passenger is a valid match if their pickup and drop-off points are within a **5km radius** of the driver's route.
* **Platform:** The application is currently optimized and tested for **Android** devices.

---

## 🚀 Setup Instructions

### Prerequisites
* **Flutter SDK** (3.0+)
* **Python** (3.9+)
* **Android Studio** (for Android SDK tools)
* **Git**

### 1. Clone the Repository
```bash
git clone [https://github.com/YOUR_USERNAME/route-roots.git](https://github.com/YOUR_USERNAME/route-roots.git)
cd route-roots

2. Backend Setup
The backend powers the routing logic and database connections.

Bash

cd backend

# Create a virtual environment
python -m venv venv

# Activate Virtual Env (Windows)
venv\Scripts\activate
# Activate Virtual Env (Mac/Linux)
source venv/bin/activate

# Install Dependencies
pip install -r requirements.txt

# Start the Server (Replace 0.0.0.0 with specific host if needed)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

3. Frontend Setup
The mobile application built with Flutter.

Bash

cd ../route_roots_app

# Install Flutter dependencies
flutter pub get

# IMPORTANT: Configure Networking
# Open lib/constants.dart and replace '127.0.0.1' with your Laptop's IPv4 Address
# const String backendUrl = "[http://192.168.](http://192.168.)X.X:8000";


4. Build & Run
Connect your Android device via USB or start an emulator.

Bash

flutter run

📱 User Guide
1. Registration & Login
Open the app.

Enter your Organization Email (e.g., student@vit.edu).

Enter your Phone Number (with country code, e.g., 919876543210).

Note: If you are a new user, the system automatically registers you.

2. Posting a Ride (For Drivers)
Go to the "Offer Ride" tab.

Enter Start Point and Destination (or use the map picker).

Set the Departure Time, Available Seats, and Price.

Click "Post My Ride". The app will calculate the optimal route and store it.

3. Finding a Ride (For Passengers)
Go to the "Find Ride" tab.

Enter your Pickup and Drop locations.

Click "Search Rides".

The system will display a list of drivers passing through your route.

View details (Driver Name, Price, Time) and click the WhatsApp Icon to contact them directly.

🤝 Contributing
This project was built for a hackathon, but contributions are welcome! Please fork the repository and submit a pull request.