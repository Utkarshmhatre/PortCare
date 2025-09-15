

🏥 PortCare – Smart Healthcare Scheduling App

PortCare is a Flutter + Firebase-based healthcare app designed to simplify medical access. It allows patients to book appointments, check booth availability, upload documents, track health metrics, view doctor ratings, and monitor fitness – all in one secure and user-friendly platform.

✨ Features

📅 Appointment Scheduling – Book, reschedule, or cancel appointments easily.

🏥 Booth Availability – Check real-time booth and doctor availability.

📂 Medical Document Upload – Securely upload and store health documents.

📊 Health Tracking & Visualization – Track consultations, prescriptions, and metrics.

⭐ Doctor Ratings & Reviews – View ratings and availability before booking.

🏃 Fitness Tracking – Step counter and health tracking using phone sensors.

🛠️ Tech Stack

Frontend: Flutter (Dart)

Backend: Firebase (Authentication, Firestore, Storage, Realtime DB)

Hosting (optional): Firebase Hosting

📦 Installation
Prerequisites

Flutter SDK installed → Install Flutter

Firebase project setup (Free Tier) → Firebase Console

Android Studio / VS Code

Steps

Clone the repository:

git clone https://github.com/your-username/portcare.git
cd portcare


Install dependencies:

flutter pub get


Connect Firebase:

Create a Firebase project.

Enable Authentication, Firestore, Storage, Realtime Database.

Download google-services.json (for Android) and GoogleService-Info.plist (for iOS).

Place them in the respective /android/app/ and /ios/Runner/ folders.

Run the app:

flutter run

🔐 Data & Privacy

Uses Firebase Authentication for secure logins.

Health data stored in Firestore/Realtime DB with Firebase rules applied.

All medical documents encrypted in Firebase Storage.

🚀 Future Enhancements

AI-based health suggestions.

Integration with wearables.

Insurance & pharmacy integration.

🤝 Contributing

Pull requests are welcome! Please open an issue first to discuss proposed changes.

📜 License

This project is licensed under the MIT License.
