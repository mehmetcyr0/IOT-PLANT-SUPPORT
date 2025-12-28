# 🌱 Bitki Işık Destek – Flutter Mobile App

Bitki büyüme ışıklarını Supabase backend üzerinden kontrol eden modern bir Flutter mobil uygulaması. Kullanıcılar kırmızı ve mavi LED kanallarını (LED1 ve LED2) kontrol edebilir ve ESP32 cihazına bağlı LED'leri yönetebilir.

## ✨ Özellikler

- 🌿 **Bitki Seçimi**: Farklı bitkiler için özelleştirilmiş ışık ayarları
- 📅 **Büyüme Dönemi Seçimi**: Bitkiye özel büyüme dönemleri (Yaprak, Çiçek, Dinlenme, Geçiş)
- 💡 **LED Kontrolü**: İki LED kanalı için bağımsız kontrol (Kırmızı/Mavi/Kapalı)
- 🔄 **Gerçek Zamanlı Güncelleme**: Supabase üzerinden anlık LED durumu kontrolü
- 🌞 **LDR Sensör Desteği**: Ortam karanlıksa LED'ler otomatik kapanır - Bitki hormon üretebilir
- 🎨 **Modern UI**: Material Design 3 ile tasarlanmış güzel ve kullanıcı dostu arayüz
- 🌓 **Dark Mode**: Sistem temasına uyumlu karanlık mod desteği
- 📊 **Bağlantı Durumu**: AppBar'da görünen bağlantı durumu göstergesi
- 🎯 **Otomatik LED Ayarları**: Dönem seçildiğinde LED değerleri otomatik güncellenir

## 📋 Gereksinimler

- Flutter SDK (3.10.0 veya üzeri)
- Supabase hesabı ve projesi
- ESP32 cihazı (Supabase'i her 2 saniyede bir okuyacak şekilde yapılandırılmış)

## 🚀 Kurulum

### 1. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 2. Supabase Yapılandırması

1. [supabase.com](https://supabase.com) adresinden bir Supabase projesi oluşturun
2. Proje Ayarları → API bölümünden proje URL'nizi ve anon key'inizi alın
3. `lib/main.dart` dosyasını düzenleyin ve Supabase bilgilerinizi girin:

```dart
await SupabaseService.initialize(
  url: 'YOUR_SUPABASE_URL',  // Supabase URL'nizi buraya yazın
  anonKey: 'YOUR_SUPABASE_ANON_KEY',  // Anon key'inizi buraya yazın
);
```

### 3. Veritabanı Tablosunu Oluşturun

Supabase SQL Editor'de aşağıdaki SQL'i çalıştırın:

```sql
-- ===============================
-- 1) TABLO OLUŞTUR
-- ===============================
CREATE TABLE IF NOT EXISTS led_status (
  id BIGINT PRIMARY KEY,
  led1 TEXT NOT NULL DEFAULT 'off', -- "red", "blue", "off"
  led2 TEXT NOT NULL DEFAULT 'off', -- "red", "blue", "off"
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================
-- 2) GÜNCELLEME TARİHİ OTOMATİK
-- ===============================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON led_status;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON led_status
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ===============================
-- 3) ESP32 İÇİN GEREKLİ SATIR
-- ===============================
INSERT INTO led_status (id, led1, led2)
VALUES (1, 'off', 'off')
ON CONFLICT (id) DO NOTHING;

-- ===============================
-- 4) ROW LEVEL SECURITY
-- ===============================
ALTER TABLE led_status ENABLE ROW LEVEL SECURITY;

-- ESP32 okuma izni
DROP POLICY IF EXISTS "Allow ESP32 read" ON led_status;
CREATE POLICY "Allow ESP32 read"
ON led_status
FOR SELECT
USING (true);

-- Flutter uygulaması yazma izni
DROP POLICY IF EXISTS "Allow app update" ON led_status;
CREATE POLICY "Allow app update"
ON led_status
FOR UPDATE
USING (true);

-- ===============================
-- 5) GÜVENLİ VERİ KONTROLÜ
-- ===============================
ALTER TABLE led_status
ADD CONSTRAINT led1_check
CHECK (led1 IN ('red', 'blue', 'off'));

ALTER TABLE led_status
ADD CONSTRAINT led2_check
CHECK (led2 IN ('red', 'blue', 'off'));
```

### 4. Uygulamayı Çalıştırın

```bash
flutter run
```

## 📱 Kullanım

### Bitki Seçimi

1. **Bitki Seçimi** kartını açın (çekmeceli yapı)
2. Mevcut bitkilerden birini seçin (şu anda sadece Domates mevcut)
3. Bitki seçimini kaldırmak için "Seçimi Kaldır" butonuna tıklayın

### Büyüme Dönemi Seçimi

Domates seçildiğinde **Büyüme Dönemi** kartı görünür:

- **🌱 Yaprak (Vegetatif)**: LED1=Blue, LED2=Blue
- **🌸 Çiçek**: LED1=Red, LED2=Red
- **😴 Dinlenme**: LED1=Off, LED2=Off
- **🔄 Geçiş (Deneysel)**: LED1=Blue, LED2=Red

Dönem seçildiğinde LED değerleri otomatik olarak güncellenir.

### LED Kontrolü

Her LED için 3 seçenek bulunur:
- **Kırmızı**: LED'i kırmızı modda aç
- **Mavi**: LED'i mavi modda aç
- **Kapalı**: LED'i kapat

## 🔌 ESP32 Entegrasyonu

ESP32 cihazınız Supabase tablosunu her 2 saniyede bir okuyarak LED değerlerini almalıdır.

### LDR Sensör Özelliği

Projede **LDR (Light Dependent Resistor)** sensörü bulunmaktadır. Bu sensör sayesinde:

- 🌑 **Ortam Karanlıksa**: LED'ler otomatik olarak kapatılır
- 🌞 **Ortam Aydınlıksa**: LED'ler Supabase'den gelen değerlere göre çalışır
- 🌱 **Bitki Hormon Üretimi**: Karanlık dönemlerde bitki hormon üretebilir

ESP32 kodunda LDR sensörü kontrol edilir ve ortam karanlıksa Supabase'e istek atılmaz, LED'ler kapatılır.

### Örnek ESP32 Kodu Yapısı

```cpp
// LDR Sensör Kontrolü
#define LDR_DIGITAL_PIN 23  // D0 → Digital
#define LDR_ANALOG_PIN 34   // A0 → Analog

void loop() {
  // LDR Digital kontrolü
  int ldrDigital = digitalRead(LDR_DIGITAL_PIN);
  
  // Karanlıksa LED'leri kapat ve Supabase'e istek atma
  if (ldrDigital == HIGH) {
    turnOffAllLeds();
    delay(3000);
    return; // Supabase isteği atılmaz
  }
  
  // Aydınlıksa normal işlem devam eder
  // Supabase REST API'den veri okuma
  // GET: https://YOUR_PROJECT.supabase.co/rest/v1/led_status?id=eq.1
  // Headers: 
  //   apikey: YOUR_ANON_KEY
  //   Authorization: Bearer YOUR_ANON_KEY

  // Yanıt formatı:
  // {
  //   "id": 1,
  //   "led1": "red",  // veya "blue" veya "off"
  //   "led2": "blue", // veya "red" veya "off"
  //   "updated_at": "2024-01-01T12:00:00Z"
  // }
}
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                      # Uygulama giriş noktası ve başlatma
├── models/
│   └── plant.dart                 # Bitki ve büyüme dönemi modelleri
├── services/
│   └── supabase_service.dart      # Supabase API servisi
└── screens/
    └── led_control_screen.dart     # Ana UI ekranı
```

## 🎨 UI Özellikleri

- **Çekmeceli Yapı**: Bitki ve dönem seçimi için açılır/kapanır kartlar
- **Gradient Tasarım**: Modern gradient arka planlar ve butonlar
- **Animasyonlar**: Smooth geçiş animasyonları
- **Durum Göstergeleri**: Görsel LED durum göstergeleri
- **Bağlantı İzleme**: AppBar'da bağlantı durumu (yeşil/kırmızı)

## 🔧 LED Değerleri

| Değer | Açıklama |
|-------|----------|
| `red` | LED kırmızı modda açık |
| `blue` | LED mavi modda açık |
| `off` | LED kapalı |

### LDR Sensör Davranışı

| Ortam Durumu | LED Durumu | Açıklama |
|--------------|------------|----------|
| 🌞 Aydınlık | Supabase'den kontrol edilir | Normal LED kontrolü aktif |
| 🌑 Karanlık | Otomatik kapatılır | LDR sensörü LED'leri kapatır, bitki hormon üretebilir |

**Not**: Ortam karanlıksa ESP32 Supabase'e istek atmaz ve LED'leri kapatır. Bu sayede bitki doğal karanlık dönemlerinde hormon üretebilir.

## 🐛 Sorun Giderme

### Bağlantı Sorunları

- Supabase URL ve anon key'inizin doğru olduğundan emin olun
- İnternet bağlantınızı kontrol edin
- Supabase tablosunun doğru yapıda olduğunu doğrulayın
- Supabase dashboard'da proje durumunu kontrol edin

### Güncelleme Hataları

- RLS politikalarının güncellemelere izin verdiğini kontrol edin
- `id=1` olan satırın tabloda mevcut olduğunu doğrulayın
- Supabase loglarını hatalar için inceleyin

### LED Değerleri Güncellenmiyor

- ESP32'nin doğru tabloyu okuduğundan emin olun
- LED değerlerinin (`red`, `blue`, `off`) doğru formatta olduğunu kontrol edin
- Supabase trigger'larının çalıştığını doğrulayın

## 📦 Bağımlılıklar

- `flutter`: SDK
- `supabase_flutter: ^2.5.0`: Supabase entegrasyonu
- `cupertino_icons: ^1.0.8`: iOS ikonları

## 🔐 Güvenlik Notları

- **Önemli**: Production ortamında RLS politikalarını daha sıkı yapılandırın
- Supabase anon key'inizi public repository'lerde paylaşmayın
- Mümkünse authentication ekleyin
- API rate limiting kullanmayı düşünün

## 📄 Lisans

Bu proje açık kaynaklıdır ve kişisel ve ticari kullanım için kullanılabilir.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen:

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📞 Destek

Sorularınız ve sorunlarınız için:

- [Flutter Dokümantasyonu](https://docs.flutter.dev/)
- [Supabase Dokümantasyonu](https://supabase.com/docs)
- [GitHub Issues](https://github.com/yourusername/bitki_isik_destek/issues)

## 🎯 Gelecek Özellikler

- [ ] Daha fazla bitki türü desteği
- [ ] Zamanlanmış LED kontrolü
- [ ] LED geçmişi ve istatistikleri
- [ ] Çoklu ESP32 cihaz desteği
- [ ] Bildirimler ve uyarılar
- [ ] Offline mod desteği

## 📸 Ekran Görüntüleri

*(Ekran görüntüleri ekleyebilirsiniz)*

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
