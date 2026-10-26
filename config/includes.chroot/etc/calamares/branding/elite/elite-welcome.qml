/* EliteLinux: экран «Добро пожаловать» — логотип, железо ПК и проверка требований.
 * Данные о железе готовит elite-installer в /run/elite/hardware.json. */
import QtQuick

Rectangle {
    id: root
    color: "#232325"
    property var hw: ({ cpu: "…", cores: 0, ramGb: 0, board: "—", serial: "—", gpu: "—", disks: [], nics: [] })
    readonly property real minRamGb: 3.5
    readonly property int minDiskGb: 60

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.responseText.length > 0)
                root.hw = JSON.parse(xhr.responseText);
        };
        xhr.open("GET", "file:///run/elite/hardware.json");
        xhr.send();
    }

    function maxDiskGb() {
        var m = 0;
        for (var i = 0; i < hw.disks.length; i++) m = Math.max(m, parseInt(hw.disks[i].size));
        return m;
    }
    function warnings() {
        var w = [];
        if (hw.ramGb > 0 && hw.ramGb < minRamGb) w.push("Оперативной памяти " + hw.ramGb + " ГБ — меньше рекомендуемых 4 ГБ, система будет работать медленно.");
        if (hw.disks.length > 0 && maxDiskGb() < minDiskGb) w.push("Самый большой диск меньше " + minDiskGb + " ГБ — места может не хватить.");
        if (hw.disks.length === 0) w.push("Не найдено ни одного диска для установки.");
        return w;
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 760)
        spacing: 22

        Image { source: "logo.png"; height: 110; fillMode: Image.PreserveAspectFit; anchors.horizontalCenter: parent.horizontalCenter }
        Image { source: "wordmark.png"; width: 420; fillMode: Image.PreserveAspectFit; anchors.horizontalCenter: parent.horizontalCenter }

        Text {
            text: "Установка EliteLinux на этот компьютер"
            color: "#ececec"; font.pixelSize: 22; font.weight: Font.DemiBold
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: parent.width; height: hwColumn.height + 32
            color: "#1c1c1e"; radius: 10; border.color: "#313134"
            Column {
                id: hwColumn
                x: 20; y: 16; width: parent.width - 40; spacing: 7
                Repeater {
                    model: [
                        ["Процессор", root.hw.cpu + (root.hw.cores ? "  (" + root.hw.cores + " потоков)" : "")],
                        ["Память", root.hw.ramGb + " ГБ"],
                        ["Видеокарта", root.hw.gpu],
                        ["Плата", root.hw.board + (root.hw.serial !== "—" ? "  ·  S/N " + root.hw.serial : "")]
                    ].concat(root.hw.disks.map(function(d) { return ["Диск " + d.name, d.size + "  ·  " + d.type + "  ·  " + d.model]; }))
                     .concat(root.hw.nics.map(function(n) { return ["Сеть " + n.name, n.type + "  ·  " + n.mac]; }))
                    Row {
                        spacing: 12
                        Text { text: modelData[0]; color: "#a9a9ae"; font.pixelSize: 15; width: 130 }
                        Text { text: modelData[1]; color: "#ececec"; font.pixelSize: 15; width: hwColumn.width - 142; elide: Text.ElideRight }
                    }
                }
            }
        }

        Repeater {
            model: root.warnings()
            Rectangle {
                width: parent.width; height: warnText.height + 20
                color: "#3a2e17"; radius: 8; border.color: "#d4b06a"
                Text { id: warnText; x: 14; y: 10; width: parent.width - 28; wrapMode: Text.WordWrap
                       text: "⚠  " + modelData; color: "#f0d9a6"; font.pixelSize: 14 }
            }
        }

        Text {
            visible: root.warnings().length === 0
            text: "Компьютер подходит для установки. Нажмите «Далее», чтобы выбрать диск."
            color: "#a9a9ae"; font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
