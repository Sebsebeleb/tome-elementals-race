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

for _, world in pairs {'Maj\'Eyal', 'Infinite', 'Arena',} do
	local bd = getBirthDescriptor('world', world)
	if bd then
		bd.descriptor_choices.race.Elemental = 'allow'
	end
end

newBirthDescriptor {
	type = 'race',
	name = 'Elemental',
	desc = {'Sentient beings created as part of nature\'s reaction to its gradual corruption by the spellblaze.'},
	descriptor_choices = {
		subrace = {
			__ALL__ = 'disallow',
			Elemental = 'allow',},
		class = {
			__ALL__ = 'disallow',
			Elemental = 'allow',},},}

newBirthDescriptor {
	type = 'subrace',
	name = 'Elemental',
	desc = {'Sentient beings created as part of nature\'s reaction to its gradual corruption by the spellblaze.',
	},
	random_escort_possibilities = {
		{'tier1.1', 1, 2}, {'tier1.2', 1, 2}, {'daikara', 1, 2},
		{'old-forest', 1, 4}, {'dreadfell', 1, 8}, {'reknor', 1, 2},},
	moddable_attachement_spots = 'race_human',
	copy = {
		faction = 'allied-kingdoms',
		type = 'elemental',
		resolvers.inventory{id = true, {defined = 'ORB_SCRYING',},},
		resolvers.inscription(
			'INFUSION:_REGENERATION', {cooldown = 10, dur = 5, heal = 60,}),
		resolvers.inscription(
			'INFUSION:_WILD',
			{cooldown = 12, what = {physical = true,}, dur = 4, power = 14,}),
		moddable_tile = 'human_#sex#',
		moddable_tile_base = 'base_cornac_01.png',
		random_name_def = 'cornac_#sex#',
		default_wilderness = {'playerpop', 'allied'},
		starting_zone = 'trollmire',
		starting_quest = 'start-allied',
		starting_intro = 'cornac',
		disease_immune = 1,
		poison_immune = 1,},}

newBirthDescriptor {
	type = 'class',
	name = 'Elemental',
	desc = {'One of the various elementals.'},
	descriptor_choices = {
		subclass = {
			__ALL__ = 'disallow',
			Jadir = 'allow',
			Asha = 'allow',
			Silyhe = 'allow',
			Naiar = 'allow',},},}

newBirthDescriptor {
	type = 'subclass',
	name = 'Jadir',
	desc = {
		'Jadir is, if the element doesn\'t betray it already, the beefier of the four classes. If it hits, it hits hard, if it tanks, it tanks even harder. I wanted this class to have the most "inert" of skillsets, that is skills that don\'t require complex targeting, as it would be more fitting for a class that\'s supposed to rely less on mobility and more on the raw stat bulk - hence the majority of the skills having a focus on point-blank AoE skills, sustains or enhancements.',
		'',
		'This does of course not mean that it\'s a class entirely grounded in it\'s ability to manipulate the game elements beyond just punching them. To compensate for the lack of speed it has a variety of skills that affect the environment, in particular walls. It felt very fitting, both for the lore and the general playstyle, an earth elemental controlling natural solid physical obstacles.'},
	inc_stats = {str = 4, dex = -2, con = 5, mag = 4, cun = -2,},
	power_source = {nature = true,},
	talents_types = {
		['elemental/mountain'] = {true, 0.3,},
		['elemental/avalanche'] = {true, 0.3,},
		['elemental/symbiosis'] = {true, 0.3,},
		['elemental/geokinesis'] = {true, 0.3,},
		['technique/combat-training'] = {true, 0.3,},
		['advanced/earth metamorphosis'] = {false, 0.3,},},
	talents = {
		[ActorTalents.T_WEAPON_COMBAT] = 1,
		[ActorTalents.T_ARMOUR_TRAINING] = 1,
		[ActorTalents.T_JAGGED_BODY] = 1,},
	copy = {
		subtype = 'earth',
		max_life = 130,
		life_rating = 13,
		no_breath = 1,
		resolvers.equip {
			id = true,
			{type = 'weapon', subtype = 'greatmaul', name = 'iron greatmaul',
			 autoreq = true, ego_chance = -1000, ego_chance = -1000},
 			{type = 'armor', subtype = 'heavy', name = 'iron mail armour',
			 autoreq = true, ego_chance = -1000, ego_chance = -1000},},},}
