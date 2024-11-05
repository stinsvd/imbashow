"GameInfo"
{
    game "Dota 2"
    title "DefenderSimba"

    FileSystem
    {
        SteamAppId                570
        ToolsAppId                816
        AdditionalContentId       570

        SearchPaths
        {
            Game                |gameinfo_path|.
            Game                dota
            Game                |all_source_engine_paths|hl2
        }
    }

    "Custom"
    {
        "ResourceCompiler"
        {
            "SourceModDir"      "defendersimba"
            "DestGameDir"       "defendersimba"
            "SourceDir"         "content/dota_addons"
            "DestDir"           "game/dota_addons"
        }
    }
}
