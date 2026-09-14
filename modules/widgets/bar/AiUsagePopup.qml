import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledPopup {
    id: root

    function remainingPercent(windowData) {
        if (!windowData || windowData.usedPercent === undefined || windowData.usedPercent === null)
            return null;
        return Math.max(0, Math.min(100, Math.round(100 - windowData.usedPercent)));
    }

    function progressColor(provider, windowData) {
        if (AiUsage.isStale(provider) || root.remainingPercent(windowData) === null)
            return Appearance.colors.colOutline;
        const remaining = root.remainingPercent(windowData);
        if (remaining <= 20)
            return Appearance.colors.colError;
        if (remaining <= 40)
            return Appearance.colors.colTertiary;
        return Appearance.colors.colPrimary;
    }

    function syncStatusText() {
        if (AiUsage.syncing)
            return "SYNCING";
        if (AiUsage.paused)
            return "PAUSED";
        const claudeTime = AiUsage.claude?.capturedAt ?? 0;
        const codexTime = AiUsage.codex?.capturedAt ?? 0;
        const capturedAt = Math.max(claudeTime, codexTime);
        if (capturedAt <= 0)
            return "NOT SYNCED";
        return `SYNCED ${Qt.formatDateTime(new Date(capturedAt * 1000), "HH:mm")}`;
    }

    ColumnLayout {
        id: popupContent

        anchors.centerIn: parent
        spacing: Appearance.spacing.m

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.xs

            MaterialSymbol {
                text: "data_usage"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: "AI usage limits"
                color: Appearance.colors.colOnLayer2
                font {
                    pixelSize: Appearance.font.pixelSize.large
                    weight: Font.Medium
                }
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: root.syncStatusText()
                color: Appearance.colors.colSubtext
                font {
                    pixelSize: Appearance.font.pixelSize.smallest
                    capitalization: Font.AllUppercase
                    letterSpacing: Appearance.spacing.xxs / 2
                }
            }
        }

        GridLayout {
            id: providerGrid

            columns: 2
            columnSpacing: Appearance.spacing.m
            rowSpacing: Appearance.spacing.m

            ProviderCard {
                Layout.fillHeight: true
                providerName: "Claude"
                provider: AiUsage.claude
            }

            ProviderCard {
                Layout.fillHeight: true
                providerName: "Codex"
                provider: AiUsage.codex
            }
        }
    }

    component ProviderCard: Rectangle {
        id: providerCard

        required property string providerName
        required property var provider
        readonly property real contentPadding: Appearance.spacing.lg

        implicitWidth: Math.max(cardContent.implicitWidth + contentPadding * 2,
            Appearance.font.pixelSize.normal * 13)
        implicitHeight: cardContent.implicitHeight + contentPadding * 2
        color: Appearance.colors.colLayer3
        radius: Appearance.rounding.normal

        ColumnLayout {
            id: cardContent

            anchors {
                fill: parent
                margins: providerCard.contentPadding
            }
            spacing: Appearance.spacing.m

            StyledText {
                text: providerCard.providerName
                color: Appearance.colors.colOnLayer3
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
            }

            UsageWindowRow {
                provider: providerCard.provider
                windowData: providerCard.provider?.fiveHour
                windowLabel: "5h"
                icon: "hourglass_empty"
            }

            UsageWindowRow {
                provider: providerCard.provider
                windowData: providerCard.provider?.sevenDay
                windowLabel: "7d"
                icon: "calendar_month"
            }
        }
    }

    component UsageWindowRow: RowLayout {
        id: usageRow

        required property var provider
        required property var windowData
        required property string windowLabel
        required property string icon
        readonly property var remaining: root.remainingPercent(windowData)

        spacing: Appearance.spacing.xs

        IconCircularProgress {
            id: windowProgress

            implicitSize: Appearance.font.pixelSize.hugeass + Appearance.spacing.m
            lineWidth: Appearance.spacing.xs / 2
            value: (usageRow.remaining ?? 0) / 100
            colPrimary: root.progressColor(usageRow.provider, usageRow.windowData)
            icon: usageRow.icon
            iconSize: Appearance.font.pixelSize.small
            enableAnimation: true
            animationDuration: Appearance.animation.elementMove.duration
        }

        ColumnLayout {
            spacing: 0

            StyledText {
                text: usageRow.remaining === null ? "--" : `${usageRow.remaining}%`
                color: Appearance.colors.colOnLayer3
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
            }

            StyledText {
                text: `${usageRow.windowLabel} · ${AiUsage.resetText(usageRow.windowData)}`
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
        }
    }
}
