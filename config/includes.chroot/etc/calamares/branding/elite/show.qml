/* EliteLinux: слайды во время установки — паспорт ПК вместо рекламы.
 * Данные — /run/elite/hardware.json (готовит elite-installer). */
import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation
    property var hw: ({ cpu: "…", cores: 0, ramGb: 0, board: "—", serial: "—", gpu: "—", disks: [], nics: [] })

    function onActivate() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText.length > 0)
                presentation.hw = JSON.parse(xhr.responseText);
        };
        xhr.open("GET", "file:///run/elite/hardware.json");
        xhr.send();
    }
    function onLeave() {}

    Timer { interval: 12000; running: presentation.activatedInCalamares; repeat: true; onTriggered: presentation.goToNextSlide() }

    component InfoSlide: Slide {
        id: slide
        property string title
        property var rows: []
        Rectangle { anchors.fill: parent; color: "#232325" }
        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 720)
            spacing: 16
            Image { source: "logo.png"; height: 70; fillMode: Image.PreserveAspectFit; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: slide.title; color: "#d4b06a"; font.pixelSize: 24; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
            Repeater {
                model: slide.rows
                Row {
                    spacing: 14
                    Text { text: modelData[0]; color: "#a9a9ae"; font.pixelSize: 17; width: 170 }
                    Text { text: modelData[1]; color: "#ececec"; font.pixelSize: 17; width: 520; wrapMode: Text.WordWrap }
                }
            }
        }
    }

    InfoSlide {
        title: "Паспорт ПК"
        rows: [
            ["Процессор", presentation.hw.cpu],
            ["Потоков", "" + presentation.hw.cores],
            ["Память", presentation.hw.ramGb + " ГБ"],
            ["Видеокарта", presentation.hw.gpu],
            ["Плата", presentation.hw.board],
            ["Серийный №", presentation.hw.serial]
        ]
    }
    InfoSlide {
        title: "Диски и сеть"
        rows: presentation.hw.disks.map(function(d) { return ["Диск " + d.name, d.size + " · " + d.type + " · " + d.model]; })
              .concat(presentation.hw.nics.map(function(n) { return ["Сеть " + n.name, n.type + " · " + n.mac]; }))
    }
    InfoSlide {
        title: "После установки"
        rows: [
            ["Паспорт ПК", "сохраняется в /etc/elite/hardware.txt"],
            ["Учётки", "Менеджер и Администратор"],
            ["Имя ПК", "elite- и последние 6 символов MAC"],
            ["Флешка", "после установки — извлечь, ПК перезагрузится сам"]
        ]
    }
}
