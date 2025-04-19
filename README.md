# 🌼 Pregnancy Monitoring App

> **A Digital Lifeline for Expecting Mothers. Powered by Technology, Guided by Compassion.**

---

## 👋 Overview

Pregnancy is a journey, and every journey deserves the right support. In many developing regions, including Ghana, maternal health risks remain alarmingly high due to **delayed antenatal care**, **lack of early detection**, and **inadequate monitoring**.

The **Pregnancy Monitoring App** is a **cross-platform, role-based digital health solution** designed to **monitor**, **educate**, and **connect** pregnant women, doctors, relatives, and administrators — ensuring a safer pregnancy experience for every mother.

Built with **Flutter**, **NestJS**, and **MongoDB**, our solution bridges the gap between healthcare providers and pregnant women through real-time vitals tracking, live chat, AI assistance, and data-driven risk assessment.

---

## 📌 Why It Matters

> "12% of maternal deaths in Ghana are pregnancy-related."

A study at Mamprobi Hospital revealed:
- 📈 51.8% of women had complications
- 🕑 Most began antenatal care late
- 🧠 Many lacked key pregnancy knowledge

Our app is **research-informed**, addressing these challenges with:
- 📅 Early engagement & appointment scheduling
- 📈 Smart vitals tracking & predictions
- 🧠 Pregnancy tips & AI-based Q&A

---

## 🧑‍⚕️ Key User Roles & Features

### 👩 Pregnant Woman
- 📝 OTP-based registration and secure login
- 📅 Schedule, reschedule or cancel appointments
- 🧮 Calculate pregnancy weeks (LMP-based)
- 💾 Record vitals (weight, blood pressure, protein in urine, etc.)
- 📈 View historical health data and trends
- 💬 Real-time chat with doctor via WebSockets
- 🧠 Get weekly pregnancy tips and guidance
- 🤖 Ask an AI chatbot for health-related queries
- 👨‍👩‍👧 Add a relative for shared support & monitoring

---

### 👨‍⚕️ Doctor
- 🧑‍⚕️ Manage and view patient profiles
- 💊 Create & view prescriptions
- 🗓 Manage appointments
- 📈 Access vitals and health trends of patients
- 🛑 View complication risk levels (Low / Medium / High)
- 💬 Chat live with patients

---

### 👨‍👩 Relative
- 🧭 Track the health status of a linked pregnant woman
- ⚠️ Receive alerts on complications or emergencies

---

### 🧑‍💼 Admin
- 🧑‍💻 Manage platform users
- 📊 Access overview of users and system health

---

## 🔐 Authentication & Security

- 🔒 Role-Based Access Control (RBAC)
- 🔐 JWT for secure sessions
- 📧 OTP verification on signup
- 🧂 Hashed passwords & secure storage
- 🔑 Forgot password with temporary email-based recovery

---

## ⚙️ Tech Stack

| Layer       | Technology        |
|-------------|-------------------|
| Frontend    | Flutter            |
| Backend     | NestJS             |
| Database    | MongoDB            |
| Real-Time   | WebSockets         |
| AI Assistant| NLP / GPT-based Chatbot |
| Auth        | JWT + Email OTP    |

---

## 🧠 AI Chatbot

Need answers on-the-go? Our built-in AI chatbot answers questions related to pregnancy, complications, health tips, and lifestyle changes — helping users make informed decisions at any time.

---

## 📊 Risk Scoring Algorithm

The backend uses a custom logic based on:
- Weeks of pregnancy
- Vitals data
- Symptom entries

To assign:
- ✅ Low Risk
- ⚠️ Medium Risk
- 🚨 High Risk

This risk visibility empowers **doctors** to act early and **women** to stay informed.

---

## 🛠 Planned Features

- 📲 Push notifications (reminders & alerts)
- 🧠 Smarter AI model with multilingual support
- 📉 Doctor dashboards with analytics
- 📡 Integration with wearable sensors
- 🏥 Hospital-side appointment calendar view

---
## 🧪 API Documentation

If you're interested in exploring how the backend works or want to test the available API endpoints directly, you can check out our **Swagger UI**.

👉 [**Swagger UI – API Docs**](http://localhost:3100/api-docs)

### What is Swagger UI?

Swagger UI is an interactive documentation tool that allows developers and testers to:
- 📖 View all available API endpoints with descriptions
- 🧪 Test endpoints directly from the browser
- 🧾 See required parameters and example responses
- 🔐 Try out authenticated routes with ease

This helps ensure better understanding, faster debugging, and smoother collaboration between frontend and backend teams.

> **Note**: Check out the SwaggerUI folder in this repo to have a view of the created endpoints!


## 🤝 Contributing

We welcome contributions!  
To get started:
1. Fork this repo
2. Create a new branch (`git checkout -b feature-name`)
3. Make your changes
4. Submit a Pull Request
---

## 🙋‍♂️ About the Developer

**👤 Nathaniel Adika**  
📍 Accra, Ghana  
📧 [nathanieladikajnr@gmail.com](mailto:nathanieladikajnr@gmail.com)  
🔗 [LinkedIn](https://www.linkedin.com/in/nathaniel-adika-20a30226a/)  
🐙 [GitHub](https://github.com/AdikaNathaniel)

---

> _“Empowering maternal health through data, dialogue, and dignity.”_

