import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    compactRepresentation: CompactRepresentation { app: root }
    fullRepresentation: FullRepresentation { app: root }

    property var agents: ({ "running": [], "waiting": [], "finished": [], "attention": 0, "featured": null })
    property bool refreshing: false
    property string launchError: ""

    function refresh() {
        if (refreshing) return;
        refreshing = true;
        source.exec("python3 \"$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel/contents/code/agents.py\"", function(out) {
            try { agents = JSON.parse(out); } catch (e) { agents = ({ "running": [], "waiting": [], "finished": [], "attention": 0, "featured": null }); }
            refreshing = false;
        });
    }

    function openSession(agent) {
        launchError = "";
        const command = "/usr/bin/python3 \"$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel/contents/code/open_session.py\" "
            + shellQuote(agent.provider) + " " + shellQuote(agent.id) + " " + shellQuote(agent.projectPath || "");
        source.exec(command, function(out, code, err) {
            if (code !== 0) launchError = (err || out || "Could not open the agent session").trim();
            refresh();
        });
    }

    function deleteSession(id) {
        launchError = "";
        source.exec("/usr/bin/python3 \"$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel/contents/code/session_actions.py\" delete " + id, function(out, code, err) {
            if (code !== 0) launchError = (err || out || "Could not delete the chat").trim();
            refresh();
        });
    }

    function closeSession(agent) {
        launchError = "";
        const command = "/usr/bin/python3 \"$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel/contents/code/session_actions.py\" close "
            + shellQuote(agent.provider) + " " + shellQuote(agent.id);
        source.exec(command, function(out, code, err) {
            if (code !== 0) launchError = (err || out || "Could not close the chat window").trim();
            refresh();
        });
    }

    function acknowledgeAllDone() {
        source.exec("python3 \"$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel/contents/code/agents.py\" acknowledge-all", function() {
            refresh();
        });
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'";
    }

    function openNewChat(projectPath) {
        launchError = "";
        source.exec("/usr/bin/python3 \"$HOME/.local/share/plasma/plasmoids/com.vidit.agentpanel/contents/code/new_chat.py\" " + shellQuote(projectPath), function(out, code, err) {
            if (code !== 0) launchError = (err || out || "Could not open a new chat").trim();
        });
    }

    Plasma5Support.DataSource {
        id: source
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})
        property int serial: 0
        function exec(command, callback) {
            const key = command + " #agentpanel" + (++serial);
            if (callback) callbacks[key] = callback;
            connectSource(key);
        }
        onNewData: (key, data) => {
            const cb = callbacks[key];
            delete callbacks[key];
            disconnectSource(key);
            if (cb) cb(data.stdout || "", data["exit code"], data.stderr || "");
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
