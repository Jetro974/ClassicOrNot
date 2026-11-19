-------------------------------------------------------------------------------
--  Locales.lua
--  The player's texts: English, then the client's language over it. The
--  addon's name is never translated.
-------------------------------------------------------------------------------
local _, ns = ...

local L = {
    NAME = "Classic or Not",
    NEW_ITEM = "New in Forever",

    QUESTS = "Quests",
    PROFESSIONS = "Professions",
    ITEMS = "Items",
    COLLECTIONS = "Collections",

    givers = "At quest givers",
    givers_TIP = "Marks new quests in a quest giver's list and on the quest text before you accept it.",
    log = "In the quest log",
    log_TIP = "Marks new quests in the quest log, under each quest's track box.",
    window = "In the profession window",
    window_TIP = "Marks new recipes in the profession window's recipe list.",
    trainer = "At profession trainers",
    trainer_TIP = "Marks new recipes in a profession trainer's list.",
    tooltip = "In item tooltips",
    tooltip_TIP = "Adds a line to the tooltip of every item that is not from the original game: gear, recipes, mounts, pets and toys.",
    merchant = "At merchants",
    merchant_TIP = "Marks new items in a merchant's list and buyback list.",
    missing = "Show what's missing",
    missing_TIP = "Also shows, greyed, the mounts and pets you lack, and the journals' Filter button the mount and pet filters need.",
    mounts = "Mounts",
    mounts_TIP = "In the mount journal: the mark on new mounts, and All, New in Forever and Classic in the Filter menu, which needs \"Show what's missing\".",
    pets = "Pets",
    pets_TIP = "In the pet journal: the mark on new pets, and All, New in Forever and Classic in the Filter menu, which needs \"Show what's missing\".",
    appearances = "Appearances",
    appearances_TIP = "In the collections journal's appearances: the mark on new ones (those no item of the original game had), and All, New in Forever and Classic in the Filter menu.",
    toys = "Toys: mark",
    toys_TIP = "Marks new toys in the toy box.",
    books = "Library books tab",
    books_TIP = "Adds a tab to the collections journal: the library books to hand in, to find and handed in, with where each one is.",
    booksMap = "Books to find on the maps",
    booksMap_TIP = "Shows the library books you still have to find on the world map and the minimap; a click pins the spot.",
    booksNotes = "Books: tooltip and loot message",
    booksNotes_TIP = "On a library book's tooltip, whether you still have to hand it in; and a chat line when you loot one.",
    BOOK_TODO = "Library book: to hand in",
    BOOK_DONE = "Library book: already handed in",
    BOOK_FIND = "Library book: not handed in yet",
    BOOK_OTHER = "Library book: for the other faction",
    BOOK_FOUND = "library book found: %s. Hand it in to %s (%d/%d).",
    BOOK_AGAIN = "library book already handed in: %s.",
    LIBRARIAN_Alliance = "Garion Wendell (Stormwind)",
    LIBRARIAN_Horde = "Owen Thadd (Undercity)",
    BOOKS = "Library books",
    BOOKS_COUNT = "Books handed in",
    BOOKS_bags = "To hand in",
    BOOKS_find = "To find",
    BOOKS_done = "Handed in",
    BOOKS_PIN = "Click: pin it on the map",
    BOOKS_REWARDS = "Rewards for books handed in",
    BOOKS_REWARD = "%d books",
    BOOKS_HANDIN = "Hand them in to Garion Wendell (Stormwind) or Owen Thadd (Undercity).",
    SHOW_both = "Mark and filter",
    SHOW_mark = "Mark",
    SHOW_filter = "Filter",
    SHOW_none = "None",
    VIEW_all = "All",
    VIEW_new = "New in Forever",
    VIEW_classic = "Classic",
    RELOAD = "This change takes effect at the next reload. Reload the interface now?",
    RELOAD_NOW = "Reload",
    LATER = "Later",
}

if GetLocale() == "frFR" then
    L.NEW_ITEM = "Nouveau dans Forever"

    L.QUESTS = "Quêtes"
    L.PROFESSIONS = "Métiers"
    L.ITEMS = "Objets"

    L.givers = "Chez les donneurs de quêtes"
    L.givers_TIP = "Marque les quêtes nouvelles dans la liste d'un donneur de quêtes et sur le texte de la quête avant de l'accepter."
    L.log = "Dans le journal de quêtes"
    L.log_TIP = "Marque les quêtes nouvelles dans le journal de quêtes, sous la case de suivi de chaque quête."
    L.window = "Dans la fenêtre de métier"
    L.window_TIP = "Marque les recettes nouvelles dans la liste de la fenêtre de métier."
    L.trainer = "Chez les maîtres de métier"
    L.trainer_TIP = "Marque les recettes nouvelles dans la liste d'un maître de métier."
    L.tooltip = "Dans l'infobulle des objets"
    L.tooltip_TIP = "Ajoute une ligne à l'infobulle de chaque objet qui ne vient pas du jeu d'origine : équipement, recettes, montures, mascottes et jouets."
    L.merchant = "Chez les marchands"
    L.merchant_TIP = "Marque les objets nouveaux dans la liste d'un marchand et dans ses rachats."
    L.missing = "Montrer ce qui manque"
    L.missing_TIP = "Montre aussi, en grisé, les montures et mascottes qui manquent, et le bouton Filtre des journaux dont les filtres des montures et des mascottes ont besoin."
    L.mounts = "Montures"
    L.mounts_TIP = "Dans le journal des montures : le sigle sur les nouvelles, et Toutes, Nouveautés de Forever et Classic dans le menu Filtre, qui demande « Montrer ce qui manque »."
    L.pets = "Mascottes"
    L.pets_TIP = "Dans le journal des mascottes : le sigle sur les nouvelles, et Toutes, Nouveautés de Forever et Classic dans le menu Filtre, qui demande « Montrer ce qui manque »."
    L.appearances = "Apparences"
    L.appearances_TIP = "Dans les apparences du journal des collections : le sigle sur les nouvelles (celles qu'aucun objet du jeu d'origine n'avait), et Toutes, Nouveautés de Forever et Classic dans le menu Filtre."
    L.toys = "Jouets : sigle"
    L.toys_TIP = "Marque les jouets nouveaux dans le coffre à jouets."
    L.books = "Onglet Livres de la bibliothèque"
    L.books_TIP = "Ajoute un onglet au journal des collections : les livres de la bibliothèque à rendre, à trouver et remis, avec l'endroit de chacun."
    L.booksMap = "Livres à trouver sur les cartes"
    L.booksMap_TIP = "Montre les livres de la bibliothèque qu'il te reste à trouver sur la carte du monde et la minicarte ; un clic pose un repère."
    L.booksNotes = "Livres : infobulle et message au ramassage"
    L.booksNotes_TIP = "Dit dans l'infobulle d'un livre de la bibliothèque s'il te reste à le rendre, et écrit une ligne dans le chat quand tu en ramasses un."
    L.BOOK_TODO = "Livre de la bibliothèque : à rendre"
    L.BOOK_DONE = "Livre de la bibliothèque : déjà remis"
    L.BOOK_FIND = "Livre de la bibliothèque : pas encore remis"
    L.BOOK_OTHER = "Livre de la bibliothèque : pour l'autre faction"
    L.BOOK_FOUND = "livre trouvé : %s. À rendre à %s (%d/%d)."
    L.BOOK_AGAIN = "livre déjà remis : %s."
    L.LIBRARIAN_Alliance = "Garion Wendell (Hurlevent)"
    L.LIBRARIAN_Horde = "Owen Thadd (Fossoyeuse)"
    L.BOOKS = "Livres de la bibliothèque"
    L.BOOKS_COUNT = "Livres remis"
    L.BOOKS_bags = "À rendre"
    L.BOOKS_find = "À trouver"
    L.BOOKS_done = "Remis"
    L.BOOKS_PIN = "Clic : repère sur la carte"
    L.BOOKS_REWARDS = "Récompenses selon les livres remis"
    L.BOOKS_REWARD = "%d livres"
    L.BOOKS_HANDIN = "À rendre à Garion Wendell (Hurlevent) ou à Owen Thadd (Fossoyeuse)."
    L.SHOW_both = "Sigle et filtre"
    L.SHOW_mark = "Sigle"
    L.SHOW_filter = "Filtre"
    L.SHOW_none = "Rien"
    L.VIEW_all = "Toutes"
    L.VIEW_new = "Nouveautés de Forever"
    L.RELOAD = "Ce changement prend effet au prochain rechargement. Recharger l'interface maintenant ?"
    L.RELOAD_NOW = "Recharger"
    L.LATER = "Plus tard"
end

ns.L = L
