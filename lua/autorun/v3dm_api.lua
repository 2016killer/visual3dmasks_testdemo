local ENT = FindMetaTable('Entity')

v3dm_hookName = 'visual3DMasks_base'

if CLIENT then
	ENT.v3dm_destoryMasks = function(self) 
		for i, mask in pairs(self.v3dm_masks) do SafeRemoveEntity(mask) end 
	end
	
	// 材质缓存
	function v3dm_getInteriorMaterial(interiorMat)
		if isstring(interiorMat) then
			if !v3dm_interiorMats[interiorMat] then
				v3dm_interiorMats[interiorMat] = CreateMaterial('v3dm_'..interiorMat, 'UnlitGeneric', {
					['$basetexture'] = interiorMat, 
				} )
			end

			return v3dm_interiorMats[interiorMat]
		else
			return interiorMat
		end
	end

	net.Receive(v3dm_hookName, function() // BUG
		local ent = net.ReadEntity()
		local v3dm_masksInfo = net.ReadTable()
		local v3dm_originMaterial = net.ReadString()

		ent.v3dm_masksInfo = v3dm_masksInfo
		ent.v3dm_originMaterial = 'v3dmmodel_'..v3dm_originMaterial
			v3dm_interiorMats[ent.v3dm_originMaterial] = Material(v3dm_originMaterial)
			// print(v3dm_originMaterial)
		ent:v3dm_InitMasks()

	end)

end



if SERVER then
	ENT.v3dm_sendMasksInfo = function(self, ply)
		net.Start(v3dm_hookName) 
			net.WriteEntity(self)
			net.WriteTable(self.v3dm_masksInfo) 
			net.WriteString(self.v3dm_originMaterial)
		if ply then net.Send(ply) else net.Broadcast() end
	end

	ENT.v3dm_setMasksInfoFast = function(self, effectsInfo, override)
		local v3dm_masksInfo = {}
	
		for i, info in pairs(effectsInfo) do
			v3dm_masksInfo[i] = {
				modelName = info.mask:GetModel(),
				modelScale = info.mask:GetModelScale(),
				interiorMat = info.interiorMat,
				maskMat = info.maskMat,
		
				// invert = info.invert,
				// mode = info.mode, // 是否精细多遮罩
				
				lpos = info.parent:WorldToLocal( info.mask:GetPos() ),
				lang = info.parent:WorldToLocalAngles( info.mask:GetAngles() ),
				parent = info.parent
			}
		end
	
		if !table.IsEmpty(v3dm_masksInfo) then
			if override then 
				self.v3dm_masksInfo =  v3dm_masksInfo
			else
				if !self.v3dm_masksInfo then self.v3dm_masksInfo = {} end
				table.Add(self.v3dm_masksInfo, v3dm_masksInfo)
			end
		end
		
		// PrintTable(self.v3dm_masksInfo)
	end
	
	// 快速添加遮罩 (遮罩必须为全透明才能正确检测)
	ENT.v3dm_addMaskInfoFast = function(self, mask, interiorMat, maskMat, parent) 
		maskMat = maskMat and maskMat or 'Models/effects/vol_light001'
		parent = parent and parent or self

		self:v3dm_setMasksInfoFast( {
			{
				mask = mask,
				parent = parent,
	
				interiorMat = interiorMat,
				maskMat = maskMat,
				
				// invert = nil,
				// mode = 0x01
			}
		} )
	end
end

ENT.v3dm_InitMasks = function(self, ply)
	if CLIENT then
		if self.v3dm_masks then self:v3dm_destoryMasks() end
		self.v3dm_masks = {} 
	
		for i, info in pairs(self.v3dm_masksInfo) do
			local mask = ClientsideModel(info.modelName)
			mask:SetModelScale(info.modelScale)
			mask:SetMaterial(info.maskMat)
			mask:SetNoDraw(true)
	
			mask:SetPos( info.parent:LocalToWorld(info.lpos) )
			mask:SetAngles( info.parent:LocalToWorldAngles(info.lang) )
			mask:SetParent(info.parent)
			self.v3dm_masks[i] = mask
		end
	end

	if !table.IsEmpty(self.v3dm_masksInfo) then 
		if SERVER then // BUG
			if !self.v3dm_originMaterial then 
				self.v3dm_originMaterial = self:GetMaterials()[1]
				self:SetMaterial('Models/effects/vol_light001') 
			end
		end
		table.insert(v3dm_ents, self)
		// print('初始化成功')
	end
	
	if SERVER then self:v3dm_sendMasksInfo(ply) end
end

ENT = nil