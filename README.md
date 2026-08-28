# EnergyWise SL

**AI-Assisted Household Energy Intelligence for Smarter Electricity Consumption**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.0-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)](https://github.com/DulminiR/energywise-sl)

---

## Overview

EnergyWise SL helps **Sri Lankan households** understand their electricity consumption, estimate costs, simulate usage changes, and receive **personalized AI-powered recommendations** to reduce bills.

**Core Message:** *"Understand your electricity. Spend smarter."*

### Key Problems Solved

- 🤔 **What's costing me the most?** → Appliance-level consumption breakdown
- 💰 **Where can I save?** → Specific, ranked recommendations
- 📊 **How much would I actually save?** → Instant What-If simulations
- 📈 **Am I in a high tariff band?** → Tariff threshold visibility

---

## Features

### 🏠 Household Management
- **Quick Start:** Studio / Standard House / Large House presets (based on real consumption data)
- **Smart Defaults:** Reduce manual data entry with archetype-based appliances
- **Flexible Setup:** Add custom appliances or tune preset values
- **Age Selection:** Standard / Old / Inverter efficiency multipliers

### ⚡ Energy Intelligence
- **Appliance-Level Tracking:** 19 Sri Lankan household appliances in catalog
- **Real-Time Calculation:** See kWh and cost updates instantly
- **Tariff Awareness:** CEB tariff bands 1-5 with threshold visibility
- **Bill Calibration:** Compare estimated vs. actual bill for accuracy

### 🎮 What-If Simulation
- **Experiment Safely:** Adjust appliance usage without committing
- **Instant Feedback:** See bill impact (LKR + %) immediately
- **Top Contributors:** Pinned cards for highest-cost appliances
- **Apply & Advise:** Test scenarios then get AI recommendations

### 🤖 AI Energy Advisor
- **Personalized Analysis:** AI interprets YOUR household data (not generic advice)
- **Ranked Recommendations:** 3-5 actions prioritized by impact
- **Effort Badges:** See if each action is Easy/Medium/Hard
- **Interactive Chat:** Ask follow-up questions in natural language

### 📈 Visual Dashboard
- **Hero Bill Card:** Monthly estimate + kWh badge + tariff band progress
- **Dynamic Insights:** Green (good), Orange (high), personalized to archetype average
- **Interactive Pie Chart:** 5 colors, tap to see which appliance costs what
- **Opportunity Cards:** Top 2 savings opportunities highlighted

---

## Architecture

### Deterministic Core + AI Advisory

```
User Input
    ↓
[Energy Calculation Engine] ← DETERMINISTIC
    ↓
[Tariff Engine] ← DETERMINISTIC  
    ↓
Calculated Results (kWh, Bill, Band)
    ↓
[Gemini AI Advisor] ← ADVISORY LAYER
    ↓
Personalized Recommendations
```

**Key Principle:** AI does NOT calculate electricity or tariff — it interprets results and provides context-aware advice.

### System Components

| Component | Purpose | Technology |
|-----------|---------|-----------|
| **Energy Engine** | Convert appliance usage → monthly kWh | Dart (deterministic) |
| **Tariff Engine** | Convert kWh → LKR bill (CEB tariff) | Dart (deterministic) |
| **Simulation Engine** | What-If scenario calculations | Dart (deterministic) |
| **AI Advisor** | Context-aware recommendations | Gemini API |
| **Appliance Catalog** | 19 appliances + wattage/efficiency | JSON |
| **Mobile App** | UI/UX + state management | Flutter + Provider |

---

## Installation

### Prerequisites

- **Flutter:** 3.47.0+
- **Dart:** 3.13.0+
- **Android SDK:** API 36+ (for mobile)
- **Chrome:** Latest (for web testing)
- **Git:** Latest

### Quick Start

```bash
# Clone repository
git clone https://github.com/DulminiR/energywise-sl.git
cd energywise-sl

# Install dependencies
flutter pub get

# Create .env file with Gemini API key
echo "GEMINI_API_KEY=your_key_here" > .env

# Run on web (development)
flutter run -d chrome

# Run on Android device
flutter run -d <device_id>

# Build APK (production)
flutter build apk --release
```

### Get Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Create API Key"
3. Copy key to `.env` file:
   ```
   GEMINI_API_KEY=your_key_here
   ```

---

## Usage

### User Journey

**1. Welcome** → Choose household archetype (Studio/Standard/Large)  
**2. Tune Appliances** → Adjust quantities, usage hours, age  
**3. Add Bill [Optional]** → Input actual bill for calibration  
**4. Dashboard** → See consumption, costs, and insights  
**5. What-If** → Simulate usage changes  
**6. AI Advisor** → Get ranked recommendations or ask questions  

### Example Scenarios

**Scenario 1: Understand Current Bill**
- Select "Standard House"
- Dashboard shows: 226 kWh, LKR 1,680/month
- Air Conditioner identified as 45% of bill
- Orange warning: "You're in a high tariff band"

**Scenario 2: Explore Savings**
- Go to What-If
- Reduce AC from 6 hrs → 4 hrs/day
- See instant savings: LKR 720/month
- Click "Apply & Get AI Advice"
- AI recommends 3-5 prioritized actions

**Scenario 3: Ask AI**
- Go to AI Advisor Chat
- Ask: "Which appliance costs me most?"
- AI responds with specific appliance + cost breakdown
- Ask: "How can I save LKR 500?"
- AI suggests actionable changes for THIS household

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.47.0 |
| **Language** | Dart 3.13.0 |
| **State Mgmt** | Provider 6.0.0 |
| **Charts** | fl_chart 0.65.0 |
| **HTTP** | http 1.1.0 |
| **Config** | flutter_dotenv 5.1.0 |
| **AI** | Google Gemini API |

### Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  fl_chart: ^0.65.0
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
```

---

## Project Structure

```
energywise_sl/
├── assets/data/
│   ├── appliances.json         (19 Sri Lankan appliances)
│   └── tariff_config.json      (CEB tariff bands May 2026)
│
├── lib/
│   ├── models/                 (Data structures)
│   ├── services/               (Business logic)
│   │   ├── energy_calculation_engine.dart
│   │   ├── tariff_engine.dart
│   │   └── ai_advisor_service_gemini.dart
│   ├── screens/                (7 app screens)
│   ├── widgets/                (Reusable UI components)
│   └── main.dart
│
├── test/                       (Unit tests)
├── pubspec.yaml                (Dependencies)
├── .env                        (API keys - not in repo)
└── .gitignore
```

---

## Calculations

### Energy Calculation

**Formula:**
```
Monthly kWh = (Wattage × Usage Pattern × Duty Cycle × Age Multiplier × Quantity) / 1000
```

**Usage Patterns:**
- **Always-On:** Wattage × 24h × 30 days (e.g., Refrigerator)
- **Daily Hours:** Wattage × hours × 30 days (e.g., Fan)
- **Weekly Hours:** Wattage × (4 weeks/month) × hours (e.g., Cooker)
- **Weekly Cycles:** Wattage × cycles × hours_per_cycle (e.g., Washing Machine)

**Age Multipliers:**
- Standard: 1.0
- Old: 1.15 (15% less efficient)
- Inverter: 0.85 (15% more efficient)

### Tariff Calculation

**Sri Lanka CEB Tariff (May 2026):**

| Band | kWh Range | Rate/kWh |
|------|-----------|----------|
| 1 | 0-30 | LKR 3.86 |
| 2 | 31-60 | LKR 4.48 |
| 3 | 61-90 | LKR 5.23 |
| 4 | 91-120 | LKR 6.10 |
| 5 | 120+ | LKR 6.98 |

**Formula:**
```
Base Cost = kWh × Band Rate
SSCL = Base Cost × 0.0475
Fixed Charge = LKR 300
Total Bill = Base Cost + SSCL + Fixed Charge
```

---

## Testing

### Run Tests

```bash
flutter test
```

### Test Coverage

- ✅ **Energy Calculation Engine:** All scenarios passing
- ✅ **Tariff Engine:** All bands + edge cases passing
- ✅ **AI Advisor Service:** Gemini integration verified

### Manual Testing

```bash
# Test calculations
flutter run -d chrome
→ Select archetype → Verify kWh matches manual calculation

# Test What-If
flutter run -d chrome
→ What-If → Adjust AC → Verify bill updates instantly

# Test AI
flutter run -d chrome
→ AI Advisor → Ask "How can I save?" → Verify response is contextual
```

---

## Known Limitations

### Current Prototype

- 📝 **Manual Data Entry** — No smart meter integration
- 📊 **Estimation-Based** — Uses wattage + usage estimates, not live data
- 🔧 **19 Appliances** — Limited catalog (custom input available)
- 💾 **No Cloud Sync** — Data lost when app closes
- 🏦 **CEB Only** — Single utility, Colombo area tariff

### AI Limitations

- Uses free tier Gemini (not specialized model)
- No real-time model updates
- Generic advice adapted via prompt (not trained on Sri Lankan data)

---

## Future Roadmap

### Phase 2: Accuracy
- [ ] Smart meter integration (CEB API)
- [ ] Historical bill tracking
- [ ] Real-time tariff updates
- [ ] Expanded appliance database (100+)

### Phase 3: Intelligence
- [ ] Machine learning for consumption prediction
- [ ] Seasonal adjustments
- [ ] Household learning profiles

### Phase 4: Platform
- [ ] User accounts + cloud sync
- [ ] Utility partnerships (white-label for CEB)
- [ ] Social features (compare with similar households)

---

## Contributing

This is an AI Launch Pad 2026 prototype. Contributions welcome!

1. Fork repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m "Add feature"`
4. Push: `git push origin feature/your-feature`
5. Open Pull Request

---

## License

MIT License — see [LICENSE](LICENSE) file

---

## Author

**Dulmini R.**  
AI Launch Pad 2026 Participant

---

## Contact & Links

- 📧 **GitHub:** [DulminiR/energywise-sl](https://github.com/DulminiR/energywise-sl)
- 📱 **Try Prototype:** Clone & run `flutter run -d chrome`

---

## Acknowledgments

- **Research:** Real Sri Lankan household consumption data
- **Technology:** Flutter, Dart, Google Gemini API
- **Design:** Minimalist sustainability-focused UX
- **Context:** Sri Lanka CEB tariff structure, household appliances

---

**Last Updated:** August 2026  