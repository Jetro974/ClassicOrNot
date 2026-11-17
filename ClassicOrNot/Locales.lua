-------------------------------------------------------------------------------
--  Locales.lua
--  The player's texts: English, then the client's language over it. The
--  addon's name is never translated.
-------------------------------------------------------------------------------
local _, ns = ...

local L = {
    NAME = "Classic or Not",
    SUBTITLE = "What's New in Forever",
    DESCRIPTION = "Marks with a small blue infinity what is not from the original game.",
    GENERAL = "General",
    NEW_ITEM = "New in Forever",

    QUESTS = "Quests", QUESTS_UP = "QUESTS",
    RECIPES = "Recipes", RECIPES_UP = "RECIPES",
    ITEMS = "Items and collections", ITEMS_UP = "ITEMS AND COLLECTIONS",

    givers = "At quest givers",
    givers_TIP = "Marks new quests in a quest giver's list and on the quest text before you accept it.",
    log = "In the quest log",
    log_TIP = "Marks new quests in the quest log, under each quest's track box.",
    tracker = "In the quest tracker",
    tracker_TIP = "Marks new quests on the rows of EllesmereUI's quest tracker.",
    window = "In the profession window",
    window_TIP = "Marks new recipes in the profession window's recipe list.",
    trainer = "At profession trainers",
    trainer_TIP = "Marks new recipes in a profession trainer's list.",
    tooltip = "In item tooltips",
    tooltip_TIP = "Adds a line to the tooltip of every item that is not from the original game: gear, recipes, mounts, pets and toys.",
    mounts = "In the mount journal",
    mounts_TIP = "Marks new mounts in the mount journal.",
    pets = "In the pet journal",
    pets_TIP = "Marks new pets in the pet journal.",
    toys = "In the toy box",
    toys_TIP = "Marks new toys in the toy box.",
    appearances = "In appearances",
    appearances_TIP = "Marks new appearances in the collections journal: those no item of the original game had.",
}

if GetLocale() == "frFR" then
    L.SUBTITLE = "Les nouveautés de Forever"
    L.DESCRIPTION = "Marque d'un petit infini bleu ce qui ne vient pas du jeu d'origine."
    L.GENERAL = "Général"
    L.NEW_ITEM = "Nouveau dans Forever"

    L.QUESTS, L.QUESTS_UP = "Quêtes", "QUÊTES"
    L.RECIPES, L.RECIPES_UP = "Recettes", "RECETTES"
    L.ITEMS, L.ITEMS_UP = "Objets et collections", "OBJETS ET COLLECTIONS"

    L.givers = "Chez les donneurs de quêtes"
    L.givers_TIP = "Marque les quêtes nouvelles dans la liste d'un donneur de quêtes et sur le texte de la quête avant de l'accepter."
    L.log = "Dans le journal de quêtes"
    L.log_TIP = "Marque les quêtes nouvelles dans le journal de quêtes, sous la case de suivi de chaque quête."
    L.tracker = "Dans le suivi des quêtes"
    L.tracker_TIP = "Marque les quêtes nouvelles sur les lignes du suivi des quêtes d'EllesmereUI."
    L.window = "Dans la fenêtre de métier"
    L.window_TIP = "Marque les recettes nouvelles dans la liste de la fenêtre de métier."
    L.trainer = "Chez les maîtres de métier"
    L.trainer_TIP = "Marque les recettes nouvelles dans la liste d'un maître de métier."
    L.tooltip = "Dans l'infobulle des objets"
    L.tooltip_TIP = "Ajoute une ligne à l'infobulle de chaque objet qui ne vient pas du jeu d'origine : équipement, recettes, montures, mascottes et jouets."
    L.mounts = "Dans le journal des montures"
    L.mounts_TIP = "Marque les montures nouvelles dans le journal des montures."
    L.pets = "Dans le journal des mascottes"
    L.pets_TIP = "Marque les mascottes nouvelles dans le journal des mascottes."
    L.toys = "Dans le coffre à jouets"
    L.toys_TIP = "Marque les jouets nouveaux dans le coffre à jouets."
    L.appearances = "Dans les apparences"
    L.appearances_TIP = "Marque les apparences nouvelles dans le journal des collections : celles qu'aucun objet du jeu d'origine n'avait."
end

ns.L = L
