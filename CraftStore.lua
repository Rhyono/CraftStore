local CS = CraftStoreFixedAndImprovedLongClassName

local EM, WM, SM, ZOSF, CSLOOT = EVENT_MANAGER, WINDOW_MANAGER, SCENE_MANAGER, zo_strformat, nil
local ITEMMARK, TIMER, SELF, MAXCRAFT = {}, {}, false, 999

local blueprint_limit = 500 -- maximum to show using search

function CS.RemoveCharacter(char)
  if char == CS.CurrentPlayer then
    CS.Chat:Print(CS.Loc.removeCurrentCharacter)
  else
    --character removal needs to remain a direct write to the variables
    CS.SelectedPlayer = CS.CurrentPlayer
    if CS.Account.mainchar == char then
      CS.Account.mainchar = false
    end
    CS.Account.player[char] = nil
    CS.Account.crafting.researching[char] = nil
    CS.Account.crafting.researched[char] = nil
    CS.Account.crafting.studies[char] = nil
    CS.Account.crafting.skill[char] = nil
    CS.Account.style.tracking[char] = nil
    CS.Account.style.knowledge[char] = nil
    CS.Account.cook.tracking[char] = nil
    CS.Account.cook.knowledge[char] = nil
    CS.Account.furnisher.tracking[char] = nil
    CS.Account.furnisher.knowledge[char] = nil
    CS.Account.trait.tracking[char] = nil
    CS.Character[char] = nil
    CS.RemoveCharacterStorage(char)
    for nr,_ in pairs(CS.GetCharacters()) do
      WM:GetControlByName('CraftStoreFixed_CharacterFrame'..nr):SetHidden(true)
    end
    CS.DrawCharacters()
    CS.UpdateScreen()
  end
end

function CS.LoadCharacter(control,button)
  local char = control.data.charactername
  if button == 2 then
    if CS.Account.mainchar == char then
      CS.Account.mainchar = false
    else
      CS.Account.mainchar = char
    end
    CS.DrawCharacters()
  elseif button == 3 then
    CS.RemoveCharacter(char)
  else
    CS.SelectedPlayer = char
    CS.UpdateScreen()
    CraftStoreFixed_PanelButtonCharacters:SetText(char)
    CraftStoreFixed_CharacterPanel:SetHidden(true)
  end
end

function CS.DrawCharacters()
  --Update height

  -- slimmer overview
  local overviewHeight = 83
  if CS.Account.options.overviewstyle == 1 then
    overviewHeight = overviewHeight + 58
  end
  if CS.Account.options.overviewstyle ~= 3 then
    overviewHeight = overviewHeight + 58
  end

  CraftStoreFixed_CharacterPanelBoxScrollChild:SetHeight(#CS.GetCharacters() * overviewHeight - 8)
  local control, mainchar
  local swatch = {[false] = '|t16:16:esoui/art/buttons/checkbox_unchecked.dds|t', [true] = '|t16:16:esoui/art/buttons/checkbox_checked.dds|t'}
  local tex = {[true] = '|t18:18:esoui/art/characterwindow/equipmentbonusicon_full.dds|t ', [false] = ''}
  local function GetResearch(char,nr)
    local row, now, control = 1, GetTimeStamp()
  -- minimal overview does not need any of this
  if CS.Account.options.overviewstyle ~= 3 then
    for craft,craftData in pairs(CS.Data.crafting.researched[char]) do
      for line,lineData in pairs(craftData) do
        for trait,traitData in pairs(lineData) do
          if traitData ~= true and traitData ~= false then
            if traitData > 0 then
              local name, icon = GetSmithingResearchLineInfo(craft,line)
              local tid = GetSmithingResearchLineTraitInfo(craft,line,trait)
              local _,_,ticon = GetSmithingTraitItemInfo(tid + 1)
              -- only complete overview has this control
              if CS.Account.options.overviewstyle == 1 then
                control = WM:GetControlByName('CraftStoreFixed_Character'..nr..'Research'..craft..'Slot'..row)
                control:SetText('|t22:22:'..icon..'|t  |t22:22:'..ticon..'|t')
                control.data = {info = ZOSF('<<C:1>> - <<C:2>>',name,GetString('SI_ITEMTRAITTYPE',tid))}
                WM:GetControlByName('CraftStoreFixed_Character'..nr..'Research'..craft..'Slot'..row..'Time'):SetText(CS.GetTime(traitData - now))
              end
              row = row + 1
            end
          end
        end
      end
      local maxsim = CS.Account.crafting.skill[char][craft].maxsim or 1
      local level = string.format('%02d',CS.Account.crafting.skill[char][craft].level) or 1
      local rank = string.format('%02d',CS.Account.crafting.skill[char][craft].rank) or 1
      local unknown = CS.Account.crafting.skill[char][craft].unknown or 1
      local simcolor, unknowncolor, current = '|cFFFFFF', '|cFF0000', row - 1
      if current == maxsim or unknown == 0 then
        simcolor = '|c00FF00'
      else
        simcolor = '|cFF0000'
      end
      WM:GetControlByName('CraftStoreFixed_Character'..nr..'Skill'..craft):SetText('|t24:24:'..CS.CraftIcon[craft]..'|t  '..level..' ('..rank..')|r    |c808080'..GetString(SI_BULLET)..'|r   '..simcolor..current..' / '..maxsim..'|r')
      row = 1
    end
  end
  end
  for x = 1, 20 do
    control = WM:GetControlByName('CraftStoreFixed_CharacterFrame'..x);
    if control then
      control:SetHidden(true)
    end
  end
  for nr, char in pairs(CS.GetCharacters()) do
    local player = CS.Account.player[char]
    if CS.Account.mainchar == char then
      mainchar = true
    else
      mainchar = false
    end
    WM:GetControlByName('CraftStoreFixed_CharacterFrame'..nr):SetHidden(false)
    control = WM:GetControlByName('CraftStoreFixed_Character'..nr..'Name')
  -- fallback race
  if CS.Races[player.race] == nil then
    player.race = 1
  end
  if CS.Classes[player.class] == nil then
    if CS.Debug then
      d('Unknown player class id: '..player.class)
    end
    player.class = 1
  end
  control:SetText(tex[mainchar]..char..(player.level ~= 0 and (' ('.. player.level..') ') or '')..'|t25:25:'..CS.Flags[player.faction]..'|t|t30:30:'..CS.Classes[player.class]..'|t|t25:25:'..CS.Races[player.race]..'|t')
  control.data = { charactername = char, info = CS.Loc.TT[10] }
    control = WM:GetControlByName('CraftStoreFixed_Character'..nr..'Info')
  -- If mount training isn't entirely completed
  if not player.mount.complete then
    control:SetText(CS.Texture(CS.Mount.capacity,20)..' '..player.mount.space..'  '..CS.Texture(CS.Mount.stamina,20)..' '..player.mount.stamina..' '..CS.Texture(CS.Mount.speed,20)..' '..player.mount.speed..'  '..'|t22:22:esoui/art/miscellaneous/timer_32.dds|t '..CS.GetTime(player.mount.time - GetTimeStamp()))
  else
    control:SetText(CS.Texture(CS.Mount.skills,24)..' 180/180')
  end
  control.data = { info = CS.Loc.TT[20] }
  control = WM:GetControlByName('CraftStoreFixed_Character'..nr..'InfoSkillPoints')
  if player.skillPoints == nil then
    player.skillPoints = "?/?"
  end
  control:SetText(CS.Loc.TT[30] .. player.skillPoints)
  control.data = { info = CS.Loc.TT[29] }
  control = WM:GetControlByName('CraftStoreFixed_Character'..nr..'InfoSkyShards')
  if player.skyShards == nil then
    player.skyShards = "?/?"
  end
  control:SetText('|t22:22:CraftStoreFixedAndImproved/DDS/skyshard.dds|t ' .. player.skyShards)
  control.data = { info = CS.Loc.TT[31] }

  -- minimal overview does not have this control
  if CS.Account.options.overviewstyle ~= 3 then
    for x, icon in pairs(CS.CraftIcon) do
      local name = GetSkillLineInfo(GetCraftingSkillLineIndices(x))
      local level = string.format('%02d',CS.Account.crafting.skill[char][x].level) or 1
      local rank = string.format('%02d',CS.Account.crafting.skill[char][x].rank) or 1
      control = WM:GetControlByName('CraftStoreFixed_Character'..nr..'Skill'..x)
      control:SetText('|t24:24:'..icon..'|t  '..level..' ('..rank..')')
      control.data = { info = ZOSF('<<C:1>>',name)..' - '..CS.Loc.rank..' ('..CS.Loc.level..')' }
    end
  end
    GetResearch(char,nr)
    WM:GetControlByName('CraftStoreFixed_Character'..nr..'Recipe'):SetText(swatch[CS.Account.cook.tracking[char]]..' |t22:22:esoui/art/icons/quest_scroll_001.dds|t')
    WM:GetControlByName('CraftStoreFixed_Character'..nr..'Style'):SetText(swatch[CS.Account.style.tracking[char]]..' |t22:22:esoui/art/icons/quest_book_001.dds|t')
    WM:GetControlByName('CraftStoreFixed_Character'..nr..'Trait'):SetText(swatch[CS.Account.trait.tracking[char]]..' |t22:22:esoui/art/icons/crafting_potent_nirncrux_dust.dds|t')
  end
end

-- determines if a character has trait tracking fully enabled
function CS.UpdateTrackingStatus(char)
  CS.Account.trait.tracking[char] = LBE:FlattenTable(CS.Data.crafting.studies[char],CS.Name,CS.LBE.Crafting):find("0") == nil and true or false
end

function CS.DrawTraitColumn(craft,line)
  local name, icon = GetSmithingResearchLineInfo(craft,line)
  local craftname = GetSkillLineInfo(GetCraftingSkillLineIndices(craft))
  local p = WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft..'Line'..line)
  local c = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Header',p,CT_BUTTON)
  c:SetAnchor(3,p,3,-1,0)
  c:SetDimensions(27,27)
  c:SetClickSound('Click')
  c:EnableMouseButton(2,true)
  c:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,true,self,'bc') end)
  c:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false,true) end)
  c:SetHandler('OnMouseDown',function(self,button)
  -- value is inverse; if any are false, switch to all true
  local value = false
  for trait = 1, CS.MaxTraits do
    if CS.Data.crafting.studies[CS.SelectedPlayer][craft][line][trait] == false then
      value = true
      break
    end
  end
  -- select or deselect entire skill
    if button == 2 then
      for col = 1, WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft):GetNumChildren() do
    for trait = 1, CS.MaxTraits do
      CS.Data.crafting.studies[CS.SelectedPlayer][craft][col][trait] = value
    end
        CS.UpdateStudyLine(WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft):GetChild(col),value)
      end
  -- update single column
    else
    for trait = 1, CS.MaxTraits do
      CS.Data.crafting.studies[CS.SelectedPlayer][craft][line][trait] = value
    end
      CS.UpdateStudyLine(p,value)
    end
  -- if any are disabled, tracking is not fully enabled
  if value == false then
    CS.Account.trait.tracking[CS.SelectedPlayer] = false
  -- otherwise figure out whether they are all enabled
  else
    CS.UpdateTrackingStatus(CS.SelectedPlayer)
  end
  end)
  c.data = {info = ZOSF(CS.Loc.TT[1],name,CS.CraftIcon[craft],craftname)}
  local t = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'HeaderTexture',c,CT_TEXTURE)
  t:SetAnchor(128,c,128,0,0)
  t:SetDimensions(26,26)
  t:SetTexture(icon)
  for trait = 1, CS.MaxTraits do
    local b = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Trait'..trait..'Bg',p,CT_BACKDROP)
    b:SetAnchor(3,p,3,-1,2 + trait * 26)
    b:SetDimensions(27,25)
    b:SetCenterColor(0.06,0.06,0.06,1)
    b:SetEdgeTexture('',1,1,1,1)
    b:SetEdgeColor(1,1,1,0.12)
    c = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Trait'..trait,b,CT_BUTTON)
    c:SetAnchor(128,b,128,0,0)
    c:SetDimensions(25,25)
    c:SetClickSound('Click')
    c:EnableMouseButton(2,true)
  c:EnableMouseButton(3,true)
    c:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true) end)
    c:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
    c:SetHandler('OnMouseDown',function(self,button)
    -- research
      if button == 3 and self.data.research and CS.SelectedPlayer == CS.CurrentPlayer then
    local proceed = false
    local bag,slot = 0,0
    --The shown researchable item is accessible to this character
    if (self.data.research[4] == CS.CurrentPlayer or self.data.research[4] == CS.Lang.en.bank) then
      local uid = CS.Account.crafting.stored[self.data.research[1]][self.data.research[2]][self.data.research[3]].id or false
      if uid then
        bag,slot = CS.ScanUidBag(uid)
        if bag and CanItemBeSmithingTraitResearched(bag,slot,self.data.research[1],self.data.research[2],self.data.research[3]) and not CS.IsLocked(bag,slot) then
          proceed = true
        end
      end
    end
    --It isn't, so let's try to find a substitute
    if not proceed then
      bag,slot = CS.ScanBagResearch(self.data.research[1],self.data.research[2],self.data.research[3],false,true)
      if bag and CanItemBeSmithingTraitResearched(bag,slot,self.data.research[1],self.data.research[2],self.data.research[3]) then
        proceed = true
      end
    end
    if proceed then
      ResearchSmithingTrait(bag,slot)
    else CS.Chat:Print(CS.Loc.noSlot) end
    -- to chat
      elseif button == 2 then
        local tnr = GetSmithingResearchLineTraitInfo(craft,line,trait)
        CS.ToChat(ZOSF(CS.Loc.itemsearch,name,GetString('SI_ITEMTRAITTYPE',tnr)))
    -- track/untrack
    elseif button == 1 then
    CS.Data.crafting.studies[CS.SelectedPlayer][craft][line][trait] = not CS.Data.crafting.studies[CS.SelectedPlayer][craft][line][trait]
    CS.UpdateStudyLine(WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft..'Line'..line),CS.Data.crafting.studies[CS.SelectedPlayer][craft][line])
    CS.UpdateTrackingStatus(CS.SelectedPlayer)
      end
    end)
    local t = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Trait'..trait..'Texture',c,CT_TEXTURE)
    t:SetAnchor(128,c,128,0,0)
    t:SetDimensions(25,25)
  end
  local b = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'CountBg',p,CT_BACKDROP)
  b:SetAnchor(3,p,3,-1,262)
  b:SetDimensions(27,25)
  b:SetCenterColor(0.06,0.06,0.06,1)
  b:SetEdgeTexture('',1,1,1,1)
  b:SetEdgeColor(1,1,1,0.12)
  local c = WM:CreateControl('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Count',b,CT_BUTTON)
  c:SetAnchor(128,b,128,0,0)
  c:SetDimensions(25,25)
  c:SetHorizontalAlignment(1)
  c:SetVerticalAlignment(1)
  c:SetFont('CraftStoreFixedFont')
  c:SetNormalFontColor(0.9,0.87,0.68,1)
end

function CS.ScanBagResearch(target_craft,target_line,target_trait,bag,secondary)
  --Check if it is a secondary craft attempt
  if not secondary then
    secondary = false
  end

  if not bag then
    bag = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_WORN,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK,BAG_VIRTUAL)
  end
  for _, data in pairs(bag) do
    local craft,line,trait = CS.GetTrait(GetItemLink(data.bagId,data.slotIndex))
    if target_craft == craft and target_line == line and target_trait == trait then
      local found = true
      --Check for locked or epic and above
      local quality = GetItemQuality(data.bagId,data.slotIndex)
      --thorough lock check including set
      local locked = CS.IsLocked(data.bagId,data.slotIndex)
      if locked or (secondary and quality > ITEM_QUALITY_ARCANE) then
        found = false
      end
      if found then
        return data.bagId, data.slotIndex
      end
    end
  end
  return false
end

function CS.ScanBag(scanid)
  local bag = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK,BAG_VIRTUAL)
  for _, data in pairs(bag) do
    local id = CS.SplitLink(GetItemLink(data.bagId,data.slotIndex),3)
    if id == scanid then
      return data.bagId, data.slotIndex
    end
  end
end

function CS.ScanUidBag(id,bag)
  if not id then
    return false
  end
  if not bag then
    bag = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_WORN,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK,BAG_VIRTUAL)
  end
  for _, data in pairs(bag) do
    if id == Id64ToString(data.uniqueId) then
      return data.bagId, data.slotIndex
    end
  end
  return false,false
end

function CS.UpdateBag()
  local bag = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK,BAG_VIRTUAL)
  for _, data in pairs(bag) do
    local link, stack = CS.StripLink(GetItemLink(data.bagId,data.slotIndex)), 0
    local backpack, bank, craftBag = GetItemLinkStacks(link)
    if not CS.Account.storage[link] then
      CS.Account.storage[link] = {}
    end
  if data.bagId == BAG_BACKPACK then
    stack = backpack
  elseif data.bagId == BAG_BANK or data.bagId == BAG_SUBSCRIBER_BANK then
    stack = bank
  elseif data.bagId == BAG_VIRTUAL then
    stack = craftBag
  else
    stack = data.stackCount
  end
  data.uid = Id64ToString(GetItemUniqueId(data.bagId,data.slotIndex))
  data.lnk = link
    local bagName = CS.CurrentPlayer
    if data.bagId == BAG_BANK or data.bagId == BAG_SUBSCRIBER_BANK then
      bagName = CS.Lang.en.bank
    end
    if IsHouseBankBag(data.bagId) then
      bagName = CS.Lang.en.housebank..(data.bagId-7)
    end
    if data.bagId == BAG_VIRTUAL then
      bagName = CS.Lang.en.craftbag
    end
  CS.Account.storage[link][bagName] = stack
  if stack == 0 then CS.Account.storage[link][bagName] = nil end
    local itemType = GetItemLinkItemType(link)
    if CS.RawItemTypes[itemType] and not CS.Account.materials[link] then
      local refinedLink = CS.StripLink(GetItemLinkRefinedMaterialItemLink(link,0))
      CS.Account.materials[link] = {raw=true,link=refinedLink}
      CS.Account.materials[refinedLink] = {raw=false,link=link}
  elseif CS.IsValidEquip(GetItemLinkEquipType(link)) then
    if CS.IsLocked(data.bagId,data.slotIndex) then
      CS.UpdateStored('removed',data,false)
    else
      CS.UpdateStored('added',data)
    end
    end
  end
end

function CS.RemoveCharacterStorage(char)
  for index, data in pairs(CS.Account.storage) do
    if data[char] ~= nil then
      CS.Account.storage[index][char] = nil
    end
  end
end

--Checks if an item is locked via game API, Item Saver and FCO
function CS.IsLocked(bagId,slotIndex)
  local locked = false

  --Allow disabling of lock check
  if not CS.Account.options.lockprotection then
    return locked
  end

  --Check default locking mechanism
  local _,_,_,_,locked,equipType = GetItemInfo(bagId,slotIndex)

  --Check for player locked
  if not locked then
    locked = IsItemPlayerLocked(bagId,slotIndex)
  end

  --Check set items are disabled
  if not locked and not CS.Account.options.marksetitems then
    locked = GetItemLinkSetInfo(GetItemLink(bagId,slotIndex))
  end

  --Determine item type
  local isGlyph = false
  local itemType = GetItemType(bagId,slotIndex)
  if itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_WEAPON or itemType == ITEMTYPE_GLYPH_JEWELRY then
    isGlyph = true
  end
  -- Determine equip type
  local isJewelry = false
  if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
    isJewelry = true
  end

  --Check with Item Saver
  if not locked and type(ItemSaver_IsItemSaved) == "function" then
    local _, set = ItemSaver_IsItemSaved(bagId,slotIndex)
    if set then
      local setData = ItemSaver_GetSetData(set)
      --Try to prevent extraction
      if isGlyph then
        locked = setData['filterDeconstruction']
      --Try to prevent research
      else
        locked = setData['filterResearch'];
      end
    end
  end
  --Check with FCOIS
  if not locked and FCOIS and FCOIS.addonVars.gPlayerActivated then
    --Try to prevent extraction
    if isGlyph then
      locked = FCOIS.IsEnchantingLocked(bagId,slotIndex)
    -- Try to prevent research (jewelry)
    elseif isJewelry then
      locked = FCOIS.IsJewelryResearchLocked(bagId,slotIndex)
    --Try to prevent research
    else
      locked = FCOIS.IsResearchLocked(bagId,slotIndex)
    end
  end
  return locked
end

function CS.ClearStorage()
  for x, slot in pairs(CS.Account.storage) do
    local count = 0
    for y, item in pairs(slot) do
      if item < 1 then CS.Account.storage[x][y] = nil
      else count = count + 1 end
    end
    if count == 0 then CS.Account.storage[x] = nil end
  end
end

--Reset all storage, materials and stored research item data via slash command
function CS.StoragePurge()
  CS.Account.storage = nil
  CS.Account.materials = nil
  CS.Account.crafting.stored = nil
  ReloadUI("ingame")
end

function CS.ScrollText()
  local function DrawControl(control)
    local container = CraftStoreFixed_QuestFrame:CreateControl('CraftStoreFixed_Inspiration'..control:GetNextControlId(),CT_CONTROL)
    local c = container:CreateControl('$(parent)Loot',CT_LABEL)
    c:SetFont('CraftStoreFixedInsp')
    c:SetColor(1,1,1,1)
    c:SetAnchor(1,container,1,0,0)
    container.c = c
    return container
  end
  local function ClearControl(c)
    c:SetHidden(true)
    c:ClearAnchors()
  end
  CSLOOT = ZO_ObjectPool:New(DrawControl,ClearControl)
end

function CS.Slide(c,x1,y1,x2,y2,duration)
    local a=ANIMATION_MANAGER:CreateTimeline()
    local s=a:InsertAnimation(ANIMATION_TRANSLATE,c)
    local fi=a:InsertAnimation(ANIMATION_ALPHA,c)
    local fo=a:InsertAnimation(ANIMATION_ALPHA,c,duration-500)
    fi:SetAlphaValues(0,1)
    fi:SetDuration(10)
    s:SetStartOffsetX(x1)
    s:SetStartOffsetY(y1)
    s:SetEndOffsetX(x2)
    s:SetEndOffsetY(y2)
    s:SetDuration(duration)
    fo:SetAlphaValues(1,0)
    fo:SetDuration(500)
  a:PlayFromStart()
end

function CS.Queue()
  if CS.Init then
  -- ensure at least one alarm is on
    if CS.Account.options.timeralarm ~= 4 or
      CS.Account.options.mountalarm ~= 4 or
      CS.Account.options.researchalarm ~= 4
    then
      for x,project in pairs(TIMER) do
        if(GetDiffBetweenTimeStamps(project.time,GetTimeStamp())) <= 0
        then
          --Handle announcement or chat message choices
          local alarm = nil;
          if project.id:find("^%$M") then
            alarm = 'mount';
          elseif project.id:find("^%$R") then
            alarm = 'research';
          elseif project.id == 'AccountTimer12' or project.id == 'AccountTimer24' then
            alarm = 'timer';
          end

          -- if alarm chat or both
          if
            (alarm == 'timer' and (CS.Account.options.timeralarm == 2 or CS.Account.options.timeralarm == 3)) or
            (alarm == 'mount' and (CS.Account.options.mountalarm == 2 or CS.Account.options.mountalarm == 3)) or
            (alarm == 'research' and (CS.Account.options.researchalarm == 2 or CS.Account.options.researchalarm == 3))
          then
            CS.Chat:Print(project.info)
          end

          -- if alarm announce or both
          if
            (alarm == 'timer' and (CS.Account.options.timeralarm == 1 or CS.Account.options.timeralarm == 3)) or
            (alarm == 'mount' and (CS.Account.options.mountalarm == 1 or CS.Account.options.mountalarm == 3)) or
            (alarm == 'research' and (CS.Account.options.researchalarm == 1 or CS.Account.options.researchalarm == 3))
          then
            PlaySound('Smithing_Finish_Research')
            CraftStoreFixed_Alarm:AddMessage(project.info,1,0.66,0.2,1)
            CraftStoreFixed_Alarm:AddMessage('|t10:10:x.dds|t',0,0,0,1)
          end

          -- if not off
          if
            (alarm == 'timer' and (CS.Account.options.timeralarm ~= 4)) or
            (alarm == 'mount' and (CS.Account.options.mountalarm ~= 4)) or
            (alarm == 'research' and (CS.Account.options.researchalarm ~= 4))
          then
            CS.Account.announce[project.id] = GetTimeStamp()
          end

          table.remove(TIMER,x)
        end
      end
    end

    if
      ZO_Provisioner_IsSceneShowing() and
      CS.Account.options.usecook
    then
      ZO_ProvisionerTopLevelTooltip:SetHidden(true)
      if PP ~= nil
      then
        ZO_ProvisionerTopLevel:SetHidden(true)
      end
    end

    if CS.Inspiration ~= ''
    then
      local c,x = CSLOOT:AcquireObject()
      c:SetHidden(false)
      c:SetAnchor(128,CraftStoreFixed_QuestFrame,128,0,0)
      c:GetChild(1):SetText(CS.Inspiration)
      CS.Slide(c,0,20,0,(GuiRoot:GetHeight()/2)-180,3500)
      zo_callLater(function() CSLOOT:ReleaseObject(x) end,3510)
      CS.Inspiration = ''
    end
  end
end

function CS.UpdateScreen()
  local function SetPoint(x)
    local left,num,right=string.match(x,'^([^%d]*%d)(%d*)(,-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1' .. (GetCVar('language.2') == 'en' and ',' or '.')):reverse())..right
  end
  for craft, _ in pairs(CS.Data.crafting.researched[CS.SelectedPlayer]) do
    for line = 1, GetNumSmithingResearchLines(craft) do
      for trait = 1, CS.MaxTraits do
        CS.UpdatePanelIcon(craft,line,trait)
      end
    end
    for id,value in pairs(CS.Data.cook.knowledge[CS.SelectedPlayer]) do
      for x,recipe in pairs(CS.Cook.recipe) do
        if recipe.id == id then
          CS.Cook.recipe[x].known = value; break
        end
      end
    end
    for id,value in pairs(CS.Data.furnisher.knowledge[CS.SelectedPlayer]) do
      for x,recipe in pairs(CS.Furnisher.recipe) do
        if recipe.id == id then
          CS.Furnisher.recipe[x].known = value; break
        end
      end
    end
  end
  CS.UpdateAllStudies()
  CS.UpdateResearchWindows()
  CS.UpdateStyleKnowledge()
  local fmax,fused = GetFenceSellTransactionInfo()
  CraftStoreFixed_PanelButtonCharacters:SetText(CS.SelectedPlayer)
  CraftStoreFixed_PanelFenceGoldText:SetText("|cC5C29E"..fused.."/"..fmax.." |r  "..SetPoint(GetCurrentMoney() - CS.Character.income[2]).." |t14:14:esoui/art/currency/currency_gold.dds|t")
end

local function NeedAppend(need,unneed,researching)
  if researching == nil then
    researching = {}
  end
  local function sorter(a, b)
    return a:lower() < b:lower()
  end
  if #need ~= 0 then
    table.sort(need,sorter)
    need = '|t20:20:esoui/art/buttons/decline_up.dds|t ' .. (CS.Account.options.displaycount and string.format("(%d) ", #need) or '') .. table.concat(need,', ')
  else need = '' end
  if #unneed ~= 0 then
    table.sort(unneed,sorter)
    unneed = '|t20:20:esoui/art/buttons/accept_up.dds|t ' .. (CS.Account.options.displaycount and string.format("(%d) ", #unneed) or '') .. table.concat(unneed,', ')
  else unneed = '' end
  if #researching ~= 0 then
    table.sort(researching,sorter)
    researching = '|t23:23:esoui/art/miscellaneous/timer_32.dds|t  ' .. (CS.Account.options.displaycount and string.format("(%d) ", #researching) or '') .. table.concat(researching,', ')
  else researching = '' end
  return need, unneed, researching
end

function CS.UpdatePanelIcon(craft,line,trait)
  if not craft or not line or not trait then
    return
  end
  if trait < 1 then
    return
  end
  local traitname = GetString('SI_ITEMTRAITTYPE',GetSmithingResearchLineTraitInfo(craft,line,trait))
  local control = WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Trait'..trait..'Texture')
  local known = CS.NilCheck(CS.Data.crafting.researched,false,CS.SelectedPlayer,craft,line,trait)
  local store = CS.NilCheck(CS.Account.crafting.stored,{link = false, owner = false},craft,line,trait)
  local now, tip = GetTimeStamp(), ''
  local function CountTraits()
    local count = 0
    for _, trait in pairs(CS.Data.crafting.researched[CS.SelectedPlayer][craft][line]) do
      if trait == true then
        count = count + 1
      end
    end
    return count
  end
  local need, unneed, researching = {}, {}, {}
  for _, char in pairs(CS.GetCharacters()) do
  local val = CS.NilCheck(CS.Data.crafting.researched,false,char,craft,line,trait)
    if val == true then
      table.insert(unneed,'|c00FF00'..char..'|r')
    elseif val == false then
      table.insert(need,'|cFF1010'..char..'|r')
    elseif val and val > 0 then
      if char == CS.CurrentPlayer then
        local _,remain = GetSmithingResearchLineTraitTimes(craft,line,trait)
        table.insert(researching,'|c66FFCC'..char..' ('..CS.GetTime(remain)..')|r')
      else
        table.insert(researching,'|c66FFCC'..char..' ('..CS.GetTime(GetDiffBetweenTimeStamps(val,now))..')|r')
      end
    end
  end

  local needTip, unneedTip, researchingTip = NeedAppend(need,unneed,researching)

  if researchingTip ~= '' then
    tip = '\n' .. researchingTip
  end
  if needTip ~= '' then
    tip = tip .. '\n' .. needTip
  end
  if unneedTip ~= '' then
    tip = tip .. '\n' .. unneedTip
  end

  control:GetParent().data = { info = '|cFFFFFF'..traitname..'|r'..tip, buttons = {CS.Loc.TT[34], CS.Loc.TT[6]} }

  if known == false then
    -- see if another character knows it if the option is on
    -- red = none know,
    -- white = none know & has item somewhere, blue = white + selected has item, cyan = white + current has item, navy blue = white + bank
    -- orange = some know & no item, yellow = some know (not this) & has item somewhere, purple = yellow + selected has item, pink = yellow + current has item, eggplant = yellow + bank
    -- green = this knows
    local altKnown = false
    if CS.Account.options.advancedcolorgrid then
      for _, char in pairs(CS.GetCharacters()) do
        if CS.Data.crafting.researched[char][craft][line][trait] then
          altKnown = true
          break
        end
      end
    end
    -- none know, red
    control:SetColor(1,0,0,1)
    -- some know, orange
    if altKnown then
      control:SetColor(1,170/255,0,1)
    end
    control:SetTexture('esoui/art/buttons/decline_up.dds')
    if store.link and store.owner then
      local isSet = GetItemLinkSetInfo(store.link)
      local mark = true
      if not CS.Account.options.marksetitems and isSet then
        mark = false
      end
      if mark then
        tip = '|t20:20:esoui/art/buttons/pointsplus_up.dds|t |cE8DFAF'..store.owner..'|r'..tip
        -- none know, white
        control:SetColor(1,1,1,1)

        if CS.Account.options.advancedcolorgrid then
          -- item is in the bank
          if store.owner == CS.Lang.en.bank then
            -- navy blue
            control:SetColor(0,0,0.5,1)
            -- alt knows, eggplant
            if altKnown then
              control:SetColor(0.5,0,0.5,1)
            end
          -- item is on this character
          elseif store.owner == CS.SelectedPlayer then
            -- blue
            control:SetColor(0,0,1,1)
            -- alt knows, purple
            if altKnown then
              control:SetColor(0.5,0,1,1)
            end
          -- item is on the current player
          elseif store.owner == CS.CurrentPlayer then
            -- cyan
            control:SetColor(0,1,1,1)
            -- alt knows, pink
            if altKnown then
              control:SetColor(1,0,1,1)
            end
          -- item not on this character and alt knows, yellow
          elseif altKnown then
            control:SetColor(1,1,0,1)
          end
        end
        control:SetTexture('esoui/art/buttons/pointsplus_up.dds')
        control:GetParent().data = { link = store.link, addline = {tip}, research = {craft,line,trait,store.owner}, buttons = {CS.Loc.TT[33], CS.Loc.TT[34], CS.Loc.TT[6]}}
      end
    end
  -- known, green
  elseif known == true then
    control:SetColor(0,1,0,1)
    control:SetTexture('esoui/art/buttons/accept_up.dds')
  -- researching
  else
    control:SetColor(0.4,1,0.8,1)
    control:SetTexture('esoui/art/miscellaneous/timer_32.dds')
  end
  WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft..'Line'..line..'Count'):SetText(CountTraits())
end

function CS.UpdateStudyLine(control,tracking,craft,line)
  local trackingTable = {}
  -- if tracking is a bool, create a true table out of it
  if type(tracking) == 'boolean' then
    for trait = 1, CS.MaxTraits do
      trackingTable[trait] = tracking
    end
  elseif type(tracking) == 'table' then
    for index,data in pairs(tracking) do
      trackingTable[index] = data
    end
  end
  -- check if all true; otherwise header is red
  local allTracked = true
  for index, data in pairs(trackingTable) do
    if data == false then
      allTracked = false
      break
    end
  end

  -- set all tracked
  if allTracked then
    control:GetNamedChild('HeaderTexture'):SetColor(1,1,1,1)
    for x = 2, control:GetNumChildren() - 1 do
      local subcontrol = control:GetChild(x)
      subcontrol:SetCenterColor(0.06,0.06,0.06,1)
      subcontrol:SetEdgeColor(1,1,1,0.12)
    end
  else
    -- set header red
    control:GetNamedChild('HeaderTexture'):SetColor(1,0,0,1)
    for x = 2, control:GetNumChildren() - 1 do
      local subcontrol = control:GetChild(x)
      -- set individually
      if trackingTable[x-1] then
        subcontrol:SetCenterColor(0.06,0.06,0.06,1)
        subcontrol:SetEdgeColor(1,1,1,0.12)
      else
        subcontrol:SetCenterColor(0.15,0,0,1)
        subcontrol:SetEdgeColor(1,0,0,0.5)
      end
    end
  end
end

function CS.UpdateAllStudies()
  for craft, craftData in pairs(CS.Data.crafting.studies[CS.SelectedPlayer]) do
    for line, lineData in pairs(craftData) do
      CS.UpdateStudyLine(WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft..'Line'..line),lineData,craft,line)
    end
  end
end

function CS.GetTotalSpentSkillPoints()
  local count = 0
  for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
    for _, skillLineData in skillTypeData:SkillLineIterator() do
      count = count + SKILL_POINT_ALLOCATION_MANAGER:GetNumPointsAllocatedInSkillLine(skillLineData)
    end
  end
  return count
end

function CS.GetSkyShards(asString)
  local function GetNextZoneStoryZoneIdIter(_, lastZoneId)
  return GetNextZoneStoryZoneId(lastZoneId)
  end

  local acquired, total = 0, 0
  for zoneId in GetNextZoneStoryZoneIdIter do
    local acquired2, total2 = ZONE_STORIES_MANAGER.GetActivityCompletionProgressValues(zoneId, ZONE_COMPLETION_TYPE_SKYSHARDS)
    total = total + total2
    acquired = acquired + acquired2
  end

  local _, coldharbourCompleted = GetAchievementCriterion(993, 1)
  acquired = acquired + coldharbourCompleted
  total = total + 1

  if asString then
    return acquired .. "/" .. total
  else
    return acquired, total
  end
end

function CS.UpdatePlayer(deactivation)
  deactivation = deactivation or false
  local function GetBonus(bonus,craft)
    local skillType, skillId = GetCraftingSkillLineIndices(craft)
    local _, rank = GetSkillLineInfo(skillType,skillId)
    return {level = GetNonCombatBonus(bonus) or 1, rank = rank, maxsim = GetMaxSimultaneousSmithingResearch(craft) or 1}
  end
  if not deactivation then
    CS.Account.crafting.skill[CS.CurrentPlayer] = {
      GetBonus(NON_COMBAT_BONUS_BLACKSMITHING_LEVEL,1),
      GetBonus(NON_COMBAT_BONUS_CLOTHIER_LEVEL,2),
      GetBonus(NON_COMBAT_BONUS_ENCHANTING_LEVEL,3),
      GetBonus(NON_COMBAT_BONUS_ALCHEMY_LEVEL,4),
      GetBonus(NON_COMBAT_BONUS_PROVISIONING_LEVEL,5),
      GetBonus(NON_COMBAT_BONUS_WOODWORKING_LEVEL,6),
    GetBonus(NON_COMBAT_BONUS_JEWELRYCRAFTING_LEVEL,7)
    }
  end
  local ride = {GetRidingStats()}
  local rideTime = 0
  local rideComplete = false
  --Check if fully trained
  if not ((ride[1] == ride[2]) and
    (ride[3] == ride[4]) and
    (ride[5] == ride[6])) then
    rideTime = GetTimeUntilCanBeTrained()/1000 or 0
    if rideTime > 1 then
      rideTime = rideTime + GetTimeStamp()
    end
  else
    rideComplete = true
  end
  local level = GetUnitLevel('player')
  local levelcp = GetUnitChampionPoints('player')
  if levelcp>0 then
    level = 0
  end

  CS.Account.player[CS.CurrentPlayer] = {
    race =  GetUnitRaceId('player'),
    class = GetUnitClassId('player'),
    level = level,
    faction = GetUnitAlliance('player'),
    mount = {
      space = ride[1]..'/'..ride[2],
      stamina = ride[3]..'/'..ride[4],
      speed = ride[5]..'/'..ride[6],
      complete = rideComplete,
      time = rideTime
    },
    skillPoints = GetAvailableSkillPoints() .. "/" .. (CS.GetTotalSpentSkillPoints()+GetAvailableSkillPoints()),
    skyShards = CS.GetSkyShards(true)
  }
  --save or load saved vars
  if deactivation then
    CS.Account.cook.knowledge[CS.CurrentPlayer] = LBE:Encode(CS.Data.cook.knowledge[CS.CurrentPlayer],CS.Name,CS.LBE.Cook)
    CS.Account.furnisher.knowledge[CS.CurrentPlayer] = LBE:Encode(CS.Data.furnisher.knowledge[CS.CurrentPlayer],CS.Name,CS.LBE.Furnisher)
    CS.Account.style.knowledge[CS.CurrentPlayer] = LBE:Encode(CS.Data.style.knowledge[CS.CurrentPlayer],CS.Name,CS.LBE.Styles)
    CS.Account.crafting.researched[CS.CurrentPlayer] = LBE:Encode(CS.Data.crafting.researched[CS.CurrentPlayer],CS.Name,CS.LBE.Researched)

    -- any character can be updated for studies
    for _, char in pairs(CS.GetCharacters()) do
      if type(CS.Data.crafting.studies[char]) == 'table' then
        CS.Account.crafting.studies[char] = LBE:Encode(CS.Data.crafting.studies[char],CS.Name,CS.LBE.Crafting)
      end
    end

    -- researching only takes the non-bool values
    CS.Account.crafting.researching[CS.CurrentPlayer] = nil
    for ci,crafts in pairs(CS.Data.crafting.researched[CS.CurrentPlayer]) do
      for li, lines in pairs(crafts) do
        for ti, trait in pairs(lines) do
          if type(trait) == 'number' then
            CS.NilCheckSet(CS.Account.crafting.researching,CS.Data.crafting.researched[CS.CurrentPlayer][ci][li][ti],CS.CurrentPlayer,ci,li,ti)
          end
        end
      end
    end
  end
end

--Sort functions
--alphabetical on .name
local function asort(a, b)
  return a.name:lower() < b.name:lower()
end
--level; numlevel, then .name
local function tsort(a,b)
  --Level equal, use name
  if a.numlevel == b.numlevel then
    return asort(a,b)
  else
    return a.numlevel > b.numlevel
  end
end
--reverse trait sort; traits, then .name
local function traitsort(a,b)
  --trait equal, use name
  if a.traits == b.traits then
    return asort(a,b)
  else
    return a.traits < b.traits
  end
end

--sort by motif number
local function msort(a,b)
  return a.motif < b.motif
end

local styleNames = {}

function CS.StyleSort()
  styleNames = {}
  --build list of styles by internal id
  for id = 1,GetNumValidItemStyles() do
    local style = GetValidItemStyleId(id)
    local icon, link, name, aName, aLink, popup = CS.Style.GetHeadline(style)
    if id ~= 33 and CS.Style.CheckStyle(style) then
      styleNames[#styleNames+1] = {name=name,id=id,motif=CS.Style.StyleMotifNumber(style)}
    end
  end

  -- sort alphabetically
  if CS.Account.options.sortstyles == 1 then
    table.sort(styleNames,asort)
  -- sort by motif #
  elseif CS.Account.options.sortstyles == 2 then
    table.sort(styleNames,msort)
  end
end


function CS.UpdateStyleKnowledge(activate)
  --only update the current player during activation or while selected
  if activate or CS.SelectedPlayer == CS.CurrentPlayer then
    if CS.Data.style.knowledge[CS.CurrentPlayer] == nil then
      CS.Data.style.knowledge[CS.CurrentPlayer] = LBE:CloneSchema(CS.Name,CS.LBE.Styles)
    end
    --build the complete list, with variants
    for index,data in pairs(CS.Data.style.knowledge[CS.CurrentPlayer]) do
      CS.Data.style.knowledge[CS.CurrentPlayer][index] = IsItemLinkBookKnown(('|H1:item:%u:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(index))
    end
  end
  --display knowledge
  CS.StyleSort()
  local known, control
  for id,data in pairs(styleNames) do
    local style = GetValidItemStyleId(data.id)
    for chapter = 1,14 do
      known = CS.Data.style.knowledge[CS.SelectedPlayer][CS.Style.GetChapterId(style,chapter)]
      control = WM:GetControlByName('CraftStoreFixed_StylePanelScrollChild'..id..'Button'..chapter..'Texture')
      if known then
        control:SetColor(1,1,1,1)
      else
        control:SetColor(1,0,0,0.5)
      end
    end
    CS.FilterStyles()
  end
end

function CS.UpdateRecipeKnowledge()
  CS.Cook.recipe = {}
  CS.Furnisher.recipe = {}
  for _,id in pairs(CS.Cook.recipelist) do
    local link,stat = ('|H1:item:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(id), 0
    local name = GetItemLinkName(link)
    local known = IsItemLinkRecipeKnown(link)
    CS.Data.cook.knowledge[CS.SelectedPlayer][id] = known
    local reslink = GetItemLinkRecipeResultItemLink(link,LINK_STYLE_DEFAULT)
    local quality,itype = GetItemLinkQuality(reslink), GetItemLinkItemType(reslink)
    local _,_,text = GetItemLinkOnUseAbilityInfo(reslink)
    local level = GetItemLinkRequiredLevel(reslink)
    local levelcp = GetItemLinkRequiredChampionPoints(reslink)
    local numlevel = level+levelcp
    if levelcp>0 then
      level = CS.ChampionPointsTexture..levelcp
    end
    local function statcheck(stat)
      if string.find(text,stat) then
        return true
      else
        return false
      end
    end
    local function namecheck(stat)
      if string.find(name,stat) then
        return true
      else
        return false
      end
    end
    local fm,fs,fh = statcheck(CS.MagickaName), statcheck(CS.StaminaName), statcheck(CS.HealthName)
    if fm and fh and fs then
      stat = 7
    elseif fs and fh then
      stat = 5
    elseif fm and fh then
      stat = 4
    elseif fm and fs then
      stat = 6
    elseif fm then
      stat = 2
    elseif fh then
      stat = 1
    elseif fs then
      stat = 3
    else
      stat = 8
    end
    if itype == ITEMTYPE_DRINK then
      stat = stat + 7
    end
    if id > 70000 then
      stat = itype == ITEMTYPE_FOOD and 16 or 15
    end
    table.insert(CS.Cook.recipe,{name = ZOSF('<<C:1>>',GetItemLinkName(reslink)), stat = stat, quality = quality, level = level, numlevel = numlevel, link = link, result = reslink, known = known, id = id})
  end
  -- handle bound (duplicate) recipes
  for _,id in pairs(CS.Cook.recipeduplicatelist) do
    local link,stat = ('|H1:item:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(id), 0
    local name = GetItemLinkName(link)
    local known = IsItemLinkRecipeKnown(link)
    CS.Data.cook.knowledge[CS.SelectedPlayer][id] = known
  end

  for _,id in pairs(CS.Furnisher.recipelist) do
    local link,stat = ('|H1:item:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(id), 0
    local _, spectype = GetItemLinkItemType(link)
    local name = GetItemLinkName(link)
    local known = IsItemLinkRecipeKnown(link)
    CS.Data.furnisher.knowledge[CS.SelectedPlayer][id] = known
    local reslink = GetItemLinkRecipeResultItemLink(link,LINK_STYLE_DEFAULT)
    local quality,itype = GetItemLinkQuality(reslink), GetItemLinkItemType(reslink)
    local _,_,text = GetItemLinkOnUseAbilityInfo(reslink)
    local level = GetItemLinkRequiredLevel(reslink)
    local levelcp = GetItemLinkRequiredChampionPoints(reslink)
    local numlevel = level+levelcp
    if levelcp>0 then
      level = CS.ChampionPointsTexture..levelcp
    end
    stat = spectype - 171
    if GetItemLinkName(reslink) ~= '' then
      table.insert(CS.Furnisher.recipe,{name = ZOSF('<<C:1>>',GetItemLinkName(reslink)), stat = stat, quality = quality, level = level, numlevel = numlevel, link = link, result = reslink, known = known, id = id})
    end
  end
  table.sort(CS.Cook.recipe,tsort)
  table.sort(CS.Furnisher.recipe,asort)
  CS.UpdateIngredientTracking()
end

function CS.UpdateIngredientTracking()
  for k in next,CS.Cook.ingredient do
    CS.Cook.ingredient[k] = nil
  end
  for recid,_ in pairs(CS.Account.cook.ingredients)do
    local reslink,_ = ('|H1:item:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(recid), false
    for num = 1, GetItemLinkRecipeNumIngredients(reslink) do
      local name = GetItemLinkRecipeIngredientInfo(reslink,num)
      for _,ingid in pairs(CS.Cook.ingredientlist) do
        if GetItemLinkName('|H1:item:'..ingid..':0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h') == name then
          CS.Cook.ingredient[ingid] = true; break
        end
      end
    end
  end
end

function CS.UpdateResearchWindows()
  local known, unknown, row, now, control = 0, 0, 1, GetTimeStamp()
  local pip = '|r|c808080  '..GetString(SI_BULLET)..'|r  '
  for craft,craftData in pairs(CS.Data.crafting.researched[CS.SelectedPlayer]) do
    for x = 1,3 do
      control = WM:GetControlByName('CraftStoreFixed_PanelResearch'..craft..'WindowLine'..x)
      control:SetText(nil)
      control.data = nil
      control:GetNamedChild('Time'):SetText(nil)
    end
    for line,lineData in pairs(craftData) do
      for trait,traitData in pairs(lineData) do
        if traitData then
          known = known + 1
        else
          unknown = unknown + 1
        end
        if traitData ~= true and traitData ~= false then
          if traitData > 0 then
            control = WM:GetControlByName('CraftStoreFixed_PanelResearch'..craft..'WindowLine'..row)
            local name, icon = GetSmithingResearchLineInfo(craft,line)
            local tid = GetSmithingResearchLineTraitInfo(craft,line,trait)
            control:SetText(' |t28:28:'..icon..'|t  '..GetString('SI_ITEMTRAITTYPE',tid))
            control.data = {info = ZOSF('<<C:1>>',name)}
            if CS.SelectedPlayer == CS.CurrentPlayer then
              local _,remain = GetSmithingResearchLineTraitTimes(craft,line,trait)
              control:GetNamedChild('Time'):SetText(CS.GetTime(remain))
            else
              control:GetNamedChild('Time'):SetText(CS.GetTime(GetDiffBetweenTimeStamps(traitData,now)))
            end
            row = row + 1
          end
        end
      end
    end
    --Set the unknown amount to saved vars for overview usage
    CS.Account.crafting.skill[CS.SelectedPlayer][craft].unknown = unknown
    local maxsim = (CS.Account.crafting.skill[CS.SelectedPlayer][craft].maxsim or 1)
    local level = (CS.Account.crafting.skill[CS.SelectedPlayer][craft].level or 1)
    local rank = (CS.Account.crafting.skill[CS.SelectedPlayer][craft].rank or 1)
    local simcolor, unknowncolor, current = '|cFFFFFF', '|cFF0000', row - 1
    if current == maxsim or unknown == 0 then
      simcolor = '|c00FF00'
    else
      simcolor = '|cFF0000'
    end
    if unknown == 0 then
      unknowncolor = '|c00FF00'
    end
    control = WM:GetControlByName('CraftStoreFixed_PanelResearch'..craft..'Header')
    control:GetNamedChild('Data'):SetText('|c00FF00'..known..pip..unknowncolor..unknown..pip..'|c808080'..CS.Loc.level..': '..level..' ('..rank..')|r')
    control:GetNamedChild('Slot'):SetText(simcolor..current..' / '..maxsim..'|r')
    row = 1; known = 0; unknown = 0
  end
end

function CS.UpdateResearch()
  local crafts = {CRAFTING_TYPE_BLACKSMITHING,CRAFTING_TYPE_CLOTHIER,CRAFTING_TYPE_WOODWORKING,CRAFTING_TYPE_JEWELRYCRAFTING}
  for _,craft in pairs(crafts) do
    for line = 1, GetNumSmithingResearchLines(craft) do
      for trait = 1, CS.MaxTraits do
        local _,_,known = GetSmithingResearchLineTraitInfo(craft,line,trait)
        if known == false then
          local _,remaining = GetSmithingResearchLineTraitTimes(craft,line,trait)
          if remaining and remaining > 0 then
            CS.NilCheckSet(CS.Data.crafting.researched,remaining + GetTimeStamp(),CS.CurrentPlayer,craft,line,trait)
          else
            CS.NilCheckSet(CS.Data.crafting.researched,false,CS.CurrentPlayer,craft,line,trait)
          end
        else
          CS.NilCheckSet(CS.Data.crafting.researched,true,CS.CurrentPlayer,craft,line,trait)
        end
        CS.UpdatePanelIcon(craft,line,trait)
      end
    end
  end
end

function CS.UpdateAccountVars()
  CS.UpdateResearch()
  CS.Data.style.knowledge[CS.CurrentPlayer] = LBE:CloneSchema(CS.Name,CS.LBE.Styles)
  CS.Data.cook.knowledge[CS.CurrentPlayer] = LBE:CloneSchema(CS.Name,CS.LBE.Cook)
  CS.Data.furnisher.knowledge[CS.CurrentPlayer] = LBE:CloneSchema(CS.Name,CS.LBE.Furnisher)

  if not CS.Account.style.tracking[CS.CurrentPlayer] then
    CS.Account.style.tracking[CS.CurrentPlayer] = false
  end
  if not CS.Account.cook.tracking[CS.CurrentPlayer] then
    CS.Account.cook.tracking[CS.CurrentPlayer] = false
  end
  if not CS.Account.furnisher.tracking[CS.CurrentPlayer] then
    CS.Account.furnisher.tracking[CS.CurrentPlayer] = false
  end
  if not CS.Account.trait.tracking[CS.CurrentPlayer] then
    CS.Account.trait.tracking[CS.CurrentPlayer] = false
  end

  -- only reset studies if nil
  if not CS.Data.crafting.studies[CS.CurrentPlayer] then
    CS.Data.crafting.studies[CS.CurrentPlayer] = LBE:CloneSchema(CS.Name,CS.LBE.Crafting)
  end
end

function CS.UpdateQuest(qId)
  for _, quest in pairs(CS.Quest) do
    if quest.id == qId then
      local out = ''
      local title = quest.name..'\n'
      quest.work = {}
      for cId = 1, GetJournalQuestNumConditions(qId,1) do
        local text,current,maximum = GetJournalQuestConditionInfo(qId,1,cId)
        if text and text ~= '' then
          if current == maximum then text = '|c00FF00'..text..'|r' end
          quest.work[cId] = text
          out = out..text..'\n'
        end
      end
      if DolgubonsWrits and CraftStoreFixed_DolgubonsWritsEndpoint then
        if WritCreater.savedVars.tutorial then
          zo_callLater(function () CS.UpdateQuest(qId) end, 1000)
          return
        end
        CraftStoreFixed_DolgubonsWritsEndpoint:SetText(out)
        CraftStoreFixed_QuestText:SetText(title..out)
      else
        CraftStoreFixed_QuestText:SetText(title..out)
      end
      return
    end
  end
end

function CS.UpdateInventory()
  local inv = {
    ZO_PlayerInventoryList,
    ZO_PlayerBankBackpack,
    ZO_GuildBankBackpack,
    ZO_HouseBankBackpack,
    ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack,
    ZO_SmithingTopLevelImprovementPanelInventoryBackpack,
    ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryBackpack
  }
  for x = 1,#inv do
    local puffer = inv[x].dataTypes[1].setupCallback
    inv[x].dataTypes[1].setupCallback = function(control,slot,...)
      puffer(control,slot,...)
      CS.SetItemMark(control,1)
    end
  end
    local puffer1 = ZO_LootAlphaContainerList.dataTypes[1].setupCallback
    ZO_LootAlphaContainerList.dataTypes[1].setupCallback = function(control,slot,...)
    puffer1(control,slot,...)
    CS.SetItemMark(control,2)
  end
end
function CS.UpdateGuildStore()
  if not IsInGamepadPreferredMode() then
    local puffer = TRADING_HOUSE.searchResultsList.dataTypes[1].setupCallback
    TRADING_HOUSE.searchResultsList.dataTypes[1].setupCallback = function(control,slot,...)
      puffer(control,slot,...)
      CS.SetItemMark(control,3)
    end
  end
end

--Finds and adds multiple items to research grid
function CS.AddResearchItems(items,bag_data)
  if not bag_data then
    bag_data = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_WORN,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK)
  end
  for index,data in pairs (bag_data) do
    if next(items) == nil then
      break
    end
    local link = GetItemLink(data.bagId,data.slotIndex)
    --Skip non-equipment
    if CS.IsValidEquip(GetItemLinkEquipType(link)) then
      local craft,line,trait = CS.GetTrait(link)
      local locked = CS.IsLocked(data.bagId,data.slotIndex)
      if not locked then
        --Cycle through items
        for items_index,i_data in pairs(items) do
          if i_data.craft == craft and i_data.line == line and i_data.trait == trait then
            table.remove(items,items_index)
            CS.UpdateStored('added',data)
            break
          end
        end
      end
    end
  end
end

--Finds and adds an item to research grid
function CS.AddResearchItem(craft,line,trait,bag_data)
  if not bag_data then
    bag_data = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_WORN,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK)
  end
  local bag,slot = CS.ScanBagResearch(craft,line,trait,bag_data)
  if bag then
    --Find its shared location
    for index,data in pairs (bag_data) do
      if data.bagId == bag and data.slotIndex == slot then
        CS.UpdateStored('added',data)
        break
      end
    end
  end
end

--Removes lost and locked items from research
function CS.RepairStored()
  --Build a list of possible items
  local bag_data = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_WORN,BAG_BACKPACK,BAG_BANK,BAG_SUBSCRIBER_BANK)
  local item_queue = {}
  --Cycle through all crafts
  for craft,data in pairs(CS.Account.crafting.stored) do
    --Cycle through all lines
    for line,ldata in pairs(CS.Account.crafting.stored[craft]) do
      --Cycle through all traits
      for trait,tdata in pairs(CS.Account.crafting.stored[craft][line]) do
        --Found an item
        if tdata.id ~= nil then
          --Check if this player owns it
          if tdata.owner == CS.CurrentPlayer or tdata.owner == CS.Lang.en.bank then
            --Use unique ID to check against accessible data
            local bag,slot = CS.ScanUidBag(tdata.id,bag_data)
            if not bag or CS.IsLocked(bag,slot) then
              CS.Account.crafting.stored[craft][line][trait] = {}
              item_queue[#item_queue+1] = {}
              item_queue[#item_queue].craft = craft
              item_queue[#item_queue].line = line
              item_queue[#item_queue].trait = trait
            end
          end
        end
      end
    end
  end
  --Find replacements
  CS.AddResearchItems(item_queue,bag_data)
  ReloadUI("ingame")
end

function CS.UpdateStored(action,data,replace)
  if not replace then replace = false end
  local link, owner = data.lnk, CS.CurrentPlayer
  local craft,line,trait = CS.GetTrait(link)
  -- catch invalid traits
  if craft == false then return end
  local function CompareItem(craft,line,trait,q1,l1,v1)
    -- safety check due to Dragonhold quests
    if CS.NilCheck(CS.Account.crafting.stored,{},craft,line,trait) == {} then
      return true
    elseif CS.Account.crafting.stored[craft][line][trait] == nil or not CS.Account.crafting.stored[craft][line][trait].link then
      return true
    else
      local q2 = GetItemLinkQuality(CS.Account.crafting.stored[craft][line][trait].link)
      local l2 = GetItemLinkRequiredLevel(CS.Account.crafting.stored[craft][line][trait].link)
      local v2 = GetItemLinkRequiredChampionPoints(CS.Account.crafting.stored[craft][line][trait].link)
      if q1 < q2 then
        return true
      end
      if l1 < l2 then
        return true
      end
      if v1 < v2 then
        return true
      end
      return false
    end
  end
  if craft and line and trait then
    if action == 'added' then
      if data.bagId == BAG_BANK or data.bagId == BAG_SUBSCRIBER_BANK then
        owner = CS.Lang.en.bank
      end
      if IsHouseBankBag(data.bagId) then
        owner = CS.Lang.en.housebank
      end
      if data.bagId == BAG_GUILDBANK then
        owner = CS.Lang.en.guildbank
      end
      if data.bagId == BAG_VIRTUAL then
        owner = CS.Lang.en.craftbag
      end
      --Do not include locked items
      if not CS.IsLocked(data.bagId,data.slotIndex) and CompareItem(craft,line,trait,GetItemLinkQuality(link),GetItemLinkRequiredLevel(link),GetItemLinkRequiredChampionPoints(link)) then
        CS.Account.crafting.stored[craft][line][trait] = { link = link, owner = owner, id = data.uid }
      end
    end
    if action == 'removed' and CS.Account.crafting.stored[craft][line][trait].id == data.uid then
      CS.Account.crafting.stored[craft][line][trait] = {}
      --Attempt to replace it
      if replace then
        CS.AddResearchItem(craft,line,trait)
      end
    end
    CS.UpdatePanelIcon(craft,line,trait)
  end
end

--closes recipe window and removes anchors
function CS.CloseRecipeWindow()
  CraftStoreFixed_Recipe_Window:SetHidden(true)
  for x = 1,CraftStoreFixed_RecipePanelScrollChild:GetNumChildren() do
    CS.HideControl('CraftStoreFixed_RecipePanelScrollChildButton'..x)
  end
end

function CS.GetRecipeChild(id)
  local btn = WM:GetControlByName('CraftStoreFixed_RecipePanelScrollChildButton'..id)
  if btn == nil then
    btn = WM:CreateControl('CraftStoreFixed_RecipePanelScrollChildButton'..id,CraftStoreFixed_RecipePanelScrollChild,CT_BUTTON)
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 22)
    btn:SetDimensions(508,22)
    btn:SetFont('CraftStoreFixedFont')
    btn:SetHidden(true)
    btn:EnableMouseButton(2,true)
    btn:EnableMouseButton(3,true)
    btn:SetClickSound('Click')
    btn:SetMouseOverFontColor(1,0.66,0.2,1)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Recipe,'tl') end)
    btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown',function(self,button) CS.RecipeMark(self,button) end)
  elseif btn:GetAnchor() == false then
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 22)
  end
  return WM:GetControlByName('CraftStoreFixed_RecipePanelScrollChildButton'..id)
end

function CS.RecipeMark(control,button)
  local mark
  if button == 2 then
    CS.ToChat(control.data.link)
  else
    local tracked = CS.Account.cook.ingredients[control.data.id] or false
    if tracked then
      mark = ''
      CS.Account.cook.ingredients[control.data.id] = nil
    else
      mark = '|t22:22:esoui/art/inventory/newitem_icon.dds|t '
      CS.Account.cook.ingredients[control.data.id] = true
    end
    control:SetText(mark..'('..CS.Cook.recipe[control.data.rec].level..') '..CS.Cook.recipe[control.data.rec].name)
    zo_callLater(CS.UpdateIngredientTracking,500)
  end
end

function CS.RecipeShow(id,inc)
  local color, mark, control
  if CS.Account.cook.ingredients[CS.Cook.recipe[id].id] then
    mark = '|t22:22:esoui/art/inventory/newitem_icon.dds|t '
  else
    mark = ''
  end
  if CS.Cook.recipe[id].known then
    color = CS.Quality[CS.Cook.recipe[id].quality]
  else
    color = {1,0,0,1}
  end
  control = CS.GetRecipeChild(inc)
  control:SetNormalFontColor(color[1],color[2],color[3],color[4])
  control:SetText(mark..'('..CS.Cook.recipe[id].level..') '..CS.Cook.recipe[id].name)
  control:SetHidden(false)
  control.data = {link = CS.Cook.recipe[id].link, rec = id, id = CS.Cook.recipe[id].id, buttons = {CS.Loc.TT[7],CS.Loc.TT[6]}}
  return inc + 1
end

function CS.RecipeShowCategory(list)
  if list == nil or list > 16 then
    list = 1
  end
  local inc, known, total = 1, 0, 0
  for x = 1,CraftStoreFixed_RecipePanelScrollChild:GetNumChildren() do
    CS.HideControl('CraftStoreFixed_RecipePanelScrollChildButton'..x)
  end
  for id, recipe in pairs(CS.Cook.recipe) do
    if recipe.stat == list then
      if CS.Cook.recipe[id].known then
        known = known+1
      end
      total = total+1
      --If hide known is false and it is known, show it. If hide unknown is false and it is unknown, show it.
      if (not CS.Character.hideKnownRecipes and CS.Cook.recipe[id].known) or (not CS.Character.hideUnknownRecipes and not CS.Cook.recipe[id].known) then
        inc = CS.RecipeShow(id,inc)
      end
    end
  end
  CraftStoreFixed_RecipePanelScrollChild:SetHeight(inc * 22 - 13)
  CraftStoreFixed_RecipeHeadline:SetText(ZOSF('<<C:1>>',GetRecipeListInfo(list)))

  --If hiding both
  if CS.Character.hideKnownRecipes and CS.Character.hideUnknownRecipes then
    CraftStoreFixed_RecipeInfo:SetText('(0 / '..total..')')
  --If showing known/both
  elseif not CS.Character.hideKnownRecipes then
    CraftStoreFixed_RecipeInfo:SetText('('..known..' / '..total..')')
  --If only showing unknown
  elseif not CS.Character.hideUnknownRecipes  then
    CraftStoreFixed_RecipeInfo:SetText('('..(total-known)..' / '..total..')')
  end
  CS.Character.recipe = list
end

function CS.RecipeSearch()
  local search, inc, known = CraftStoreFixed_RecipeSearch:GetText(), 1, 0
  if search ~= '' then
    for x = 1,CraftStoreFixed_RecipePanelScrollChild:GetNumChildren() do
      local control = CS.GetRecipeChild(x)
      control:SetHidden(true)
    control:ClearAnchors()
      control.data = nil
    end
    for id, food in pairs(CS.Cook.recipe) do
      if string.find(string.lower(food.name),string.lower(search)) then
        inc,known = CS.RecipeShow(id,inc,known)
      end
    end
    CraftStoreFixed_RecipePanelScrollChild:SetHeight(inc * 22 - 13)
    CraftStoreFixed_RecipeHeadline:SetText(CS.Loc.searchfor)
    CraftStoreFixed_RecipeInfo:SetText(search..' ('..(inc - 1)..')')
  end
end
function CS.RecipeLearned(list,id)
  local link = GetRecipeResultItemLink(list,id,LINK_STYLE_DEFAULT)
  if link then
    for id, recipe in pairs(CS.Cook.recipe) do
      if recipe.result == link then
        CS.Cook.recipe[id].known = true
        CS.Data.cook.knowledge[CS.CurrentPlayer][CS.Cook.recipe[id].id] = true
        break
      end
    end
  end
end

CS.selectedControl = nil

function CS.GetCookChild(id)
  local btn = WM:GetControlByName('CraftStoreFixed_CookFoodSectionScrollChildButton'..id)
  if btn == nil then
    btn = WM:CreateControl('CraftStoreFixed_CookFoodSectionScrollChildButton'..id,CraftStoreFixed_CookFoodSectionScrollChild,CT_BUTTON)
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 24)
    btn:SetDimensions(508,24)
    btn:SetFont('ZoFontGame')
    btn:EnableMouseButton(2,true)
    btn:EnableMouseButton(3,true)
    btn:SetClickSound('Click')
    btn:SetMouseOverFontColor(1,0.66,0.2,1)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Cook,'tl') end)
    btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown',function(self,button) CS.CookStart(self,button) end)
  elseif btn:GetAnchor() == false then
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 24)
  end
  return WM:GetControlByName('CraftStoreFixed_CookFoodSectionScrollChildButton'..id)
end

function CS.CookStart(control, button, isEnchanting)
  if not control then
    return
  end
  if isEnchanting == nil then
    isEnchanting = false
  end
  local notpreview = true

  if button == 3 then
    local idx = control.data.list..'_'..control.data.id
    local  _,_,_,_,_,_,tradeType = GetRecipeInfo(control.data.list,control.data.id)
    if CS.Character.favorites[tradeType][idx] then
      CS.Character.favorites[tradeType][idx] = nil
    else
      CS.Character.favorites[tradeType][idx] = {control.data.list, control.data.id}
    end
    CS.CookShowRecipe(control,control.data.list,control.data.id,0,sound,tradeType==CRAFTING_TYPE_ENCHANTING)
    return
  end
  if notpreview and control.data.craftable then
    if GetNumBagFreeSlots(BAG_BACKPACK) > 0 then
      local amount = isEnchanting and (tonumber(CraftStoreFixed_RuneAmount:GetText()) or 1) or (tonumber(CraftStoreFixed_CookAmount:GetText()) or 1)
      --changed from all to bulk
      if button == 2 then
        amount = CS.Account.options.bulkcraftlimit
        if amount > control.data.crafting[2] then
          amount = control.data.crafting[2]
        end
      end
      if amount > MAXCRAFT then
        amount = MAXCRAFT
        if amount > control.data.crafting[2] then
          amount = control.data.crafting[2]
        end
      end
      if isEnchanting then
        CraftStoreFixed_RuneAmount:SetText(amount)
      else
        CraftStoreFixed_CookAmount:SetText(amount)
      end
      CraftProvisionerItem(control.data.list, control.data.id, amount)
      PlaySound(control.data.sound)
    else
      CS.Chat:Print(CS.Loc.nobagspace)
    end
  end
end

function CS.CookShowRecipe(control,list,id,inc,sound,enchanting)
  if not control then
    return
  end
  local known, name, numIngredients, pLev, qLev = GetRecipeInfo(list,id)
  local mark = ''
  if known then
    local fault, maxval, ing = false, 999999, {}
    local link = GetRecipeResultItemLink(list,id,LINK_STYLE_DEFAULT)
    local level = GetItemLinkRequiredLevel(link)
    local levelcp = GetItemLinkRequiredChampionPoints(link)
    if levelcp>0 then
      level = CS.ChampionPointsTexture..levelcp
    end
    for num = 1, numIngredients do
      local count, color = GetCurrentRecipeIngredientCount(list,id,num)
    local _,_,qtyReq = GetRecipeIngredientItemInfo(list,id,num)
      if count < qtyReq then
        color = 'FF0000'; fault = true
      else
        color = '00FF00'
      end
      if (count/qtyReq) < maxval then
        maxval = math.floor(count/qtyReq)
      end
      table.insert(ing,ZOSF((qtyReq > 1 and (qtyReq .. 'x ') or '') .. '<<C:1>> |c<<2>>(<<3>>)|r',GetRecipeIngredientItemLink(list,id,num,LINK_STYLE_DEFAULT),color,count))
    end

    local craft_amount = {CraftStoreFixed_CookAmount,maxval}
    --Handles enchanting being the furniture source
    if enchanting then
      craft_amount = {CraftStoreFixed_RuneAmount,maxval}
      if CS.Character.favorites[CRAFTING_TYPE_ENCHANTING][list..'_'..id] then
        mark = '|t16:16:esoui/art/characterwindow/equipmentbonusicon_full.dds|t '
      else
        mark = ''
      end
    else
      if CS.Character.favorites[CRAFTING_TYPE_PROVISIONING][list..'_'..id] then
        mark = '|t16:16:esoui/art/characterwindow/equipmentbonusicon_full.dds|t '
      else
        mark = ''
      end
    end
    control:SetText(ZOSF(mark..'(<<1>>) <<C:2>> |c666666(<<3>>)|r',level,name,maxval))
    if fault or pLev > CS.Cook.craftLevel or qLev > CS.Cook.qualityLevel then
      control:SetNormalFontColor(1,0,0,1)
      fault = true
    else
      local color = GetItemLinkQuality(link)
      control:SetNormalFontColor(CS.Quality[color][1],CS.Quality[color][2],CS.Quality[color][3],1)
    end
    control.data = {id = id, list = list, link = link, sound = sound, crafting = craft_amount, addline = {table.concat(ing,'\n')}, craftable = not fault}
    control:SetHidden(false)
    return inc + 1
  end
  return inc
end

function CS.CookShowCategory(list,override)
  local lang = GetCVar('language.2')
  if not list then
    return
  end
  if override == nil then
    override = true
  end
  --handle maintaining search
  local search = CraftStoreFixed_CookSearch:GetText()
  if search ~= '' and search ~= (GetString(SI_GAMEPAD_HELP_SEARCH) .. "...") and override == false then
    CS.CookSearchRecipe()
  else
    CraftStoreFixed_CookSearch:SetText(GetString(SI_GAMEPAD_HELP_SEARCH) .. "...")
    local inc, control, name, num = 1
    for x = 1,CraftStoreFixed_CookFoodSectionScrollChild:GetNumChildren() do
      CS.HideControl('CraftStoreFixed_CookFoodSectionScrollChildButton'..x)
    end
    -- cooking favorites only
    if list == 17 then
      name = CS.Loc.TT[11]
      for _,val in pairs(CS.Character.favorites[CRAFTING_TYPE_PROVISIONING]) do
        if select(6,GetRecipeInfo(val[1],val[2])) ~= PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING then
          control = CS.GetCookChild(inc)
          inc = CS.CookShowRecipe(control,val[1],val[2],inc)
        end
        if inc > CraftStoreFixed_CookFoodSectionScrollChild:GetNumChildren() then
          break
        end
      end
    -- furniture favorites only
    elseif list == 20 then
      name = CS.Loc.TT[24] .. ' ' .. CS.Loc.TT[11]
      for _,val in pairs(CS.Character.favorites[CRAFTING_TYPE_PROVISIONING]) do
        local  _,_,_,_,_,ingredientType,tradeType = GetRecipeInfo(val[1],val[2])
        if ingredientType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING and tradeType == CRAFTING_TYPE_PROVISIONING then
          control = CS.GetCookChild(inc)
          inc = CS.CookShowRecipe(control,val[1],val[2],inc)
        end
        if inc > CraftStoreFixed_CookFoodSectionScrollChild:GetNumChildren() then
          break
        end
      end
    elseif list == 18 then
      name = CS.Loc.TT[23]
      CS.GetQuest()
      if CS.Quest[CRAFTING_TYPE_PROVISIONING] then
        local lists = {1,2,3,8,9,10}
        for list_num=1,#lists do
          local _,num,_,_,_,_,sound = GetRecipeListInfo(lists[list_num])
          for id = num, 1, -1 do
            local _, name = GetRecipeInfo(lists[list_num],id)
            for _, step in pairs(CS.Quest[CRAFTING_TYPE_PROVISIONING].work) do
              --Remove hyphens, capitalization and control characters
              local temp_step = step:gsub("-"," "):gsub("%^%a*",""):lower()
              local temp_name = name:gsub("-"," "):gsub("%^%a*",""):lower()
              --German adjustments
              if lang == 'de' then
                --Remove trailing s
                temp_name = temp_name:gsub("s$","")
                --Prepare step for modified matching
                local temp_word = ""
                local new_temp_step = ""
                for word in string.gmatch(temp_step, "%a+") do
                  temp_word = word:gsub(".$",".")
                  new_temp_step = new_temp_step .. " " .. temp_word
                end
                temp_step = new_temp_step
                --Prepare name for modified matching
                local new_temp_name = ""
                for word in string.gmatch(temp_name, "%a+") do
                  temp_word = word:gsub(".$",".")
                  new_temp_name = new_temp_name .. " " .. temp_word
                end
                temp_name = new_temp_name
              end
              local res1, res2 = string.find(temp_step, temp_name)
              if ((res1 == CS.Loc.provisioningWritOffset and lang == 'en') or (res1 and lang ~= 'en')) and res2 ~= 0 then
                control = CS.GetCookChild(inc)
                inc = CS.CookShowRecipe(control,lists[list_num],id,inc,sound)
              end
            end
          end
        end
      end
    --Furniture
    elseif list == 19 then
      name = CS.Loc.TT[24]
      for cat = 17,GetNumRecipeLists() do
        local _,num,_,_,_,_,sound = GetRecipeListInfo(cat)
        for id = num, 1, -1 do
          local _, _, _, _, _, _, crafttype = GetRecipeInfo(cat, id);
          if crafttype == RECIPE_CRAFTING_SYSTEM_PROVISIONING_DESIGNS then
            control = CS.GetCookChild(inc)
            inc = CS.CookShowRecipe(control,cat,id,inc,sound)
          end
        end
      end
    else
      local _,num,_,_,_,_,sound = GetRecipeListInfo(list)
      for id = num, 1, -1 do
        control = CS.GetCookChild(inc)
        inc = CS.CookShowRecipe(control,list,id,inc,sound)
      end
    end

    CraftStoreFixed_CookFoodSectionScrollChild:SetHeight(inc * 24 - 15)
    CraftStoreFixed_CookHeadline:SetText(ZOSF('<<C:1>>',name))
    CraftStoreFixed_CookInfo:SetText(CS.Cook.category[list])
    CS.Character.recipe = list
  end
end

function CS.CookSearchRecipe()
  local search, inc, control = CraftStoreFixed_CookSearch:GetText(), 1
  if search ~= '' then
    for x = 1,CraftStoreFixed_CookFoodSectionScrollChild:GetNumChildren() do
      CS.HideControl('CraftStoreFixed_CookFoodSectionScrollChildButton'..x)
    end
    for list = 1, GetNumRecipeLists() do
      local _,num = GetRecipeListInfo(list)
      for id = num, 1, -1 do
        local known, name,_,_,_,_,tradeSkill = GetRecipeInfo(list,id)
        if tradeSkill == CRAFTING_TYPE_PROVISIONING and string.find(string.lower(name),string.lower(search)) and known then
          control = CS.GetCookChild(inc)
          inc = CS.CookShowRecipe(control,list,id,inc)
          if inc > CraftStoreFixed_CookFoodSectionScrollChild:GetNumChildren() then
            break
          end
        end
      end
    end
    CraftStoreFixed_CookFoodSectionScrollChild:SetHeight(inc * 23 - 10)
    CraftStoreFixed_CookHeadline:SetText(CS.Loc.searchfor)
    CraftStoreFixed_CookInfo:SetText(search)
  end
end

function CS.RuneCreate(control,button)
  if not control then
    return
  end
  if control.data.list ~= nil then
    return CS.CookStart(control,button,true)
  end
  if CS.Extern and button == 2 then
    CS.ToChat(control.data.link); return
  end
  if button == 3 then
    local id, idx = control.data.glyph, control.data.glyph..'_'..control.data.quality..'_'..control.data.level
    if CS.Character.favorites[CRAFTING_TYPE_ENCHANTING][idx] then
      CS.Character.favorites[CRAFTING_TYPE_ENCHANTING][idx] = nil
    else
      CS.Character.favorites[CRAFTING_TYPE_ENCHANTING][idx] = { id, control.data.level, control.data.quality, control.data.essence, control.data.potencyType }
    end
    CS.RuneShow(control.data.nr ,id, control.data.quality, control.data.level, control.data.essence, control.data.potencyType)
    return
  end
  if control.data.craftable and not CS.Extern then
    if GetNumBagFreeSlots(BAG_BACKPACK) > 0 then
      local amount = (tonumber(CraftStoreFixed_RuneAmount:GetText()) or 1)
      -- changed "all" (control.data.crafting[2]) to "10" (CS.Account.options.bulkcraftlimit)
      if button == 2 then
        -- check if that's more than can be made
        amount = CS.Account.options.bulkcraftlimit
        if CS.Account.options.bulkcraftlimit > control.data.crafting[2] then
          amount = control.data.crafting[2]
        end
      end
      if amount > MAXCRAFT then
        amount = MAXCRAFT
        if amount > control.data.crafting[2] then
          amount = control.data.crafting[2]
        end
      end
      CraftStoreFixed_RuneAmount:SetText(amount)
      local bagP, slotP = CS.ScanBag(control.data.potency)
      local bagE, slotE = CS.ScanBag(control.data.essence)
      local bagA, slotA = CS.ScanBag(control.data.aspect)
      CraftEnchantingItem(bagP,slotP,bagE,slotE,bagA,slotA,amount)
      if CS.Account.options.playrunevoice then
        local soundP, lengthP = GetRunestoneSoundInfo(bagP,slotP)
        local soundE, lengthE = GetRunestoneSoundInfo(bagE,slotE)
        local soundA, _ = GetRunestoneSoundInfo(bagA,slotA)
        PlaySound(soundP)
        zo_callLater(function() PlaySound(soundE) end, lengthP)
        zo_callLater(function() PlaySound(soundA) end, lengthE + lengthP)
      end
    else CS.Chat:Print(CS.Loc.nobagspace) end
  end
end

function CS.RuneCheckGlyph(glyphs,link)
  local found = 0
  --Find if the glyph is already in the table
  for ind, data in pairs(glyphs) do
    local _,_,_,item_id1 = ZO_LinkHandler_ParseLink(data.link)
    local _,_,_,item_id2 = ZO_LinkHandler_ParseLink(link)
    local level1,cplevel1 = GetItemLinkGlyphMinLevels(data.link)
    local level2,cplevel2 = GetItemLinkGlyphMinLevels(link)
    --Check for matching crafted state, quality, level and ID
    if IsItemLinkCrafted(data.link) == IsItemLinkCrafted(link) and
      data.quality == GetItemLinkQuality(link) and
      level1 == level2 and cplevel1 == cplevel2 and
      item_id1 == item_id2 then
      found = ind
      break
    end
  end
  return found
end

function CS.GlyphSort(a,b)
  --Lowest level first
  if a.level == b.level then
    --Alphabetical names
    if a.name == b.name then
      --Lowest quality first
      return a.quality < b.quality
    else
      return a.name < b.name
    end
  else return a.level < b.level end
end

function CS.RuneGetGylphs()
  local bag = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_BANK,BAG_SUBSCRIBER_BANK,BAG_BACKPACK,BAG_VIRTUAL)
  local glyphs = {}
  for _, data in pairs(bag) do
    local item = data.itemType
    local link = GetItemLink(data.bagId, data.slotIndex)
    local icon = data.iconFile
    if (item == ITEMTYPE_GLYPH_ARMOR or item == ITEMTYPE_GLYPH_WEAPON or item == ITEMTYPE_GLYPH_JEWELRY) and not CS.IsLocked(data.bagId, data.slotIndex) then
      local glyph_position = CS.RuneCheckGlyph(glyphs,link)
      --Check if it's already in the list
      if glyph_position == 0 then
        --Determine level
        local level,cplevel = GetItemLinkGlyphMinLevels(link)
        if not level and not cplevel then
          CS.Chat:Print('Unknown level: ' .. link)
        else
          if not level then
            level = cplevel+50
          end
          table.insert(glyphs,{ name = ZOSF('<<C:1>>',data.name), icon = icon, link = link, quality = data.quality, level=level, location = {{data.bagId,data.slotIndex}}, crafted = IsItemLinkCrafted(link) })
        end
      else
      --Add to the location
        table.insert(glyphs[glyph_position]['location'],{data.bagId,data.slotIndex})
      end
    end
  end
  --Sort by level, then alphabetically
  table.sort(glyphs,CS.GlyphSort)
  return glyphs
end

function CS.RuneGetLink(id,quality,rank)
  local color = {19,19,19,19,19,19,19,19,19,115,117,119,121,271,307,365,[0] = 0}
  local adder = {1,1,1,1,1,1,1,1,1,10,10,10,10,1,1,1,[0] = 0}
  local level = {5,10,15,20,25,30,35,40,45,50,50,50,50,50,50,50,[0] = 0}
  return ('|H1:item:%u:%u:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(id,(color[rank] + quality * adder[rank]),level[rank])
end

function CS.RuneSetValue(key,value,ptype)
  if key == 1 then
    CS.Character.enchant = value
  elseif key == 2 then
    CS.Character.aspect = value; CraftStoreFixed_RuneLevelButton:SetNormalFontColor(CS.Quality[value][1],CS.Quality[value][2],CS.Quality[value][3],1)
  elseif key == 3 then
    CS.Character.potency = value;
    if ptype then
      CS.Character.potencytype = ptype
    end
  elseif key == 4 then
    CS.Character.essence = value
  elseif key == 5 then
    CS.Character.runemode = 'search'
  elseif key == 6 then
    CS.Character.runemode = 'craft'
  elseif key == 7 then
    CS.Character.runemode = 'refine'
  elseif key == 9 then
    CS.Character.runemode = 'selection'
  elseif key == 10 then
    CS.Character.runemode = 'favorites'
  elseif key == 11 then
    CS.Character.runemode = 'writ'
  elseif key == 12 then
    CS.Character.runemode = 'furniture'
  elseif key == 13 then
    CS.Character.runemode = 'furniturefavorites'
  end
end

--sets hidden and clears anchor
function CS.HideControl(controlName)
  local control = WM:GetControlByName(controlName)
  if control ~= nil then
    control:SetHidden(true)
    control:ClearAnchors()
  end
end

--creates rune child button if it doesn't exist
function CS.GetRuneChild(id)
  btn = WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChildButton'..id)
  --if it doesn't exist, create it
  if btn == nil then
    btn = WM:CreateControl('CraftStoreFixed_RuneGlyphSectionScrollChildButton'..id,CraftStoreFixed_RuneGlyphSectionScrollChild,CT_BUTTON)
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 30)
    btn:SetDimensions(508,30)
    btn:SetFont('ZoFontGame')
    btn:EnableMouseButton(2,true)
    btn:EnableMouseButton(3,true)
    btn:SetClickSound('Click')
    btn:SetMouseOverFontColor(1,0.66,0.2,1)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Rune,'tl') end)
    btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown',function(self,button) CS.RuneCreate(self,button) end)
  elseif btn:GetAnchor() == false then
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 30)
  end
  return WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChildButton'..id)
end

function CS.RuneShow(nr,id,quality,level,essence,potencytype)
  local bank, bag, virt, mark, control, color, maxval, fault, addline, countcol, col
  control = CS.GetRuneChild(nr)
  local link = CS.RuneGetLink(id,quality,level)
  local icon = GetItemLinkInfo(link)
  local basename = ZOSF('<<C:1>>',GetItemLinkName(('|H0:item:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(id)))
  local potencyId, essenceId, aspectId = CS.Rune.rune[51][potencytype][level], essence, CS.Rune.rune[52][quality]
  local potencyLink, essenceLink,aspectLink = CS.RuneGetLink(potencyId,1,1), CS.RuneGetLink(essenceId,1,1), CS.RuneGetLink(aspectId,quality,1)
  local potencySkill, aspectSkill = CS.Rune.skillLevel[level], quality - 1
  bag, bank, virt = GetItemLinkStacks(potencyLink)
  local potencyCount = bag + bank + virt
  bag, bank, virt = GetItemLinkStacks(essenceLink)
  local essenceCount = bag + bank + virt
  bag, bank, virt = GetItemLinkStacks(aspectLink)
  local aspectCount = bag + bank+ virt
  maxval = math.min(potencyCount, essenceCount, aspectCount)
  if maxval == 0 or (aspectSkill > CS.Rune.aspectSkill or potencySkill > CS.Rune.potencySkill) then
    color = {1,0,0}; fault = true
  else
    color = CS.Quality[quality]; fault = false
  end
  if CS.Character.favorites[CRAFTING_TYPE_ENCHANTING][id..'_'..quality..'_'..level] then
    mark = '|t16:16:esoui/art/characterwindow/equipmentbonusicon_full.dds|t '
  else
    mark = ''
  end
  control:SetText(mark..'|t24:24:'..icon..'|t '..basename..' |c666666('..maxval..')|r')
  control:SetNormalFontColor(color[1],color[2],color[3],1)
  if potencyCount == 0 or potencySkill > CS.Rune.potencySkill then
    col = 'FF0000'
  else
    col = 'FFFFFF'
  end
  if potencyCount == 0 then
    countcol = 'FF0000'
  else
    countcol = '00FF00'
  end
  addline = '|t22:22:'..GetItemLinkInfo(potencyLink)..'|t |c'..col..ZOSF('<<C:1>>',GetItemLinkName(potencyLink))..' |c'..countcol..'('..potencyCount..')|r'
  if essenceCount == 0 then
    col = 'FF0000'
  else
    col = 'FFFFFF'
  end
  if essenceCount == 0 then
   countcol = 'FF0000'
  else
    countcol = '00FF00'
  end
  addline = addline..'|r  |t22:22:'..GetItemLinkInfo(essenceLink)..'|t |c'..col..ZOSF('<<C:1>>',GetItemLinkName(essenceLink))..' |c'..countcol..'('..essenceCount..')|r'
  if aspectCount == 0 or aspectSkill > CS.Rune.aspectSkill then
    col = 'FF0000'
  else
    col = CS.QualityHex[quality]
  end
  if aspectCount == 0 then
    countcol = 'FF0000'
  else
    countcol = '00FF00'
  end
  addline = addline..'|r  |t22:22:'..GetItemLinkInfo(aspectLink)..'|t |c'..col..ZOSF('<<C:1>>',GetItemLinkName(aspectLink))..' |c'..countcol..'('..aspectCount..')|r'
  control:SetHidden(false)
  control.data = {
    nr = nr, link = link, addline = {addline}, crafting = {CraftStoreFixed_RuneAmount,maxval}, craftable = not fault,
    quality = quality, level = level, glyph = id, potency = potencyId, essence = essenceId, aspect = aspectId, potencyType = potencytype
  }
end

function CS.RuneShowCategory()
  local useCSRune = CS.Account.options.userune
  if (CS.Account.options.userune and CS.Account.options.userunecreation) or CS.Extern then
    local count = 1
    CraftStoreFixed_RuneInfo:SetText(GetString(SI_ENCHANTING_CREATION))
    local function tsort(a,b)
      return a[4] < b[4]
    end
    table.sort(CS.Rune.glyph[CS.Character.enchant],tsort)
    for _,glyph in pairs(CS.Rune.glyph[CS.Character.enchant]) do
      CS.RuneShow(count,glyph[1],CS.Character.aspect,CS.Character.potency,glyph[2],glyph[3])
      count = count + 1
    end
    CraftStoreFixed_RuneGlyphSectionScrollChild:SetHeight(#CS.Rune.glyph[CS.Character.enchant] * 30 + 20)
    if CS.Extern then
      CS.Character.enchant = ITEMTYPE_GLYPH_ARMOR
    end
  else
    useCSRune = false
    ZO_MenuBar_SelectDescriptor(ENCHANTING.modeBar, ENCHANTING_MODE_CREATION)
    ZO_EnchantingTopLevelRuneSlotContainer:SetHidden(false)
    ZO_EnchantingTopLevelInventory:SetHidden(false)
    ZO_EnchantingTopLevelModeMenu:SetHidden(false)
  end
  if not CS.Extern then
    CS.RuneHideVanillaUI(useCSRune)
  end
  CS.RuneInitialize(useCSRune)
end

function CS.RuneRefining()
    if CS.Rune.refine.glyphs[1] then
      if GetNumBagFreeSlots(BAG_BACKPACK) >= 3 or (tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_ADD_TO_CRAFT_BAG)) == 1 and IsESOPlusSubscriber()) then
        ExtractEnchantingItem(CS.Rune.refine.glyphs[1].location[1][1], CS.Rune.refine.glyphs[1].location[1][2])
        PlaySound('Enchanting_Extract_Start_Anim')
    --Only remove the table if all of the stack is gone
    if #CS.Rune.refine.glyphs[1].location == 1 then
      table.remove(CS.Rune.refine.glyphs,1)
    else
    --Remove only the used glyph
      table.remove(CS.Rune.refine.glyphs[1].location,1)
    end
      else CS.Chat:Print(CS.Loc.nobagspace) end
    end
  --Update space
    CS.InventorySpace(CraftStoreFixed_RuneSpaceButtonName)
end

function CS.RuneRefine(control,button)
  --Check if the whole stack is being done
  if button == 2 then
    --Build a special refine table for just this item
    local glyphs = {}
    table.insert(glyphs,{ location = control.data.location, crafted = IsItemLinkCrafted(control.data.link) })
    CS.Rune.refine = {glyphs = glyphs, crafted = true}
    CS.RuneRefining()
  elseif GetNumBagFreeSlots(BAG_BACKPACK) >= 3 or (tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_ADD_TO_CRAFT_BAG)) == 1 and IsESOPlusSubscriber()) then
    ExtractEnchantingItem(control.data.location[1][1], control.data.location[1][2])
    PlaySound('Enchanting_Extract_Start_Anim')
  else CS.Chat:Print(CS.Loc.nobagspace) end
  --Update space
    CS.InventorySpace(CraftStoreFixed_RuneSpaceButtonName)
end
function CS.RefineAll(_,button)
  CS.Rune.refine = {glyphs = CS.RuneGetGylphs(), crafted = (button == 2)}
  if #CS.Rune.refine.glyphs > 0 then
    local remove = true
    while remove do
      if CS.Rune.refine.glyphs[1] and CS.Rune.refine.glyphs[1].crafted and not CS.Rune.refine.crafted then
        table.remove(CS.Rune.refine.glyphs,1)
      else
        remove = false
      end
    end

    CS.RuneRefining()
  end
end

function CS.RuneShowMode(atStationOnly)
    if atStationOnly == nil then
      atStationOnly = false
    end
    if (atStationOnly and not CS.Extern) or not atStationOnly then
        CraftStoreFixed_RuneGlyphDivider:SetHidden(true)
        CraftStoreFixed_RuneGlyphSectionScrollChildRefine:SetHidden(true)
        CraftStoreFixed_RuneGlyphSectionScrollChildSelection:SetHidden(true)
        CraftStoreFixed_RuneRefineAllButton:SetHidden(true)
        for x = 1,CraftStoreFixed_RuneGlyphSectionScrollChild:GetNumChildren() do CS.HideControl('CraftStoreFixed_RuneGlyphSectionScrollChildButton'..x) end
        if CS.Character.runemode == 'craft' then
          ENCHANTING.enchantingMode = ENCHANTING_MODE_CREATION
          CS.RuneShowCategory()
        elseif CS.Character.runemode == 'search' then
          CS.RuneSearch()
        elseif CS.Character.runemode == 'refine' then
          ENCHANTING.enchantingMode = ENCHANTING_MODE_EXTRACTION
          CS.RuneShowRefine()
        elseif CS.Character.runemode == 'selection' then
          CS.RuneShowSelection()
        elseif CS.Character.runemode == 'favorites' then
          CS.RuneShowFavorites()
        elseif CS.Character.runemode == 'furniturefavorites' then
          CS.RuneShowFurnitureFavorites()
        elseif CS.Character.runemode == 'writ' then
          CS.RuneShowWrit()
        elseif CS.Character.runemode == 'furniture' then
          ENCHANTING.enchantingMode = ENCHANTING_MODE_RECIPES
          CS.RuneShowFurniture()
        end
    end
end

function CS.RuneShowRefine()
  local useCSRune = CS.Account.options.userune
  if CS.Account.options.userune and CS.Account.options.useruneextraction then
    CraftStoreFixed_RuneInfo:SetText(GetString(SI_ENCHANTING_EXTRACTION))
    CraftStoreFixed_RuneGlyphSectionScrollChildRefine:SetHidden(false)
    CraftStoreFixed_RuneRefineAllButton:SetHidden(false)
    for x = 1, CraftStoreFixed_RuneGlyphSectionScrollChildRefine:GetNumChildren() do
      CraftStoreFixed_RuneGlyphSectionScrollChildRefine:GetChild(x):SetHidden(true)
    end
    local count, crafted = 0
    for x, glyph in pairs(CS.RuneGetGylphs()) do
      local c = WM:GetControlByName('CraftStoreFixed_GlyphControl'..x)
      if not c then
        c = WM:CreateControl('CraftStoreFixed_GlyphControl'..x,CraftStoreFixed_RuneGlyphSectionScrollChildRefine,CT_BUTTON)
        c:SetAnchor(TOPLEFT,CraftStoreFixed_RuneGlyphSectionScrollChild,TOPLEFT,8,5 + (x - 1) * 30)
        c:SetDimensions(508,30)
        c:SetFont('ZoFontGame')
        c:SetClickSound('Click')
        c:SetMouseOverFontColor(1,0.66,0.2,1)
        c:EnableMouseButton(2,true)
        c:SetHorizontalAlignment(0)
        c:SetVerticalAlignment(1)
        c:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Rune,'tl') end)
        c:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
        c:SetHandler('OnMouseDown',function(self,button) CS.RuneRefine(self,button) end)
      end
      if glyph.crafted then
        crafted = '|t22:22:esoui/art/treeicons/achievements_indexicon_crafting_up.dds|t '
      else
        crafted = ''
      end
      c:SetHidden(false)
      c:SetText(crafted..'|t24:24:'..glyph.icon..'|t '..glyph.name..' |c666666('..#glyph.location..')|r')
      c:SetNormalFontColor(CS.Quality[glyph.quality][1],CS.Quality[glyph.quality][2],CS.Quality[glyph.quality][3],1)
      c.data = { link = glyph.link, location= glyph.location, buttons = {CS.Loc.TT[8],CS.Loc.TT[28]} }
      count = count + 1
    end
    CraftStoreFixed_RuneGlyphSectionScrollChild:SetHeight(count * 30 + 20)
  else
    useCSRune = false
    ZO_MenuBar_SelectDescriptor(ENCHANTING.modeBar, ENCHANTING_MODE_EXTRACTION)
    ZO_EnchantingTopLevelExtractionSlotContainer:SetHidden(false)
    ZO_EnchantingTopLevelInventory:SetHidden(false)
    ZO_EnchantingTopLevelModeMenu:SetHidden(false)
  end

  CS.RuneHideVanillaUI(useCSRune)
  CS.RuneInitialize(useCSRune)

end

function CS.RuneShowSelection()
  local color, count = 'FFFFFF', 0
  local function RuneSelected()
    local essence = CS.SplitLink(CS.RuneGetLink(CS.Rune.rune[ITEMTYPE_ENCHANTING_RUNE_ESSENCE][CS.Character.essence],1,1),3)
    for _, enchant in pairs(CS.Rune.glyph) do
      for _, glyph in pairs(enchant) do
        if glyph[2] == essence and glyph[3] == CS.Character.potencytype then
          CS.RuneShow(1,glyph[1],CS.Character.aspect,CS.Character.potency,essence,glyph[3])
          return
        end
      end
    end
  end
  for x,rune in pairs(CS.Rune.rune[ITEMTYPE_ENCHANTING_RUNE_POTENCY][1]) do
    local link = CS.RuneGetLink(rune,1,1)
    local known = GetItemLinkEnchantingRuneName(link)
    local bag, bank, virt = GetItemLinkStacks(link)
    count = bag + bank + virt
    color = CS.Quality[GetItemLinkQuality(link)]
    if count == 0 then
      color = {0.4,0.4,0.4}
    end
    if not known then
      color = {1,0,0}
    end
    local btn = WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild1Selector'..x)
    if not btn then
      btn = WM:CreateControl('CraftStoreFixed_RuneGlyphSectionScrollChild1Selector'..x,CraftStoreFixed_RuneGlyphSectionScrollChildSelection,CT_BUTTON)
      btn:SetAnchor(3,nil,3,8,50 + (x-1) * 30)
      btn:SetDimensions(160,30)
      btn:SetFont('ZoFontGame')
      btn:EnableMouseButton(2,true)
      btn:SetClickSound('Click')
      btn:SetNormalFontColor(color[1],color[2],color[3],1)
      btn:SetMouseOverFontColor(1,0.66,0.2,1)
      btn:SetHorizontalAlignment(0)
      btn:SetVerticalAlignment(1)
      btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Rune,'tl') end)
      btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
      btn:SetHandler('OnMouseDown',function(self,button)
        if button == 1 then
          CS.RuneSetValue(3,x,1)
          CraftStoreFixed_RuneLevelButton:SetText(CS.Loc.level..': '..CS.Rune.level[x])
          CraftStoreFixed_RuneHighlight1:SetAnchor(2,WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild1Selector'..x),2,-14,0)
          RuneSelected()
        elseif button == 2 then
          CS.ToChat(link)
        end
      end)
    end
    btn:SetText('|t24:24:'..GetItemLinkInfo(link)..'|t '..ZOSF('<<C:1>>',GetItemLinkName(link))..' |c666666('..count..')')
    btn.data = { link = link, addline = {'|cFFAA33CraftStoreRune:|r '..CS.Loc.level..' '..CS.Rune.level[x]} }
  end
  for x,rune in pairs(CS.Rune.rune[ITEMTYPE_ENCHANTING_RUNE_POTENCY][2]) do
    local link = CS.RuneGetLink(rune,1,1)
    local known = GetItemLinkEnchantingRuneName(link)
    local bag, bank, virt = GetItemLinkStacks(link)
    count = bag + bank + virt
    color = CS.Quality[GetItemLinkQuality(link)]
    if count == 0 then
      color = {0.4,0.4,0.4}
    end
    if not known then
      color = {1,0,0}
    end
    local btn = WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild2Selector'..x)
    if not btn then
      btn = WM:CreateControl('CraftStoreFixed_RuneGlyphSectionScrollChild2Selector'..x,CraftStoreFixed_RuneGlyphSectionScrollChildSelection,CT_BUTTON)
      btn:SetAnchor(3,nil,3,170,50 + (x-1) * 30)
      btn:SetDimensions(160,30)
      btn:SetFont('ZoFontGame')
      btn:EnableMouseButton(2,true)
      btn:SetClickSound('Click')
      btn:SetNormalFontColor(color[1],color[2],color[3],1)
      btn:SetMouseOverFontColor(1,0.66,0.2,1)
      btn:SetHorizontalAlignment(0)
      btn:SetVerticalAlignment(1)
      btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Rune,'tl') end)
      btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
      btn:SetHandler('OnMouseDown',function(self,button)
        if button == 1 then
          CS.RuneSetValue(3,x,2)
          CraftStoreFixed_RuneLevelButton:SetText(CS.Loc.level..': '..CS.Rune.level[x])
          CraftStoreFixed_RuneHighlight1:SetAnchor(2,WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild2Selector'..x),2,-14,0)
          RuneSelected()
        elseif button == 2 then
          CS.ToChat(link)
        end
      end)
    end
    btn:SetText('|t24:24:'..GetItemLinkInfo(link)..'|t '..ZOSF('<<C:1>>',GetItemLinkName(link))..' |c666666('..count..')')
    btn.data = { link = link, addline = {'|cFFAA33CraftStoreRune:|r '..CS.Loc.level..' '..CS.Rune.level[x]} }
  end
  for x,rune in pairs(CS.Rune.rune[ITEMTYPE_ENCHANTING_RUNE_ESSENCE]) do
    local link = CS.RuneGetLink(rune,1,1)
    local known = GetItemLinkEnchantingRuneName(link)
    local bag, bank, virt = GetItemLinkStacks(link)
    count = bag + bank + virt
    color = CS.Quality[GetItemLinkQuality(link)]
    if count == 0 then
      color = {0.4,0.4,0.4}
    end
    if not known then
      color = {1,0,0}
    end
    local btn = WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild3Selector'..x)
    if not btn then
      btn = WM:CreateControl('CraftStoreFixed_RuneGlyphSectionScrollChild3Selector'..x,CraftStoreFixed_RuneGlyphSectionScrollChildSelection,CT_BUTTON)
      btn:SetAnchor(3,nil,3,332,50 + (x-1) * 30)
      btn:SetDimensions(160,30)
      btn:SetFont('ZoFontGame')
      btn:EnableMouseButton(2,true)
      btn:SetClickSound('Click')
      btn:SetNormalFontColor(color[1],color[2],color[3],1)
      btn:SetMouseOverFontColor(1,0.66,0.2,1)
      btn:SetHorizontalAlignment(0)
      btn:SetVerticalAlignment(1)
      btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Rune,'tl') end)
      btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
      btn:SetHandler('OnMouseDown',function(self,button)
        if button == 1 then
          CraftStoreFixed_RuneHighlight2:SetAnchor(2,WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild3Selector'..x),2,-14,0)
          CS.RuneSetValue(4,x)
          RuneSelected()
        elseif
        button == 2 then
          CS.ToChat(link)
        end
      end)
    end
    btn:SetText('|t24:24:'..GetItemLinkInfo(link)..'|t '..ZOSF('<<C:1>>',GetItemLinkName(link))..' |c666666('..count..')')
    btn.data = { link = link }
  end
  local dot = WM:GetControlByName('CraftStoreFixed_RuneHighlight1')
  if not dot then
    dot = WM:CreateControl('CraftStoreFixed_RuneHighlight1',CraftStoreFixed_RuneGlyphSectionScrollChildSelection,CT_TEXTURE)
    dot:SetAnchor(2,WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild'..CS.Character.potencytype..'Selector'..CS.Character.potency),2,-14,0)
    dot:SetDimensions(48,48)
    dot:SetColor(1,1,1,1)
    dot:SetTexture('esoui/art/quickslots/quickslot_highlight_blob.dds')
  end
  dot = WM:GetControlByName('CraftStoreFixed_RuneHighlight2')
  if not dot then
    dot = WM:CreateControl('CraftStoreFixed_RuneHighlight2',CraftStoreFixed_RuneGlyphSectionScrollChildSelection,CT_TEXTURE)
    dot:SetAnchor(2,WM:GetControlByName('CraftStoreFixed_RuneGlyphSectionScrollChild3Selector'..CS.Character.essence),2,-14,0)
    dot:SetDimensions(48,48)
    dot:SetColor(1,1,1,1)
    dot:SetTexture('esoui/art/quickslots/quickslot_highlight_blob.dds')
  end
  CraftStoreFixed_RuneGlyphDivider:SetHidden(false)
  CraftStoreFixed_RuneGlyphSectionScrollChildSelection:SetHidden(false)
  CraftStoreFixed_RuneInfo:SetText(GetString(SI_CRAFTING_PERFORM_FREE_CRAFT))
  RuneSelected()
end

function CS.RuneSearch()
  local search, countRune, countFurniture, inc = CraftStoreFixed_RuneSearch:GetText(), 0,0,1
  if search == '' then
    return
  end

  for cat = 17,GetNumRecipeLists() do
    local _,num,_,_,_,_,sound = GetRecipeListInfo(cat)
    for id = num, 1, -1 do
      local known, name, _, _, _, _, crafttype = GetRecipeInfo(cat, id)
      if crafttype == RECIPE_CRAFTING_SYSTEM_ENCHANTING_SCHEMATICS and string.find(string.lower(name),string.lower(search)) and known then
        control =  CS.GetRuneChild(inc)
        inc = CS.CookShowRecipe(control,cat,id,inc,sound,true)
        countFurniture = countFurniture+1
      end
    end
  end
  for _,enchant in pairs(CS.Rune.glyph) do
    for _,glyph in pairs(enchant) do
      local basename = ZOSF('<<C:1>>',GetItemLinkName(('|H1:item:%u:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(glyph[1])))
      if string.find(string.lower(basename),string.lower(search)) then
        CS.RuneShow(inc + countRune,glyph[1],CS.Character.aspect,CS.Character.potency,glyph[2],glyph[3])
        countRune = countRune + 1
      end
    end
  end
  CraftStoreFixed_RuneGlyphSectionScrollChild:SetHeight((countRune * 24 + countFurniture * 30) + 20)
  CraftStoreFixed_RuneInfo:SetText(CS.Loc.searchfor..' '..search)
end

function CS.RuneShowFurniture()
  local useCSRune = CS.Account.options.userune
  if CS.Account.options.userune and CS.Account.options.userunerecipe then
    CraftStoreFixed_RuneInfo:SetText(CS.Loc.TT[24])
    local inc,count = 1,0
    for cat = 17,GetNumRecipeLists() do
    local _,num,_,_,_,_,sound = GetRecipeListInfo(cat)
    for id = num, 1, -1 do
      local _, _, _, _, _, _, crafttype = GetRecipeInfo(cat, id)
      if crafttype == RECIPE_CRAFTING_SYSTEM_ENCHANTING_SCHEMATICS then
      control =  CS.GetRuneChild(inc)
      inc = CS.CookShowRecipe(control,cat,id,inc,sound,true)
      count = count+1
      end
    end
    end
    CraftStoreFixed_RuneGlyphSectionScrollChild:SetHeight(inc * 30 + 20)
  else
    useCSRune = false
    ZO_MenuBar_SelectDescriptor(ENCHANTING.modeBar, ENCHANTING_MODE_RECIPES)
    ZO_ProvisionerTopLevel:SetHidden(false)
    ZO_EnchantingTopLevelExtractionSlotContainer:SetHidden(true)
    ZO_EnchantingTopLevelRuneSlotContainer:SetHidden(true)
    ZO_EnchantingTopLevelInventoryTabs:SetHidden(true)
    ZO_EnchantingTopLevelInventory:SetHidden(true)
  end
  CS.RuneHideVanillaUI(useCSRune)
  CS.RuneInitialize(useCSRune)
end


function CS.RuneShowWrit()
  CraftStoreFixed_RuneInfo:SetText(CS.Loc.TT[23])
  CS.GetQuest()

  local function GetLevelName(level)
    local basename = ZOSF('<<t:1>>', GetItemLinkName(CS.RuneGetLink(26580,0,0)))
    local basedata = { zo_strsplit(' ', basename) }
    local name = ZOSF('<<t:1>>', GetItemLinkName(CS.RuneGetLink(26580,3,level)))
    local namedata = { zo_strsplit(' ', name) }
    for j = #namedata, 1, -1 do
      for i = #basedata, 1, -1 do
        if namedata[j] == basedata[i] then
          table.remove(namedata, j)
          table.remove(basedata, i)
        end
      end
    end
    return ZOSF('<<C:1>>', table.concat(namedata,' '))
  end

  local function GetEssenceName(essence)
    local basename = ZOSF('<<t:1>>', GetItemLinkName(CS.RuneGetLink(68343,0,0)))
    local basedata = { zo_strsplit(' ', basename) }
    local name = ZOSF('<<t:1>>', GetItemLinkName(CS.RuneGetLink(essence,0,0)))
    local namedata = { zo_strsplit(' ', name) }
    for j = #namedata, 1, -1 do
      for i = #basedata, 1, -1 do
        if namedata[j] == basedata[i] then
          table.remove(namedata, j)
          table.remove(basedata, i)
        end
      end
    end
    return ZOSF('<<C:1>>', table.concat(namedata,' '))
  end

  local levels = {}
  for level=1,16 do
    levels[level] = GetLevelName(level)
  end

  local runes = {{id=26580,name="",essence="oko"},{id=26582,name="",essence="makko"},{id=26588,name="",essence="deni"}}
  for rune=1,#runes do
    runes[rune].name = GetEssenceName(runes[rune].id)
  end

  if CS.Quest[CRAFTING_TYPE_ENCHANTING] then
    for _, step in pairs(CS.Quest[CRAFTING_TYPE_ENCHANTING].work) do
      local writ_level = nil
      local writ_rune = nil
      for level = 1,16 do
        local res1, res2 = string.find(step:lower(), levels[level]:lower())
        if res1 then
          writ_level = level
        end
      end
      for rune = 1,#runes do
        local res1, res2 = string.find(step:lower(), runes[rune].name:lower())
        if res1 then
          writ_rune = rune
        end
      end
      if writ_level and writ_rune then
        CS.RuneShow(1,runes[writ_rune].id,1,writ_level,45830+writ_rune,1)
      end
    end
  end
end

function CS.RuneShowFavorites()
  local count = 1
  for _,glyph in pairs(CS.Character.favorites[CRAFTING_TYPE_ENCHANTING]) do
  --Glyphs have 5 data pieces, blueprints have 2
  if #glyph == 5 then
    CS.RuneShow(count,glyph[1],glyph[3],glyph[2],glyph[4],glyph[5]); count = count + 1
  end
  end
  CraftStoreFixed_RuneGlyphSectionScrollChild:SetHeight(count * 24 + 20)
  CraftStoreFixed_RuneInfo:SetText(CS.Loc.TT[11])
end

function CS.RuneShowFurnitureFavorites()
  CraftStoreFixed_RuneInfo:SetText(CS.Loc.TT[24] .. ' ' .. CS.Loc.TT[11])
  local inc,count = 1, 0
  for _,val in pairs(CS.Character.favorites[CRAFTING_TYPE_ENCHANTING]) do
    local  _,_,_,_,_,ingredientType,tradeType = GetRecipeInfo(val[1],val[2])
    if ingredientType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING and tradeType == RECIPE_CRAFTING_SYSTEM_ENCHANTING_SCHEMATICS then
      control = CS.GetRuneChild(inc)
      inc = CS.CookShowRecipe(control,val[1],val[2],inc,sound,true)
      count = count+1
    end
    if inc > CraftStoreFixed_RuneGlyphSectionScrollChild:GetNumChildren() then
      break
    end
  end
  CraftStoreFixed_RuneGlyphSectionScrollChild:SetHeight(inc * 30 + 20)
end

function CS.RuneView(mode)
  local function Close()
    CraftStoreFixed_Rune:SetHidden(true)
    CraftStoreFixed_RuneCloseButton:SetHidden(true)
    CraftStoreFixed_RuneSpaceButton:SetHidden(false)
    CraftStoreFixed_RuneCreateButton:SetHidden(false)
    CraftStoreFixed_RuneRefineButton:SetHidden(false)
    CraftStoreFixed_RuneFurnitureButton:SetHidden(false)
    CraftStoreFixed_RuneHeader:SetWidth(308)
    CraftStoreFixed_RuneSearch:SetWidth(150)
    CraftStoreFixed_RuneSearchBG:SetWidth(160)
    CraftStoreFixed_RuneInfo:SetHidden(false)
    CraftStoreFixed_RuneAmount:SetHidden(false)
    CraftStoreFixed_RuneAmountLabel:SetHidden(false)
    CS.Extern = false
    for x = 1,CraftStoreFixed_RuneGlyphSectionScrollChild:GetNumChildren() do
      CS.HideControl('CraftStoreFixed_RuneGlyphSectionScrollChildButton'..x)
    end
  end

  if ZO_EnchantingTopLevel:IsHidden() then
    if mode == 1 and CraftStoreFixed_Rune:IsHidden() then
      CS.ControlShow(CraftStoreFixed_Rune)
      CraftStoreFixed_RuneCloseButton:SetHidden(false)
      CraftStoreFixed_RuneSpaceButton:SetHidden(true)
      CraftStoreFixed_RuneCreateButton:SetHidden(true)
      CraftStoreFixed_RuneRefineButton:SetHidden(true)
      CraftStoreFixed_RuneFurnitureButton:SetHidden(true)
      CraftStoreFixed_RuneHeader:SetWidth(532)
      CraftStoreFixed_RuneSearch:SetWidth(290)
      CraftStoreFixed_RuneSearchBG:SetWidth(300)
      CraftStoreFixed_RuneInfo:SetHidden(true)
      CraftStoreFixed_RuneAmount:SetHidden(true)
      CraftStoreFixed_RuneAmountLabel:SetHidden(true)
      CS.Extern = true
      CS.Character.runemode = 'craft'
      CS.RuneInitialize()
    else
      Close()
    end
  end
end

function CS.RuneHideVanillaUI(toggle)
  ZO_EnchantingTopLevelModeMenu:SetHidden(toggle)
  -- turn off for all, but handle individually for on
  if toggle then
    ZO_EnchantingTopLevelInventory:SetHidden(toggle)
    ZO_EnchantingTopLevelModeMenu:SetHidden(toggle)
    ZO_EnchantingTopLevelTooltip:SetHidden(toggle)
    ZO_EnchantingTopLevelRuneSlotContainer:SetHidden(toggle)
    ZO_EnchantingTopLevelExtractionSlotContainer:SetHidden(toggle)
    ZO_ProvisionerTopLevel:SetHidden(toggle)
    ZO_ProvisionerTopLevelTooltip:SetHidden(toggle)
  end

  -- leave it regardless for gamepad mode
  if not IsInGamepadPreferredMode() then
    ZO_KeybindStripControl:SetHidden(toggle)
  end
end

function CS.RuneInitialize(toggle)
  if toggle or CS.Extern then
    CS.Rune.aspectSkill = GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_RARITY_LEVEL)
    CS.Rune.potencySkill = GetNonCombatBonus(NON_COMBAT_BONUS_ENCHANTING_LEVEL)
    CraftStoreFixed_RuneLevelButton:SetNormalFontColor(CS.Quality[CS.Character.aspect][1],CS.Quality[CS.Character.aspect][2],CS.Quality[CS.Character.aspect][3],1)
    CraftStoreFixed_RuneAmount:SetText('')
    CraftStoreFixed_RuneSearch:SetText(GetString(SI_GAMEPAD_HELP_SEARCH)..'...')
    CraftStoreFixed_Rune:SetHidden(false)
  else
    CraftStoreFixed_Rune:SetHidden(true)
  end
end

function CS.SetTimer(control,hour)
  local seconds = hour * 3600
  if CS.Account.timer[hour] > 0 then
    control:SetText(hour..':00h')
    CS.Account.timer[hour] = 0
  else
    control:SetText(CS.GetTime(seconds - 1))
    CS.Account.timer[hour] = seconds + GetTimeStamp()
  end
  CS.GetTimer()
end

function CS.SetItemMark(control,linksource)
  if not control then
    return
  end
  local function GetMark(control)
    local name = control:GetName()
    if not ITEMMARK[name] then
      ITEMMARK[name] = WM:CreateControl(name..'CSMark',control,CT_TEXTURE)
    end
    ITEMMARK[name]:SetDrawLayer(3)
    ITEMMARK[name]:SetDimensions(30,30)
    ITEMMARK[name]:SetHidden(true)
    ITEMMARK[name]:ClearAnchors()
    return ITEMMARK[name]
  end
  local function Show(mark,icon,color)
    if color == false then
      color = {1,0,1}
    elseif color == true then
      color = {1,0,0}
    end
    mark:SetColor(color[1],color[2],color[3],0.8)
    mark:SetHidden(false)
    if (control:GetWidth() - control:GetHeight()) > 5 then
      mark:SetAnchor(LEFT,control:GetNamedChild('Bg'),LEFT,0,0)
    else
      mark:SetAnchor(TOPLEFT,control:GetNamedChild('Bg'),TOPLEFT,-4,-4)
    end
    mark:SetTexture(icon)
  end
    local slot, link = control.dataEntry.data or nil, nil
  local uid = Id64ToString(GetItemUniqueId(slot.bagId,slot.slotIndex)) or nil
  if linksource == 3 then
    link = GetTradingHouseSearchResultItemLink(slot.slotIndex); uid = nil
  elseif linksource == 2 then
    link = GetLootItemLink(slot.lootId); uid = nil
  elseif linksource == 1 then
    link = GetItemLink(slot.bagId,slot.slotIndex)
  end
  if not slot or not link then
    return
  end
  local mark = GetMark(control)
  if CS.Account.options.showsymbols then
    local trait = GetItemTrait(slot.bagId,slot.slotIndex)
    if trait == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or trait == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or trait == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE then
      Show(mark,'esoui/art/icons/servicemappins/servicepin_smithy.dds',{0,1,1}); return
    elseif trait == ITEM_TRAIT_TYPE_ARMOR_ORNATE or trait == ITEM_TRAIT_TYPE_WEAPON_ORNATE or trait == ITEM_TRAIT_TYPE_JEWELRY_ORNATE then
      Show(mark,'esoui/art/guild/guild_tradinghouseaccess.dds',{1,1,0}); return
    end
  end
  if CS.Account.options.markitems then
    --local item = (slot.itemType or GetItemLinkItemType(link))
    local item, specializedItemType = GetItemLinkItemType(link)
    if item == ITEMTYPE_INGREDIENT then
      local ingid = CS.SplitLink(link,3)
      if ingid then
        if CS.Cook.ingredient[ingid] then
          Show(mark,'esoui/art/inventory/newitem_icon.dds',{0,1,0});
        elseif mark then
          mark:SetHidden(true)
        end
        return
      end
    end
    if item == ITEMTYPE_RACIAL_STYLE_MOTIF then
      if CS.IsStyleNeeded(link) ~= '' then Show(mark,'esoui/art/inventory/newitem_icon.dds',SELF); return end
    end
    if item == ITEMTYPE_RECIPE then

      if specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING or
        specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING or
        specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING or
        specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING or
        specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING or
        specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING or
        specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING
      then
        if CS.IsBlueprintNeeded(link) ~= '' then
          Show(mark,'esoui/art/inventory/newitem_icon.dds',SELF); return
        end
      else
        if CS.IsRecipeNeeded(link) ~= '' then
          Show(mark,'esoui/art/inventory/newitem_icon.dds',SELF); return
        end
      end
    end
    local craft,line,trait = CS.GetTrait(link)
    if craft and line and trait then
      if CS.IsItemNeeded(craft,line,trait,uid,link) ~= '' then
        Show(mark,'esoui/art/inventory/newitem_icon.dds',SELF)
        return
      end
    end
  end
end

function CS.SetAllStyles()
  if CraftStoreFixed_Style_Window:IsHidden() then
    CraftStoreFixed_StylePanelScrollChildStyles:SetHidden(false)
    CraftStoreFixed_StylePanelScrollChildSets:SetHidden(true)
    CraftStoreFixed_StyleHeader:SetText('CraftStoreStyles')
    CS.ControlShow(CraftStoreFixed_Style_Window)
  else
    CraftStoreFixed_Style_Window:SetHidden(true)
  end
end

function CS.CloseStyle()
  CraftStoreFixed_Style_Window:SetHidden(true)
  ACHIEVEMENTS.popup:Hide()
end

function CS.HideStyles(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hidestyles = not CS.Character.hidestyles
  end
  CraftStoreFixed_StyleHideButton:SetText(ZOSF(tex,val[CS.Character.hidestyles])..CS.Loc.hideStyles)
  CS.FilterStyles()
end

function CS.HideCrownStyles(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hidecrownstyles = not CS.Character.hidecrownstyles
  end
  CraftStoreFixed_StyleHideCrownButton:SetText(ZOSF(tex,val[CS.Character.hidecrownstyles])..CS.Loc.hideCrownStyles)
  CS.FilterStyles()
end

function CS.HidePerfectedStyles(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hideperfectedstyles = not CS.Character.hideperfectedstyles
  end
  CraftStoreFixed_StyleHidePerfectedButton:SetText(ZOSF(tex,val[CS.Character.hideperfectedstyles])..CS.Loc.hideKnown)
  CS.FilterStyles()
end

function CS.FilterStyles()
  local h = {[true]=0,[false]=90}
  local filterPerfected = CS.Character.hideperfectedstyles
  local filterSimple = CS.Character.hidestyles
  local filterCrown = CS.Character.hidecrownstyles
  for id,data in pairs(styleNames) do
    local style = GetValidItemStyleId(data.id)
      local c = WM:GetControlByName('CraftStoreFixed_StyleRow'..id)
      if (filterPerfected and CS.Style.IsPerfectedStyle(style)) or
         (filterCrown and CS.Style.IsCrownStyle(style)) or
         (filterSimple and CS.Style.IsSimpleStyle(style))
      then
        c:SetHidden(true)
        c:SetHeight(h[true])
      else
        c:SetHidden(false)
        c:SetHeight(h[false])
      end
  end
end

function CS.HideKnownBlueprints(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hideKnownBlueprints = not CS.Character.hideKnownBlueprints
  end
  CraftStoreFixed_BlueprintHideKnownButton:SetText(ZOSF(tex,val[CS.Character.hideKnownBlueprints])..CS.Loc.hideKnown)
  CS.FilterBlueprints()
end

function CS.HideUnknownBlueprints(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hideUnknownBlueprints = not CS.Character.hideUnknownBlueprints
  end
  CraftStoreFixed_BlueprintHideUnknownButton:SetText(ZOSF(tex,val[CS.Character.hideUnknownBlueprints])..CS.Loc.hideUnknown)
  CS.FilterBlueprints()
end

function CS.FilterBlueprints()
  CS.BlueprintShowCategory(CS.Character.furniture)
end

function CS.HideKnownRecipes(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hideKnownRecipes = not CS.Character.hideKnownRecipes
  end
  CraftStoreFixed_RecipeHideKnownButton:SetText(ZOSF(tex,val[CS.Character.hideKnownRecipes])..CS.Loc.hideKnown)
  CS.FilterRecipes()
end

function CS.HideUnknownRecipes(init)
  local val, tex = {[true]='checked',[false]='unchecked'}, '|t16:16:esoui/art/buttons/checkbox_<<1>>.dds|t |t2:2:x.dds|t '
  if not init then
    CS.Character.hideUnknownRecipes = not CS.Character.hideUnknownRecipes
  end
  CraftStoreFixed_RecipeHideUnknownButton:SetText(ZOSF(tex,val[CS.Character.hideUnknownRecipes])..CS.Loc.hideUnknown)
  CS.FilterRecipes()
end

function CS.FilterRecipes()
  CS.RecipeShowCategory(CS.Character.recipe)
end

function CS.UpdateIcons()
  local pre, icons = 0, {8,5,9,12,7,3,2,1,14,10,6,13,4,11}
  for id,data in pairs(styleNames) do
    local style = GetValidItemStyleId(data.id)
    if CS.Style.CheckStyle(style) then
      local icon, link, name, aName, aLink, popup = CS.Style.GetHeadline(style)
      for z,y in pairs(icons) do
      icon, link = CS.Style.GetIconAndLink(style,y)
      local tex = WM:GetControlByName('CraftStoreFixed_StylePanelScrollChild'..id..'Button'..y..'Texture')
      tex:SetTexture(icon)
      end
    end
  end
end

function CS.InitPreviews()
  local previews = {CS.Loc.previewType[1], CS.Loc.previewType[2], CS.Loc.previewType[3], CS.Loc.previewType[4]}
  local combo = CraftStoreFixed_StylePreviewType
  local selected = combo.name
  local dropdown = combo.dropdown

  if not CS.Character.previewType then
    CS.Character.previewType = 1
  end

  dropdown:SetSelectedItem(CS.Loc.previewType[CS.Character.previewType])

  local function OnItemSelect(_, choiceText, choice)
    CS.Character.previewType = CS.previewType[choiceText]
    CS.Style.UpdatePreview(CS.previewType[choiceText])
    CS.UpdateIcons()
  end

  for i=1,#previews do
    local entry = dropdown:CreateItemEntry(previews[i], OnItemSelect)
    dropdown:AddItem(entry)
  end
end

function CS.GetQuest()
  local function GetQuestCraft(qName)
    local craftString={
      --[Craft] = English, German, French, French (optional), Brazilian, Russian
      [CRAFTING_TYPE_BLACKSMITHING]={'blacksmith','schmied','forge','forgeron', 'ferraria','кузнецов'},
      [CRAFTING_TYPE_CLOTHIER]={'cloth','schneider','tailleur', 'alfaiataria','портных'},
      [CRAFTING_TYPE_ENCHANTING]={'enchant','verzauber','enchantement','enchanteur','encantador','зачарователей'},
      [CRAFTING_TYPE_ALCHEMY]={'alchemist','alchemie','alchimie','alchimiste', 'alquimista','алхимиков'},
      [CRAFTING_TYPE_PROVISIONING]={'provision','versorg','cuisine','cuisinier', 'culinária','снабженцев'},
      [CRAFTING_TYPE_WOODWORKING]={'woodwork','schreiner','travail du bois', 'marcenaria','столяров'},
      [CRAFTING_TYPE_JEWELRYCRAFTING]={'jewelry crafting','schmuckhandwerks','joaillerie', 'joalheria','ювелиру','ювелиров'},
    }
    for x, craft in pairs(craftString) do
      for _,s in pairs(craft) do
        if string.find(string.lower(qName),s) then
          return x
        end
      end
    end
    return false
  end
  CS.Quest = {}
  for qId = 1, MAX_JOURNAL_QUESTS do
    if IsValidQuestIndex(qId) then
      if GetJournalQuestType(qId) == QUEST_TYPE_CRAFTING then
        local qName,_,activeText,_,_,completed = GetJournalQuestInfo(qId)
        local craft = GetQuestCraft(qName)
        if craft and not completed then
          CS.Quest[craft] = {id = qId, name = ZOSF('|cFFFFFF<<C:1>>|r',qName), work = {}}
          for cId = 1, GetJournalQuestNumConditions(qId,1) do
            local text,current,maximum,_,complete = GetJournalQuestConditionInfo(qId,1,cId)
            if text and text ~= ''and not complete then
              if current == maximum then
                text = '|c00FF00'..text..'|r'
              end
              CS.Quest[craft].work[cId] = text
            end
          end
        elseif craft then
          CS.Quest[craft] = {id = qId, name = '|cFFFFFF'..qName..'|r', work = {[1] = activeText}}
        end
      end
    end
  end
end

function CS.GetTime(seconds)
  if seconds and seconds > 0 then
    seconds = tostring(ZO_FormatTime(seconds,TIME_FORMAT_STYLE_COLONS,TIME_FORMAT_PRECISION_SECONDS))
    local ts,endtime,y={},'',0
    for x in string.gmatch(seconds,'%d+') do
      ts[y] = x; y = y + 1;
    end
    if y == 4 then
      if tonumber(ts[1]) < 10 then
        ts[1] = '0'..ts[1]
      end
      endtime = ts[0]..'d '..ts[1]..':'..ts[2]..'h'
    end
    if y == 3 then
      if tonumber(ts[0]) < 10 then
        ts[0] = '0'..ts[0]
      end
      endtime = ts[0]..':'..ts[1]..'h'
    end
    if y == 2 then
      endtime = ts[0]..'min'
    end
    return endtime
  else
    return '|cFF4020'..CS.Loc.finished..'|r'
  end
end

function CS.GetTimer()
  -- at least one alarm must be enabled
  if CS.Account.options.timeralarm == 4 and CS.Account.options.mountalarm == 4 and CS.Account.options.researchalarm == 4 then return end
  CS.UpdatePlayer()
  TIMER = {}
  for _,x in pairs(CS.Account.announce) do
    if x + 3600 > GetTimeStamp() then
      x = nil
    end
  end
  if CS.Account.timer[12] > 0 then
    table.insert(TIMER,{id = "AccountTimer12", info = CS.Loc.finish12, time = CS.Account.timer[12]})
  end
  if CS.Account.timer[24] > 0 then
    table.insert(TIMER,{id = "AccountTimer24",info = CS.Loc.finish24, time = CS.Account.timer[24]})
  end
  local crafts = {CRAFTING_TYPE_BLACKSMITHING,CRAFTING_TYPE_CLOTHIER,CRAFTING_TYPE_WOODWORKING,CRAFTING_TYPE_JEWELRYCRAFTING}
  for _, char in pairs(CS.GetCharacters()) do
    if CS.Account.player[char].mount.time > 1 then
      table.insert(TIMER,{info = ZOSF(CS.Loc.finishMount, char), id = '$M' .. char, time = CS.Account.player[char].mount.time})
    end
    for _,craft in pairs(crafts) do
      for line = 1, GetNumSmithingResearchLines(craft) do
        for trait = 1, CS.MaxTraits do
          local ts = CS.Data.crafting.researched[char][craft][line][trait] or false
          if ts ~= true and ts ~= false then
            if ts and ts > 1 then
              table.insert(TIMER,{id = '$R' .. char..craft..line..trait, info = ZOSF(CS.Loc.finishResearch,char,GetString('SI_ITEMTRAITTYPE',GetSmithingResearchLineTraitInfo(craft,line,trait)),GetSmithingResearchLineInfo(craft,line)), time = CS.Data.crafting.researched[char][craft][line][trait]})
            end
          end
        end
      end
    end
  end
end

function CS.GetCharacters()
  local function TableSort(t)
    local orderedIndex = {}
    for key in pairs(t) do
      table.insert(orderedIndex,key)
    end
    table.sort(orderedIndex)
    return orderedIndex
  end
  return TableSort(CS.Account.player)
end

function CS.GetTrait(link)
  if not link then
    return false
  end
  local actorCategory = GetItemLinkActorCategory(link)
  if actorCategory ~= 0 then
  return false
  end
  local trait,eq,craft=GetItemLinkTraitInfo(link),GetItemLinkEquipType(link)
  if not CS.IsValidEquip(eq)or not CS.IsValidTrait(trait)then
    return false
  end
  local at,wt,line=GetItemLinkArmorType(link),GetItemLinkWeaponType(link),nil
  if trait==ITEM_TRAIT_TYPE_ARMOR_NIRNHONED then
    trait=19
    if at == ARMORTYPE_NONE then trait = 9 end
  end -- Nirnhoned Weapon replacement
  if trait==ITEM_TRAIT_TYPE_WEAPON_NIRNHONED then
    trait=9
    if wt == WEAPONTYPE_NONE then trait = 19 end
  end -- Nirnhoned Armor replacement
  if wt==WEAPONTYPE_AXE then
    craft=1;line=1;
  elseif wt==WEAPONTYPE_HAMMER then
    craft=1;line=2;
  elseif wt==WEAPONTYPE_SWORD then
    craft=1;line=3
  elseif wt==WEAPONTYPE_TWO_HANDED_AXE then
    craft=1;line=4;
  elseif wt==WEAPONTYPE_TWO_HANDED_HAMMER then
    craft=1;line=5;
  elseif wt==WEAPONTYPE_TWO_HANDED_SWORD then
    craft=1;line=6;
  elseif wt==WEAPONTYPE_DAGGER then
    craft=1;line=7;
  elseif wt==WEAPONTYPE_BOW then
    craft=6;line=1;
  elseif wt==WEAPONTYPE_FIRE_STAFF then
    craft=6;line=2;
  elseif wt==WEAPONTYPE_FROST_STAFF then
    craft=6;line=3;
  elseif wt==WEAPONTYPE_LIGHTNING_STAFF then
    craft=6;line=4;
  elseif wt==WEAPONTYPE_HEALING_STAFF then
    craft=6;line=5;
  elseif wt==WEAPONTYPE_SHIELD then
    craft=6;line=6;trait=trait-10;
  elseif eq==EQUIP_TYPE_CHEST then
    line=1
  elseif eq==EQUIP_TYPE_FEET then
    line=2
  elseif eq==EQUIP_TYPE_HAND then
    line=3
  elseif eq==EQUIP_TYPE_HEAD then
    line=4
  elseif eq==EQUIP_TYPE_LEGS then
    line=5
  elseif eq==EQUIP_TYPE_SHOULDERS then
    line=6
  elseif eq==EQUIP_TYPE_WAIST then
    line=7
  end
  --Handle Jewelry
  if eq==EQUIP_TYPE_NECK or eq==EQUIP_TYPE_RING then
    craft=7
    line = eq==EQUIP_TYPE_NECK and 1 or 2
    --No real order to jewelry traits
    if trait==ITEM_TRAIT_TYPE_JEWELRY_ARCANE then
      trait=1
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_HEALTHY then
      trait=2
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_ROBUST then
      trait=3
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_TRIUNE then
      trait=4
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_INFUSED then
      trait=5
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE then
      trait=6
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_SWIFT then
      trait=7
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_HARMONY then
      trait=8
    elseif trait==ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY then
      trait=9
    end
  else
  --Handle armor
    if at==ARMORTYPE_HEAVY then
      craft=1;line=line+7;trait=trait-10;
    end
    if at==ARMORTYPE_MEDIUM then
      craft=2;line=line+7;trait=trait-10;
    end
    if at==ARMORTYPE_LIGHT then
      craft=2;trait=trait-10;
    end
  end
  if craft and line and trait then
    -- catch invalid values
    if craft < 1 or line < 1 or trait < 1 then
      return false
    else
      return craft,line,trait
    end
  else return false end
end

function CS.IsValidEquip(equip)
  if equip==EQUIP_TYPE_CHEST
  or equip==EQUIP_TYPE_FEET
  or equip==EQUIP_TYPE_HAND
  or equip==EQUIP_TYPE_HEAD
  or equip==EQUIP_TYPE_LEGS
  or equip==EQUIP_TYPE_MAIN_HAND
  or equip==EQUIP_TYPE_OFF_HAND
  or equip==EQUIP_TYPE_ONE_HAND
  or equip==EQUIP_TYPE_TWO_HAND
  or equip==EQUIP_TYPE_SHOULDERS
  or equip==EQUIP_TYPE_WAIST
  or equip==EQUIP_TYPE_NECK
  or equip==EQUIP_TYPE_RING
  then return true else return false end
end

function CS.IsValidTrait(trait)
  if trait~=ITEM_TRAIT_TYPE_NONE
  and trait~=ITEM_TRAIT_TYPE_ARMOR_INTRICATE
  and trait~=ITEM_TRAIT_TYPE_ARMOR_ORNATE
  and trait~=ITEM_TRAIT_TYPE_WEAPON_INTRICATE
  and trait~=ITEM_TRAIT_TYPE_WEAPON_ORNATE
  and trait~=ITEM_TRAIT_TYPE_JEWELRY_INTRICATE
  and trait~=ITEM_TRAIT_TYPE_JEWELRY_ORNATE
  then
    return true
  else
    return false
  end
end

--API for quantity of an item
function CS.GetItemQuantity(link,storage)
  if not storage then
    storage = false
  end
  local qty = {}
  stripedLink = CS.StripLink(link)
  if CS.Account.storage[stripedLink] then
    for location, stock in pairs(CS.Account.storage[stripedLink]) do
      if storage == false or storage == location then
        qty[#qty+1] = {location,stock}
      end
    end
    return qty
  end
  return false
end

--API for whether an item can be researched
function CS.IsResearchable(link,current)
  if not current then
    current = false
  end
  local needed = {}
  local craft,line,trait = CS.GetTrait(link)
  if craft and line and trait then
    for _, char in pairs(CS.GetCharacters()) do
      if current == false or (char == CS.CurrentPlayer and current == true) then
        needed[#needed+1] = {char,not CS.Data.crafting.researched[char][craft][line][trait]}
      end
    end
    return needed
  end
  return false
end

--API for whether a recipe, blueprint or style can be learned
function CS.IsLearnable(link,current)
  if not current then
    current = false
  end
  local needed = {}
  local id = CS.SplitLink(link,3)
  for _, char in pairs(CS.GetCharacters()) do
    if current == false or (char == CS.CurrentPlayer and current == true) then
           needed[#needed+1] = {char,not (CS.Data.cook.knowledge[char][id] or CS.Data.furnisher.knowledge[char][id] or CS.Data.style.knowledge[char][id])}
    end
  end
  return needed
end

function CS.IsItemNeeded(craft,line,trait,id,link)
  if not craft or not line or not trait then
    return
  end
  if craft < 1 or line < 1 or trait < 1 then
    return
  end
  local isSet = GetItemLinkSetInfo(link)
  local mark, need, unneed, storedId = true, {}, {}, CS.Account.crafting.stored[craft][line][trait].id or 0
  if not CS.Account.options.marksetitems and isSet then
    mark = false
  end
  SELF = false
  --if needed and optionally allow duplicates
  if mark and (CS.Account.options.markduplicates or (storedId == id or (not id and storedId == 0))) then
    for _, char in pairs(CS.GetCharacters()) do
      if CS.Account.trait.tracking[char] or CS.Data.crafting.studies[char][craft][line][trait] then
        if not CS.Data.crafting.researched[char][craft][line][trait] then
          if char == CS.CurrentPlayer then
            SELF = true
          end
          table.insert(need,'|cFF1010'..char..'|r')
        elseif CS.Data.crafting.researched[char][craft][line][trait] then
          table.insert(unneed,'|c00FF00'..char..'|r')
        end
      end
    end
  end
  return NeedAppend(need,unneed)
end

function CS.IsStyleNeeded(link)
  SELF = false
  local need, unneed, id = {}, {}, CS.SplitLink(link,3)
  if id then
    for _, char in pairs(CS.GetCharacters()) do
      if CS.Account.style.tracking[char] then
        if not CS.Data.style.knowledge[char][id] then
          if char == CS.CurrentPlayer then
            SELF = true
          end
          table.insert(need,'|cFF1010'..char..'|r')
        else
          table.insert(unneed,'|c00FF00'..char..'|r')
        end
      end
    end
  end
  return NeedAppend(need,unneed)
end
function CS.IsRecipeNeeded(link)
  SELF = false
  local id, need, unneed = CS.SplitLink(link,3), {}, {}
  if id then
    for char,data in pairs(CS.Data.cook.knowledge) do
      if CS.Account.cook.tracking[char] then
        if not data[id] then
          if char == CS.CurrentPlayer then
            SELF = true
          end
          table.insert(need,'|cFF1010'..char..'|r')
        else
          table.insert(unneed,'|c00FF00'..char..'|r')
        end
      end
    end
  end
  return NeedAppend(need,unneed)
end

function CS.IsBlueprintNeeded(link)
  SELF = false
  local id, need, unneed = CS.SplitLink(link,3), {}, {}
  if id then
    for char,data in pairs(CS.Data.furnisher.knowledge) do
      if CS.Account.furnisher.tracking[char] then
        if not data[id] then
          if char == CS.CurrentPlayer then
            SELF = true
          end
          table.insert(need,'|cFF1010'..char..'|r')
        else
          table.insert(unneed,'|c00FF00'..char..'|r')
        end
      end
    end
  end
  return NeedAppend(need,unneed)
end

function CS.IsBait(link)
  if not link then
    return ''
  end
  local id = CS.SplitLink(link,3)
  local bait = {
    [42877] = 1,
    [42871] = 2,
    [42873] = 2,
    [42872] = 3,
    [42874] = 3,
    [42870] = 4,
    [42876] = 4,
    [42875] = 5,
    [42869] = 5
  }
  if id then
    return '\n'..CS.Loc.TT[21][bait[id]]
  end
  return ''
end

function CS.IsPotency(link)
  if not link then
    return ''
  end
  if CS.Account.options.userune then
    local id = CS.SplitLink(link,3)
    for _,add in pairs(CS.Rune.rune[ITEMTYPE_ENCHANTING_RUNE_POTENCY]) do
      for level,rune in pairs(add) do
        if rune == id then
          return CS.Loc.level..' '..CS.Rune.level[level]
        end
      end
    end
    return ''
  end
end

function CS.IsItemStoredForCraftStore(id)
  for x,craft in pairs(CS.Account.crafting.stored)do
    for y,line in pairs(craft)do
      for z,trait in pairs(line)do
        if trait.id == id then
          for char,data in pairs(CS.Data.crafting.researched)do
            if CS.Data.crafting.studies[char][x][y][z] and not data[x][y][z] then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function CS.TravelToNode(control,node)
  if control.data then
    if control.data.travel then
      FastTravelToNode(CS.Sets[control.data.set].nodes[node])
    else
      CS.Chat:Print(CS.Loc.unknownWayshrine)
    end
  else
    CS.Chat:Print(CS.Loc.unselectedWayshrine)
  end
end

function CS.OptionSetSelect(control,button)
  if button == 2 then
    CS.ToChat(control.data.link)
  else
    for x = 1,3 do
      local zone = {GetZoneNameByIndex(control.data.zone[x])}
      local node = {GetFastTravelNodeInfo(control.data.node[x])}
      local nr, travel, zonename, nodename = control.data.nr, true, ZOSF('<<C:1>>',zone[1]), CS.Loc.unknown
      if CS.Sets[nr].nodes[x] == -1 then
        nodename = CS.Loc.TT[17]
      elseif CS.Sets[nr].nodes[x] == -2 then
        nodename = CS.Loc.TT[18]
    -- todo: add explanation of location
    elseif CS.Sets[nr].nodes[x] == -3 then
      nodename = ''
    end
      local cost = ' (|cFFFF00'..GetRecallCost()..'|r|t1:0:x.dds|t |t14:14:esoui/art/currency/currency_gold.dds|t)'
      if node[1] then
        nodename = ZOSF('<<C:1>>',node[2])
      else
        travel = false; cost = ''
      end
      WM:GetControlByName('CraftStoreFixed_PanelButtonWayshrine'..x).data = { set = nr, travel = travel, info = nodename..'\n'..zonename..cost }
    end
    CraftStoreFixed_PanelButtonCraftedSets.data = { link = control.data.link }
    CraftStoreFixed_PanelButtonCraftedSets:SetText(control.data.name)
    CraftStoreFixed_SetPanel:SetHidden(true)
  end
end

function CS.OptionSelect(control,condition,text)
  if not control then
    return
  end
  if condition then
    condition = false
  else
    condition = true
  end
  local tex = 'esoui/art/buttons/checkbox_unchecked.dds'
  if condition then
    tex = 'esoui/art/buttons/checkbox_checked.dds'
  end
  control:SetText('|t16:16:'..tex..'|t '..text)
  return condition
end

function CS.TraitToggle(control,char,text)
  local crafts = {CRAFTING_TYPE_BLACKSMITHING,CRAFTING_TYPE_CLOTHIER,CRAFTING_TYPE_WOODWORKING,CRAFTING_TYPE_JEWELRYCRAFTING}
  local value = CS.OptionSelect(control,CS.Account.trait.tracking[char],text)
  for _,craft in pairs(crafts) do
    for line = 1, GetNumSmithingResearchLines(craft) do
      for trait = 1, CS.MaxTraits do
        CS.Data.crafting.studies[char][craft][line][trait] = value
      end
      if CS.SelectedPlayer == char then
        CS.UpdateStudyLine(WM:GetControlByName('CraftStoreFixed_PanelCraft'..craft):GetChild(line),value)
      end
    end
  end
  return value
end

function CS.OptionSet()
  --Button
  CraftStoreFixed_ButtonFrame:SetHidden(not CS.Account.options.showbutton)
  CraftStoreFixed_ButtonFrameButtonBG:SetMovable(not CS.Account.options.lockbutton)
  CraftStoreFixed_ButtonFrameButtonBG:SetMouseEnabled(not CS.Account.options.lockbutton)

  --Quest
  CraftStoreFixed_Quest:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Quest:SetMouseEnabled(not CS.Account.options.lockelements)

  --Main
  CraftStoreFixed_Panel:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Panel:SetMouseEnabled(not CS.Account.options.lockelements)

  --Blueprint
  CraftStoreFixed_Blueprint_Window:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Blueprint_Window:SetMouseEnabled(not CS.Account.options.lockelements)

  --Cook
  CraftStoreFixed_Cook:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Cook:SetMouseEnabled(not CS.Account.options.lockelements)

  --Flask (unreleased)
  --CraftStoreFixed_Flask:SetMovable(not CS.Account.options.lockelements)
  --CraftStoreFixed_Flask:SetMouseEnabled(not CS.Account.options.lockelements)

  --Furnisher (unreleased)
  --CraftStoreFixed_Furnisher:SetMovable(not CS.Account.options.lockelements)
  --CraftStoreFixed_Furnisher:SetMouseEnabled(not CS.Account.options.lockelements)

  --Recipe
  CraftStoreFixed_Recipe_Window:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Recipe_Window:SetMouseEnabled(not CS.Account.options.lockelements)

  --Rune
  CraftStoreFixed_Rune:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Rune:SetMouseEnabled(not CS.Account.options.lockelements)

  --Style
  CraftStoreFixed_Style_Window:SetMovable(not CS.Account.options.lockelements)
  CraftStoreFixed_Style_Window:SetMouseEnabled(not CS.Account.options.lockelements)
end

function CS.SetsSet()
  if type(CS.Character.previewType) ~= 'number' or CS.Character.previewType < 1 or CS.Character.previewType > 4 then CS.Character.previewType=1 end
  -- add name to prep presort
  for x,set in pairs(CS.Sets) do
  local link = '|H1:item:'..set.item[CS.Character.previewType]..':370:50:0:370:50:0:0:0:0:0:0:0:0:0:'..GetHighestItemStyleId()..':0:0:0:10000:0|h|h'
    local _,setName = GetItemLinkSetInfo(link,false)
  set.name = setName;
  end
  -- sort alphabetically
  if CS.Account.options.sortsets == 1 then
  table.sort(CS.Sets,asort)
  -- sort by number of traits
  elseif CS.Account.options.sortsets == 2 then
  table.sort(CS.Sets,traitsort)
  end
  for x,set in pairs(CS.Sets) do
  local btn = WM:GetControlByName('CraftStoreFixed_SetPanelScrollChildButton'..x)
  if not btn then
    btn = WM:CreateControl('CraftStoreFixed_SetPanelScrollChildButton'..x,CraftStoreFixed_SetPanelScrollChild,CT_BUTTON)
    btn:SetAnchor(3,nil,3,8,5 + (x-1) * 22)
    btn:SetDimensions(280,22)
    btn:SetFont('CraftStoreFixedFont')
    btn:SetClickSound('Click')
    btn:EnableMouseButton(2,true)
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetMouseOverFontColor(1,0.66,0.2,1)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_SetPanel,'tl') end)
    btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown',function(self,button) CS.OptionSetSelect(self,button) end)
  end
  --Changed to recently added set
    local link = '|H1:item:'..set.item[CS.Character.previewType]..':370:50:0:370:50:0:0:0:0:0:0:0:0:0:'..GetHighestItemStyleId()..':0:0:0:10000:0|h|h'
    local _,setName = GetItemLinkSetInfo(link,false)
    setName = ZOSF('[<<1>>] <<C:2>>',set.traits,setName)
    btn:SetText(setName)
    btn.data = { link = link, nr = x, zone = set.zone, node = set.nodes, name = setName, buttons = {CS.Loc.TT[5],CS.Loc.TT[6]} }
  end
end

function CS.StyleInitialize()
  local pre, icons = 0, {8,5,9,12,7,3,2,1,14,10,6,13,4,11}
  CS.StyleSort()
  --id is index, data.id is ZOS id
  for id,data in pairs(styleNames) do
    local style = GetValidItemStyleId(data.id)
      local c = WM:GetControlByName('CraftStoreFixed_StyleRow'..pre)
    local p = nil
    if WM:GetControlByName('CraftStoreFixed_StyleRow'..id) == nil then
      p = WM:CreateControl('CraftStoreFixed_StyleRow'..id,CraftStoreFixed_StylePanelScrollChildStyles,CT_CONTROL)
      if c then
        p:SetAnchor(3,c,6,0,0)
      else
        p:SetAnchor(3,nil,3,0,3)
      end
      p:SetDimensions(750,90)
    else
      p = WM:GetControlByName('CraftStoreFixed_StyleRow'..id);
    end
    local bg = nil
    if WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildBgLine'..id) == nil then
      bg = WM:CreateControl('CraftStoreFixed_StylePanelScrollChildBgLine'..id,p,CT_BACKDROP)
      bg:SetAnchor(3,p,3,0,0)
      bg:SetDimensions(750,37)
      bg:SetCenterColor(0,0,0,0.2)
      bg:SetEdgeColor(1,1,1,0)
    else
      bg = WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildBgLine'..id)
    end

    local btn = nil
      local icon, link, name, aName, aLink, popup = CS.Style.GetHeadline(style)
    if WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildMaterial'..id) == nil then
      btn = WM:CreateControl('CraftStoreFixed_StylePanelScrollChildMaterial'..id,p,CT_BUTTON)
      btn:SetAnchor(2,bg,2,10,0)
      btn:SetDimensions(30,30)
    else
      btn = WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildMaterial'..id)
    end

      btn:SetNormalTexture(icon)
      btn:EnableMouseButton(2,true)
      btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Style,'tl') end)
      btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
      btn:SetHandler('OnMouseDown',function(self,button) if button == 2 then CS.ToChat(self.data.link) end end)
      btn.data = { link = link, buttons = {CS.Loc.TT[6]} }

    local lbl = nil
    if WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildName'..id) == nil then
      lbl = WM:CreateControl('CraftStoreFixed_StylePanelScrollChildName'..id,p,CT_LABEL)
      lbl:SetAnchor(2,bg,2,50,0)
      lbl:SetDimensions(nil,32)
      lbl:SetFont('CraftStoreFixedFont')
      lbl:SetColor(1,0.66,0.2,1)
      lbl:SetHorizontalAlignment(0)
      lbl:SetVerticalAlignment(1)
    else
    lbl = WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildName'..id)
    end
    lbl:SetText(name)

    local av = nil
    if WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildAchievement'..id) == nil then
      av = WM:CreateControl('CraftStoreFixed_StylePanelScrollChildAchievement'..id,p,CT_BUTTON)
      av:SetAnchor(2,lbl,8,15,0)
      av:SetDimensions(300,32)
      av:SetFont('CraftStoreFixedFont')
      av:SetNormalFontColor(1,0.66,0.2,0.5)
      av:SetMouseOverFontColor(1,0.66,0.2,1)
      av:SetHorizontalAlignment(0)
      av:SetVerticalAlignment(1)
    else
      av = WM:GetControlByName('CraftStoreFixed_StylePanelScrollChildAchievement'..id)
    end

    if aName ~= 'crown' then
      av:EnableMouseButton(2,true)
      av:SetText('['..aName..']')
      av:SetHandler('OnMouseDown',function(self,button)
        if button == 2 then
          CS.ToChat(aLink)
        else
          ACHIEVEMENTS:ShowAchievementPopup(unpack(popup))
          ZO_PopupTooltip_Hide()
        end
      end)
    else
      av:SetText('|t32:32:esoui/art/currency/currency_crowns_32.dds|t')
    end
    for z,y in pairs(icons) do
      icon, link = CS.Style.GetIconAndLink(style,y)
      local btn = nil
      local btnName = 'CraftStoreFixed_StylePanelScrollChild'..id..'Button'..y
      if WM:GetControlByName(btnName) == nil then
        btn = WM:CreateControl(btnName,p,CT_BUTTON)
        btn:SetAnchor(3,bg,6,4+(z-1)*52,2)
        btn:SetDimensions(52,50)
        btn:EnableMouseButton(2,true)
        btn:SetClickSound('Click')
        btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,true,CraftStoreFixed_Style,'tl') end)
        btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false,true) end)
        btn:SetHandler('OnMouseDown',function(self,button) if button == 2 then CS.ToChat(self.data.link) end end)
      else
        btn = WM:GetControlByName(btnName)
      end
      btn.data = { link = link, buttons = {CS.Loc.TT[6]} }
      local tex = nil
      if WM:GetControlByName(btnName..'Texture') == nil then
        tex = WM:CreateControl(btnName..'Texture',btn,CT_TEXTURE)
        tex:SetAnchor(128,btn,128,0,0)
        tex:SetDimensions(45,45)
        tex:SetColor(1,0,0,0.5)
      else
        tex = WM:GetControlByName(btnName..'Texture')
      end
      tex:SetTexture(icon)
    end
    pre = id
  end
  CS.UpdateStyleKnowledge()
end

function CS.PanelInitialize()
  local crafts = {CRAFTING_TYPE_BLACKSMITHING,CRAFTING_TYPE_CLOTHIER,CRAFTING_TYPE_WOODWORKING,CRAFTING_TYPE_JEWELRYCRAFTING}
  CS.Data.crafting.researched[CS.CurrentPlayer] = {}
  CS.SetsSet()
  for _,craft in pairs(crafts) do
    CS.Data.crafting.researched[CS.CurrentPlayer][craft] = {}
    if not CS.Account.crafting.stored[craft] then
      CS.Account.crafting.stored[craft] = {}
    end
    for line = 1, GetNumSmithingResearchLines(craft) do
      CS.DrawTraitColumn(craft,line)
      CS.Data.crafting.researched[CS.CurrentPlayer][craft][line] = {}
      if not CS.Account.crafting.stored[craft][line] then
        CS.Account.crafting.stored[craft][line] = {}
      end
      for trait = 1, CS.MaxTraits do
        if not CS.Account.crafting.stored[craft][line][trait] then
          CS.Account.crafting.stored[craft][line][trait] = {}
        end
      end
    end
  end
  --initialize style window
  CS.StyleInitialize()

  local function Split(level)
    local basename = ZOSF('<<t:1>>', GetItemLinkName(CS.RuneGetLink(26580,0,0)))
    local basedata = { zo_strsplit(' ', basename) }
    local name = ZOSF('<<t:1>>', GetItemLinkName(CS.RuneGetLink(26580,3,level)))
    local namedata = { zo_strsplit(' ', name) }
    for j = #namedata, 1, -1 do
      for i = #basedata, 1, -1 do
        if namedata[j] == basedata[i] then
          table.remove(namedata, j)
          table.remove(basedata, i)
        end
      end
    end
    return ZOSF('<<C:1>>', table.concat(namedata,' '))
  end
  for x,level in pairs(CS.Rune.level) do
    local name = Split(x)
    local btn = WM:CreateControl('CraftStoreFixed_RuneMenuButton'..x,CraftStoreFixed_RuneMenu,CT_BUTTON)
    btn:SetAnchor(3,nil,3,8,5 + (x-1) * 24)
    btn:SetDimensions(240,24)
    btn:SetFont('ZoFontGame')
    btn:SetClickSound('Click')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetMouseOverFontColor(1,0.66,0.2,1)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetText(name..' |c888888('..level..')|r')
    btn.data = {level = x}
    btn:SetHandler('OnClicked',function(self)
      CS.RuneSetValue(3,self.data.level);
      CraftStoreFixed_RuneLevelButton:SetText(CS.Loc.level..': '..CS.Rune.level[self.data.level])
      CraftStoreFixed_RuneMenu:SetHidden(true)
      CS.RuneShowMode()
    end)
  end
  CraftStoreFixed_SetPanelScrollChild:SetHeight(#CS.Sets * 22 + 10)
  CraftStoreFixed_Panel:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.position[1],CS.Account.position[2])
  CraftStoreFixed_Quest:SetAnchor(TOPLEFT,CraftStoreFixed_QuestFrame,TOPLEFT,CS.Account.questbox[1],CS.Account.questbox[2])
  CraftStoreFixed_ButtonFrameButtonBG:SetAnchor(TOPLEFT,CraftStoreFixed_ButtonFrame,TOPLEFT,CS.Account.button[1],CS.Account.button[2])
  CraftStoreFixed_PanelButtonCraftedSets:SetText(CS.Loc.set)
  CraftStoreFixed_CharacterPanelHeader:SetText(CS.Loc.chars)

  CraftStoreFixed_Style_Window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.coords.style[1],CS.Account.coords.style[2])
  CraftStoreFixed_Recipe_Window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.coords.recipe[1],CS.Account.coords.recipe[2])
  CraftStoreFixed_Blueprint_Window:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.coords.blueprint[1],CS.Account.coords.blueprint[2])
  CraftStoreFixed_Rune:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.coords.rune[1],CS.Account.coords.rune[2])
  CraftStoreFixed_Cook:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.coords.cook[1],CS.Account.coords.cook[2])
  CraftStoreFixed_CharacterPanel:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,CS.Account.coords.overview[1],CS.Account.coords.overview[2])

  if CS.Account.mainchar then
    CraftStoreFixed_PanelButtonCharacters:SetText(CS.Account.mainchar)
  else
    CraftStoreFixed_PanelButtonCharacters:SetText(CS.CurrentPlayer)
  end
  CraftStoreFixed_RuneInfo:SetText(GetString(SI_CRAFTING_PERFORM_FREE_CRAFT))
  CraftStoreFixed_RuneLevelButton:SetText(CS.Loc.level..': '..CS.Rune.level[CS.Character.potency])
  CS.OptionSet()
  -- Tooltips
  local control
  for x = 1,16 do
    control = WM:GetControlByName('CraftStoreFixed_CookCategoryButton'..x)
    control.data = {info = ZOSF('|cFFFFFF<<C:1>>|r\n<<2>>',GetRecipeListInfo(x),CS.Cook.category[x])}
    control = WM:GetControlByName('CraftStoreFixed_RecipeCategoryButton'..x)
    control.data = {info = ZOSF('|cFFFFFF<<C:1>>|r\n<<2>>',GetRecipeListInfo(x),CS.Cook.category[x])}
  end
  CraftStoreFixed_PanelQuestButton.data = nil
  --Handle traits for Woodworking, Blacksmithing and Clothier
  for line = 1, 2 do
    for trait = 1, CS.MaxTraits do
      local tid = GetSmithingResearchLineTraitInfo(1,math.abs(line - 9),trait)
      local _,desc = GetSmithingResearchLineTraitInfo(1,math.abs(line - 9),trait)
      local _,name,icon = GetSmithingTraitItemInfo(tid + 1)
      control = WM:GetControlByName('CraftStoreFixed_PanelTraitrow'..(trait + (line - 1) * 9))
      control:SetText(GetString('SI_ITEMTRAITTYPE',tid)..' |t25:25:'..icon..'|t|t5:25:x.dds|t')
      control.data = {info = ZOSF('|cFFFFFF<<C:1>>',name)..'|r\n'..desc}
    end
  end
  --Handle traits for Jewelry
  for trait = 1, CS.JewelryMaxTraits do
    local tid = GetSmithingResearchLineTraitInfo(7,1,trait)
    local _,desc = GetSmithingResearchLineTraitInfo(7,1,trait)
    local _,name,icon = GetSmithingTraitItemInfo(tid + 1)
    control = WM:GetControlByName('CraftStoreFixed_PanelTraitrow'..(18+trait))
    control:SetText(GetString('SI_ITEMTRAITTYPE',tid)..' |t25:25:'..icon..'|t|t5:25:x.dds|t')
    control.data = {info = ZOSF('|cFFFFFF<<C:1>>',name)..'|r\n'..desc}
  end
  --Localizes various parts of the addon
  CraftStoreFixed_PanelFenceGoldText.data = { info = CS.Loc.TT[16] }
  CraftStoreFixed_ButtonFrameButton.data = { info = 'CraftStore' }
  CraftStoreFixed_RuneArmorButton.data =  { info = GetString('SI_ITEMTYPE',ITEMTYPE_GLYPH_ARMOR) }
  CraftStoreFixed_RuneWeaponButton.data =  { info = GetString('SI_ITEMTYPE',ITEMTYPE_GLYPH_WEAPON) }
  CraftStoreFixed_RuneJewelryButton.data =  { info = GetString('SI_ITEMTYPE',ITEMTYPE_GLYPH_JEWELRY) }
  CraftStoreFixed_RuneSpaceButton.data =  { info = GetString(SI_GAMEPAD_MAIL_INBOX_INVENTORY) }
  CraftStoreFixed_RuneCreateButton.data =  { info = GetString(SI_ENCHANTING_CREATION) }
  CraftStoreFixed_RuneRefineButton.data =  { info = GetString(SI_ENCHANTING_EXTRACTION) }
  CraftStoreFixed_RuneFavoriteButton.data =  { info = CS.Loc.TT[11] }
  CraftStoreFixed_RuneWritButton.data =  { info = CS.Loc.TT[23] }
  CraftStoreFixed_RuneFurnitureButton.data =  { info = CS.Loc.TT[24] }
  CraftStoreFixed_RuneFavoriteFurnitureButton.data =  { info = CS.Loc.TT[24] .. ' ' .. CS.Loc.TT[11]}
  CraftStoreFixed_RuneRefineAllButton.data =  { info = CS.Loc.TT[22], addline = {CS.Loc.TT[9]} }
  CraftStoreFixed_RuneHandmadeButton.data =  { info = CS.Loc.TT[12] }
  CraftStoreFixed_CookSpaceButton.data =  { info = GetString(SI_GAMEPAD_MAIL_INBOX_INVENTORY) }
  CraftStoreFixed_CookCategoryButtonFavorites.data = { info = CS.Loc.TT[11] }
  CraftStoreFixed_CookCategoryButtonWrit.data = { info = CS.Loc.TT[23] }
  CraftStoreFixed_CookCategoryButtonFurniture.data = { info = CS.Loc.TT[24] }
  CraftStoreFixed_CookCategoryButtonFurnitureFavorites.data = { info = CS.Loc.TT[24] .. ' ' .. CS.Loc.TT[11] }
  CraftStoreFixed_BlueprintCategoryButton1.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM1)}
  CraftStoreFixed_BlueprintCategoryButton2.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM2)}
  CraftStoreFixed_BlueprintCategoryButton3.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM3)}
  CraftStoreFixed_BlueprintCategoryButton4.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM4)}
  CraftStoreFixed_BlueprintCategoryButton5.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM5)}
  CraftStoreFixed_BlueprintCategoryButton6.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM6)}
  CraftStoreFixed_BlueprintCategoryButton7.data = {info = GetString(SI_RECIPECRAFTINGSYSTEM7)}
  --Localize it
  for x = 1,5 do
    WM:GetControlByName('CraftStoreFixed_RuneAspect'..x..'Button').data = { link = CS.RuneGetLink(CS.Rune.rune[ITEMTYPE_ENCHANTING_RUNE_ASPECT][x],x,1) }
  end
end

--Handles inventory count and color for enchanting/provisioning
function CS.InventorySpace(control)
  control:SetText(GetNumBagUsedSlots(1) .. '/' .. GetBagSize(1))
  if GetBagSize(1) ==  GetNumBagUsedSlots(1) then
    control:SetColor(1,0,0,1)
  elseif (GetBagSize(1)-GetNumBagUsedSlots(1)) <= 5 then
    control:SetColor(1,0.9,0,1)
  else
    control:SetColor(1, 1, 1, 1)
  end
end

function CS.CharacterInitialize()
  -- safety check due to Dragonhold quests
  if CraftStoreFixed_CharacterFrame1 ~= nil then
    return
  end

  -- slimmer overview
  local overviewHeight = 83
  if CS.Account.options.overviewstyle == 1 then
  overviewHeight = overviewHeight + 58
  end
  if CS.Account.options.overviewstyle ~= 3 then
  overviewHeight = overviewHeight + 58
  end

  local tex = {[false] = '|t16:16:esoui/art/buttons/checkbox_unchecked.dds|t', [true] = '|t16:16:esoui/art/buttons/checkbox_checked.dds|t'}
  for x,char in pairs(CS.GetCharacters()) do
    local frame = WM:CreateControl('CraftStoreFixed_CharacterFrame'..x,CraftStoreFixed_CharacterPanelBoxScrollChild,CT_CONTROL)
  --Frame height also needs set in CS.DrawCharacter()
    frame:SetAnchor(TOPLEFT,CraftStoreFixed_CharacterPanelBoxScrollChild,TOPLEFT,0,(x - 1) * overviewHeight)
    local offset_pos = 0

    local bg = WM:CreateControl('CraftStoreFixed_Character'..x..'NameBG',frame,CT_BACKDROP)
    bg:SetAnchor(TOPLEFT,frame,TOPLEFT,0,0)
  offset_pos = 60
    bg:SetDimensions(563,offset_pos)
    bg:SetCenterColor(0.06,0.06,0.06,1)
    bg:SetEdgeColor(0.12,0.12,0.12,1)
    bg:SetEdgeTexture('',1,1,1)

    local btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Name',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,10,1)
    btn:SetDimensions(450,35)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetClickSound('Click')
    btn:EnableMouseButton(2,true)
    btn:EnableMouseButton(3,true)
    btn:SetFont('ZoFontWinH3')
    btn:SetNormalFontColor(1,1,1,1)
    btn:SetMouseOverFontColor(1,0.66,0.3,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bl') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown', function(self,button) CS.LoadCharacter(self,button) end)

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'InfoSkillPoints',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,8,30)
    btn:SetDimensions(80,25)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bl') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'InfoSkyShards',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,88,30)
    btn:SetDimensions(80,25)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bl') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Info',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,176,30)
    btn:SetDimensions(400,25)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bl') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Trait',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,307,7)
    btn:SetDimensions(80,25)
    btn:SetHorizontalAlignment(2)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetClickSound('Click')
    btn:SetText(tex[CS.NilCheckSetIfNil(CS.Account.trait.tracking,false,char)]..' |t22:22:esoui/art/icons/crafting_potent_nirncrux_dust.dds|t')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bc') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown', function(self) CS.Account.trait.tracking[char] = CS.TraitToggle(self,char,'|t22:22:esoui/art/icons/crafting_potent_nirncrux_dust.dds|t') end)
    btn.data = { info = CS.Loc.TT[25] }

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Style',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,362,7)
    btn:SetDimensions(80,25)
    btn:SetHorizontalAlignment(2)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetClickSound('Click')
    btn:SetText(tex[CS.NilCheckSetIfNil(CS.Account.style.tracking,false,char)]..' |t22:22:esoui/art/icons/quest_book_001.dds|t')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bc') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnClicked', function(self) CS.Account.style.tracking[char] = CS.OptionSelect(self,CS.Account.style.tracking[char],'|t22:22:esoui/art/icons/quest_book_001.dds|t') end)
    btn.data = { info = CS.Loc.TT[13] }

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Recipe',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,417,7)
    btn:SetDimensions(80,25)
    btn:SetHorizontalAlignment(2)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetClickSound('Click')
    btn:SetText(tex[CS.NilCheckSetIfNil(CS.Account.cook.tracking,false,char)]..' |t22:22:esoui/art/icons/quest_scroll_001.dds|t')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bc') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnClicked', function(self) CS.Account.cook.tracking[char] = CS.OptionSelect(self,CS.Account.cook.tracking[char],'|t22:22:esoui/art/icons/quest_scroll_001.dds|t') end)
    btn.data = { info = CS.Loc.TT[14] }

    btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Furnisher',frame,CT_BUTTON)
    btn:SetAnchor(TOPLEFT,frame,TOPLEFT,472,7)
    btn:SetDimensions(80,25)
    btn:SetHorizontalAlignment(2)
    btn:SetVerticalAlignment(1)
    btn:SetFont('ZoFontGame')
    btn:SetClickSound('Click')
    btn:SetText(tex[CS.NilCheckSetIfNil(CS.Account.furnisher.tracking,false,char)]..' |t22:22:EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds|t')
    btn:SetNormalFontColor(0.9,0.87,0.68,1)
    btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bc') end)
    btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnClicked', function(self) CS.Account.furnisher.tracking[char] = CS.OptionSelect(self,CS.Account.furnisher.tracking[char],'|t22:22:EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds|t') end)
    btn.data = { info = CS.Loc.TT[32] }

    offset_pos = offset_pos+1
    local skills, xpos, ypos, res = {5,4,3,0,2,1,6,7}, 0, offset_pos, {2,1,6,7}

  -- Only hide for minimal
  if CS.Account.options.overviewstyle ~= 3 then
    for y,z in pairs(skills) do
      bg = WM:CreateControl('CraftStoreFixed_Character'..x..'Skill'..z..'BG',frame,CT_BACKDROP)
      bg:SetAnchor(TOPLEFT,frame,TOPLEFT,xpos,ypos)
      bg:SetDimensions(140,28)
      bg:SetCenterColor(0.06,0.06,0.06,1)
      bg:SetEdgeColor(0.12,0.12,0.12,1)
      bg:SetEdgeTexture('',1,1,1)

      btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Skill'..z,frame,CT_BUTTON)
      btn:SetAnchor(TOPLEFT,frame,TOPLEFT,xpos + 5,ypos)
      btn:SetDimensions(165,28)
      btn:SetFont('CraftStoreFixedFont')
      btn:SetNormalFontColor(0.9,0.87,0.68,1)
      btn:SetHorizontalAlignment(0)
      btn:SetVerticalAlignment(1)
      btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bl') end)
      btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
      xpos = xpos + 141
      if y == 4 then
        xpos = 0; ypos = ypos+29;
      end
    end
  end

  xpos = 0

  -- Only show for complete
  if CS.Account.options.overviewstyle == 1 then
    for _,z in pairs(res) do
      bg = WM:CreateControl('CraftStoreFixed_Character'..x..'Research'..z..'BG',frame,CT_BACKDROP)
      bg:SetAnchor(TOPLEFT,frame,TOPLEFT,xpos,offset_pos+58)
      bg:SetDimensions(140,70)
      bg:SetCenterColor(0.06,0.06,0.06,1)
      bg:SetEdgeColor(0.12,0.12,0.12,1)
      bg:SetEdgeTexture('',1,1,1)
      xpos = xpos + 141
      for i = 1,3 do
        btn = WM:CreateControl('CraftStoreFixed_Character'..x..'Research'..z..'Slot'..i,bg,CT_BUTTON)
        btn:SetAnchor(TOPLEFT,bg,TOPLEFT,5,1 + (i - 1) * 22)
        btn:SetDimensions(137,22)
        btn:SetFont('CraftStoreFixedFont')
        btn:SetNormalFontColor(0.9,0.87,0.68,1)
        btn:SetHorizontalAlignment(0)
        btn:SetVerticalAlignment(1)
        btn:SetHandler('OnMouseEnter', function(self) CS.Tooltip(self,true,false,self,'bl') end)
        btn:SetHandler('OnMouseExit', function(self) CS.Tooltip(self,false) end)
        local lbl = WM:CreateControl('CraftStoreFixed_Character'..x..'Research'..z..'Slot'..i..'Time',bg,CT_LABEL)
        lbl:SetAnchor(TOPRIGHT,bg,TOPRIGHT,-5,1 + (i - 1) * 22)
        lbl:SetDimensions(90,22)
        lbl:SetFont('CraftStoreFixedFont')
        lbl:SetColor(0.9,0.87,0.68,1)
        lbl:SetHorizontalAlignment(2)
        lbl:SetVerticalAlignment(1)
      end
    end
  end
  end
end
function CS.Tooltip(c,visible,scale,parent,pos)
  if not c then
    return
  end
  local function IconScale(c,from,to)
    local a,t = CreateSimpleAnimation(ANIMATION_SCALE,c)
    a:SetDuration(150)
    a:SetStartScale(from)
    a:SetEndScale(to)
    t:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT)
    t:PlayFromStart()
  end
  local function TooltipCraft(c,field,maxval)
    if CS.Extern then
      return {CS.Loc.TT[6],CS.Loc.TT[4]}
    end
    if c.data.craftable and maxval > 0 then
      if maxval > MAXCRAFT then
        maxval = MAXCRAFT
      end
      local amount = tonumber(field:GetText()) or 1
      --Check if furniture
      local itemType = GetItemLinkItemType(c.data.link)
      if itemType == ITEMTYPE_FURNISHING then
        return {ZOSF(CS.Loc.TT[2],amount),CS.Loc.TT[4]}
      else
        return {ZOSF(CS.Loc.TT[2],amount),ZOSF(CS.Loc.TT[3],maxval),CS.Loc.TT[4]}
      end
    end
    return {CS.Loc.TT[4]}
  end
  if scale then
    if visible then
      IconScale(c:GetNamedChild('Texture'),1,1.4)
    else
      IconScale(c:GetNamedChild('Texture'),1.4,1)
    end
  end
  if c.data == nil then
    return
  elseif visible then
    if not parent then
      parent = c
    end
    if not pos then
      pos = 0
    end
    local anchor, first = {tl={9,2,1,3},tc={4,0,-2,1},tr={3,2,3,9},cl={8,-2,0,2},[0]={2,1,0,8},cr={2,2,0,8},bl={3,2,2,6},bc={1,0,2,4},br={6,2,-3,12}}, '\n'
    if c.data.link then
      c.text = ItemTooltip
      InitializeTooltip(c.text,parent,anchor[pos][1],anchor[pos][2],anchor[pos][3],anchor[pos][4])
      c.text:SetLink(c.data.link)
      ZO_ItemTooltip_ClearCondition(c.text)
      ZO_ItemTooltip_ClearCharges(c.text)
    elseif c.data.info then
      c.text = InformationTooltip
      InitializeTooltip(c.text,parent,anchor[pos][1],anchor[pos][2],anchor[pos][3],anchor[pos][4])
      SetTooltipText(c.text,c.data.info)
    end
    if c.data.addline then
      for _,text in pairs(c.data.addline) do
        c.text:AddLine(first..text,'CraftStoreFixedFont')
        first = ''
      end
    end
    if c.data.buttons then
      c.text:AddLine(first..table.concat(c.data.buttons,'\n'),'CraftStoreFixedFont'); first = ''
    end

    if c.data.crafting then
      -- changed from max to bulk
      local amount = CS.Account.options.bulkcraftlimit
      if amount > c.data.crafting[2] then
        amount = c.data.crafting[2]
      end
      c.text:AddLine(first..table.concat(TooltipCraft(c,c.data.crafting[1],amount),'\n'),'CraftStoreFixedFont'); first = ''
    end

    --Integrate MM graphs
    if c.data.link and CS.Account.options.displaymm and MasterMerchant and MasterMerchant.isInitialized then
      MasterMerchant:addStatsAndGraph(c.text, c.data.link, false)
    end
    --Integrate TTC info
    if CS.Account.options.displayttc and TamrielTradeCentre and TamrielTradeCentrePrice then
      if c.data.info then
        TamrielTradeCentrePrice:AppendPriceInfo(c.text, c.data.info)
      elseif c.data.link then
        TamrielTradeCentrePrice:AppendPriceInfo(c.text, TamrielTradeCentre_ItemInfo:New(c.data.link))
      end
    end
    c.text:SetHidden(false)
  else
  if c.text == nil then
    return
  end
  ClearTooltip(c.text)
  c.text:SetHidden(true)
  c.text = nil
  end
end

function CS.TooltipShow(control,link,id)
  local function localizeStorage(storage)
  local localize = ""
  --skip checks for English
  if GetCVar('language.2') ~= 'en' then
    --temporarily translate
    if storage == CS.Lang.en.bank then
      localize = CS.Loc.bank
    end
    if storage:find(CS.Lang.en.housebank) then
      localize = storage:gsub(CS.Lang.en.housebank,CS.Loc.housebank)
    end
    if storage == CS.Lang.en.guildbank then
      localize = CS.Loc.guildbank
    end
    if storage == CS.Lang.en.craftbag then
      localize = CS.Loc.craftbag
    end
  end
  if localize == "" then
    localize = storage
  end
  return localize
  end
  local stripedLink = CS.StripLink(link)
  local it, specializedItemType = GetItemLinkItemType(link)
  local store, need, unneed = {}, '', ''
  if it == ITEMTYPE_RACIAL_STYLE_MOTIF then
    need, unneed = CS.IsStyleNeeded(link)
  elseif it == ITEMTYPE_RECIPE then
    if specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_ALCHEMY_FORMULA_FURNISHING or
       specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING or
       specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_CLOTHIER_PATTERN_FURNISHING or
       specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_ENCHANTING_SCHEMATIC_FURNISHING or
       specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_DESIGN_FURNISHING or
       specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_WOODWORKING_BLUEPRINT_FURNISHING or
       specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_JEWELRYCRAFTING_SKETCH_FURNISHING
    then
      need, unneed = CS.IsBlueprintNeeded(link)
    else
      need, unneed = CS.IsRecipeNeeded(link)
    end

  elseif it == ITEMTYPE_LURE then
    need = CS.IsBait(link)
  elseif it == ITEMTYPE_ENCHANTING_RUNE_POTENCY then
    if CS.Account.options.displayrunelevel then
      need = CS.IsPotency(link)
    end
  elseif CS.IsValidEquip(GetItemLinkEquipType(link)) then
    local craft,line,trait = CS.GetTrait(link)
    if CS.Account.options.displaystyles then
      local name = zo_strformat('<<C:1>>',GetItemStyleName(GetItemLinkItemStyle(link)))
      --Check for undefined names
      if name:find("Unused") then
        for index,data in pairs (CS.Loc.styleNames) do
          if index:lower() == name:lower() then
            name = zo_strformat('<<C:1>>',data)
          end
        end
      end
      control:AddLine('\n|cC5C29E'..ZOSF('<<ZC:1>>',name)..'|r','ZoFontGameSmall')
    end
    if craft and line and trait then
      need, unneed = CS.IsItemNeeded(craft,line,trait,id,link)
    end
  end
  if need ~= '' and CS.Account.options.displayunknown then
    control:AddLine(need,'CraftStoreFixedFont')
  end
  if unneed ~= '' and CS.Account.options.displayknown then
    control:AddLine(unneed,'CraftStoreFixedFont')
  end
  if CS.Account.options.showstock and CS.Account.storage[stripedLink] then
    if CS.Account.materials[stripedLink] and CS.Account.storage[CS.Account.materials[stripedLink].link] then
      local pairedInfo = CS.Account.materials[stripedLink]
      local prefix1, prefix2 = '', ''

      if pairedInfo.raw then
        prefix1 = 'Raw: '
        prefix2 = 'Refined: '
      else
        prefix1 = 'Refined: '
        prefix2 = 'Raw: '
      end
      for x, stock in pairs(CS.Account.storage[stripedLink]) do
        if stock and stock > 0 then
          table.insert(store,'|c8085FF'..localizeStorage(x)..':|r |cC0C5FF'..stock..'|r')
        end
      end
      if #store > 0 then
        control:AddLine(prefix1..table.concat(store,', '),'CraftStoreFixedFont')
      end
      store={}
      for x, stock in pairs(CS.Account.storage[pairedInfo.link]) do
        if stock and stock > 0 then
          table.insert(store,'|c8085FF'..localizeStorage(x)..':|r |cC0C5FF'..stock..'|r')
        end
      end
      if #store > 0 then
        control:AddLine(prefix2..table.concat(store,', '),'CraftStoreFixedFont')
      end
    else
      for x, stock in pairs(CS.Account.storage[stripedLink]) do
        if stock and stock > 0 then
          table.insert(store,'|c8085FF'..localizeStorage(x)..':|r |cC0C5FF'..stock..'|r')
        end
      end
      if #store > 0 then
        control:AddLine(table.concat(store,', '),'CraftStoreFixedFont')
      end
    end
  end
  store = nil
end

function CS.TooltipHandler()
  local tt=ItemTooltip.SetBagItem
  ItemTooltip.SetBagItem=function(control,bagId,slotIndex,...)
    tt(control,bagId,slotIndex,...)
    local itemLink = GetItemLink(bagId,slotIndex)
    local uID = GetItemUniqueId(bagId,slotIndex)
    CS.TooltipShow(control,itemLink,Id64ToString(uID))
  end
  local tt=ItemTooltip.SetWornItem
  ItemTooltip.SetWornItem=function(control,slotIndex,...)
    tt(control,slotIndex,...)
    local itemLink = GetItemLink(BAG_WORN,slotIndex)
    local uID = GetItemUniqueId(BAG_WORN,slotIndex)
    CS.TooltipShow(control,itemLink,Id64ToString(uID))
  end
  local tt=ItemTooltip.SetLootItem
  ItemTooltip.SetLootItem=function(control,lootId,...)
    tt(control,lootId,...)
    CS.TooltipShow(control,GetLootItemLink(lootId))
  end
  local ResultTooltip=ZO_SmithingTopLevelCreationPanelResultTooltip
  local tt=ResultTooltip.SetPendingSmithingItem
  ResultTooltip.SetPendingSmithingItem=function(control,pid,mid,mq,sid,tid)
    tt(control,pid,mid,mq,sid,tid)
    CS.TooltipShow(control,GetSmithingPatternResultLink(pid,mid,mq,sid,tid))
  end
  local tt=PopupTooltip.SetLink
  PopupTooltip.SetLink=function(control,link,...)
    tt(control,link,...)
    CS.TooltipShow(control,link)
  end
  local tt=ItemTooltip.SetLink
  ItemTooltip.SetLink=function(control,link,...)
    tt(control,link,...)
    CS.TooltipShow(control,link)
  end
  local tt=ItemTooltip.SetAttachedMailItem
  ItemTooltip.SetAttachedMailItem=function(control,openMailId,attachmentIndex,...)
    tt(control,openMailId,attachmentIndex,...)
    CS.TooltipShow(control,GetAttachedItemLink(openMailId,attachmentIndex))
  end
  local tt=ItemTooltip.SetBuybackItem
  ItemTooltip.SetBuybackItem=function(control,index,...)
    tt(control,index,...)
    CS.TooltipShow(control,GetBuybackItemLink(index))
  end
  local tt=ItemTooltip.SetTradingHouseItem
  ItemTooltip.SetTradingHouseItem=function(control,tradingHouseIndex,...)
    tt(control,tradingHouseIndex,...)
    CS.TooltipShow(control,GetTradingHouseSearchResultItemLink(tradingHouseIndex))
  end
  local tt=ItemTooltip.SetTradingHouseListing
  ItemTooltip.SetTradingHouseListing=function(control,tradingHouseListingIndex,...)
    tt(control,tradingHouseListingIndex,...)
    CS.TooltipShow(control,GetTradingHouseListingItemLink(tradingHouseListingIndex))
  end
  local tt=ItemTooltip.SetTradeItem
  ItemTooltip.SetTradeItem=function(control,tradeWho,slotIndex,...)
    tt(control,tradeWho,slotIndex,...)
    CS.TooltipShow(control,GetTradeItemLink(tradeWho,slotIndex))
  end
  local tt=ItemTooltip.SetQuestReward
  ItemTooltip.SetQuestReward=function(control,rewardIndex,...)
    tt(control,rewardIndex,...)
    CS.TooltipShow(control,GetQuestRewardItemLink(rewardIndex))
  end
end
function CS.ControlCloseAll(preview)
  CraftStoreFixed_CharacterPanel:SetHidden(true)
  CS.CloseRecipeWindow()
  CraftStoreFixed_Style_Window:SetHidden(true)
  CraftStoreFixed_SetPanel:SetHidden(true)
  if not preview then
    CS.CloseBlueprintWindow()
  end
  SM:HideTopLevel(CraftStoreFixed_Panel)
  CS.RuneView(2)
end
function CS.ControlShow(scene)
  local closed = scene:IsHidden()
  CraftStoreFixed_CharacterPanel:SetHidden(true)
  CS.CloseRecipeWindow()
  CS.CloseBlueprintWindow()
  CraftStoreFixed_Style_Window:SetHidden(true)
  CraftStoreFixed_SetPanel:SetHidden(true)
  --Don't close when enchanting
  if ZO_EnchantingTopLevel:IsHidden() then
  CraftStoreFixed_Rune:SetHidden(true)
  end
  --Update sets if set panel
  if scene == CraftStoreFixed_SetPanel then
  CS.SetsSet()
  end
  if closed then
    scene:SetHidden(false)
    if scene:GetType() == CT_TOPLEVELCONTROL then
      scene:BringWindowToTop()
    end
  end
end

function CS.ShowMain()
  SM:ToggleTopLevel(CraftStoreFixed_Panel)
    if not CraftStoreFixed_Panel:IsHidden() then
    CS.GetQuest()
    local questText = ''
    for _, quest in pairs(CS.Quest) do
      if questText ~= '' then
        questText = questText..'\n\n'
      end
      questText = questText..quest.name
      for _, step in pairs(quest.work) do
        questText = questText..'\n'..step
      end
    end
    if questText ~= '' then
      CraftStoreFixed_PanelQuestButton.data = { info = questText }
    else
      CraftStoreFixed_PanelQuestButton.data = nil
    end
    if CS.Account.mainchar then
      CS.SelectedPlayer = CS.Account.mainchar
    end
    CS.UpdatePlayer()
    CS.UpdateScreen()
    if CS.Account.timer[12] > 0 then
      CraftStoreFixed_Panel12Hours:SetText(CS.GetTime(CS.Account.timer[12] - GetTimeStamp()))
    else
      CraftStoreFixed_Panel12Hours:SetText('12:00h')
    end
    if CS.Account.timer[24] > 0 then
      CraftStoreFixed_Panel24Hours:SetText(CS.GetTime(CS.Account.timer[24] - GetTimeStamp()))
    else
      CraftStoreFixed_Panel24Hours:SetText('24:00h')
    end
  end
end

--closes blueprint window and removes anchors
function CS.CloseBlueprintWindow()
  CraftStoreFixed_Blueprint_Window:SetHidden(true)
  for x = 1,CraftStoreFixed_BlueprintPanelScrollChild:GetNumChildren() do
    CS.HideControl('CraftStoreFixed_BlueprintPanelScrollChildButton'..x)
  end
end

--creates blueprint child button if it doesn't exist
function CS.GetBlueprintChild(id)
  local btn = WM:GetControlByName('CraftStoreFixed_BlueprintPanelScrollChildButton'..id)
  if btn == nil then
    btn = WM:CreateControl('CraftStoreFixed_BlueprintPanelScrollChildButton'..id,CraftStoreFixed_BlueprintPanelScrollChild,CT_BUTTON)
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 22)
    btn:SetDimensions(508,22)
    btn:SetFont('CraftStoreFixedFont')
    btn:SetHidden(true)
    btn:EnableMouseButton(1,false)
    btn:EnableMouseButton(2,true)
    btn:EnableMouseButton(3,true)
    btn:SetClickSound('Click')
    btn:SetMouseOverFontColor(1,0.66,0.2,1)
    btn:SetHorizontalAlignment(0)
    btn:SetVerticalAlignment(1)
    btn:SetHandler('OnMouseEnter',function(self) CS.Tooltip(self,true,false,CraftStoreFixed_Blueprint,'tl') end)
    btn:SetHandler('OnMouseExit',function(self) CS.Tooltip(self,false) end)
    btn:SetHandler('OnMouseDown',function(self,button) CS.BlueprintMark(self,button) end)
  elseif btn:GetAnchor() == false then
    btn:SetAnchor(3,nil,3,8,5 + (id-1) * 22)
  end
  return WM:GetControlByName('CraftStoreFixed_BlueprintPanelScrollChildButton'..id)
end

function CS.BlueprintMark(control,button)
  local mark
  if button == 2 then
    CS.ToChat(control.data.link)
  else
    local tracked = CS.Account.furnisher.ingredients[control.data.id] or false
    if tracked then
      mark = ''
      CS.Account.furnisher.ingredients[control.data.id] = nil
    else
      mark = '|t22:22:esoui/art/inventory/newitem_icon.dds|t '
      CS.Account.furnisher.ingredients[control.data.id] = true
    end
    control:SetText(mark..'('..CS.Furnisher.recipe[control.data.rec].level..') '..CS.Furnisher.recipe[control.data.rec].name)
    zo_callLater(CS.UpdateIngredientTracking,500)
  end
end
function CS.BlueprintShow(id,inc)
  local color, mark, control
  if CS.Account.furnisher.ingredients[CS.Furnisher.recipe[id].id] then
    mark = '|t22:22:esoui/art/inventory/newitem_icon.dds|t '
  else
    mark = ''
  end
  if CS.Furnisher.recipe[id].known then
    color = CS.Quality[CS.Furnisher.recipe[id].quality]
  else
    color = {1,0,0,1}
  end
  control = CS.GetBlueprintChild(inc)
  control:SetNormalFontColor(color[1],color[2],color[3],color[4])
  control:SetText(mark..'('..CS.Furnisher.recipe[id].level..') '..CS.Furnisher.recipe[id].name)
  control:SetHidden(false)
  control.data = {link = CS.Furnisher.recipe[id].link, rec = id, id = CS.Furnisher.recipe[id].id, buttons = {CS.Loc.TT[6],CS.Loc.TT[7]}}
  return inc + 1
end
function CS.BlueprintShowCategory(list)
  if list == nil or list > 7 then
    list = 1
  end
  local inc, known, total = 1, 0, 0
  for x = 1,CraftStoreFixed_BlueprintPanelScrollChild:GetNumChildren() do
    CS.HideControl('CraftStoreFixed_BlueprintPanelScrollChildButton'..x)
  end
  for id, recipe in pairs(CS.Furnisher.recipe) do
    if recipe.stat == list then
      if CS.Furnisher.recipe[id].known then
        known = known+1
      end
      total = total+1
      --If hide known is false and it is known, show it. If hide unknown is false and it is unknown, show it.
      if (not CS.Character.hideKnownBlueprints and CS.Furnisher.recipe[id].known) or (not CS.Character.hideUnknownBlueprints and not CS.Furnisher.recipe[id].known) then
        inc = CS.BlueprintShow(id,inc)
      end
    end
  end
  CraftStoreFixed_BlueprintPanelScrollChild:SetHeight(inc * 22 - 13)
  CraftStoreFixed_BlueprintHeadline:SetText(ZOSF('<<C:1>>',GetString('SI_RECIPECRAFTINGSYSTEM',list)))
  --If hiding both
  if CS.Character.hideKnownBlueprints and CS.Character.hideUnknownBlueprints then
    CraftStoreFixed_BlueprintInfo:SetText('(0 / '..total..')')
  --If showing known/both
  elseif not CS.Character.hideKnownBlueprints then
  CraftStoreFixed_BlueprintInfo:SetText('('..known..' / '..total..')')
  --If only showing unknown
  elseif not CS.Character.hideUnknownBlueprints  then
    CraftStoreFixed_BlueprintInfo:SetText('('..(total-known)..' / '..total..')')
  end
  CS.Character.furniture = list
end
function CS.BlueprintSearch()
  local search, inc, known = CraftStoreFixed_BlueprintSearch:GetText(), 1, 0
  if search ~= '' then
    for x = 1,CraftStoreFixed_BlueprintPanelScrollChild:GetNumChildren() do
      local control = CS.GetBlueprintChild(x)
      control:SetHidden(true)
      control.data = nil
    end
  --If showing at least one
  if not CS.Character.hideKnownBlueprints or not CS.Character.hideUnknownBlueprints then
    for id, food in pairs(CS.Furnisher.recipe) do
      local proceed = false
      if string.find(string.lower(food.name),string.lower(search)) then
        --If showing only one ensure it is met
        if (not CS.Character.hideKnownBlueprints and not CS.Character.hideUnknownBlueprints) or
          (CS.Character.hideUnknownBlueprints and CS.Furnisher.recipe[id].known) or
          (CS.Character.hideKnownBlueprints and not CS.Furnisher.recipe[id].known) then
          --Check if the hard coded limit has been met, if so stop and give an error
          if inc > blueprint_limit then
            CS.Chat:Print(CS.Loc.blueprintSearchLimit)
            break
          else
            inc = CS.BlueprintShow(id,inc)
          end
        end
      end
    end
  end
    CraftStoreFixed_BlueprintPanelScrollChild:SetHeight(inc * 22 - 13)
    CraftStoreFixed_BlueprintHeadline:SetText(CS.Loc.searchfor)
    CraftStoreFixed_BlueprintInfo:SetText(search..' ('..(inc - 1)..')')
  end
end
function CS.BlueprintLearned(list,id)
  local link = GetRecipeResultItemLink(list,id,LINK_STYLE_DEFAULT)
  if link then
    for id, recipe in pairs(CS.Furnisher.recipe) do
      if recipe.result == link then
        CS.Furnisher.recipe[id].known = true
        CS.Data.furnisher.knowledge[CS.CurrentPlayer][CS.Furnisher.recipe[id].id] = true
        break
      end
    end
  end
end


if CS.Debug then

  --[[
  function CS.ListItems(begin, count)
    begin = tonumber(begin)
    for i=begin,begin+100 do
      d('|H1:item:'..i..':5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h')
    end
  end


  function CS.PerfomanceTest(args)
    local start = 0
    local endt = 0
    local count, count2 = zo_strsplit(' ',args)
    count = tonumber(count)
    count2 = tonumber(count2)

    local test_1 = {}
    test_2 = {}
    test_2.test_3 = {}
    test_5 = {}
    local test_4 = test_2.test_3
    start = GetTimeStamp()
    for j = 1, count2 do
      for i = 1,count do
        test_1[i] = i
      end
      test_1 = {}
    end
    endt = GetTimeStamp()
    d("Local: "..(endt-start))
    start = GetTimeStamp()
    for j = 1, count2 do
      for i = 1,count do
        test_4[i] = i
      end
      test_4 = {}
    end
    endt = GetTimeStamp()
    d("Referenced: "..(endt-start))
    start = GetTimeStamp()
    for j = 1, count2 do
      for i = 1,count do
        test_5[i] = i
      end
      test_5 = {}
    end
    endt = GetTimeStamp()
    d("Global: "..(endt-start))
  end
  SLASH_COMMANDS["/list"] = CS.ListItems
  SLASH_COMMANDS["/perf"] = CS.PerfomanceTest]]
  _CS = CS
  SLASH_COMMANDS["/_"] = function() CS.Chat:Print(_G["_"]) end
  SLASH_COMMANDS["//"] = SLASH_COMMANDS["/reloadui"]
  SLASH_COMMANDS["/langfr"] = function() SetCVar("language.2", "fr") end
  SLASH_COMMANDS["/langen"] = function() SetCVar("language.2", "en") end
  SLASH_COMMANDS["/langde"] = function() SetCVar("language.2", "de") end
end

SLASH_COMMANDS["/cs"] = CS.ShowMain
SLASH_COMMANDS["/craftstore"] = CS.ShowMain
SLASH_COMMANDS["/cspurge"] = CS.StoragePurge
SLASH_COMMANDS["/csrepair"] = CS.RepairStored
SLASH_COMMANDS["/csrepairknowledge"] = CS.UpdateRecipeKnowledge
SLASH_COMMANDS["/csremovechar"] = CS.RemoveCharacter
