//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "modules/widgets/gmailInbox"
import "modules/widgets/pass"

import qs.modules.widgets.background
import qs.modules.widgets.bar
import qs.modules.widgets.keyDisplay
import qs.modules.widgets.lock
import qs.modules.widgets.mediaControls
import qs.modules.widgets.notificationPopup
import qs.modules.widgets.onScreenDisplay
import qs.modules.widgets.overlay
import qs.modules.widgets.overview
import qs.modules.widgets.pinentry
import qs.modules.widgets.polkit
import qs.modules.widgets.regionSelector
import qs.modules.widgets.screenCorners
import qs.modules.widgets.screenTranslator
import qs.modules.widgets.screenZoom
import qs.modules.widgets.selector
import qs.modules.widgets.sessionScreen
import qs.modules.widgets.sidebarRight
import qs.modules.widgets.textPopup
import qs.modules.widgets.wallpaperSelector

import QtQuick
import Quickshell

ShellRoot {
    component PanelLoader: LazyLoader {
        property bool extraCondition: true

        active: Config.ready && extraCondition
    }

    ReloadPopup {}

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        PowerProfile.load()
        Cliphist.refresh()
        Wallpapers.load()
    }

    PanelLoader { component: Bar {} }
    PanelLoader { component: GmailInbox {} }

    PanelLoader { component: Background {} }
    PanelLoader { component: KeyDisplay {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Pass {} }
    PanelLoader { component: Pinentry {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: ScreenZoom {} }
    PanelLoader { component: Selector {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { component: TextPopup {} }
    PanelLoader { component: WallpaperSelector {} }
}
