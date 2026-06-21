# AllaTurca — Türk Usulü Metronom Eklentisi

MuseScore Studio 4.x için geliştirilmiş, partisyona girilen usul vuruş desenine göre otomatik bir vurmalı (davul) partisi ekleyen eklenti.

**Geliştiren:** B. Orkun ARAPOĞLU • orkuun@gmail.com

---

## Sürüm Geçmişi

### v0.1 — İlk Sürüm
- Temel arayüz: usul adı giriş kutusu, "Oluştur" düğmesi
- Sabit 9 vuruşluk (Aksak benzeri) desen ile davul partisi ekleme
- Zaman imzasının üst ve alt değerleri için ComboBox'lar (vuruş sayısı 2–10, birim değer 4/8/16)
- Her vuruş için kuvvetli/hafif (düm/tek) seçimi yapan checkbox satırı
- Davul partisi: Bass Drum (düm) ve Acoustic Snare (tek) sesleriyle
- Seçili ölçüden eserin sonuna kadar deseni uygulama
- Zaman imzasını otomatik değiştirme

### v0.2 — İsim ve Kararlılık Güncellemesi
- Eklenti adı **"AllaTurca"** olarak değiştirildi
- Açıklama metni güncellendi: *"Partisyona, vuruş desenine göre bir vurmalı partisi ekler."*
- Vuruş sayısı aralığı 2–20 ile sınırlandırıldı
- Nota yazma döngüsündeki kritik hatalar giderildi:
  - Sonsuz döngü / donma sorunu çözüldü (ölçü bazlı sınırlı döngüye geçildi)
  - `track = staffIdx * 4 + voice` kullanımı doğru hale getirildi (MuseScore API'sinde `track` ayarının `tick` değerini sıfırladığı, bu yüzden önce `track` sonra `rewindToTick` çağrılması gerektiği keşfedildi)
  - Son vuruş işaretliyken ölçünün yarıda kesilmesi sorunu giderildi
- Geliştiren bilgisi arayüze eklendi
- Eklenti logosu (kudüm çalgısı temalı, SVG) tasarlandı ve `thumbnailName` ile bağlandı

### v0.3 — Esnek Ritim Sistemi
- **Eşit olmayan birim değerli usuller** desteklendi (örn. Sofyan: 2'lik + 4'lük + 4'lük)
- Harf tabanlı vuruş girişi sistemi getirildi:
  - `i` = ikilik, `d` = dörtlük, `s` = sekizlik, `o` = onaltılık
  - Noktalı notalar için harfin yanına nokta: `i.`, `d.`, `s.`, `o.`
  - Örnek: Sofyan = `i+d+d`, Aksak = `s+s+s+s+s+s+s+s+s`, Düyek = `s+d+s+d+d`
- Otomatik zaman imzası hesaplama (girilen desene göre 4/4, 9/8, 7/8, 7/16 gibi paydaları doğru seçen mantık)
- Noktalı notalar için `setDuration(3, denom)` yöntemi (örn. noktalı dörtlük = `setDuration(3, 8)`)
- Checkbox satırının üstünde her vuruşun nota harfini gösteren etiketler
- Nota değerleri için görsel referans tablosu (SVG ile çizilmiş gerçek nota sembolleri — ikilik, dörtlük, sekizlik, onaltılık ve noktalı halleri)
- Arayüz metinleri numaralandırılmış adımlar halinde yeniden yazıldı (1 - Usul adı, 2 - Ritim deseni, 3 - Kuvvetli/hafif seçimi)
- Karanlık/aydınlık mod uyumluluğu: pencere arka planı gri, metin kutuları beyaz, yazılar siyah yapıldı
- 20 vuruştan fazla giriş engellendi; fazlası otomatik kesilip kullanıcıya uyarı gösterilir
- Vuruş deseni giriş kutusuna geçersiz karakter girildiğinde görsel uyarı (kırmızı kenarlık) ve açıklayıcı hata mesajı eklendi

### v0.4 — Kararlılık ve Arayüz İyileştirmeleri (Mevcut Sürüm)
- Ciddi bir "boş pencere" sorunu adım adım izole edilerek çözüldü:
  - Sorunun kaynağının `RegularExpressionValidator` ve `onObjectNameChanged` gibi MuseScore 4'ün QML ortamında güvenilir çalışmayan bileşenler olduğu tespit edildi
  - Bu bileşenler kaldırılıp yerlerine güvenli alternatifler (regex tabanlı `property bool` kontrolü, doğrudan property binding) kullanıldı
  - `Qt.callLater()` ile metin kutusu içinden kendi metnini değiştirmenin yarattığı özyinelemeli tetiklenme riski giderildi
- Nota referans tablosundaki sembollerin sıralaması **uzundan kısaya** olacak şekilde düzenlendi: `i., i, d., d, s., s, o., o`
- Arayüzdeki gereksiz açıklama metinleri sadeleştirildi
- Checkbox üstü etiketler arasına görsel "+" işaretleri eklendi

---

## Kullanım Özeti

1. **Usul adını** yazın (örn. "Sofyan") — bu isim, oluşturulacak davul partisinin üstüne metin (StaffText) olarak eklenir.
2. **Ritim desenini** harflerle yazın: `i` (ikilik), `d` (dörtlük), `s` (sekizlik), `o` (onaltılık); noktalı notalar için harfin yanına nokta ekleyin (`d.` gibi). Vuruşları `+` ile ayırın.
   - Örnek: Semai = `d+d+d`, Sofyan = `i+d+d`, Düyek = `s+d+s+d+d`, 7/8'lik = `d+d+d.`
3. **Checkbox'ları** işaretleyerek hangi vuruşların kuvvetli (düm) çalınacağını belirleyin; işaretsiz bırakılanlar hafif (tek) çalınır.
4. **Oluştur** düğmesine basın. Eklenti, partisyonun seçili ölçüsünden (seçim yoksa baştan) eserin sonuna kadar yeni bir davul (Drumset) partisi ekler ve zaman imzasını girilen desene göre otomatik ayarlar.

---
---

# AllaTurca — Turkish Usul Metronome Plugin (English)

A MuseScore Studio 4.x plugin that automatically adds a percussion (drum) part to a score based on a user-defined Turkish rhythmic pattern (*usul*).

**Developer:** B. Orkun ARAPOĞLU • orkuun@gmail.com

---

## Version History

### v0.1 — Initial Release
- Basic UI: usul name input field, "Create" button
- Fixed 9-beat (Aksak-like) pattern for adding the drum part
- ComboBoxes for the numerator and denominator of the time signature (beat count 2–10, unit value 4/8/16)
- A row of checkboxes for marking each beat as strong/weak (düm/tek)
- Drum part using Bass Drum (düm) and Acoustic Snare (tek) sounds
- Pattern applied from the selected measure to the end of the score
- Automatic time signature change

### v0.2 — Naming and Stability Update
- Plugin renamed to **"AllaTurca"**
- Description updated to: *"Adds a percussion part to the score based on the beat pattern."*
- Beat count range limited to 2–20
- Critical bugs in the note-writing loop were fixed:
  - Infinite loop / freezing issue resolved (switched to a measure-bounded loop)
  - Corrected use of `track = staffIdx * 4 + voice` (discovered that setting `track` resets the cursor's `tick`, so `track` must be set before calling `rewindToTick`)
  - Fixed a bug where the measure was cut short when the last beat was marked as strong
- Developer credit added to the UI
- Plugin icon designed (kudüm drum themed SVG) and linked via `thumbnailName`

### v0.3 — Flexible Rhythm System
- Added support for **usuls with unequal note values** (e.g. Sofyan: half + quarter + quarter)
- Introduced a letter-based beat input system:
  - `i` = half note, `d` = quarter note, `s` = eighth note, `o` = sixteenth note
  - Dotted notes indicated with a dot after the letter: `i.`, `d.`, `s.`, `o.`
  - Example: Sofyan = `i+d+d`, Aksak = `s+s+s+s+s+s+s+s+s`, Düyek = `s+d+s+d+d`
- Automatic time signature calculation (logic correctly selects denominators like 4/4, 9/8, 7/8, 7/16 based on the entered pattern)
- Dotted notes implemented via `setDuration(3, denom)` (e.g. dotted quarter = `setDuration(3, 8)`)
- Labels above the checkboxes now show each beat's note letter
- Visual reference table for note values (real note symbols drawn in SVG — half, quarter, eighth, sixteenth notes and their dotted forms)
- UI text rewritten as numbered steps (1 - Usul name, 2 - Rhythm pattern, 3 - Strong/weak selection)
- Dark/light mode compatibility: window background set to gray, text fields to white, text to black
- Input of more than 20 beats is blocked; excess beats are automatically trimmed with a warning shown to the user
- Invalid characters in the pattern input field now trigger a visual warning (red border) and an explanatory error message

### v0.4 — Stability and UI Refinements (Current Version)
- A serious "blank window" issue was resolved through step-by-step isolation testing:
  - Root cause identified as `RegularExpressionValidator` and `onObjectNameChanged`, components that do not reliably work in MuseScore 4's QML environment
  - These were removed and replaced with safer alternatives (regex-based `property bool` checks, direct property bindings)
  - Fixed a recursive-trigger risk caused by a text field modifying its own text from within its own change handler, resolved using `Qt.callLater()`
- Reordered the note reference table symbols from **longest to shortest**: `i., i, d., d, s., s, o., o`
- Simplified redundant explanatory text in the UI
- Added visual "+" separators between the letter labels above the checkboxes

---

## Usage Summary

1. Enter the **usul name** (e.g. "Sofyan") — this will be added as staff text above the generated drum part.
2. Enter the **rhythm pattern** using letters: `i` (half), `d` (quarter), `s` (eighth), `o` (sixteenth); add a dot after the letter for dotted notes (e.g. `d.`). Separate beats with `+`.
   - Example: Semai = `d+d+d`, Sofyan = `i+d+d`, Düyek = `s+d+s+d+d`, 7/8 = `d+d+d.`
3. Use the **checkboxes** to mark which beats should be played strong (düm); unmarked beats are played weak (tek).
4. Click **Create**. The plugin adds a new drum (Drumset) part from the selected measure (or from the beginning if nothing is selected) to the end of the score, and automatically sets the time signature based on the entered pattern.
