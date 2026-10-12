"""Writes the translation files of Timber! Chainsaw (Build 42.21, .json only).

    python source/build_translations.py

getText() picks the file from the key prefix (Translator.java, 42.21):
IGUI_ -> IG_UI.json, ContextMenu_ -> ContextMenu.json, Tooltip_ -> Tooltip.json,
Sandbox_ -> Sandbox.json, GameSound_ -> GameSound.json; item names in
ItemName.json ("Module.Type"), recipe names in Recipes.json (recipe name).
No fallback except English: every language lists every key.
A lone % is written %% (Translator formats the strings).
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRANSLATE = (ROOT / "Contents" / "mods" / "batman_TimberChainsaw" / "42.21"
             / "media" / "lua" / "shared" / "Translate")

LANGS = ["EN", "FR", "DE", "ES", "IT", "PL", "PTBR", "RU"]  # CN and PT: T2 below

# key -> (EN, FR, DE, ES, IT, PL, PTBR, RU)
T = {
    "ItemName": {
        "ChainsawB42.ChainsawOff": ("Chainsaw", "Tronçonneuse", "Kettensäge", "Motosierra", "Motosega", "Piła łańcuchowa", "Motosserra", "Бензопила"),
        "ChainsawB42.Chainsaw": ("Chainsaw (running)", "Tronçonneuse (en marche)", "Kettensäge (läuft)", "Motosierra (en marcha)", "Motosega (accesa)", "Piła łańcuchowa (włączona)", "Motosserra (ligada)", "Бензопила (работает)"),
        "ChainsawB42.ChainsawMaintenanceMagazine": ("Small Engine Repair & Maintenance", "Réparation et entretien des petits moteurs", "Reparatur und Wartung von Kleinmotoren", "Reparación y mantenimiento de motores pequeños", "Riparazione e manutenzione dei piccoli motori", "Naprawa i konserwacja małych silników", "Reparo e manutenção de motores pequenos", "Ремонт и обслуживание малых двигателей"),
    },
    "Recipes": {
        "ForgeChainsaw": ("Forge Chainsaw", "Forger une tronçonneuse", "Kettensäge schmieden", "Forjar motosierra", "Forgiare una motosega", "Wykuj piłę łańcuchową", "Forjar motosserra", "Выковать бензопилу"),
        "RepairChainsaw": ("Repair Chainsaw", "Réparer la tronçonneuse", "Kettensäge reparieren", "Reparar motosierra", "Riparare la motosega", "Napraw piłę łańcuchową", "Consertar motosserra", "Починить бензопилу"),
    },
    "ContextMenu": {
        "ContextMenu_CSB42_Start": ("Start the chainsaw", "Démarrer la tronçonneuse", "Kettensäge starten", "Arrancar la motosierra", "Avviare la motosega", "Uruchom piłę łańcuchową", "Ligar a motosserra", "Завести бензопилу"),
        "ContextMenu_CSB42_Stop": ("Stop the chainsaw", "Arrêter la tronçonneuse", "Kettensäge abstellen", "Apagar la motosierra", "Spegnere la motosega", "Wyłącz piłę łańcuchową", "Desligar a motosserra", "Заглушить бензопилу"),
        "ContextMenu_CSB42_Refuel": ("Refuel the chainsaw", "Faire le plein de la tronçonneuse", "Kettensäge betanken", "Repostar la motosierra", "Fare il pieno alla motosega", "Zatankuj piłę łańcuchową", "Abastecer a motosserra", "Заправить бензопилу"),
        "ContextMenu_CSB42_CutTree": ("Cut down the tree with the chainsaw", "Abattre l'arbre à la tronçonneuse", "Baum mit der Kettensäge fällen", "Talar el árbol con la motosierra", "Abbattere l'albero con la motosega", "Zetnij drzewo piłą łańcuchową", "Derrubar a árvore com a motosserra", "Спилить дерево бензопилой"),
    },
    "Tooltip": {
        "Tooltip_CSB42_Broken": ("The chainsaw is broken.", "La tronçonneuse est cassée.", "Die Kettensäge ist kaputt.", "La motosierra está rota.", "La motosega è rotta.", "Piła łańcuchowa jest zepsuta.", "A motosserra está quebrada.", "Бензопила сломана."),
        "Tooltip_CSB42_NoFuel": ("The tank is empty.", "Le réservoir est vide.", "Der Tank ist leer.", "El depósito está vacío.", "Il serbatoio è vuoto.", "Zbiornik jest pusty.", "O tanque está vazio.", "Бак пуст."),
        "Tooltip_CSB42_InVehicle": ("Not inside a vehicle.", "Pas dans un véhicule.", "Nicht in einem Fahrzeug.", "No dentro de un vehículo.", "Non dentro un veicolo.", "Nie w pojeździe.", "Não dentro de um veículo.", "Не в транспорте."),
        "Tooltip_CSB42_NoPetrol": ("Needs a container of pure petrol in your inventory.", "Il faut un récipient d'essence pure dans l'inventaire.", "Benötigt einen Behälter mit reinem Benzin im Inventar.", "Necesita un recipiente con gasolina pura en el inventario.", "Serve un contenitore di benzina pura nell'inventario.", "Potrzebny pojemnik z czystą benzyną w ekwipunku.", "Precisa de um recipiente com gasolina pura no inventário.", "Нужна ёмкость с чистым бензином в инвентаре."),
    },
    "IG_UI": {
        "IGUI_CSB42_TooltipProvider": ("Chainsaw: engine and fuel", "Tronçonneuse : moteur et carburant", "Kettensäge: Motor und Kraftstoff", "Motosierra: motor y combustible", "Motosega: motore e carburante", "Piła łańcuchowa: silnik i paliwo", "Motosserra: motor e combustível", "Бензопила: двигатель и топливо"),
        "IGUI_CSB42_Engine": ("Engine", "Moteur", "Motor", "Motor", "Motore", "Silnik", "Motor", "Двигатель"),
        "IGUI_CSB42_Running": ("Running", "En marche", "Läuft", "En marcha", "Acceso", "Włączony", "Ligado", "Работает"),
        "IGUI_CSB42_Stopped": ("Stopped", "Arrêté", "Aus", "Apagado", "Spento", "Wyłączony", "Desligado", "Заглушен"),
        "IGUI_CSB42_Fuel": ("Fuel", "Carburant", "Kraftstoff", "Combustible", "Carburante", "Paliwo", "Combustível", "Топливо"),
        "IGUI_CSB42_Jammed": ("*Sputter* The chainsaw won't start...", "*Toussotement* La tronçonneuse ne démarre pas...", "*Stotter* Die Kettensäge springt nicht an...", "*Petardeo* La motosierra no arranca...", "*Scoppiettio* La motosega non parte...", "*Krztuszenie* Piła nie chce zapalić...", "*Engasgo* A motosserra não pega...", "*Чих-пых* Бензопила не заводится..."),
        "IGUI_CSB42_OutOfFuel": ("The chainsaw ran out of fuel", "La tronçonneuse n'a plus d'essence", "Der Kettensäge ist der Kraftstoff ausgegangen", "La motosierra se quedó sin combustible", "La motosega ha finito il carburante", "W pile skończyło się paliwo", "A motosserra ficou sem combustível", "В бензопиле кончилось топливо"),
        "IGUI_CSB42_Broken": ("The chainsaw broke", "La tronçonneuse a cassé", "Die Kettensäge ist kaputtgegangen", "La motosierra se ha roto", "La motosega si è rotta", "Piła łańcuchowa się zepsuła", "A motosserra quebrou", "Бензопила сломалась"),
        "IGUI_CSB42_Repaired": ("Chainsaw repaired", "Tronçonneuse réparée", "Kettensäge repariert", "Motosierra reparada", "Motosega riparata", "Piła naprawiona", "Motosserra consertada", "Бензопила отремонтирована"),
    },
    "Sandbox": {
        "Sandbox_ChainsawB42": ("Chainsaw B42", "Tronçonneuse B42", "Kettensäge B42", "Motosierra B42", "Motosega B42", "Piła łańcuchowa B42", "Motosserra B42", "Бензопила B42"),
        "Sandbox_ChainsawB42_FuelConsumption": ("Fuel consumption", "Consommation de carburant", "Kraftstoffverbrauch", "Consumo de combustible", "Consumo di carburante", "Zużycie paliwa", "Consumo de combustível", "Расход топлива"),
        "Sandbox_ChainsawB42_FuelConsumption_tooltip": ("In %. 100 = a full tank lasts about 16 minutes idling at game speed x1, less while cutting. 0 = no consumption.", "En %. 100 = un plein dure environ 16 minutes au ralenti à la vitesse x1, moins en coupant. 0 = aucune consommation.", "In %. 100 = ein voller Tank hält im Leerlauf bei Spielgeschwindigkeit x1 etwa 16 Minuten, beim Sägen weniger. 0 = kein Verbrauch.", "En %. 100 = un depósito lleno dura unos 16 minutos al ralentí a velocidad x1, menos al cortar. 0 = sin consumo.", "In %. 100 = un pieno dura circa 16 minuti al minimo a velocità x1, meno tagliando. 0 = nessun consumo.", "W %. 100 = pełny zbiornik wystarcza na około 16 minut na biegu jałowym przy prędkości x1, krócej podczas cięcia. 0 = brak zużycia.", "Em %. 100 = um tanque cheio dura cerca de 16 minutos em marcha lenta na velocidade x1, menos cortando. 0 = sem consumo.", "В %. 100 = полного бака хватает примерно на 16 минут холостого хода при скорости x1, при пилении меньше. 0 = без расхода."),
        "Sandbox_ChainsawB42_DamageMod": ("Damage", "Dégâts", "Schaden", "Daño", "Danno", "Obrażenia", "Dano", "Урон"),
        "Sandbox_ChainsawB42_DamageMod_tooltip": ("In %, damage of a running chainsaw. 100 = normal.", "En %, dégâts d'une tronçonneuse en marche. 100 = normal.", "In %, Schaden einer laufenden Kettensäge. 100 = normal.", "En %, daño de una motosierra en marcha. 100 = normal.", "In %, danno di una motosega accesa. 100 = normale.", "W %, obrażenia włączonej piły. 100 = normalnie.", "Em %, dano de uma motosserra ligada. 100 = normal.", "В %, урон работающей бензопилы. 100 = обычный."),
        "Sandbox_ChainsawB42_ConditionLossCombat": ("Combat wear", "Usure au combat", "Verschleiß im Kampf", "Desgaste en combate", "Usura in combattimento", "Zużycie w walce", "Desgaste em combate", "Износ в бою"),
        "Sandbox_ChainsawB42_ConditionLossCombat_tooltip": ("Condition lost per zombie killed with a running chainsaw (condition 200). 20 = about 10 zombies. 0 = none.", "État perdu par zombie tué avec une tronçonneuse en marche (état 200). 20 = environ 10 zombies. 0 = aucune.", "Zustandsverlust pro getötetem Zombie mit laufender Kettensäge (Zustand 200). 20 = etwa 10 Zombies. 0 = keiner.", "Estado perdido por zombi matado con la motosierra en marcha (estado 200). 20 = unos 10 zombis. 0 = ninguno.", "Condizione persa per zombie ucciso con la motosega accesa (condizione 200). 20 = circa 10 zombie. 0 = nessuna.", "Stan tracony za każdego zombie zabitego włączoną piłą (stan 200). 20 = około 10 zombie. 0 = brak.", "Condição perdida por zumbi morto com a motosserra ligada (condição 200). 20 = cerca de 10 zumbis. 0 = nenhuma.", "Потеря состояния за каждого зомби, убитого работающей пилой (состояние 200). 20 = около 10 зомби. 0 = нет."),
        "Sandbox_ChainsawB42_ConditionLossTree": ("Tree cutting wear", "Usure à l'abattage", "Verschleiß beim Fällen", "Desgaste al talar", "Usura nel taglio", "Zużycie przy ścince", "Desgaste ao derrubar", "Износ при валке"),
        "Sandbox_ChainsawB42_ConditionLossTree_tooltip": ("Condition lost, one chance in 8 per cut (2.5 cuts per second). 0 = none.", "État perdu, une chance sur 8 par coupe (2,5 coupes par seconde). 0 = aucune.", "Zustandsverlust, mit einer Chance von 1 zu 8 pro Schnitt (2,5 Schnitte pro Sekunde). 0 = keiner.", "Estado perdido, una probabilidad entre 8 por corte (2,5 cortes por segundo). 0 = ninguno.", "Condizione persa, una probabilità su 8 per taglio (2,5 tagli al secondo). 0 = nessuna.", "Utrata stanu, szansa 1 na 8 przy każdym cięciu (2,5 cięcia na sekundę). 0 = brak.", "Condição perdida, uma chance em 8 por corte (2,5 cortes por segundo). 0 = nenhuma.", "Потеря состояния с шансом 1 из 8 за рез (2,5 реза в секунду). 0 = нет."),
        "Sandbox_ChainsawB42_TreeCuttingSpeed": ("Tree cutting speed", "Vitesse d'abattage", "Fällgeschwindigkeit", "Velocidad de tala", "Velocità di abbattimento", "Szybkość ścinki", "Velocidade de derrubada", "Скорость валки"),
        "Sandbox_ChainsawB42_TreeCuttingSpeed_tooltip": ("In %. 100 = a small tree falls in 1 to 3 seconds, the biggest in about 11 seconds.", "En %. 100 = un petit arbre tombe en 1 à 3 secondes, le plus gros en 11 secondes environ.", "In %. 100 = ein kleiner Baum fällt in 1 bis 3 Sekunden, der größte in etwa 11 Sekunden.", "En %. 100 = un árbol pequeño cae en 1 a 3 segundos, el más grande en unos 11 segundos.", "In %. 100 = un albero piccolo cade in 1-3 secondi, il più grande in circa 11 secondi.", "W %. 100 = małe drzewo pada w 1-3 sekundy, największe w około 11 sekund.", "Em %. 100 = uma árvore pequena cai em 1 a 3 segundos, a maior em cerca de 11 segundos.", "В %. 100 = маленькое дерево падает за 1-3 секунды, самое большое примерно за 11 секунд."),
        "Sandbox_ChainsawB42_EnduranceCost": ("Endurance cost", "Coût en endurance", "Ausdauerkosten", "Coste de resistencia", "Costo in resistenza", "Koszt wytrzymałości", "Custo de resistência", "Расход выносливости"),
        "Sandbox_ChainsawB42_EnduranceCost_tooltip": ("In %, endurance lost by attacking with a running chainsaw. 100 = full cost of a 7 kg weapon swung every 0.67 s, 0 = none.", "En %, endurance perdue en attaquant avec une tronçonneuse en marche. 100 = coût complet d'une arme de 7 kg frappant toutes les 0,67 s, 0 = aucune.", "In %, Ausdauerverlust beim Angreifen mit einer laufenden Kettensäge. 100 = volle Kosten einer 7-kg-Waffe, die alle 0,67 s zuschlägt, 0 = keine.", "En %, resistencia perdida al atacar con una motosierra en marcha. 100 = coste completo de un arma de 7 kg que golpea cada 0,67 s, 0 = ninguna.", "In %, resistenza persa attaccando con una motosega accesa. 100 = costo pieno di un'arma da 7 kg che colpisce ogni 0,67 s, 0 = nessuna.", "W %, wytrzymałość tracona przy atakowaniu włączoną piłą. 100 = pełny koszt broni 7 kg uderzającej co 0,67 s, 0 = brak.", "Em %, resistência perdida ao atacar com uma motosserra ligada. 100 = custo total de uma arma de 7 kg golpeando a cada 0,67 s, 0 = nenhuma.", "В %, расход выносливости при атаке работающей бензопилой. 100 = полный расход оружия весом 7 кг с ударом каждые 0,67 с, 0 = нет."),
        "Sandbox_ChainsawB42_NoiseIdle": ("Noise radius (idle)", "Portée du bruit (ralenti)", "Lärmradius (Leerlauf)", "Radio del ruido (ralentí)", "Raggio del rumore (minimo)", "Zasięg hałasu (jałowy bieg)", "Alcance do ruído (marcha lenta)", "Радиус шума (холостой ход)"),
        "Sandbox_ChainsawB42_NoiseIdle_tooltip": ("Radius in tiles of the noise that attracts zombies every 2 seconds while the engine idles. 0 = silent.", "Rayon en cases du bruit qui attire les zombies toutes les 2 secondes quand le moteur tourne au ralenti. 0 = silencieux.", "Radius in Feldern des Lärms, der alle 2 Sekunden Zombies anlockt, solange der Motor im Leerlauf läuft. 0 = lautlos.", "Radio en casillas del ruido que atrae a los zombis cada 2 segundos mientras el motor está al ralentí. 0 = silencioso.", "Raggio in caselle del rumore che attira gli zombie ogni 2 secondi mentre il motore è al minimo. 0 = silenzioso.", "Promień w polach hałasu przyciągającego zombie co 2 sekundy, gdy silnik pracuje na jałowym biegu. 0 = cisza.", "Raio em quadrados do ruído que atrai zumbis a cada 2 segundos enquanto o motor está em marcha lenta. 0 = silencioso.", "Радиус в клетках шума, привлекающего зомби каждые 2 секунды, пока двигатель работает на холостом ходу. 0 = бесшумно."),
        "Sandbox_ChainsawB42_NoiseWorking": ("Noise radius (attacking, cutting)", "Portée du bruit (attaque, coupe)", "Lärmradius (Angriff, Sägen)", "Radio del ruido (ataque, corte)", "Raggio del rumore (attacco, taglio)", "Zasięg hałasu (atak, cięcie)", "Alcance do ruído (ataque, corte)", "Радиус шума (атака, пиление)"),
        "Sandbox_ChainsawB42_NoiseWorking_tooltip": ("Radius in tiles of the noise that attracts zombies every 2 seconds while attacking or cutting a tree. 0 = idle noise only.", "Rayon en cases du bruit qui attire les zombies toutes les 2 secondes pendant une attaque ou l'abattage d'un arbre. 0 = bruit du ralenti seulement.", "Radius in Feldern des Lärms, der alle 2 Sekunden Zombies anlockt, während man angreift oder einen Baum fällt. 0 = nur Leerlauflärm.", "Radio en casillas del ruido que atrae a los zombis cada 2 segundos al atacar o talar un árbol. 0 = solo el ruido del ralentí.", "Raggio in caselle del rumore che attira gli zombie ogni 2 secondi durante un attacco o il taglio di un albero. 0 = solo il rumore del minimo.", "Promień w polach hałasu przyciągającego zombie co 2 sekundy podczas ataku lub ścinania drzewa. 0 = tylko hałas jałowego biegu.", "Raio em quadrados do ruído que atrai zumbis a cada 2 segundos ao atacar ou derrubar uma árvore. 0 = só o ruído da marcha lenta.", "Радиус в клетках шума, привлекающего зомби каждые 2 секунды во время атаки или рубки дерева. 0 = только шум холостого хода."),
    "Sandbox_ChainsawB42_JamFrequency": ("Starting failures", "Ratés au démarrage", "Startaussetzer", "Fallos de arranque", "Mancate accensioni", "Nieudane rozruchy", "Falhas na partida", "Отказы запуска"),
        "Sandbox_ChainsawB42_JamFrequency_tooltip": ("Chance in % that a chainsaw below half condition fails to start. 0 = never.", "Chance en % qu'une tronçonneuse sous la moitié de son état ne démarre pas. 0 = jamais.", "Chance in %, dass eine Kettensäge unter halbem Zustand nicht anspringt. 0 = nie.", "Probabilidad en % de que una motosierra por debajo de la mitad de su estado no arranque. 0 = nunca.", "Probabilità in % che una motosega sotto metà condizione non parta. 0 = mai.", "Szansa w %, że piła poniżej połowy stanu nie zapali. 0 = nigdy.", "Chance em % de uma motosserra abaixo da metade da condição não ligar. 0 = nunca.", "Шанс в %, что бензопила с состоянием ниже половины не заведётся. 0 = никогда."),
        "Sandbox_ChainsawB42_LootChance": ("Chainsaw loot", "Tronçonneuses trouvables", "Kettensägen als Beute", "Motosierras en el botín", "Motoseghe nel bottino", "Piły w łupach", "Motosserras no saque", "Бензопилы в добыче"),
        "Sandbox_ChainsawB42_LootChance_tooltip": ("3 = default (1 to 3 % per roll in logging sites, ranger stations, fire stations, barns, garages...). 0 = none. Applied when the game starts.", "3 = par défaut (1 à 3 % par tirage dans les scieries, postes de gardes forestiers, casernes, granges, garages...). 0 = aucune. Appliqué au lancement de la partie.", "3 = Standard (1 bis 3 % pro Wurf in Sägewerken, Försterstationen, Feuerwachen, Scheunen, Garagen...). 0 = keine. Wird beim Spielstart angewendet.", "3 = por defecto (1 a 3 % por tirada en aserraderos, puestos de guardabosques, parques de bomberos, graneros, garajes...). 0 = ninguna. Se aplica al iniciar la partida.", "3 = predefinito (dall'1 al 3 % per estrazione in segherie, stazioni forestali, caserme dei pompieri, fienili, garage...). 0 = nessuna. Applicato all'avvio della partita.", "3 = domyślnie (1 do 3 % na losowanie w tartakach, leśniczówkach, remizach, stodołach, garażach...). 0 = brak. Stosowane przy starcie gry.", "3 = padrão (1 a 3 % por sorteio em serrarias, postos de guarda florestal, quartéis de bombeiros, celeiros, garagens...). 0 = nenhuma. Aplicado ao iniciar o jogo.", "3 = по умолчанию (1-3 % за бросок на лесопилках, в лесничествах, пожарных частях, амбарах, гаражах...). 0 = нет. Применяется при запуске игры."),
    },
    "GameSound": {
        "GameSound_ChainsawB42_Idle": ("Chainsaw: engine", "Tronçonneuse : moteur", "Kettensäge: Motor", "Motosierra: motor", "Motosega: motore", "Piła łańcuchowa: silnik", "Motosserra: motor", "Бензопила: двигатель"),
        "GameSound_ChainsawB42_Start": ("Chainsaw: start", "Tronçonneuse : démarrage", "Kettensäge: Start", "Motosierra: arranque", "Motosega: avvio", "Piła łańcuchowa: rozruch", "Motosserra: partida", "Бензопила: запуск"),
        "GameSound_ChainsawB42_Stop": ("Chainsaw: stop", "Tronçonneuse : arrêt", "Kettensäge: Abstellen", "Motosierra: apagado", "Motosega: spegnimento", "Piła łańcuchowa: wyłączenie", "Motosserra: desligar", "Бензопила: остановка"),
        "GameSound_ChainsawB42_Attack": ("Chainsaw: attack", "Tronçonneuse : attaque", "Kettensäge: Angriff", "Motosierra: ataque", "Motosega: attacco", "Piła łańcuchowa: atak", "Motosserra: ataque", "Бензопила: атака"),
        "GameSound_ChainsawB42_WoodCut": ("Chainsaw: cutting wood", "Tronçonneuse : coupe du bois", "Kettensäge: Holz sägen", "Motosierra: cortar madera", "Motosega: taglio del legno", "Piła łańcuchowa: cięcie drewna", "Motosserra: cortando madeira", "Бензопила: пиление дерева"),
        "GameSound_ChainsawB42_ZombieHit": ("Chainsaw: hit", "Tronçonneuse : impact", "Kettensäge: Treffer", "Motosierra: impacto", "Motosega: colpo", "Piła łańcuchowa: trafienie", "Motosserra: impacto", "Бензопила: удар"),
    },
}


# Simplified Chinese (CN) and Portuguese of Portugal (PT, distinct from PTBR):
# key -> (CN, PT)
T2 = {
    # ItemName
    "ChainsawB42.ChainsawOff": ("电锯", "Motosserra"),
    "ChainsawB42.Chainsaw": ("电锯（运转中）", "Motosserra (ligada)"),
    "ChainsawB42.ChainsawMaintenanceMagazine": ("小型发动机维修与保养", "Reparação e manutenção de pequenos motores"),
    # Recipes
    "ForgeChainsaw": ("锻造电锯", "Forjar motosserra"),
    "RepairChainsaw": ("修理电锯", "Reparar motosserra"),
    # ContextMenu
    "ContextMenu_CSB42_Start": ("启动电锯", "Ligar a motosserra"),
    "ContextMenu_CSB42_Stop": ("关闭电锯", "Desligar a motosserra"),
    "ContextMenu_CSB42_Refuel": ("给电锯加油", "Abastecer a motosserra"),
    "ContextMenu_CSB42_CutTree": ("用电锯砍倒这棵树", "Abater a árvore com a motosserra"),
    # Tooltip
    "Tooltip_CSB42_Broken": ("电锯坏了。", "A motosserra está avariada."),
    "Tooltip_CSB42_NoFuel": ("油箱是空的。", "O depósito está vazio."),
    "Tooltip_CSB42_InVehicle": ("不能在车内使用。", "Não dentro de um veículo."),
    "Tooltip_CSB42_NoPetrol": ("物品栏中需要一个装有纯汽油的容器。", "É preciso um recipiente com gasolina pura no inventário."),
    # IG_UI
    "IGUI_CSB42_TooltipProvider": ("电锯：发动机和燃油", "Motosserra: motor e combustível"),
    "IGUI_CSB42_Engine": ("发动机", "Motor"),
    "IGUI_CSB42_Running": ("运转中", "Ligado"),
    "IGUI_CSB42_Stopped": ("已关闭", "Desligado"),
    "IGUI_CSB42_Fuel": ("燃油", "Combustível"),
    "IGUI_CSB42_Jammed": ("*突突* 电锯打不着火……", "*Engasga* A motosserra não pega..."),
    "IGUI_CSB42_OutOfFuel": ("电锯没油了", "A motosserra ficou sem combustível"),
    "IGUI_CSB42_Broken": ("电锯坏了", "A motosserra avariou"),
    "IGUI_CSB42_Repaired": ("电锯已修好", "Motosserra reparada"),
    # Sandbox
    "Sandbox_ChainsawB42": ("电锯 B42", "Motosserra B42"),
    "Sandbox_ChainsawB42_FuelConsumption": ("燃油消耗", "Consumo de combustível"),
    "Sandbox_ChainsawB42_FuelConsumption_tooltip": ("单位为 %。100 = 在 1 倍游戏速度下怠速时，满箱油约可用 16 分钟，锯木时更短。0 = 不消耗。", "Em %. 100 = um depósito cheio dura cerca de 16 minutos ao ralenti à velocidade x1, menos a cortar. 0 = sem consumo."),
    "Sandbox_ChainsawB42_DamageMod": ("伤害", "Dano"),
    "Sandbox_ChainsawB42_DamageMod_tooltip": ("单位为 %，运转中的电锯的伤害。100 = 正常。", "Em %, dano de uma motosserra ligada. 100 = normal."),
    "Sandbox_ChainsawB42_ConditionLossCombat": ("战斗磨损", "Desgaste em combate"),
    "Sandbox_ChainsawB42_ConditionLossCombat_tooltip": ("用运转中的电锯每杀死一只丧尸损失的耐久（耐久 200）。20 = 约 10 只丧尸。0 = 无。", "Condição perdida por cada zombie morto com a motosserra ligada (condição 200). 20 = cerca de 10 zombies. 0 = nenhuma."),
    "Sandbox_ChainsawB42_ConditionLossTree": ("砍树磨损", "Desgaste ao abater"),
    "Sandbox_ChainsawB42_ConditionLossTree_tooltip": ("每次锯切有八分之一的几率损失的耐久（每秒 2.5 次锯切）。0 = 无。", "Condição perdida, com uma probabilidade em 8 por corte (2,5 cortes por segundo). 0 = nenhuma."),
    "Sandbox_ChainsawB42_TreeCuttingSpeed": ("砍树速度", "Velocidade de abate"),
    "Sandbox_ChainsawB42_TreeCuttingSpeed_tooltip": ("单位为 %。100 = 小树 1 到 3 秒倒下，最大的树约 11 秒。", "Em %. 100 = uma árvore pequena cai em 1 a 3 segundos, a maior em cerca de 11 segundos."),
    "Sandbox_ChainsawB42_EnduranceCost": ("耐力消耗", "Custo de resistência"),
    "Sandbox_ChainsawB42_EnduranceCost_tooltip": ("单位为 %，用运转中的电锯攻击时消耗的耐力。100 = 每 0.67 秒挥动一次的 7 公斤武器的全部消耗，0 = 不消耗。", "Em %, resistência perdida ao atacar com uma motosserra ligada. 100 = custo total de uma arma de 7 kg a golpear a cada 0,67 s, 0 = nenhuma."),
    "Sandbox_ChainsawB42_NoiseIdle": ("噪音范围（怠速）", "Alcance do ruído (ralenti)"),
    "Sandbox_ChainsawB42_NoiseIdle_tooltip": ("发动机怠速时每 2 秒发出的吸引丧尸的噪音半径（格）。0 = 静音。", "Raio em quadrículas do ruído que atrai zombies a cada 2 segundos enquanto o motor está ao ralenti. 0 = silencioso."),
    "Sandbox_ChainsawB42_NoiseWorking": ("噪音范围（攻击、伐木）", "Alcance do ruído (ataque, corte)"),
    "Sandbox_ChainsawB42_NoiseWorking_tooltip": ("攻击或伐木时每 2 秒发出的吸引丧尸的噪音半径（格）。0 = 只有怠速噪音。", "Raio em quadrículas do ruído que atrai zombies a cada 2 segundos ao atacar ou abater uma árvore. 0 = só o ruído do ralenti."),
    "Sandbox_ChainsawB42_JamFrequency": ("启动失败", "Falhas no arranque"),
    "Sandbox_ChainsawB42_JamFrequency_tooltip": ("耐久低于一半的电锯启动失败的几率（%）。0 = 从不。", "Probabilidade em % de uma motosserra abaixo de metade da condição não arrancar. 0 = nunca."),
    "Sandbox_ChainsawB42_LootChance": ("电锯掉落", "Motosserras no saque"),
    "Sandbox_ChainsawB42_LootChance_tooltip": ("3 = 默认（在伐木场、护林站、消防站、谷仓、车库等处每次抽取 1 到 3 %）。0 = 无。开始游戏时生效。", "3 = predefinição (1 a 3 % por sorteio em serrações, postos de guardas florestais, quartéis de bombeiros, celeiros, garagens...). 0 = nenhuma. Aplicado ao iniciar o jogo."),
    # GameSound
    "GameSound_ChainsawB42_Idle": ("电锯：发动机", "Motosserra: motor"),
    "GameSound_ChainsawB42_Start": ("电锯：启动", "Motosserra: arranque"),
    "GameSound_ChainsawB42_Stop": ("电锯：关闭", "Motosserra: paragem"),
    "GameSound_ChainsawB42_Attack": ("电锯：攻击", "Motosserra: ataque"),
    "GameSound_ChainsawB42_WoodCut": ("电锯：锯木头", "Motosserra: cortar madeira"),
    "GameSound_ChainsawB42_ZombieHit": ("电锯：击中", "Motosserra: impacto"),
}
LANGS2 = ["CN", "PT"]


def write(lang, filename, data):
    folder = TRANSLATE / lang
    folder.mkdir(parents=True, exist_ok=True)
    data = {key: value.replace("%", "%%") for key, value in data.items()}
    text = json.dumps(data, ensure_ascii=False, indent=4) + "\n"
    (folder / f"{filename}.json").write_text(text, encoding="utf-8", newline="\n")


def main():
    all_keys = {key for entries in T.values() for key in entries}
    if all_keys != set(T2):
        raise SystemExit(f"CN/PT keys differ: missing {sorted(all_keys - set(T2))}, extra {sorted(set(T2) - all_keys)}")
    for index, lang in enumerate(LANGS):
        for filename, entries in T.items():
            write(lang, filename, {key: values[index] for key, values in entries.items()})
    for index, lang in enumerate(LANGS2):
        for filename, entries in T.items():
            write(lang, filename, {key: T2[key][index] for key in entries})
    languages = len(LANGS) + len(LANGS2)
    print(f"{languages} languages x {len(T)} files written to {TRANSLATE}")


if __name__ == "__main__":
    main()
