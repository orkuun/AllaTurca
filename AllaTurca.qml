import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import MuseScore 3.0
import FileIO 3.0

MuseScore {
    id: usulPlugin
    menuPath: "Plugins.AllaTurca"
    title: "AllaTurca"
    description: "Partisyona, vuruş desenine göre bir vurmalı partisi ekler."
    version: "0.1"
    thumbnailName: "AllaTurca.png"
    pluginType: "dialog"
    requiresScore: true
    width: 440
    height: 430

    // true  = kuvvetli vuruş (düm)
    // false = hafif vuruş (tek)
    property var dumPattern: [true, false, false, false, false, false, false, false, false]

    // Bas davul (düm) ve Side Stick (tek) - General MIDI perküsyon haritası
    property int dumPitch: 36  // Bass Drum
    property int tekPitch: 38  // Acoustic Snare

    // ---- Hata ayıklama günlüğü ----
    // Çökme anında ekran kaybolduğu için, son ulaşılan adımı görmek üzere
    // bir metin dosyasına yazıyoruz (son ~25 satır tutulur).
    property var debugLines: []

    FileIO {
        id: logFile
        source: ""
        onError: function(msg) { /* sessizce yut */ }
    }

    function log(msg) {
        debugLines.push(msg)
        if (debugLines.length > 25) debugLines.shift()
        try {
            logFile.write(debugLines.join("\n") + "\n")
        } catch (e) {
            // log yazımı başarısız olursa eklentiyi durdurmasın
        }
    }

    function rebuildPattern(n) {
        var arr = []
        for (var i = 0; i < n; i++) {
            arr.push(i === 0 ? dumPattern[i] !== undefined ? dumPattern[i] : (i === 0) : (dumPattern[i] === true))
        }
        // basitleştirilmiş: mevcut değerleri koru, eksikleri false yap
        var newArr = []
        for (var j = 0; j < n; j++) {
            newArr.push(dumPattern[j] === true)
        }
        if (newArr.length > 0 && dumPattern.length === 0) newArr[0] = true
        dumPattern = newArr
        patternRepeater.model = 0
        patternRepeater.model = n
    }

    onRun: {
        logFile.source = logFile.homePath() + "/usul_debug_log.txt"
        log("=== Eklenti başlatıldı ===")
        rebuildPattern(parseInt(numCombo.currentText))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Label {
            text: "Usul Adı (Dizeğin üstüne metin ekler)"
            font.bold: true
        }
        TextField {
            id: usulNameField
            Layout.fillWidth: true
            placeholderText: "Örn. Aksak, Düyek, Sofyan, Curcuna..."
        }

        RowLayout {
            spacing: 12

            ColumnLayout {
                Label { text: "Vuruş sayısı (üst)" }
                ComboBox {
                    id: numCombo
                    model: ["2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20"]
                    currentIndex: 7   // varsayılan: 9
                    onCurrentTextChanged: rebuildPattern(parseInt(currentText))
                }
            }

            ColumnLayout {
                Label { text: "Birim değer (alt)" }
                ComboBox {
                    id: denomCombo
                    model: ["4","8","16"]
                    currentIndex: 1   // varsayılan: 8
                }
            }
        }



        Label {
            text: "Vuruş deseni — işaretli kutu KUVVETLİ (düm), boş kutu HAFİF (tek)"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Flow {
            id: patternFlow
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                id: patternRepeater
                model: 9

                delegate: ColumnLayout {
                    spacing: 2
                    Label {
                        text: (index + 1).toString()
                        Layout.alignment: Qt.AlignHCenter
                    }
                    CheckBox {
                        checked: dumPattern.length > index ? dumPattern[index] === true : false
                        onToggled: {
                            var arr = dumPattern.slice()
                            while (arr.length <= index) arr.push(false)
                            arr[index] = checked
                            dumPattern = arr
                        }
                    }
                }
            }
        }



        Label {
            text: "Not: Yukarıda ayarlanan usulü yeni bir parti olarak partisyonundaki seçili yerden itibaren ekler. Seçili bir ölçü yoksa en baştan en sona kadar ekler."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 11
            color: "#555555"
        }

        Label {
            id: statusLabel
            text: ""
            color: "#444444"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 11
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Button {
                text: "Kapat"
                onClicked: usulPlugin.parent.Window.window.close()
            }

            Button {
                text: "Oluştur"
                highlighted: true
                onClicked: createUsulPart()
            }
        }

        Label {
            text: "Geliştiren: B. Orkun ARAPOĞLU  •  orkuun@gmail.com"
            font.pixelSize: 10
            color: "#888888"
            Layout.alignment: Qt.AlignHCenter
        }
    }

    function createUsulPart() {
        if (typeof curScore === "undefined" || curScore === null) {
            statusLabel.text = "Açık bir nota bulunamadı."
            return
        }

        var usulName = usulNameField.text.trim()
        if (usulName.length === 0) {
            usulName = "Usul"
        }

        var beatCount = parseInt(numCombo.currentText)
        var unitDenom = parseInt(denomCombo.currentText)
        log("Oluştur tıklandı: usul=" + usulName + " beat=" + beatCount + "/" + unitDenom)

        var startTick = 0
        try {
            // 1. Başlangıç noktasını belirle
            log("ADIM 1: Başlangıç noktası aranıyor...")
            var startCursor = curScore.newCursor()
            var hasSelection = false
            try {
                startCursor.rewind(Cursor.SELECTION_START)
                if (startCursor.segment) hasSelection = true
            } catch (e1) {
                hasSelection = false
            }
            if (!hasSelection) {
                startCursor.rewind(Cursor.SCORE_START)
            }
            startTick = startCursor.tick
            log("ADIM 1 TAMAM: startTick=" + startTick + " hasSelection=" + hasSelection)
        } catch (ePrep) {
            log("ADIM 1 HATA: " + ePrep)
            statusLabel.text = "Başlangıç noktası belirlenirken hata: " + ePrep
            return
        }

        // 2. Zaman imzasını uygula
        try {
            log("ADIM 2: Zaman imzası ekleniyor " + beatCount + "/" + unitDenom)
            curScore.startCmd()
            var ts = newElement(Element.TIMESIG)
            ts.timesig = fraction(beatCount, unitDenom)
            var tsCursor = curScore.newCursor()
            tsCursor.rewindToTick(startTick)
            tsCursor.add(ts)
            curScore.endCmd()
            log("ADIM 2 TAMAM")
        } catch (eTs) {
            curScore.endCmd(true)
            log("ADIM 2 HATA: " + eTs)
            statusLabel.text = "Zaman imzası eklenirken hata: " + eTs
            return
        }

        // 3. Davul partisi ekle
        try {
            log("ADIM 3: appendPart(drumset) çağrılıyor...")
            curScore.startCmd()
            curScore.appendPart("drumset")
            curScore.endCmd()
            log("ADIM 3 TAMAM: nstaves=" + curScore.nstaves)
        } catch (eAppend) {
            curScore.endCmd(true)
            log("ADIM 3 HATA: " + eAppend)
            statusLabel.text = "Parti eklenirken hata: " + eAppend
            return
        }

        var staffIdx = curScore.nstaves - 1
        log("staffIdx=" + staffIdx)
        // 4. Deseni yaz - ölçü bazlı, sonsuz döngü riski yok
        var totalMeasures = curScore.nmeasures
        log("ADIM 4 basladi: toplamOlcu=" + totalMeasures + " staffIdx=" + staffIdx)

        try {
            curScore.startCmd()

            // Başlangıç ölçüsünü bul
            var startMeasure = curScore.firstMeasure
            var m = startMeasure
            while (m && m.nextMeasure && m.firstSegment.tick < startTick) {
                m = m.nextMeasure
            }
            startMeasure = m
            log("ADIM 4: baslangic olcusu bulundu, tick=" + (m ? m.firstSegment.tick : "null"))

            // Usul adını StaffText olarak ilk ölçünün başına ekle
            var stCursor = curScore.newCursor()
            stCursor.staffIdx = staffIdx
            stCursor.voice = 0
            var st = newElement(Element.STAFF_TEXT)
            st.text = usulName
            stCursor.rewindToTick(startMeasure.firstSegment.tick)
            stCursor.add(st)


            // Tek cursor, tek voice — addNote() otomatik ilerler
            var cursor = curScore.newCursor()
            cursor.staffIdx = staffIdx
            cursor.voice = 0

            var patternIdx = 0
            var measureCount = 0
            var measure = startMeasure
            while (measure && measureCount < totalMeasures) {
                cursor.rewindToTick(measure.firstSegment.tick)
                for (var b = 0; b < beatCount; b++) {
                    if (!cursor.segment) break
                    cursor.setDuration(1, unitDenom)
                    var isStrong = (dumPattern.length > 0) ? (dumPattern[patternIdx % beatCount] === true) : (patternIdx % beatCount === 0)
                    var pitch = isStrong ? dumPitch : tekPitch
                    cursor.addNote(pitch, false)
                    patternIdx++
                }
                measure = measure.nextMeasure
                measureCount++
            }

            curScore.endCmd()
            log("ADIM 4 TAMAM: " + measureCount + " olcu " + patternIdx + " nota")
            statusLabel.text = "\"" + usulName + "\" deseni (" + beatCount + "/" + unitDenom + ") " + measureCount + " ölçüye eklendi."
        } catch (eWrite) {
            curScore.endCmd(true)
            log("ADIM 4 HATA: " + eWrite)
            statusLabel.text = "Desen yazilirken hata: " + eWrite
        }
    }
}
