--[[ trade.lua — inti Automation Trade.
     Alur per-trade: SendRequest -> tunggu window kebuka -> AddItem pets -> Accept
                     -> tunggu lawan accept -> Confirm -> tunggu selesai.
     Mengisi: ctx.getPlayers, ctx.getData, ctx.matchingPetUuids,
              ctx.startTrade, ctx.stopTrade ]]
return function(ctx)
	local Players     = ctx.Services.Players
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local DataService = ctx.deps.DataService
	local TC          = ctx.deps.TradingController
	local SendRequest = ctx.deps.SendRequest
	local AddItem     = ctx.deps.AddItem
	local Accept      = ctx.deps.Accept
	local Confirm     = ctx.deps.Confirm
	local Decline     = ctx.deps.Decline
	local FavoriteItem = ctx.deps.FavoriteItem
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end

	----------------------------------------------------------------- data helpers
	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok then return d end
		return nil
	end
	ctx.getData = getData

	local function getPlayers()
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then list[#list + 1] = p.Name end
		end
		table.sort(list)
		return list
	end
	ctx.getPlayers = getPlayers

	-- cek pet cocok dengan filter CFG
	local function petPasses(v)
		local pt = v.PetType
		local pd = v.PetData
		if not (pt and pd) then return false end
		-- filter type (kosong = semua)
		if next(CFG.petTypes) and not CFG.petTypes[pt] then return false end
		-- weight: berat TAMPIL di game = BaseWeight + 0.5 (pakai angka tampilan di filter)
		local w = (pd.BaseWeight or 0) + 0.5
		local wf = CFG.weightFilter or 0
		if wf > 0 and w < wf then return false end
		if wf < 0 and w > -wf then return false end
		-- age (Level)
		local age = pd.Level or 0
		local af = CFG.ageFilter or 0
		if af > 0 and age < af then return false end
		if af < 0 and age > -af then return false end
		return true
	end

	-- kumpulkan uuid pet yang cocok (maksimal `limit`)
	local function matchingPetUuids(limit)
		local out = {}
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return out end
		-- pet yang lagi di-equip jangan di-trade
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		for uuid, v in pairs(pinv) do
			if #out >= limit then break end
			if not equipped[uuid] and petPasses(v) then
				local fav = v.PetData.IsFavorite
				if (not fav) or CFG.autoUnfavorite then
					out[#out + 1] = { uuid = uuid, fav = fav, petType = v.PetType }
				end
			end
		end
		return out
	end
	ctx.matchingPetUuids = matchingPetUuids

	----------------------------------------------------------------- trade-state read
	local function replicatorData()
		if not (TC and TC.CurrentTradeReplicator) then return nil end
		local rep = TC.CurrentTradeReplicator
		local ok, d = pcall(function() return rep:GetDataAsync() end)
		if ok and d then return d end
		ok, d = pcall(function() return rep:GetData() end)
		if ok then return d end
		return nil
	end

	ctx.replicatorData = replicatorData
	local loggedSchema = false
	local function otherAccepted(d)
		if type(d) ~= "table" then return false end
		local players = d.players or d.Players
		if type(players) ~= "table" then return false end
		local myIdx, otherIdx
		for i, p in ipairs(players) do
			if p == LP then myIdx = i else otherIdx = otherIdx or i end
		end
		local offers = d.offers or d.Offers
		if otherIdx and offers then
			local off = offers[otherIdx]
			if type(off) == "table" then
				if not loggedSchema then
					loggedSchema = true
					local keys = {}
					for k in pairs(off) do keys[#keys + 1] = tostring(k) end
					log("offer keys: " .. table.concat(keys, ","))
				end
				if off.accepted or off.Accepted or off.confirmed or off.Confirmed or off.ready or off.isReady then
					return true
				end
			end
		end
		-- map accepted by player
		local acc = d.accepted or d.Accepted
		if acc and otherIdx then
			local other = players[otherIdx]
			if acc[other] or (other and acc[other.Name]) or (other and acc[tostring(other.UserId)]) then return true end
		end
		return false
	end
	ctx.otherAccepted = otherAccepted

	----------------------------------------------------------------- one trade
	local function doOneTrade(target)
		setStatus("Kirim ajakan ke " .. target.Name)
		pcall(function() SendRequest:FireServer(target) end)

		-- tunggu window trade kebuka (lawan accept request)
		local t0 = os.clock()
		repeat task.wait(0.3) until (not ctx.state.tradeRunning) or (TC and TC.CurrentTradeReplicator) or (os.clock() - t0) > 20
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Timeout: " .. target.Name .. " tidak accept ajakan.")
			return false
		end

		-- kumpulkan pet
		local pets = matchingPetUuids(CFG.petsPerTrade)
		if #pets == 0 then
			log("Tidak ada pet cocok filter. Batalkan trade.")
			pcall(function() Decline:FireServer() end)
			return false
		end

		-- auto unfavorite dulu kalau perlu
		if CFG.autoUnfavorite and FavoriteItem then
			for _, p in ipairs(pets) do
				if p.fav then pcall(function() FavoriteItem:FireServer(p.uuid) end); task.wait(0.15) end
			end
			task.wait(0.3)
		end

		-- add item
		setStatus(("Menambah %d pet..."):format(#pets))
		for _, p in ipairs(pets) do
			if not ctx.state.tradeRunning then break end
			pcall(function() AddItem:FireServer("Pet", p.uuid) end)
			task.wait(0.25)
		end

		-- accept dari sisi kita
		task.wait(0.4)
		pcall(function() Accept:FireServer() end)
		setStatus("Menunggu lawan accept...")

		-- tunggu lawan accept
		t0 = os.clock()
		local accepted = false
		repeat
			task.wait(0.5)
			if otherAccepted(replicatorData()) then accepted = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 30
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Trade ditutup sebelum selesai.")
			return false
		end
		if not accepted then
			log("Lawan tidak accept (timeout). Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end

		-- confirm
		pcall(function() Confirm:FireServer() end)
		setStatus("Confirm... menunggu selesai")

		-- tunggu trade selesai (replicator hilang)
		t0 = os.clock()
		repeat task.wait(0.4) until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 15
		if TC and TC.CurrentTradeReplicator then
			log("Confirm terkirim tapi trade belum tertutup.")
			return false
		end
		return true
	end

	----------------------------------------------------------------- loop
	local function tradeLoop()
		ctx.elevate()
		while ctx.state.tradeRunning do
			if ctx.state.completed >= CFG.totalTrades then
				ctx.state.status = "DONE"
				setStatus(("Selesai %d/%d trade."):format(ctx.state.completed, CFG.totalTrades))
				ctx.state.tradeRunning = false
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				break
			end
			local target = CFG.targetPlayer ~= "" and Players:FindFirstChild(CFG.targetPlayer) or nil
			if not target then
				setStatus("Target player tidak ada / belum dipilih.")
				task.wait(2)
			else
				ctx.state.status = "RUNNING"
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				local ok = doOneTrade(target)
				if ok then
					ctx.state.completed += 1
					log(("Trade sukses (%d/%d)"):format(ctx.state.completed, CFG.totalTrades))
					if ctx.notifyTrade then ctx.notifyTrade(target, #matchingPetUuids(CFG.petsPerTrade)) end
				end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				task.wait(1.5)
			end
		end
	end

	function ctx.startTrade()
		if ctx.state.tradeRunning then return end
		ctx.state.tradeRunning = true
		ctx.state.status = "RUNNING"
		task.spawn(tradeLoop)
	end

	function ctx.stopTrade()
		ctx.state.tradeRunning = false
		ctx.state.status = "IDLE"
	end
end
