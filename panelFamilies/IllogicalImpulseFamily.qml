import QtQuick
import Quickshell
import qs.modules.common
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
import qs.modules.widgets.selector
import qs.modules.widgets.sessionScreen
import qs.modules.widgets.sidebarRight
import qs.modules.widgets.verticalBar
import qs.modules.widgets.wallpaperSelector

Scope {
    PanelLoader {
        extraCondition: !Config.options.bar.vertical

        component: Bar {
        }

    }

    PanelLoader {

        component: Background {
        }

    }

    PanelLoader {

        component: KeyDisplay {
        }

    }

    PanelLoader {

        component: Lock {
        }

    }

    PanelLoader {

        component: MediaControls {
        }

    }

    PanelLoader {

        component: NotificationPopup {
        }

    }

    PanelLoader {

        component: OnScreenDisplay {
        }

    }

    PanelLoader {

        component: Overlay {
        }

    }

    PanelLoader {

        component: Overview {
        }

    }

    PanelLoader {

        component: Pinentry {
        }

    }

    PanelLoader {

        component: Polkit {
        }

    }

    PanelLoader {

        component: RegionSelector {
        }

    }

    PanelLoader {

        component: ScreenCorners {
        }

    }

    PanelLoader {

        component: ScreenTranslator {
        }

    }

    PanelLoader {

        component: Selector {
        }

    }

    PanelLoader {

        component: SessionScreen {
        }

    }

    PanelLoader {

        component: SidebarRight {
        }

    }

    PanelLoader {
        extraCondition: Config.options.bar.vertical

        component: VerticalBar {
        }

    }

    PanelLoader {

        component: WallpaperSelector {
        }

    }

}
