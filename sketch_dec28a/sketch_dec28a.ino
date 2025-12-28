#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

/* ================= WIFI ================= */
const char* ssid = "!-";
const char* password = "Allah11!!";

/* ================= SUPABASE ================= */
const char* supabaseUrl =
"https://ebfvxcohvlpkdztafzmy.supabase.co/rest/v1/led_status?id=eq.1&select=led1,led2";

const char* supabaseKey =
"sb_publishable_RmSMz2pOTeq4_Kdm-bScpQ_21yljDUs";

/* ================= LED PINLER ================= */
#define LED1_RED   25
#define LED1_BLUE  26
#define LED2_RED   27
#define LED2_BLUE  14

/* ================= LDR ================= */
// A0 → Analog
#define LDR_ANALOG_PIN 34
// D0 → Digital
#define LDR_DIGITAL_PIN 23

/* ================= LED DURUM ================= */
String lastLed1 = "off";
String lastLed2 = "off";

/* ================= LED AYAR (ORTAK ANOT) ================= */
void setLed(int redPin, int bluePin, const String& color) {
  Serial.print("[LED] Ayar -> ");
  Serial.println(color);

  if (color == "red") {
    digitalWrite(redPin, LOW);   // LOW -> LED yanar
    digitalWrite(bluePin, HIGH); // HIGH -> LED söner
  } 
  else if (color == "blue") {
    digitalWrite(redPin, HIGH);
    digitalWrite(bluePin, LOW);
  } 
  else {
    digitalWrite(redPin, HIGH); // Tümünü kapat
    digitalWrite(bluePin, HIGH);
  }
}

/* ================= TUM LED KAPAT (ORTAK ANOT) ================= */
void turnOffAllLeds() {
  digitalWrite(LED1_RED, HIGH);
  digitalWrite(LED1_BLUE, HIGH);
  digitalWrite(LED2_RED, HIGH);
  digitalWrite(LED2_BLUE, HIGH);

  lastLed1 = "off";
  lastLed2 = "off";

  Serial.println("[LED] Tum LED'ler KAPALI");
}

/* ================= WIFI BAGLANTI ================= */
void ensureWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  Serial.println("\n[WiFi] Baglaniyor...");
  WiFi.begin(ssid, password);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] BAGLANDI ✅");
    Serial.print("[WiFi] IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WiFi] BAGLANAMADI ❌");
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n=== ESP32 BASLADI ===");

  pinMode(LED1_RED, OUTPUT);
  pinMode(LED1_BLUE, OUTPUT);
  pinMode(LED2_RED, OUTPUT);
  pinMode(LED2_BLUE, OUTPUT);

  pinMode(LDR_ANALOG_PIN, INPUT);
  pinMode(LDR_DIGITAL_PIN, INPUT);

  turnOffAllLeds();
  ensureWiFi();
}

/* ================= LOOP ================= */
void loop() {
  ensureWiFi();

  /* -------- LDR DIGITAL (ANA KARAR) -------- */
  int ldrDigital = digitalRead(LDR_DIGITAL_PIN);

  Serial.print("\n[LDR-D0] Durum: ");
  Serial.println(ldrDigital == HIGH ? "KARANLIK 🌑" : "AYDINLIK 🌞");

  // Karanliksa: LED OFF + API YOK
  if (ldrDigital == HIGH) {
    Serial.println("[LDR] Ortam KARANLIK -> Supabase pas gecildi");
    turnOffAllLeds();
    delay(3000);
    return;
  }

  /* -------- LDR ANALOG (BILGI) -------- */
  int ldrAnalog = analogRead(LDR_ANALOG_PIN);
  Serial.print("[LDR-A0] Analog Deger: ");
  Serial.println(ldrAnalog);

  /* -------- SUPABASE ISTEK -------- */
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("[HTTP] Supabase istek atiliyor...");

    HTTPClient http;
    http.begin(supabaseUrl);
    http.addHeader("apikey", supabaseKey);
    http.addHeader("Authorization", "Bearer " + String(supabaseKey));

    int httpCode = http.GET();
    Serial.print("[HTTP] Status Code: ");
    Serial.println(httpCode);

    if (httpCode == 200) {
      String payload = http.getString();
      Serial.print("[HTTP] JSON: ");
      Serial.println(payload);

      StaticJsonDocument<256> doc;
      DeserializationError err = deserializeJson(doc, payload);

      if (!err && doc.size() > 0) {
        String led1 = doc[0]["led1"] | "off";
        String led2 = doc[0]["led2"] | "off";

        Serial.print("[DATA] LED1: ");
        Serial.println(led1);
        Serial.print("[DATA] LED2: ");
        Serial.println(led2);

        if (led1 != lastLed1) {
          setLed(LED1_RED, LED1_BLUE, led1);
          lastLed1 = led1;
        }

        if (led2 != lastLed2) {
          setLed(LED2_RED, LED2_BLUE, led2);
          lastLed2 = led2;
        }
      } else {
        Serial.println("[JSON] Parse hatasi ❌");                                                                             
      }
    } else {
      Serial.println("[HTTP] Supabase erisim hatasi ❌");
    }

    http.end();
  }

  delay(2000);
}
