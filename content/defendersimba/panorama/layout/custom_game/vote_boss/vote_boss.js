$.Schedule(1, () => {$("#vote_boss").AddClass("active1")})

function ConfirmButton(choise) {
	$("#vote_boss").RemoveClass("active1");
	GameEvents.SendCustomGameEventToServer("OnPlayerChoseBoss", {PlayerID: Players.GetLocalPlayer(), choice: choise});
	let loc = choise == 0 ? "Да" : "Нет";
	GameUI.SendCustomHUDError("Жопка выбрала: "+loc, 0);
}
