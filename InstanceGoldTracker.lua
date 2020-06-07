--- SAVED VARIABLES ---
    table_Dungeon_Name = {}
    table_Dungeon_Difficulty = {}
    table_Time = {}
    table_Looted_Item_Value_Total = {}
    table_Looted_Money_Total = {}
    table_Money_Total = {}
    table_Character_Name = {}
    table_Character_Class = {}
    table_Item_Level = {}
    table_Date = {}
    StopwatchActive = ""
    DB = {}

--- VARIABLES ---
    local select, tostring, time, unpack, tonumber, floor, pairs, tinsert, smatch, math, gsub = select, tostring, time, unpack, tonumber, floor, pairs, table.insert, string.match, math, gsub
    local timer_Status = 0
    local PATTERN_LOOT_ITEM_SELF = LOOT_ITEM_SELF:gsub("%%s", "(.+)")
    local PATTERN_LOOT_ITEM_SELF_MULTIPLE = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    looted_money_total = 0
    sell_value_total = 0			
    MyAddon = LibStub("AceAddon-3.0"):NewAddon("Instance Gold Tracker", "AceConsole-3.0")
    MyConsole = LibStub("AceConsole-3.0")

--- MINIMAP BUTTON ---
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("Instance Gold Tracker", {
    type = "data source",
    text = "Instance Gold Tracker",
    icon = "Interface\\Icons\\inv_misc_thegoldencheep",
    OnTooltipShow = function(tooltip)
        tooltip:SetText("Instance Gold Tracker")
        tooltip:AddLine("/igticon to toggle minimap icon.", 1, 1, 1)
        tooltip:AddLine("/igt to open window.", 1, 1, 1)
        tooltip:Show()
    end,
    OnClick = function() 
        igtframe:SetShown(not igtframe:IsShown())
        setTableData()
    end,
    })

    local icon = LibStub("LibDBIcon-1.0")
    function MyAddon:OnInitialize()
        self.db = LibStub("AceDB-3.0"):New("DB", { profile = { minimap = { hide = false, }, }, }) 
        icon:Register("Instance Gold Tracker", LDB, self.db.profile.minimap) 

    end
    function MyAddon:CommandTheBunnies() 
        self.db.profile.minimap.hide = not self.db.profile.minimap.hide 
        if self.db.profile.minimap.hide then 
            icon:Hide("Instance Gold Tracker") 
        else 
            icon:Show("Instance Gold Tracker") 
        end 
    end

--- ONENABLE ---
    function MyAddon:OnEnable()
    if StopwatchActive == "" then
        StopwatchActive = "ON"
    end

--- CREATE MAIN FRAME ---
    igtframe = CreateFrame("Frame", "InstanceGoldTracker", UIParent, "SimplePanelTemplate")
    igtframe:SetPoint("CENTER")
    igtframe:SetSize(892, 640)
    igtframe:SetFrameStrata("DIALOG")
    tinsert(UISpecialFrames, "InstanceGoldTracker")

--- MAKE FRAME MOVEABLE ---
    igtframe:SetMovable(true)
    igtframe:EnableMouse(true)
    igtframe:RegisterForDrag("LeftButton")
    igtframe:SetScript("OnDragStart", igtframe.StartMoving)
    igtframe:SetScript("OnDragStop", igtframe.StopMovingOrSizing)

--- MAIN FRAME TITLE ---
    igtframe.title = igtframe:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    igtframe.title:SetPoint("CENTER", igtframe, "TOP", 0,-17)
    igtframe.title:SetText("Instance Gold Tracker")

--- EXIT BUTTON ---
    local button = CreateFrame("button","ExitButton", igtframe, "UIPanelCloseButtonNoScripts")
    button:SetPoint("TOPRIGHT", igtframe, "TOPRIGHT", 0, -1)
    button:SetScript("OnClick", function(self, button, down) self:GetParent():Hide() end)

--- DELETE BUTTON ---
    local delete = CreateFrame("button","DeleteButton", igtframe, "UIPanelButtonTemplate")
    delete:SetPoint("BOTTOMLEFT", igtframe, "BOTTOMLEFT", 3, 5)
    delete:SetScript("OnClick", function(self, button, down) 
        if st.GetSelection(st) then
        deleteEntry(st.GetSelection(st)) 
        MyAddon:Print("Entry deleted!") 
        else
            MyAddon:Print("Please select row you want to delete!")
        end
        setTableData()
        st.ClearSelection(st)
    end)
    delete:SetSize(60, 21)
    delete:SetText("Delete")
    delete.tooltipText = "Delete selected entry"

--- SETTINGS BUTTON ---
    local setbtn = CreateFrame("button","SettingsButton", igtframe, "UIPanelButtonTemplate")
    setbtn:SetPoint("BOTTOMRIGHT", igtframe, "BOTTOMRIGHT", -6, 5)
    setbtn:SetScript("OnClick", function(self, button, down) 

    settingsframe:SetShown(not settingsframe:IsShown())

    end)
    setbtn:SetSize(80, 21)
    setbtn:SetText("Settings")


--- CREATE DUNGEONS FRAME ---
    dngframe = CreateFrame("Frame", "Dungeons", igtframe, "SimplePanelTemplate")
    dngframe:SetPoint("TOPRIGHT", igtframe, "TOPLEFT", 1,0)
    dngframe:SetSize(300, 640)
    dngframe:SetFrameStrata("TOOLTIP")
    tinsert(UISpecialFrames, "Dungeons")
    dngframe.title = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dngframe.title:SetPoint("CENTER", dngframe, "TOP", 0,-17)
    dngframe.title:SetText("Details")

    dngframe.dngtitle = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dngframe.dngtitle:SetPoint("TOP", dngframe, "TOP", 0, -40)
   
    dngframe.dngtotalmoneyheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngtotalmoneyheader:SetPoint("TOPLEFT", dngframe, "TOPLEFT", 15, -80)
    dngframe.dngtotalmoneyheader:SetText("Total gold made")

    dngframe.dngtotalmoney = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngtotalmoney:SetPoint("TOPLEFT", dngframe.dngtotalmoneyheader, "TOPLEFT", 0, -20)
   
    dngframe.dngtotaltimeheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngtotaltimeheader:SetPoint("TOPLEFT", dngframe.dngtotalmoney, "TOPLEFT", 0, -40)
    dngframe.dngtotaltimeheader:SetText("Total time spent")

    dngframe.dngtotaltime = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngtotaltime:SetPoint("TOPLEFT", dngframe.dngtotaltimeheader, "TOPLEFT", 0, -20)
   
    dngframe.dngavgmoneyheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngavgmoneyheader:SetPoint("TOPLEFT", dngframe.dngtotaltime, "TOPLEFT", 0, -40)
    dngframe.dngavgmoneyheader:SetText("Average money made")

    dngframe.dngavgmoney = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngavgmoney:SetPoint("TOPLEFT", dngframe.dngavgmoneyheader, "TOPLEFT", 0, -20)

    dngframe.dngavgtimeheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngavgtimeheader:SetPoint("TOPLEFT", dngframe.dngavgmoney, "TOPLEFT", 0, -40)
    dngframe.dngavgtimeheader:SetText("Average time spent")

    dngframe.dngavgtime = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngavgtime:SetPoint("TOPLEFT", dngframe.dngavgtimeheader, "TOPLEFT", 0, -20)
   
    dngframe.dngavgmoneyperhourheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngavgmoneyperhourheader:SetPoint("TOPLEFT", dngframe.dngavgtime, "TOPLEFT", 0, -40)
    dngframe.dngavgmoneyperhourheader:SetText("Average money per hour")

    dngframe.dngavgmoneyperhour = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngavgmoneyperhour:SetPoint("TOPLEFT", dngframe.dngavgmoneyperhourheader, "TOPLEFT", 0, -20)

    dngframe.dngfastestrunheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngfastestrunheader:SetPoint("TOPLEFT", dngframe.dngavgmoneyperhour, "TOPLEFT", 0, -40)
    dngframe.dngfastestrunheader:SetText("Fastest run")

    dngframe.dngfastestruntime = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngfastestruntime:SetPoint("TOPLEFT", dngframe.dngfastestrunheader, "TOPLEFT", 0, -20)

    dngframe.dngprofitableheader = dngframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dngframe.dngprofitableheader:SetPoint("TOPLEFT", dngframe.dngfastestruntime, "TOPLEFT", 0, -40)
    dngframe.dngprofitableheader:SetText("Most gold earned")

    dngframe.dngprofitable = dngframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dngframe.dngprofitable:SetPoint("TOPLEFT", dngframe.dngprofitableheader, "TOPLEFT", 0, -20)

 --- CREATE SETTINGS FRAME ---
    settingsframe = CreateFrame("Frame", "Settings", igtframe, "SimplePanelTemplate")
    settingsframe:SetPoint("TOPLEFT", igtframe, "TOPRIGHT", -1,0)
    settingsframe:SetSize(300, 640)
    settingsframe:SetFrameStrata("TOOLTIP")
    tinsert(UISpecialFrames, "Settings")

--- SETTINGS FRAME TITLE ---
    settingsframe.title = settingsframe:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    settingsframe.title:SetPoint("CENTER", settingsframe, "TOP", 0,-17)
    settingsframe.title:SetText("Settings")
                    
--- STOPWATCH BUTTON ---
    local swtooltiptext = "If " .. "|cFF008000" .. "ON" .. "|cFFFFFFFF" .. ", Stopwatch will be shown when entering an instance, and hide when leaving the instance.\n\nStopwatch: "
    local swcb = CreateFrame("checkbutton","StopwatchButton", settingsframe, "UICheckButtonTemplate")
    swcb:SetPoint("TOPLEFT", settingsframe, "TOPLEFT", 6, -30)
    if StopwatchActive == "ON" then
        swcb:SetChecked(true)
    else
        swcb:SetChecked(false)
    end
    swcb:SetScript("OnClick", function(self, button, down) 

        if swcb:GetChecked() then
            swcb:SetChecked(true)
            StopwatchActive = "ON"
        else
            swcb:SetChecked(false)
            StopwatchActive = "OFF"
        end
        settingsframe:Hide()
        settingsframe:Show()
    end)
    swcb:SetText("Stopwatch")
    settingsframe.helpLabel = settingsframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    settingsframe.helpLabel:SetPoint("TOPLEFT", swcb, "TOPRIGHT", 0, -9)
    settingsframe.helpLabel:SetText("Stopwatch")

--- MINIMAP BUTTON ---
    local mmcb = CreateFrame("checkbutton","MinimapButton", swcb, "UICheckButtonTemplate")
    mmcb:SetPoint("TOPLEFT", settingsframe, "TOPLEFT", 6 , -55)
    if self.db.profile.minimap.hide then
        mmcb:SetChecked(false)
    else
        mmcb:SetChecked(true)
    end
    mmcb:SetScript("OnClick", function(self, button, down) 

        if mmcb:GetChecked() then
            mmcb:SetChecked(true)
            MyAddon:CommandTheBunnies()
        else
            mmcb:SetChecked(false)
            MyAddon:CommandTheBunnies()
        end
        settingsframe:Hide()
        settingsframe:Show()
    end)
    mmcb:SetText("Minimap Button")
    settingsframe.helpLabel = settingsframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    settingsframe.helpLabel:SetPoint("TOPLEFT", mmcb, "TOPRIGHT", 0, -9)
    settingsframe.helpLabel:SetText("Minimap Button")

    

--- SCROLLING TABLE ---
    local ScrollingTable = LibStub("ScrollingTable");
    local color = { 
        ["r"] = 0.5,
        ["g"] = 0.5,
        ["b"] = 1.0,
        ["a"] = 1.0,
    };
    local bgcolor = { 
        ["r"] = 0.0,
        ["g"] = 0.0,
        ["b"] = 0.0,
        ["a"] = 0.0,
    };
    local highlight = { 
        ["r"] = 0.75,
        ["g"] = 0.75,
        ["b"] = 0.75,
        ["a"] = 0.1,
    };

    local cols = {
        {
            ["name"] = "Name",
            ["width"] = 200,
            ["align"] = "LEFT",
            ["color"] = color,
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
            ["sortnext"] = 2
        },
        {
            ["name"] = "Difficulty",
            ["width"] = 100,
            ["align"] = "LEFT",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
            ["sortnext"] = 3
        },
        {
            ["name"] = "Time",
            ["width"] = 60,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },
        {
            ["name"] = "Item Value",
            ["width"] = 70,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },
        {
            ["name"] = "Gold",
            ["width"] = 70,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },
        {
            ["name"] = "Total",
            ["width"] = 90,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },
        {
            ["name"] = "Per Hour",
            ["width"] = 90,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },
        {
            ["name"] = "Character",
            ["width"] = 100,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },
        {
            ["name"] = "Date",
            ["width"] = 65,
            ["align"] = "CENTER",
            ["highlight"] = highlight,
            ["bgcolor"] = bgcolor,
            ["defaultsort"] = "dsc",
        },

    };
    st = ScrollingTable:CreateST(cols, 24, 23, nil, igtframe);
    st.frame:SetPoint("CENTER", igtframe, "CENTER", -1,-10)
    st:EnableSelection(true)

--- ON CLICK ---
    st:RegisterEvents({
        ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            if dngframe:IsShown() then
                dngframe:SetShown(not dngframe:IsShown())
            else
                if realrow == st:GetSelection() then
                    if not dngframe:IsShown() then
                        if table_Dungeon_Name[realrow] then
                            dngframe:SetShown(not dngframe:IsShown())
                            dngframe.dngtitle:SetText(table_Dungeon_Name[realrow])
                            dngtime, dngmoney, dngcount, timearray, moneyarray = getpart(table_Dungeon_Name[realrow])
                            dngframe.dngtotalmoney:SetText(CopperToGold(dngmoney))
                            dngframe.dngtotaltime:SetText(SecondsToClock(dngtime))
                            dngframe.dngavgmoney:SetText(CopperToGold(math.floor(dngmoney/dngcount)))
                            dngframe.dngavgtime:SetText(SecondsToClock(math.floor(dngtime/dngcount)))
                            dngframe.dngavgmoneyperhour:SetText(CopperToGold(3600/math.floor(dngtime/dngcount)*math.floor(dngmoney/dngcount)))
                            dngframe.dngfastestruntime:SetText(SecondsToClock(minArray(timearray)))
                            dngframe.dngprofitable:SetText(CopperToGold(maxArray(moneyarray)))
                        end
                    end
                end
            end
        end,
    });

--- TIMER ---
    local function instance_timer()
        local player_name, player_realm = UnitName("player")
        local localizedClass, englishClass, classIndex = UnitClass("player")
        local inInstance, instanceType = IsInInstance()
        local overall, equipped = GetAverageItemLevel()
        if instanceType == "party" or instanceType == "raid" then
            if timer_Status == 0 then
                timer_Status = 1
                
                sell_value_total = 0
                sell_value_per_minute = 0
                looted_money_total = 0
                looted_money_per_minute = 0
                total_money = 0
                total_money_per_minute = 0
                if StopwatchActive == "ON" then
                    Stopwatch_Toggle()
                    Stopwatch_Clear()
                    Stopwatch_Play()
                end
                
                local name, type, difficultyIndex, difficultyName = GetInstanceInfo()
                name_lastDungen = name
                difficulty_lastDungen = difficultyName
                t_start = GetTime()
                MyAddon:Print("Your run is being recorded.")
            end
        else
            if timer_Status == 1 then
                timer_Status = 0
                t_end = GetTime() - t_start
                sell_value_per_minute = (sell_value_total / (math.floor(t_end*1000)/1000)) * 60
                total_money = sell_value_total + looted_money_total
                looted_money_per_minute = (looted_money_total / (math.floor(t_end*1000)/1000)) * 60
                total_money_per_minute = (total_money / (math.floor(t_end*1000)/1000)) * 60
                if StopwatchActive == "ON" then
                    Stopwatch_Pause()
                    Stopwatch_Toggle()
                end
                if true then
                    MyAddon:Print("Stored data:",name_lastDungen, difficulty_lastDungen)
                    table.insert(table_Dungeon_Name,name_lastDungen)
                    table.insert(table_Dungeon_Difficulty,difficulty_lastDungen)
                    table.insert(table_Time,math.floor(t_end))
                    table.insert(table_Looted_Item_Value_Total,sell_value_total)
                    table.insert(table_Looted_Money_Total,looted_money_total)
                    table.insert(table_Money_Total,total_money)
                    table.insert(table_Character_Name, player_name)
                    table.insert(table_Item_Level, math.floor(equipped))
                    table.insert(table_Character_Class, englishClass)
                    table.insert(table_Date,date("%m/%d/%y"))
                else
                    MyAddon:Print("Time below your min set, data not stored")
                end
            end
        end
    end

--- HANDLE LOOTED ITEMS ---
    local function loot_item(arg1)
        local loottype, itemLink, quantity, source
        if arg1:match(PATTERN_LOOT_ITEM_SELF_MULTIPLE) then
            itemLink, quantity = smatch(arg1, PATTERN_LOOT_ITEM_SELF_MULTIPLE)
            itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
            sell_value_total = sell_value_total + (quantity * itemSellPrice)
        elseif arg1:match(PATTERN_LOOT_ITEM_SELF) then
            itemLink = smatch(arg1, PATTERN_LOOT_ITEM_SELF)
            itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
            quantity = 1
            sell_value_total = sell_value_total + itemSellPrice
        end
    end

--- HANDLE LOOTED GOLD ---
    local function loot_money(arg1)

        local string_table = {}
        local gold, silver, copper = 0
        local is_gold, is_silver, is_copper = 0

        for i in string.gmatch(arg1, "%d+") do
            table.insert(string_table, i)
        end

        if table.getn(string_table) == 1 then
            copper = string_table[1]
        elseif table.getn(string_table) == 2 then
            copper = string_table[2]
            silver = string_table[1]
        
        elseif table.getn(string_table) == 3 then
            copper = string_table[3]
            silver = string_table[2]
            gold = string_table[1]
        
        end
        looted_money_total = looted_money_total + copper + (silver*100) + (gold * 10000)
    end
--- EVENT HANDLER ---
    local function myEventHandler(self, event, ...)
        local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15= ...

        if event == 'ZONE_CHANGED' then
            instance_timer()
        elseif event == 'ZONE_CHANGED_NEW_AREA' then
            instance_timer()
        elseif event == "CHAT_MSG_LOOT" then
            loot_item(arg1)
        elseif event == "CHAT_MSG_MONEY" then
            loot_money(arg1)
        end
    end

--- SLASH COMMANDS ---
    SLASH_OPENFRAME1 = "/igt"
    SlashCmdList.OPENFRAME = function(arg)
        igtframe:SetShown(not igtframe:IsShown())
        setTableData()
    end

    SLASH_MINIMAPHIDE1 = "/igticon"
    SlashCmdList.MINIMAPHIDE = function(arg)
            mmcb:SetChecked(not mmcb:GetChecked())
        if self.db.profile.minimap.hide then
            icon:Show("Instance Gold Tracker")
        else
            icon:Hide("Instance Gold Tracker")
        end
            self.db.profile.minimap.hide = not self.db.profile.minimap.hide 
    end

--- REGISTER EVENTS ---
    igtframe:RegisterEvent("ZONE_CHANGED")
    igtframe:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    igtframe:RegisterEvent("CHAT_MSG_LOOT")
    igtframe:RegisterEvent("CHAT_MSG_MONEY")
    igtframe:RegisterEvent("PLAYER_LOGIN")
    igtframe:SetScript("OnEvent", myEventHandler)
    end

--- CONVERT SECONDS TO HOUR:MINUTES:SECONDS ---
    function SecondsToClock(seconds)
        local seconds = tonumber(seconds)
        if seconds <= 0 then
            return "00:00:00";
        else
            hours = string.format("%02.f", math.floor(seconds/3600));
            mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
            secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
            return hours..":"..mins..":"..secs
        end
    end

--- CONVERT COPPER TO GOLD SILVER COPPER ---
    function CopperToGold(copper)
        gold = floor(copper / 10000)
        silver = string.sub(copper, string.len(copper)-3, string.len(copper)-2)
        copper = string.sub(copper, string.len(copper)-1, string.len(copper))
        return  "|cFFC9B037" .. gold .. " " .. "|cFF808080" .. silver .. " " .. "|cFF976D5C" .. copper
    end

--- REMOVE ENTRY FROM TABLE ---
    function deleteEntry(index)
        table.remove(table_Dungeon_Name, index)
        table.remove(table_Dungeon_Difficulty, index)
        table.remove(table_Time, index)
        table.remove(table_Looted_Item_Value_Total, index)
        table.remove(table_Looted_Money_Total, index)
        table.remove(table_Money_Total, index)
        table.remove(table_Character_Name, index)
        table.remove(table_Character_Class, index)
        table.remove(table_Item_Level, index)
        table.remove(table_Date, index)
    end

--- SET TABLE DATA ---
    function setTableData()
        local data = {}

        for row = 1, table.getn(table_Dungeon_Name) do
            for row = 1, table.getn(table_Dungeon_Name) do
                if not data[row] then
                    data[row] = {};
                end
                if not data[row].cols then
                    data[row].cols = {};
                end
                data[row].cols[1] = { ["value"] = table_Dungeon_Name[row] }
                data[row].cols[2] = { ["value"] = table_Dungeon_Difficulty[row] }
                data[row].cols[3] = { ["value"] = SecondsToClock(table_Time[row]) }
                data[row].cols[4] = { ["value"] = CopperToGold(table_Looted_Item_Value_Total[row]) }
                data[row].cols[5] = { ["value"] = CopperToGold(table_Looted_Money_Total[row]) }
                data[row].cols[6] = { ["value"] = CopperToGold(table_Money_Total[row]) }
                data[row].cols[7] = { ["value"] = CopperToGold(3600/table_Time[row]*table_Money_Total[row]) }
                data[row].cols[8] = { ["value"] = table_Character_Name[row] }
                data[row].cols[9] = { ["value"] = table_Date[row] }
            end
            if row == table.getn(table_Dungeon_Name) then
                row = row + 1
                if not data[row] then
                    data[row] = {};
                end
                if not data[row].cols then
                    data[row].cols = {};
                end
               data[row].cols[1] = { ["value"] = "Total" }
                data[row].cols[2] = { ["value"] = "----------" }
                data[row].cols[3] = { ["value"] = SecondsToClock(sumArray(table_Time)) }
                data[row].cols[4] = { ["value"] = CopperToGold(sumArray(table_Looted_Item_Value_Total)) }
                data[row].cols[5] = { ["value"] = CopperToGold(sumArray(table_Looted_Money_Total)) }
                data[row].cols[6] = { ["value"] = CopperToGold(sumArray(table_Money_Total)) }
                data[row].cols[7] = { ["value"] = CopperToGold(3600/sumArray(table_Time)*sumArray(table_Money_Total)) }
                data[row].cols[8] = { ["value"] = "----------" }
                data[row].cols[9] = { ["value"] = "----------" }
        
            end
        end

        st:ClearSelection(st)
        st:SetData(data)
        st:SortData()
    end

--- SUM ARRAY ---
    function sumArray(thistable)
        something = 0
        for i = 1, table.getn(thistable) do
            something = something + thistable[i]  
        end
        return something
    end

--- GET MIN FROM ARRAY ---
    function minArray(thistable)
        something = thistable[1] 
        for i = 1, table.getn(thistable) do
            if something > thistable[i] then
                something = thistable[i] 
            end 
        end
        return something
    end

--- GET MAX FROM ARRAY ---
    function maxArray(thistable)
        something = thistable[1] 
        for i = 1, table.getn(thistable) do
            if something < thistable[i] then
                something = thistable[i] 
            end 
        end
        return something
    end

--- GET TABLE PART ---
    function getpart(name)
        runcount = 0
        temp_table_time = {}
        temp_table_money = {}
        for i = 1, table.getn(table_Dungeon_Name) do
            if table_Dungeon_Name[i] == name then
                table.insert(temp_table_time, table_Time[i])
                table.insert(temp_table_money, table_Money_Total[i])
                runcount = runcount + 1
            end
        end


    return sumArray(temp_table_time), sumArray(temp_table_money), runcount, temp_table_time, temp_table_money
    end
