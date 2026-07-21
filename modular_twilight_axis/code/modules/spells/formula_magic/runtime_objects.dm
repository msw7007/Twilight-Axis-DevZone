/obj/effect/temp_visual/fire/shortduration/formula_magic_toxic
	name = "toxic green flame"
	color = "#36B36A"
	light_color = "#36B36A"
	duration = 4

/obj/effect/temp_visual/formula_magic_falling_meteor
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_meteor"
	name = "falling formula"
	layer = FLY_LAYER
	plane = GAME_PLANE_UPPER
	randomdir = FALSE
	duration = 12
	pixel_z = 270
	var/impact_delay = 9
	var/datum/callback/on_impact

/obj/effect/temp_visual/formula_magic_falling_meteor/Initialize(mapload, datum/callback/impact_cb, impact_color = "#B96DFF", new_impact_delay)
	if(new_impact_delay)
		impact_delay = max(1, new_impact_delay)
	duration = impact_delay + 2
	. = ..()
	on_impact = impact_cb
	if(impact_color)
		add_atom_colour(impact_color, FIXED_COLOUR_PRIORITY)
		set_light(1, 1, 1, l_color = impact_color)
	animate(src, pixel_z = 0, time = impact_delay, easing = CUBIC_EASING | EASE_IN)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_falling_meteor_impact), src), impact_delay)

/obj/effect/temp_visual/formula_magic_falling_meteor/Destroy()
	on_impact = null
	return ..()

/obj/effect/temp_visual/formula_magic_falling_meteor/proc/do_impact()
	on_impact?.Invoke()
	on_impact = null
	alpha = 0

/proc/formula_magic_falling_meteor_impact(obj/effect/temp_visual/formula_magic_falling_meteor/meteor)
	if(!meteor || QDELETED(meteor))
		return FALSE
	meteor.do_impact()
	return TRUE

/obj/effect/formula_magic_dirt
	name = "formula mud"
	desc = "A temporary patch of earth churned by spoken formula."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_summon"
	anchored = TRUE
	density = FALSE
	alpha = 135
	layer = ABOVE_NORMAL_TURF_LAYER
	var/slow_amount = 3

/obj/effect/formula_magic_dirt/proc/setup_formula_dirt(lifespan, dirt_words)
	add_atom_colour("#7A5B35", FIXED_COLOUR_PRIORITY)
	var/word_count = max(1, dirt_words || 1)
	slow_amount = 3 + ((word_count - 1) * 3)
	for(var/mob/living/L in loc)
		L.Slowdown(slow_amount)
	QDEL_IN(src, max(10 SECONDS, lifespan || 30 SECONDS))
	return TRUE

/obj/effect/formula_magic_dirt/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		L.Slowdown(slow_amount)

/obj/effect/formula_magic_part_rune
	name = "formula rune"
	desc = "A dormant formula waits in the ground."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_rune"
	anchored = TRUE
	density = FALSE
	alpha = 150
	layer = ABOVE_NORMAL_TURF_LAYER
	var/mob/living/carbon/human/caster
	var/datum/formula_magic_part/part
	var/remaining_triggers = 1
	var/next_trigger_time = 0

/obj/effect/formula_magic_part_rune/Destroy()
	caster = null
	part = null
	. = ..()

/obj/effect/formula_magic_part_rune/proc/setup_formula_rune(mob/living/carbon/human/new_caster, datum/formula_magic_part/new_part, lifespan, trigger_count)
	caster = new_caster
	part = new_part
	remaining_triggers = max(1, trigger_count || 1)
	if(part?.impact_color)
		add_atom_colour(part.impact_color, FIXED_COLOUR_PRIORITY)
		set_light(1, 1, 1, l_color = part.impact_color)
	QDEL_IN(src, max(10 SECONDS, lifespan || 60 SECONDS))
	return TRUE

/obj/effect/formula_magic_part_rune/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		trigger_formula_rune(AM)

/obj/effect/formula_magic_part_rune/proc/trigger_formula_rune(mob/living/L)
	if(!L || !part || world.time < next_trigger_time)
		return FALSE
	if(caster?.mind && L.mind == caster.mind)
		return FALSE
	var/turf/source = get_turf(src)
	if(!source)
		return FALSE
	next_trigger_time = world.time + 2 SECONDS
	var/power = formula_magic_part_power(part, FORMULA_FORM_RUNE)
	var/ricochet_count = max(0, part.tags["ricochet"] || 0)
	var/chain_count = max(0, part.tags["chain"] || 0)
	var/pierce_count = max(0, part.tags["pierce"] || 0)
	var/shrapnel_count = max(0, part.tags["shrapnel"] || 0)
	if(ricochet_count > 0)
		formula_magic_apply_part_area(caster, part, source, max(0, pierce_count), power, list(caster), FORMULA_FORM_NOVA)
	else
		formula_magic_apply_part_area(caster, part, source, max(0, part.radius || 0), power, list(caster), FORMULA_FORM_RUNE)
	if(chain_count > 0)
		var/list/seen = list(caster, L)
		for(var/i in 1 to chain_count)
			var/mob/living/next_target = formula_magic_nearest_chain_target(caster, source, seen)
			if(!next_target)
				break
			seen += next_target
			formula_magic_apply_beam_line(caster, part, source, get_turf(next_target), 0, FORMULA_FORM_GUIDANCE, FALSE, 0.5)
	if(shrapnel_count > 0)
		formula_magic_fire_orb_shrapnel(caster, source, power, part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor, part.impact_color, shrapnel_count)
	if(pierce_count > 0)
		remaining_triggers--
		if(remaining_triggers > 0)
			return TRUE
	qdel(src)
	return TRUE

/obj/effect/formula_magic_blade_field
	name = "spinning arcyne blade"
	desc = "A brief formula blade turns in the air."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_summon"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_NORMAL_TURF_LAYER
	var/mob/living/carbon/human/caster
	var/damage = 1

/obj/effect/formula_magic_blade_field/Initialize(mapload, mob/living/carbon/human/new_caster, new_damage, lifespan)
	. = ..()
	caster = new_caster
	damage = max(1, new_damage || 1)
	add_atom_colour("#C8F5D2", FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, max(2 SECONDS, lifespan || 10 SECONDS))

/obj/effect/formula_magic_blade_field/Destroy()
	caster = null
	return ..()

/obj/effect/formula_magic_blade_field/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		if(L != caster)
			formula_magic_apply_payload_hit(L, caster, damage, BRUTE, "slash", BCLASS_CUT)

/datum/status_effect/buff/formula_magic_stat_aura
	id = "formula_magic_stat_aura"
	alert_type = null
	duration = 30 SECONDS

/datum/status_effect/buff/formula_magic_stat_aura/on_creation(mob/living/new_owner, list/stat_bonuses, new_duration)
	if(length(stat_bonuses))
		effectedstats = stat_bonuses.Copy()
	if(new_duration)
		duration = new_duration
	return ..()

/datum/status_effect/debuff/formula_magic_stat_curse
	id = "formula_magic_stat_curse"
	alert_type = null
	duration = 30 SECONDS

/datum/status_effect/debuff/formula_magic_stat_curse/on_creation(mob/living/new_owner, list/stat_debuffs, new_duration)
	if(length(stat_debuffs))
		effectedstats = stat_debuffs.Copy()
	if(new_duration)
		duration = new_duration
	return ..()

/datum/status_effect/buff/formula_magic_nondetection
	id = "formula_magic_nondetection"
	alert_type = null
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/buff/formula_magic_nondetection/on_apply()
	. = ..()
	owner.add_filter("formula_nondetection", 2, list("type" = "outline", "color" = "#2F80FF", "alpha" = 25, "size" = 1))

/datum/status_effect/buff/formula_magic_nondetection/on_remove()
	. = ..()
	owner.remove_filter("formula_nondetection")

/datum/stressevent/formula_magic_temporal_stress
	stressadd = 2
	desc = span_warning("The spoken Origin presses against my sense of time.")

/datum/status_effect/buff/formula_magic_aura
	id = "formula_magic_aura"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/blocks_all_formula = TRUE
	var/applied_antimagic_trait = FALSE
	var/list/damage_resistance = list()
	var/list/status_resistance = list()
	var/list/chance_resistance = list()

/datum/status_effect/buff/formula_magic_aura/on_creation(mob/living/new_owner, new_duration, datum/formula_magic_part/part, strength_multiplier = 1)
	if(new_duration)
		duration = new_duration
	compile_from_part(part, strength_multiplier)
	return ..()

/datum/status_effect/buff/formula_magic_aura/proc/compile_from_part(datum/formula_magic_part/part, strength_multiplier = 1)
	damage_resistance = list()
	status_resistance = list()
	chance_resistance = list()
	blocks_all_formula = TRUE
	if(!part)
		return
	var/strength = max(0.05, strength_multiplier || 1)
	for(var/tag in part.tags)
		switch(tag)
			if("damage_burn")
				damage_resistance[BURN] = max(damage_resistance[BURN] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("ignite")
				chance_resistance["ignite"] = max(chance_resistance["ignite"] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("damage_cold")
				damage_resistance["cold"] = max(damage_resistance["cold"] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("frost_stack")
				chance_resistance["frost_stack"] = max(chance_resistance["frost_stack"] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("damage_shock")
				damage_resistance["shock"] = max(damage_resistance["shock"] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("electrocute")
				chance_resistance["electrocute"] = max(chance_resistance["electrocute"] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("damage_blunt", "damage_force")
				damage_resistance[BRUTE] = max(damage_resistance[BRUTE] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("slow", "dirt", "gravity", "anchor_target", "phase", "teleport", "push", "pull")
				status_resistance[tag] = max(status_resistance[tag] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE
			if("blind", "silence", "confuse")
				chance_resistance[tag] = max(chance_resistance[tag] || 0, 0.1 * (part.tags[tag] || 1) * strength)
				blocks_all_formula = FALSE

/datum/status_effect/buff/formula_magic_aura/on_apply()
	. = ..()
	if(!.)
		return FALSE
	if(blocks_all_formula && owner)
		ADD_TRAIT(owner, TRAIT_ANTIMAGIC, src)
		applied_antimagic_trait = TRUE
	return TRUE

/datum/status_effect/buff/formula_magic_aura/on_remove()
	if(applied_antimagic_trait && owner)
		REMOVE_TRAIT(owner, TRAIT_ANTIMAGIC, src)
		applied_antimagic_trait = FALSE
	return ..()

/datum/status_effect/buff/formula_magic_aura/proc/blocks_formula_casting()
	return blocks_all_formula

/datum/status_effect/buff/formula_magic_aura/proc/modify_formula_damage(amount, damage_type, damage_flag)
	if(blocks_all_formula)
		return 0
	var/reduction = 0
	if(damage_type in damage_resistance)
		reduction = max(reduction, damage_resistance[damage_type])
	if(damage_flag in damage_resistance)
		reduction = max(reduction, damage_resistance[damage_flag])
	reduction = min(0.95, max(0, reduction))
	return round(amount * (1 - reduction))
