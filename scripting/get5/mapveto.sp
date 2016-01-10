/**
 * Map vetoing functions
 */
public void CreateMapVeto() {
    g_VetoCaptains[MatchTeam_Team1] = GetTeamCaptain(MatchTeam_Team1);
    g_VetoCaptains[MatchTeam_Team2] = GetTeamCaptain(MatchTeam_Team2);
    g_TeamReady[MatchTeam_Team1] = false;
    g_TeamReady[MatchTeam_Team2] = false;
    MatchTeam startingTeam = OtherMatchTeam(g_LastVetoTeam);
    MapVetoController(g_VetoCaptains[startingTeam]);
}

public void VetoFinished() {
    ChangeState(GameState_Warmup);
    Get5_MessageToAll("The maps have been decided:");
    for (int i = 0; i < g_MapsToPlay.Length; i++) {
        char map[PLATFORM_MAX_PATH];
        g_MapsToPlay.GetString(i, map, sizeof(map));
        Get5_MessageToAll("Map %d: {GREEN}%s", i + 1, map);
    }

    g_MapChangePending = true;
    CreateTimer(10.0, Timer_NextMatchMap);
}

public void MapVetoController(int client) {
    if (!IsPlayer(client) || GetClientMatchTeam(client) == MatchTeam_TeamSpec) {
        AbortVeto();
    }

    int mapsLeft = GetNumMapsLeft();
    int maxMaps = MaxMapsToPlay(g_MapsToWin);

    // This is a dirty hack to get ban/ban/pick/pick/ban/ban
    // instead of straight vetoing until the maplist is the length
    // of the series.
    // This only applies to a standard Bo3 in the 7-map pool.
    // TODO: It should be written more generically.
    bool bo3_hack = false;
    if (maxMaps == 3 && (mapsLeft == 4 || mapsLeft == 5) && g_MapList.Length == 7) {
        bo3_hack = true;
    }

    if (mapsLeft == 1) {
        // Only 1 map left in the pool, add it directly to the active maplist.
        char mapName[PLATFORM_MAX_PATH];
        g_MapsLeftInVetoPool.GetString(0, mapName, sizeof(mapName));
        g_MapsToPlay.PushString(mapName);
        VetoFinished();
    } else if (mapsLeft + g_MapsToPlay.Length <= maxMaps || bo3_hack) {
        GiveMapPickMenu(client);
    } else {
        GiveVetoMenu(client);
    }
}

public void GiveMapPickMenu(int client) {
    Menu menu = new Menu(MapPickHandler);
    menu.ExitButton = false;
    menu.SetTitle("Select a map to PLAY:");
    char mapName[PLATFORM_MAX_PATH];
    for (int i = 0; i < g_MapsLeftInVetoPool.Length; i++) {
        g_MapsLeftInVetoPool.GetString(i, mapName, sizeof(mapName));
        menu.AddItem(mapName, mapName);
    }
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MapPickHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        MatchTeam team = GetClientMatchTeam(client);
        char mapName[PLATFORM_MAX_PATH];
        menu.GetItem(param2, mapName, sizeof(mapName));

        g_WhoPickedEachMap[g_MapsToPlay.Length] = team;
        g_MapsToPlay.PushString(mapName);
        RemoveStringFromArray(g_MapsLeftInVetoPool, mapName);

        Get5_MessageToAll("%s picked {GREEN}%s {NORMAL}as map %d",
            g_FormattedTeamNames[team], mapName, g_MapsToPlay.Length);

        MapVetoController(GetNextTeamCaptain(client));
        g_LastVetoTeam = team;
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

public void GiveVetoMenu(int client) {
    Menu menu = new Menu(VetoHandler);
    menu.ExitButton = false;
    menu.SetTitle("Select a map to VETO:");
    char mapName[PLATFORM_MAX_PATH];
    for (int i = 0; i < g_MapsLeftInVetoPool.Length; i++) {
        g_MapsLeftInVetoPool.GetString(i, mapName, sizeof(mapName));
        menu.AddItem(mapName, mapName);
    }
    menu.Display(client, MENU_TIME_FOREVER);
}

public int VetoHandler(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char mapName[PLATFORM_MAX_PATH];
        menu.GetItem(param2, mapName, sizeof(mapName));
        RemoveStringFromArray(g_MapsLeftInVetoPool, mapName);

        MatchTeam team = GetClientMatchTeam(client);
        Get5_MessageToAll("%s vetoed {LIGHT_RED}%s", g_FormattedTeamNames[team], mapName);

        MapVetoController(GetNextTeamCaptain(client));
        g_LastVetoTeam = team;
    } else if (action == MenuAction_End) {
        delete menu;
    }
}

static void AbortVeto() {
    Get5_MessageToAll("A captain left during the veto, pausing the veto.");
    Get5_MessageToAll("Type {GREEN}!ready {NORMAL}when you are ready to resume the veto.");
    ChangeState(GameState_PreVeto);
}

static int GetNumMapsLeft() {
    return g_MapsLeftInVetoPool.Length;
}