import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import ComputerModel 1.0

import ComputerManager 1.0
import StreamingPreferences 1.0
import SystemProperties 1.0
import SdlGamepadKeyNavigation 1.0
import Artemis 1.0

CenteredGridView {
    property ComputerModel computerModel : createModel()
    property string statusText: pcGrid.count + (pcGrid.count === 1 ? qsTr(" PC") : qsTr(" PCs"))

    id: pcGrid
    focus: true
    activeFocusOnTab: true
    topMargin: 20
    bottomMargin: 5
    cellWidth: 290; cellHeight: 310;
    objectName: qsTr("Computers")


    onCountChanged: {
        // Keep the highlighted item valid when filtering
        if (currentIndex >= count) {
            currentIndex = count - 1
        }
    }

    Component.onCompleted: {
        // Don't show any highlighted item until interacting with them.
        // We do this here instead of onActivated to avoid losing the user's
        // selection when backing out of a different page of the app.
        currentIndex = -1

        ComputerManager.serverCmdCompleted.connect(function(error) {
            if (error !== undefined && error !== "") {
                powerResultDialog.text = error
                powerResultDialog.open()
            }
        })
    }

    // Note: Any initialization done here that is critical for streaming must
    // also be done in CliStartStreamSegue.qml, since this code does not run
    // for command-line initiated streams.
    StackView.onActivated: {
        // Setup signals on CM
        ComputerManager.computerAddCompleted.connect(addComplete)

        // Highlight the first item if a gamepad is connected
        if (currentIndex === -1 && SdlGamepadKeyNavigation.getConnectedGamepads() > 0) {
            currentIndex = 0
        }
    }

    StackView.onDeactivating: {
        ComputerManager.computerAddCompleted.disconnect(addComplete)
    }

    function pairingComplete(error)
    {
        // Close the PIN dialog
        pairDialog.close()

        // Display a failed dialog if we got an error
        if (error !== undefined) {
            errorDialog.text = error
            errorDialog.helpText = ""
            errorDialog.open()
        }
    }

    function addComplete(success, detectedPortBlocking)
    {
        if (!success) {
            errorDialog.text = qsTr("Unable to connect to the specified PC.")

            if (detectedPortBlocking) {
                errorDialog.text += "\n\n" + qsTr("This PC's Internet connection is blocking Artemis. Streaming over the Internet may not work while connected to this network.")
            }
            else {
                errorDialog.helpText = qsTr("Click the Help button for possible solutions.")
            }

            errorDialog.open()
        }
    }

    function createModel()
    {
        var model = Qt.createQmlObject('import ComputerModel 1.0; ComputerModel {}', parent, '')
        model.initialize(ComputerManager)
        model.pairingCompleted.connect(pairingComplete)
        model.connectionTestCompleted.connect(testConnectionDialog.connectionTestComplete)
        return model
    }

    Row {
        anchors.centerIn: parent
        spacing: 5
        visible: pcGrid.count === 0

        BusyIndicator {
            id: searchSpinner
            visible: StreamingPreferences.enableMdns
            running: visible
        }

        Label {
            height: searchSpinner.height
            elide: Label.ElideRight
            text: StreamingPreferences.enableMdns ? qsTr("Searching for compatible hosts on your local network...")
                                                  : qsTr("Automatic PC discovery is disabled. Add your PC manually.")
            font.pointSize: 20
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }

    model: computerModel

    delegate: NavigableItemDelegate {
        width: pcGrid.cellWidth - 10; height: pcGrid.cellHeight - 10;
        grid: pcGrid
        padding: 0

        property alias pcContextMenu : pcContextMenuLoader.item
        property int pcIndex: index
        property var apolloCommands: model.serverCommands

        background: Rectangle {
            radius: 14
            color: highlighted ? Theme.colors.surfaceRaised : Theme.colors.surface
            border.width: highlighted ? 2 : 1
            border.color: highlighted ? Theme.colors.primary : Theme.colors.border
        }

        function isPowerCommand(name) {
            var n = name.toLowerCase()
            return /apagar|shutdown|poweroff|power off|power-off|reiniciar|restart|reboot|cancelar apagado|cancel shutdown/.test(n)
        }

        function isCancelCommand(name) {
            return /cancelar|cancel|shutdown \/a/.test(name.toLowerCase())
        }

        Image {
            id: pcIcon
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 45
            source: Theme.isDark ? "qrc:/res/desktop_windows-48px.svg" : "qrc:/res/desktop_windows-48px-light.svg"
            sourceSize {
                width: 160
                height: 160
            }
        }

        Image {
            // TODO: Tooltip
            id: stateIcon
            anchors.horizontalCenter: pcIcon.horizontalCenter
            anchors.verticalCenter: pcIcon.verticalCenter
            anchors.verticalCenterOffset: !model.online ? -18 : -16
            visible: !model.statusUnknown && (!model.online || !model.paired)
            source: !model.online ? (Theme.isDark ? "qrc:/res/warning_FILL1_wght300_GRAD200_opsz24.svg" : "qrc:/res/warning_FILL1_wght300_GRAD200_opsz24-light.svg")
                                   : (Theme.isDark ? "qrc:/res/baseline-lock-24px.svg" : "qrc:/res/baseline-lock-24px-light.svg")
            sourceSize {
                width: !model.online ? 75 : 70
                height: !model.online ? 75 : 70
            }
        }

        BusyIndicator {
            id: statusUnknownSpinner
            anchors.horizontalCenter: pcIcon.horizontalCenter
            anchors.verticalCenter: pcIcon.verticalCenter
            anchors.verticalCenterOffset: -15
            width: 75
            height: 75
            visible: model.statusUnknown
            running: visible
        }

        Column {
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: pcIcon.bottom
            anchors.topMargin: 4
            spacing: 2

            Label {
                id: pcNameText
                text: model.name
                width: parent.width
                font.pointSize: 28
                font.bold: true
                color: Theme.colors.textBase
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }

            Label {
                width: parent.width
                visible: model.apolloHost
                text: qsTr("Apollo 2026")
                font.pointSize: 10
                color: Theme.colors.primary
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                width: parent.width
                visible: !model.online
                text: qsTr("Offline")
                font.pointSize: 10
                color: Theme.colors.textSubtle
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                width: parent.width
                visible: model.online && model.paired
                text: model.appCount === 1 ? qsTr("1 app") : qsTr("%1 apps").arg(model.appCount)
                font.pointSize: 9
                color: Theme.colors.textSubtle
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                width: parent.width
                visible: model.online && model.paired && model.apolloHost && !model.inputPermission
                text: qsTr("Input permissions missing")
                font.pointSize: 9
                font.bold: true
                color: Theme.colors.danger
                horizontalAlignment: Text.AlignHCenter
            }
        }

        RoundButton {
            id: remoteDesktopButton
            z: 1
            visible: model.online && model.paired && (parent.hovered || parent.highlighted)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            implicitWidth: 44
            implicitHeight: 44
            focusPolicy: Qt.NoFocus

            icon.source: Theme.isDark ? "qrc:/res/desktop_windows-48px.svg"
                                      : "qrc:/res/desktop_windows-48px-light.svg"
            icon.width: 26
            icon.height: 26

            ToolTip.text: qsTr("Remote desktop")
            ToolTip.delay: 500
            ToolTip.timeout: 3000
            ToolTip.visible: hovered

            onClicked: {
                var component = Qt.createComponent("AppView.qml")
                var appView = component.createObject(stackView, {
                    "computerIndex": pcIndex,
                    "objectName": model.name,
                    "remoteDesktop": true,
                    "showHiddenGames": true
                })
                stackView.push(appView)
            }
        }

        Loader {
            id: pcContextMenuLoader
            asynchronous: true
            sourceComponent: NavigableMenu {
                id: pcContextMenu
                initiator: pcContextMenuLoader.parent
                MenuItem {
                    text: qsTr("PC Status: %1").arg(model.online ? qsTr("Online") : qsTr("Offline"))
                    font.bold: true
                    enabled: false
                }
                NavigableMenuItem {
                    text: qsTr("View All Apps")
                    onTriggered: {
                        var component = Qt.createComponent("AppView.qml")
                        var appView = component.createObject(stackView, {"computerIndex": index, "objectName": model.name, "showHiddenGames": true})
                        stackView.push(appView)
                    }
                    visible: model.online && model.paired
                }
                NavigableMenuItem {
                    text: qsTr("Remote desktop")
                    onTriggered: {
                        var component = Qt.createComponent("AppView.qml")
                        var appView = component.createObject(stackView, {
                            "computerIndex": index,
                            "objectName": model.name,
                            "remoteDesktop": true,
                            "showHiddenGames": true
                        })
                        stackView.push(appView)
                    }
                    visible: model.online && model.paired

                    ToolTip.text: qsTr("Open the host Desktop in remote desktop mouse mode")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                }
                NavigableMenuItem {
                    text: qsTr("Resume Running App")
                    onTriggered: {
                        var session = computerModel.createSessionForCurrentGame(index)
                        if (session) {
                            var component = Qt.createComponent("StreamSegue.qml")
                            var segue = component.createObject(stackView, {
                                "appName": model.name,
                                "session": session,
                                "isResume": true
                            })
                            stackView.push(segue)
                        }
                    }
                    visible: model.online && model.paired && model.busy
                }
                NavigableMenuItem {
                    text: qsTr("Stream shortcuts...")
                    onTriggered: streamShortcutsDialog.open()
                }
                NavigableMenuItem {
                    text: qsTr("Wake PC")
                    onTriggered: computerModel.wakeComputer(index)
                    visible: !model.online && model.wakeable
                }
                NavigableMenuItem {
                    text: qsTr("Test Network")
                    onTriggered: {
                        computerModel.testConnectionForComputer(index)
                        testConnectionDialog.open()
                    }
                }

                Repeater {
                    model: apolloCommands

                    NavigableMenuItem {
                        property int commandIndex: index
                        text: modelData
                        visible: pcIndex !== undefined && isPowerCommand(modelData)
                        onTriggered: {
                            powerCmdDialog.pcIndex = pcIndex
                            powerCmdDialog.commandIndex = commandIndex
                            powerCmdDialog.commandName = modelData
                            powerCmdDialog.isCancel = isCancelCommand(modelData)
                            powerCmdDialog.open()
                        }
                    }
                }

                NavigableMenuItem {
                    text: qsTr("Apollo input permissions...")
                    visible: model.online && model.paired && model.apolloHost && !model.inputPermission
                    onTriggered: inputPermissionDialog.open()
                }

                NavigableMenuItem {
                    text: qsTr("Rename PC")
                    onTriggered: {
                        renamePcDialog.pcIndex = index
                        renamePcDialog.originalName = model.name
                        renamePcDialog.open()
                    }
                }
                NavigableMenuItem {
                    text: qsTr("Delete PC")
                    onTriggered: {
                        deletePcDialog.pcIndex = index
                        deletePcDialog.pcName = model.name
                        deletePcDialog.open()
                    }
                }
                NavigableMenuItem {
                    text: qsTr("View Details")
                    onTriggered: {
                        showPcDetailsDialog.pcDetails = model.details
                        showPcDetailsDialog.open()
                    }
                }
            }
        }

        onClicked: {
            if (model.online) {
                if (!model.serverSupported) {
                    errorDialog.text = qsTr("The version of GeForce Experience on %1 is not supported by this build of Artemis. You must update Artemis to stream from %1.").arg(model.name)
                    errorDialog.helpText = ""
                    errorDialog.open()
                }
                else if (model.paired) {
                    // go to game view
                    var component = Qt.createComponent("AppView.qml")
                    var appView = component.createObject(stackView, {"computerIndex": index, "objectName": model.name})
                    stackView.push(appView)
                }
                else {
                    var pin = computerModel.generatePinString()

                    // Kick off pairing in the background
                    computerModel.pairComputer(index, pin)

                    // Display the pairing dialog
                    pairDialog.pin = pin
                    pairDialog.open()
                }
            } else if (!model.online) {
                // Using open() here because it may be activated by keyboard
                pcContextMenu.open()
            }
        }

        onPressAndHold: {
            // popup() ensures the menu appears under the mouse cursor
            if (pcContextMenu.popup) {
                pcContextMenu.popup()
            }
            else {
                // Qt 5.9 doesn't have popup()
                pcContextMenu.open()
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton;

            // Let left clicks reach the ItemDelegate so the card opens the
            // host or the remote desktop button.
            onPressed: function(mouse) {
                mouse.accepted = (mouse.button === Qt.RightButton)
            }

            onClicked: {
                parent.pressAndHold()
            }
        }

        Keys.onMenuPressed: {
            // We must use open() here so the menu is positioned on
            // the ItemDelegate and not where the mouse cursor is
            pcContextMenu.open()
        }

        Keys.onDeletePressed: {
            deletePcDialog.pcIndex = index
            deletePcDialog.pcName = model.name
            deletePcDialog.open()
        }
    }

    ErrorMessageDialog {
        id: errorDialog

        // Using Setup-Guide here instead of Troubleshooting because it's likely that users
        // will arrive here by forgetting to enable GameStream or not forwarding ports.
        helpUrl: "https://github.com/leonidas10009/Artemis-pc"
    }

    NavigableMessageDialog {
        id: pairDialog
        closePolicy: Popup.CloseOnEscape

        // don't allow edits to the rest of the window while open
        property string pin : "0000"
        text:qsTr("Please enter %1 on your host PC. This dialog will close when pairing is completed.").arg(pin)+"\n\n"+
             qsTr("If your host PC is running Apollo, open its web UI to enter the PIN.")
        standardButtons: Dialog.Cancel
        onRejected: {
            // FIXME: We should interrupt pairing here
        }
    }

    NavigableMessageDialog {
        id: deletePcDialog
        // don't allow edits to the rest of the window while open
        property int pcIndex : -1
        property string pcName : ""
        text: qsTr("Are you sure you want to remove '%1'?").arg(pcName)
        standardButtons: Dialog.Yes | Dialog.No

        onAccepted: {
            computerModel.deleteComputer(pcIndex)
        }
    }

    NavigableMessageDialog {
        id: testConnectionDialog
        closePolicy: Popup.CloseOnEscape
        standardButtons: Dialog.Ok

        onAboutToShow: {
            testConnectionDialog.text = qsTr("Artemis is testing your network connection to determine if any required ports are blocked.") + "\n\n" + qsTr("This may take a few seconds…")
            showSpinner = true
        }

        function connectionTestComplete(result, blockedPorts)
        {
            if (result === -1) {
                text = qsTr("The network test could not be performed because none of Artemis's connection testing servers were reachable from this PC. Check your Internet connection or try again later.")
                imageSrc = "qrc:/res/baseline-warning-24px.svg"
            }
            else if (result === 0) {
                text = qsTr("This network does not appear to be blocking Artemis. If you still have trouble connecting, check your PC's firewall settings.") + "\n\n" + qsTr("Make sure Apollo is running and reachable on your gaming PC.")
                imageSrc = "qrc:/res/baseline-check_circle_outline-24px.svg"
            }
            else {
                text = qsTr("Your PC's current network connection seems to be blocking Artemis. Streaming over the Internet may not work while connected to this network.") + "\n\n" + qsTr("The following network ports were blocked:") + "\n"
                text += blockedPorts
                imageSrc = "qrc:/res/baseline-error_outline-24px.svg"
            }

            // Stop showing the spinner and show the image instead
            showSpinner = false
        }
    }

    NavigableDialog {
        id: renamePcDialog
        property string label: qsTr("Enter the new name for this PC:")
        property string originalName
        property int pcIndex : -1;

        standardButtons: Dialog.Ok | Dialog.Cancel

        onOpened: {
            // Force keyboard focus on the textbox so keyboard navigation works
            editText.forceActiveFocus()
        }

        onClosed: {
            editText.clear()
        }

        onAccepted: {
            if (editText.text) {
                computerModel.renameComputer(pcIndex, editText.text)
            }
        }

        ColumnLayout {
            Label {
                text: renamePcDialog.label
                font.bold: true
            }

            TextField {
                id: editText
                placeholderText: renamePcDialog.originalName
                Layout.fillWidth: true
                focus: true

                Keys.onReturnPressed: {
                    renamePcDialog.accept()
                }

                Keys.onEnterPressed: {
                    renamePcDialog.accept()
                }
            }
        }
    }

    NavigableMessageDialog {
        id: showPcDetailsDialog
        property string pcDetails : "";
        text: showPcDetailsDialog.pcDetails
        imageSrc: "qrc:/res/baseline-help_outline-24px.svg"
        standardButtons: Dialog.Ok
    }

    NavigableMessageDialog {
        id: streamShortcutsDialog
        text: qsTr("Remote desktop (Desktop app):") + "\n\n" +
              "Ctrl+F5   " + qsTr("Disconnect (the host app keeps running)") + "\n" +
              "Ctrl+F6   " + qsTr("Release or recapture the mouse and keyboard") + "\n" +
              "Ctrl+F7   " + qsTr("Toggle game / remote desktop mouse") + "\n" +
              "Ctrl+F8   " + qsTr("Toggle fullscreen") + "\n" +
              "Ctrl+F9   " + qsTr("Minimize the stream window") + "\n" +
              "Ctrl+F10  " + qsTr("Toggle the performance overlay") + "\n\n" +
              qsTr("Games and other apps: Ctrl+Alt+Shift+Q/E/Z/M/X/D/S") + "\n" +
              qsTr("Gamepad: Start+Select+L1+R1 to disconnect.")
        standardButtons: Dialog.Ok
        imageSrc: "qrc:/res/baseline-help_outline-24px.svg"
    }

    NavigableMessageDialog {
        id: powerCmdDialog
        property int pcIndex: -1
        property int commandIndex: -1
        property string commandName: ""
        property bool isCancel: false

        text: isCancel ? qsTr("Send '%1' to the host PC?").arg(commandName)
                       : qsTr("Are you sure you want to run '%1' on the host PC?").arg(commandName)
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            if (pcIndex >= 0 && commandIndex >= 0) {
                computerModel.execServerCmd(pcIndex, commandIndex)
            }
        }
    }

    NavigableMessageDialog {
        id: powerResultDialog
        standardButtons: Dialog.Ok
        imageSrc: "qrc:/res/baseline-error_outline-24px.svg"
    }

    NavigableMessageDialog {
        id: inputPermissionDialog
        text: qsTr("Apollo has not granted mouse and keyboard permissions to this client.") + "\n\n" +
              qsTr("Open Apollo's web UI, go to Clients, select this device and enable Mouse and Keyboard under Input permissions. The change applies to the next stream.")
        standardButtons: Dialog.Ok
        imageSrc: "qrc:/res/baseline-warning-24px.svg"
    }

    ScrollBar.vertical: ScrollBar {}
}
