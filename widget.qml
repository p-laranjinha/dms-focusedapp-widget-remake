import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Inspired by:
//  https://github.com/AvengeMedia/DankMaterialShell/blob/32d16d067364e3181922bba5f5a5a4f2b0515a7b/quickshell/Modules/Plugins/PluginComponent.qml
//  https://github.com/AvengeMedia/DankMaterialShell/blob/27c26d35ab22cc69a0525aab0aa0da8b753284ec/quickshell/Modules/DankBar/Widgets/FocusedApp.qml
//  https://github.com/AvengeMedia/DankMaterialShell/blob/27c26d35ab22cc69a0525aab0aa0da8b753284ec/quickshell/Modules/DankBar/Widgets/RunningApps.qml
//  https://github.com/AvengeMedia/DankMaterialShell/blob/27c26d35ab22cc69a0525aab0aa0da8b753284ec/quickshell/Modules/DankBar/Widgets/AppsDock.qml

BasePill {
    id: root

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property bool isVerticalOrientation: axis?.isVertical ?? false
    readonly property int maxTextWidth: 600
    property var activeDesktopEntry: null
    property bool isAutoHideBar: false

    // Tooltip utility for top bar
    readonly property real minTooltipY: {
        if (!parentScreen || !isVerticalOrientation) {
            return 0;
        }
        if (isAutoHideBar) {
            return 0;
        }
        if (parentScreen.y > 0) {
            return barThickness + (barSpacing || 4);
        }
        return 0;
    }

    // Update the active window/program
    function updateDesktopEntry() {
        if (activeWindow && activeWindow.appId) {
            const moddedId = Paths.moddedAppId(activeWindow.appId);
            activeDesktopEntry = DesktopEntries.heuristicLookup(moddedId);
        } else {
            activeDesktopEntry = null;
        }
    }
    Component.onCompleted: {
        updateDesktopEntry();
    }
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.updateDesktopEntry();
        }
    }
    Connections {
        target: root
        function onActiveWindowChanged() {
            root.updateDesktopEntry();
        }
    }
    Connections {
        target: SettingsData
        function onAppIdSubstitutionsChanged() {
            root.updateDesktopEntry();
        }
    }


    // Hide pill if no windows exist on the current workspace
    readonly property bool hasWindowsOnCurrentWorkspace: {
        if (CompositorService.isNiri) {
            let currentWorkspaceId = null;
            for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
                const ws = NiriService.allWorkspaces[i];
                if (ws.is_focused) {
                    currentWorkspaceId = ws.id;
                    break;
                }
            }
            if (!currentWorkspaceId) {
                return false;
            }
            const workspaceWindows = NiriService.windows.filter(w => w.workspace_id === currentWorkspaceId);
            return workspaceWindows.length > 0 && activeWindow && activeWindow.title;
        }
        if (CompositorService.isHyprland) {
            if (!Hyprland.focusedWorkspace || !activeWindow || !activeWindow.title) {
                return false;
            }
            try {
                if (!Hyprland.toplevels)
                    return false;
                const hyprlandToplevels = Array.from(Hyprland.toplevels.values);
                const activeHyprToplevel = hyprlandToplevels.find(t => t?.wayland === activeWindow);
                if (!activeHyprToplevel || !activeHyprToplevel.workspace) {
                    return false;
                }
                return activeHyprToplevel.workspace.id === Hyprland.focusedWorkspace.id;
            } catch (e) {
                return false;
            }
        }
        return activeWindow && activeWindow.title;
    }
    width: hasWindowsOnCurrentWorkspace ? (isVerticalOrientation ? barThickness : visualWidth) : 0
    height: hasWindowsOnCurrentWorkspace ? (isVerticalOrientation ? visualHeight : barThickness) : 0
    visible: hasWindowsOnCurrentWorkspace

    content: Component {
        Item {
            implicitWidth: {
                if (!root.hasWindowsOnCurrentWorkspace)
                    return 0;
                if (root.isVerticalOrientation)
                    return root.widgetThickness - root.horizontalPadding * 2;
                return contentRow.implicitWidth;
            }
            implicitHeight: root.widgetThickness - root.horizontalPadding * 2
            clip: false

            IconImage {
                id: verticalAppIcon
                visible: root.isVerticalOrientation && activeWindow && status === Image.Ready
                anchors.centerIn: parent
                width: 18
                height: 18
                source: {
                    if (!activeWindow || !activeWindow.appId)
                        return "";
                    return Paths.getAppIcon(activeWindow.appId, activeDesktopEntry);
                }
                smooth: true
                mipmap: true
                asynchronous: true
            }

             Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: Theme.spacingS
                visible: !root.isVerticalOrientation
                IconImage {
                    id: horizontalAppIcon
                    visible: activeWindow && status === Image.Ready
                    width: 18
                    height: 18
                    source: {
                        if (!activeWindow || !activeWindow.appId)
                            return "";
                        return Paths.getAppIcon(activeWindow.appId, activeDesktopEntry);
                    }
                    smooth: true
                    mipmap: true
                    asynchronous: true
                }
                StyledText {
                    id: appTitle
                    visible: !root.isVerticalOrientation && text.length > 0
                    text: {
                        const title = activeWindow && activeWindow.title ? activeWindow.title : "";
                        let appName = "";
                        if (activeWindow && activeWindow.appId) {
                          appName = Paths.getAppName(activeWindow.appId, activeDesktopEntry);
                        }
                        if (!title || !appName) {
                            return title;
                        }
                        if (title.endsWith(" - " + appName)) {
                            return title.substring(0, title.length - (" - " + appName).length);
                        } else if (title.endsWith(" — " + appName)) {
                            return title.substring(0, title.length - (" — " + appName).length);
                        } else if (title.endsWith(" — " + appName.replace(/ \(Beta\)$/, ""))) {
                            // For Zen Browser.
                            return title.substring(0, title.length - (" — " + appName.replace(/ \(Beta\)$/, "")).length);
                        } else if (title.endsWith(appName)) {
                            return title.substring(0, title.length - appName.length).replace(/ - $/, "");
                        }

                        return title;
                    }
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: Math.min(implicitWidth, maxTextWidth)
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onEntered: {
            if (activeWindow && activeWindow.appId && root.parentScreen) {
                tooltipLoader.active = true;
                if (tooltipLoader.item) {
                    const appName = Paths.getAppName(activeWindow.appId, activeDesktopEntry);
                    const title = activeWindow.title || "";
                    const tooltipText = appName + (title ? " • " + title : "");
                    const globalPos = mapToGlobal(width / 2, height / 2);
                    if (root.isVerticalOrientation) {
                        const screenX = root.parentScreen ? root.parentScreen.x : 0;
                        const screenY = root.parentScreen ? root.parentScreen.y : 0;
                        const isLeft = root.axis?.edge === "left";
                        const tooltipX = isLeft ? (root.barThickness + root.barSpacing) : (root.parentScreen.width - root.barThickness - root.barSpacing);
                        const screenRelativeY = globalPos.y - screenY + root.minTooltipY;
                        tooltipLoader.item.show(tooltipText, screenX + tooltipX, screenRelativeY, root.parentScreen, isLeft, !isLeft);
                    } else {
                        const screenHeight = root.parentScreen ? root.parentScreen.height : Screen.height;
                        const isBottom = root.axis?.edge === "bottom";
                        const tooltipY = isBottom ? (screenHeight - root.barThickness - root.barSpacing - 30) : (root.barThickness + root.barSpacing);
                        tooltipLoader.item.show(tooltipText, globalPos.x, tooltipY, root.parentScreen, false, false);
                    }
                }
            }
        }
        onExited: {
            if (tooltipLoader.item) {
                tooltipLoader.item.hide();
            }
            tooltipLoader.active = false;
        }
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                activeWindow.close();
            }
            if (mouse.button === Qt.RightButton) {
                if (tooltipLoader.item) {
                    tooltipLoader.item.hide();
                }
                tooltipLoader.active = false;
                contextMenuLoader.active = true;

                if (contextMenuLoader.item) {
                    const globalPos = mapToGlobal(width / 2, height / 2);
                    const screenX = root.parentScreen ? root.parentScreen.x : 0;
                    const screenY = root.parentScreen ? root.parentScreen.y : 0;
                    const isBarVertical = root.axis?.isVertical ?? false;
                    const barEdge = root.axis?.edge ?? "top";

                    let x = globalPos.x - screenX;
                    let y = globalPos.y - screenY;

                    switch (barEdge) {
                        case "bottom":
                        y = (root.parentScreen ? root.parentScreen.height : Screen.height) - root.barThickness - root.barSpacing;
                        break;
                        case "top":
                        y = root.barThickness + root.barSpacing;
                        break;
                        case "left":
                        x = root.barThickness + root.barSpacing;
                        break;
                        case "right":
                        x = (root.parentScreen ? root.parentScreen.width : Screen.width) - root.barThickness - root.barSpacing;
                        break;
                    }

                    const moddedId = Paths.moddedAppId(activeWindow.appId);
                    const desktopEntry = moddedId ? DesktopEntries.heuristicLookup(moddedId) : null;

                    contextMenuLoader.item.showAt(x, y, isBarVertical, barEdge, desktopEntry, root.parentScreen);
                }
            }
        }
    }

    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: DankTooltip {}
    }

    Loader {
        id: contextMenuLoader
        active: false
        source: "context-menu.qml"
    }
}
