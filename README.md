# Code Sync Application

[![GitHub Repo](https://img.shields.io/badge/github-zaibten-blue)](https://github.com/zaibten)

A full-stack **Code Sync Application** built with **Flutter**, **Node.js**, and **Admin Panel** in Node.js. This app allows users to write, generate, copy, and save code with real-time error detection.  

---

## Project Overview

This project consists of three main components:

1. **Flutter Application (Frontend)**  
   - Users can write or paste code in a text editor.
   - Copy or save the generated code locally.
   - View real-time code outputs.
   - Professional, responsive UI with scrollable input/output sections.

2. **Node.js Server (Backend)**  
   - Handles API requests from the Flutter application.
   - Performs error detection on submitted code.
   - Provides data for the admin panel and frontend.

3. **Admin Panel (Node.js / Web)**  
   - Admin can monitor users and their generated code.
   - Manage app data and view activity logs.
   - Built using Node.js, Express, and a simple web interface.

---

## Features

- User authentication and profile management.
- Code editor with:
  - Multi-line input
  - Scrollable text area
  - Copy and Save code functionality
- Real-time error detection for code.
- Full-width loader animation while generating code.
- Admin panel to monitor users and code submissions.
- Professional and responsive UI for both mobile and web.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter |
| Backend | Node.js, Express |
| Admin Panel | Node.js, Express, HTML/CSS/JS |
| Storage | Mongo DB & File system (for saved code) |
| State Management | Provider (Flutter) |

---
