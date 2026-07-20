/proc/formula_magic_schedule_existence_repeats(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/affected_turfs, power, lifespan)
	if(!caster || QDELETED(caster) || !part || !length(affected_turfs))
		return FALSE
	var/repeat_count = max(0, part.tags["existence"] || 0)
	if(repeat_count <= 0)
		return FALSE
	var/datum/formula_magic_part/repeat_part = formula_magic_copy_part_payload(part)
	if(!repeat_part)
		return FALSE
	var/repeat_delay = formula_magic_payload_repeat_delay(part)
	var/payload_zone_duration = max(0, part.tags["payload_zone_duration"] || 0)
	if(payload_zone_duration > 0)
		var/total_zone_duration = max(payload_zone_duration, repeat_delay * repeat_count)
		repeat_count = max(1, CEILING(total_zone_duration / repeat_delay, 1))
	var/list/repeat_turfs = affected_turfs.Copy()
	for(var/repeat_index in 1 to repeat_count)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_repeat_payload_turfs), caster, repeat_part, repeat_turfs, max(1, power || part.power || 1)), repeat_index * repeat_delay)
	QDEL_IN(repeat_part, (repeat_count * repeat_delay) + 1 SECONDS)
	return TRUE

/proc/formula_magic_payload_repeat_delay(datum/formula_magic_part/part)
	if(!part)
		return 2 SECONDS
	return max(1, part.tags["payload_repeat_delay"] || 2 SECONDS)

/proc/formula_magic_copy_part_payload(datum/formula_magic_part/part)
	if(!part)
		return null
	var/datum/formula_magic_part/copy = new
	copy.tags = part.tags?.Copy() || list()
	copy.power = part.power
	copy.range = part.range
	copy.radius = part.radius
	copy.duration = part.duration
	copy.impact_damage_type = part.impact_damage_type
	copy.impact_flag = part.impact_flag
	copy.impact_woundclass = part.impact_woundclass
	copy.impact_intdamfactor = part.impact_intdamfactor
	copy.impact_color = part.impact_color
	copy.projectile_count = part.projectile_count
	return copy

/proc/formula_magic_repeat_payload_turfs(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/target_turfs, power)
	if(!caster || QDELETED(caster) || !part || QDELETED(part) || !length(target_turfs))
		return FALSE
	for(var/turf/T as anything in target_turfs)
		if(!T)
			continue
		new /obj/effect/temp_visual/spell_impact(T, part.impact_color, SPELL_IMPACT_LOW)
		formula_magic_apply_part_turf_payload(caster, part, T, max(1, power || part.power || 1))
		for(var/mob/living/L in T)
			if(L == caster)
				continue
			formula_magic_apply_part_payload_hit(L, caster, part, max(1, power || part.power || 1), T)
	return TRUE

/proc/formula_magic_apply_form_payload_area(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/center, radius, power, list/excluded, form_id = null)
	if(!center || !part)
		return list("turfs" = list(), "targets" = list())
	var/list/result_turfs = list()
	var/list/excluded_targets = excluded?.Copy() || list()
	var/list/hit_targets = list()
	var/effective_radius = max(0, min(radius || 0, 8))
	for(var/turf/T as anything in formula_magic_area_turfs_for_shape(center, effective_radius, form_id))
		if(!formula_magic_area_turf_reachable(center, T))
			continue
		result_turfs |= T
		new /obj/effect/temp_visual/spell_impact(T, part.impact_color, SPELL_IMPACT_LOW)
		formula_magic_apply_part_turf_payload(caster, part, T, max(1, power || part.power || 1))
		for(var/mob/living/L in T)
			if(L == caster || (excluded_targets && (L in excluded_targets)) || (L in hit_targets))
				continue
			hit_targets |= L
			formula_magic_apply_part_payload_hit(L, caster, part, max(1, power || part.power || 1), center)
	return list("turfs" = result_turfs, "targets" = hit_targets)

/proc/formula_magic_apply_form_payload_turfs(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/target_turfs, power, list/excluded, form_id = null, turf/center)
	if(!part || !length(target_turfs))
		return list("turfs" = list(), "targets" = list())
	var/list/result_turfs = list()
	var/list/excluded_targets = excluded?.Copy() || list()
	var/list/hit_targets = list()
	for(var/turf/T as anything in target_turfs)
		if(!T || (T in result_turfs))
			continue
		result_turfs |= T
		new /obj/effect/temp_visual/spell_impact(T, part.impact_color, SPELL_IMPACT_LOW)
		formula_magic_apply_part_turf_payload(caster, part, T, max(1, power || part.power || 1))
		for(var/mob/living/L in T)
			if(L == caster || (excluded_targets && (L in excluded_targets)) || (L in hit_targets))
				continue
			hit_targets |= L
			formula_magic_apply_part_payload_hit(L, caster, part, max(1, power || part.power || 1), center || T)
	var/datum/formula_magic_context/area_context = new
	area_context.caster = caster
	area_context.source_turf = get_turf(caster)
	area_context.target_turf = center || result_turfs[1]
	formula_magic_apply_area_modifier_handlers(area_context, part, form_id, center || result_turfs[1], max(1, power || part.power || 1), 0, result_turfs, hit_targets)
	qdel(area_context)
	return list("turfs" = result_turfs, "targets" = hit_targets)

/proc/formula_magic_perpendicular_turfs(turf/center, travel_dir, width)
	var/list/result = list()
	if(!center)
		return result
	result |= center
	width = max(0, min(width || 0, 8))
	if(width <= 0)
		return result
	var/left_dir = turn(travel_dir, 90)
	var/right_dir = turn(travel_dir, -90)
	var/turf/left_turf = center
	var/turf/right_turf = center
	for(var/side_step in 1 to width)
		left_turf = get_step(left_turf, left_dir)
		right_turf = get_step(right_turf, right_dir)
		if(left_turf)
			result |= left_turf
		if(right_turf)
			result |= right_turf
	return result

/proc/formula_magic_apply_instant_existence(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/affected_turfs, power)
	var/existence_count = formula_magic_part_modifier_count(part, "existence")
	if(existence_count <= 0 || !length(affected_turfs))
		return FALSE
	return formula_magic_schedule_existence_repeats(caster, part, affected_turfs, power, 0)

/proc/formula_magic_apply_matrix_existence(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/affected_turfs, power)
	return formula_magic_apply_instant_existence(caster, part, affected_turfs, power)

/proc/formula_magic_apply_part_area(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/center, radius, power, list/excluded, form_id = null)
	if(!center || !part)
		return null
	var/list/result = formula_magic_apply_form_payload_area(caster, part, center, radius, power, excluded, form_id)
	var/list/affected_turfs = result["turfs"] || list()
	var/list/hit_targets = result["targets"] || list()
	var/datum/formula_magic_context/area_context = new
	area_context.caster = caster
	area_context.source_turf = get_turf(caster)
	area_context.target_turf = center
	formula_magic_apply_area_modifier_handlers(area_context, part, form_id, center, max(1, power || part.power || 1), radius, affected_turfs, hit_targets)
	qdel(area_context)
	return result

/proc/formula_magic_apply_beam_line(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, turf/target, fade_percent, form_id = FORMULA_FORM_BEAM, allow_followups = TRUE, power_multiplier = 1, apply_modifiers = TRUE)
	if(!caster || !part || !source || !target)
		return FALSE
	var/distance = 0
	var/turf/beam_end = source
	var/turf/previous_turf = source
	var/beam_dir = get_dir(source, target) || caster.dir
	var/effective_radius = apply_modifiers ? max(0, part.radius || 0) : 0
	var/beam_width = 0
	if(form_id == FORMULA_FORM_BEAM)
		beam_width = FLOOR(effective_radius / 2, 1)
	else if(form_id == FORMULA_FORM_GUIDANCE)
		beam_width = effective_radius
	var/living_pierce_left = (apply_modifiers && form_id == FORMULA_FORM_BEAM) ? max(0, part.tags["pierce"] || 0) : 0
	var/list/hit = list(caster)
	var/list/affected_turfs = list()
	var/list/existence_turfs = list()
	for(var/turf/T in getline(source, target))
		if(T == source)
			continue
		distance++
		beam_end = T
		var/fade_distance = distance
		var/current_power = max(1, round(formula_magic_part_power(part, form_id) * (power_multiplier || 1) * max(0.1, 1 - ((fade_percent || 0) * fade_distance / 100))))
		affected_turfs |= T
		var/living_hits_this_step = 0
		var/hit_count_before = length(hit)
		formula_magic_apply_beam_turf(caster, part, T, current_power, hit)
		if(length(hit) > hit_count_before)
			existence_turfs |= T
			living_hits_this_step += length(hit) - hit_count_before
		if(beam_width > 0)
			var/left_dir = turn(beam_dir, 90)
			var/right_dir = turn(beam_dir, -90)
			var/turf/left_turf = T
			var/turf/right_turf = T
			for(var/side_step in 1 to beam_width)
				left_turf = get_step(left_turf, left_dir)
				right_turf = get_step(right_turf, right_dir)
				if(left_turf)
					affected_turfs |= left_turf
					hit_count_before = length(hit)
					formula_magic_apply_beam_turf(caster, part, left_turf, current_power, hit)
					if(length(hit) > hit_count_before)
						existence_turfs |= left_turf
						living_hits_this_step += length(hit) - hit_count_before
				if(right_turf)
					affected_turfs |= right_turf
					hit_count_before = length(hit)
					formula_magic_apply_beam_turf(caster, part, right_turf, current_power, hit)
					if(length(hit) > hit_count_before)
						existence_turfs |= right_turf
						living_hits_this_step += length(hit) - hit_count_before
		if(form_id == FORMULA_FORM_BEAM && living_hits_this_step > 0)
			living_pierce_left -= living_hits_this_step
			if(living_pierce_left < 0)
				break
		if(formula_magic_beam_turf_blocks(previous_turf, T))
			break
		previous_turf = T
	if(form_id == FORMULA_FORM_BEAM && beam_end != source)
		generate_tracer_between_points(RETURN_PRECISE_POINT(source), RETURN_PRECISE_POINT(beam_end), /obj/effect/projectile/tracer/stun, part.impact_color, 5)
	if(apply_modifiers && (part.tags["existence"] || 0) > 0)
		var/list/existence_targets = (form_id == FORMULA_FORM_GUIDANCE) ? affected_turfs : existence_turfs
		if(length(existence_targets))
			formula_magic_apply_matrix_existence(caster, part, existence_targets, max(1, formula_magic_part_power(part, form_id)))
	if(apply_modifiers && allow_followups && form_id == FORMULA_FORM_BEAM && beam_end != source)
		if((part.tags["chain"] || 0) > 0 && length(hit) > 1)
			var/list/visited = hit.Copy()
			for(var/i in 1 to max(0, part.tags["chain"] || 0))
				var/mob/living/next_target = formula_magic_nearest_chain_target(caster, beam_end, visited)
				if(!next_target)
					break
				visited |= next_target
				formula_magic_apply_beam_line(caster, part, beam_end, get_turf(next_target), fade_percent, form_id, FALSE, 1)
		if((part.tags["ricochet"] || 0) > 0)
			var/turf/start = beam_end
			var/current_angle = Get_Angle(source, beam_end)
			for(var/i in 1 to max(0, part.tags["ricochet"] || 0))
				if(!start)
					break
				var/turf/approach = start ? formula_magic_step_from_angle(start, SIMPLIFY_DEGREES((current_angle || 0) + 180)) : source
				if(!approach)
					approach = source
				var/new_angle = formula_magic_reflected_angle_from_projectile(approach, start, current_angle)
				if(isnull(new_angle))
					break
				var/turf/reflected_start = formula_magic_ricochet_start_turf(approach, start, new_angle)
				if(!reflected_start)
					break
				var/turf/reflected_target = formula_magic_turf_at_angle(reflected_start, new_angle, max(1, part.range))
				if(!reflected_target)
					break
				formula_magic_apply_beam_line(caster, part, reflected_start, reflected_target, fade_percent, form_id, FALSE, 1)
				var/turf/next_end = formula_magic_trace_beam_end(reflected_start, reflected_target)
				if(!next_end || next_end == reflected_start)
					break
				current_angle = Get_Angle(reflected_start, next_end)
				start = next_end
		if((part.tags["shrapnel"] || 0) > 0)
			for(var/i in 1 to max(0, part.tags["shrapnel"] || 0))
				var/turf/random_target = get_ranged_target_turf(beam_end, pick(GLOB.alldirs), max(1, part.range))
				if(random_target)
					formula_magic_apply_beam_line(caster, part, beam_end, random_target, fade_percent, form_id, FALSE, 1, FALSE)
	return TRUE

/proc/formula_magic_trace_beam_end(turf/source, turf/target)
	if(!source || !target)
		return source
	var/turf/beam_end = source
	var/turf/previous_turf = source
	for(var/turf/T in getline(source, target))
		if(T == source)
			continue
		beam_end = T
		if(formula_magic_beam_turf_blocks(previous_turf, T))
			break
		previous_turf = T
	return beam_end

/proc/formula_magic_beam_turf_blocks(turf/previous, turf/current)
	if(!current)
		return TRUE
	if(current.density)
		return TRUE
	if(previous && previous.LinkBlockedWithAccess(current, null))
		return TRUE
	if(current.is_blocked_turf(TRUE))
		return TRUE
	for(var/atom/movable/movable_content as anything in current.contents)
		if(ismob(movable_content) || istype(movable_content, /obj/effect))
			continue
		if(movable_content.density)
			return TRUE
	return FALSE

/proc/formula_magic_area_turf_blocks(turf/T)
	if(!T)
		return TRUE
	if(T.density)
		return TRUE
	if(T.is_blocked_turf(TRUE))
		return TRUE
	return FALSE

/proc/formula_magic_area_turf_reachable(turf/center, turf/target)
	if(!center || !target)
		return FALSE
	if(center == target)
		return TRUE
	var/turf/previous = center
	for(var/turf/T in getline(center, target))
		if(T == center)
			continue
		if(T == target)
			return TRUE
		if(formula_magic_area_turf_blocks(T))
			return FALSE
		if(previous && previous != center && previous.LinkBlockedWithAccess(T, null))
			return FALSE
		previous = T
	return TRUE

/proc/formula_magic_apply_beam_turf(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/target, power, list/hit)
	if(!caster || !part || !target)
		return FALSE
	new /obj/effect/temp_visual/spell_impact(target, part.impact_color, SPELL_IMPACT_LOW)
	for(var/mob/living/L in target)
		if(L in hit)
			continue
		hit |= L
		formula_magic_apply_part_payload_hit(L, caster, part, max(1, power), target)
	return TRUE

/proc/formula_magic_apply_part_payload_hit(mob/living/target, mob/living/carbon/human/caster, datum/formula_magic_part/part, amount, turf/center)
	if(!target || !part)
		return FALSE
	var/applied = formula_magic_apply_payload_hit(target, caster, amount, part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor)
	formula_magic_apply_payload_tags(target, caster, part.tags, amount, center || get_turf(target), part.duration)
	return applied

/proc/formula_magic_apply_part_turf_payload(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/target, amount)
	if(!part || !target)
		return FALSE
	return formula_magic_apply_payload_turf_tags(caster, part.tags, target, amount, part.impact_color, part.duration)

/proc/formula_magic_apply_payload_turf_tags(mob/living/carbon/human/caster, list/tags, turf/target, amount, impact_color = "#B96DFF", duration = 0)
	if(!target || !length(tags))
		return FALSE
	if(tags["cleanse"])
		formula_magic_cleanse_turf(target)
	if(tags["extinguish"])
		formula_magic_extinguish_turf(target)
	if(tags["ignite"])
		new /obj/effect/temp_visual/fire(target)
		target.fire_act()
	else if(tags["damage_burn"])
		new /obj/effect/temp_visual/spell_impact(target, "#FF5A1F", SPELL_IMPACT_LOW)
	if(tags["damage_cold"] || tags["frost_stack"])
		new /obj/effect/temp_visual/snap_freeze(target)
	if(tags["damage_shock"] || tags["electrocute"])
		new /obj/effect/temp_visual/lightning(target)
	if(tags["dirt"])
		var/obj/effect/formula_magic_dirt/dirt = locate(/obj/effect/formula_magic_dirt) in target
		if(!dirt)
			dirt = new(target)
		dirt.setup_formula_dirt(max(10 SECONDS, duration || 30 SECONDS), tags["dirt"])
	if(tags["blade_field"])
		var/obj/effect/formula_magic_blade_field/blade = locate(/obj/effect/formula_magic_blade_field) in target
		if(!blade)
			new /obj/effect/formula_magic_blade_field(target, caster, max(1, round((amount || 1) * 0.35)), max(10 SECONDS, duration || 10 SECONDS))
	if(tags["creation"])
		var/obj/structure/flora/roguegrass/maneater/existing_maneater = locate(/obj/structure/flora/roguegrass/maneater) in target
		if(!existing_maneater)
			var/obj/structure/flora/roguegrass/maneater/real/juvenile/maneater = new(target)
			maneater.planter = caster
			QDEL_IN(maneater, max(10 SECONDS, tags["creation"] * 10 SECONDS))
	if(tags["repair"])
		formula_magic_repair_atoms(target, amount)
	return TRUE

/proc/formula_magic_apply_payload_hit(mob/living/target, mob/living/carbon/human/caster, amount, damage_type = BRUTE, damage_flag = "blunt", woundclass = BCLASS_BLUNT, intdamfactor = BLUNT_DEFAULT_INT_DAMAGEFACTOR)
	if(!target || amount <= 0)
		return FALSE
	var/datum/status_effect/buff/formula_magic_aura/aura = target.has_status_effect(/datum/status_effect/buff/formula_magic_aura)
	if(aura)
		amount = aura.modify_formula_damage(amount, damage_type, damage_flag)
		if(amount <= 0)
			new /obj/effect/temp_visual/spell_impact(get_turf(target), "#9FCBFF", SPELL_IMPACT_LOW)
			return FALSE
	var/def_zone = caster?.zone_selected || BODY_ZONE_CHEST
	var/armor = target.run_armor_check(def_zone, damage_flag || "blunt", "", "", armor_penetration = PEN_NONE, damage = amount, blade_dulling = woundclass || BCLASS_BLUNT, intdamfactor = intdamfactor || BLUNT_DEFAULT_INT_DAMAGEFACTOR)
	return target.apply_damage(amount, damage_type || BRUTE, def_zone, armor)

/proc/formula_magic_apply_payload_tags(mob/living/target, mob/living/carbon/human/caster, list/tags, amount, turf/center, duration)
	if(!target || !length(tags))
		return FALSE
	if(tags["ignite"])
		target.adjust_fire_stacks(max(1, tags["ignite"] || 1))
		target.ignite_mob()
	if(tags["frost_stack"])
		apply_frost_stack(target, max(1, tags["frost_stack"] || 1))
	if(tags["extinguish"] && target.on_fire)
		target.adjust_fire_stacks(-max(1, tags["extinguish"] || 1))
	if(tags["electrocute"])
		target.electrocute_act(max(1, round((amount || 1) * 0.35)), caster, 1, SHOCK_NOSTUN)
	if(tags["dirt"] || tags["slow"])
		target.Slowdown(3 + ((max(tags["dirt"] || 0, tags["slow"] || 0, 1) - 1) * 3))
	if(tags["anchor_target"])
		target.apply_status_effect(STATUS_EFFECT_IMMOBILIZED, max(1 SECONDS, tags["anchor_target"] * 2 SECONDS))
	if(tags["gravity"])
		target.Knockdown(max(1 SECONDS, tags["gravity"] * 2 SECONDS))
	if(tags["push"] && center)
		var/push_dir = get_dir(center, target) || get_dir(caster, target)
		var/push_distance = max(1, min(8, tags["push"] + round((amount || 1) / 25)))
		var/turf/push_target = get_ranged_target_turf(target, push_dir, push_distance)
		if(push_target)
			target.safe_throw_at(push_target, push_distance, 1, caster, force = MOVE_FORCE_STRONG)
	if(tags["pull"] && center)
		target.safe_throw_at(center, max(1, min(5, tags["pull"] + 1)), 1, caster, force = MOVE_FORCE_STRONG)
	if(tags["silence"])
		target.apply_status_effect(/datum/status_effect/silenced, max(3 SECONDS, min(20 SECONDS, (amount || 1))))
	if(tags["curse_blindness"])
		target.apply_status_effect(STATUS_EFFECT_BLINDED)
	if(tags["mind"] && target != caster)
		target.confused = max(target.confused, max(1, tags["mind"]) * 2 SECONDS)
		target.do_jitter_animation(3)
	if(tags["darkvision"] && target == caster)
		target.apply_status_effect(/datum/status_effect/buff/darkvision)
	if(tags["nondetection"] && target == caster)
		target.apply_status_effect(/datum/status_effect/buff/formula_magic_nondetection, max(10 SECONDS, duration || 30 SECONDS))
	if(tags["softfall"] && target == caster)
		target.apply_status_effect(/datum/status_effect/buff/featherfall)
	var/list/stat_bonuses = formula_magic_stat_bonuses_from_tags(tags)
	if(length(stat_bonuses) && target == caster)
		target.apply_status_effect(/datum/status_effect/buff/formula_magic_stat_aura, stat_bonuses, max(10 SECONDS, duration || 30 SECONDS))
	var/list/stat_debuffs = formula_magic_stat_debuffs_from_tags(tags)
	if(length(stat_debuffs) && target != caster)
		target.apply_status_effect(/datum/status_effect/debuff/formula_magic_stat_curse, stat_debuffs, max(10 SECONDS, min(60 SECONDS, (amount || 1) * 2)))
	if(tags["metal"])
		formula_magic_apply_iron_armor_damage(target, 15 * max(1, tags["metal"] || 1), caster?.zone_selected || BODY_ZONE_CHEST)
	if(tags["repair"])
		formula_magic_repair_living(target, amount)
	if(tags["temporal_restore"])
		formula_magic_repair_living(target, max(amount || 1, 30))
	if(tags["time"] && !tags["temporal_restore"] && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.add_stress(/datum/stressevent/formula_magic_temporal_stress)
	return TRUE

/proc/formula_magic_stat_bonuses_from_tags(list/tags)
	var/list/stat_bonuses = list()
	if(tags["buff_strength"])
		stat_bonuses[STATKEY_STR] = tags["buff_strength"]
	if(tags["buff_speed"])
		stat_bonuses[STATKEY_SPD] = tags["buff_speed"]
	if(tags["buff_perception"])
		stat_bonuses[STATKEY_PER] = tags["buff_perception"]
	if(tags["buff_intelligence"])
		stat_bonuses[STATKEY_INT] = tags["buff_intelligence"]
	if(tags["buff_constitution"])
		stat_bonuses[STATKEY_CON] = tags["buff_constitution"]
	if(tags["buff_willpower"])
		stat_bonuses[STATKEY_WIL] = tags["buff_willpower"]
	return stat_bonuses

/proc/formula_magic_stat_debuffs_from_tags(list/tags)
	var/list/stat_debuffs = list()
	if(tags["debuff_strength"])
		stat_debuffs[STATKEY_STR] = -tags["debuff_strength"]
	if(tags["debuff_speed"])
		stat_debuffs[STATKEY_SPD] = -tags["debuff_speed"]
	if(tags["debuff_perception"])
		stat_debuffs[STATKEY_PER] = -tags["debuff_perception"]
	if(tags["debuff_intelligence"])
		stat_debuffs[STATKEY_INT] = -tags["debuff_intelligence"]
	if(tags["debuff_constitution"])
		stat_debuffs[STATKEY_CON] = -tags["debuff_constitution"]
	if(tags["debuff_willpower"])
		stat_debuffs[STATKEY_WIL] = -tags["debuff_willpower"]
	return stat_debuffs

/proc/formula_magic_apply_iron_armor_damage(mob/living/target, amount, zone = BODY_ZONE_CHEST)
	if(!target || amount <= 0)
		return FALSE
	if(!ishuman(target))
		target.apply_damage(amount, BRUTE)
		return TRUE
	var/mob/living/carbon/human/human_target = target
	var/list/layers = human_target.get_best_worn_armor_layered(zone || BODY_ZONE_CHEST, "blunt")
	var/damaged_layer = FALSE
	for(var/obj/item/clothing/armor_piece as anything in layers)
		if(QDELETED(armor_piece) || !armor_piece.max_integrity || armor_piece.obj_integrity <= 0)
			continue
		armor_piece.take_damage(amount, BRUTE, "blunt", sound_effect = FALSE, armor_penetration = 100)
		damaged_layer = TRUE
	if(!damaged_layer)
		human_target.apply_damage(amount, BRUTE, zone || BODY_ZONE_CHEST)
	return TRUE

/proc/formula_magic_repair_living(mob/living/target, amount)
	if(!target || amount <= 0)
		return FALSE
	target.adjustBruteLoss(-max(1, round(amount * 0.35)))
	target.adjustFireLoss(-max(1, round(amount * 0.25)))
	return TRUE

/proc/formula_magic_cleanse_turf(turf/target)
	if(!target)
		return FALSE
	wash_atom(target, CLEAN_MEDIUM)
	for(var/atom/A in target)
		if(istype(A, /obj/effect/decal/cleanable) || ismob(A) || (isobj(A) && !istype(A, /obj/effect)))
			wash_atom(A, CLEAN_MEDIUM)
	return TRUE

/proc/formula_magic_extinguish_turf(turf/target)
	if(!target)
		return FALSE
	for(var/obj/O in target)
		O.extinguish()
	for(var/mob/living/L in target)
		L.extinguish_mob()
	var/obj/effect/hotspot/hotspot = locate(/obj/effect/hotspot) in target
	if(hotspot)
		new /obj/effect/temp_visual/small_smoke(target)
		qdel(hotspot)
	return TRUE

/proc/formula_magic_repair_atoms(turf/target, amount)
	if(!target || amount <= 0)
		return FALSE
	var/repaired = FALSE
	for(var/obj/O in target)
		if(!O.max_integrity || O.obj_integrity >= O.max_integrity)
			continue
		O.obj_integrity = min(O.max_integrity, O.obj_integrity + max(5, round(amount * 0.5)))
		if(O.obj_broken && O.obj_integrity >= O.max_integrity)
			O.obj_fix()
		repaired = TRUE
	for(var/mob/living/L in target)
		if(!HAS_TRAIT(L, TRAIT_IRONMAN))
			continue
		formula_magic_repair_living(L, amount)
		repaired = TRUE
	return repaired

/proc/formula_magic_apply_orb_impact(mob/living/carbon/human/caster, turf/impact, atom/direct_target, power, radius, damage_type = BRUTE, damage_flag = "blunt", woundclass = BCLASS_BLUNT, intdamfactor = BLUNT_DEFAULT_INT_DAMAGEFACTOR, impact_color = "#B96DFF", list/payload_tags)
	if(!impact)
		return FALSE
	var/effective_radius = max(0, min(radius || 0, 8))
	if(!effective_radius)
		return TRUE
	for(var/turf/T as anything in formula_magic_area_turfs_for_shape(impact, effective_radius, FORMULA_FORM_ORB))
		if(!formula_magic_area_turf_reachable(impact, T))
			continue
		new /obj/effect/temp_visual/spell_impact(T, impact_color || "#B96DFF", SPELL_IMPACT_LOW)
		formula_magic_apply_payload_turf_tags(caster, payload_tags, T, max(1, power || 1), impact_color)
		for(var/mob/living/L in T)
			if(L == caster)
				continue
			formula_magic_apply_payload_hit(L, caster, max(1, power || 1), damage_type, damage_flag, woundclass, intdamfactor)
			formula_magic_apply_payload_tags(L, caster, payload_tags, max(1, power || 1), impact, 0)
	return TRUE

/proc/formula_magic_impact_turfs(turf/impact, radius)
	var/list/result = list()
	if(!impact)
		return result
	var/effective_radius = max(0, min(radius || 0, 8))
	for(var/turf/T as anything in formula_magic_area_turfs_for_shape(impact, effective_radius, FORMULA_FORM_ORB))
		if(!formula_magic_area_turf_reachable(impact, T))
			continue
		result += T
	return result
