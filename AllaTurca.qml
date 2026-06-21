// ============================================================
// AllaTurca — Türk Usulü Metronom Eklentisi
// Geliştiren: B. Orkun ARAPOĞLU  •  orkuun@gmail.com
// MuseScore 4.x için QML eklentisi
// ============================================================

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import MuseScore 3.0

MuseScore {
    id: usulPlugin
    menuPath: "Plugins.AllaTurca"
    title: "AllaTurca"
    description: "Partisyona, vuruş desenine göre bir vurmalı partisi ekler."
    thumbnailName: "AllaTurca.png"
    version: "0.4"
    pluginType: "dialog"
    requiresScore: true
    width: 460
    height: 610

    property var dumPattern: [true, false, false, false]
    property var beatValues: [480, 480, 480, 480]
    property int dumPitch: 36
    property int tekPitch: 38

    function tickToLetter(t) {
        if (t === 960 || t === 1440) return "i"
        if (t === 480 || t === 720)  return "d"
        if (t === 240 || t === 360)  return "s"
        if (t === 120 || t === 180)  return "o"
        return "?"
    }

    function calcTimeSig() {
        var has16 = false, has8 = false, hasDot8 = false, hasDot4 = false
        for (var i = 0; i < beatValues.length; i++) {
            var t = beatValues[i]
            if (t <= 120)  has16 = true
            if (t === 240) has8 = true
            if (t === 360 || t === 180) hasDot8 = true
            if (t === 720 || t === 1440) hasDot4 = true
        }
        var denom, REF
        if (has16 || hasDot8) { denom = 16; REF = 120 }
        else if (has8 || hasDot4) { denom = 8; REF = 240 }
        else { denom = 4; REF = 480 }
        var num = 0
        for (var j = 0; j < beatValues.length; j++) num += Math.round(beatValues[j] / REF)
        return { num: num, denom: denom }
    }

    function parsePattern(text) {
        var TICKS = { "i": 960, "i.": 1440, "d": 480, "d.": 720,
                      "s": 240, "s.": 360, "o": 120, "o.": 180 }
        var MAX_BEATS = 20  // İzin verilen maksimum vuruş sayısı

        var tokens = text.trim().replace(/\+/g, " ").split(/\s+/)
        if (tokens.length === 0 || (tokens.length === 1 && tokens[0] === "")) return false
        var vals = []
        for (var i = 0; i < tokens.length; i++) {
            var t = tokens[i].toLowerCase().trim()
            if (t === "") continue
            if (TICKS[t] === undefined) {
                statusLabel.text = "Hata: \"" + t + "\" geçersiz. Sadece i, d, s, o harfleri ve nokta (.) kullanın. Örn: i+d+d"
                return false
            }
            vals.push(TICKS[t])
        }
        if (vals.length === 0) return false

        // 20 vuruş sınırı: fazlası kesilir, kutucuk güncellenir, uyarı gösterilir
        if (vals.length > MAX_BEATS) {
            vals = vals.slice(0, MAX_BEATS)
            var trimmedTokens = tokens.slice(0, MAX_BEATS)

            beatValues = vals
            var newDumTrim = []
            for (var k = 0; k < vals.length; k++) newDumTrim.push(dumPattern[k] === true)
            dumPattern = newDumTrim
            patternRepeater.model = 0
            patternRepeater.model = vals.length

            // Metin kutusunu güncellemeyi bir sonraki event loop turuna ertele.
            // Aksi halde onTextChanged içinden tekrar text değiştirmek
            // özyinelemeli tetiklenmeye yol açıp arayüzü kilitleyebilir.
            Qt.callLater(function() {
                patternInput.text = trimmedTokens.join("+")
                statusLabel.text = "Uyarı: 20'den fazla vuruş giremezsiniz. Fazla vuruşlar silindi."
            })

            return true
        }

        beatValues = vals
        var newDum = []
        for (var j = 0; j < vals.length; j++) newDum.push(dumPattern[j] === true)
        dumPattern = newDum
        patternRepeater.model = 0
        patternRepeater.model = vals.length
        return true
    }

    // ADIM D: ADIM C + nota yazma döngüsü (TAM VERSİYON)
    function createUsulPart() {
        if (typeof curScore === "undefined" || curScore === null) {
            statusLabel.text = "Açık bir nota bulunamadı."
            return
        }

        if (!parsePattern(patternInput.text)) {
            statusLabel.text = "Hata: Geçersiz format."
            return
        }

        var usulName = usulNameField.text.trim()
        if (usulName.length === 0) usulName = "Usul"

        var beatCount = beatValues.length
        var startTick = 0

        var startCursor = curScore.newCursor()
        startCursor.rewind(Cursor.SELECTION_START)
        if (startCursor.segment) {
            startTick = startCursor.tick
        } else {
            startCursor.rewind(Cursor.SCORE_START)
            startTick = startCursor.tick
        }

        var sig = calcTimeSig()
        curScore.startCmd()
        var ts = newElement(Element.TIMESIG)
        ts.timesig = fraction(sig.num, sig.denom)
        var tsCursor = curScore.newCursor()
        tsCursor.rewindToTick(startTick)
        tsCursor.add(ts)
        curScore.endCmd()

        curScore.startCmd()
        curScore.appendPart("drumset")
        curScore.endCmd()

        var staffIdx = curScore.nstaves - 1
        var totalMeasures = curScore.nmeasures
        var track = staffIdx * 4

        var startMeasure = curScore.firstMeasure
        var mm = startMeasure
        while (mm && mm.nextMeasure && mm.firstSegment.tick < startTick) {
            mm = mm.nextMeasure
        }
        startMeasure = mm

        curScore.startCmd()

        var stc = curScore.newCursor()
        stc.track = track
        stc.rewindToTick(startMeasure.firstSegment.tick)
        var st = newElement(Element.STAFF_TEXT)
        st.text = usulName
        stc.add(st)

        var measureCount = 0
        var measure = startMeasure

        while (measure && measureCount < totalMeasures) {
            var cur = curScore.newCursor()
            cur.track = track
            cur.rewindToTick(measure.firstSegment.tick)

            for (var b = 0; b < beatCount; b++) {
                var isStrong = (dumPattern.length > b) ? dumPattern[b] === true : false
                var tck = beatValues[b]
                var isDoTed = (tck === 1440 || tck === 720 || tck === 360 || tck === 180)

                if (isDoTed) {
                    var nd = 0
                    if      (tck === 720)  nd = 8
                    else if (tck === 360)  nd = 16
                    else if (tck === 1440) nd = 4
                    else if (tck === 180)  nd = 32
                    cur.setDuration(3, nd)
                    cur.addNote(isStrong ? dumPitch : tekPitch, false)
                } else {
                    var denom = Math.round(1920 / tck)
                    cur.setDuration(1, denom)
                    cur.addNote(isStrong ? dumPitch : tekPitch, false)
                }
            }

            measure = measure.nextMeasure
            measureCount++
        }

        curScore.endCmd()

        statusLabel.text = "\"" + usulName + "\" (" + sig.num + "/" + sig.denom + ") "
                         + measureCount + " ölçüye eklendi."
    }

    Rectangle {
        anchors.fill: parent
        color: "#d9d9d9"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 420
                wrapMode: Text.WordWrap
                text: "1 - Usul adını yazın (Dizeğin üstüne metin olarak ekler)."
                font.bold: true
                color: "black"
            }
            TextField {
                id: usulNameField
                Layout.fillWidth: true
                placeholderText: "Örn. Aksak, Düyek, Sofyan, Curcuna..."
                color: "black"
                background: Rectangle { color: "white"; border.color: "#aaa"; radius: 3 }
            }

            Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 420
                wrapMode: Text.WordWrap
                text: "2 - Usul'ün ritmini harflerin arasına \"+\" (artı) işaretini girerek yazın. İkilik nota için (i), dörtlük nota için (d), sekizlik nota için (s) onaltılık nota için de (o) harflerini kullanın. Noktalı notalar için harfin yanına \".\" nokta koyun( d. gibi) Örneğin Semai usulü için \"d+d+d\", Sofyan usulü için \"i+d+d\",  Düyek usulü için \"s+d+s+d+d\" ya da Türk Halk Müziği 7/8'lik usul'ü için \"d+d+d.\" yazın."
                font.bold: true
                color: "black"
            }

            // Nota değeri referans tablosu (SVG ile çizilmiş)
            Image {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                sourceSize.width: 680
                sourceSize.height: 58
                fillMode: Image.PreserveAspectFit
                source: "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjgwIiBoZWlnaHQ9IjU4IiB2aWV3Qm94PSIwIDAgNjgwIDU4IiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSg0MiwyNCkiPgogIDxlbGxpcHNlIGN4PSIwIiBjeT0iMCIgcng9IjYuNSIgcnk9IjQuMyIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIgdHJhbnNmb3JtPSJyb3RhdGUoLTIwKSIvPgogIDxsaW5lIHgxPSI2LjEiIHkxPSItMS44IiB4Mj0iNi4xIiB5Mj0iLTE5IiBzdHJva2U9IiM0NDQ0NDQiIHN0cm9rZS13aWR0aD0iMS4zIi8+CiAgPGNpcmNsZSBjeD0iMTAiIGN5PSIwIiByPSIxLjYiIGZpbGw9IiM0NDQ0NDQiLz4KPC9nPgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxMjcsMjQpIj4KICA8ZWxsaXBzZSBjeD0iMCIgY3k9IjAiIHJ4PSI2LjUiIHJ5PSI0LjMiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiIHRyYW5zZm9ybT0icm90YXRlKC0yMCkiLz4KICA8bGluZSB4MT0iNi4xIiB5MT0iLTEuOCIgeDI9IjYuMSIgeTI9Ii0xOSIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIvPgo8L2c+CjxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDIxMiwyNCkiPgogIDxlbGxpcHNlIGN4PSIwIiBjeT0iMCIgcng9IjYuNSIgcnk9IjQuMyIgZmlsbD0iIzQ0NDQ0NCIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIgdHJhbnNmb3JtPSJyb3RhdGUoLTIwKSIvPgogIDxsaW5lIHgxPSI2LjEiIHkxPSItMS44IiB4Mj0iNi4xIiB5Mj0iLTE5IiBzdHJva2U9IiM0NDQ0NDQiIHN0cm9rZS13aWR0aD0iMS4zIi8+CiAgPGNpcmNsZSBjeD0iMTAiIGN5PSIwIiByPSIxLjYiIGZpbGw9IiM0NDQ0NDQiLz4KPC9nPgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgyOTcsMjQpIj4KICA8ZWxsaXBzZSBjeD0iMCIgY3k9IjAiIHJ4PSI2LjUiIHJ5PSI0LjMiIGZpbGw9IiM0NDQ0NDQiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiIHRyYW5zZm9ybT0icm90YXRlKC0yMCkiLz4KICA8bGluZSB4MT0iNi4xIiB5MT0iLTEuOCIgeDI9IjYuMSIgeTI9Ii0xOSIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIvPgo8L2c+CjxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDM4MiwyNCkiPgogIDxlbGxpcHNlIGN4PSIwIiBjeT0iMCIgcng9IjYuNSIgcnk9IjQuMyIgZmlsbD0iIzQ0NDQ0NCIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIgdHJhbnNmb3JtPSJyb3RhdGUoLTIwKSIvPgogIDxsaW5lIHgxPSI2LjEiIHkxPSItMS44IiB4Mj0iNi4xIiB5Mj0iLTE5IiBzdHJva2U9IiM0NDQ0NDQiIHN0cm9rZS13aWR0aD0iMS4zIi8+CiAgPHBhdGggZD0iTTYuMSwtMTkgUTE0LC0xNCA5LC03LjUiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiLz4KICA8Y2lyY2xlIGN4PSIxMS41IiBjeT0iMCIgcj0iMS42IiBmaWxsPSIjNDQ0NDQ0Ii8+CjwvZz4KPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNDY3LDI0KSI+CiAgPGVsbGlwc2UgY3g9IjAiIGN5PSIwIiByeD0iNi41IiByeT0iNC4zIiBmaWxsPSIjNDQ0NDQ0IiBzdHJva2U9IiM0NDQ0NDQiIHN0cm9rZS13aWR0aD0iMS4zIiB0cmFuc2Zvcm09InJvdGF0ZSgtMjApIi8+CiAgPGxpbmUgeDE9IjYuMSIgeTE9Ii0xLjgiIHgyPSI2LjEiIHkyPSItMTkiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiLz4KICA8cGF0aCBkPSJNNi4xLC0xOSBRMTQsLTE0IDksLTcuNSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIvPgo8L2c+CjxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDU1MiwyNCkiPgogIDxlbGxpcHNlIGN4PSIwIiBjeT0iMCIgcng9IjYuNSIgcnk9IjQuMyIgZmlsbD0iIzQ0NDQ0NCIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIgdHJhbnNmb3JtPSJyb3RhdGUoLTIwKSIvPgogIDxsaW5lIHgxPSI2LjEiIHkxPSItMS44IiB4Mj0iNi4xIiB5Mj0iLTE5IiBzdHJva2U9IiM0NDQ0NDQiIHN0cm9rZS13aWR0aD0iMS4zIi8+CiAgPHBhdGggZD0iTTYuMSwtMTkgUTE0LC0xNCA5LC03LjUiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiLz4KICA8cGF0aCBkPSJNNi4xLC0xNSBRMTQsLTEwIDksLTMuNSIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIvPgogIDxjaXJjbGUgY3g9IjExLjUiIGN5PSIwIiByPSIxLjYiIGZpbGw9IiM0NDQ0NDQiLz4KPC9nPgo8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSg2MzcsMjQpIj4KICA8ZWxsaXBzZSBjeD0iMCIgY3k9IjAiIHJ4PSI2LjUiIHJ5PSI0LjMiIGZpbGw9IiM0NDQ0NDQiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiIHRyYW5zZm9ybT0icm90YXRlKC0yMCkiLz4KICA8bGluZSB4MT0iNi4xIiB5MT0iLTEuOCIgeDI9IjYuMSIgeTI9Ii0xOSIgc3Ryb2tlPSIjNDQ0NDQ0IiBzdHJva2Utd2lkdGg9IjEuMyIvPgogIDxwYXRoIGQ9Ik02LjEsLTE5IFExNCwtMTQgOSwtNy41IiBmaWxsPSJub25lIiBzdHJva2U9IiM0NDQ0NDQiIHN0cm9rZS13aWR0aD0iMS4zIi8+CiAgPHBhdGggZD0iTTYuMSwtMTUgUTE0LC0xMCA5LC0zLjUiIGZpbGw9Im5vbmUiIHN0cm9rZT0iIzQ0NDQ0NCIgc3Ryb2tlLXdpZHRoPSIxLjMiLz4KPC9nPgo8bGluZSB4MT0iMjAiIHkxPSIzNCIgeDI9IjY2MCIgeTI9IjM0IiBzdHJva2U9IiNkZGRkZGQiIHN0cm9rZS13aWR0aD0iMC41Ii8+Cjx0ZXh0IHg9IjQyIiB5PSI0OCIgZm9udC1zaXplPSIxNCIgZm9udC13ZWlnaHQ9IjYwMCIgZmlsbD0iI2MwMzkyYiIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIHRleHQtYW5jaG9yPSJtaWRkbGUiPmkuPC90ZXh0Pgo8dGV4dCB4PSIxMjciIHk9IjQ4IiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iNjAwIiBmaWxsPSIjYzAzOTJiIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+aTwvdGV4dD4KPHRleHQgeD0iMjEyIiB5PSI0OCIgZm9udC1zaXplPSIxNCIgZm9udC13ZWlnaHQ9IjYwMCIgZmlsbD0iI2MwMzkyYiIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIHRleHQtYW5jaG9yPSJtaWRkbGUiPmQuPC90ZXh0Pgo8dGV4dCB4PSIyOTciIHk9IjQ4IiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iNjAwIiBmaWxsPSIjYzAzOTJiIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+ZDwvdGV4dD4KPHRleHQgeD0iMzgyIiB5PSI0OCIgZm9udC1zaXplPSIxNCIgZm9udC13ZWlnaHQ9IjYwMCIgZmlsbD0iI2MwMzkyYiIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIHRleHQtYW5jaG9yPSJtaWRkbGUiPnMuPC90ZXh0Pgo8dGV4dCB4PSI0NjciIHk9IjQ4IiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iNjAwIiBmaWxsPSIjYzAzOTJiIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+czwvdGV4dD4KPHRleHQgeD0iNTUyIiB5PSI0OCIgZm9udC1zaXplPSIxNCIgZm9udC13ZWlnaHQ9IjYwMCIgZmlsbD0iI2MwMzkyYiIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIHRleHQtYW5jaG9yPSJtaWRkbGUiPm8uPC90ZXh0Pgo8dGV4dCB4PSI2MzciIHk9IjQ4IiBmb250LXNpemU9IjE0IiBmb250LXdlaWdodD0iNjAwIiBmaWxsPSIjYzAzOTJiIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+bzwvdGV4dD4KPC9zdmc+Cg=="
            }

            RowLayout {
                spacing: 8
                TextField {
                    id: patternInput
                    Layout.fillWidth: true
                    text: "d+d+d+d"
                    placeholderText: "Örn: i+d+d  veya  s+s+s+s+s+s+s+s+s"
                    onTextChanged: parsePattern(text)
                    color: "black"
                    // Geçersiz karakter içeriyorsa kenarlık kırmızı olur
                    property bool hasInvalidChar: /[^idso.+]/i.test(text)
                    background: Rectangle {
                        color: "white"
                        border.color: patternInput.hasInvalidChar ? "#c0392b" : "#aaa"
                        border.width: patternInput.hasInvalidChar ? 2 : 1
                        radius: 3
                    }
                }
                Label {
                    text: {
                        var sig = calcTimeSig()
                        return sig.num + "/" + sig.denom
                    }
                    font.bold: true
                    font.pixelSize: 18
                    color: "#c0392b"
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 420
                wrapMode: Text.WordWrap
                text: "3 - Kuvvetli olmasını istediğiniz nota için kutucuğu işaretleyin, işaretsiz bırakılanlar zayıf olarak çalınacaktır."
                font.bold: true
                color: "black"
            }

            Flow {
                id: patternFlow
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    id: patternRepeater
                    model: 4

                    delegate: RowLayout {
                        spacing: 4
                        ColumnLayout {
                            spacing: 2
                            Label {
                                text: beatValues.length > index ? tickToLetter(beatValues[index]) : "?"
                                Layout.alignment: Qt.AlignHCenter
                                font.pixelSize: 13
                                font.bold: true
                                color: "#c0392b"
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
                        Label {
                            text: "+"
                            font.pixelSize: 14
                            font.bold: true
                            color: "black"
                            visible: index < patternRepeater.model - 1
                        }
                    }
                }
            }

            Label {
                id: statusLabel
                text: ""
                color: "black"
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
                    id: olusturBtn
                    text: "Oluştur"
                    highlighted: true
                    onClicked: createUsulPart()
                }
            }

            Label {
                text: "Geliştiren: B. Orkun ARAPOĞLU  •  orkuun@gmail.com"
                font.pixelSize: 10
                color: "black"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
