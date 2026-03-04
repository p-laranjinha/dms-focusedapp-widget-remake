import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

// Inspired by:
//  https://github.com/AvengeMedia/DankMaterialShell/blob/27c26d35ab22cc69a0525aab0aa0da8b753284ec/quickshell/Modules/DankBar/Widgets/AppsDockContextMenu.qml

PanelWindow {
    id: root

    WlrLayershell.namespace: "dms:plugins:focusedapp-remake-context-menu"

    property var anchorItem: null
    property int margin: 10
    property var desktopEntry: null
    property bool isDmsWindow: activeWindow?.appId === "org.quickshell"

    property bool isVertical: false
    property string edge: "top"
    property point anchorPos: Qt.point(0, 0)

    function showAt(x, y, vertical, barEdge, entry, targetScreen) {
        if (targetScreen) {
            root.screen = targetScreen;
        }

        anchorPos = Qt.point(x, y);
        isVertical = vertical ?? false;
        edge = barEdge ?? "top";

        desktopEntry = entry || null;

        visible = true;

        if (targetScreen) {
            TrayMenuManager.registerMenu(targetScreen.name, root);
        }
    }

    function close() {
        visible = false;

        if (root.screen) {
            TrayMenuManager.unregisterMenu(root.screen.name);
        }
    }

    screen: null
    visible: false
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Component.onDestruction: {
        if (root.screen) {
            TrayMenuManager.unregisterMenu(root.screen.name);
        }
    }

    Connections {
        target: PopoutManager
        function onPopoutOpening() {
            root.close();
        }
    }

    Rectangle {
        id: menuContainer

        x: {
            if (root.isVertical) {
                if (root.edge === "left") {
                    return Math.min(root.width - width - 10, root.anchorPos.x);
                } else {
                    return Math.max(10, root.anchorPos.x - width);
                }
            } else {
                const left = 10;
                const right = root.width - width - 10;
                const want = root.anchorPos.x - width / 2;
                return Math.max(left, Math.min(right, want));
            }
        }
        y: {
            if (root.isVertical) {
                const top = 10;
                const bottom = root.height - height - 10;
                const want = root.anchorPos.y - height / 2;
                return Math.max(top, Math.min(bottom, want));
            } else {
                if (root.edge === "top") {
                    return Math.min(root.height - height - 10, root.anchorPos.y);
                } else {
                    return Math.max(10, root.anchorPos.y - height);
                }
            }
        }

        width: Math.min(400, Math.max(180, menuColumn.implicitWidth + Theme.spacingS * 2))
        height: Math.max(28, menuColumn.implicitHeight + Theme.spacingS * 2)
        color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
        radius: Theme.cornerRadius
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1

        opacity: root.visible ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.emphasizedEasing
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 2
            anchors.rightMargin: -2
            anchors.bottomMargin: -4
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.15)
            z: -1
        }

        Column {
            id: menuColumn
            width: parent.width - Theme.spacingS * 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingS
            spacing: 1

            // Application actions (like 'New Private Window' on a browser)
            Repeater {
                model: root.desktopEntry && root.desktopEntry.actions ? root.desktopEntry.actions : []

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: Theme.cornerRadius
                    color: actionArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            visible: modelData.icon && modelData.icon !== ""

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon ? Paths.resolveIconPath(modelData.icon) : ""
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name || ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                        }
                    }

                    DankRipple {
                        id: actionRipple
                        rippleColor: Theme.surfaceText
                        cornerRadius: Theme.cornerRadius
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => actionRipple.trigger(mouse.x, mouse.y)
                        onClicked: {
                            if (modelData) {
                                SessionService.launchDesktopAction(root.desktopEntry, modelData);
                            }
                            root.close();
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                visible: {
                    if (!root.desktopEntry?.actions || root.desktopEntry.actions.length === 0) {
                        return false;
                    }
                    return !root.hidePin || (!root.isDmsWindow && root.desktopEntry && SessionService.nvidiaCommand);
                }
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            }

            // Close window
            Rectangle {
                visible: activeWindow
                width: parent.width
                height: 28
                radius: Theme.cornerRadius
                color: closeArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingS
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Close Window");
                    font.pixelSize: Theme.fontSizeSmall
                    color: closeArea.containsMouse ? Theme.error : Theme.surfaceText
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                DankRipple {
                    id: closeRipple
                    rippleColor: Theme.error
                    cornerRadius: Theme.cornerRadius
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => closeRipple.trigger(mouse.x, mouse.y)
                    onClicked: {
                        activeWindow.close();
                        root.close();
                    }
                }
            }

        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.close()
    }
}
