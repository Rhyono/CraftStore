CS = CraftStoreFixedAndImprovedLongClassName

function CS.LMMAdd()
	if not LibStub or LibStub.libs["LibMainMenu-2.0"] == nil then
		return false
	end
	
	local LMM2 = LibStub("LibMainMenu-2.0")
	LMM2:Init()
	 
	-- Add to main menu
	local categoryLayoutInfo =
	{
		binding = "SHOW_CRAFTSTOREFIXED_WINDOW",
		categoryName = SI_BINDING_NAME_CRAFTSTORE,
		callback = function(buttonData)
			CraftStoreFixed_Panel:SetHidden(not CraftStoreFixed_Panel:IsHidden())
		end,
		visible = function(buttonData) return true end,
	 
		normal = "CraftStoreFixedAndImproved/DDS/cs.dds",
		pressed = "CraftStoreFixedAndImproved/DDS/cs.dds",
		highlight = "CraftStoreFixedAndImproved/DDS/cs.dds",
		disabled = "CraftStoreFixedAndImproved/DDS/cs.dds",
	}
	 
	LMM2:AddMenuItem(CS.Title, categoryLayoutInfo)
end