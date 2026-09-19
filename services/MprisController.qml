pragma Singleton
pragma ComponentBehavior: Bound

// From https://git.outfoxxed.me/outfoxxed/nixnew
// It does not have a license, but the author is okay with redistribution.

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.modules.common
import qs.services

/**
 * A service that provides easy access to the active Mpris player.
 */
Singleton {
	id: root;
	property list<MprisPlayer> players: Mpris.players.values.filter(player => isRealPlayer(player));
	property MprisPlayer trackedPlayer: null;
	property MprisPlayer activePlayer: trackedPlayer ?? Mpris.players.values[0] ?? null;
	signal trackChanged(reverse: bool);

	property bool __reverse: false;

	property var activeTrack;

	readonly property bool hasActivePlasmaIntegration: Mpris.players.values.some(
		p => p.dbusName?.startsWith('org.mpris.MediaPlayer2.plasma-browser-integration')
	)
	function isRealPlayer(player) {
        if (!Config.options.media.filterDuplicatePlayers) {
            return true;
        }
        return (
            // Remove native browser buses only if plasma-browser-integration is actually active on D-Bus
            !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox')) && !(hasActivePlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            // playerctld just copies other buses and we don't need duplicates
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            // Non-instance mpd bus
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd')));
    }

	// Original stuff from fox below
	Instantiator {
		model: Mpris.players;

		Connections {
			required property MprisPlayer modelData;
			target: modelData;

			Component.onCompleted: {
				if (root.trackedPlayer == null || modelData.isPlaying) {
					root.trackedPlayer = modelData;
				}
			}

			Component.onDestruction: {
				if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
					for (const player of Mpris.players.values) {
						if (player.playbackState.isPlaying) {
							root.trackedPlayer = player;
							break;
						}
					}

					if (trackedPlayer == null && Mpris.players.values.length != 0) {
						trackedPlayer = Mpris.players.values[0];
					}
				}
			}

			function onPlaybackStateChanged() {
				if (root.trackedPlayer !== modelData) root.trackedPlayer = modelData;
			}
		}
	}

	Connections {
		target: activePlayer

		function onPostTrackChanged() {
			root.updateTrack();
		}

		function onTrackArtUrlChanged() {
			// console.log("arturl:", activePlayer.trackArtUrl)
			// root.updateTrack();
			if (root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.artUrl) {
				// cantata likes to send cover updates *BEFORE* updating the track info.
				// as such, art url changes shouldn't be able to break the reverse animation
				const r = root.__reverse;
				root.updateTrack();
				root.__reverse = r;

			}
		}
	}

	onActivePlayerChanged: this.updateTrack();

	function updateTrack() {
		//console.log(`update: ${this.activePlayer?.trackTitle ?? ""} : ${this.activePlayer?.trackArtists}`)
		this.activeTrack = {
			uniqueId: this.activePlayer?.uniqueId ?? 0,
			artUrl: this.activePlayer?.trackArtUrl ?? "",
			title: this.activePlayer?.trackTitle || "Unknown Title",
			artist: this.activePlayer?.trackArtist || "Unknown Artist",
			album: this.activePlayer?.trackAlbum || "Unknown Album",
		};

		this.trackChanged(__reverse);
		this.__reverse = false;
	}

	property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying;
	property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false;
	function togglePlaying() {
		if (this.canTogglePlaying) this.activePlayer.togglePlaying();
	}

	property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false;
	function previous() {
		if (this.canGoPrevious) {
			this.__reverse = true;
			this.activePlayer.previous();
		}
	}

	property bool canGoNext: this.activePlayer?.canGoNext ?? false;
	function next() {
		if (this.canGoNext) {
			this.__reverse = false;
			this.activePlayer.next();
		}
	}

	property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl;

	property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl;
	property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None;
	function setLoopState(loopState: var) {
		if (this.loopSupported) {
			this.activePlayer.loopState = loopState;
		}
	}

	property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl;
	property bool hasShuffle: this.activePlayer?.shuffle ?? false;
	function setShuffle(shuffle: bool) {
		if (this.shuffleSupported) {
			this.activePlayer.shuffle = shuffle;
		}
	}

	function setActivePlayer(player: MprisPlayer) {
		const targetPlayer = player ?? Mpris.players[0];
		console.log(`[Mpris] Active player ${targetPlayer} << ${activePlayer}`)

		if (targetPlayer && this.activePlayer) {
			this.__reverse = Mpris.players.indexOf(targetPlayer) < Mpris.players.indexOf(this.activePlayer);
		} else {
			// always animate forward if going to null
			this.__reverse = false;
		}

		this.trackedPlayer = targetPlayer;
	}

	function focusPlayer(player: var): bool {
		if (!player) return false;

		if (player.canRaise) {
			player.raise();
		}

		const dbusName = player.dbusName || "";
		const desktopEntry = player.desktopEntry || "";
		const identity = player.identity || "";
		const trackTitle = (player.trackTitle || "").toLowerCase().trim();
		const trackArtist = (player.trackArtist || "").toLowerCase().trim();

		const strippedBus = dbusName.replace(/^org\.mpris\.MediaPlayer2\./, "");
		const busBase = strippedBus.split(".")[0];

		const pidMatch = dbusName.match(/instance_?(\d+)/i);
		const playerPid = pidMatch ? parseInt(pidMatch[1], 10) : null;

		const genericPrefixes = ["org", "com", "net", "io", "app", "dev"];
		const tokens = [];
		function addToken(str) {
			if (!str) return;
			const clean = str.trim().toLowerCase();
			if (clean.length >= 2 && !tokens.includes(clean) && !genericPrefixes.includes(clean)) {
				tokens.push(clean);
			}
		}

		addToken(desktopEntry);
		if (desktopEntry) {
			const parts = desktopEntry.toLowerCase().split(".");
			for (let i = 0; i < parts.length; ++i) {
				addToken(parts[i]);
			}
			addToken(parts.join(""));
		}
		addToken(identity);
		if (identity) {
			addToken(identity.replace(/\s+/g, ""));
		}
		addToken(busBase);
		if (strippedBus) {
			addToken(strippedBus);
		}

		const windows = HyprlandData.windowList || [];
		let bestWindow = null;
		let bestScore = 0;

		for (let i = 0; i < windows.length; ++i) {
			const win = windows[i];
			let score = 0;
			const winPid = win.pid;
			const winClass = (win.class || "").toLowerCase();
			const winInitialClass = (win.initialClass || "").toLowerCase();
			const winTitle = (win.title || "").toLowerCase();
			const winInitialTitle = (win.initialTitle || "").toLowerCase();

			if (playerPid && winPid === playerPid) {
				score += 1000;
			}

			for (let t = 0; t < tokens.length; ++t) {
				const token = tokens[t];
				if (winClass === token || winInitialClass === token) {
					score += 500;
					break;
				} else if (winClass.replace(/[-_.]/g, "") === token.replace(/[-_.]/g, "")) {
					score += 400;
					break;
				} else if (winClass.includes(token) || token.includes(winClass)) {
					score += 250;
					break;
				}
			}

			if (score === 0) {
				for (let t = 0; t < tokens.length; ++t) {
					const token = tokens[t];
					if (token.length >= 3 && (winTitle.includes(token) || winInitialTitle.includes(token))) {
						score += 150;
						break;
					}
				}
			}

			if (score > 0) {
				if (trackTitle.length > 2 && winTitle.includes(trackTitle)) {
					score += 200;
				}
				if (trackArtist.length > 2 && winTitle.includes(trackArtist)) {
					score += 100;
				}
				if (typeof win.focusHistoryID === "number") {
					score += Math.max(0, 50 - win.focusHistoryID);
				}
			}

			if (score > bestScore) {
				bestScore = score;
				bestWindow = win;
			}
		}

		if (bestWindow && bestScore > 0) {
			const addr = bestWindow.address.startsWith("0x") ? bestWindow.address : `0x${bestWindow.address}`;
			if (bestWindow.workspace && bestWindow.workspace.id < 0 && bestWindow.workspace.name && bestWindow.workspace.name.startsWith("special:")) {
				const specialName = bestWindow.workspace.name.slice(8);
				Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${specialName}")`);
			}
			Hyprland.dispatch(`hl.dsp.focus({window = "address:${addr}"})`);

			if (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) {
				const toplevels = ToplevelManager.toplevels.values;
				for (let i = 0; i < toplevels.length; ++i) {
					const tl = toplevels[i];
					if (`0x${tl.HyprlandToplevel?.address}` === addr) {
						tl.activate();
						break;
					}
				}
			}
			return true;
		}

		if (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) {
			const toplevels = ToplevelManager.toplevels.values;
			for (let i = 0; i < toplevels.length; ++i) {
				const tl = toplevels[i];
				const appId = (tl.appId || "").toLowerCase();
				let matched = false;
				for (let t = 0; t < tokens.length; ++t) {
					const token = tokens[t];
					if (appId === token || (token.length >= 3 && (appId.includes(token) || token.includes(appId)))) {
						matched = true;
						break;
					}
				}
				if (matched) {
					if (tl.HyprlandToplevel?.address) {
						const addr = `0x${tl.HyprlandToplevel.address}`;
						Hyprland.dispatch(`hl.dsp.focus({window = "address:${addr}"})`);
					}
					tl.activate();
					return true;
				}
			}
		}

		return false;
	}

	IpcHandler {
		target: "mpris"

		function pauseAll(): void {
			for (const player of Mpris.players.values) {
				if (player.canPause) player.pause();
			}
		}

		function playPause(): void { root.togglePlaying(); }
		function previous(): void { root.previous(); }
		function next(): void { root.next(); }
		function focus(playerName: string): void {
			const target = root.players.find(p => p.identity === playerName || p.dbusName === playerName) ?? root.activePlayer;
			if (target) root.focusPlayer(target);
		}
	}
}
