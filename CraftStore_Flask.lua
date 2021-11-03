-- ZO_Alchemy_IsThirdAlchemySlotUnlocked()

function CraftStoreFixedAndImprovedLongClassName.FLASK()
    local self = {
        noBad = true,
        three = true,
        selectedSolvent = nil
    }
    local trait, plant, result, found = {0,0,0}, {0,0,0}, {}, {}
    local solvent = {883,1187,4570,23265,23266,23267,23268,64500,64501}
    local reagent = {
    {30165,2,14,12,23}, --1
    {30158,9,3,18,13},  --2
    {30155,6,8,1,22},   --3
    {30152,18,2,9,4},   --4
    {30162,7,5,16,11},  --5
    {30148,4,10,1,23},  --6
    {30149,16,2,7,6},   --7
    {30161,3,9,2,24},   --8
    {30160,17,1,10,3},  --9
    {30154,10,4,17,12}, --10
    {30157,5,7,2,21},   --11
    {30151,2,4,6,20},   --12
    {30164,1,3,5,19},   --13
    {30159,11,22,24,19},--14
    {30163,15,1,8,5},   --15
    {30153,13,21,23,19},--16
    {30156,8,6,15,12},  --17
    {30166,1,13,11,20}  --18
  }
    local path = 'esoui/art/icons/alchemy/crafting_alchemy_trait_'
    local icon = {
    'restorehealth','ravagehealth',
    'restoremagicka','ravagemagicka',
    'restorestamina','ravagestamina',
    'increaseweaponpower','lowerweaponpower',
    'increasespellpower','lowerspellpower',
    'weaponcrit','lowerweaponcrit',
    'spellcrit','lowerspellcrit',
    'increasearmor','lowerarmor',
    'increasespellresist','lowerspellresist',
    'unstoppable','stun',
    'speed','reducespeed',
    'invisible','detection',
  }

    local function Quality(nr,a,hex)
      local quality = {[0]={0.65,0.65,0.65,a},[1]={1,1,1,a},[2]={0.17,0.77,0.05,a},[3]={0.22,0.57,1,a},[4]={0.62,0.18,0.96,a},[5]={0.80,0.66,0.10,a}}
      local qualityhex = {[0]='B3B3B3',[1]='FFFFFF',[2]='2DC50E',[3]='3A92FF',[4]='A02EF7',[5]='EECA2A'}
      if hex then return qualityhex[nr] else return unpack(quality[nr]) end
    end

    local function SplitLink(link,nr)
      local split = {SplitString(':', link)}
      if split[nr] then return tonumber(split[nr]) else return false end
    end

    function self.GetTraitIcon(nr)
      return path..icon[nr]..'.dds'
    end

    function self.GetReagent(nr)
        local link, icon, bag, bank
        link = ('|H1:item:%u:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'):format(reagent[nr][1])
        icon = GetItemLinkInfo(link)
        bag, bank = GetItemLinkStacks(link)
        return icon, (bag + bank), link
    end

    local function GetReagentBagSlot(nr)
      local bag, id = SHARED_INVENTORY:GenerateFullSlotData(nil,BAG_BACKPACK,BAG_BANK), reagent[nr][1]
      for _,data in pairs(bag) do
        local scanid = SplitLink(GetItemLink(data.bagId,data.slotIndex),3)
        if id == scanid then return data.bagId, data.slotIndex end
      end
    end

    function self.SetTraits(traits)
        trait = traits
    end

    local function IsBad(val)
      if val%2 == 0 and val < 24 then return true end
      return false
    end

    local function GetAntiTrait(val)
      if val%2 == 0 then return val - 1 end
      return val + 1
    end

    local function GetTraits()
      local cur, acur
      found = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
      for _,x in pairs(plant) do
        for a = 2,5 do
          cur = reagent[x][a]
          acur = GetAntiTrait(cur)
        found[cur] = found[cur] + 1
        found[acur] = found[acur] - 1
        end
      end
      if self.noBad then for x,y in pairs(found) do if IsBad(x) and y > 1 then found = false; return end end end
    end

    local function SetResult()
        local ok, t = {false,false,false}
        GetTraits()
        if found then
            for i = 1,3 do
                t = trait[i]
                if t then if found[t] and found[t] > 1 then ok[i] = true end
                else ok[i] = true end
            end 
            if ok[1] and ok[2] and ok[3] then
                for nr,x in pairs(found) do if x < 2 then found[nr] = nil end end
                table.insert(result,{plant,found})
            end
        end
    end
    
    function self.GetReagentCombination()
      local size = #reagent
        for x = 1,size do
            for y = x+1, size do
                plant = {x,y}
                SetResult()
                if self.three then
                    for z = y+1, size do
                        plant = {x,y,z}
                        SetResult()
                    end
                end
            end
        end
    end

    local function GetPotion(row)
        GetReagentCombination()
        local rb, rs, slot3, traits, link, color = {}, {}, false, {}
        local good, bad = {{1,1,1,1},{0,0.8,0,1},{0.2,1,0.2,1}}, {{1,1,1,1},{0.8,0,0,1},{1,0.2,0.2,1}}
        
        for x,_ in pairs(trait) do rb[x], rs[x] = GetReagentBagSlot(result[row][1][x]) end
        rb[4], rs[4] = GetReagentBagSlot(solvent[self.selectedSolvent])
        
        if self.three and rb[3] and rs[3] then slot3 = true elseif not self.three then slot3 = true end
            
        if rb[4] and rs[4] and rb[1] and rs[1] and rb[2] and rs[2] and slot3 then
            local _, icon = GetAlchemyResultingItemInfo(rb[4],rs[4],rb[1],rs[1],rb[2],rs[2],rb[3],rs[3])
            link = GetAlchemyResultingItemLink(rb[4],rs[4],rb[1],rs[1],rb[2],rs[2],rb[3],rs[3])
            for y,z in pairs(result[row][2]) do
                if IsBad(y) then color = bad else color = good end
                table.insert(traits,{self.GetTraitIcon(y),color[z]})
            end
            return true, zo_strformat('|t32:32:<<1>>|t <<C:2>>', icon, link), link, rb, rs, traits
        else
            for y,x in pairs(plant) do
                local icon, _, link = self.GetReagent(x)
                item = item..zo_strformat('|t32:32:<<1>>|t', icon)
                color = color..zo_strformat('<<C:1>>', link)
                if y < #plant then
                    item = item..' + '
                    color = color..'\n'
                end
            end
            return false, item, color
        end
    end

    function self.GetAllPotion()
        for row,_ in ipairs(result) do
            local isPotion, item, link, rb, rs, traits = GetPotion(row)
            if isPotion then d(item) else d(item) end
        end
    end

    return self
end