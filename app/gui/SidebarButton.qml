import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Artemis 1.0

Button {
    id: control

    property string iconSourceDark
    property string iconSourceLight

    Layout.fillWidth: true
    height: 42
    flat: true
    padding: 10

    contentItem: RowLayout {
        spacing: 10

        Image {
            source: Theme.isDark ? control.iconSourceDark : control.iconSourceLight
            sourceSize { width: 20; height: 20 }
        }

        Label {
            text: control.text
            font.pointSize: 11
            color: Theme.colors.textBase
            Layout.fillWidth: true
            elide: Label.ElideRight
        }
    }

    background: Rectangle {
        radius: 8
        color: control.hovered ? Theme.colors.bgMuted : "transparent"
    }
}
