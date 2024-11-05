$.Msg("vote_boss.js загружен");

// Через 4 секунды показываем табличку
$.Schedule( 4, () =>  {$("#vote_boss").AddClass("active1")})

function OnGreenButtonClick() {
    $.Msg("Кнопка 'Да' нажата");
    $("#green_rectangle").AddClass("button-pressed");

    // Убираем эффект нажатия и скрываем UI
    $.Schedule(0.3, function() {
        $("#green_rectangle").RemoveClass("button-pressed");
        HideVoteUI();
    });
}

function OnRedButtonClick() {
    $.Msg("Кнопка 'Нет' нажата");
    $("#red_rectangle").AddClass("button-pressed-red");

    // Убираем эффект нажатия и скрываем UI
    $.Schedule(0.3, function() {
        $("#red_rectangle").RemoveClass("button-pressed-red");
        HideVoteUI();
    });
}

// Функция для скрытия всей панели голосования
function HideVoteUI() {
    $("#vote_boss").RemoveClass("active1");
}

var dotahud = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent();
dotahud.FindChildTraverse("TipContainer").visible = false;
dotahud.FindChildTraverse("NextTip").visible = false;
dotahud.FindChildTraverse("PrevTip").visible = false;