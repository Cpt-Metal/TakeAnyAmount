require "ISUI/ISToolTip"

--####################################
--Textbox manager
--####################################

function createAndOpenTextbox(items, player, mode)
	--print("mode: "..tostring(mode));
	--print("items: "..tostring(items));
	--print("player: "..tostring(player));
	local modal
	if tonumber(mode) == 0 then
		modal = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_TransferAmountInfo").." "..tostring(MAX)..")", tostring(MAX), nil, setAmountAndGrab, nil, obj, items, player);
	elseif tonumber(mode) == 1 then
		modal = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_TransferAmountInfo").." "..tostring(MAX)..")", tostring(MAX), nil, setAmountAndPut, nil, obj, items, player);
	end
    modal:initialise();
    modal:addToUIManager();
	if JoypadState.players[player+1] then
        setJoypadFocus(player, modal)
    end
end

--####################################
--Grabbing items from containers
--####################################

function setAmountAndGrab(target, button, obj, items, player)
	if button.internal == "OK" then
		local text = button.parent.entry:getText() -- text == amount
		if tonumber(text) then
			if tonumber(text) > MAX then
				text = MAX;
			end
			AMOUNT = tonumber(text);
			ISInventoryPaneContextMenu.onGrabAnyAmount(items, player);
		end
	end
end

ISInventoryPaneContextMenu.onGrabAnyAmount = function(items, player)
	local count = tonumber(AMOUNT)
	local playerObj = getSpecificPlayer(player)
	local playerInv = getPlayerInventory(player).inventory;
	local doWalk = true
	for i,k in ipairs(items) do
		if not instanceof(k, "InventoryItem") then
			-- first in a list is a dummy duplicate, so ignore it.
			for i2=1,count do
				local k2 = k.items[i2+1]
				if k2:getContainer() ~= playerInv then
					if doWalk then
						if not luautils.walkToContainer(k2:getContainer(), player) then
							return
						end
						doWalk = false
					end
					ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, k2, k2:getContainer(), playerInv))
				end
			end
		elseif k:getContainer() ~= playerInv then
			if doWalk then
				if not luautils.walkToContainer(k2:getContainer(), player) then
					return
				end
				doWalk = false
			end
			ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, k, k:getContainer(), playerInv))
		end
	end
end

function ISInventoryPaneContextMenu.doGrabMenu(context, items, player)
	
	--ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    for i,k in pairs(items) do
        if not instanceof(k, "InventoryItem") then
            if isForceDropHeavyItem(k.items[1]) then
                -- corpse or generator
            elseif #k.items > 2 then
				MAX = tonumber(#k.items - 1);
                context:addOption(getText("ContextMenu_Grab_one"), items, ISInventoryPaneContextMenu.onGrabOneItems, player);
                context:addOption(getText("ContextMenu_Grab_half"), items, ISInventoryPaneContextMenu.onGrabHalfItems, player);
                context:addOption(getText("ContextMenu_GrabAmount"), items, createAndOpenTextbox, player, 0);
                context:addOption(getText("ContextMenu_Grab_all"), items, ISInventoryPaneContextMenu.onGrabItems, player);
            else
                context:addOption(getText("ContextMenu_Grab"), items, ISInventoryPaneContextMenu.onGrabItems, player);
            end
            break;
        elseif isForceDropHeavyItem(k) then
            -- corpse or generator
        else
            context:addOption(getText("ContextMenu_Grab"), items, ISInventoryPaneContextMenu.onGrabItems, player);
            break;
        end
    end
end

--####################################
--Putting items in containers
--####################################

function setAmountAndPut(target, button, obj, items, player)
	if button.internal == "OK" then
		local text = button.parent.entry:getText() -- text == amount
		--print("Items to put: "..text);
		if tonumber(text) then
			if tonumber(text) > MAX then
				text = MAX;
			end
			if tonumber(text) < 0 then
				text = 0;
			end
			AMOUNT = tonumber(text);
			--print(tostring(AMOUNT));
			ISInventoryPaneContextMenu.onPutItemsAmount(items, player);
		end
	end
end

ISInventoryPaneContextMenu.onPutItemsAmount = function(items, player)
	local playerObj = getSpecificPlayer(player)
	local playerLoot = getPlayerLoot(player).inventory
	items = ISInventoryPane.getActualItems(items)
    --ISInventoryPaneContextMenu.transferIfNeeded(playerObj, items)
	local doWalk = true
	local count = 0;
	for i,k in ipairs(items) do
		if playerLoot:isItemAllowed(k) and not k:isFavorite() then
			if doWalk then
				if not luautils.walkToContainer(playerLoot, player) then
					break
				end
				doWalk = false
			end
			if count == AMOUNT then
				--print(tostring(count).." items transfered");
				break
			end
			ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, k, k:getContainer(), playerLoot))
			count = count + 1;
		end
	end
end

local function AddContextPutItems(player, context, items)

	local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
	local loot = getPlayerLoot(player);
	local moveItems = ISInventoryPane.getActualItems(items)

	local inPlayerInv = true;

	for i,k in ipairs(moveItems) do		
		if not k:getContainer():isInCharacterInventory(playerObj) then
			inPlayerInv = false;
		end
		if i >= 0 then
			break
		end
	end

	MAX = #moveItems;

	if inPlayerInv and MAX > 1 then
        if ISInventoryPaneContextMenu.isAnyAllowed(loot.inventory, items) and not ISInventoryPaneContextMenu.isAllFav(items) then
           -- local label = loot.title and getText("ContextMenu_PutInContainer", loot.title) or getText("ContextMenu_Put_in_Container")
			context:addOption(getText("ContextMenu_PutAmount").." ("..loot.title..")", items, createAndOpenTextbox, player, 1);
        end
    end    
end

Events.OnFillInventoryObjectContextMenu.Add(AddContextPutItems)