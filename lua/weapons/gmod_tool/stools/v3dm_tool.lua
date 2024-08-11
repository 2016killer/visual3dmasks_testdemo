TOOL.Category = 'Construction'
TOOL.Name = '#tool.v3dm_tool.name'


if CLIENT then
    local v3dm_tool_language_text = {
		['tool.v3dm_tool.name'] = {'Visual 3D Masks', '视觉3D遮罩'},
		['tool.v3dm_tool.desc'] = {'Left click main and then left click mask', '左键点击主要实体，然后左键点击遮罩'},
		['tool.v3dm_tool.left_s0'] = {'Set main entity', '设置主要实体'},
		['tool.v3dm_tool.left_s1'] = {'Set mask', '设置遮罩'},
		['tool.v3dm_tool.right'] = {'Set interior material', '选取内部材质'},
		['tool.v3dm_tool.reload'] = {'remove all masks', '移除所有遮罩'},


		['tool.v3dm_tool.panel.imaterial'] = {'interior material', '内部材质'},
		['tool.v3dm_tool.panel.mmaterial'] = {'mask material', '遮罩材质'},
	}

	for placeholder, text in pairs(v3dm_tool_language_text) do
		language.Add(placeholder, text[1])
		language.Add(placeholder..'.zh', text[2])
		v3dm_tool_language_text[placeholder] = 0
	end

	local function v3dm_tool_language()
		function languageAdd(placeholder, zh)
			language.Add(placeholder, language.GetPhrase(placeholder..(zh and '.zh' or '')))
		end

		local zh = GetConVar('gmod_language'):GetString() == 'zh-CN'

		for placeholder, _ in pairs(v3dm_tool_language_text) do languageAdd(placeholder, zh) end
	end

	v3dm_tool_language()

	// cvars.AddChangeCallback('gmod_language', function(name, old, new) v3dm_tool_language() end)



	TOOL.Information = {
		{stage = 0, name = "left_s0"},
		{stage = 1, name = "left_s1"},
		{name = "right"},
		{name = "reload"},
	}

	local cl_v3dm_tool_imaterial = CreateConVar('cl_v3dm_tool_imaterial', 'visual3dmasks/debug2material', { FCVAR_ARCHIVE })
	local cl_v3dm_tool_mmaterial = CreateConVar('cl_v3dm_tool_mmaterial', 'Models/effects/vol_light001', { FCVAR_ARCHIVE })

	function TOOL.BuildCPanel(CPanel)
		CPanel:AddControl("TextBox", {
			Label = '#tool.v3dm_tool.panel.imaterial',             
			Command = "cl_v3dm_tool_imaterial",
			MaxLength = "100"                  
		})

		CPanel:AddControl("TextBox", {
			Label = '#tool.v3dm_tool.panel.mmaterial',             
			Command = "cl_v3dm_tool_mmaterial",
			MaxLength = "100"                  
		})
	end
end


if SERVER then 
	function TOOL:Deploy()
		self.targetEnts = {}
		self:SetStage(0)
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

				self:SetStage(0)
			else
				self:SetStage(1)
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


function TOOL:Reload(tr)
	return true
end


