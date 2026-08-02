import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
pragma Singleton

Singleton {
    id: root

    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.assetsPath}/images/default_wallpaper.png`)

    function load() {
        firstRunFileView.reload();
    }

    function handleFirstRun() {
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, root.defaultWallpaperPath]);
    }

    FileView {
        id: firstRunFileView

        path: Qt.resolvedUrl(firstRunFilePath)
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                firstRunFileView.setText(root.firstRunFileContent);
                root.handleFirstRun();
            }
        }
    }

}
