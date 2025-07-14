# 🌿 RecycloVision Frontend (Flutter)

This is the mobile frontend of **RecycloVision**, a smart recycling assistant powered by computer vision and real-world carbon impact data. Built using Flutter, the app offers a smooth and engaging user experience with animated UI, scanning functionality, subtype correction, and recycling progress tracking.

---

## 🎯 Features

- ✨ **Animated Coinbase-style Welcome Screen**  
  - Rocket-style logo animation  
  - Staggered fade-in for text/buttons using `flutter_animate`

- 📷 **Image Upload & Scan**  
  - Scan button uploads images to the backend for classification  
  - Displays predicted material and carbon data

- 📊 **Subtype Dropdown Selector**  
  - For materials like plastic, allows users to choose a more specific subtype (e.g., HDPE, LDPE)

- 🧠 **Misclassification Reporter**  
  - "Report Error" button lets users correct wrong predictions, which are sent to the backend for retraining

- 🔄 **Dark Mode with Modern UI Design**  
  - Consistent styling across pages  
  - Inspired by Coinbase-style color palette and animations

- 🕹️ **Mini-Game Recycling Tracker**  
  - Tracks how many items a user recycles  
  - Every 10 recycled items unlocks a mini reward

---

## 🧱 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: `setState` + local logic
- **UI Animation**: [`flutter_animate`](https://pub.dev/packages/flutter_animate)
- **HTTP Communication**: `http` package
- **Platform**: Cross-platform (iOS + Android)

---

## 📁 Key Files

frontend/
├── lib/
│ ├── main.dart # Welcome animation and main nav routing
│ ├── scan_page.dart # Scan UI with image upload, subtype selection, and carbon data
│ ├── result_page.dart # Displays material prediction and score
│ ├── history_page.dart # Tracks past scans and recycling streaks
│ ├── misclassification.dart # Report correction form
│ └── sidebar.dart # Modern sidebar navigation for all pages
├── assets/
│ └── icons, animations, images used in UI
├── pubspec.yaml # Flutter dependencies
└── README.md # You're here!

yaml
Copy code

---

## 🚀 Getting Started

### 1. 📦 Install Flutter

If you haven't already:

```bash
https://docs.flutter.dev/get-started/install
2. 🧱 Install Dependencies
bash
Copy code
flutter pub get
3. ▶️ Run the App
Ensure your backend is running on localhost:5001 (or the appropriate IP if testing on a physical device):

bash
Copy code
flutter run
To run on a specific device:

bash
Copy code
flutter run -d chrome
flutter run -d ios
flutter run -d android
🔗 Backend API Dependencies
The frontend communicates with the following Flask endpoints:

POST /detect – Uploads image and receives material prediction

POST /subtype – Sends selected subtype to retrieve updated carbon info

POST /report_misclassification – Sends corrected material label + image path

Make sure your Flask server is running and accessible to the app (e.g., use local IP instead of localhost when running on mobile).

📦 Deployment Tips
Replace local URLs with production URLs when deploying

Add environment configuration for backend endpoints

Use flutter build apk or flutter build ios for release builds

🤝 Contributing
Open a PR or issue if you’d like to improve the UI, suggest features, or contribute to sustainability efforts through code 💚
