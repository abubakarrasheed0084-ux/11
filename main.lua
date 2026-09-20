require "import" 
import "android.widget.*" 
import "com.androlua.*" 
import "android.content.Intent"
import "android.net.Uri"
import "android.content.DialogInterface"
import "android.content.Context"
import "android.view.KeyEvent"
import "android.media.MediaPlayer"
import "org.json.JSONObject"
import "org.json.JSONArray"
import "java.io.File"
import "java.io.FileInputStream"
import "java.io.InputStreamReader"
import "java.io.BufferedReader"
import "java.io.FileOutputStream"
import "android.os.Build"
import "android.os.Environment"
import "android.provider.Settings"
import "java.lang.String"
import "java.lang.StringBuilder"

-- Helper function to safely extract text from items
local function getItemText(parent, view, position)
  pcall(function()
    local adapter = parent.getAdapter()
    if adapter then
      local item = adapter.getItem(position)
      if item then return tostring(item) end
    end
  end)
  if view and view.Text then return tostring(view.Text) end
  return ""
end

-- Helper Adapter creator for GridViews/ListViews
local function setSimpleAdapter(view, itemsArray)
  local adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(itemsArray))
  if view then view.Adapter = adapter end
  return adapter
end

-- SharedPreferences for HC Tournament Data
local sp = this.getSharedPreferences("HCTournamentData", Context.MODE_PRIVATE)
local editor = sp.edit()

-- Sound Enabled Setting (Default: true)
local isSoundEnabled = sp.getBoolean("sound_enabled", true)

-- Click sound play function
function playClickSound()
  if not isSoundEnabled then return end
  pcall(function()
    local soundPath = "/storage/emulated/0/解说/Plugins/HCTournament/sound/click.mp3"
    local mp = MediaPlayer()
    mp.setDataSource(soundPath)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener({
      onCompletion = function(mediaPlayer) mediaPlayer.release() end
    })
  end)
end

-- Unsold sound play function
function playUnsoldSound()
  if not isSoundEnabled then return end
  pcall(function()
    local soundPath = "/storage/emulated/0/解说/Plugins/HCTournament/sound/unsold.mp3"
    local mp = MediaPlayer()
    mp.setDataSource(soundPath)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener({
      onCompletion = function(mediaPlayer) mediaPlayer.release() end
    })
  end)
end

-- Sold sound play function
function playSoldSound()
  if not isSoundEnabled then return end
  pcall(function()
    local soundPath = "/storage/emulated/0/解说/Plugins/HCTournament/sound/sold.mp3"
    local mp = MediaPlayer()
    mp.setDataSource(soundPath)
    mp.prepare()
    mp.start()
    mp.setOnCompletionListener({
      onCompletion = function(mediaPlayer) mediaPlayer.release() end
    })
  end)
end

-- Load data from SharedPreferences
function loadData()
  tournaments = {}
  registeredPlayers = {}
  unsoldPlayersData = {}
  teamsData = {}
  soldPlayersData = {}
  teamBudgetsData = {}
  matchesHistory = {}

  local tourJsonStr = sp.getString("tournaments_list", nil)
  local regJsonStr = sp.getString("registered_players", nil)
  local unsoldJsonStr = sp.getString("unsold_players", nil)
  local teamsJsonStr = sp.getString("teams_data", nil)
  local soldJsonStr = sp.getString("sold_players_v2", nil)
  local budgetJsonStr = sp.getString("team_budgets", nil)
  local matchJsonStr = sp.getString("matches_history", nil)
  
  if tourJsonStr ~= nil then
    local tourObj = JSONObject(tourJsonStr)
    local keys = tourObj.keys()
    while keys.hasNext() do
      local key = tostring(keys.next())
      table.insert(tournaments, tourObj.getString(key))
    end
  end

  if regJsonStr ~= nil then
    local obj = JSONObject(regJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      registeredPlayers[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        table.insert(registeredPlayers[k], arr.getString(i))
      end
    end
  end

  if unsoldJsonStr ~= nil then
    local obj = JSONObject(unsoldJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      unsoldPlayersData[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        table.insert(unsoldPlayersData[k], arr.getString(i))
      end
    end
  end

  if teamsJsonStr ~= nil then
    local obj = JSONObject(teamsJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      teamsData[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        table.insert(teamsData[k], arr.getString(i))
      end
    end
  end

  if soldJsonStr ~= nil then
    local obj = JSONObject(soldJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      soldPlayersData[k] = {}
      local arr = obj.getJSONArray(k)
      for i=0, arr.length()-1 do
        local pObj = arr.getJSONObject(i)
        table.insert(soldPlayersData[k], {
          name = pObj.optString("name", ""),
          price = pObj.optString("price", "0"),
          runs = pObj.optString("runs", "0"),
          balls = pObj.optString("balls", "0"),
          innings = pObj.optString("innings", "0"),
          fifties = pObj.optString("fifties", "0"),
          fastestFifty = pObj.optString("fastestFifty", "999"),
          centuries = pObj.optString("centuries", "0"),
          fastestCentury = pObj.optString("fastestCentury", "999"),
          wickets = pObj.optString("wickets", "0"),
          overs = pObj.optString("overs", "0"),
          runsConceded = pObj.optString("runsConceded", "0")
        })
      end
    end
  end

  if budgetJsonStr ~= nil then
    local obj = JSONObject(budgetJsonStr)
    local keys = obj.keys()
    while keys.hasNext() do
      local k = tostring(keys.next())
      local bObj = obj.getJSONObject(k)
      teamBudgetsData[k] = {
        budget = bObj.optString("budget", "0"),
        basePrice = bObj.optString("basePrice", "0"),
        minPlayers = bObj.optString("minPlayers", "0"),
        maxPlayers = bObj.optString("maxPlayers", "0")
      }
    end
  end

  if matchJsonStr ~= nil then
    local arr = JSONArray(matchJsonStr)
    for i=0, arr.length()-1 do
      table.insert(matchesHistory, arr.getString(i))
    end
  end
end

-- Save Data to SharedPreferences
function saveData()
  local tourObj = JSONObject()
  for i, val in ipairs(tournaments) do tourObj.put(tostring(i), val) end
  
  local regObj = JSONObject()
  for k, v in pairs(registeredPlayers) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, name in ipairs(v) do arr.put(name) end
      regObj.put(k, arr)
    end
  end

  local unsoldObj = JSONObject()
  for k, v in pairs(unsoldPlayersData) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, name in ipairs(v) do arr.put(name) end
      unsoldObj.put(k, arr)
    end
  end

  local teamsObj = JSONObject()
  for k, v in pairs(teamsData) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, tname in ipairs(v) do arr.put(tname) end
      teamsObj.put(k, arr)
    end
  end

  local soldObj = JSONObject()
  for k, v in pairs(soldPlayersData) do
    if type(v) == "table" then
      local arr = JSONArray()
      for _, pData in ipairs(v) do
        local pObj = JSONObject()
        pObj.put("name", pData.name)
        pObj.put("price", pData.price or "0")
        pObj.put("runs", pData.runs or "0")
        pObj.put("balls", pData.balls or "0")
        pObj.put("innings", pData.innings or "0")
        pObj.put("fifties", pData.fifties or "0")
        pObj.put("fastestFifty", pData.fastestFifty or "999")
        pObj.put("centuries", pData.centuries or "0")
        pObj.put("fastestCentury", pData.fastestCentury or "999")
        pObj.put("wickets", pData.wickets or "0")
        pObj.put("overs", pData.overs or "0")
        pObj.put("runsConceded", pData.runsConceded or "0")
        arr.put(pObj)
      end
      soldObj.put(k, arr)
    end
  end

  local budgetObj = JSONObject()
  for k, v in pairs(teamBudgetsData) do
    local bObj = JSONObject()
    bObj.put("budget", v.budget or "0")
    bObj.put("basePrice", v.basePrice or "0")
    bObj.put("minPlayers", v.minPlayers or "0")
    bObj.put("maxPlayers", v.maxPlayers or "0")
    budgetObj.put(k, bObj)
  end

  local matchArr = JSONArray()
  for _, mDetails in ipairs(matchesHistory) do
    matchArr.put(mDetails)
  end

  editor.putString("tournaments_list", tourObj.toString())
  editor.putString("registered_players", regObj.toString())
  editor.putString("unsold_players", unsoldObj.toString())
  editor.putString("teams_data", teamsObj.toString())
  editor.putString("sold_players_v2", soldObj.toString())
  editor.putString("team_budgets", budgetObj.toString())
  editor.putString("matches_history", matchArr.toString())
  editor.apply()
end

loadData()

function safeExitApp()
  pcall(function() if dlg then dlg.dismiss() end end)
end

function showExitConfirmationDialog(parentDlg)
  local exitDlg = LuaDialog(this)
  exitDlg.setTitle("Exit Player Management By Abubakar Malik")
  exitDlg.setMessage("Are you sure you want to exit Player Management By Abubakar Malik?")
  
  exitDlg.setButton("Player Management By Abubakar Malik", function(dialog, which)
    playClickSound()
    dialog.dismiss()
    if parentDlg then pcall(function() parentDlg.dismiss() end) end
    safeExitApp()
  end)
  
  exitDlg.setButton2("No", function(dialog, which)
    playClickSound()
    dialog.dismiss()
    pcall(function() if dlg then dlg.show() end end)
  end)
  
  exitDlg.show()
end

-- HC Match Scorekeeper Module
function showMatchScoringDialog(targetTournament)
  local mDlg = LuaDialog(this)
  mDlg.setTitle("HC Match Scoring (" .. targetTournament .. ")")

  local layout = {
    ScrollView, layout_width="fill", layout_height="wrap",
    {
      LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
      { TextView, text="Team 1 Name:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtTeam1", hint="Team A", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      { TextView, text="Team 1 Score / Overs:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtScore1", hint="e.g. 45/2 (5.0 overs)", layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" },
      
      { TextView, text="Team 2 Name:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtTeam2", hint="Team B", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      { TextView, text="Team 2 Score / Overs:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtScore2", hint="e.g. 46/1 (4.2 overs)", layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" },
      
      { TextView, text="Match Result / Summary:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtResult", hint="Team B won by 5 wickets", layout_width="fill", layout_height="wrap" }
    }
  }

  local views = {}
  mDlg.View = loadlayout(layout, views)

  mDlg.setButton("Save Match", function(dialog)
    playClickSound()
    local t1 = views.edtTeam1 and tostring(views.edtTeam1.Text) or "Team 1"
    local s1 = views.edtScore1 and tostring(views.edtScore1.Text) or "0/0"
    local t2 = views.edtTeam2 and tostring(views.edtTeam2.Text) or "Team 2"
    local s2 = views.edtScore2 and tostring(views.edtScore2.Text) or "0/0"
    local res = views.edtResult and tostring(views.edtResult.Text) or "Match Finished"

    local matchSummary = "[" .. targetTournament .. "] " .. t1 .. " (" .. s1 .. ") vs " .. t2 .. " (" .. s2 .. ") -> " .. res
    table.insert(matchesHistory, matchSummary)
    saveData()

    Toast.makeText(this, "Match Saved to HC History!", Toast.LENGTH_SHORT).show()
    mDlg.dismiss()
  end)

  mDlg.setButton2("Go Back", function(dialog) dialog.dismiss() end)
  mDlg.show()
end

-- Tournament & Team Dialogs
function showCreateTournamentDialog(onCreatedCallback)
  local tourneyDlg = LuaDialog(this)
  tourneyDlg.setTitle("Create New HC Tournament")
  
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Tournament Name:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtTournamentName", hint="e.g. HC Super League", layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" },
    { TextView, text="Teams (Comma or New Line Separated):", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtTeamsName", hint="Team A\nTeam B\nTeam C", layout_width="fill", layout_height="wrap", minLines=3 }
  }
  
  local views = {}
  tourneyDlg.View = loadlayout(layout, views)
  
  tourneyDlg.setButton("Save", function(dialog)
    playClickSound()
    local tName = views.edtTournamentName and tostring(views.edtTournamentName.Text) or ""
    local teamsStr = views.edtTeamsName and tostring(views.edtTeamsName.Text) or ""
    
    if tName == "" then
      Toast.makeText(this, "Please enter tournament name!", Toast.LENGTH_SHORT).show()
    else
      table.insert(tournaments, tName)
      teamsData[tName] = {}
      for team in string.gmatch(teamsStr, "[^,\r\n]+") do
        local trimmed = string.gsub(team, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(teamsData[tName], trimmed) end
      end
      saveData()
      Toast.makeText(this, "Tournament '" .. tName .. "' Created!", Toast.LENGTH_LONG).show()
      tourneyDlg.dismiss()
      if onCreatedCallback then onCreatedCallback() end
    end
  end)
  
  tourneyDlg.setButton2("Go back", function(dialog) dialog.dismiss() end)
  tourneyDlg.show()
end

function showSettingsDialog()
  local setDlg = LuaDialog(this)
  setDlg.setTitle("HC Settings")
  local settingsLayout = {
    LinearLayout, orientation="horizontal", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Enable Audio Effects:", textSize="16sp", textColor=0xFF000000, layout_weight=1 },
    { Switch, id="swSound", checked=isSoundEnabled }
  }
  local views = {}
  setDlg.View = loadlayout(settingsLayout, views)
  
  if views.swSound then
    views.swSound.setOnCheckedChangeListener({
      onCheckedChanged = function(buttonView, isChecked)
        isSoundEnabled = isChecked
        editor.putBoolean("sound_enabled", isChecked)
        editor.apply()
        if isChecked then playClickSound() end
      end
    })
  end
  setDlg.setButton("Go back", function(dialog) dialog.dismiss() end)
  setDlg.show()
end

function showAboutMenu()
  local abItems = { "WhatsApp Community", "Contact Developer" }
  local abDlg = LuaDialog(this)
  abDlg.setTitle("Player Management By Abubakar Malik")
  local abLayout = { GridView, id="abGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  abDlg.View = loadlayout(abLayout, views)
  setSimpleAdapter(views.abGrid, abItems)

  views.abGrid.onItemClick = function(parent, view, position, id)
    playClickSound()
    local selectedText = getItemText(parent, view, position)
    if selectedText == "WhatsApp Community" then
      pcall(function()
        local intent = Intent(Intent.ACTION_VIEW)
        intent.setData(Uri.parse("https://chat.whatsapp.com/Jbrhiu4U49L3j4qCSsL6i1?s=cl&p=a&mlu=4&ilr=4"))
        this.startActivity(intent)
      end)
    elseif selectedText == "Contact Developer" then
      pcall(function()
        local intent = Intent(Intent.ACTION_SENDTO)
        intent.setData(Uri.parse("mailto:abubakarrasheed0084@gmail.com"))
        this.startActivity(intent)
      end)
    end
  end
  abDlg.setButton("Go back", function(dialog) dialog.dismiss() end)
  abDlg.show()
end

function showCreateListDialog(targetTournament)
  local createDlg = LuaDialog(this)
  createDlg.setTitle("Create Player List (" .. targetTournament .. ")")
  
  local inputLayout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Player Names (Comma or New Line separated):", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtPlayerNames", hint="Player 1, Player 2...", layout_width="fill", layout_height="wrap", minLines=3 }
  }
  local views = {}
  createDlg.View = loadlayout(inputLayout, views)

  createDlg.setButton("Save", function(dialog)
    playClickSound()
    local enteredNames = views.edtPlayerNames and tostring(views.edtPlayerNames.Text) or ""
    if enteredNames ~= "" then
      if not registeredPlayers[targetTournament] then registeredPlayers[targetTournament] = {} end
      for name in string.gmatch(enteredNames, "[^,\r\n]+") do
        local trimmed = string.gsub(name, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(registeredPlayers[targetTournament], trimmed) end
      end
      saveData()
      Toast.makeText(this, "Player List Saved!", Toast.LENGTH_SHORT).show()
      createDlg.dismiss()
    end
  end)
  createDlg.setButton2("Go back", function(dialog) dialog.dismiss() end)
  createDlg.show()
end

function showSetTeamBudgetsDialog(targetTournament)
  local budgetDlg = LuaDialog(this)
  budgetDlg.setTitle("Set Team Budgets (" .. targetTournament .. ")")
  local currentBudget = teamBudgetsData[targetTournament] or {}

  local layout = {
    ScrollView, layout_width="fill", layout_height="wrap",
    {
      LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
      { TextView, text="Team Budget (Coins):", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtTeamBudget", text=currentBudget.budget or "", hint="Budget Coins", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      { TextView, text="Base Price:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtBasePrice", text=currentBudget.basePrice or "", hint="Base Price", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      { TextView, text="Minimum Players:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtMinPlayers", text=currentBudget.minPlayers or "", hint="Min Players", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
      { TextView, text="Maximum Players:", textSize="14sp", textColor=0xFF000000 },
      { EditText, id="edtMaxPlayers", text=currentBudget.maxPlayers or "", hint="Max Players", inputType="number", layout_width="fill", layout_height="wrap" }
    }
  }

  local views = {}
  budgetDlg.View = loadlayout(layout, views)

  budgetDlg.setButton("Player Management By Abubakar Malik", function(dialog)
    playClickSound()
    teamBudgetsData[targetTournament] = {
      budget = views.edtTeamBudget and tostring(views.edtTeamBudget.Text) or "0",
      basePrice = views.edtBasePrice and tostring(views.edtBasePrice.Text) or "0",
      minPlayers = views.edtMinPlayers and tostring(views.edtMinPlayers.Text) or "0",
      maxPlayers = views.edtMaxPlayers and tostring(views.edtMaxPlayers.Text) or "0"
    }
    saveData()
    Toast.makeText(this, "Budgets Saved Successfully!", Toast.LENGTH_SHORT).show()
    budgetDlg.dismiss()
  end)
  budgetDlg.setButton2("Go back", function(dialog) dialog.dismiss() end)
  budgetDlg.show()
end

function showPlayerDraftingDialog(targetTournament)
  local draftDlg = LuaDialog(this)
  draftDlg.setTitle("Player Drafting (" .. targetTournament .. ")")

  local draftLayout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Select Player:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnPlayer", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    { TextView, text="Sale Price:", textSize="14sp", textColor=0xFF000000 },
    { EditText, id="edtSalePrice", hint="Amount", inputType="number", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    { TextView, text="Choose Team:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnTeam", layout_width="fill", layout_height="wrap", layout_marginBottom="8dp" },
    { TextView, text="Status:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnStatus", layout_width="fill", layout_height="wrap", layout_marginBottom="12dp" }
  }

  local views = {}
  draftDlg.View = loadlayout(draftLayout, views)

  local statusList = {"Unsold", "Sold"}
  local statusAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(statusList))
  statusAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
  if views.spnStatus then views.spnStatus.Adapter = statusAdapter end

  local currentPlayers = {}
  local playerSources = {}

  local function buildCombinedPlayerList()
    currentPlayers = {}
    playerSources = {}

    local tourneyP = registeredPlayers[targetTournament] or {}
    for _, name in ipairs(tourneyP) do
      table.insert(currentPlayers, name)
      table.insert(playerSources, { key = targetTournament, name = name })
    end

    local globalP = registeredPlayers["Global_Imported_Players"] or {}
    for _, name in ipairs(globalP) do
      table.insert(currentPlayers, name)
      table.insert(playerSources, { key = "Global_Imported_Players", name = name })
    end
  end

  local currentTeams = teamsData[targetTournament] or {}

  local function refreshPlayerSpinner()
    buildCombinedPlayerList()
    local pList = {"No Players"}
    if #currentPlayers > 0 then pList = currentPlayers end
    local pAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(pList))
    pAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    if views.spnPlayer then views.spnPlayer.Adapter = pAdapter end
  end

  local function refreshTeamSpinner()
    currentTeams = teamsData[targetTournament] or {}
    local tmList = {"No Teams"}
    if #currentTeams > 0 then tmList = currentTeams end
    local tmAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(tmList))
    tmAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
    if views.spnTeam then views.spnTeam.Adapter = tmAdapter end
  end

  refreshPlayerSpinner()
  refreshTeamSpinner()

  draftDlg.setButton("Player Management By Abubakar Malik", function(dialog)
    if not views.spnStatus or not views.spnPlayer or not views.spnTeam then return end
    local statusPos = views.spnStatus.getSelectedItemPosition() + 1
    local status = statusList[statusPos] or "Unsold"
    local price = views.edtSalePrice and tostring(views.edtSalePrice.Text) or "0"

    if #currentPlayers == 0 then
      playClickSound()
      Toast.makeText(this, "No players available!", Toast.LENGTH_SHORT).show()
      return
    end

    local selectedPlayerIndex = views.spnPlayer.getSelectedItemPosition() + 1
    local pSourceInfo = playerSources[selectedPlayerIndex]
    local playerName = currentPlayers[selectedPlayerIndex]

    if status == "Sold" then
      playSoldSound()
      if #currentTeams == 0 or currentTeams[1] == "No Teams" then
        Toast.makeText(this, "No teams available!", Toast.LENGTH_SHORT).show()
        return
      end
      local selectedTeam = currentTeams[views.spnTeam.getSelectedItemPosition() + 1]
      local recordKey = targetTournament .. "_" .. selectedTeam
      
      if not soldPlayersData[recordKey] then soldPlayersData[recordKey] = {} end
      table.insert(soldPlayersData[recordKey], { name = playerName, price = (price ~= "" and price or "0"), runs = "0", balls = "0", innings = "0" })
      
      if pSourceInfo then
        local srcTable = registeredPlayers[pSourceInfo.key]
        if srcTable then
          for idx, n in ipairs(srcTable) do
            if n == playerName then table.remove(srcTable, idx) break end
          end
        end
      end
      saveData()
      Toast.makeText(this, playerName .. " SOLD to " .. selectedTeam, Toast.LENGTH_LONG).show()
      refreshPlayerSpinner()
      if views.edtSalePrice then views.edtSalePrice.Text = "" end
    else
      playUnsoldSound()
      if not unsoldPlayersData[targetTournament] then unsoldPlayersData[targetTournament] = {} end
      table.insert(unsoldPlayersData[targetTournament], playerName)
      if pSourceInfo then
        local srcTable = registeredPlayers[pSourceInfo.key]
        if srcTable then
          for idx, n in ipairs(srcTable) do
            if n == playerName then table.remove(srcTable, idx) break end
          end
        end
      end
      saveData()
      Toast.makeText(this, playerName .. " marked UNSOLD", Toast.LENGTH_SHORT).show()
      refreshPlayerSpinner()
      if views.edtSalePrice then views.edtSalePrice.Text = "" end
    end
  end)

  draftDlg.setButton2("Go back", function(dialog) dialog.dismiss() end)
  draftDlg.show()
end

function showUnsoldPlayerListDialog(targetTournament)
  local unsoldDlg = LuaDialog(this)
  unsoldDlg.setTitle("Unsold Player List (" .. targetTournament .. ")")
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Unsold Players:", textSize="14sp", textColor=0xFF000000 },
    { Spinner, id="spnUnsoldPlayers", layout_width="fill", layout_height="wrap" }
  }
  local views = {}
  unsoldDlg.View = loadlayout(layout, views)

  local uList = unsoldPlayersData[targetTournament] or {}
  local showList = (#uList == 0) and {"No Unsold Players"} or uList

  local pAdapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, String(showList))
  pAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
  if views.spnUnsoldPlayers then views.spnUnsoldPlayers.Adapter = pAdapter end

  unsoldDlg.setButton("Redraft Player", function(dialog)
    playClickSound()
    if #uList == 0 then return end
    local selIndex = (views.spnUnsoldPlayers and views.spnUnsoldPlayers.getSelectedItemPosition() or 0) + 1
    local selectedPlayer = uList[selIndex]
    if selectedPlayer then
      table.remove(unsoldPlayersData[targetTournament], selIndex)
      if not registeredPlayers[targetTournament] then registeredPlayers[targetTournament] = {} end
      table.insert(registeredPlayers[targetTournament], selectedPlayer)
      saveData()
      Toast.makeText(this, selectedPlayer .. " returned to Drafting!", Toast.LENGTH_SHORT).show()
      unsoldDlg.dismiss()
      showPlayerDraftingDialog(targetTournament)
    end
  end)

  unsoldDlg.setButton2("Go back", function(dialog) dialog.dismiss() end)
  unsoldDlg.show()
end

function showTeamDetailDialog(targetTournament, selTeam)
  local detailDlg = LuaDialog(this)
  detailDlg.setTitle(selTeam .. " - Team Roster")

  local recordKey = targetTournament .. "_" .. selTeam
  local pList = soldPlayersData[recordKey] or {}
  local bData = teamBudgetsData[targetTournament] or { budget="0", maxPlayers="0" }

  local function refreshTeamDetails()
    pList = soldPlayersData[recordKey] or {}
    local totalBudget = tonumber(bData.budget) or 0
    local maxPlayers = tonumber(bData.maxPlayers) or 0
    local pickedCount = #pList

    local usedCoins = 0
    local playerNamesList = {}
    for _, p in ipairs(pList) do
      local pPrice = tonumber(p.price) or 0
      usedCoins = usedCoins + pPrice
      table.insert(playerNamesList, p.name .. " - " .. (p.runs or "0") .. " runs (" .. pPrice .. " Coins)")
    end

    local statsText = "Squad Size: " .. pickedCount .. "/" .. maxPlayers .. "\nTotal Coins: " .. totalBudget .. " | Used: " .. usedCoins .. " | Left: " .. (totalBudget - usedCoins)
    return statsText, playerNamesList
  end

  local statsStr, pDisplayList = refreshTeamDetails()
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, id="txtStats", text=statsStr, textSize="14sp", textColor=0xFF000000, layout_marginBottom="12dp" },
    { TextView, text="Squad Players:", textSize="14sp", textColor=0xFF000000, layout_marginBottom="4dp" },
    { ListView, id="lstSoldP", layout_width="fill", layout_height="200dp" }
  }

  local views = {}
  detailDlg.View = loadlayout(layout, views)
  if views.lstSoldP then views.lstSoldP.Adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(pDisplayList)) end

  detailDlg.setButton("Go back", function(dialog) dialog.dismiss() end)
  detailDlg.show()
end

function showViewTeamsDialog(targetTournament)
  local viewDlg = LuaDialog(this)
  viewDlg.setTitle("Teams (" .. targetTournament .. ")")
  local layout = {
    LinearLayout, orientation="vertical", layout_width="fill", layout_height="wrap", padding="16dp",
    { TextView, text="Participating Teams:", textSize="14sp", textColor=0xFF000000 },
    { ListView, id="lstTeams", layout_width="fill", layout_height="250dp" }
  }

  local views = {}
  viewDlg.View = loadlayout(layout, views)
  local currentTeamsList = teamsData[targetTournament] or {}
  if views.lstTeams then views.lstTeams.Adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, String(currentTeamsList)) end

  if views.lstTeams then
    views.lstTeams.onItemClick = function(parent, view, position, id)
      playClickSound()
      local selTeam = currentTeamsList[position + 1]
      if selTeam then showTeamDetailDialog(targetTournament, selTeam) end
    end
  end

  viewDlg.setButton("Go back", function(dialog) dialog.dismiss() end)
  viewDlg.show()
end

function showSingleTournamentMenu(tName)
  local subItems = { "Create Player List", "Set Team Budgets", "Player Drafting", "Unsold Player List", "View Teams", "Record Match Score" }
  local subDlg = LuaDialog(this)
  subDlg.setTitle("HC Dashboard: " .. tName)
  local subLayout = { GridView, id="subGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  subDlg.View = loadlayout(subLayout, views)
  setSimpleAdapter(views.subGrid, subItems)

  if views.subGrid then
    views.subGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local selectedText = getItemText(parent, view, position)
      if selectedText == "Create Player List" then showCreateListDialog(tName)
      elseif selectedText == "Set Team Budgets" then showSetTeamBudgetsDialog(tName)
      elseif selectedText == "Player Drafting" then showPlayerDraftingDialog(tName)
      elseif selectedText == "Unsold Player List" then showUnsoldPlayerListDialog(tName)
      elseif selectedText == "View Teams" then showViewTeamsDialog(tName)
      elseif selectedText == "Record Match Score" then showMatchScoringDialog(tName)
      end
    end
  end

  subDlg.setButton("Go back", function(dialog) dialog.dismiss() end)
  subDlg.show()
end

function showTournamentManagementMenu()
  local pDlg = LuaDialog(this)
  pDlg.setTitle("Player Management By Abubakar Malik")
  
  local function buildMenuList()
    local list = {"+ Create New HC Tournament"}
    for _, tName in ipairs(tournaments) do table.insert(list, tName) end
    return list
  end
  
  local currentList = buildMenuList()
  local pLayout = { GridView, id="pGrid", numColumns=1, layout_width="fill", layout_height="wrap" }
  local views = {}
  pDlg.View = loadlayout(pLayout, views)
  setSimpleAdapter(views.pGrid, currentList)

  local function refreshMenu()
    currentList = buildMenuList()
    setSimpleAdapter(views.pGrid, currentList)
  end

  if views.pGrid then
    views.pGrid.onItemClick = function(parent, view, position, id)
      playClickSound()
      local selectedText = getItemText(parent, view, position)
      if selectedText == "+ Create New HC Tournament" then 
        showCreateTournamentDialog(function() refreshMenu() end)
      else
        showSingleTournamentMenu(selectedText)
      end
    end
  end

  pDlg.setButton("Go back", function(dialog) dialog.dismiss() end)
  pDlg.show()
end

-- HC Main Dashboard Entry
items = {
  "Tournament Management",
  "Settings",
  "About"
}

layout = { GridView, id="grid", numColumns=1, layout_width="fill", layout_height="fill" }

local mainViews = {}
dlg = LuaDialog(this)
dlg.View = loadlayout(layout, mainViews)
setSimpleAdapter(mainViews.grid, items)
dlg.setTitle("Player Management By Abubakar Malik")
dlg.setMessage("Welcome to Player Management By Abubakar Malik")

dlg.setButton2("Exit", function(dialog)
  playClickSound()
  showExitConfirmationDialog(dlg)
end)

dlg.show()

if mainViews.grid then
  mainViews.grid.onItemClick = function(parent, view, position, id)
    playClickSound()
    local btnText = getItemText(parent, view, position)
    if btnText == "Tournament Management" then showTournamentManagementMenu()
    elseif btnText == "Settings" then showSettingsDialog()
    elseif btnText == "About" then showAboutMenu()
    end
  end
end


require "import"
import "com.androlua.Http"
import "com.androlua.LuaDialog"
import "android.widget.Toast"
import "android.os.Handler"
import "android.os.Looper"
import "java.lang.Thread"
import "java.lang.Runnable"
import "java.lang.System"
import "java.io.File"
import "android.content.Context"
import "android.media.ToneGenerator"
import "android.media.AudioManager"
import "android.os.Vibrator"
import "android.os.Build"
import "android.os.VibrationEffect"

local CURRENT_VERSION = "1.2"
local VERSION_URL = "https://raw.githubusercontent.com/abubakarrasheed0084-ux/11/main/Virgin.txt"
local UPDATE_CODE_URL = "https://raw.githubusercontent.com/abubakarrasheed0084-ux/11/main/main.lua"
local PLUGIN_PATH = (function()
    local src = debug.getinfo(1, "S").source
    return src and src:match("^@?(.*)$") or ""
end)()
local updateInProgress = false

local prefs = (service or activity).getSharedPreferences("AutoUpdatePrefs", Context.MODE_PRIVATE)

local function playNotification()
    pcall(function()
        local tone = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
        tone.startTone(ToneGenerator.TONE_PROP_ACK, 100)
        local vibrator = (service or activity).getSystemService(Context.VIBRATOR_SERVICE)
        if vibrator then
            if Build.VERSION.SDK_INT >= 26 then
                vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
            else
                vibrator.vibrate(200)
            end
        end
    end)
end

local function trim(s)
    if s == nil then return "" end
    return tostring(s):gsub("^%s*(.-)%s*$", "%1")
end

local function showUpdateErrorDialog(title, message)
    Handler(Looper.getMainLooper()).post(Runnable({
        run = function()
            local errorDialog = LuaDialog(service or activity)
            errorDialog.setTitle(title)
            errorDialog.setMessage(message)
            errorDialog.setButton("Player Management By Abubakar Malik", function()
                errorDialog.dismiss()
            end)
            errorDialog.show()
        end
    }))
end

local function checkAndShowNewFeatures()
    local lastShown = prefs.getString("lastShownVersion", "")
    if lastShown ~= CURRENT_VERSION then
        Handler(Looper.getMainLooper()).post(Runnable{
            run=function()
                playNotification()
                local featuresDialog = LuaDialog(service or activity)
                featuresDialog.setTitle("New Update Details")
                featuresDialog.setMessage("For testing.")
                featuresDialog.setButton("Player Management By Abubakar Malik", function() 
                    featuresDialog.dismiss() 
                end)
                featuresDialog.show()
                prefs.edit().putString("lastShownVersion", CURRENT_VERSION).apply()
            end
        })
    end
end

local function performUpdate(mainCode, onlineVersion)
    if not mainCode or trim(mainCode) == "" then
        showUpdateErrorDialog("Update Failed", "Main plugin code is empty.")
        return
    end
    
    updateInProgress = true
    
    local function updateProcess()
        local currentFileSrc = debug.getinfo(1, "S").source
        local currentFilePath = currentFileSrc and currentFileSrc:match("^@?(.*)$") or ""
        
        if currentFilePath ~= "" and currentFilePath ~= PLUGIN_PATH then
            pcall(function()
                os.rename(currentFilePath, PLUGIN_PATH)
            end)
        end
        
        local success = false
        local tempPath = PLUGIN_PATH .. ".temp_update"
        local f = io.open(tempPath, "w")
        if f then
            f:write(mainCode)
            f:close()
            
            local fileExists = io.open(PLUGIN_PATH, "r")
            if fileExists then
                fileExists:close()
                local delSuccess = pcall(function()
                    os.remove(PLUGIN_PATH)
                end)
                if delSuccess then
                    local renameSuccess = pcall(function()
                        os.rename(tempPath, PLUGIN_PATH)
                    end)
                    if renameSuccess then
                        success = true
                    end
                end
            else
                local renameSuccess = pcall(function()
                    os.rename(tempPath, PLUGIN_PATH)
                end)
                if renameSuccess then
                    success = true
                end
            end
            
            if not success then
                pcall(function() os.remove(tempPath) end)
            end
        end
        
        if success then
            updateInProgress = false
            Handler(Looper.getMainLooper()).post(Runnable({
                run = function()
                    playNotification()
                    local successDialog = LuaDialog(service or activity)
                    successDialog.setTitle("Update Successful")
                    successDialog.setMessage("Successfully updated to the latest version.\n\nClick Player Management By Abubakar Malik to restart and apply the update.")
                    successDialog.setButton("Player Management By Abubakar Malik", function()
                        successDialog.dismiss()
                        
                        Handler(Looper.getMainLooper()).post(Runnable({
                            run = function()
                                pcall(function() if _G.mainDialog then _G.mainDialog.dismiss() _G.mainDialog = nil end end)
                                pcall(function() if _G.mainDlg then _G.mainDlg.dismiss() _G.mainDlg = nil end end)
                                pcall(function() if _G.allDialogBox then _G.allDialogBox.dismiss() _G.allDialogBox = nil end end)
                                pcall(function() if _G.alertDialogBox then _G.alertDialogBox.dismiss() _G.alertDialogBox = nil end end)
                                
                                pcall(function() if _G.dismissAllDialogs then _G.dismissAllDialogs() end end)
                                pcall(function() if _G.dismissAll then _G.dismissAll() end end)
                                pcall(function() if _G.dismiss then _G.dismiss() end end)
                                pcall(function() if dismissAllDialogs then dismissAllDialogs() end end)
                                pcall(function() if dismissAll then dismissAll() end end)

                                pcall(function()
                                    if activity then
                                        activity.finish()
                                    end
                                end)
                            end
                        }))
                        
                        Handler(Looper.getMainLooper()).postDelayed(Runnable({
                            run = function()
                                prefs.edit().putString("lastShownVersion", "").apply()
                                local pluginFile = io.open(PLUGIN_PATH, "r")
                                if pluginFile then
                                    pluginFile:close()
                                    local func, err = loadfile(PLUGIN_PATH)
                                    if func then
                                        pcall(func)
                                    else
                                        Toast.makeText(service or activity, "Error reloading plugin: " .. tostring(err), Toast.LENGTH_SHORT).show()
                                    end
                                end
                            end
                        }), 2000)
                    end)
                    successDialog.show()
                end
            }))
            return
        else
            updateInProgress = false
            showUpdateErrorDialog("Update Failed", "Update failed. Please try again.")
        end
    end
    
    local updateThread = Thread(Runnable{
        run = updateProcess
    })
    updateThread.start()
end

local function checkUpdate()
    if updateInProgress then
        return
    end
    
    local timestamp = tostring(System.currentTimeMillis())
    Http.get(VERSION_URL .. "?t=" .. timestamp, function(code, response)
        if code == 200 and response then
            local onlineVersion = trim(response)
            if onlineVersion ~= CURRENT_VERSION then
                Http.get(UPDATE_CODE_URL .. "?t=" .. timestamp, function(code2, mainCode)
                    if code2 == 200 and mainCode and trim(mainCode) ~= "" then
                        Handler(Looper.getMainLooper()).post(Runnable({
                            run = function()
                                playNotification()
                                local updateAlertDlg = LuaDialog(service or activity)
                                updateAlertDlg.setTitle("Update Available!")
                                updateAlertDlg.setMessage("A new version (" .. onlineVersion .. ") is available.\nCurrent version: " .. CURRENT_VERSION .. "\n\nWould you like to update now?")
                                updateAlertDlg.setButton("Update Now", function()
                                    updateAlertDlg.dismiss()
                                    Toast.makeText(service or activity, "Downloading update...", Toast.LENGTH_SHORT).show()
                                    performUpdate(mainCode, onlineVersion)
                                end)
                                updateAlertDlg.setButton2("Later", function()
                                    updateAlertDlg.dismiss()
                                end)
                                updateAlertDlg.show()
                            end
                        }))
                    end
                end)
            else
                checkAndShowNewFeatures()
            end
        else
            checkAndShowNewFeatures()
        end
    end)
end

Handler(Looper.getMainLooper()).postDelayed(Runnable({
    run = function()
        checkUpdate()
    end
}), 3000)
