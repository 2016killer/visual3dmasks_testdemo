if CLIENT then
	concommand.Add('v3dm_debug', function(ply, cmd, args) v3dm_debug = !v3dm_debug end)

	concommand.Add('v3dm_test_renderingBack', function(ply, cmd, args)
		local ent = ply:GetEyeTrace().Entity
		ent.RenderOverride = function(self)
			render.CullMode(MATERIAL_CULLMODE_CW)
			self:DrawModel()
			render.CullMode(MATERIAL_CULLMODE_CCW)
		end
	end)

	concommand.Add('v3dm_test_debug2Material', function(ply, cmd, args)
		local ent = ply:GetEyeTrace().Entity
		ent:SetMaterial('visual3dmasks/debug2material')
	end)

	concommand.Add('v3dm_updateRT', function() v3dm_updateRT() end)

	concommand.Add('v3dm_rebuild', function(ply, cmd, args)
		LocalPlayer():ConCommand('v3dm_updateRT')
		hook.Add('PostDrawOpaqueRenderables', v3dm_hookName, args[1] and v3dm_renderEntsWith3DMasks or v3dm_renderEntsWith3DMasks_safe)
	end)

	concommand.Add('v3dm_remove', function() hook.Remove('PostDrawOpaqueRenderables', v3dm_hookName) end)
end


