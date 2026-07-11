--[[ pnp.lua — Pick & Place pet (reset/trigger skill).
     Remote (dari spy):
       pickup: PetsService:FireServer("UnequipPet", uuid)
       place : PetsService:FireServer("EquipPet", uuid, cframeString)  (posisi semula)
     CFrame diambil dari PU:FindLocalPetModel(uuid):GetPivot().
     Mode A = satu-satu pakai pickupDelay. Mode B = cepat pakai swapCooldown. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local PU          = ctx.deps.PU
	local CFG         = ctx.CFG
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end

	local function cframeString(cf)
		return table.concat({ cf:GetComponents() }, ", ")
	end

	-- pet yang lagi di-equip & cocok filter type (kosong = semua)
	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		for _, uuid in ipairs(eq) do
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(CFG.pnpPetTypes)) or (pt and CFG.pnpPetTypes[pt]) then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
	end

	local function getCFrame(uuid)
		if not PU then return nil end
		local ok, model = pcall(function() return PU:FindLocalPetModel(uuid) end)
		if ok and model and typeof(model) == "Instance" then
			local okc, cf = pcall(function() return model:GetPivot() end)
			if okc then return cf end
		end
		return nil
	end

	-- satu siklus pick+place untuk 1 pet
	local function pnpOne(uuid)
		if not PetsService then return false end
		local cf = getCFrame(uuid)
		if not cf then return false end          -- belum ada model (baru dilepas) -> skip
		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
		task.wait(math.max(0, CFG.equipDelay))
		pcall(function() PetsService:FireServer("EquipPet", uuid, cframeString(cf)) end)
		return true
	end

	----------------------------------------------------------------- loop PNP
	local function pnpLoop()
		ctx.state.pnpId = (ctx.state.pnpId or 0) + 1
		local myId = ctx.state.pnpId
		ctx.elevate()
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpId == myId do
			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP: tidak ada pet target (equip pet dulu)")
				task.wait(1)
			else
				setStatus(("PNP jalan: %d pet"):format(#pets))
				for _, p in ipairs(pets) do
					if not CFG.pnpEnabled or ctx.state.pnpId ~= myId then break end
					pnpOne(p.uuid)
					task.wait(math.max(0, CFG.pickupDelay))
				end
			end
		end
	end

	function ctx.startPnp() task.spawn(pnpLoop) end
	-- stop cukup set CFG.pnpEnabled=false (loop keluar sendiri)
end
