/proc/formula_magic_fire_orb_followup(mob/living/carbon/human/caster, turf/start, atom/target, power, radius, chain_remaining, ricochet_remaining, pierce_remaining, existence_repeats, shrapnel_remaining, damage_type, damage_flag, woundclass, intdamfactor, impact_color, list/chain_visited, forced_angle = null, speed_multiplier = 1, homing = FALSE, list/payload_tags)
	if(!caster || !start)
		return FALSE
	var/obj/projectile/magic/formula_magic_orb/bolt = new(start)
	bolt.firer = caster
	bolt.fired_from = start
	bolt.def_zone = caster.zone_selected
	bolt.damage = max(1, power || 1)
	bolt.damage_type = damage_type || BRUTE
	bolt.flag = damage_flag || "blunt"
	bolt.woundclass = woundclass || BCLASS_BLUNT
	bolt.intdamfactor = intdamfactor || BLUNT_DEFAULT_INT_DAMAGEFACTOR
	bolt.spell_impact_color = impact_color || "#B96DFF"
	bolt.arcane_radius = max(0, radius || 0)
	bolt.chain_remaining = max(0, chain_remaining || 0)
	bolt.ricochet_remaining = max(0, ricochet_remaining || 0)
	bolt.pierce_remaining = max(0, pierce_remaining || 0)
	bolt.existence_repeats = max(0, existence_repeats || 0)
	bolt.shrapnel_remaining = max(0, shrapnel_remaining || 0)
	bolt.payload_tags = payload_tags?.Copy() || list()
	bolt.chain_visited = chain_visited?.Copy() || list()
	bolt.speed = max(0.2, bolt.speed * (speed_multiplier || 1))
	bolt.range = 7
	bolt.max_range = 7
	if(target)
		bolt.preparePixelProjectile(target, start)
	else
		var/turf/angle_target = get_ranged_target_turf(start, angle2dir(forced_angle), bolt.range)
		bolt.preparePixelProjectile(angle_target || start, start)
		bolt.setAngle(forced_angle)
	if(homing && target)
		bolt.set_homing_target(target)
	bolt.fire()
	return TRUE

/proc/formula_magic_fire_orb_shrapnel(mob/living/carbon/human/caster, turf/start, power, damage_type, damage_flag, woundclass, intdamfactor, impact_color, shrapnel_count, list/payload_tags)
	if(!caster || !start)
		return FALSE
	var/count = max(0, shrapnel_count || 0)
	if(count <= 0)
		return FALSE
	for(var/i in 1 to count)
		formula_magic_fire_orb_followup(caster, start, null, power, 0, 0, 0, 0, 0, 0, damage_type, damage_flag, woundclass, intdamfactor, impact_color, list(), rand(0, 359), 1, FALSE, payload_tags?.Copy())
	return TRUE

/obj/projectile/magic/formula_magic_orb
	name = "formula orb"
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_orb"
	guard_deflectable = TRUE
	damage = 30
	damage_type = BRUTE
	flag = "blunt"
	woundclass = BCLASS_BLUNT
	intdamfactor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	armor_penetration = PEN_NONE
	nodamage = TRUE
	range = 7
	max_range = 7
	hitsound = 'sound/combat/hits/blunt/shovel_hit2.ogg'
	spell_impact_intensity = SPELL_IMPACT_LOW
	var/arcane_radius = 0
	var/chain_remaining = 0
	var/ricochet_remaining = 0
	var/pierce_remaining = 0
	var/existence_repeats = 0
	var/shrapnel_remaining = 0
	var/list/payload_tags = list()
	var/list/chain_visited = list()

/obj/projectile/magic/formula_magic_orb/on_hit(atom/target, blocked = FALSE)
	var/current_angle = Angle
	var/turf/impact_before = get_turf(target)
	var/turf/approach = impact_before ? get_step(impact_before, angle2dir(SIMPLIFY_DEGREES((current_angle || 0) + 180))) : get_turf(src)
	if(!approach)
		approach = get_turf(src)
	if(ismob(target))
		var/mob/M = target
		if(M.anti_magic_check())
			visible_message(span_warning("[src] fizzles on contact with [target]!"))
			playsound(get_turf(target), 'sound/magic/magic_nulled.ogg', 100)
			qdel(src)
			return BULLET_ACT_BLOCK
		hitsound = pick('sound/combat/hits/blunt/shovel_hit.ogg', 'sound/combat/hits/blunt/shovel_hit2.ogg', 'sound/combat/hits/blunt/shovel_hit3.ogg')
	. = ..()
	if(out_of_effective_range())
		return
	var/mob/living/carbon/human/caster
	if(istype(firer, /mob/living/carbon/human))
		caster = firer
	var/turf/impact = get_turf(target)
	if(isliving(target) && blocked != 100)
		var/mob/living/direct_living_target = target
		formula_magic_apply_payload_hit(direct_living_target, caster, damage, damage_type, flag, woundclass, intdamfactor)
		formula_magic_apply_payload_tags(direct_living_target, caster, payload_tags, damage, impact, 0)
	formula_magic_apply_orb_impact(caster, impact, target, damage, arcane_radius, damage_type, flag, woundclass, intdamfactor, spell_impact_color, payload_tags)
	var/list/affected_turfs = formula_magic_impact_turfs(impact, arcane_radius)
	if(existence_repeats > 0 && length(affected_turfs))
		var/existence_lifespan = max(0, 5 SECONDS * existence_repeats)
		if(existence_lifespan > 0)
			var/datum/formula_magic_part/lingering_part = new
			lingering_part.power = damage
			lingering_part.impact_damage_type = damage_type
			lingering_part.impact_flag = flag
			lingering_part.impact_woundclass = woundclass
			lingering_part.impact_intdamfactor = intdamfactor
			lingering_part.impact_color = spell_impact_color
			lingering_part.tags = payload_tags?.Copy() || list()
			formula_magic_schedule_existence_repeats(caster, lingering_part, affected_turfs, damage, existence_lifespan)
	if(shrapnel_remaining > 0 && impact)
		formula_magic_fire_orb_shrapnel(caster, impact, damage, damage_type, flag, woundclass, intdamfactor, spell_impact_color, shrapnel_remaining, payload_tags)
	if(chain_remaining > 0 && impact)
		if(target && !(target in chain_visited))
			chain_visited += target
		var/mob/living/next_target = formula_magic_nearest_chain_target(caster, impact, chain_visited)
		if(next_target)
			var/list/next_visited = chain_visited.Copy()
			next_visited += next_target
			formula_magic_fire_orb_followup(caster, impact, next_target, max(1, round(damage * 0.7)), arcane_radius, chain_remaining - 1, ricochet_remaining, pierce_remaining, existence_repeats, shrapnel_remaining, damage_type, flag, woundclass, intdamfactor, spell_impact_color, next_visited, null, 1, FALSE, payload_tags)
	if(ricochet_remaining > 0 && target)
		var/new_angle = formula_magic_reflected_angle(approach, target, current_angle)
		var/turf/start = formula_magic_ricochet_start_turf(approach, target, new_angle)
		if(start)
			formula_magic_fire_orb_followup(caster, start, null, damage, arcane_radius, chain_remaining, ricochet_remaining - 1, pierce_remaining, existence_repeats, shrapnel_remaining, damage_type, flag, woundclass, intdamfactor, spell_impact_color, chain_visited, new_angle, 1, FALSE, payload_tags)
	if(pierce_remaining > 0)
		pierce_remaining--
		return BULLET_ACT_FORCE_PIERCE
	return BULLET_ACT_HIT
