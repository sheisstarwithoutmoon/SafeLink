# Safe Ride – Flutter Frontend

Safe Ride is a Flutter-based mobile application developed as part of an **IoT Accident Alert System**.  
This repository contains the **frontend mobile app**, which communicates with IoT hardware via Bluetooth and a backend server to trigger emergency alerts and notify registered emergency contacts.

---

## 🎥 Demo Video

Watch the working demo of the application here:  
👉 **[Demo Video](https://drive.google.com/file/d/1W5foQydEXs2tQ-Oh507MB0DTkoLOJtFr/view?usp=sharing)**

---

## 🔗 Backend Repository

The backend server for this project is available here:  
👉 **[Safe Ride Backend Repository](https://github.com/sheisstarwithoutmoon/saferide-backend)**

---

## 📌 Overview

The Flutter application serves as the user-facing layer of the system. It receives accident signals from the IoT hardware module, manages emergency contacts, displays alert countdowns, and communicates with the backend for notification delivery and alert history tracking.

---

## ✨ Features

- Bluetooth communication with Arduino (HC-05)
- Automatic and manual accident alert triggering
- Countdown timer to cancel false alerts
- Emergency contact management
- OTP-based user authentication
- Push notifications using Firebase Cloud Messaging (FCM)
- Alert and notification history
- Clean, minimal, and responsive UI

---

## 🛠️ Tech Stack

### Mobile Framework
- Flutter (Dart)

### Authentication & Notifications
- Firebase Authentication (OTP-based)
- Firebase Cloud Messaging (FCM)

### Communication
- REST APIs
- Socket.IO (real-time updates)
- Bluetooth communication with IoT device
- Google Maps integration (for location display)

### State & Storage
- Local storage for session and user settings
- Service-based architecture for API and socket handling

---

## 🔧 Setup & Installation

### Clone the Repository
```bash
git clone https://github.com/sheisstarwithoutmoon/SafeLink
