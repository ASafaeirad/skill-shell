import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property var action
    property string description: switch (root.action) {
    case RegionSelection.SnipAction.Copy:
    case RegionSelection.SnipAction.Edit:
        return "Copy region (LMB) or annotate (RMB)";
    case RegionSelection.SnipAction.Search:
        return "Search with Google Lens";
    case RegionSelection.SnipAction.CharRecognition:
        return "Recognize text";
    case RegionSelection.SnipAction.Record:
        return "Record region";
    case RegionSelection.SnipAction.RecordWithSound:
        return "Record region with audio";
    }
    property string materialSymbol: switch (root.action) {
    case RegionSelection.SnipAction.Copy:
    case RegionSelection.SnipAction.Edit:
        return "content_cut";
    case RegionSelection.SnipAction.Search:
        return "image_search";
    case RegionSelection.SnipAction.CharRecognition:
        return "document_scanner";
    case RegionSelection.SnipAction.Record:
        return "videocam";
    case RegionSelection.SnipAction.RecordWithSound:
        return "mic";
    default:
        return "";
    }
    property bool showDescription: true
    property int margins: 8

    function hideDescription() {
        root.showDescription = false;
    }

    onActionChanged: {
        root.showDescription = true;
        descTimeout.restart();
    }
    implicitWidth: content.implicitWidth + margins * 2
    implicitHeight: content.implicitHeight + margins * 2

    Timer {
        id: descTimeout

        interval: 1000
        running: true
        onTriggered: {
            root.hideDescription();
        }
    }

    Rectangle {
        id: content

        property real padding: 8

        anchors.centerIn: parent
        implicitHeight: 38
        implicitWidth: root.showDescription ? contentRow.implicitWidth + padding * 2 : implicitHeight
        clip: true
        topLeftRadius: 6
        bottomLeftRadius: implicitHeight - topLeftRadius
        bottomRightRadius: bottomLeftRadius
        topRightRadius: bottomLeftRadius
        color: Appearance.colors.colPrimary

        Row {
            id: contentRow

            spacing: 12

            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: content.padding
            }

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: Appearance.colors.colOnPrimary
                animateChange: true
                text: root.materialSymbol
            }

            FadeLoader {
                id: descriptionLoader

                anchors.verticalCenter: parent.verticalCenter
                shown: root.showDescription

                sourceComponent: StyledText {
                    color: Appearance.colors.colOnPrimary
                    text: root.description
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                }

            }

        }

        Behavior on topLeftRadius {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

    }

}
