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
- Vuruş sayısı aralığı 2–20 ile sınırlandırıldı
- Nota yazma döngüsündeki kritik hatalar giderildi: sonsuz döngü/donma sorunu çözüldü, `track = staffIdx * 4 + voice` kullanımı doğru hale getirildi (`track` ayarının `tick` değerini sıfırladığı keşfedildi)
- Geliştiren bilgisi ve eklenti logosu (kudüm çalgısı temalı, SVG) eklendi

### v0.3 — Esnek Ritim Sistemi
- Eşit olmayan birim değerli usuller desteklendi (örn. Sofyan: ikilik + dörtlük + dörtlük)
- Harf tabanlı vuruş girişi sistemi: `i` (ikilik), `d` (dörtlük), `s` (sekizlik), `o` (onaltılık); noktalı notalar için harfin yanına nokta (`d.`, `s.` vb.)
- Otomatik zaman imzası hesaplama (4/4, 9/8, 7/8, 7/16 gibi)
- Checkbox satırının üstünde her vuruşun nota harfini gösteren etiketler
- 20 vuruştan fazla giriş engellendi; geçersiz karakterlerde görsel uyarı

### v0.4 — Kararlılık ve Arayüz İyileştirmeleri
- Ciddi bir "boş pencere" sorunu adım adım izole edilerek çözüldü (kaynak: `RegularExpressionValidator` ve `onObjectNameChanged` gibi MuseScore 4'te güvenilir çalışmayan QML bileşenleri)
- Nota referans tablosundaki sembollerin sıralaması uzundan kısaya düzenlendi

### v0.5 — Hazır Usul Şablonları ve Görsel Vuruş Şemaları
- **16 hazır usul şablonu** eklendi: 2 zamanlıdan 10 zamanlıya kadar Türk sanat müziğinin en yaygın usulleri (Nim Sofyan, Semai, Sofyan, Türk Aksağı, Yürük Semai, Devr-i Hindi, Devr-i Turan, Düyek, Müsemmen, Aksak, Evfer, Raks Aksağı, Oynak, Aksak Semai, Curcuna, Cengi Harbi), her biri doğru zaman imzası ve düm/tek deseniyle
- ComboBox'tan seçim yapınca vuruş deseni ve checkbox'lar otomatik doluyor; listenin sonundaki **"Diğer (Elle Gir)"** seçeneğiyle eski elle giriş modu korundu
- Her hazır şablonun yanında, geleneksel iki çizgili gösterimle (üst çizgi=kuvvetli, alt çizgi=zayıf) çizilmiş SVG vuruş şeması eklendi — zaman imzası, nota değerleri (ikilik/dörtlük/sekizlik/onaltılık, noktalılar dahil) ve düm/tek heceleri görsel olarak gösteriliyor
- "Diğer" seçili değilken ilgili alanlar otomatik gizlenip arayüz sadeleştirildi
- Pencere düzeni iyileştirildi: butonlar ve geliştiren bilgisi her zaman pencerenin altında sabit

### v0.6 — Notasyon Kalitesi: Kirişsiz ve Doğru Sap Yönlü Notalar (Mevcut Sürüm)
- **Kiriş (beam) sorunu çözüldü**: Önceki sürümlerde sekizlik/onaltılık gruplar otomatik olarak birbirine kirişleniyordu; bu MuseScore 4 plugin API'sinde uzun süre çözülemeyen bir problemdi. Çözüm, açık kaynaklı [traditionalVocalBeaming](https://github.com/heuchi/traditionalVocalBeaming) eklentisinin kaynak kodu incelenerek bulundu: doğru API `chordRest.beamMode = Beam.NONE` (önceki denemelerdeki `BeamMode.NO` veya sayısal değerler değil, `Beam` nesnesi üzerinden erişim gerekiyormuş)
- **Doğru sap yönü**: Kuvvetli (düm) notalar artık sap yukarı, zayıf (tek) notalar sap aşağı yazılıyor — `stemDirection` property'si pitch'e göre otomatik atanıyor
- **Ses değişikliği**: Kuvvetli vuruş için Open Hi-Hat (pitch 45), zayıf vuruş için Low Floor Tom (pitch 41) kullanılmaya başlandı
- Oluşturulan davul partisi otomatik olarak seçili bırakılıyor, kullanıcı isterse ek düzenleme yapabilir
- Kod temizlendi: önceki denemelerden kalan kullanılmayan fonksiyonlar ve değişkenler kaldırıldı

---

## Kullanım Özeti

1. Açılır listeden bir **usul** seçin (örn. "9 Zamanlı — Aksak") ya da listenin sonundaki **"Diğer (Elle Gir)"** seçeneğiyle kendi deseninizi tanımlayın.
2. "Diğer" seçtiyseniz, **usul adını** yazın — bu isim davul partisinin üstüne metin (StaffText) olarak eklenir — ve **ritim desenini** harflerle girin (`i+d+d`, `s+d+s+d+d` gibi).
3. **Checkbox'larla** hangi vuruşların kuvvetli (düm) çalınacağını belirleyin.
4. **Oluştur** düğmesine basın. Eklenti, seçili ölçüden (seçim yoksa eserin başından) sonuna kadar yeni bir davul (Drumset) partisi ekler, zaman imzasını otomatik ayarlar ve notaları kirişsiz, doğru sap yönleriyle yazar.

---
---

# AllaTurca — Turkish Usul Metronome Plugin (English)

A MuseScore Studio 4.x plugin that automatically adds a percussion (drum) part to a score based on a user-defined or preset Turkish rhythmic pattern (*usul*).

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
- Beat count range limited to 2–20
- Critical bugs in the note-writing loop were fixed: infinite loop/freezing resolved, corrected use of `track = staffIdx * 4 + voice` (discovered that setting `track` resets the cursor's `tick`)
- Developer credit and plugin icon (kudüm drum themed SVG) added

### v0.3 — Flexible Rhythm System
- Added support for usuls with unequal note values (e.g. Sofyan: half + quarter + quarter)
- Letter-based beat input system: `i` (half), `d` (quarter), `s` (eighth), `o` (sixteenth); dotted notes via a dot after the letter (`d.`, `s.` etc.)
- Automatic time signature calculation (4/4, 9/8, 7/8, 7/16 etc.)
- Labels above the checkboxes showing each beat's note letter
- Input of more than 20 beats blocked; invalid characters trigger a visual warning

### v0.4 — Stability and UI Refinements
- A serious "blank window" issue was resolved through step-by-step isolation testing (root cause: `RegularExpressionValidator` and `onObjectNameChanged`, QML components that don't reliably work in MuseScore 4)
- Reordered the note reference table symbols from longest to shortest

### v0.5 — Preset Usul Templates and Visual Beat Diagrams
- **16 preset usul templates** added, covering the most common Turkish classical music usuls from 2 to 10 beats (Nim Sofyan, Semai, Sofyan, Türk Aksağı, Yürük Semai, Devr-i Hindi, Devr-i Turan, Düyek, Müsemmen, Aksak, Evfer, Raks Aksağı, Oynak, Aksak Semai, Curcuna, Cengi Harbi), each with the correct time signature and düm/tek pattern
- Selecting a preset from the ComboBox auto-fills the beat pattern and checkboxes; the legacy manual-entry mode is preserved via the **"Diğer (Other — Enter Manually)"** option at the end of the list
- Each preset now shows an SVG beat diagram drawn in the traditional two-line notation (top line = strong beat, bottom line = weak beat) — displaying time signature, note values (half/quarter/eighth/sixteenth, including dotted), and düm/tek syllables
- UI simplified: irrelevant fields auto-hide unless "Other" is selected
- Window layout improved: buttons and developer credit are now fixed at the bottom of the window

### v0.6 — Notation Quality: Beamless Notes with Correct Stem Direction (Current Version)
- **Beam issue resolved**: In previous versions, groups of eighth/sixteenth notes were automatically beamed together — a problem that had no working solution in the MuseScore 4 plugin API for a long time. The fix was found by examining the source code of the open-source [traditionalVocalBeaming](https://github.com/heuchi/traditionalVocalBeaming) plugin: the correct API is `chordRest.beamMode = Beam.NONE` (not `BeamMode.NO` or numeric values as previously attempted — access must go through the `Beam` object)
- **Correct stem direction**: Strong (düm) notes are now written with stems up, weak (tek) notes with stems down — the `stemDirection` property is set automatically based on pitch
- **Sound change**: Open Hi-Hat (pitch 45) is now used for strong beats, Low Floor Tom (pitch 41) for weak beats
- The generated drum part is left selected after creation, allowing for further manual adjustment if needed
- Code cleanup: removed unused functions and variables left over from earlier experiments

---

## Usage Summary

1. Select a **usul** from the dropdown (e.g. "9 Zamanlı — Aksak") or define your own pattern using the **"Diğer (Other — Enter Manually)"** option at the end of the list.
2. If you chose "Other", enter the **usul name** — this will be added as staff text above the drum part — and the **rhythm pattern** using letters (e.g. `i+d+d`, `s+d+s+d+d`).
3. Use the **checkboxes** to mark which beats should be played strong (düm).
4. Click **Create**. The plugin adds a new drum (Drumset) part from the selected measure (or from the beginning if nothing is selected) to the end of the score, automatically sets the time signature, and writes the notes beamless with the correct stem direction.
