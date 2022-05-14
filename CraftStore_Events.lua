local CS = CraftStoreFixedAndImprovedLongClassName
local LAM = LibAddonMenu2

local EM, WM, SM, ZOSF = EVENT_MANAGER, WINDOW_MANAGER, SCENE_MANAGER, zo_strformat
function CS.OnQuestConditionCounterChanged(eventCode,journalIndex)
  CS.UpdateQuest(journalIndex)
end

function CS.OnRecipeLearned(eventCode,list,id)
  CS.RecipeLearned(list,id)
  CS.BlueprintLearned(list,id)
end

function CS.OnStyleLearned(eventCode, styleIndex, chapterIndex, isDefaultRacialStyle)
  CS.UpdateStyleKnowledge(true) 
end

function CS.OnSmithingTraitResearchStarted(eventCode, craft, line, trait)
  local _,remaining = GetSmithingResearchLineTraitTimes(craft,line,trait)
  if remaining then CS.Data.crafting.researched[CS.CurrentPlayer][craft][line][trait] = remaining + GetTimeStamp() end
  CS.Account.crafting.stored[craft][line][trait] = {}
  CS.UpdateResearchWindows()
  CS.UpdatePanelIcon(craft,line,trait)
  CS.GetTimer()
end

function CS.OnSmithingTraitResearchChange(eventCode, craft, line, trait)
	CS.UpdateResearch()	
	CS.UpdateResearchWindows()
end

function CS.OnStableInteractEnd(eventCode)
  CS.GetTimer()
end

function CS.OnCraftingStationInteract(eventCode,craftSkill)
  -- Provisioning level is needed for both the enchanting and provisioning level due to furniture
  if CS.Account.options.usecook or CS.Account.options.userune then
	if craftSkill == CRAFTING_TYPE_PROVISIONING or craftSkill == CRAFTING_TYPE_ENCHANTING then
      CS.Cook.craftLevel = GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_LEVEL)
      CS.Cook.qualityLevel = GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL)	
	end
  end
  if CS.Account.options.usecook and craftSkill == CRAFTING_TYPE_PROVISIONING then
      CS.CookShowCategory(CS.Character.recipe)
      CraftStoreFixed_CookAmount:SetText('')
      CraftStoreFixed_CookSearch:SetText(GetString(SI_GAMEPAD_HELP_SEARCH)..'...')
      CraftStoreFixed_Cook:SetHidden(false)
      for x = 2, ZO_ProvisionerTopLevel:GetNumChildren() do ZO_ProvisionerTopLevel:GetChild(x):SetAlpha(0) end
      ZO_KeybindStripControl:SetHidden(not IsInGamepadPreferredMode())
	  --Update space
	  CS.InventorySpace(CraftStoreFixed_CookSpaceButtonName)	  
  end
  if CS.Account.options.userune and craftSkill == CRAFTING_TYPE_ENCHANTING then
      CS.Extern = false
	-- use CS interface?
	local useCSRune = true
	if (not CS.Account.options.userunecreation and CS.Character.runemode == 'craft') or 
		(not CS.Account.options.useruneextraction and CS.Character.runemode == 'refine') or
		(not CS.Account.options.userunerecipe and CS.Character.runemode == 'furniture')
	then
		useCSRune = false
	end
      CS.RuneInitialize(useCSRune)
      CS.RuneHideVanillaUI(useCSRune)
	  CS.RuneShowMode()
      local soundPlayer = CRAFTING_RESULTS.enchantSoundPlayer
      soundPlayer.PlaySound = function() return end
	  --Update space
	  CS.InventorySpace(CraftStoreFixed_RuneSpaceButtonName)	  
  end
  -- if CS.Account.options.useflask then
    -- if craftSkill == CRAFTING_TYPE_ALCHEMY then
      -- CS_Flask:SetHidden(false)
    -- end
  -- end
  if CS.Account.options.usequest then
    CS.GetQuest()
    if CS.Quest[craftSkill] then
      local title = CS.Quest[craftSkill].name..'\n'
      local out = ''
      for _, step in pairs(CS.Quest[craftSkill].work) do out = out..step..'\n' end
	  if CS.Quest[craftSkill] then     
	    CraftStoreFixed_QuestText:SetText(title..out)
	    CraftStoreFixed_Quest:SetHidden(false)
	  end
    end
  end
  --Handle updating research
  if craftSkill == CRAFTING_TYPE_BLACKSMITHING or craftSkill == CRAFTING_TYPE_CLOTHIER or craftSkill == CRAFTING_TYPE_WOODWORKING or craftSkill == CRAFTING_TYPE_JEWELRYCRAFTING then
	CS.UpdateResearch()
	CS.UpdateResearchWindows()	
  end
end

function CS.OnCraftCompleted(eventCode,craftSkill)
  local val = GetLastCraftingResultTotalInspiration()
    if val > 0 then CS.Inspiration = '|t30:30:/esoui/art/currency/currency_inspiration.dds|t |c9095FF'..val..'|r' end
    if CS.Account.options.usecook and craftSkill == CRAFTING_TYPE_PROVISIONING then
      CraftStoreFixed_CookAmount:SetText('')
      zo_callLater(function() CS.CookShowCategory(CS.Character.recipe,false) end,500)
	  --Update space
	  CS.InventorySpace(CraftStoreFixed_CookSpaceButtonName)	  
    end
    if CS.Account.options.userune and craftSkill == CRAFTING_TYPE_ENCHANTING then
        CraftStoreFixed_RuneAmount:SetText('')
      if CS.Rune.refine.glyphs[1] then
        local remove = true
        while remove do
          if CS.Rune.refine.glyphs[1] and CS.Rune.refine.glyphs[1].crafted and not CS.Rune.refine.crafted then 
            table.remove(CS.Rune.refine.glyphs,1) 
          else
            remove = false 
          end
        end
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
      end
	  --Update space
	  CS.InventorySpace(CraftStoreFixed_RuneSpaceButtonName)
      zo_callLater(function() CS.RuneShowMode(true) end,500)
    end
    CS.UpdateBag()
end

function CS.OnEndCraftingStationInteract(eventCode, craftSkill)	
	CraftStoreFixed_Quest:SetHidden(true)
	--CraftStoreFixed_Flask:SetHidden(true)
	CS.UIClosed = true
	
	if CS.Account.options.usecook and craftSkill == CRAFTING_TYPE_PROVISIONING then
		CraftStoreFixed_Cook:SetHidden(true)
		for x = 2, ZO_ProvisionerTopLevel:GetNumChildren() do ZO_ProvisionerTopLevel:GetChild(x):SetAlpha(1) end
		CS.Cook.job = {amount=0}
		for x = 1,CraftStoreFixed_CookFoodSectionScrollChild:GetNumChildren() do CS.HideControl('CraftStoreFixed_CookFoodSectionScrollChildButton'..x) end
	end
	if CS.Account.options.userune and craftSkill == CRAFTING_TYPE_ENCHANTING then
		CraftStoreFixed_Rune:SetHidden(true)
		CS.Extern = true
		for k in next,CS.Rune.refine.glyphs do CS.Rune.refine.glyphs[k] = nil end
		for x = 2, ZO_EnchantingTopLevel:GetNumChildren() do ZO_EnchantingTopLevel:GetChild(x):SetHidden(false) end
		CS.Rune.job = {amount=0}
		for x = 1,CraftStoreFixed_RuneGlyphSectionScrollChild:GetNumChildren() do CS.HideControl('CraftStoreFixed_RuneGlyphSectionScrollChildButton'..x) end
	end	
end

function CS.OnGameCameraUIModeChanged(eventCode)
	if CS.UIClosed then CS.UIClosed = false end
end

function CS.OnActionLayerPushed(eventCode, layerIndex, activeLayerIndex)
  if CS.UIClosed then ZO_KeybindStripControl:SetHidden(false) CS.UIClosed=false end 
end

function CS.NewMovementInUIMode(eventCode)
  if CS.Account.options.closeonmove and not CraftStoreFixed_Panel:IsHidden() then CS.ControlCloseAll() end
end

function CS.OnReticleHiddenUpdate(eventCode,hidden)
  if not hidden and not CraftStoreFixed_Rune:IsHidden() then CS.RuneView(2) end
end

function CS.OnPlayerActivated(eventCode,initial)
  CS.UpdateAccountVars()
  CS.UpdatePlayer()
  CS.UpdateStyleKnowledge(true)
  CS.UpdateRecipeKnowledge()
  CS.UpdateAllStudies()
  CS.UpdateInventory()
  CS.CharacterInitialize()
  CS.GetTimer()
  CS.InitPreviews()
  CS.UpdateResearch()
  CS.UpdateResearchWindows()  
  CS.UpdateBag()
  CS.HideStyles(true)
  CS.HideCrownStyles(true)
  CS.HidePerfectedStyles(true)
  CS.HideKnownBlueprints(true)
  CS.HideUnknownBlueprints(true)
  CS.HideKnownRecipes(true)
  CS.HideUnknownRecipes(true)
  CS.Init = true 
  EM:UnregisterForEvent('CSEE',EVENT_PLAYER_ACTIVATED)
end

function CS.OnPlayerDeactivated(eventCode)
  CS.UpdatePlayer(true)
  EM:UnregisterForEvent('CSEE',EVENT_PLAYER_DEACTIVATED)
end

function CS.OnChampionPerksSceneStateChange(oldState,newState)
  if newState == SCENE_SHOWING then
	  CS.ControlCloseAll()
      CraftStoreFixed_ButtonFrame:SetHidden(true)
    elseif newState == SCENE_HIDDEN then
      if CS.Account.options.showbutton then CraftStoreFixed_ButtonFrame:SetHidden(false) end
    end
end

function CS.HouseBankQuantity(bag,slot,link)
	if link == nil then link = false end
	local items = SHARED_INVENTORY:GenerateFullSlotData(nil,bag)
	--slot is used during initialize/add actions; link is used to sum during a remove
	if slot then
		link = CS.StripLink(GetItemLink(bag,slot))
	end	
	local quantity = 0
	for index,data in pairs(items) do
		if link == CS.StripLink(GetItemLink(data.bagId,data.slotIndex)) then
			local _,stack = GetItemInfo(data.bagId,data.slotIndex)
			quantity = quantity + stack
		end	
	end
	return quantity
end

function CS.OnInventorySlotAdded(bag,slot,data,replace)
  if not replace then replace = false end
  if bag ~= BAG_BACKPACK and bag~=BAG_BANK and bag~=BAG_SUBSCRIBER_BANK and bag~=BAG_VIRTUAL and not IsHouseBankBag(bag) then return end
  local link = CS.StripLink(GetItemLink(bag,slot))
  local a1, a2, a3 = GetItemLinkStacks(link)

  if not CS.Account.storage[link] then CS.Account.storage[link] = {} end
  --inline ternary did not work, handle line by line
  CS.Account.storage[link][CS.Lang.en.craftbag] = a3
  if a3 == 0 then CS.Account.storage[link][CS.Lang.en.craftbag] = nil end
	
  CS.Account.storage[link][CS.Lang.en.bank] = a2
  if a2 == 0 then CS.Account.storage[link][CS.Lang.en.bank] = nil end
  
  CS.Account.storage[link][CS.CurrentPlayer] = a1
  if a1 == 0 then CS.Account.storage[link][CS.CurrentPlayer] = nil end
  
  if IsHouseBankBag(bag) then
	if not CS.Account.storage[link][CS.Lang.en.housebank..(bag-7)] then
		CS.Account.storage[link][CS.Lang.en.housebank] = 0
	end	
	CS.Account.storage[link][CS.Lang.en.housebank..(bag-7)] = CS.HouseBankQuantity(bag,slot)
  end	
  CS.UpdateMatsInfo(link)
  data.uid = Id64ToString(GetItemUniqueId(bag,slot))
  data.lnk = link
  if CS.IsValidEquip(GetItemLinkEquipType(link)) then 
	if CS.IsLocked(bag,slot) then
		CS.UpdateStored('removed',data,replace)
	else	
		CS.UpdateStored('added',data)
	end
  end	
end
  
function CS.OnInventorySlotRemoved(bag,slot,data)
  if bag ~= BAG_BACKPACK and bag~=BAG_BANK and bag~=BAG_SUBSCRIBER_BANK and bag~=BAG_VIRTUAL and not IsHouseBankBag(bag) then return end
  local link = CS.StripLink(data.lnk)
  local a1, a2, a3 = GetItemLinkStacks(link)

  --inline ternary did not work, handle line by line
  CS.Account.storage[link][CS.Lang.en.craftbag] = a3
  if a3 == 0 then CS.Account.storage[link][CS.Lang.en.craftbag] = nil end
	
  CS.Account.storage[link][CS.Lang.en.bank] = a2
  if a2 == 0 then CS.Account.storage[link][CS.Lang.en.bank] = nil end
  
  CS.Account.storage[link][CS.CurrentPlayer] = a1
  if a1 == 0 then CS.Account.storage[link][CS.CurrentPlayer] = nil end
  if IsHouseBankBag(bag) then
	CS.Account.storage[link][CS.Lang.en.housebank..(bag-7)] = CS.HouseBankQuantity(bag,false,link)
  end  
  CS.UpdateMatsInfo(link)
  if CS.IsValidEquip(GetItemLinkEquipType(link)) then CS.UpdateStored('removed',data) end
end

function CS.OnStackSplitShow()
  if CS.Account.options.stacksplit then
    ZO_StackSplitSpinnerDisplay:TakeFocus()
    ZO_StackSplitSpinnerDisplay:SelectAll()
  end
end

function CS.OnInventorySingleSlotUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
  --Locked or unlocked, so replace it
  local replace = inventoryUpdateReason == 4 and true or false
  CS.OnInventorySlotAdded(bagId, slotId, {bagId=bagId},replace)
end

function CS.OnMoneyUpdate(eventCode, newMoney, oldMoney, reason)
  if reason == 42 or reason == 43 then
    CS.Character.income[2] = CS.Character.income[2] + newMoney - oldMoney
  end
end

-- hooks for the default rune interface
function CS.RuneCreationTabShow()
	CS.Character.runemode = 'craft'
	if CS.Account.options.userune and CS.Account.options.userunecreation then
		CS.RuneShowMode()
	end
end

function CS.RuneExtractionTabShow()
	CS.Character.runemode = 'refine'
	if CS.Account.options.userune and CS.Account.options.useruneextraction then
		CS.RuneShowMode()
	end
end

function CS.RuneRecipeTabShow()
	CS.Character.runemode = 'furniture'
	if CS.Account.options.userune then
		CS.RuneShowMode()
	end
end

function CS.OnAddOnLoaded(eventCode,addOnName)
  if addOnName ~= CS.Name then return end
  
  CS.Style = CS.STYLE()
  CS.Style.RemoveUnpublishedStyles()
  CS.Style.CompileStyles()
  CS.Style.CompilePartialStyles({[114]=true,[119]=true})
  CS.Crafting.CompileTraits()
  --cs_flask = CS.CS.Flask()  
  CS.Account = ZO_SavedVars:NewAccountWide('CraftStore_Account',3,GetWorldName(),CS.AccountInit)
  CS.Character = ZO_SavedVars:NewCharacterIdSettings('CraftStore_Character',2,GetWorldName(),CS.CharInit)

  -- remove unpublished furnishing recipies
  CS.Furnisher.recipelist = CS.FilterPublishedItems(CS.Furnisher.recipelist)

	--build schema for data
	LBE:DefinePrefix("CSCK28",CS.Name,CS.LBE.Cook,64,LBE:ConvertTable(LBE:ConcatTables(CS.Cook.recipelist,CS.Cook.recipeduplicatelist)))
	LBE:DefinePrefix("CSFK32",CS.Name,CS.LBE.Furnisher,64,LBE:ConvertTable(CS.Furnisher.recipelist))
	LBE:DefinePrefix("CSSK29",CS.Name,CS.LBE.Styles.."Old",64,LBE:ConvertTable(CS.Styles.oldlist))
	LBE:DefinePrefix("CSSK32",CS.Name,CS.LBE.Styles,64,LBE:ConvertTable(CS.Styles.list))
	LBE:DefinePrefix("CSCS29",CS.Name,CS.LBE.Crafting,64,CS.Crafting.list)
	LBE:DefinePrefix("CSCR29",CS.Name,CS.LBE.Researched,64,CS.Crafting.list) -- intentionally same schema as CSCS, but unique prefix needed
	-- only applicable for characters with saved vars already
	for nr, char in pairs(CS.GetCharacters()) do
		local temp = {}
		--cooking knowledge
		CS.Data.cook.knowledge[char] = LBE:ParseTrusted(CS.Account.cook.knowledge[char],CS.Name,CS.LBE.Cook)

		--furnishing knowledge
		CS.Data.furnisher.knowledge[char] = LBE:ParseTrusted(CS.Account.furnisher.knowledge[char],CS.Name,CS.LBE.Furnisher)
		
		--style knowledge
		CS.Data.style.knowledge[char] = LBE:ParseTrusted(CS.Account.style.knowledge[char],CS.Name,CS.LBE.Styles)
		
		--trait tracking
		CS.Data.crafting.studies[char] = LBE:ParseTrusted(CS.Account.crafting.studies[char],CS.Name,CS.LBE.Crafting)
		
		--researched tracking
		CS.Data.crafting.researched[char] = LBE:MergeTables(CS.Account.crafting.researching[char],LBE:ParseTrusted(CS.Account.crafting.researched[char],CS.Name,CS.LBE.Researched))	
	end
	
	-- temporary saved var cleanup
	CS.Account.crafting.research = nil

  if CS.Character.income[1] ~= GetDate()then
    CS.Character.income[1] = GetDate()
    CS.Character.income[2] = GetCurrentMoney()
  end 
 
  ZO_CreateStringId('SI_BINDING_NAME_SHOW_CRAFTSTOREFIXED_WINDOW',CS.Loc.TT[15])
  SM:RegisterTopLevel(CraftStoreFixed_Panel,false)
  EM:RegisterForEvent('CSEE',EVENT_QUEST_CONDITION_COUNTER_CHANGED,CS.OnQuestConditionCounterChanged)
  EM:RegisterForEvent("CSEE",EVENT_RECIPE_LEARNED,CS.OnRecipeLearned)
  EM:RegisterForEvent('CSEE',EVENT_STYLE_LEARNED,CS.OnStyleLearned)
  EM:RegisterForEvent('CSEE',EVENT_TRADING_HOUSE_RESPONSE_RECEIVED,CS.UpdateGuildStore)
  EM:RegisterForEvent('CSEE',EVENT_SMITHING_TRAIT_RESEARCH_STARTED,CS.OnSmithingTraitResearchStarted)
  EM:RegisterForEvent('CSEE',EVENT_STABLE_INTERACT_END,CS.OnStableInteractEnd)
  EM:RegisterForEvent('CSEE',EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED,CS.OnSmithingTraitResearchChange)
  EM:RegisterForEvent('CSEE',EVENT_SMITHING_TRAIT_RESEARCH_CANCELED,CS.OnSmithingTraitResearchChange)
  EM:RegisterForEvent('CSEE',EVENT_CRAFTING_STATION_INTERACT,CS.OnCraftingStationInteract)
  EM:RegisterForEvent('CSEE',EVENT_INVENTORY_FULL_UPDATE,CS.UpdateBag)
  EM:RegisterForEvent('CSEE',EVENT_CRAFT_COMPLETED,CS.OnCraftCompleted)
  EM:RegisterForEvent('CSEE',EVENT_END_CRAFTING_STATION_INTERACT,CS.OnEndCraftingStationInteract)
  EM:RegisterForEvent('CSEE',EVENT_GAME_CAMERA_UI_MODE_CHANGED,CS.OnGameCameraUIModeChanged)
  EM:RegisterForEvent('CSEE',EVENT_ACTION_LAYER_PUSHED,CS.OnActionLayerPushed)
  EM:RegisterForEvent('CSEE',EVENT_NEW_MOVEMENT_IN_UI_MODE,CS.NewMovementInUIMode)
  EM:RegisterForEvent('CSEE',EVENT_RETICLE_HIDDEN_UPDATE,CS.OnReticleHiddenUpdate)
  EM:RegisterForEvent('CSEE',EVENT_PLAYER_ACTIVATED,CS.OnPlayerActivated)
  EM:RegisterForEvent('CSEE',EVENT_PLAYER_DEACTIVATED,CS.OnPlayerDeactivated)
  EM:RegisterForEvent('CSEE',EVENT_INVENTORY_SINGLE_SLOT_UPDATE, CS.OnInventorySingleSlotUpdate)
  EM:RegisterForEvent('CSEE',EVENT_MONEY_UPDATE, CS.OnMoneyUpdate)
  
  --Esc close
  --SCENE_MANAGER:RegisterTopLevel(CraftStoreFixed_Blueprint_Window, false)
  --SCENE_MANAGER:RegisterTopLevel(CraftStoreFixed_Recipe_Window, false)
  --SCENE_MANAGER:RegisterTopLevel(CraftStoreFixed_Style_Window, false)
  --SCENE_MANAGER:RegisterTopLevel(CraftStoreFixed_Rune, false)
  
  CHAMPION_PERKS_SCENE:RegisterCallback('StateChange',CS.OnChampionPerksSceneStateChange)
  
  SHARED_INVENTORY:RegisterCallback('SlotAdded',CS.OnInventorySlotAdded)
  SHARED_INVENTORY:RegisterCallback('SlotRemoved',CS.OnInventorySlotRemoved)
  ZO_PreHookHandler(ZO_StackSplit,'OnShow', CS.OnStackSplitShow)
  ZO_PreHookHandler(ZO_EnchantingTopLevelModeMenuBarButton1,'OnMouseDown', CS.RuneCreationTabShow)
  ZO_PreHookHandler(ZO_EnchantingTopLevelModeMenuBarButton2,'OnMouseDown', CS.RuneExtractionTabShow)
  ZO_PreHookHandler(ZO_EnchantingTopLevelModeMenuBarButton3,'OnMouseDown', CS.RuneRecipeTabShow)
  
  CS.LAM = LAM:RegisterAddonPanel(CS.Name, CS.PanelData)
  LAM:RegisterOptionControls(CS.Name, CS.OptionsTable)
  
  CS.ScrollText()
  CS.TooltipHandler()
  if type(CS.Character.previewtype) == "string" or not CS.Character.previewType then CS.Character.previewtype=1 end
  CS.Style.UpdatePreview(CS.Character.previewtype)
  CS.PanelInitialize()
  
  --CS.LMMAdd()
  EM:UnregisterForEvent('CSEE',EVENT_ADD_ON_LOADED)
end

EM:RegisterForEvent('CSEE',EVENT_ADD_ON_LOADED,CS.OnAddOnLoaded)