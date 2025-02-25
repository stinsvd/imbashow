let activated = false
function UpdateWaveTimer() {
	activated = true
	let data = CustomNetTables.GetTableValue("game_options", "waveOptions");
	$("#WaveTimerMain").SetHasClass("hidden", data == null)
	if (data) {
		$("#WaveTimerProgressBar").value = data.waveTimer / data.waveInterval
		$("#WaveTimerText").text = `${Math.max(Math.floor(data.waveTimer), 0)} / ${data.waveInterval}`
		$("#WaveName").SetDialogVariableInt("current_wave", Math.floor(data.currentWave));
	}
}

function ShowBossKilledNotif(data) {
	$("#NeutralBossKilledText").text = `Босс ${data.text} был убит`
	$("#NeutralBossNotificationMain").SetHasClass("hidden", false)
	$.Schedule((data.delay || 5), () => {
		$("#NeutralBossNotificationMain").SetHasClass("hidden", true)
	})
}


(function() {
	CustomNetTables.SubscribeNetTableListener("game_options", UpdateWaveTimer)
	
	GameEvents.Subscribe("ShowBossKilledNotif", ShowBossKilledNotif)
	
	$.RegisterForUnhandledEvent("DOTAHUDShopClosed", function () {
		if (activated == true) {
		}
	})
	
	$.RegisterForUnhandledEvent("DOTAHUDShopOpened", function () {
		if (activated == true) {
		}
	})
})()
