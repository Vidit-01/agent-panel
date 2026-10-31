import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: popup
    required property var app
    implicitWidth: Kirigami.Units.gridUnit * 25
    implicitHeight: Math.min(Kirigami.Units.gridUnit * 28,
        Math.max(Kirigami.Units.gridUnit * 10, estimatedHeight()))

    property var rows: buildRows()
    property string viewMode: "agents"
    property string selectedProject: ""
    property var recentProjects: getRecentProjects()

    function estimatedHeight() {
        let content = Kirigami.Units.gridUnit * 6;
        for (let i = 0; i < rows.length; ++i) {
            content += rows[i].kind === "agent" ? Kirigami.Units.gridUnit * 4
                : rows[i].kind === "project" ? Kirigami.Units.gridUnit * 3
                : Kirigami.Units.gridUnit * 1.5;
        }
        return content;
    }

    function getRecentProjects() {
        const byPath = ({});
        const groups = [app.agents.running, app.agents.waiting, app.agents.finished];
        for (let g = 0; g < groups.length; ++g) {
            for (let i = 0; i < groups[g].length; ++i) {
                const agent = groups[g][i];
                const path = agent.projectPath || agent.project;
                const stamp = agent.status === "Running" || agent.status === "Needs input" ? agent.updated : (agent.completedAt || agent.updated);
                if (!byPath[path]) {
                    byPath[path] = { name: agent.project, path: path, updated: stamp, opened: false };
                }
                byPath[path].opened = byPath[path].opened || agent.opened;
                byPath[path].updated = Math.max(byPath[path].updated, stamp);
            }
        }
        const paths = Object.keys(byPath);
        const result = [];
        for (let i = 0; i < paths.length; ++i) result.push(byPath[paths[i]]);
        return result.sort((a, b) => (Number(b.opened) - Number(a.opened)) || (b.updated - a.updated)).slice(0, 8);
    }

    function sortedAgents(agents) {
        const copy = agents.slice();
        copy.sort((a, b) => {
            if (a.opened !== b.opened) return a.opened ? -1 : 1;
            const at = a.status === "Running" || a.status === "Needs input" ? a.updated : (a.completedAt || a.updated);
            const bt = b.status === "Running" || b.status === "Needs input" ? b.updated : (b.completedAt || b.updated);
            return bt - at;
        });
        return copy;
    }

    function buildRows() {
        const result = [];
        if (viewMode === "projects" && selectedProject === "") {
            const byPath = ({});
            const groups = [app.agents.running, app.agents.waiting, app.agents.finished];
            for (let g = 0; g < groups.length; ++g) {
                for (let i = 0; i < groups[g].length; ++i) {
                    const agent = groups[g][i];
                    const path = agent.projectPath || agent.project;
                    if (!byPath[path]) byPath[path] = { kind: "project", path: path, name: agent.project, running: 0, waiting: 0, finished: 0, opened: 0, updated: agent.updated };
                    const stamp = agent.status === "Running" || agent.status === "Needs input" ? agent.updated : (agent.completedAt || agent.updated);
                    byPath[path].updated = Math.max(byPath[path].updated, stamp);
                    if (agent.opened) byPath[path].opened++;
                    if (agent.status === "Running" || agent.active) byPath[path].running++;
                    else if (agent.status === "Needs input" || agent.needsInput) byPath[path].waiting++;
                    else byPath[path].finished++;
                }
            }
            const paths = Object.keys(byPath).sort((a, b) =>
                (byPath[b].opened - byPath[a].opened) || (byPath[b].updated - byPath[a].updated));
            for (let i = 0; i < paths.length; ++i) result.push(byPath[paths[i]]);
            if (result.length === 0) result.push({ kind: "empty", text: "No projects with agent chats" });
            return result;
        }
        const matchesProject = agents => sortedAgents(selectedProject === "" ? agents : agents.filter(agent => (agent.projectPath || agent.project) === selectedProject));
        appendGroup(result, "Running", matchesProject(app.agents.running), "No agents are running");
        appendGroup(result, "Needs input", matchesProject(app.agents.waiting), "No agents are waiting for input");
        appendGroup(result, app.agents.attention > 0 ? "Finished · %1 new".arg(app.agents.attention) : "Finished", matchesProject(app.agents.finished), "No finished agents");
        return result;
    }

    function appendGroup(result, title, agents, emptyText) {
        result.push({ kind: "header", title: title, count: agents.length });
        if (agents.length === 0) {
            result.push({ kind: "empty", text: emptyText });
        } else {
            for (let i = 0; i < agents.length; ++i) {
                result.push({ kind: "agent", agent: agents[i] });
            }
        }
    }

    function confirmDelete(agent) {
        deleteDialog.sessionId = agent.id;
        deleteDialog.sessionName = agent.name;
        deleteDialog.open();
    }

    function startNewChat() {
        newProjectPath.text = selectedProject;
        newChatDialog.pathError = "";
        newChatDialog.open();
    }

    function providerImage(provider) {
        if (["openai", "claude", "cursor", "gemini"].indexOf(provider) < 0) return "";
        return Qt.resolvedUrl("../images/" + provider + ".svg");
    }

    function groupIcon(title) {
        if (title.indexOf("Running") === 0) return "media-playback-start-symbolic";
        if (title.indexOf("Needs input") === 0) return "dialog-question-symbolic";
        return "task-complete-symbolic";
    }

    function groupColor(title) {
        if (title.indexOf("Running") === 0) return Kirigami.Theme.highlightColor;
        if (title.indexOf("Needs input") === 0) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.textColor;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.ToolButton {
                icon.name: "view-list-details"
                text: "Agents"
                display: PlasmaComponents.AbstractButton.TextBesideIcon
                checkable: true
                checked: popup.viewMode === "agents"
                onClicked: {
                    popup.viewMode = "agents";
                    popup.selectedProject = "";
                }
            }
            PlasmaComponents.ToolButton {
                icon.name: "folder-open"
                text: "Projects"
                display: PlasmaComponents.AbstractButton.TextBesideIcon
                checkable: true
                checked: popup.viewMode === "projects"
                onClicked: {
                    popup.viewMode = "projects";
                    popup.selectedProject = "";
                }
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.Button {
                icon.name: "list-add"
                text: "New chat"
                onClicked: popup.startNewChat()
            }
            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: PlasmaComponents.AbstractButton.IconOnly
                PlasmaComponents.ToolTip.text: "Refresh agent chats"
                PlasmaComponents.ToolTip.visible: hovered
                onClicked: popup.app.refresh()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: popup.selectedProject === "" ? "applications-development" : "folder-open"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                opacity: 0.75
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: popup.selectedProject !== "" ? popup.selectedProject : "All projects"
                font.bold: true
                elide: Text.ElideMiddle
            }
            PlasmaComponents.Label {
                visible: popup.app.refreshing
                text: "Updating…"
                opacity: 0.7
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        PlasmaComponents.Label {
            visible: popup.app.launchError !== ""
            Layout.fillWidth: true
            text: popup.app.launchError
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.WordWrap
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: popup.rows

            delegate: Item {
                id: rowItem
                required property var modelData
                width: list.width
                property var rowData: modelData
                height: rowData.kind === "agent"
                    ? agentDelegate.implicitHeight
                    : rowData.kind === "project" ? projectDelegate.implicitHeight
                    : rowData.kind === "header" ? Kirigami.Units.gridUnit * 2.2 : Kirigami.Units.gridUnit * 2

                RowLayout {
                    visible: rowItem.rowData.kind === "header"
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        source: popup.groupIcon(rowItem.rowData.title)
                        color: popup.groupColor(rowItem.rowData.title)
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    }
                    PlasmaComponents.Label {
                        text: rowItem.rowData.title
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                        Layout.fillWidth: true
                    }
                    PlasmaComponents.ToolButton {
                        visible: rowItem.rowData.title.indexOf("Finished") === 0 && popup.app.agents.attention > 0
                        text: "Mark all seen"
                        icon.name: "checkbox"
                        display: PlasmaComponents.AbstractButton.TextBesideIcon
                        onClicked: popup.app.acknowledgeAllDone()
                    }
                    Rectangle {
                        radius: height / 2
                        color: Kirigami.Theme.alternateBackgroundColor
                        implicitWidth: countLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                        implicitHeight: countLabel.implicitHeight + 4
                        PlasmaComponents.Label {
                            id: countLabel
                            anchors.centerIn: parent
                            text: rowItem.rowData.count
                            opacity: 0.8
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }

                PlasmaComponents.Label {
                    visible: rowItem.rowData.kind === "empty"
                    anchors.fill: parent
                    text: rowItem.rowData.text
                    opacity: 0.65
                    verticalAlignment: Text.AlignVCenter
                }

                PlasmaComponents.ItemDelegate {
                    id: projectDelegate
                    visible: rowItem.rowData.kind === "project"
                    anchors.fill: parent
                    onClicked: {
                        popup.selectedProject = rowItem.rowData.path;
                        popup.viewMode = "agents";
                    }
                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing / 2
                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Icon {
                                source: "folder-open"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: rowItem.rowData.kind === "project" ? rowItem.rowData.name : ""
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.largeSpacing
                            PlasmaComponents.Label {
                                text: "● %1 running".arg(rowItem.rowData.running)
                                color: Kirigami.Theme.highlightColor
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                            PlasmaComponents.Label {
                                text: "● %1 need input".arg(rowItem.rowData.waiting)
                                color: Kirigami.Theme.neutralTextColor
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                            PlasmaComponents.Label {
                                text: "● %1 finished".arg(rowItem.rowData.finished)
                                color: Kirigami.Theme.textColor
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: rowItem.rowData.kind === "project" ? rowItem.rowData.path : ""
                            opacity: 0.5
                            elide: Text.ElideMiddle
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }
                }

                PlasmaComponents.ItemDelegate {
                    id: agentDelegate
                    visible: rowItem.rowData.kind === "agent"
                    enabled: visible && (rowItem.rowData.agent.canOpen !== false || rowItem.rowData.agent.opened)
                    anchors.fill: parent
                    onClicked: popup.app.openSession(rowItem.rowData.agent)
                    background: Rectangle {
                        radius: Kirigami.Units.largeSpacing
                        color: "transparent"
                        border.width: 0
                    }
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Image {
                            visible: popup.providerImage(rowItem.rowData.agent.provider) !== ""
                            source: popup.providerImage(rowItem.rowData.agent.provider)
                            sourceSize.width: 44
                            sourceSize.height: 44
                            fillMode: Image.PreserveAspectFit
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                            Accessible.name: rowItem.rowData.agent.provider
                        }
                        Kirigami.Icon {
                            visible: popup.providerImage(rowItem.rowData.agent.provider) === ""
                            source: "applications-other"
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                            spacing: Kirigami.Units.smallSpacing
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: rowItem.rowData.agent.name
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: rowItem.rowData.agent.summary
                                opacity: 0.75
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Kirigami.Units.smallSpacing
                                Kirigami.Icon {
                                    source: "folder"
                                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                    opacity: 0.65
                                }
                                PlasmaComponents.Label {
                                    Layout.fillWidth: true
                                    text: rowItem.rowData.agent.project
                                    opacity: 0.65
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: rowItem.rowData.agent.opened ? "window-close" : "edit-delete"
                            text: rowItem.rowData.agent.opened ? "Close terminal" : "Delete chat"
                            display: PlasmaComponents.AbstractButton.IconOnly
                            PlasmaComponents.ToolTip.text: rowItem.rowData.agent.opened
                                ? "Close terminal window"
                                : rowItem.rowData.agent.canDelete === false
                                    ? "Deleting this provider’s chats is not supported"
                                    : "Delete chat"
                            PlasmaComponents.ToolTip.visible: hovered
                            enabled: rowItem.rowData.agent.opened
                                || (!rowItem.rowData.agent.active && rowItem.rowData.agent.canDelete !== false)
                            Layout.alignment: Qt.AlignTop
                            onClicked: {
                                if (rowItem.rowData.agent.opened) popup.app.closeSession(rowItem.rowData.agent);
                                else popup.confirmDelete(rowItem.rowData.agent);
                            }
                        }
                    }
                }
            }
        }
    }

    QQC2.Dialog {
        id: deleteDialog
        modal: true
        title: "Delete chat?"
        property string sessionId: ""
        property string sessionName: ""
        contentItem: PlasmaComponents.Label {
            text: "Permanently delete ‘%1’ and its chat history?".arg(deleteDialog.sessionName)
            wrapMode: Text.WordWrap
            width: Kirigami.Units.gridUnit * 22
        }
        footer: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Button {
                text: "Cancel"
                onClicked: deleteDialog.close()
            }
            PlasmaComponents.Button {
                text: "Delete"
                icon.name: "edit-delete"
                onClicked: {
                    const id = deleteDialog.sessionId;
                    deleteDialog.close();
                    popup.app.deleteSession(id);
                }
            }
        }
    }

    QQC2.Dialog {
        id: newChatDialog
        modal: true
        title: "Start a new Codex chat"
        property string pathError: ""
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Label {
                text: "Choose a recent project or enter any project directory."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: popup.recentProjects
                    delegate: PlasmaComponents.Button {
                        required property var modelData
                        text: modelData.name
                        onClicked: newProjectPath.text = modelData.path
                    }
                }
            }
            QQC2.TextField {
                id: newProjectPath
                Layout.fillWidth: true
                placeholderText: "/path/to/project"
                selectByMouse: true
            }
            PlasmaComponents.Label {
                visible: newChatDialog.pathError !== ""
                text: newChatDialog.pathError
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
        footer: RowLayout {
            spacing: Kirigami.Units.smallSpacing
            PlasmaComponents.Button {
                text: "Cancel"
                onClicked: newChatDialog.close()
            }
            PlasmaComponents.Button {
                text: "Open chat"
                icon.name: "list-add"
                onClicked: {
                    const path = newProjectPath.text.trim();
                    if (path === "") {
                        newChatDialog.pathError = "Enter a project directory first.";
                        return;
                    }
                    newChatDialog.close();
                    popup.app.openNewChat(path);
                }
            }
        }
    }
}
