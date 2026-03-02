# EventPulse - Gerçek Zamanlı Etkinlik Takip Uygulaması 🚀

Bu proje, şehirdeki etkinlikleri (konser, workshop, spor vb.) anlık olarak listeleyen, kullanıcıların katılım bildirebildiği ve yorumlarını paylaşabildiği "Junior Part-Time Developer" vaka çalışması için geliştirilmiş monorepo (frontend + backend) projesidir.

## 📹 Proje Demo Videosu
> **Değerlendiricinin Dikkatine:** Projenin local ortamda baştan sona çalışır halini, mimari kararları ve SignalR canlı veri akışını gösteren tanıtım videosunu aşağıdan izleyebilirsiniz:
> 👉 `[YouTube / Loom Video Linkinizi Buraya Yapıştırın]`

---

## 🛠️ Teknik Stack & Mimari

Proje, birbirinden tamamen izole iki katmanlı (Monorepo) bir yapıda geliştirilmiştir:

### Backend (.NET 8 Web API)
* **Framework:** .NET 8
* **Veritabanı:** PostgreSQL 16 (Entity Framework Core & Npgsql)
* **Gerçek Zamanlı İletişim:** SignalR (WebSocket)
* **Kimlik Doğrulama:** JWT (RS256 Algoritması) & Firebase Auth ID Token Middleware
* **Önbellekleme (Cache):** Redis (StackExchange.Redis)
* **Mimari:** DTO (Data Transfer Object) Pattern, Clean Code, Dependency Injection

### Frontend (Flutter 3.x)
* **Durum Yönetimi (State Management):** Riverpod (`AsyncNotifierProvider`, `StateNotifierProvider`)
* **Ağ (Network):** Dio (Interceptor mimarisi ile otomatik JWT yönetimi)
* **Gerçek Zamanlı İletişim:** `signalr_netcore`
* **UX/UI Geliştirmeleri:** Shimmer Loading, Hero Animations, Infinite Scroll, Pull-to-refresh

---

## ✨ Öne Çıkan Özellikler & Tamamlanan Görevler

✅ **Zorunlu Görevler Başarıyla Tamamlandı:**
- Sayfalandırma (Pagination) ve Filtreleme mimarisine sahip Event Listesi.
- Hero animasyonu ile geçiş yapılan detay ve yorum sayfası.
- Entity Framework üzerinden `MaxCapacity > 0` gibi kısıtlamalar (Check Constraints) ve Seed Data içeren Migration.
- SignalR ile sayfa yenilemeden "Canlı Katılımcı Sayısı" güncellemesi (Broadcast).
- RS256 algoritmasıyla In-Memory JWT (Access + Refresh Token) üretimi.
- Yorum gönderimi için maksimum 500 karakter sınırlandırması ve doğrulaması.

🌟 **Bonus Görevler Entegrasyonu:**
- **Redis Cache (+10 Puan):** `/api/events` uç noktası veritabanını yormamak için 60 saniyelik Redis önbelleğine alınmıştır. Herhangi bir katılım (Attend/Unattend) gerçekleştiğinde cache otomatik olarak temizlenir (Cache Invalidation).
- **Firebase Auth (+8 Puan):** .NET tarafında `AddJwtBearer` ile Firebase ID Token doğrulama middleware'i projeye entegre edilmiştir.

---

## 📁 Proje Klasör Yapısı (Monorepo)

```text
EventPulse/
├── backend/                  # .NET 8 Web API Projesi
│   ├── src/
│   │   ├── EventPulse.API/           # Controller, SignalR Hub, Program.cs
│   │   ├── EventPulse.Core/          # Entities, DTOs, Interfaces
│   │   └── EventPulse.Infrastructure/# DbContext, Migrations
├── frontend/                 # Flutter 3.x Mobil Uygulama Projesi
│   ├── lib/
│   │   ├── core/                     # Tema ve Ağ (Network/Dio) Ayarları
│   │   ├── features/
│   │   │   ├── auth/                 # Login Ekranı ve Auth Provider
│   │   │   └── events/               # Event Listesi, Detay Ekranı, Shimmer, SignalR
│   │   └── main.dart                 # Uygulama Başlangıç Noktası
└── docker-compose.yml        # Tüm altyapıyı ayağa kaldıran Docker konfigürasyonu
⚙️ Projeyi Local'de Ayağa Kaldırma
Değerlendiricinin veritabanı veya önbellek sunucusu kurmasına gerek kalmadan, tüm backend altyapısı Docker üzerinden çalıştırılabilir. Alternatif olarak manuel kurulum adımları da aşağıda belirtilmiştir.

Seçenek 1: Docker ile Tek Tıkla Kurulum (Önerilen)
Ön Koşullar: Docker Desktop kurulu olmalıdır.

Terminalde projenin ana dizininde (docker-compose.yml dosyasının bulunduğu yerde) şu komutu çalıştırın:

Bash
docker-compose up -d --build
Bu komut; PostgreSQL 16'yı, Redis'i ve .NET 8 API'sini otomatik olarak ayağa kaldıracak, veritabanı tablolarını ve Seed verilerini oluşturacaktır.
API yayına girdikten sonra http://localhost:5000/swagger adresinden test edebilirsiniz.

Seçenek 2: Manuel Kurulum
Ön Koşullar: .NET 8 SDK, PostgreSQL (5432) ve opsiyonel olarak Redis (6379).

Bash
cd backend
# Migration'ları veritabanına uygulayın
dotnet ef database update --project src/EventPulse.Infrastructure --startup-project src/EventPulse.API

# Projeyi çalıştırın
dotnet run --project src/EventPulse.API
📱 Frontend (Mobil Uygulama) Kurulumu
Yeni bir terminal sekmesi açın ve frontend klasörüne gidin:

Bash
cd frontend
flutter pub get
flutter run
🚨 ÖNEMLİ NOT (Android Emülatör İçin): Uygulamayı Android emülatörde çalıştırıyorsanız, Android'in ağ yapısı gereği lib/features/events/providers/events_provider.dart ve event_detail_screen.dart dosyalarındaki API URL'lerini http://localhost:5000 yerine http://10.0.2.2:5000 olarak değiştirmeniz gerekmektedir. iOS Simülatör için localhost kalabilir.

💡 Kullanım Senaryosu (Test Adımları)
Giriş: Uygulama açıldığında Login ekranı gelir. Herhangi bir kullanıcı adı yazın ve şifre olarak 123456 girin (Mock doğrulama testi).

Listeleme: Ana sayfada Redis Cache ve Shimmer efekti ile hızlıca yüklenen etkinlik listesini görün.

Sayfalandırma: Listeyi aşağı çekip bırakarak (Pull-to-refresh) yenilemeyi veya en alta kaydırarak (Infinite scroll) yeni veri çekmeyi test edin.

Detay ve Animasyon: Etkinliklerden birine tıklayıp Hero animasyonu ile kusursuz geçişi deneyimleyin.

Gerçek Zamanlı İletişim (SignalR): Detay sayfasındayken Katıl butonuna basın. Aynı anda hem HTTP POST başarı mesajını hem de SignalR üzerinden broadcast edilen anlık değişen canlı katılımcı sayısını gözlemleyin. Aynı butona tekrar basarak "Duplicate" kuralını test edin.

👨‍💻 Geliştirici
Ahmet Emre Bancar
Computer Engineering Student, Istanbul University-Cerrahpaşa | President of Computer Society

GitHub: @ahmetemrebancar

LinkedIn: ahmetemrebancar