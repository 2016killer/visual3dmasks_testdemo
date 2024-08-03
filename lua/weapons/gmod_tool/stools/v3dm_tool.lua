TOOL.Category = 'Construction'
TOOL.Name = 'visual3dmasks'

if SERVER then 
	function TOOL:Deploy()
		self.targetEnts = {}
	end
end

function TOOL:LeftClick(tr)
	if tr.Entity:EntIndex() != 0 then
		if SERVER then 
			table.insert(self.targetEnts, tr.Entity) 
			if #self.targetEnts > 1 then
				self.targetEnts[1]:v3dm_addMaskInfoFast(self.targetEnts[2], self.interiorMat)
				self.targetEnts[1]:v3dm_InitMasks()
				self.targetEnts = {}
			end
		end
		return true
	else
		return
	end
end

function TOOL:RightClick(tr)
    if CLIENT then return true end
    self.interiorMat = tr.Entity:GetMaterial() and tr.Entity:GetMaterial() or tr.Entity:GetMaterials()[1] 
    return true
end
