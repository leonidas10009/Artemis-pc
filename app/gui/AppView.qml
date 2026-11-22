import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

import AppModel 1.0
import ComputerManager 1.0
import SdlGamepadKeyNavigation 1.0
import StreamingPreferences 1.0
import Artemis 1.0

CenteredGridView {
    property int computerIndex
    property AppModel appModel : createModel()
    property bool activated
    property bool showHiddenGames
    property bool showGames
    property bool remoteDesktop
    property string statusText: appGrid.count + (appGrid.count === 1 ? qsTr(" app") : qsTr(" apps"))

    id: appGrid
    focus: true
    activeFocusOnTab: true
    topMargin: 20
    bottomMargin: 5
    cellWidth: 230; cellHeight: 297;


    function computerLost()
    {
        // Go back to the PC view on PC loss
        stackView.pop()
    }

    Component.onCompleted: {
        // Don't show any highlighted item until interacting with them.
        // We do this here instead of onActivated to avoid losing the user's
        // selection when backing out of a different page of the app.
        currentIndex = -1
    }

    StackView.onActivated: {
        appModel.computerLost.connect(computerLost)
        activated = true

        // Highlight the first item if a gamepad is connected
        if (currentIndex === -1 && SdlGamepadKeyNavigation.getConnectedGamepads() > 0) {
            currentIndex = 0
        }

        if (remoteDesktop && !showGames) {
            // "Remote desktop" from the PC context menu: use the host's
            // Desktop app and absolute mouse mode for a TeamViewer-like
            // experience.
            var desktopIndex = model.getDesktopAppIndex()
            if (desktopIndex >= 0) {
                StreamingPreferences.absoluteMouseMode = true
                StreamingPreferences.save()
                currentIndex = desktopIndex
                currentItem.launchOrResumeSelectedApp(true)
            }
            else {
                remoteDesktopUnavailableDialog.open()
            }

            // Don't retry automatically when returning from the stream.
            showGames = true
        }
        else if (!showGames && !showHiddenGames) {
            // Check if there's a direct launch app
            var directLaunchAppIndex = model.getDirectLaunchAppIndex();
            if (directLaunchAppIndex >= 0) {
                // Start the direct launch app if nothing else is running
                currentIndex = directLaunchAppIndex
                currentItem.launchOrResumeSelectedApp(false)

                // Set showGames so we will not loop when the stream ends
                showGames = true
            }
        }
    }

    StackView.onDeactivating: {
        appModel.computerLost.disconnect(computerLost)
        activated = false
    }

    function createModel()
    {
        var model = Qt.createQmlObject('import AppModel 1.0; AppModel {}', parent, '')
        model.initialize(ComputerManager, computerIndex, showHiddenGames)
        return model
    }

    model: appModel

    delegate: NavigableItemDelegate {
        width: 220; height: 287;
        grid: appGrid
        padding: 0
        clip: true

        property alias appContextMenu: appContextMenuLoader.item
        property alias appNameText: appNameTextLoader.item

        // Dim the app if it's hidden
        opacity: model.hidden ? 0.4 : 1.0

        background: Rectangle {
            radius: 14
            color: Theme.colors.surface
            border.width: highlighted ? 2 : 1
            border.color: highlighted ? Theme.colors.primary : Theme.colors.border
        }

        // Blurred/darkened backdrop made from the app art itself
        Image {
            id: appBackground
            anchors.fill: parent
            anchors.margins: 2
            source: model.boxart
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0.38
            scale: 1.12
            visible: !appIcon.isPlaceholder
        }

        Image {
            property bool isPlaceholder: false

            id: appIcon
            anchors.centerIn: parent
            source: model.boxart
            fillMode: Image.PreserveAspectFit
            opacity: isPlaceholder ? 0 : 1

            onSourceSizeChanged: {
                // Nearly all of Nvidia's official box art does not match the dimensions of placeholder
                // images, however the one known exception is Overcooked. Therefore, we only execute
                // the image size checks if this is not an app collector game. We know the officially
                // supported games all have box art, so this check is not required.
                if (!model.isAppCollectorGame &&
                    ((sourceSize.width === 130 && sourceSize.height === 180) || // GFE 2.0 placeholder image
                     (sourceSize.width === 628 && sourceSize.height === 888) || // GFE 3.0 placeholder image
                     (sourceSize.width === 200 && sourceSize.height === 266)))  // Our no_app_image.png
                {
                    isPlaceholder = true
                }
                else
                {
                    isPlaceholder = false
                }

                width = parent.width - 12
                height = parent.height - 12
            }

            // Display a tooltip with the full name if it's truncated
            ToolTip.text: model.name
            ToolTip.delay: 1000
            ToolTip.timeout: 5000
            ToolTip.visible: (parent.hovered || parent.highlighted) && (!appNameText || appNameText.truncated)
        }

        // Clean placeholder tile for apps without real box art
        Rectangle {
            id: placeholderTile
            visible: appIcon.isPlaceholder
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -14
            width: 104
            height: 104
            radius: 24
            color: Theme.colors.surfaceRaised
            border.width: 1
            border.color: Theme.colors.border

            Label {
                anchors.centerIn: parent
                text: model.name.length > 0 ? model.name.charAt(0).toUpperCase() : "?"
                font.pointSize: 44
                font.bold: true
                color: Theme.colors.primary
            }
        }

        // Bottom scrim to keep the app name readable over any artwork
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 12
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.58; color: Theme.alpha(Theme.colors.bgBase, 0.0) }
                GradientStop { position: 0.78; color: Theme.alpha(Theme.colors.bgBase, 0.72) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.colors.bgBase, 0.98) }
            }
        }

        Loader {
            active: model.running
            asynchronous: true
            z: 1
            anchors.fill: parent

            sourceComponent: Row {
                spacing: 12
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 58

                RoundButton {
                    // Don't steal focus from the toolbar buttons
                    focusPolicy: Qt.NoFocus

                    implicitWidth: 56
                    implicitHeight: 56

                    icon.source: "qrc:/res/play_arrow_FILL1_wght700_GRAD200_opsz48.svg"
                    icon.width: 40
                    icon.height: 40
                    icon.color: "#FFFFFF"

                    onClicked: launchOrResumeSelectedApp(true)

                    ToolTip.text: qsTr("Resume Game")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 3000
                    ToolTip.visible: hovered

                    Material.background: "#D0131620"
                }

                RoundButton {
                    // Don't steal focus from the toolbar buttons
                    focusPolicy: Qt.NoFocus

                    implicitWidth: 56
                    implicitHeight: 56

                    icon.source: "qrc:/res/stop_FILL1_wght700_GRAD200_opsz48.svg"
                    icon.width: 40
                    icon.height: 40
                    icon.color: "#FFFFFF"

                    onClicked: doQuitGame()

                    ToolTip.text: qsTr("Quit Game")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 3000
                    ToolTip.visible: hovered

                    Material.background: "#D0131620"
                }
            }
        }

        Loader {
            id: appNameTextLoader
            active: true

            // This loader is not asynchronous to avoid noticeable differences
            // in the time in which the text loads for each game.

            width: parent.width - 24
            height: 48

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            sourceComponent: Label {
                id: appNameText
                text: model.name
                font.pointSize: 11
                font.bold: true
                color: Theme.colors.textBase
                leftPadding: 6
                rightPadding: 6
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        // Rounded border on top of the artwork
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            border.width: highlighted ? 2 : 1
            border.color: highlighted ? Theme.colors.primary : Theme.colors.border
        }

        scale: highlighted ? 1.015 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }

        function launchOrResumeSelectedApp(quitExistingApp)
        {
            var runningId = appModel.getRunningAppId()
            if (runningId !== 0 && runningId !== model.appid) {
                if (quitExistingApp) {
                    quitAppDialog.appName = appModel.getRunningAppName()
                    quitAppDialog.segueToStream = true
                    quitAppDialog.nextAppName = model.name
                    quitAppDialog.nextAppIndex = index
                    quitAppDialog.open()
                }

                return
            }

            var component = Qt.createComponent("StreamSegue.qml")
            var segue = component.createObject(stackView, {
                                                   "appName": model.name,
                                                   "session": appModel.createSessionForApp(index),
                                                   "isResume": runningId === model.appid
                                               })
            stackView.push(segue)
        }

        onClicked: {
            // Single click launches a stopped app or resumes the running
            // one. The explicit Resume/Quit buttons remain available on the
            // card for running games.
            launchOrResumeSelectedApp(true)
        }

        onPressAndHold: {
            // popup() ensures the menu appears under the mouse cursor
            if (appContextMenu.popup) {
                appContextMenu.popup()
            }
            else {
                // Qt 5.9 doesn't have popup()
                appContextMenu.open()
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton;

            // Let left clicks reach the ItemDelegate so a single click can
            // launch or resume the app.
            onPressed: function(mouse) {
                mouse.accepted = (mouse.button === Qt.RightButton)
            }

            onClicked: {
                parent.pressAndHold()
            }
        }

        Keys.onReturnPressed: {
            clicked()
        }

        Keys.onEnterPressed: {
            clicked()
        }

        Keys.onMenuPressed: {
            // This will be keyboard/gamepad driven so use open() instead of popup()
            appContextMenu.open()
        }

        function doQuitGame() {
            quitAppDialog.appName = appModel.getRunningAppName()
            quitAppDialog.segueToStream = false
            quitAppDialog.open()
        }

        Loader {
            id: appContextMenuLoader
            asynchronous: true
            sourceComponent: NavigableMenu {
                id: appContextMenu
                initiator: appContextMenuLoader.parent
                NavigableMenuItem {
                    text: model.running ? qsTr("Resume Game") : qsTr("Launch Game")
                    onTriggered: launchOrResumeSelectedApp(true)
                }
                NavigableMenuItem {
                    text: qsTr("Open in remote desktop mode")
                    onTriggered: {
                        StreamingPreferences.absoluteMouseMode = true
                        StreamingPreferences.save()
                        launchOrResumeSelectedApp(true)
                    }

                    ToolTip.text: qsTr("Use absolute mouse mode so the client cursor controls the host desktop directly")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                }
                NavigableMenuItem {
                    text: qsTr("Quit Game")
                    onTriggered: doQuitGame()
                    visible: model.running
                }
                NavigableMenuItem {
                    checkable: true
                    checked: model.directLaunch
                    text: qsTr("Direct Launch")
                    onTriggered: appModel.setAppDirectLaunch(model.index, !model.directLaunch)
                    enabled: !model.hidden

                    ToolTip.text: qsTr("Launch this app immediately when the host is selected, bypassing the app selection grid.")
                    ToolTip.delay: 1000
                    ToolTip.timeout: 3000
                    ToolTip.visible: hovered
                }
                NavigableMenuItem {
                    checkable: true
                    checked: model.hidden
                    text: qsTr("Hide Game")
                    onTriggered: appModel.setAppHidden(model.index, !model.hidden)
                    enabled: model.hidden || (!model.running && !model.directLaunch)

                    ToolTip.text: qsTr("Hide this game from the app grid. To access hidden games, right-click on the host and choose %1.").arg(qsTr("View All Apps"))
                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                }
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 5
        visible: appGrid.count === 0

        Label {
            text: qsTr("This computer doesn't seem to have any applications or some applications are hidden")
            font.pointSize: 20
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }

    NavigableMessageDialog {
        id: quitAppDialog
        property string appName : ""
        property bool segueToStream : false
        property string nextAppName: ""
        property int nextAppIndex: 0
        text:qsTr("Are you sure you want to quit %1? Any unsaved progress will be lost.").arg(appName)
        standardButtons: Dialog.Yes | Dialog.No

        function quitApp() {
            var component = Qt.createComponent("QuitSegue.qml")
            var params = {"appName": appName, "quitRunningAppFn": function() { appModel.quitRunningApp() }}
            if (segueToStream) {
                // Store the session and app name if we're going to stream after
                // successfully quitting the old app.
                params.nextAppName = nextAppName
                params.nextSession = appModel.createSessionForApp(nextAppIndex)
            }
            else {
                params.nextAppName = null
                params.nextSession = null
            }

            stackView.push(component.createObject(stackView, params))
        }

        onAccepted: quitApp()
    }

    NavigableMessageDialog {
        id: remoteDesktopUnavailableDialog
        text: qsTr("This host does not expose a Desktop app. Add a desktop app in Apollo/Sunshine or launch an app manually.")
        standardButtons: Dialog.Ok
        imageSrc: "qrc:/res/baseline-warning-24px.svg"
    }

    ScrollBar.vertical: ScrollBar {}
}
