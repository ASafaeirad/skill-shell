import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: root

    signal done(string path, int width, int height);
    required property string filePath;
    required property string sourceUrl;
    property string downloadUserAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    
    function processFilePath() {
        return StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(filePath));
    }

    function processSourceUrl() {
        return StringUtils.shellSingleQuoteEscape(sourceUrl);
    }

    function curlUserAgentArg() {
        if (!downloadUserAgent) {
            return "";
        }
        return ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(downloadUserAgent)}'`;
    }

    running: true
    command: ["bash", "-c", 
        `mkdir -p $(dirname '${processFilePath()}'); [ -f '${processFilePath()}' ] || curl -sSL '${processSourceUrl()}'${curlUserAgentArg()} -o '${processFilePath()}' && file '${processFilePath()}'`
    ]
    stdout: StdioCollector {
        id: imageSizeOutputCollector
        onStreamFinished: {
            const output = imageSizeOutputCollector.text.trim();
            const match = output.match(/(\d+)\s*x\s*(\d+)/);

            if (match) {
                const width = Number(match[1]);
                const height = Number(match[2]);
                root.done(root.filePath, width, height);
            }
        }
    }
}
