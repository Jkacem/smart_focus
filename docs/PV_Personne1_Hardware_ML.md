# 🔧 PV Personne 1 – Hardware, Firmware & ML Vision

**Projet** : Smart Focus & Life Assistant  
**Responsable** : Personne 1  
**Date** : 06 Février 2026  

---

## 🎯 Périmètre de Responsabilité

Personne 1 est responsable de **toute la partie hardware et ML vision** du projet :

| Domaine | Description |
|---------|-------------|
| **Hardware ESP32** | Configuration ESP32-CAM, capteurs, écran TFT, LEDs |
| **Firmware** | Code embarqué, communication WiFi/HTTP/MQTT |
| **Boîtier 3D** | Conception et impression 3D du boîtier physique |
| **ML Vision (Serveur)** | Modèles détection posture, fatigue, visage |

---

## 1️⃣ Hardware ESP32

### 1.1 Composants à Intégrer

| Composant | Modèle | Rôle |
|-----------|--------|------|
| **Microcontrôleur** | ESP32-CAM | Caméra + WiFi + traitement |
| **Capteur cardiaque** | MAX30102 | Rythme cardiaque, SpO2 |
| **Écran** | TFT ILI9341 2.4" | Affichage score, alertes |
| **LEDs** | WS2812B (NeoPixel) | Anneau RGB feedback visuel |
| **Audio sortie** | MAX98357A I2S | Haut-parleur |
| **Audio entrée** | INMP441 I2S | Microphone |
| **Capteur pression** | Optionnel | Détection présence |

### 1.2 Schéma de Câblage

```
┌─────────────────────────────────────────────────────┐
│                    ESP32-CAM                        │
├─────────────────────────────────────────────────────┤
│  GPIO 21 (SDA) ──────> MAX30102                    │
│  GPIO 22 (SCL) ──────> MAX30102                    │
│  GPIO 18 (SCK) ──────> TFT ILI9341                 │
│  GPIO 23 (MOSI) ─────> TFT ILI9341                 │
│  GPIO 5 (CS) ────────> TFT ILI9341                 │
│  GPIO 4 (DATA) ──────> WS2812B (LEDs)              │
│  GPIO 25 (BCLK) ─────> MAX98357A (Audio)           │
│  GPIO 26 (LRC) ──────> MAX98357A                   │
│  GPIO 22 (DIN) ──────> MAX98357A                   │
└─────────────────────────────────────────────────────┘
```

### 1.3 Livrables Hardware

- [ ] Sélection et achat des composants
- [ ] Schéma de câblage complet
- [ ] Prototype sur breadboard
- [ ] Tests individuels de chaque capteur
- [ ] Assemblage final sur PCB/perfboard
- [ ] Test d'intégration complet

---

## 2️⃣ Firmware ESP32

### 2.1 Technologies

| Technologie | Usage |
|-------------|-------|
| **Arduino IDE / PlatformIO** | Environnement de développement |
| **ESP32-CAM Library** | Capture images |
| **TFT_eSPI** | Affichage écran |
| **FastLED** | Contrôle LEDs RGB |
| **I2S** | Audio entrée/sortie |
| **WiFiClient** | Communication HTTP |
| **PubSubClient** | Communication MQTT (optionnel) |

### 2.2 Fonctionnalités Firmware

#### Capture & Envoi Images
```cpp
// Pseudo-code structure
void captureAndSendImage() {
    camera_fb_t *fb = esp_camera_fb_get();
    // Envoyer image au serveur via HTTP POST
    httpClient.POST("/api/ml/analyze", fb->buf, fb->len);
    esp_camera_fb_return(fb);
}
```

#### Lecture Capteurs
```cpp
// Pseudo-code structure
void readSensors() {
    SensorData data;
    data.heart_rate = max30102.getHeartRate();
    data.spo2 = max30102.getSpO2();
    data.timestamp = getTimestamp();
    sendToBackend(data);
}
```

#### Affichage & Feedback
```cpp
// Afficher score sur écran TFT
void displayScore(int score) {
    tft.drawCircle(120, 120, 80, scoreColor(score));
    tft.setCursor(100, 110);
    tft.print(score);
}

// Feedback LED selon état
void setFeedbackLED(FocusState state) {
    switch(state) {
        case FOCUSED: leds.fill(GREEN); break;
        case DISTRACTED: leds.fill(ORANGE); break;
        case FATIGUE: leds.fill(RED); break;
    }
}
```

### 2.3 Communication avec Backend

| Protocole | Endpoint | Usage |
|-----------|----------|-------|
| **HTTP POST** | `/api/ml/image` | Envoi image pour analyse |
| **HTTP POST** | `/api/sensors/data` | Envoi données capteurs |
| **HTTP GET** | `/api/focus/score` | Récupérer score calculé |
| **WebSocket** | `/ws/device` | Communication temps réel |

### 2.4 Format de Données (Contrat API)

```json
// Données envoyées par ESP32
{
  "device_id": "esp32_001",
  "timestamp": "2026-02-06T10:30:00Z",
  "heart_rate": 72,
  "spo2": 98,
  "sensor_status": {
    "camera": true,
    "heart_sensor": true,
    "microphone": true
  }
}

// Données reçues du serveur
{
  "focus_score": 85,
  "posture_ok": true,
  "fatigue_level": 3,
  "alerts": ["Mauvaise posture détectée"],
  "led_color": "#00FF00"
}
```

### 2.5 Livrables Firmware

- [ ] Configuration ESP32-CAM (capture images)
- [ ] Intégration MAX30102 (rythme cardiaque)
- [ ] Driver écran TFT ILI9341
- [ ] Contrôle LEDs WS2812B
- [ ] Communication HTTP avec backend
- [ ] Gestion WiFi (connexion, reconnexion)
- [ ] Mode économie d'énergie
- [ ] Gestion des erreurs et logs

---

## 3️⃣ Boîtier 3D

### 3.1 Spécifications

| Caractéristique | Valeur |
|-----------------|--------|
| **Dimensions** | H: 25-30 cm, L: 15 cm |
| **Forme** | Cylindre ou ovale arrondi |
| **Matériau** | PLA/PETG (impression 3D) |
| **Couleurs** | Blanc, gris, bleu clair |
| **Alimentation** | USB-C 5V |

### 3.2 Conception

- [ ] Modélisation 3D (Fusion 360 / Blender)
- [ ] Emplacements pour caméra, écran, LEDs
- [ ] Ouvertures ventilation
- [ ] Support interne pour composants
- [ ] Accès port USB-C
- [ ] Prototype impression 3D
- [ ] Ajustements et version finale

---

## 4️⃣ ML Vision (Côté Serveur)

### 4.1 Technologies ML

| Technologie | Usage |
|-------------|-------|
| **Python 3.11+** | Langage principal |
| **OpenCV** | Traitement d'images |
| **MediaPipe** | Détection pose, visage |
| **TensorFlow/PyTorch** | Modèles personnalisés |
| **FastAPI** | API endpoints ML |

### 4.2 Modèles à Développer

#### Détection Posture
| Aspect | Détail |
|--------|--------|
| **Input** | Image 640x480 de l'ESP32-CAM |
| **Technologie** | MediaPipe Pose |
| **Output** | `posture_ok: boolean`, `angle_tete: float` |
| **Alertes** | Dos courbé, tête basse, absence |

```python
# Pseudo-code détection posture
def detect_posture(image):
    results = mp_pose.process(image)
    if results.pose_landmarks:
        shoulder_angle = calculate_shoulder_angle(results)
        head_position = calculate_head_position(results)
        return {
            "posture_ok": shoulder_angle > 160,
            "head_angle": head_position,
            "alerts": generate_alerts(shoulder_angle, head_position)
        }
```

#### Détection Fatigue
| Aspect | Détail |
|--------|--------|
| **Input** | Image visage |
| **Technologie** | MediaPipe Face Mesh + Custom CNN |
| **Output** | `fatigue_level: 1-10`, `eyes_closed: boolean` |
| **Détections** | Bâillements, yeux fermés, clignements fréquents |

```python
# Pseudo-code détection fatigue
def detect_fatigue(image):
    face_mesh = mp_face_mesh.process(image)
    if face_mesh.multi_face_landmarks:
        ear = calculate_eye_aspect_ratio(face_mesh)
        mar = calculate_mouth_aspect_ratio(face_mesh)
        blink_rate = count_blinks(ear)
        yawn_detected = mar > YAWN_THRESHOLD
        
        fatigue_level = calculate_fatigue_score(ear, mar, blink_rate)
        return {
            "fatigue_level": fatigue_level,
            "eyes_closed": ear < EAR_THRESHOLD,
            "yawn_detected": yawn_detected,
            "blink_rate": blink_rate
        }
```

#### Détection Visage & Regard
| Aspect | Détail |
|--------|--------|
| **Input** | Image |
| **Technologie** | MediaPipe Face Detection |
| **Output** | `face_detected: boolean`, `looking_at_screen: boolean` |
| **Usage** | Détecter si l'utilisateur est présent et concentré |

#### Analyse Mouvement/Distraction
| Aspect | Détail |
|--------|--------|
| **Input** | Séquence d'images |
| **Technologie** | OpenCV motion detection |
| **Output** | `movement_level: float`, `distracted: boolean` |
| **Usage** | Détecter agitation, absence prolongée |

### 4.3 API Endpoints ML

```python
# Endpoints à développer
@app.post("/api/ml/analyze")
async def analyze_image(image: UploadFile) -> AnalysisResult:
    """Analyse complète : posture + fatigue + visage"""

@app.post("/api/ml/posture")
async def analyze_posture(image: UploadFile) -> PostureResult:
    """Analyse posture uniquement"""

@app.post("/api/ml/fatigue")
async def analyze_fatigue(image: UploadFile) -> FatigueResult:
    """Analyse fatigue uniquement"""

@app.post("/api/ml/focus-score")
async def calculate_focus_score(data: SensorData) -> FocusScore:
    """Calcul score de concentration global"""
```

### 4.4 Livrables ML

- [ ] Setup environnement Python + dépendances
- [ ] Modèle détection posture (MediaPipe)
- [ ] Modèle détection fatigue (yeux, bâillements)
- [ ] Modèle détection visage et regard
- [ ] Analyse mouvement/distraction
- [ ] API endpoints ML fonctionnels
- [ ] Calcul score de focus global
- [ ] Tests de performance (latence < 500ms)
- [ ] Optimisation des modèles

---

## 📅 Planning Personnel

### Phase 1 : Fondations (Semaines 1-3)
| Semaine | Tâches |
|---------|--------|
| **S1** | Setup ESP32-CAM, tests caméra, configuration WiFi |
| **S2** | Intégration capteurs (MAX30102), écran TFT, LEDs |
| **S3** | Communication HTTP avec backend, format JSON |

### Phase 2 : ML Vision (Semaines 4-7)
| Semaine | Tâches |
|---------|--------|
| **S4** | Setup Python ML, MediaPipe, OpenCV |
| **S5** | Modèle détection posture |
| **S6** | Modèle détection fatigue (yeux, bâillements) |
| **S7** | Modèle détection visage, calcul score focus |

### Phase 3 : Boîtier & Intégration (Semaines 8-11)
| Semaine | Tâches |
|---------|--------|
| **S8** | Conception 3D du boîtier |
| **S9** | Impression 3D, ajustements |
| **S10** | Assemblage complet hardware |
| **S11** | Tests intégration avec backend Personne 2 |

### Phase 4 : Finition (Semaines 12-14)
| Semaine | Tâches |
|---------|--------|
| **S12** | Optimisation firmware, gestion erreurs |
| **S13** | Tests end-to-end avec application |
| **S14** | Documentation, préparation démo |

---

## 📚 Formations Recommandées

| Formation | Durée | Lien |
|-----------|-------|------|
| ESP32-CAM Complete Guide | 3h | [RandomNerdTutorials](https://randomnerdtutorials.com/esp32-cam/) |
| MediaPipe Pose Detection | 2h | [Google AI](https://mediapipe.dev) |
| OpenCV Python Tutorial | 4h | [OpenCV Docs](https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html) |
| Fusion 360 pour Impression 3D | 3h | [Autodesk](https://www.autodesk.com/products/fusion-360) |

---

## ✅ Critères de Validation

| Critère | Validation |
|---------|------------|
| ESP32-CAM capture images | Images claires envoyées au serveur |
| Capteurs fonctionnels | Données heart rate, SpO2 correctes |
| Écran TFT affiche score | Interface claire et lisible |
| LEDs feedback couleurs | Vert/Orange/Rouge selon état |
| ML posture précis | Détection correcte > 85% |
| ML fatigue précis | Détection yeux fermés > 90% |
| Latence ML < 500ms | Temps réel acceptable |
| Boîtier fonctionnel | Tous composants intégrés |

---

## 🔗 Intégration avec Personne 2

| Point d'intégration | Responsable | Description |
|---------------------|-------------|-------------|
| **Contrat API** | Les deux | Format JSON commun pour données |
| **Endpoints réception** | Personne 2 | Backend reçoit images/données |
| **Endpoints ML** | Personne 1 | API retourne résultats analyse |
| **Mock hardware** | Les deux | Simuler données pour dev parallèle |

---

## 📝 Notes

- Réunion hebdomadaire avec Personne 2 pour synchronisation
- Utiliser GitHub avec branches feature
- Documenter les schémas de câblage
- Tester chaque composant individuellement avant intégration
- Prévoir composants de rechange

---

**Signature** : _________________________  
**Date** : _________________________
