-- Elementals Race, for Tales of Maj'Eyal.
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.


local eutil = require 'elementals-race.util'
local stats = require 'engine.interface.ActorStats'
local object = require 'mod.class.Object'

newTalentType {
	type = 'elemental/avalanche',
	name = 'Avalanche',
	description = 'Physical Caster',}

local make_require = function(tier)
	return {
		stat = {str = function(level) return 2 + tier * 8 + level * 2 end,},
		level = function(level) return -5 + tier * 4 + level end,}
end

local grounded_pre_use = function(self, t, silent)
	if self:hasEffect('EFF_ZERO_GRAVITY') or
		self:attr('levitation') or self:attr('fly')
	then
		if not silent then
			game.logPlayer(self, 'You must be grounded to use this talent.')
		end
		return false
	end
	return true
end

newTalent {
	name = 'Heavy Arms',
	type = {'elemental/avalanche', 1,},
	require = make_require(1),
	points = 5,
	mode = 'passive',
	getWeaponPower = function(self, t) return self:getTalentLevel(t) * 0.7 end,
	getDamage = function(self, t) return t.getWeaponPower(self, t) * 10 end,
	getPercentInc = function(self, t)
		return math.sqrt(t.getWeaponPower(self, t) / 5) / 2
	end,
	daze = function(self, t) return 10 + self:getStr(15, true) end,
	info = function(self, t)
		return ([[The Jadir's body gives it a huge advantage when fighting in close quarters.
Increases physical power by %d and damage done by %d%% with standard weapons.
Also gives each blow a %d%% chance (scaling with Strength) to daze the enemy for 1 turn.]])
			:format(t.getDamage(self, t),
							t.getPercentInc(self, t) * 100,
							t.daze(self, t))
	end,}

newTalent {
	name = 'Pinpoint Toss',
	type = {'elemental/avalanche', 2,},
	require = make_require(2),
	points = 5,
	essence = 15,
	cooldown = 8,
	tactical = {ATTACK = 3,},
	accuracy = function(self, t)
		return self:combatTalentScale(t, 10, 20) * (5 + self:getStr(5, true))
	end,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 50, 300)
	end,
	range = function(self, t)
		return math.min(10, math.floor(2 + self:getStr(6)))
	end,
	duration = function(self, t)
		return math.floor(self:combatTalentScale(self:getStr(5, true), 2, 5))
	end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, 'combat_atk', t.accuracy(self, t))
	end,
	recompute_passives = {stats = {stats.STAT_STR,},},
	target = function(self, t)
		return {type = 'hit', range = t.range(self, t), talent = t,}
	end,
 	on_pre_use = grounded_pre_use,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return end

		local dam = self:phsyicalCrit(t.damage(self, t))
		self:project(tg, x, y, DamageType.PHYSICAL, dam, {type = 'archery'})
		local terrain_projector = function(x, y, tg, self)
			local oe = game.level.map(x, y, Map.TERRAIN)
			if oe and oe.special then return end
			if oe and oe:attr('temporary') then return end

			local e = object.new{
				old_feat = oe,
				type = oe.type, subtype = oe.subtype,
				name = self.name:capitalize()..'\'s Boulder',
				image = 'terrain/huge_rock.png',
				display = '#', color=colors.WHITE, --back_color=colors.DARK_GREY,
				always_remember = true,
				desc = 'a thrown boulder',
				type = 'wall',
				can_pass = {pass_wall=1},
				does_block_move = true,
				show_tooltip = true,
				block_move = true,
				block_sight = true,
				temporary = t.duration(self, t) + 1,
				x = x, y = y,
				canAct = false,
				act = function(self)
					self:useEnergy()
					self.temporary = self.temporary - 1
					if self.temporary <= 0 then
						game.level.map(self.x, self.y, engine.Map.TERRAIN, self.old_feat)
						game.level:removeEntity(self)
						game.level.map:updateMap(self.x, self.y)
					end
				end,
				dig = function(src, x, y, old)
					game.level:removeEntity(old)
					game.level.map:updateMap(self.x, self.y)
					return nil, old.old_feat
				end,
				summoner_gain_exp = true,
				summoner = self,}
			e.tooltip = mod.class.Grid.tooltip
			game.level:addEntity(e)
			game.level.map(x, y, Map.TERRAIN, e)
			--game.level.map:updateMap(x, y)
		end
		self:project(tg, x, y, terrain_projector)

		game:playSoundNear(self, "talents/ice")
		return true
	end,
	info = function(self, t)
		return ([[Rip an enormous bulk of stone out of the ground and throw it, dealing %d physical damage and leaving a stone wall there for %d turns.
This also passively increases your accuracy by %d.
Cannot be used while #SLATE#(UNIMPLEMENTED: in water)#LAST# or floating.
Damage, range, accuracy, and duration scale with Strength.]])
			:format(Talents.damDesc(self, DamageType.PHYSICAL, t.damage(self, t)),
							t.duration(self, t),
							t.accuracy(self, t))
	end,}

newTalent {
	name = 'Tremor',
	type = {'elemental/avalanche', 3,},
	require = make_require(3),
	points = 5,
	essence = 15,
	cooldown = 15,
	range = 0,
	radius = function(self, t)
		return math.floor(util.bound(self:getTalentLevel(t), 1, 6))
	end,
	tactical = {ATTACK = 3, DISABLE = {PIN = 1,},},
	target = function(self, t)
		return {type = 'ball', range = t.range, radius = t.radius(self, t),
						selffire = false, talent = t,}
	end,
	damage = function(self, t)
		return 0.5 + self:combatTalentScale(t, 0.5, 1) * (0.5 + self:getStr(0.5, true))
	end,
	duration = function(self, t)
		return math.floor(3 + self:getStr(3, true))
	end,
 	on_pre_use = grounded_pre_use,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local base_damage = t.damage(self, t)
		local duration = t.duration(self, t)
		local projector = function(x, y, tg, self)
			local target = game.level.map(x, y, Map.ACTOR)
			if target and target ~= self then
				local damage = base_damage
				if target:attr('stoned') then damage = damage + 0.5 end
				-- TODO: figure out how to tell if we're in a wall
				local in_wall = false
				if in_wall then damage = damage + 0.5 end
				local hit = self:attackTarget(target, DamageType.PHYSICAL, damage, true)
				if hit and
					(target:attr('stunned') or target:attr('dazed') or target:attr('confused')) and
					target:canBe('pin')
				then
					target:setEffect('EFF_PINNED', duration, {})
				end
			end
		end
		self:project(tg, self.x, self.y, projector)
		--self:addParticles(Particles.new("meleestorm", 1, {radius=4, img="spinningwinds_blue"}))
		game:playSoundNear(self, "talents/earth")
		return true
	end,
	info = function(self, t)
		return ([[Deal %d%% weapon damage in radius %d, pinning down any stunned, confused or dazed target for %d turns. Any petrified targets will take an additional 50%% weapon damage, #SLATE#(UNIMPLEMENTED: and any targets standing in a wall will take an additional 50%% weapon damage)#LAST#.
Cannot be used while #SLATE#(UNIMPLEMENTED: in water)#LAST# or floating.
Damage and pinning duration scale with strength.]])
			:format(t.damage(self, t) * 100, t.radius(self, t), t.duration(self, t))
	end,}

newTalent {
	name = 'Catapult',
	type = {'elemental/avalanche', 4,},
	require = make_require(4),
	points = 5,
	essence = 20,
	cooldown = 18,
	grab_range = 1,
	range = function(self, t)
		return math.floor(4 + self:getStr(5, true))
	end,
	radius = 2,
	tactical = {ATTACKAREA = 3, DISABLE = {MAIM = 1,},},
	target = function(self, t)
		return {type = 'ball',
						range = util.getval(t.range, self, t),
						radius = util.getval(t.radius, self, t),
						selffire = false, talent = t,}
	end,
	damage = function(self, t)
		return self:combatTalentPhysicalDamage(t, 80, 280)
	end,
	duration = function(self, t)
		return math.floor(3 + self:getStr(3, true))
	end,
	-- Don't allow repeated throw attempts.
	on_pre_use = function(self, t, silent)
		return not self.turn_procs.catapult_failed
	end,
	action = function(self, t)
		local tg = {type = 'hit', range = util.getval(t.grab_range, self, t),}
		local x1, y1, target1 = self:getTarget(tg)
		if not x1 or not y1 or not target1 then return end
		if core.fov.distance(self.x, self.y, x1, y1) > tg.range then return end

		-- Let player retarget same enemy without worrying about knockback resistance.
		if not eutil.get(self.turn_procs, 'catapult_succeeded', target1.uid) then
			if target1:canBe('knockback') then
				eutil.set(self.turn_procs, 'catapult_succeeded', target1.uid, true)
			else
				game.logPlayer(self, '%s resists being thrown!', target1.name:capitalize())
				self.turn_procs.catapult_failed = true
				return
			end
		end

		tg = util.getval(t.target, self, t)
		local x2, y2 = self:getTarget(tg)
		if not x2 or not y2 then return end
		if core.fov.distance(self.x, self.y, x2, y2) > tg.range then return end
		if game.level.map:checkAllEntities(x2, y2, 'block_move', target1) then
			game.logPlayer(self, '%s cannot be thrown there!', target1.name:capitalize())
			return
		end

		target1:move(x2, y2, true)

		local damage = self:physicalCrit(t.damage(self, t))
		local duration = t.duration(self, t)
		local projector = function(x, y)
			local target = game.level.map(x, y, Map.ACTOR)
			if target and target ~= self then
				DamageType:get(DamageType.PHYSICAL).projector(
					self, x, y, DamageType.PHYSICAL, damage)
				if target.size_category < target1.size_category then
					target:setEffect('EFF_MAIMED', duration, {})
				end
			end
		end
		self:project(tg, x2, y2, projector)
		game:playSoundNear(target1, "talents/ice")
		return true
	end,
	info = function(self, t)
		return ([[Grab a target enemy and toss them up to %d tiles, dealing %d damage within radius 2 of the landing point. Anything hit which is smaller than the one tossed are squashed, maiming them for %d turns.
Damage, range and maim duration increase with Strength, damage also increases with target's size.]])
			:format(
				util.getval(t.range, self, t),
				Talents.damDesc(self, DamageType.PHYSICAL, t.damage(self, t)),
				t.duration(self, t))
	end,}
