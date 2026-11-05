# SeriesTime

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![TMDB API](https://img.shields.io/badge/TMDB-API%20v3-01b4e4?logo=themoviedatabase&logoColor=white)](https://www.themoviedb.org)
[![Live Demo](https://img.shields.io/badge/Demo-Live%20on%20Firebase-039BE5?logo=firebase&logoColor=white)](https://seriestime-data.web.app)
[![Tests](https://img.shields.io/badge/Tests-332%20Passing-brightgreen?logo=checkmarx&logoColor=white)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Live Web Application**: [https://seriestime-data.web.app](https://seriestime-data.web.app)
>
> SeriesTime is a mobile and web application for tracking TV series, viewing watch-time analytics, and unlocking milestone achievements, built with Flutter and Firebase.

---

## Academic Context & Collaboration

This project was developed for the **Design and Implementation of Mobile Applications (DIMA)** course at **Politecnico di Milano**.

The project brief, product concept, and specifications were defined in collaboration with **Bending Spoons**, who provided the initial requirements and architectural guidelines for creating a high-performance, user-centric mobile tracking experience.

---


## Features

* **Discover & Search**:
  * Browse trending TV shows of the week with carousel animations.
  * Search TV shows in real-time across TMDB's global catalog.
  * View comprehensive series details: synopsis, user scores, genres, production networks, and streaming providers.
* **Episode & Season Tracking**:
  * Track watched episodes with interactive checklists per season.
  * Automatic calculation of watch percentages and visual progress bars.
  * Quick links to next-up episodes and last watched episodes.
* **Cast & Crew**:
  * Full cast listings with character portraits and roles.
* **Watch-Time Analytics & Binge Mode**:
  * Real-time calculation of total time spent watching TV shows (split into days, hours, and minutes).
  * **Binge Mode**: Monitor intensive viewing sessions and track continuous watching streaks.
* **Gamification & Milestone Badges**:
  * Multi-tiered badge system (Base, Bronze, Silver, Gold, Diamond) unlocked dynamically based on activity:
    * **Marathoner**: Total cumulative watch hours.
    * **Pure Obsession**: Single-session binge records.
    * **Weekend Warrior**: Weekend viewing activity.
    * **Streak**: Consecutive days of tracking.
    * **The Perfectionist**: Completing 100% of TV series.
    * **The Night Owl**: Late-night viewing hours.
* **Cloud Sync & Authentication**:
  * Google Sign-In via Firebase Authentication.
  * Real-time cloud synchronization with Cloud Firestore for profile data, tracked series, and badges.

---

## Architecture & Project Structure

The codebase is organized using a layered separation of concerns:

```
lib/
├── data/           # App constants, badge definitions, and static data managers
├── models/         # Strongly-typed data models (User, Series, Episode, Season, Actor, etc.)
├── screens/        # UI Views (Explore, My Series, Detail, Binge Mode, Badges, Profile, Settings)
├── services/       # External APIs and business logic (TMDB client, series logic, stats calculation)
├── widgets/        # Reusable UI components (AuthGate, SeasonTile, NotificationBanner)
└── firebase_options.dart # FlutterFire configuration
```

---

## Testing & Code Quality

The repository includes a comprehensive automated test suite with **332 tests** covering both business logic and UI components:

```bash
flutter test
# +332: All tests passed!
```

* **Unit Tests**: Full verification of data models, JSON serialization, badge milestone triggers, and time aggregation logic.
* **Widget & Integration Tests**: Automated UI tests using `fake_cloud_firestore`, `firebase_auth_mocks`, and `network_image_mock`.
* **Zero Analyzer Warnings**: Fully compliant with `flutter_lints` and strict typing rules.

---

## Data & API Attribution

Series metadata, episode guides, cast listings, promotional artwork, and streaming provider information are provided by **The Movie Database (TMDB)**.

* Website: [https://www.themoviedb.org](https://www.themoviedb.org)
* Disclaimer: *This product uses the TMDB API but is not endorsed or certified by TMDB.*

---

## Authors & Collaborators

SeriesTime was collaboratively designed, architected, and implemented by:

* [Vincenzo Picone](https://github.com/vincenzopiconee)
* [Francesco Lo Monaco](https://github.com/fralomonaco)

---


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
