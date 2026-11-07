local _, ns = ...

local L = {
    TITLE = "Demon Trainer",
    NOW = "Available now",
    LEVEL = "Level %d",
    LEARNED = "Learned",
    IN_BAGS = "In bags",
    UNKNOWN = "Summon this demon once so its learned grimoires can be detected.",
    SCANNED = "Learned grimoires detected",
    CLICK_HIDE = "Click to hide",
    CLICK_SHOW = "Click to show",
    NOTICE_LOGIN = "Open grimoires at the demon trainer: %d (%s)",
    NOTICE_LEVEL = "New grimoires: %d. Open in total: %d (%s)",
    NOT_WARLOCK = "Demon Trainer only works for warlocks.",
    TOGGLE = "Toggle window",
    FAMILY = {
        Imp = "Imp",
        Voidwalker = "Voidwalker",
        Succubus = "Succubus",
        Incubus = "Incubus",
        Felhunter = "Felhunter",
    },
}

if GetLocale() == "deDE" then
    L.NOW = "Jetzt verfügbar"
    L.LEVEL = "Stufe %d"
    L.LEARNED = "Gelernt"
    L.IN_BAGS = "In Taschen"
    L.UNKNOWN = "Diesen Dämon einmal beschwören, damit gelernte Grimoires erkannt werden."
    L.SCANNED = "Gelernte Grimoires erkannt"
    L.CLICK_HIDE = "Klicken zum Ausblenden"
    L.CLICK_SHOW = "Klicken zum Einblenden"
    L.NOTICE_LOGIN = "Offene Grimoires beim Dämonenausbilder: %d (%s)"
    L.NOTICE_LEVEL = "Neue Grimoires: %d. Offen insgesamt: %d (%s)"
    L.NOT_WARLOCK = "Demon Trainer funktioniert nur für Hexenmeister."
    L.TOGGLE = "Fenster ein-/ausblenden"
    L.FAMILY = {
        Imp = "Wichtel",
        Voidwalker = "Leerwandler",
        Succubus = "Sukkubus",
        Incubus = "Inkubus",
        Felhunter = "Teufelsjäger",
    }
end

ns.L = L

BINDING_HEADER_DEMONTRAINER = "Demon Trainer"
BINDING_NAME_DEMONTRAINER_TOGGLE = L.TOGGLE
