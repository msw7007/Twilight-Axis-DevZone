/proc/formula_magic_execute_orb_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	if(!context?.caster || !part)
		return FALSE
	var/turf/source = get_turf(context.caster)
	var/turf/target = context.target_turf || get_ranged_target_turf(context.caster, context.caster.dir, part.range)
	if(!target)
		target = get_step(source, context.caster.dir)
	if(!target)
		target = source
	var/projectiles_to_fire = max(1, part.projectile_count || 1)
	var/spread_step = projectiles_to_fire > 1 ? 12 : 0
	var/start_spread = -round((projectiles_to_fire - 1) * spread_step / 2)
	for(var/i in 1 to projectiles_to_fire)
		var/obj/projectile/magic/formula_magic_orb/bolt = new(source)
		bolt.firer = context.caster
		bolt.fired_from = source
		bolt.def_zone = context.caster.zone_selected
		bolt.damage = formula_magic_part_power(part, FORMULA_FORM_ORB)
		bolt.damage_type = part.impact_damage_type
		bolt.flag = part.impact_flag
		bolt.woundclass = part.impact_woundclass
		bolt.intdamfactor = part.impact_intdamfactor
		bolt.spell_impact_color = part.impact_color
		bolt.arcane_radius = max(0, part.radius || 0)
		bolt.chain_remaining = max(0, part.tags["chain"] || 0)
		bolt.ricochet_remaining = max(0, part.tags["ricochet"] || 0)
		bolt.pierce_remaining = max(0, part.tags["pierce"] || 0)
		bolt.existence_repeats = max(0, part.tags["existence"] || 0)
		bolt.shrapnel_remaining = max(0, part.tags["shrapnel"] || 0)
		bolt.payload_tags = part.tags.Copy()
		bolt.chain_visited = list()
		bolt.range = max(1, min(part.range, 14))
		bolt.max_range = bolt.range
		bolt.preparePixelProjectile(target, context.caster, null, start_spread + ((i - 1) * spread_step))
		bolt.fire()
	context.caster.visible_message(span_notice("[context.caster] releases [projectiles_to_fire] arcyne orb[projectiles_to_fire == 1 ? "" : "s"]."))
	return TRUE

/proc/formula_magic_execute_seeker_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	if(!context?.caster || !part)
		return FALSE
	var/turf/source = get_turf(context.caster)
	var/turf/search_center = formula_magic_limited_part_target(context, part, part.range)
	if(!source || !search_center)
		return FALSE
	var/mob/living/target = formula_magic_nearest_chain_target(context.caster, search_center, list(context.caster))
	if(!target)
		target = search_center
	var/projectiles_to_fire = max(1, min(formula_magic_part_count_form(part, FORMULA_FORM_ORB) || part.projectile_count || 1, formula_magic_part_count_form(part, FORMULA_FORM_WAVE) || 1))
	for(var/i in 1 to projectiles_to_fire)
		formula_magic_fire_orb_followup(context.caster, source, target, formula_magic_part_power(part, FORMULA_FORM_ORB), max(0, part.radius || 0), max(0, part.tags["chain"] || 0), max(0, part.tags["ricochet"] || 0), max(0, part.tags["pierce"] || 0), max(0, part.tags["existence"] || 0), max(0, part.tags["shrapnel"] || 0), part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor, part.impact_color, list(), null, 0.2, TRUE, part.tags.Copy())
	context.caster.visible_message(span_notice("[context.caster] releases a seeking formula orb."))
	return TRUE

/proc/formula_magic_execute_aura_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	if(!source)
		return FALSE
	new /obj/effect/temp_visual/spell_impact(source, part.impact_color, SPELL_IMPACT_LOW)
	var/aura_words = max(1, formula_magic_part_form_repeat_count(part, FORMULA_FORM_AURA) || 1)
	var/aura_duration = max(30 SECONDS, part.duration || (aura_words * 30 SECONDS))
	formula_magic_apply_aura_status(context.caster, part, aura_duration, 1)
	var/widen_count = formula_magic_part_modifier_count(part, "widen")
	if(widen_count > 0 && context.caster.current_fellowship)
		var/list/members = context.caster.current_fellowship.get_members()
		members -= context.caster
		for(var/i in 1 to min(length(members), aura_words))
			var/mob/living/member = pick(members)
			members -= member
			if(member)
				new /obj/effect/temp_visual/spell_impact(get_turf(member), part.impact_color, SPELL_IMPACT_LOW)
				formula_magic_apply_aura_status(member, part, max(10 SECONDS, round(aura_duration * 0.3)), 0.3)
	var/pierce_count = max(0, part.tags["pierce"] || 0)
	if(pierce_count > 0)
		var/pierce_fraction = min(1, pierce_count * 0.3)
		for(var/mob/living/L in range(1, source))
			if(L == context.caster)
				continue
			new /obj/effect/temp_visual/spell_impact(get_turf(L), part.impact_color, SPELL_IMPACT_LOW)
			formula_magic_apply_aura_status(L, part, max(10 SECONDS, round(aura_duration * pierce_fraction)), pierce_fraction)
	var/ricochet_count = max(0, part.tags["ricochet"] || 0)
	if(ricochet_count > 0 && context.caster.current_fellowship)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_aura_ricochet_jumps), context.caster, part, ricochet_count, aura_duration), aura_duration)
	context.caster.visible_message(span_notice("[context.caster] gathers a formula aura."))
	return TRUE

/proc/formula_magic_apply_aura_ricochet_jumps(mob/living/carbon/human/caster, datum/formula_magic_part/part, ricochet_count, aura_duration)
	if(!caster || QDELETED(caster) || !part || ricochet_count <= 0 || !caster.current_fellowship)
		return FALSE
	var/list/members = caster.current_fellowship.get_members()
	members -= caster
	for(var/i in 1 to ricochet_count)
		if(!length(members))
			break
		var/mob/living/member = pick(members)
		members -= member
		if(!member || QDELETED(member))
			continue
		new /obj/effect/temp_visual/spell_impact(get_turf(member), part.impact_color, SPELL_IMPACT_LOW)
		formula_magic_apply_aura_status(member, part, max(10 SECONDS, round((aura_duration || 30 SECONDS) * 0.3)), 0.3)
	return TRUE

/proc/formula_magic_apply_aura_status(mob/living/target, datum/formula_magic_part/part, duration, strength_multiplier = 1)
	if(!target || !part)
		return FALSE
	var/datum/status_effect/buff/formula_magic_aura/aura = target.apply_status_effect(/datum/status_effect/buff/formula_magic_aura, max(1 SECONDS, duration || 30 SECONDS), part, strength_multiplier)
	return !!aura

/proc/formula_magic_execute_moment_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/target = formula_magic_limited_part_target(context, part, 3 + max(0, (part.tags["moment"] || 1) - 1))
	if(!target)
		return FALSE
	return formula_magic_apply_part_area(context.caster, part, target, part.radius, formula_magic_part_power(part, FORMULA_FORM_INSTANT), null, FORMULA_FORM_INSTANT)

/proc/formula_magic_execute_beam_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/turf/target = formula_magic_limited_part_target(context, part, max(1, part.range))
	if(!source || !target)
		return FALSE
	if(target == source)
		target = get_ranged_target_turf(source, context.caster.dir, max(1, part.range))
	var/beam_words = max(1, part.tags["beam"] || 1)
	var/fade_percent = max(0, 10 - max(0, beam_words - 1))
	return formula_magic_apply_beam_line(context.caster, part, source, target, fade_percent, FORMULA_FORM_BEAM)

/proc/formula_magic_execute_spiral_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	if(!context?.caster || !part)
		return FALSE
	var/arms = max(1, part.tags["spiral"] || 1)
	var/radius = max(1, 1 + (part.radius || 0))
	var/cycles = max(1, 1 + (part.tags["existence"] || 0))
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_spiral_loop), context.caster, part, arms, radius, cycles, FORMULA_FORM_SPIRAL, FALSE)
	return TRUE

/proc/formula_magic_execute_summon_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/summon_dir = get_dir(source, context.target_turf) || context.caster.dir
	var/turf/target = get_step(source, summon_dir)
	if(!target)
		return FALSE
	new /obj/effect/temp_visual/spell_impact(target, part.impact_color, SPELL_IMPACT_MEDIUM)
	var/summon_words = max(1, formula_magic_part_count_form(part, FORMULA_FORM_SUMMON) || 1)
	var/summon_lifespan = max(5 MINUTES, part.duration) + (max(0, part.tags["existence"] || 0) * 1 MINUTES)
	var/list/summon_targets = list(target)
	var/widen_count = formula_magic_part_modifier_count(part, "widen")
	if(widen_count > 0)
		for(var/turf/T as anything in formula_magic_area_turfs_for_shape(target, min(8, widen_count), FORMULA_FORM_SUMMON))
			summon_targets |= T
	if(!formula_magic_part_has_payload_words(part))
		if(formula_magic_part_modifier_count(part, "existence") > 0)
			return formula_magic_detonate_formula_part(context.caster, part, "empty summon existence", 0)
		for(var/turf/T as anything in summon_targets)
			for(var/i in 1 to summon_words)
				var/obj/item/natural/clay/clay = new(T)
				QDEL_IN(clay, summon_lifespan)
		return TRUE
	formula_magic_apply_part_area(context.caster, part, target, part.radius, formula_magic_part_power(part, FORMULA_FORM_SUMMON), null, FORMULA_FORM_SUMMON)
	return TRUE

/proc/formula_magic_execute_wave_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/turf/target = formula_magic_limited_part_target(context, part, part.range)
	if(!source || !target)
		return FALSE
	var/list/line = getline(source, target)
	line -= source
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_progressive_part_line), context.caster, part, line, max(0, part.radius || 0), 5, FORMULA_FORM_WAVE)
	return TRUE

/proc/formula_magic_execute_touch_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/turf/target = context.target_turf
	var/touch_dir = get_dir(source, target) || context.caster.dir
	var/turf/touch_turf = get_step(source, touch_dir)
	if(!touch_turf)
		return FALSE
	return formula_magic_apply_part_area(context.caster, part, touch_turf, part.radius, formula_magic_part_power(part, FORMULA_FORM_TOUCH), null, FORMULA_FORM_TOUCH)

/proc/formula_magic_execute_cloak_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	if(!source)
		return FALSE
	new /obj/effect/temp_visual/spell_impact(source, part.impact_color, SPELL_IMPACT_MEDIUM)
	var/cloak_repeats = max(1, min(formula_magic_part_count_form(part, FORMULA_FORM_SPIRAL) || 1, formula_magic_part_count_form(part, FORMULA_FORM_AURA) || 1))
	var/duration = max(10 SECONDS, 10 SECONDS + (max(0, cloak_repeats - 1) * 5 SECONDS) + (part.tags["existence_duration"] || 0))
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_cloak_loop), context.caster, part, max(1, part.radius || 1), duration)
	return TRUE

/proc/formula_magic_execute_meteor_part(datum/formula_magic_context/context, datum/formula_magic_part/part, index)
	var/turf/target = formula_magic_limited_part_target(context, part, part.range)
	if(!target)
		return FALSE
	var/form_repeats = max(1, min(formula_magic_part_count_form(part, FORMULA_FORM_INSTANT) || 1, formula_magic_part_count_form(part, FORMULA_FORM_BEAM) || 1))
	var/delay = max(0.5 SECONDS, 2 SECONDS - ((form_repeats - 1) * 0.15 SECONDS) + ((index - 1) * 0.5 SECONDS))
	var/datum/formula_magic_part/fall_part = formula_magic_copy_part_payload(part)
	if(!fall_part)
		return FALSE
	var/fall_power = round(formula_magic_part_power(part, FORMULA_FORM_FALL) * 1.5)
	var/datum/callback/impact_callback = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_fall_payload), context.caster, fall_part, target, fall_power)
	new /obj/effect/temp_visual/formula_magic_falling_meteor(target, impact_callback, part.impact_color, delay)
	QDEL_IN(fall_part, delay + 1 MINUTES)
	return TRUE

/proc/formula_magic_execute_guidance_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/turf/target = formula_magic_limited_part_target(context, part, part.range)
	if(!source || !target)
		return FALSE
	return formula_magic_apply_beam_line(context.caster, part, source, target, 0, FORMULA_FORM_GUIDANCE)

/proc/formula_magic_execute_breath_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/breath_length = 2
	var/turf/target = get_ranged_target_turf(source, context.caster.dir, breath_length)
	if(!source || !target)
		return FALSE
	var/list/line = getline(source, target)
	line -= source
	var/breath_duration = max(2 SECONDS, 2 SECONDS + (max(0, min(formula_magic_part_count_form(part, FORMULA_FORM_TOUCH) || 1, formula_magic_part_count_form(part, FORMULA_FORM_NOVA) || 1) - 1) * 1 SECONDS) + (part.tags["existence_duration"] || 0))
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_breath_loop), context.caster, part, breath_length, max(1, part.radius || 1), breath_duration)
	return TRUE

/proc/formula_magic_execute_nova_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	if(!source)
		return FALSE
	return formula_magic_apply_part_area(context.caster, part, source, max(1, part.radius || 1), formula_magic_part_power(part, FORMULA_FORM_NOVA), list(context.caster), FORMULA_FORM_NOVA)

/proc/formula_magic_execute_rune_part(datum/formula_magic_context/context, datum/formula_magic_part/part, index)
	var/turf/target = formula_magic_limited_part_target(context, part, part.range)
	if(!target)
		return FALSE
	var/rune_words = max(1, min(formula_magic_part_count_form(part, FORMULA_FORM_SUMMON) || 1, formula_magic_part_count_form(part, FORMULA_FORM_GUIDANCE) || 1))
	var/lifespan = 60 SECONDS + (max(0, rune_words - 1) * 20 SECONDS)
	var/trigger_count = max(1, 1 + max(0, part.tags["pierce"] || 0))
	var/list/targets = list(target)
	var/widen_count = max(0, part.tags["widen"] || 0)
	if(widen_count > 0)
		for(var/direction in GLOB.cardinals)
			var/turf/outer = get_ranged_target_turf(target, direction, widen_count)
			if(outer)
				targets |= outer
	for(var/turf/T as anything in targets)
		if(!T)
			continue
		new /obj/effect/temp_visual/spell_impact(T, part.impact_color, SPELL_IMPACT_MEDIUM)
		var/obj/effect/formula_magic_part_rune/rune = new(T)
		rune.setup_formula_rune(context.caster, part, lifespan, trigger_count)
	return TRUE


/proc/formula_magic_progressive_part_line(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/line, width, delay, form_id = FORMULA_FORM_WAVE)
	if(!caster || !part || !length(line))
		return FALSE
	var/list/hit = list(caster)
	var/turf/previous_turf = get_turf(caster)
	for(var/turf/T in line)
		if(!T)
			continue
		var/travel_dir = get_dir(previous_turf, T) || caster.dir
		var/list/step_turfs = formula_magic_perpendicular_turfs(T, travel_dir, max(0, width || 0))
		var/list/result = formula_magic_apply_form_payload_turfs(caster, part, step_turfs, formula_magic_part_power(part, form_id), hit, form_id, T)
		var/list/hit_targets = islist(result) ? (result["targets"] || list()) : list()
		for(var/mob/living/L as anything in hit_targets)
			hit |= L
		if(form_id == FORMULA_FORM_WAVE && (part.tags["ricochet"] || 0) > 0 && length(hit_targets) > 0)
			var/turf/random_target = get_ranged_target_turf(T, pick(GLOB.alldirs), max(1, part.range))
			if(random_target)
				var/list/new_line = getline(T, random_target)
				new_line -= T
				INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_progressive_part_line), caster, part, new_line, width, delay, form_id)
				return TRUE
		if(form_id == FORMULA_FORM_WAVE && (part.tags["chain"] || 0) > 0 && length(hit_targets) > 0)
			var/mob/living/next_target = formula_magic_nearest_chain_target(caster, T, hit, max(1, (width || 0) + 1))
			if(next_target)
				var/list/chain_line = getline(T, get_turf(next_target))
				chain_line -= T
				INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_progressive_part_line), caster, part, chain_line, width, delay, form_id)
				return TRUE
		previous_turf = T
		sleep(max(1, delay || 1))
	return TRUE

/proc/formula_magic_spiral_loop(mob/living/carbon/human/caster, datum/formula_magic_part/part, arms, radius, cycles, form_id = FORMULA_FORM_SPIRAL, reverse = FALSE)
	if(!caster || !part)
		return FALSE
	arms = max(1, min(8, arms || 1))
	radius = max(1, min(8, radius || 1))
	cycles = max(1, min(8, cycles || 1))
	var/ricochet_remaining = max(0, part.tags["ricochet"] || 0)
	var/list/active_arms = list()
	var/list/arm_pierce = list()
	for(var/arm in 1 to arms)
		active_arms[arm] = TRUE
		arm_pierce[arm] = max(0, part.tags["pierce"] || 0)
	for(var/cycle in 1 to cycles)
		var/turf/source = get_turf(caster)
		var/list/path_turfs = formula_magic_spiral_ring_turfs(source, radius, caster.dir, reverse)
		if(!length(path_turfs))
			return FALSE
		for(var/step_index in 1 to length(path_turfs))
			var/turf/current_source = get_turf(caster)
			if(!current_source)
				return FALSE
			path_turfs = formula_magic_spiral_ring_turfs(current_source, radius, caster.dir, reverse)
			var/any_active = FALSE
			for(var/arm in 1 to arms)
				if(!active_arms[arm])
					continue
				any_active = TRUE
				var/path_index = ((step_index - 1 + round((arm - 1) * length(path_turfs) / arms)) % length(path_turfs)) + 1
				var/turf/target = path_turfs[path_index]
				if(target)
					var/list/result = formula_magic_apply_part_area(caster, part, target, 0, formula_magic_part_power(part, form_id), list(caster), form_id)
					var/list/hit_targets = islist(result) ? (result["targets"] || list()) : list()
					if(length(hit_targets) > 0 && ricochet_remaining > 0)
						ricochet_remaining--
						reverse = !reverse
						continue
					if(length(hit_targets) > 0)
						if((arm_pierce[arm] || 0) > 0)
							arm_pierce[arm]--
						else
							active_arms[arm] = FALSE
			if(!any_active)
				return TRUE
			sleep(2)
	return TRUE

/proc/formula_magic_spiral_ring_turfs(turf/source, radius, start_dir = NORTH, reverse = FALSE)
	var/list/result = list()
	if(!source)
		return result
	radius = max(1, min(8, radius || 1))
	var/cx = source.x
	var/cy = source.y
	var/cz = source.z
	for(var/north_dx = -radius, north_dx <= radius, north_dx++)
		var/turf/north_turf = locate(cx + north_dx, cy + radius, cz)
		if(north_turf)
			result += north_turf
	for(var/east_dy = radius - 1, east_dy >= -radius, east_dy--)
		var/turf/east_turf = locate(cx + radius, cy + east_dy, cz)
		if(east_turf)
			result += east_turf
	for(var/south_dx = radius - 1, south_dx >= -radius, south_dx--)
		var/turf/south_turf = locate(cx + south_dx, cy - radius, cz)
		if(south_turf)
			result += south_turf
	for(var/west_dy = -radius + 1, west_dy <= radius - 1, west_dy++)
		var/turf/west_turf = locate(cx - radius, cy + west_dy, cz)
		if(west_turf)
			result += west_turf
	var/turf/start_turf = get_ranged_target_turf(source, start_dir || NORTH, radius)
	var/start_index = start_turf ? result.Find(start_turf) : 0
	if(start_index > 1)
		var/list/rotated = list()
		for(var/i in start_index to length(result))
			rotated += result[i]
		for(var/i in 1 to start_index - 1)
			rotated += result[i]
		result = rotated
	if(!reverse)
		return result
	var/list/reversed = list()
	for(var/i = length(result), i >= 1, i--)
		reversed += result[i]
	return reversed

/proc/formula_magic_cloak_loop(mob/living/carbon/human/caster, datum/formula_magic_part/part, radius, duration)
	if(!caster || !part)
		return FALSE
	var/end_time = world.time + max(1 SECONDS, duration || 10 SECONDS)
	while(!QDELETED(caster) && world.time <= end_time)
		formula_magic_apply_part_area(caster, part, get_turf(caster), radius, max(1, round(formula_magic_part_power(part, FORMULA_FORM_CLOAK) * 0.25)), list(caster), FORMULA_FORM_CLOAK)
		sleep(2 SECONDS)
	return TRUE

/proc/formula_magic_breath_loop(mob/living/carbon/human/caster, datum/formula_magic_part/part, length, width, duration)
	if(!caster || !part)
		return FALSE
	var/end_time = world.time + max(1 SECONDS, duration || 2 SECONDS)
	while(!QDELETED(caster) && world.time <= end_time)
		var/turf/source = get_turf(caster)
		var/turf/target = get_ranged_target_turf(source, caster.dir, max(1, length || 2))
		var/list/line = getline(source, target)
		line -= source
		formula_magic_progressive_part_line(caster, part, line, width, 1, FORMULA_FORM_BREATH)
		sleep(5)
	return TRUE
