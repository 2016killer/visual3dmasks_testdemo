v3dm_hookName = 'visual3DMasks_base'
v3dm_debug = false
v3dm_ents = {}
v3dm_interiorMats = { 
	debug2Material = Material('visual3dmasks/debug2material'),
	debugMaterial = Material('models/wireframe')
}
local A = Material('brick/brick_model')
if CLIENT then
	v3dm_scrShotRT,v3dm_scrShotRTMat = nil
	v3dm_interiorRT,v3dm_interiorRTMat = nil

	local ENT = FindMetaTable('Entity')

	function v3dm_updateRT()
		v3dm_scrShotRT = GetRenderTarget( 'v3dm_scrShotRT', ScrW(), ScrH() )
		v3dm_scrShotRTMat = nil

		v3dm_interiorRT = GetRenderTarget( 'v3dm_interiorRT', ScrW(), ScrH() )
		v3dm_interiorRTMat = nil
	end
	v3dm_updateRT()

	------------------基本渲染------------------

	ENT.v3dm_masksStencilTest = function(self)
		local isDrawingHalo = halo.RenderedEntity() == self
		if isDrawingHalo then
			return
		end

		local b = v3dm_debug and 0 or 255

		function main()
			render.SetStencilEnable(true)
				// 恢复
				render.SetStencilTestMask(255)
				render.SetStencilReferenceValue(0)
				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)
				
				render.MaterialOverride( v3dm_getInteriorMaterial(self.v3dm_originMaterial) )
					self:DrawModel()
				render.MaterialOverride()

				render.SetStencilCompareFunction(STENCIL_LESSEQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_INCR)
				// 透明材质会使用双面绘制
				for i, mask in pairs(self.v3dm_masks) do if IsValid(mask) then mask:DrawModel() end end
		
			
				// 奇偶校验并替换成1与0
				render.SetStencilTestMask(1)
				render.SetStencilReferenceValue(1)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_ZERO)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				render.ClearBuffersObeyStencil(255, 255, b, 0, true)

				// 1换2
				render.SetStencilReferenceValue(2)
				render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)
				
				render.MaterialOverride( v3dm_getInteriorMaterial(self.v3dm_originMaterial) )
					render.CullMode(MATERIAL_CULLMODE_CW)
					self:DrawModel()
					render.CullMode(MATERIAL_CULLMODE_CCW)
				render.MaterialOverride()

				render.SetStencilTestMask(255)
				render.SetStencilCompareFunction(STENCIL_LESSEQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_INCR)
				// 透明材质会使用双面绘制
				for i, mask in pairs(self.v3dm_masks) do if IsValid(mask) then mask:DrawModel() end end
			render.SetStencilEnable(false)
		end
	end

	function v3dm_renderEntsWith3DMasks()
		local finished = {}

		// 保存当前屏幕 BUG
		render.CopyTexture(nil, v3dm_scrShotRT)
		v3dm_scrShotRTMat = CreateMaterial('v3dm_scrShotRTMat', 'UnlitGeneric', {
			['$basetexture'] = v3dm_scrShotRT:GetName(), 
			['$translucent'] = 0,
			['$vertexcolor'] = 1,
			['$alphatest'] = 0
		} )

		// 外部渲染
		render.ClearStencil()
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		for i, ent in pairs(v3dm_ents) do
			local flag = ent.v3dm_masks and ent.v3dm_masksInfo and IsValid(ent) 
			flag = flag and !table.IsEmpty(ent.v3dm_masks) and !table.IsEmpty(ent.v3dm_masksInfo)

			if flag then 
				if !finished[ ent:EntIndex() ] then
					ent:v3dm_masksStencilTest() 
					finished[ ent:EntIndex() ] = true
				end
			else 
				v3dm_ents[i] = nil 
			end
		end

		finished = {}

		// 内部渲染
		render.PushRenderTarget(v3dm_interiorRT)
			local r, b = v3dm_debug and 0 or 255, v3dm_debug and 0 or 255

			render.Clear(0, 0, 0, 0, true, true)
			render.SetStencilWriteMask(255)
			render.SetStencilTestMask(255)
			render.SetStencilPassOperation(STENCIL_KEEP)
			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)
			for i, ent in pairs(v3dm_ents) do
				if !finished[ ent:EntIndex() ] then
					ent:v3dm_masksStencilTest(true)
					finished[ ent:EntIndex() ] = true
				end
			end

			render.Clear(0, 0, 0, 0, true, false)
			render.SetStencilEnable(true)
				render.SetStencilReferenceValue(1) 
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				render.ClearBuffersObeyStencil(r, 255, b, 255, true)
			render.SetStencilEnable(false)
		render.PopRenderTarget()
		v3dm_interiorRTMat = CreateMaterial('v3dm_interiorRTMat', 'UnlitGeneric', {
			['$basetexture'] = v3dm_interiorRT:GetName(), 
			['$translucent'] = 1,
			['$vertexcolor'] = 1,
			['$alphatest'] = 1
		} )

		// 融合内外遮罩
		render.SetStencilEnable(true)
			render.SetStencilReferenceValue(1) 
			render.SetStencilCompareFunction(STENCIL_EQUAL)
			render.SetStencilPassOperation(STENCIL_INCR)
			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)

			cam.Start2D()
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(v3dm_interiorRTMat)
				surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
			cam.End2D()
		render.SetStencilEnable(false)	

		if v3dm_debug then
			for i, ent in pairs(v3dm_ents) do
				for _, mask in pairs(ent.v3dm_masks) do
					render.MaterialOverride(v3dm_interiorMats['debugMaterial'])
						mask:DrawModel()
						render.CullMode(MATERIAL_CULLMODE_CW)
						mask:DrawModel()
						render.CullMode(MATERIAL_CULLMODE_CCW)
					render.MaterialOverride()
				end
			end
		else	
			render.SetStencilEnable(true)
				// 填补空缺
				render.SetStencilTestMask(255)
				render.SetStencilReferenceValue(2)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				cam.Start2D()
					surface.SetDrawColor(255, 255, 255, 255)
					surface.SetMaterial(v3dm_scrShotRTMat)
					surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
				cam.End2D()

				// 绘制破损处
				render.SetStencilReferenceValue(1)
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				render.ClearBuffersObeyStencil(0, 255, 0, 255, true)
				for i, ent in pairs(v3dm_ents) do
					for i, mask in pairs(ent.v3dm_masks) do
						local info = ent.v3dm_masksInfo[i]
						render.CullMode(MATERIAL_CULLMODE_CW)
							if info.interiorMat then 
								render.MaterialOverride(v3dm_getInteriorMaterial(info.interiorMat))
									mask:DrawModel()
								render.MaterialOverride()
							end
							render.MaterialOverride( v3dm_getInteriorMaterial(ent.v3dm_originMaterial) )
								ent:DrawModel()
							render.MaterialOverride()
						render.CullMode(MATERIAL_CULLMODE_CCW)
					end
				end
			render.SetStencilEnable(false)	
		end
	end

	function v3dm_renderEntsWith3DMasks_safe()
		local success, errorLog = pcall(v3dm_renderEntsWith3DMasks)
		if !success then
			render.SetStencilEnable(false)	
			render.ClearStencil()
			render.SetStencilWriteMask(255)
			render.SetStencilTestMask(255)
			render.SetStencilCompareFunction(STENCIL_ALWAYS)
			render.SetStencilPassOperation(STENCIL_KEEP)
			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)	

			hook.Remove('PostDrawOpaqueRenderables', v3dm_hookName)
			error('视觉3D遮罩程序异常,钩子已破坏,如需重建则运行指令:v3dm_rebuild\n\n'..errorLog)
		end
	end

	hook.Add('PostDrawOpaqueRenderables', v3dm_hookName, v3dm_renderEntsWith3DMasks)
end

if SERVER then
	util.AddNetworkString(v3dm_hookName)
	
	// 数据复制
	hook.Add('PostEntityCopy', v3dm_hookName, function(ply, ent, entsTable)
		if IsValid(ent) and ent.v3dm_masksInfo then
			duplicator.StoreEntityModifier(ent:EntIndex(), 'visual3DMasksInfo', { v3dm_masksInfo = ent.v3dm_masksInfo })
		end
	end)
	
	// 数据恢复
	hook.Add('PreEntityPaste', v3dm_hookName, function(ply, ent, entTable)
		if entTable and entTable['visual3DMasksInfo'] then
			ent.v3dm_masksInfo = entTable['visual3DMasksInfo']['v3dm_masksInfo']
			ent:v3dm_InitMasks()
		end
	end)

	// 数据清理
	hook.Add('EntityRemoved', v3dm_hookName, function(ent)
		if ent.v3dm_masksInfo then
			ent.v3dm_masksInfo = nil
			if CLIENT then 
				ent:v3dm_destoryMasks() 
				etn.v3dm_masks = nil
			end
		end
	end)
end



------------------菜单------------------
CreateConVar('cl_v3dm_enable', '1', { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE })



local v3dm_TEXT = {
	title = {'Visual3DMask', '视觉3D遮罩'},
	name = {'BaseConfig', '基础配置'},
	default = {'default', '默认'},
}

local default_option =	{
	cl_v3dm_enable = 1
}

hook.Add('PopulateToolMenu', v3dm_hookName, function()//添加菜单
	spawnmenu.AddToolMenuOption('Utilities','#v3dm.menu.category', v3dm_hookName,'#v3dm.menu.name', '', '', function(panel)
		panel:Clear()

		local ctrl = vgui.Create('ControlPresets', panel)
		ctrl:SetPreset(v3dm_hookName)
		ctrl:AddOption('#preset.default',default_option)
		for k, v in pairs(default_option) do ctrl:AddConVar(k) end

		panel:Help('#addons.menu.default')
		panel:AddPanel(ctrl)	

		panel:CheckBox()
	end)
end)

