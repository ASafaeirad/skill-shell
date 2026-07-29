import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.actionCenter
import qs.modules.waffle.looks
import qs.services

ActionCenterToggle {
    id: root

    name: Network.ethernet ? Translation.tr("Network") : Network.networkName
}
