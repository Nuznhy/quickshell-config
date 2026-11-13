pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string helper: Quickshell.shellPath("scripts/wallpaper/wallhaven.py")
    readonly property var sortings: ["toplist", "date_added", "relevance", "random", "views", "favorites"]
    readonly property var topRanges: ["1d", "3d", "1w", "1M", "3M", "6M", "1y"]
    property bool ready: false

    // Saved preferences. The API key is only ever passed to the helper on stdin.
    property string apiKey: ""
    property string username: ""
    property string query: ""
    property string categories: "111"
    property string purity: "100"
    property string sorting: "toplist"
    property string topRange: "1M"
    property bool matchResolution: false
    property int collection: 0
    readonly property bool hasKey: apiKey.length > 0

    // Results of the latest search or collection listing.
    property var items: []
    property int page: 1
    property int lastPage: 1
    property int total: 0
    property string seed: ""
    property bool searched: false
    property string errorMessage: ""
    property var collections: []
    property string collectionsError: ""
    property string downloadingId: ""
    property string downloadError: ""
    readonly property bool loading: searchWorker.running || pendingSearch !== null
    readonly property bool downloading: downloadWorker.running || pendingDownload !== null

    property int revision: 0
    property var pendingSearch: null
    property var searchJob: ({})
    property var pendingDownload: null
    property var downloadJob: ({})
    signal downloaded(string id, string fileUrl, var context)

    // NSFW needs an API key; at least one category and purity stays selected.
    function allowedBits(value, fallback, nsfw) {
        if (typeof value !== "string" || !/^[01]{3}$/.test(value))
            return fallback;
        const masked = nsfw ? value : value.slice(0, 2) + "0";
        return masked === "000" ? fallback : masked;
    }
    function setOption(name, value) {
        if (name === "query" && typeof value === "string")
            query = value.trim().slice(0, 200);
        else if (name === "categories" && allowedBits(value, "", true))
            categories = value;
        else if (name === "purity" && allowedBits(value, "", hasKey))
            purity = allowedBits(value, "", hasKey);
        else if (name === "sorting" && sortings.includes(value))
            sorting = value;
        else if (name === "topRange" && topRanges.includes(value))
            topRange = value;
        else if (name === "matchResolution")
            matchResolution = value === true;
        else if (name === "collection" && Number.isInteger(value) && value >= 0)
            collection = value;
        else
            return false;
        saveTimer.restart();
        return true;
    }
    function setAccount(key, name) {
        if (typeof key !== "string" || typeof name !== "string")
            return;
        apiKey = key.trim();
        username = name.trim();
        if (!hasKey) {
            purity = allowedBits(purity, "100", false);
            collection = 0;
            collections = [];
        }
        saveTimer.restart();
        if (hasKey)
            loadCollections();
    }

    // Request one page; `atleast` is the minimum resolution ("WxH") or empty.
    function search(pageNumber, atleast) {
        revision++;
        const requested = Number.isInteger(pageNumber) && pageNumber > 0 ? pageNumber : 1;
        pendingSearch = {
            action: collection > 0 ? "collection" : "search",
            apiKey: apiKey,
            username: username,
            collection: collection,
            q: query,
            categories: categories,
            purity: purity,
            sorting: sorting,
            topRange: topRange,
            atleast: matchResolution && typeof atleast === "string" ? atleast : "",
            // Random results only page consistently with the server's seed.
            seed: requested > 1 ? seed : "",
            page: requested,
            revision: revision
        };
        errorMessage = "";
        Qt.callLater(pumpSearch);
    }
    function loadCollections() {
        collectionsError = "";
        if (!hasKey || collectionsWorker.running)
            return;
        collectionsWorker.running = true;
    }
    function download(item, context) {
        if (!item || typeof item.id !== "string" || typeof item.full !== "string")
            return;
        downloadError = "";
        pendingDownload = {
            action: "download",
            id: item.id,
            full: item.full,
            context: context || {}
        };
        downloadingId = item.id;
        Qt.callLater(pumpDownload);
    }

    function pumpSearch() {
        if (!ready || !pendingSearch || searchWorker.running)
            return;
        searchJob = pendingSearch;
        pendingSearch = null;
        searchWorker.running = true;
    }
    function pumpDownload() {
        if (!pendingDownload || downloadWorker.running)
            return;
        downloadJob = pendingDownload;
        pendingDownload = null;
        downloadingId = downloadJob.id;
        downloadWorker.running = true;
    }
    function parse(text) {
        try {
            const value = JSON.parse(text);
            return value && typeof value === "object" ? value : {};
        } catch (error) {
            return {};
        }
    }
    function save() {
        stateFile.setText(JSON.stringify({
            apiKey: apiKey,
            username: username,
            query: query,
            categories: categories,
            purity: purity,
            sorting: sorting,
            topRange: topRange,
            matchResolution: matchResolution,
            collection: collection
        }, null, 2) + "\n");
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.save()
    }
    FileView {
        id: stateFile
        path: Quickshell.statePath("wallhaven.json")
        printErrors: false
        onLoaded: {
            if (root.ready)
                return;
            const saved = root.parse(text());
            root.apiKey = typeof saved.apiKey === "string" ? saved.apiKey.trim() : "";
            root.username = typeof saved.username === "string" ? saved.username.trim() : "";
            root.query = typeof saved.query === "string" ? saved.query.slice(0, 200) : "";
            root.categories = root.allowedBits(saved.categories, "111", true);
            root.purity = root.allowedBits(saved.purity, "100", root.hasKey);
            root.sorting = root.sortings.includes(saved.sorting) ? saved.sorting : "toplist";
            root.topRange = root.topRanges.includes(saved.topRange) ? saved.topRange : "1M";
            root.matchResolution = saved.matchResolution === true;
            root.collection = root.hasKey && Number.isInteger(saved.collection) && saved.collection > 0 ? saved.collection : 0;
            root.ready = true;
            if (root.hasKey)
                root.loadCollections();
            root.pumpSearch();
        }
        onLoadFailed: {
            root.ready = true;
            root.pumpSearch();
        }
        onSaveFailed: error => console.warn("Could not save Wallhaven settings:", FileViewError.toString(error))
    }

    Process {
        id: searchWorker
        command: ["python3", root.helper]
        stdinEnabled: true
        property var response: ({})
        onStarted: {
            write(JSON.stringify(root.searchJob));
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: searchWorker.response = root.parse(text)
        }
        stderr: StdioCollector {}
        onExited: code => {
            stdinEnabled = true;
            if (root.searchJob.revision === root.revision) {
                if (code === 0 && Array.isArray(response.items)) {
                    root.items = response.items;
                    root.page = response.page || 1;
                    root.lastPage = Math.max(root.page, response.lastPage || 1);
                    root.total = response.total || 0;
                    if (root.searchJob.page === 1)
                        root.seed = response.seed || "";
                    root.errorMessage = "";
                } else
                    root.errorMessage = response.error || "Wallhaven search failed.";
                root.searched = true;
            }
            Qt.callLater(root.pumpSearch);
        }
    }
    Process {
        id: collectionsWorker
        command: ["python3", root.helper]
        stdinEnabled: true
        property var response: ({})
        onStarted: {
            write(JSON.stringify({
                action: "collections",
                apiKey: root.apiKey
            }));
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: collectionsWorker.response = root.parse(text)
        }
        stderr: StdioCollector {}
        onExited: code => {
            stdinEnabled = true;
            if (code === 0 && Array.isArray(response.collections)) {
                root.collections = response.collections;
                root.collectionsError = "";
                if (root.collection > 0 && !root.collections.some(entry => entry.id === root.collection))
                    root.setOption("collection", 0);
            } else
                root.collectionsError = response.error || "Could not load collections.";
        }
    }
    Process {
        id: downloadWorker
        command: ["python3", root.helper]
        stdinEnabled: true
        property var response: ({})
        onStarted: {
            write(JSON.stringify({
                action: "download",
                id: root.downloadJob.id,
                full: root.downloadJob.full
            }));
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: downloadWorker.response = root.parse(text)
        }
        stderr: StdioCollector {}
        onExited: code => {
            stdinEnabled = true;
            const job = root.downloadJob;
            if (!root.pendingDownload)
                root.downloadingId = "";
            // A newer click supersedes this one; only the latest choice is applied.
            if (!root.pendingDownload) {
                if (code === 0 && typeof response.file === "string" && response.file.startsWith("file:///"))
                    root.downloaded(job.id, response.file, job.context);
                else
                    root.downloadError = response.error || "Could not download this wallpaper.";
            }
            Qt.callLater(root.pumpDownload);
        }
    }
}
