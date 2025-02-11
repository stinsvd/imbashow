function UpdateWaveTimer() {
	let data = CustomNetTables.GetTableValue("game_options", "waveOptions");
	$("#WaveTimerMain").SetHasClass("hidden", data == null)
	if (data) {
		$("#WaveTimerProgressBar").value = data.waveTimer / data.waveInterval
		$("#WaveTimerText").text = `${Math.max(Math.floor(data.waveTimer), 0)} / ${data.waveInterval}`
		$("#WaveName").SetDialogVariableInt("current_wave", Math.floor(data.currentWave));
	//	$("#WaveName").text = `Волна: ${Math.floor(data.currentWave)}`
	}
}

(function() {
	CustomNetTables.SubscribeNetTableListener("game_options", UpdateWaveTimer)
})()
