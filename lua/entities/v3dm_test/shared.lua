ENT.Type = 'anim'
ENT.Base = 'base_gmodentity'
ENT.PrintName = '3dMaskTest'
ENT.Spawnable = true

function ENT:Initialize()
	self:SetModel('models/props_c17/oildrum001.mdl')
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	if SERVER then self:PhysicsInit(SOLID_VPHYSICS) end
	self:PhysWake()

    if SERVER then timer.Simple(10 * FrameTime(), function() self:go() end) end
end

function ENT:go()
    self.v3dm_masksInfo = {
        {
            modelName = 'models/Combine_Helicopter/helicopter_bomb01.mdl',
            modelScale = 1,

            interiorMat = 'debug2Material',
            maskMat = 'Models/effects/vol_light001',
            // invert = info.invert,
            // mode = info.mode, // 是否精细多遮罩
            
            lpos = Vector(0, 20, 50),
            lang = Angle(),
            parent = self

        }
    }

    self:v3dm_InitMasks()
end