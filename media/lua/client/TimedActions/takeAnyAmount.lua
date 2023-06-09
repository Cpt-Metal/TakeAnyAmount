require "ISUI/ISToolTip"

local function setAmountAndTransfer(target, button, obj, items, player)
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

function createAndOpenWindow(items, player)
	local modal = ISTextBox:new(0, 0, 280, 180, getText("ContextMenu_TransferAmountInfo").." "..tostring(MAX)..")", tostring(MAX), nil, setAmountAndTransfer, nil, obj, items, player);
    modal:initialise();
    modal:addToUIManager();
end

--###########################
--Inventory Context Menu
--###########################


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
    for i,k in pairs(items) do
        if not instanceof(k, "InventoryItem") then
            if isForceDropHeavyItem(k.items[1]) then
                -- corpse or generator
            elseif #k.items > 2 then
				MAX = tonumber(#k.items - 1);
                context:addOption(getText("ContextMenu_Grab_one"), items, ISInventoryPaneContextMenu.onGrabOneItems, player);
                context:addOption(getText("ContextMenu_Grab_half"), items, ISInventoryPaneContextMenu.onGrabHalfItems, player);
                context:addOption(getText("ContextMenu_SelectAmount"), items, createAndOpenWindow, player);
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