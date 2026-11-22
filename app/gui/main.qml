import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtQuick.Controls.Material 2.2

import ComputerManager 1.0
import AutoUpdateChecker 1.0
import StreamingPreferences 1.0
import SystemProperties 1.0
import SdlGamepadKeyNavigation 1.0
import Artemis 1.0

ApplicationWindow {
    property bool pollingActive: false

    // Set by SettingsView to force the back operation to pop all
    // pages except the initial view. This is required when doing
    // a retranslate() because AppView breaks for some reason.
    property bool clearOnBack: false

    property bool updateAvailable: false
    property string updateVersion: ""
    property string updateUrl: ""

    id: window
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    color: Theme.colors.bgBase
    title: stackView.currentItem ? qsTr("Artemis - %1").arg(stackView.currentItem.objectName) : qsTr("Artemis")

    // Apollo 2026 design tokens (synced with the Apollo Web UI themes)
    Material.theme: Theme.isDark ? Material.Dark : Material.Light
    Material.background: Theme.colors.bgBase
    Material.foreground: Theme.colors.textBase
    Material.accent: Theme.colors.primary
    Material.primary: Theme.colors.surface

    // This function runs prior to creation of the initial StackView item
    function doEarlyInit() {
        // Keep the selected theme background on every Qt version
        Material.background = Theme.colors.bgBase

        SdlGamepadKeyNavigation.enable()
    }

    function isGeometryOnScreen(geo) {
        var screens = Qt.application.screens
        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i]
            if (geo.x + geo.width > screen.virtualX &&
                geo.x < screen.virtualX + screen.width &&
                geo.y + geo.height > screen.virtualY &&
                geo.y < screen.virtualY + screen.height) {
                return true
            }
        }
        return false
    }

    Component.onCompleted: {
        // Restore the desktop window geometry before showing the window
        var startMaximized = false
        var geo = SystemProperties.loadWindowGeometry()
        if (geo.valid && isGeometryOnScreen(geo)) {
            window.x = geo.x
            window.y = geo.y
            window.width = Math.max(minimumWidth, geo.width)
            window.height = Math.max(minimumHeight, geo.height)
            startMaximized = geo.maximized
        }

        // Show the window according to the user's preferences
        if (SystemProperties.hasDesktopEnvironment) {
            if (startMaximized || StreamingPreferences.uiDisplayMode == StreamingPreferences.UI_MAXIMIZED) {
                window.showMaximized()
            }
            else if (StreamingPreferences.uiDisplayMode == StreamingPreferences.UI_FULLSCREEN) {
                window.showFullScreen()
            }
            else {
                window.show()
            }
        } else {
            window.showFullScreen()
        }

        // Display any modal dialogs for configuration warnings
        if (runConfigChecks) {
            if (SystemProperties.isWow64) {
                wow64Dialog.open()
            }

            // Hardware acceleration and unmapped gamepads are checked asynchronously
            SystemProperties.hasHardwareAccelerationChanged.connect(hasHardwareAccelerationChanged)
            SystemProperties.unmappedGamepadsChanged.connect(hasUnmappedGamepadsChanged)
            SystemProperties.startAsyncLoad()
        }

        AutoUpdateChecker.onUpdateAvailable.connect(function(version, url) {
            window.updateAvailable = true
            window.updateVersion = version
            window.updateUrl = url
        })
        AutoUpdateChecker.start()
    }

    onClosing: function(close) {
        SystemProperties.saveWindowGeometry(window.x, window.y,
                                            window.width, window.height,
                                            window.visibility === Window.Maximized)
    }

    function hasHardwareAccelerationChanged() {
        if (!SystemProperties.hasHardwareAcceleration && StreamingPreferences.videoDecoderSelection !== StreamingPreferences.VDS_FORCE_SOFTWARE) {
            if (SystemProperties.isRunningXWayland) {
                xWaylandDialog.open()
            }
            else {
                noHwDecoderDialog.open()
            }
        }
    }

    function hasUnmappedGamepadsChanged() {
        if (SystemProperties.unmappedGamepads) {
            unmappedGamepadDialog.unmappedGamepads = SystemProperties.unmappedGamepads
            unmappedGamepadDialog.open()
        }
    }

    // It would be better to use TextMetrics here, but it always lays out
    // the text slightly more compactly than real Text does in ToolTip,
    // causing unexpected line breaks to be inserted
    Text {
        id: tooltipTextLayoutHelper
        visible: false
        font: ToolTip.toolTip.font
        text: ToolTip.toolTip.text
    }

    // This configures the maximum width of the singleton attached QML ToolTip. If left unconstrained,
    // it will never insert a line break and just extend on forever.
    ToolTip.toolTip.contentWidth: Math.min(tooltipTextLayoutHelper.width, 400)

    function goBack() {
        if (clearOnBack) {
            // Pop all items except the first one
            stackView.pop(null)
            clearOnBack = false
        }
        else {
            stackView.pop()
        }
    }

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: sidebar
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            color: Theme.colors.surface

            Rectangle {
                width: 1
                height: parent.height
                anchors.right: parent.right
                color: Theme.colors.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    spacing: 10

                    Image {
                        source: "qrc:/res/artemis.png"
                        sourceSize { width: 34; height: 34 }
                    }

                    ColumnLayout {
                        spacing: 0
                        Label {
                            text: "Artemis"
                            font.pointSize: 15
                            font.bold: true
                            color: Theme.colors.textBase
                        }
                        Label {
                            text: qsTr("PC 2026")
                            font.pointSize: 8
                            color: Theme.colors.primary
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                SidebarButton {
                    text: qsTr("Computers")
                    iconSourceDark: "qrc:/res/desktop_windows-48px.svg"
                    iconSourceLight: "qrc:/res/desktop_windows-48px-light.svg"
                    onClicked: {
                        stackView.pop(null)
                        stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                    }
                }

                SidebarButton {
                    text: qsTr("Settings")
                    iconSourceDark: "qrc:/res/settings.svg"
                    iconSourceLight: "qrc:/res/settings-light.svg"
                    onClicked: navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
                }

                SidebarButton {
                    text: qsTr("Help")
                    iconSourceDark: "qrc:/res/github.svg"
                    iconSourceLight: "qrc:/res/github-light.svg"
                    onClicked: Qt.openUrlExternally("https://github.com/leonidas10009/Artemis-pc")
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                SidebarButton {
                    text: qsTr("Add PC")
                    iconSourceDark: "qrc:/res/ic_add_to_queue_white_48px.svg"
                    iconSourceLight: "qrc:/res/ic_add_to_queue_white_48px-light.svg"
                    visible: stackView.currentItem instanceof PcView
                    onClicked: addPcDialog.open()
                }

                SidebarButton {
                    id: sidebarUpdateButton
                    visible: window.updateAvailable
                    text: qsTr("Update: %1").arg(window.updateVersion)
                    iconSourceDark: "qrc:/res/update.svg"
                    iconSourceLight: "qrc:/res/update-light.svg"
                    onClicked: Qt.openUrlExternally(window.updateUrl)
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                }

                Label {
                    text: "v" + SystemProperties.versionString
                    font.pointSize: 9
                    color: Theme.colors.textSubtle
                    Layout.fillWidth: true
                }
            }
        }

        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true

        Component.onCompleted: {
            // Perform our early initialization before constructing
            // the initial view and pushing it to the StackView
            doEarlyInit()
            push(initialView)
        }

        onCurrentItemChanged: {
            // Ensure focus travels to the next view when going back
            if (currentItem) {
                currentItem.forceActiveFocus()
            }
        }

        Keys.onEscapePressed: {
            if (depth > 1) {
                goBack()
            }
            else {
                quitConfirmationDialog.open()
            }
        }

        Keys.onBackPressed: {
            if (depth > 1) {
                goBack()
            }
            else {
                quitConfirmationDialog.open()
            }
        }

        Keys.onMenuPressed: {
            navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
        }

        // This is a keypress we've reserved for letting the
        // SdlGamepadKeyNavigation object tell us to show settings
        // when Menu is consumed by a focused control.
        Keys.onHangupPressed: {
            navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
        }
    }
    }

    // This timer keeps us polling for 5 minutes of inactivity
    // to allow the user to work with Artemis on a second display
    // while dealing with configuration issues. This will ensure
    // machines come online even if the input focus isn't on Artemis.
    Timer {
        id: inactivityTimer
        interval: 5 * 60000
        onTriggered: {
            if (!active && pollingActive) {
                ComputerManager.stopPollingAsync()
                pollingActive = false
            }
        }
    }

    onVisibleChanged: {
        // When we become invisible while streaming is going on,
        // stop polling immediately.
        if (!visible) {
            inactivityTimer.stop()

            if (pollingActive) {
                ComputerManager.stopPollingAsync()
                pollingActive = false
            }
        }
        else if (active) {
            // When we become visible and active again, start polling
            inactivityTimer.stop()

            // Restart polling if it was stopped
            if (!pollingActive) {
                ComputerManager.startPolling()
                pollingActive = true
            }
        }

        // Poll for gamepad input only when the window is in focus
        SdlGamepadKeyNavigation.notifyWindowFocus(visible && active)
    }

    onActiveChanged: {
        if (active) {
            // Stop the inactivity timer
            inactivityTimer.stop()

            // Restart polling if it was stopped
            if (!pollingActive) {
                ComputerManager.startPolling()
                pollingActive = true
            }
        }
        else {
            // Start the inactivity timer to stop polling
            // if focus does not return within a few minutes.
            inactivityTimer.restart()
        }

        // Poll for gamepad input only when the window is in focus
        SdlGamepadKeyNavigation.notifyWindowFocus(visible && active)
    }

    function navigateTo(url, objectType)
    {
        var existingItem = stackView.find(function(item, index) {
            return item instanceof objectType
        })

        if (existingItem !== null) {
            // Pop to the existing item
            stackView.pop(existingItem)
        }
        else {
            // Create a new item
            stackView.push(url)
        }
    }

    header: ToolBar {
        id: toolBar
        height: 60
        anchors.topMargin: 5
        anchors.bottomMargin: 5

        background: Rectangle {
            color: Theme.colors.surface
            Rectangle {
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
                color: Theme.colors.border
            }
        }

        Label {
            id: titleLabel
            visible: toolBar.width > 700
            anchors.fill: parent
            text: stackView.currentItem.objectName
            font.pointSize: 20
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
        }

        RowLayout {
            spacing: 10
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.fill: parent

            NavigableToolButton {
                // Only make the button visible if the user has navigated somewhere.
                visible: stackView.depth > 1

                iconSource: "qrc:/res/arrow_left.svg"

                onClicked: goBack()

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }

            // This label will appear when the window gets too small and
            // we need to ensure the toolbar controls don't collide
            Label {
                id: titleRowLabel
                font.pointSize: titleLabel.font.pointSize
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true

                // We need this label to always be visible so it can occupy
                // the remaining space in the RowLayout. To "hide" it, we
                // just set the text to empty string.
                text: !titleLabel.visible ? stackView.currentItem.objectName : ""
            }

            NavigableToolButton {
                id: themeButton

                iconSource: "qrc:/res/theme.svg"
                Accessible.name: qsTr("Theme")

                onClicked: themeMenu.open()

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Theme: %1").arg(Theme.displayName(Theme.name))

                Keys.onDownPressed: {
                    stackView.currentItem.forceActiveFocus(Qt.TabFocus)
                }
            }
        }
    }

    Shortcut {
        id: newPcShortcut
        sequence: StandardKey.New
        onActivated: addPcDialog.open()
    }

    Shortcut {
        id: settingsShortcut
        sequence: StandardKey.Preferences
        onActivated: navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
    }

    Shortcut {
        id: helpShortcut
        sequence: StandardKey.HelpContents
        onActivated: Qt.openUrlExternally("https://github.com/leonidas10009/Artemis-pc")
    }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: {
            var keys = Theme.darkThemeKeys.concat(Theme.lightThemeKeys)
            var index = keys.indexOf(Theme.name)
            Theme.setTheme(keys[(index + 1) % keys.length])
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+T"
        onActivated: themeMenu.open()
    }

    footer: ToolBar {
        id: statusBar
        height: 30
        visible: stackView.currentItem &&
                 (stackView.currentItem instanceof PcView ||
                  stackView.currentItem instanceof AppView)

        background: Rectangle {
            color: Theme.colors.bgBase
            Rectangle {
                width: parent.width
                height: 1
                anchors.top: parent.top
                color: Theme.colors.border
            }
        }

        contentItem: RowLayout {
            spacing: 12
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Label {
                text: stackView.currentItem && stackView.currentItem.statusText !== undefined
                      ? stackView.currentItem.statusText : ""
                font.pointSize: 9
                color: Theme.colors.textMuted
                elide: Label.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Enter: open · Right click: menu · Ctrl+Shift+T: themes · Ctrl+,: settings")
                font.pointSize: 9
                color: Theme.colors.textSubtle
                elide: Label.ElideRight
            }
        }
    }

    Popup {
        id: themeMenu
        parent: window.contentItem
        width: 560
        height: contentItem.implicitHeight + 24
        padding: 12
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        x: Math.max(8, Math.min(themeButton.mapToItem(window.contentItem, 0, 0).x + themeButton.width - width,
                                   window.contentItem.width - width - 8))
        y: Math.max(8, themeButton.mapToItem(window.contentItem, 0, 0).y + themeButton.height + 4)

        background: Rectangle {
            color: Theme.colors.surface
            border.width: 1
            border.color: Theme.colors.border
            radius: 12
        }

        contentItem: ColumnLayout {
            spacing: 8

            RowLayout {
                spacing: 8

                Label {
                    text: qsTr("Theme")
                    font.pointSize: 12
                    font.bold: true
                    color: Theme.colors.textBase
                    Layout.fillWidth: true
                }

                Button {
                    text: qsTr("Random")
                    font.pointSize: 9
                    onClicked: {
                        var keys = Theme.darkThemeKeys.concat(Theme.lightThemeKeys)
                        Theme.setTheme(keys[Math.floor(Math.random() * keys.length)])
                    }
                }
            }

            RowLayout {
                spacing: 16
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Dark themes")
                        font.pointSize: 9
                        font.bold: true
                        color: Theme.colors.textMuted
                    }

                    Repeater {
                        model: Theme.darkThemeKeys

                        ItemDelegate {
                            id: darkThemeItem
                            property var tokenColors: Theme.colorsFor(modelData)
                            width: parent.width
                            height: 32
                            text: Theme.displayName(modelData)
                            font.pointSize: 10
                            focusPolicy: Qt.StrongFocus
                            onClicked: {
                                Theme.setTheme(modelData)
                                themeMenu.close()
                            }

                            background: Rectangle {
                                radius: 6
                                color: darkThemeItem.hovered || Theme.name === modelData
                                       ? Theme.colors.bgMuted : "transparent"
                                border.width: Theme.name === modelData ? 1 : 0
                                border.color: Theme.colors.primary
                            }

                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: darkThemeItem.tokenColors.primary
                                }
                                Label {
                                    text: darkThemeItem.text
                                    font.pointSize: 10
                                    color: Theme.colors.textBase
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: "✓"
                                    visible: Theme.name === modelData
                                    color: Theme.colors.primary
                                }
                            }

                            Keys.onReturnPressed: clicked()
                            Keys.onEnterPressed: clicked()
                        }
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Light themes")
                        font.pointSize: 9
                        font.bold: true
                        color: Theme.colors.textMuted
                    }

                    Repeater {
                        model: Theme.lightThemeKeys

                        ItemDelegate {
                            id: lightThemeItem
                            property var tokenColors: Theme.colorsFor(modelData)
                            width: parent.width
                            height: 32
                            text: Theme.displayName(modelData)
                            font.pointSize: 10
                            focusPolicy: Qt.StrongFocus
                            onClicked: {
                                Theme.setTheme(modelData)
                                themeMenu.close()
                            }

                            background: Rectangle {
                                radius: 6
                                color: lightThemeItem.hovered || Theme.name === modelData
                                       ? Theme.colors.bgMuted : "transparent"
                                border.width: Theme.name === modelData ? 1 : 0
                                border.color: Theme.colors.primary
                            }

                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: lightThemeItem.tokenColors.primary
                                }
                                Label {
                                    text: lightThemeItem.text
                                    font.pointSize: 10
                                    color: Theme.colors.textBase
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: "✓"
                                    visible: Theme.name === modelData
                                    color: Theme.colors.primary
                                }
                            }

                            Keys.onReturnPressed: clicked()
                            Keys.onEnterPressed: clicked()
                        }
                    }
                }
            }
        }
    }

    ErrorMessageDialog {
        id: noHwDecoderDialog
        text: qsTr("No functioning hardware accelerated video decoder was detected by Artemis. " +
                   "Your streaming performance may be severely degraded in this configuration.")
        helpText: qsTr("Click the Help button for more information on solving this problem.")
        helpUrl: "https://github.com/moonlight-stream/moonlight-docs/wiki/Fixing-Hardware-Decoding-Problems"
    }

    ErrorMessageDialog {
        id: xWaylandDialog
        text: qsTr("Hardware acceleration doesn't work on XWayland. Continuing on XWayland may result in poor streaming performance. " +
                   "Try running with QT_QPA_PLATFORM=wayland or switch to X11.")
        helpText: qsTr("Click the Help button for more information.")
        helpUrl: "https://github.com/moonlight-stream/moonlight-docs/wiki/Fixing-Hardware-Decoding-Problems"
    }

    NavigableMessageDialog {
        id: wow64Dialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        text: qsTr("This version of Artemis isn't optimized for your PC. Please download the '%1' version of Artemis for the best streaming performance.").arg(SystemProperties.friendlyNativeArchName)
        onAccepted: {
            Qt.openUrlExternally("https://github.com/leonidas10009/Artemis-pc/releases");
        }
    }

    ErrorMessageDialog {
        id: unmappedGamepadDialog
        property string unmappedGamepads : ""
        text: qsTr("Artemis detected gamepads without a mapping:") + "\n" + unmappedGamepads
        helpTextSeparator: "\n\n"
        helpText: qsTr("Click the Help button for information on how to map your gamepads.")
        helpUrl: "https://github.com/moonlight-stream/moonlight-docs/wiki/Gamepad-Mapping"
    }

    // This dialog appears when quitting via keyboard or gamepad button
    NavigableMessageDialog {
        id: quitConfirmationDialog
        standardButtons: Dialog.Yes | Dialog.No
        text: qsTr("Are you sure you want to quit?")
        // For keyboard/gamepad navigation
        onAccepted: Qt.quit()
    }

    // HACK: This belongs in StreamSegue but keeping a dialog around after the parent
    // dies can trigger bugs in Qt 5.12 that cause the app to crash. For now, we will
    // host this dialog in a QML component that is never destroyed.
    //
    // To repro: Start a stream, cut the network connection to trigger the "Connection
    // terminated" dialog, wait until the app grid times out back to the PC grid, then
    // try to dismiss the dialog.
    ErrorMessageDialog {
        id: streamSegueErrorDialog

        property bool quitAfter: false

        onClosed: {
            if (quitAfter) {
                Qt.quit()
            }

            // StreamSegue assumes its dialog will be re-created each time we
            // start streaming, so fake it by wiping out the text each time.
            text = ""
        }
    }

    NavigableDialog {
        id: addPcDialog
        property string label: qsTr("Enter the IP address of your host PC:")

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
                ComputerManager.addNewHostManually(editText.text.trim())
            }
        }

        ColumnLayout {
            Label {
                text: addPcDialog.label
                font.bold: true
            }

            TextField {
                id: editText
                Layout.fillWidth: true
                focus: true

                Keys.onReturnPressed: {
                    addPcDialog.accept()
                }

                Keys.onEnterPressed: {
                    addPcDialog.accept()
                }
            }
        }
    }
}
