/datum/mind/proc/perform_formula_magic_cast(mob/living/carbon/human/caster, list/word_ids, atom/cast_on, speak_words = TRUE, atom/guidance_start)
	if(!caster || !length(word_ids))
		return FALSE
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(word_ids)
	if(!formula || !formula.can_resolve())
		to_chat(caster, span_warning("The formula refuses to resolve."))
		qdel(formula)
		return FALSE

	if(speak_words)
		var/arcane_rank = caster.get_skill_level(/datum/skill/magic/arcane)
		var/word_index = 1
		for(var/word_id in word_ids)
			var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
			if(!word)
				qdel(formula)
				return FALSE
			caster.say(word.get_phrase(), forced = "spell", language = /datum/language/common)
			caster.stamina_add(max(1, word.mana_cost * 3))
			var/speak_delay = max(2, (formula.word_cast_times[word_index] || word.cast_time) - arcane_rank)
			word_index++
			if(!do_after(caster, speak_delay, target = caster))
				to_chat(caster, span_warning("My formula breaks apart before it can resolve."))
				qdel(formula)
				return FALSE

	resolve_formula_magic_effect(caster, formula, cast_on, guidance_start)
	qdel(formula)
	return TRUE

/proc/resolve_formula_magic_effect(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, atom/cast_on, atom/guidance_start)
	if(!caster || !formula)
		return FALSE

	var/turf/source = get_turf(caster)
	var/turf/target = get_turf(cast_on)
	if(!target)
		target = get_ranged_target_turf(caster, caster.dir, max(1, min(formula.range, 12)))
	if(!target)
		target = get_step(source, caster.dir)
	if(!target)
		target = source

	if(formula.tags["unstable_opposition"])
		caster.visible_message(span_danger("[caster]'s opposed formula detonates in their hands!"), span_userdanger("The opposed formula detonates through me!"))
		caster.adjustBruteLoss(max(10, formula.power))
		caster.safe_throw_at(get_ranged_target_turf(caster, turn(caster.dir, 180), 3), 3, 1, caster, force = MOVE_FORCE_STRONG)
		return FALSE

	var/resolved_any = FALSE
	var/list/resolved_forms = list()
	for(var/form_id in formula.forms)
		if(form_id in resolved_forms)
			continue
		if(form_id == FORMULA_FORM_RUNE && (FORMULA_FORM_NOVA in formula.forms))
			continue
		resolved_forms += form_id
		if(resolve_formula_magic_single_form(caster, formula, form_id, target, guidance_start))
			resolved_any = TRUE

	if(resolved_any)
		return TRUE

	resolve_formula_magic_area_effect(caster, formula.get_summary(), target)
	return TRUE

/proc/resolve_formula_magic_single_form(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, form_id, turf/target, atom/guidance_start)
	if(!caster || !formula || !form_id)
		return FALSE
	var/turf/source = get_turf(caster)
	switch(form_id)
		if(FORMULA_FORM_ORB)
			return resolve_formula_magic_projectile(caster, formula, target)
		if(FORMULA_FORM_AURA)
			return resolve_formula_magic_aura(caster, formula)
		if(FORMULA_FORM_CLOAK)
			return resolve_formula_magic_cloak(caster, formula)
		if(FORMULA_FORM_NOVA)
			if(formula.tags["trap"])
				return resolve_formula_magic_rune(caster, formula, target)
			var/list/nova_summary = formula.get_summary()
			nova_summary["skip_center_visual"] = TRUE
			return resolve_formula_magic_area_effect(caster, nova_summary, source)
		if(FORMULA_FORM_WAVE)
			return resolve_formula_magic_wave(caster, formula, target)
		if(FORMULA_FORM_BREATH)
			return resolve_formula_magic_breath(caster, formula, target)
		if(FORMULA_FORM_TOUCH)
			var/turf/touch_target = get_step(source, get_dir(source, target) || caster.dir)
			return resolve_formula_magic_area_effect(caster, formula.get_summary(), touch_target)
		if(FORMULA_FORM_INSTANT)
			if(formula.tags["teleport"])
				do_teleport(caster, target, channel = TELEPORT_CHANNEL_MAGIC)
				playsound(source, 'sound/magic/blink.ogg', 60, TRUE)
				resolve_formula_magic_departure_effect(caster, formula, source)
				caster.visible_message(span_notice("[caster] folds through space."), span_notice("I step through the formula."))
				return TRUE
		if(FORMULA_FORM_FALL)
			return resolve_formula_magic_meteor(caster, formula, target)
		if(FORMULA_FORM_RUNE)
			return resolve_formula_magic_rune(caster, formula, target)
		if(FORMULA_FORM_GUIDANCE)
			var/turf/line_start = get_turf(guidance_start)
			if(!line_start)
				line_start = source
			return resolve_formula_magic_guidance(caster, formula, line_start, target)
		if(FORMULA_FORM_SUMMON)
			return resolve_formula_magic_summon(caster, formula, target)
	return FALSE

/proc/resolve_formula_magic_departure_effect(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/source)
	if(!caster || !formula || !source)
		return FALSE
	var/list/summary = formula.get_summary()
	var/list/source_tags = summary["tags"] || list()
	var/list/tags = source_tags.Copy()
	tags -= "teleport"
	tags -= "self"
	tags -= "persistent"
	if(!formula_magic_has_pulse_payload(tags) && !tags["metal"] && !tags["weapon"] && !tags["cut"] && !tags["repair"])
		return FALSE
	summary["tags"] = tags
	summary["radius"] = max(0, min(summary["radius"] || 0, 2))
	if(tags["metal"] && !tags["damage_blunt"] && !tags["damage_force"])
		tags["damage_blunt"] = 1
	if(tags["cut"] || tags["weapon"])
		tags["fragments"] = max(tags["fragments"] || 0, 1)
	new /obj/effect/temp_visual/formula_magic_zone(source, formula_magic_color_for_summary(summary), "formula_rune", 12)
	resolve_formula_magic_area_effect(caster, summary, source, list(caster))
	return TRUE

/proc/resolve_formula_magic_wave(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, atom/target)
	if(!caster || !formula || !target)
		return FALSE
	var/turf/source = get_turf(caster)
	var/turf/target_turf = get_ranged_target_turf_direct(caster, target, max(1, min(formula.range, 12)), 0)
	if(!source || !target_turf)
		return FALSE
	var/wave_dir = get_dir(source, target_turf) || caster.dir
	var/list/turfs = getline(caster, target_turf) - source
	playsound(caster.loc, 'sound/magic/fireball.ogg', 80, TRUE)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(progressive_formula_magic_wave), caster, formula.get_summary(), turfs, wave_dir, max(0, formula.radius || 0))
	return TRUE

/proc/formula_magic_wave_step_turfs(turf/base_turf, movement_dir, width)
	var/list/result = list()
	if(!base_turf)
		return result
	var/left_dir = turn(movement_dir, 90)
	var/right_dir = turn(movement_dir, -90)
	result |= base_turf
	for(var/offset in 1 to width)
		var/turf/left = base_turf
		var/turf/right = base_turf
		for(var/i in 1 to offset)
			if(left)
				left = get_step(left, left_dir)
			if(right)
				right = get_step(right, right_dir)
		if(left)
			result |= left
		if(right)
			result |= right
	return result

/proc/progressive_formula_magic_wave(mob/living/carbon/human/caster, list/summary, list/base_turfs, movement_dir, width)
	var/list/hit_list = list(caster)
	for(var/turf/base_turf in base_turfs)
		if(!base_turf || base_turf.is_blocked_turf(exclude_mobs = TRUE))
			return
		var/list/step_turfs = formula_magic_wave_step_turfs(base_turf, movement_dir, width)
		for(var/turf/T in step_turfs)
			if(!T || T.is_blocked_turf(exclude_mobs = TRUE))
				continue
			resolve_formula_magic_area_effect(caster, summary, T, hit_list)
		sleep(5)

/proc/resolve_formula_magic_breath(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, atom/target)
	if(!caster || !formula)
		return FALSE
	var/turf/source = get_turf(caster)
	if(!source)
		return FALSE
	playsound(caster.loc, 'sound/magic/fireball.ogg', 80, TRUE)
	var/list/summary = formula.get_summary()
	var/list/breath_summary = formula_magic_summary_with_radius(summary, 0)
	breath_summary["power"] = max(1, round((breath_summary["power"] || 10) * 0.4))
	breath_summary["formula_stack_chance"] = 40
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(progressive_formula_magic_dragon_breath), caster, breath_summary, max(1, min(formula.range, 8)))
	return TRUE

/proc/progressive_formula_magic_dragon_breath(mob/living/carbon/human/caster, list/summary, breath_range)
	if(!caster || !summary)
		return FALSE
	var/duration = 3 SECONDS
	var/interval = 2
	var/max_ticks = duration / interval
	for(var/i in 1 to max_ticks)
		if(!caster || QDELETED(caster) || caster.stat || caster.incapacitated())
			break
		var/current_dir = caster.dir
		var/turf/user_turf = get_turf(caster)
		if(!user_turf)
			break
		var/user_angle = dir2angle(current_dir)
		for(var/p in 1 to 6)
			new /obj/effect/temp_visual/formula_magic_dragon_fire_particle(user_turf, current_dir, formula_magic_color_for_summary(summary))
		playsound(user_turf, 'sound/items/firelight.ogg', 40, TRUE)
		var/list/shared_hit_list = list(caster)
		for(var/turf/T in view(breath_range, user_turf))
			var/dist = get_dist(user_turf, T)
			if(dist == 0)
				continue
			var/target_angle = Get_Angle(user_turf, T)
			var/angle_diff = abs(closer_angle_difference(user_angle, target_angle))
			if(angle_diff <= 30)
				resolve_formula_magic_area_effect(caster, summary, T, shared_hit_list)
		sleep(interval)
	return TRUE

/proc/resolve_formula_magic_rune(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target)
	if(!caster || !formula || !target)
		return FALSE
	var/rune_limit = formula_magic_rune_limit(caster)
	var/current_runes = formula_magic_active_rune_count(caster)
	if(current_runes >= rune_limit)
		to_chat(caster, span_warning("I cannot hold more than [rune_limit] active formula runes."))
		return FALSE
	var/list/rune_targets = formula_magic_rune_targets(caster, formula, target)
	if(!length(rune_targets))
		return FALSE
	var/runes_created = 0
	var/list/summary = formula.get_summary()
	var/rune_duration = max(60 SECONDS, formula.duration || 60 SECONDS)
	for(var/turf/T in rune_targets)
		if(!T || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		if(current_runes + runes_created >= rune_limit)
			break
		var/blocked_by_rune = FALSE
		for(var/obj/structure/trap/formula_magic/existing in T)
			blocked_by_rune = TRUE
			break
		if(blocked_by_rune)
			continue
		var/obj/structure/trap/formula_magic/rune = new(T)
		rune.setup_formula_rune(caster, summary, rune_duration)
		runes_created++
	if(!runes_created)
		to_chat(caster, span_warning("There is no room for the formula rune."))
		return FALSE
	caster.visible_message(span_notice("[caster] inscribes [runes_created] dormant formula rune[runes_created == 1 ? "" : "s"] into the ground."))
	return TRUE

/proc/formula_magic_rune_limit(mob/living/carbon/human/caster)
	if(!caster)
		return 0
	return max(0, caster.get_skill_level(/datum/skill/magic/arcane) * 5)

/proc/formula_magic_active_rune_count(mob/living/carbon/human/caster)
	if(!caster?.mind)
		return 0
	var/count = 0
	for(var/obj/structure/trap/formula_magic/rune in world)
		if(rune.caster?.mind == caster.mind)
			count++
	return count

/proc/formula_magic_rune_targets(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target)
	var/list/result = list()
	if(!caster || !formula)
		return result
	var/nova_words = 0
	for(var/form_id in formula.forms)
		if(form_id == FORMULA_FORM_NOVA)
			nova_words++
	if(nova_words <= 0)
		if(target)
			result += target
		return result
	var/turf/center = get_turf(caster)
	if(!center)
		return result
	result += center
	if(nova_words <= 1)
		return result
	var/ring_distance = max(1, round(nova_words / 2))
	var/list/ring_dirs = (nova_words % 2) ? GLOB.diagonals : GLOB.cardinals
	for(var/rune_dir in ring_dirs)
		var/turf/T = center
		for(var/i in 1 to ring_distance)
			if(T)
				T = get_step(T, rune_dir)
		if(T)
			result |= T
	return result

/proc/resolve_formula_magic_meteor(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target)
	if(!caster || !formula || !target)
		return FALSE
	var/list/summary = formula.get_summary()
	var/fall_delay = max(1 SECONDS, summary["delay"] || 5 SECONDS)
	start_formula_magic_meteor(caster, summary, target, fall_delay)
	caster.visible_message(span_warning("A formula meteor gathers above [target]."))
	return TRUE

/proc/start_formula_magic_meteor(mob/living/carbon/human/caster, list/summary, turf/target, fall_delay)
	if(!target || !summary)
		return FALSE
	new /obj/effect/temp_visual/formula_magic_meteor(target, formula_magic_color_for_summary(summary), fall_delay)
	addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(resolve_formula_magic_meteor_impact), caster, summary, target, fall_delay), fall_delay)
	return TRUE

/proc/resolve_formula_magic_meteor_impact(mob/living/carbon/human/caster, list/summary, turf/target, fall_delay)
	if(!target || !summary)
		return FALSE
	var/list/tags = summary["tags"] || list()
	var/list/impact_summary = formula_magic_secondary_summary(summary)
	resolve_formula_magic_area_effect(caster, impact_summary, target)
	if(tags["ricochet"])
		resolve_formula_magic_meteor_ricochet(caster, impact_summary, target, tags["ricochet"], fall_delay)
	if(tags["chain"])
		resolve_formula_magic_meteor_chain(caster, impact_summary, target, tags["chain"], fall_delay)
	return TRUE

/proc/resolve_formula_magic_meteor_ricochet(mob/living/carbon/human/caster, list/summary, turf/source, ricochet_count, fall_delay)
	var/remaining = max(0, ricochet_count || 0)
	var/turf/current = source
	while(remaining > 0)
		var/list/possible_turfs = list()
		for(var/turf/T in range(2, current))
			if(T == current || T.is_blocked_turf(exclude_mobs = TRUE))
				continue
			possible_turfs += T
		if(!length(possible_turfs))
			return
		current = pick(possible_turfs)
		addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(start_formula_magic_meteor), caster, summary, current, fall_delay), 1 SECONDS)
		remaining--

/proc/resolve_formula_magic_meteor_chain(mob/living/carbon/human/caster, list/summary, turf/source, chain_count, fall_delay)
	var/remaining = max(0, chain_count || 0)
	var/turf/current = source
	var/list/hit_targets = list()
	while(remaining > 0)
		var/mob/living/next_target
		var/best_distance = 999
		for(var/mob/living/L in view(7, current))
			if(L == caster || (L in hit_targets))
				continue
			var/distance = get_dist(current, L)
			if(distance < best_distance)
				best_distance = distance
				next_target = L
		if(!next_target)
			return
		hit_targets |= next_target
		current = get_turf(next_target)
		if(current)
			addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(start_formula_magic_meteor), caster, summary, current, fall_delay), 1 SECONDS)
		remaining--

/proc/resolve_formula_magic_guidance(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/start, turf/end)
	if(!caster || !formula || !start || !end)
		return FALSE
	var/list/summary = formula.get_summary()
	var/list/line_summary = formula_magic_summary_with_radius(summary, 0)
	var/list/hit_list = list(caster)
	var/max_distance = max(1, summary["range"] || 3)
	if(get_dist(start, end) > max_distance)
		var/turf/limited_end = get_ranged_target_turf(start, get_dir(start, end), max_distance)
		if(limited_end)
			end = limited_end
	new /obj/effect/temp_visual/formula_magic_zone(start, formula_magic_color_for_summary(summary), "formula_guidance", 12)
	new /obj/effect/temp_visual/formula_magic_zone(end, formula_magic_color_for_summary(summary), "formula_guidance", 12)
	for(var/turf/T in getline(start, end))
		if(!T || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		new /obj/effect/temp_visual/formula_magic_zone(T, formula_magic_color_for_summary(summary), "formula_guidance", 6)
		resolve_formula_magic_area_effect(caster, line_summary, T, hit_list)
		sleep(1)
	return TRUE

/proc/resolve_formula_magic_aura(mob/living/carbon/human/caster, datum/formula_magic_formula/formula)
	if(!caster || !formula)
		return FALSE
	var/list/tags = formula.tags || list()
	var/duration = max(30, formula.duration || 30)
	var/list/stat_bonuses = formula_magic_stat_bonuses_from_tags(tags)
	if(length(stat_bonuses))
		caster.apply_status_effect(/datum/status_effect/buff/formula_magic_stat_aura, stat_bonuses, duration)
	if(tags["darkvision"])
		caster.apply_status_effect(/datum/status_effect/buff/darkvision)
	if(tags["softfall"])
		for(var/mob/living/L in range(max(1, formula.radius || 1), caster))
			L.apply_status_effect(/datum/status_effect/buff/featherfall)
	if(tags["nondetection"])
		caster.add_filter("formula_nondetection", 2, list("type" = "outline", "color" = "#2F80FF", "alpha" = 25, "size" = 1))
		addtimer(CALLBACK(caster, TYPE_PROC_REF(/atom/movable, remove_filter), "formula_nondetection"), duration)
	var/list/resists = list()
	if(tags["damage_burn"])
		resists["fire"] = min(0.9, 0.1 * tags["damage_burn"])
	if(tags["damage_cold"])
		resists["cold"] = min(0.9, 0.1 * tags["damage_cold"])
	if(tags["damage_shock"])
		resists["shock"] = min(0.9, 0.1 * tags["damage_shock"])
	if(tags["damage_blunt"] || tags["damage_force"])
		resists["physical"] = min(0.9, 0.1 * max(tags["damage_blunt"] || 0, tags["damage_force"] || 0))
	if(length(resists))
		caster.apply_status_effect(/datum/status_effect/buff/formula_magic_elemental_aura, resists, duration)
	new /obj/effect/temp_visual/spell_impact(get_turf(caster), formula_magic_color_for_summary(formula.get_summary()), SPELL_IMPACT_MEDIUM)
	caster.visible_message(span_notice("[caster] is wrapped in a formula aura."))
	return TRUE

/proc/resolve_formula_magic_cloak(mob/living/carbon/human/caster, datum/formula_magic_formula/formula)
	if(!caster || !formula)
		return FALSE
	var/duration = max(30, formula.duration || 30)
	var/list/cloak_summary = formula.get_summary()
	cloak_summary["radius"] = max(1, formula.radius || 1)
	cloak_summary["power"] = max(1, round((cloak_summary["power"] || 10) * 0.1))
	cloak_summary["formula_stack_chance"] = 10
	var/list/source_cloak_tags = cloak_summary["tags"] || list()
	var/list/cloak_tags = source_cloak_tags.Copy()
	cloak_tags -= "self"
	cloak_tags -= "persistent"
	cloak_tags -= "cloak"
	cloak_tags -= "buff"
	cloak_tags -= "chain"
	cloak_tags -= "ricochet"
	if(!formula_magic_has_pulse_payload(cloak_tags))
		to_chat(caster, span_warning("The formula cloak has no aggressive payload."))
		return FALSE
	cloak_summary["tags"] = cloak_tags
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_cloak_loop), caster, cloak_summary, duration)
	new /obj/effect/temp_visual/spell_impact(get_turf(caster), formula_magic_color_for_summary(cloak_summary), SPELL_IMPACT_MEDIUM)
	caster.visible_message(span_warning("[caster] is wrapped in a hostile formula cloak."))
	return TRUE

/proc/formula_magic_has_pulse_payload(list/tags)
	if(!length(tags))
		return FALSE
	if(tags["damage_arcane"] || tags["damage_burn"] || tags["ignite"] || tags["damage_cold"] || tags["frost_stack"] || tags["damage_shock"] || tags["electrocute"] || tags["damage_blunt"] || tags["damage_force"] || tags["fragments"] || tags["push"] || tags["pull"] || tags["gravity"] || tags["shift_target"] || tags["anchor_target"] || tags["silence"] || tags["stumble"] || tags["repair"] || tags["mind"])
		return TRUE
	return FALSE

/proc/formula_magic_cloak_loop(mob/living/carbon/human/caster, list/summary, duration)
	var/end_time = world.time + max(1, duration || 30 SECONDS)
	while(caster && !QDELETED(caster) && world.time < end_time)
		var/turf/center = get_turf(caster)
		if(!center)
			return
		resolve_formula_magic_area_effect(caster, summary, center, list(caster))
		sleep(2 SECONDS)

/proc/resolve_formula_magic_projectile(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, atom/target)
	if(!caster || !formula)
		return FALSE
	var/projectiles_to_fire = max(1, formula.projectile_count || 1)
	var/spread_step = projectiles_to_fire > 1 ? 12 : 0
	var/start_spread = -round((projectiles_to_fire - 1) * spread_step / 2)
	for(var/i in 1 to projectiles_to_fire)
		var/obj/projectile/magic/formula_magic_bolt/bolt = new(get_turf(caster))
		bolt.firer = caster
		bolt.fired_from = get_turf(caster)
		bolt.def_zone = caster.zone_selected
		bolt.formula_summary = formula.get_summary()
		bolt.range = max(1, min(formula.range, 14))
		bolt.max_range = bolt.range
		bolt.pierce_remaining = formula.tags["pierce"] || 0
		bolt.spell_impact_color = formula_magic_color_for_summary(bolt.formula_summary)
		bolt.light_color = bolt.spell_impact_color
		if(formula.primary_form == FORMULA_FORM_ORB)
			bolt.icon_state = "formula_orb"
			bolt.speed = 1.1
		else
			bolt.icon_state = "formula_orb"
			bolt.speed = 0.6
		bolt.preparePixelProjectile(target, caster, null, start_spread + ((i - 1) * spread_step))
		bolt.fire()
	return TRUE

/proc/resolve_formula_magic_summon(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target)
	if(!caster || !formula)
		return FALSE
	if(!target)
		target = get_turf(caster)
	if(formula.tags["damage_burn"] || formula.tags["ignite"])
		if(target && !locate(/obj/machinery/light/rogue/campfire/create_campfire) in target)
			new /obj/machinery/light/rogue/campfire/create_campfire(target)
			caster.visible_message(span_notice("[caster] calls a temporary campfire into being."))
			return TRUE
	if(formula.tags["damage_shock"] || formula.tags["electrocute"])
		new /obj/effect/formula_magic_light(target, formula_magic_color_for_summary(formula.get_summary()), max(30 SECONDS, formula.duration || 60 SECONDS))
		caster.visible_message(span_notice("[caster] binds a small formula light."))
		return TRUE
	if(formula.tags["damage_cold"] || formula.tags["frost_stack"])
		new /obj/effect/temp_visual/snap_freeze(target)
		target.visible_message(span_notice("A chill formula settles over [target]."))
		return TRUE
	if(formula.tags["life"])
		var/mob/living/simple_animal/pet/familiar/fae/familiar = new(target)
		familiar.name = "formula familiar"
		QDEL_IN(familiar, max(60 SECONDS, formula.duration || 3 MINUTES))
		caster.visible_message(span_notice("[caster] gives a formula a brief living shape."))
		return TRUE
	if(formula.tags["death"])
		var/mob/living/simple_animal/hostile/rogue/skeleton/guard/bones = new(target, caster)
		QDEL_IN(bones, max(60 SECONDS, formula.duration || 3 MINUTES))
		caster.visible_message(span_warning("[caster] calls bones into a temporary servant."))
		return TRUE
	if((formula.tags["summon"] || 0) > 1)
		var/obj/structure/formula_magic_forge/forge = new(target)
		forge.setup_formula_forge(caster, max(60 SECONDS, formula.duration || 5 MINUTES))
		caster.visible_message(span_notice("[caster] folds a temporary arcyne forge into the air."))
		return TRUE
	if(formula.tags["weapon"] || formula.tags["metal"])
		var/obj/item/rogueweapon/magicbrick/brick = new(caster.drop_location())
		brick.name = formula.tags["cut"] ? "formula blade" : "formula iron"
		brick.desc = "A temporary object shaped from a spoken formula."
		brick.force = max(brick.force, round(formula.power / 2))
		brick.throwforce = max(brick.throwforce, formula.power)
		brick.AddComponent(/datum/component/conjured_item, null, FALSE, caster, null)
		caster.put_in_hands(brick)
		caster.visible_message(span_notice("[caster] shapes a temporary arcyne implement."))
		return TRUE
	caster.visible_message(span_notice("[caster]'s formula coils into being, then fades without a suitable material word."))
	return FALSE

/proc/resolve_formula_magic_area_effect(mob/living/carbon/human/caster, list/summary, turf/center, list/shared_hit_list)
	if(!center || !summary)
		return FALSE
	var/list/tags = summary["tags"] || list()
	var/power = summary["power"] || 10
	var/radius = max(0, summary["radius"] || 0)
	var/effective_radius = min(radius, 16)
	var/effect_color = formula_magic_color_for_summary(summary)
	var/skip_center_visual = summary["skip_center_visual"]

	if(!skip_center_visual)
		new /obj/effect/temp_visual/spell_impact(center, effect_color, SPELL_IMPACT_LOW)
	if(!skip_center_visual && tags["ignite"])
		new /obj/effect/temp_visual/fire(center)
		playsound(center, 'sound/magic/fireball.ogg', 70, TRUE)
	else if(!skip_center_visual && tags["damage_burn"])
		new /obj/effect/temp_visual/spell_impact(center, "#FF5A1F", SPELL_IMPACT_LOW)
	if(!skip_center_visual && (tags["damage_cold"] || tags["frost_stack"]))
		new /obj/effect/temp_visual/snap_freeze(center)
	if(!skip_center_visual && (tags["damage_shock"] || tags["electrocute"]))
		new /obj/effect/temp_visual/lightning(center)
		playsound(center, 'sound/magic/lightning.ogg', 70, TRUE)
	if(!skip_center_visual && tags["damage_arcane"])
		new /obj/effect/temp_visual/spell_impact(center, "#B7B3FF", SPELL_IMPACT_MEDIUM)
	if(!skip_center_visual && tags["gravity"])
		new /obj/effect/temp_visual/gravity(center)

	var/list/hit_targets = list()
	for(var/turf/T in range(effective_radius, center))
		if(T != center)
			new /obj/effect/temp_visual/spell_impact(T, effect_color, SPELL_IMPACT_LOW)
		if(tags["ignite"])
			new /obj/effect/temp_visual/fire(T)
			T.fire_act()
		else if(tags["damage_burn"])
			new /obj/effect/temp_visual/spell_impact(T, "#FF5A1F", SPELL_IMPACT_LOW)
		if(tags["damage_cold"] || tags["frost_stack"])
			new /obj/effect/temp_visual/snap_freeze(T)
		if(tags["damage_arcane"])
			new /obj/effect/temp_visual/spell_impact(T, "#B7B3FF", SPELL_IMPACT_LOW)
		if(tags["gravity"])
			new /obj/effect/temp_visual/gravity(T)

		for(var/mob/living/L in T)
			if(shared_hit_list && (L in shared_hit_list))
				continue
			if(shared_hit_list)
				shared_hit_list |= L
			if(L == caster && !(tags["buff"] || tags["self"]))
				continue
			hit_targets |= L
			if(tags["damage_arcane"])
				formula_magic_apply_damage(L, max(1, round(power * 0.45)), BRUTE)
			if(tags["damage_burn"])
				formula_magic_apply_damage(L, max(1, round(power * 0.6)), BURN)
			if(tags["ignite"])
				if(formula_magic_stack_chance_succeeds(summary))
					L.adjust_fire_stacks(1)
					L.ignite_mob()
			if(tags["damage_cold"] || tags["frost_stack"])
				formula_magic_apply_damage(L, max(1, round(power * 0.35)), BURN)
				if(tags["frost_stack"] && formula_magic_stack_chance_succeeds(summary))
					apply_frost_stack(L)
			if(tags["damage_shock"])
				L.electrocute_act(max(1, round(power * 0.45)), caster, 1, SHOCK_NOSTUN)
			if(tags["electrocute"] && formula_magic_stack_chance_succeeds(summary))
				L.electrocute_act(1, caster, 1, SHOCK_NOSTUN)
			if(tags["anchor_target"] && formula_magic_stack_chance_succeeds(summary))
				L.apply_status_effect(STATUS_EFFECT_IMMOBILIZED, max(1 SECONDS, tags["anchor_target"] * 2 SECONDS))
				new /obj/effect/temp_visual/gravity(get_turf(L))
			if(tags["damage_blunt"] || tags["damage_force"])
				formula_magic_apply_damage(L, max(1, round(power * 0.5)), BRUTE)
			if(tags["fragments"])
				formula_magic_apply_damage(L, max(1, round(power * 0.25)), BRUTE)
			if(tags["push"] && !tags["anchor_target"])
				var/push_dir = get_dir(center, L)
				var/push_distance = formula_magic_push_distance(summary)
				L.safe_throw_at(get_ranged_target_turf(L, push_dir, push_distance), push_distance, 1, caster, force = MOVE_FORCE_STRONG)
			if(tags["pull"] && !tags["anchor_target"])
				L.safe_throw_at(center, 2, 1, caster, force = MOVE_FORCE_STRONG)
			if(tags["gravity"] && formula_magic_stack_chance_succeeds(summary))
				L.Knockdown(2 SECONDS)
			if(tags["shift_target"] && !tags["anchor_target"] && formula_magic_stack_chance_succeeds(summary))
				var/turf/shift_turf = get_ranged_target_turf(L, pick(GLOB.alldirs), 2)
				if(shift_turf)
					do_teleport(L, shift_turf, channel = TELEPORT_CHANNEL_MAGIC)
			if(tags["buff_speed"] && L == caster)
				L.visible_message(span_notice("[L]'s formula quickens their movement for a breath."))
			if(tags["buff_stamina"] && L == caster)
				L.stamina_add(-max(5, power))
			if(tags["darkvision"] && L == caster)
				L.apply_status_effect(/datum/status_effect/buff/darkvision)
			var/list/stat_debuffs = formula_magic_stat_debuffs_from_tags(tags)
			if(length(stat_debuffs) && formula_magic_stack_chance_succeeds(summary))
				L.apply_status_effect(/datum/status_effect/debuff/formula_magic_stat_curse, stat_debuffs, max(10 SECONDS, min(60 SECONDS, power * 2)))
			if(tags["curse_blindness"] && formula_magic_stack_chance_succeeds(summary))
				L.apply_status_effect(STATUS_EFFECT_BLINDED)
			if(tags["silence"] && formula_magic_stack_chance_succeeds(summary))
				L.apply_status_effect(/datum/status_effect/silenced, max(3 SECONDS, min(20 SECONDS, power)))
			if(tags["stumble"] && formula_magic_stack_chance_succeeds(summary))
				L.Knockdown(max(1 SECONDS, min(4 SECONDS, tags["stumble"] SECONDS)))
			if(tags["softfall"])
				L.apply_status_effect(/datum/status_effect/buff/featherfall)
			if(tags["mind"])
				if(tags["self"] || L == caster)
					to_chat(L, span_notice("A formula opens a quiet thread of thought."))
				else
					to_chat(L, span_notice("A brief formula whisper brushes my mind."))
			if(tags["size_down"])
				L.add_filter("formula_size_down", 2, list("type" = "outline", "color" = "#2F80FF", "alpha" = 35, "size" = 1))
				addtimer(CALLBACK(L, TYPE_PROC_REF(/atom/movable, remove_filter), "formula_size_down"), max(10 SECONDS, min(60 SECONDS, power * 2)))
			if(tags["size_up"])
				L.add_filter("formula_size_up", 2, list("type" = "outline", "color" = "#8A8A8A", "alpha" = 40, "size" = 2))
				addtimer(CALLBACK(L, TYPE_PROC_REF(/atom/movable, remove_filter), "formula_size_up"), max(10 SECONDS, min(60 SECONDS, power * 2)))

		if(tags["repair"])
			formula_magic_repair_atoms(caster, T, power)

	if(tags["chain"])
		resolve_formula_magic_chain(caster, summary, center, hit_targets, tags["chain"])
	if(tags["ricochet"])
		resolve_formula_magic_ricochet(caster, summary, center, tags["ricochet"])
	center.visible_message(span_warning("A spoken formula resolves at [center]."))
	return TRUE

/proc/resolve_formula_magic_chain(mob/living/carbon/human/caster, list/summary, turf/source, list/hit_targets, chain_count)
	var/remaining = max(0, chain_count || 0)
	var/turf/current = source
	var/list/chained_summary = formula_magic_secondary_summary(summary)
	while(remaining > 0)
		var/mob/living/next_target
		var/best_distance = 999
		for(var/mob/living/L in view(7, current))
			if(L == caster || (hit_targets && (L in hit_targets)))
				continue
			var/distance = get_dist(current, L)
			if(distance < best_distance)
				best_distance = distance
				next_target = L
		if(!next_target)
			return
		if(hit_targets)
			hit_targets |= next_target
		current = get_turf(next_target)
		resolve_formula_magic_area_effect(caster, chained_summary, current)
		remaining--

/proc/resolve_formula_magic_ricochet(mob/living/carbon/human/caster, list/summary, turf/source, ricochet_count)
	var/remaining = max(0, ricochet_count || 0)
	var/turf/current = source
	var/dir_to_travel = get_dir(get_turf(caster), source) || caster.dir
	var/list/ricochet_summary = formula_magic_secondary_summary(summary)
	while(remaining > 0)
		var/turf/next_turf = get_ranged_target_turf(current, turn(dir_to_travel, pick(-45, 45)), 3)
		if(!next_turf)
			return
		current = next_turf
		resolve_formula_magic_area_effect(caster, ricochet_summary, current)
		remaining--

/proc/formula_magic_secondary_summary(list/summary)
	var/list/result = summary.Copy()
	var/list/source_tags = summary["tags"] || list()
	var/list/tags = source_tags.Copy()
	tags -= "chain"
	tags -= "ricochet"
	result["tags"] = tags
	return result

/proc/formula_magic_summary_with_radius(list/summary, new_radius)
	var/list/result = summary.Copy()
	result["radius"] = max(0, new_radius || 0)
	return result

/proc/formula_magic_color_for_summary(list/summary)
	var/list/tags = summary?["tags"] || list()
	var/list/schools = summary?["schools"] || list()
	if(tags["death"])
		return "#6B6B6B"
	if(FORMULA_SCHOOL_CURSES in schools)
		return "#8A8A8A"
	if(FORMULA_SCHOOL_PYROMANCY in schools)
		return "#FF5A1F"
	if(FORMULA_SCHOOL_CRYOMANCY in schools)
		return "#8FE8FF"
	if(FORMULA_SCHOOL_FULGURMANCY in schools)
		return "#FFFFFF"
	if(FORMULA_SCHOOL_GEOMANCY in schools)
		return "#8B5E34"
	if(FORMULA_SCHOOL_AUGMENTATION in schools)
		return "#2F80FF"
	if(FORMULA_SCHOOL_DISPLACEMENT in schools)
		return "#5B1A8E"
	if(FORMULA_SCHOOL_ARTIFICE_WARDING in schools)
		return "#36B36A"
	if(FORMULA_SCHOOL_LIFE in schools)
		return "#75D86F"
	if(FORMULA_SCHOOL_KINESIS in schools)
		return "#D7A51E"
	if(tags["damage_burn"] || tags["ignite"])
		return "#FF5A1F"
	if(tags["damage_cold"] || tags["frost_stack"])
		return "#8FE8FF"
	if(tags["damage_shock"] || tags["electrocute"])
		return "#FFFFFF"
	if(tags["damage_blunt"] || tags["shrapnel"])
		return "#8B5E34"
	if(tags["push"] || tags["pull"] || tags["gravity"])
		return "#D7A51E"
	if(tags["teleport"] || tags["phase"] || tags["shift_target"] || tags["anchor_target"])
		return "#5B1A8E"
	if(tags["metal"] || tags["weapon"] || tags["armor"])
		return "#36B36A"
	if(tags["curse"] || tags["curse_blindness"])
		return "#8A8A8A"
	if(tags["life"])
		return "#75D86F"
	if(tags["death"])
		return "#6B6B6B"
	return "#C000FF"

/proc/formula_magic_apply_damage(mob/living/target, amount, damagetype)
	if(!target || amount <= 0)
		return
	target.apply_damage(amount, damagetype, forced = TRUE)

/proc/formula_magic_push_distance(list/summary)
	var/power = summary?["power"] || 10
	var/list/tags = summary?["tags"] || list()
	return max(1, min(8, 1 + (tags["push"] || 1) + round(power / 25)))

/proc/formula_magic_stack_chance_succeeds(list/summary)
	var/chance = summary?["formula_stack_chance"]
	if(!isnum(chance))
		return TRUE
	return prob(clamp(chance, 0, 100))

/proc/formula_magic_repair_atoms(mob/living/carbon/human/caster, turf/T, power)
	if(!T)
		return FALSE
	var/repaired = FALSE
	for(var/obj/O in T)
		if(O.obj_integrity >= O.max_integrity)
			continue
		O.obj_integrity = min(O.max_integrity, O.obj_integrity + max(5, round(power * 0.5)))
		if(O.obj_broken && O.obj_integrity >= O.max_integrity)
			O.obj_fix()
		new /obj/effect/temp_visual/spell_impact(get_turf(O), "#36B36A", SPELL_IMPACT_LOW)
		repaired = TRUE
	for(var/mob/living/L in T)
		if(!HAS_TRAIT(L, TRAIT_IRONMAN))
			continue
		L.adjustBruteLoss(-max(1, round(power * 0.25)))
		L.adjustFireLoss(-max(1, round(power * 0.25)))
		new /obj/effect/temp_visual/spell_impact(get_turf(L), "#36B36A", SPELL_IMPACT_LOW)
		repaired = TRUE
	if(repaired && caster)
		playsound(T, 'sound/magic/mending.ogg', 35, TRUE, -2)
	return repaired

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
	if(tags["buff_stamina"])
		stat_bonuses[STATKEY_CON] = (stat_bonuses[STATKEY_CON] || 0) + tags["buff_stamina"]
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

/atom/movable/screen/alert/status_effect/buff/formula_magic_stat_aura
	name = "Formula Aura"
	desc = "A formula reinforces my body."
	icon_state = "buff"

/datum/status_effect/buff/formula_magic_stat_aura
	id = "formula_magic_stat_aura"
	alert_type = /atom/movable/screen/alert/status_effect/buff/formula_magic_stat_aura
	duration = 30 SECONDS

/datum/status_effect/buff/formula_magic_stat_aura/on_creation(mob/living/new_owner, list/stat_bonuses, new_duration)
	if(length(stat_bonuses))
		effectedstats = stat_bonuses.Copy()
	if(new_duration)
		duration = new_duration
	. = ..()

/datum/status_effect/buff/formula_magic_stat_aura/on_apply()
	. = ..()
	owner.add_filter("formula_stat_aura", 2, list("type" = "outline", "color" = "#B7B3FF", "alpha" = 35, "size" = 1))

/datum/status_effect/buff/formula_magic_stat_aura/on_remove()
	. = ..()
	owner.remove_filter("formula_stat_aura")

/atom/movable/screen/alert/status_effect/debuff/formula_magic_stat_curse
	name = "Formula Curse"
	desc = "A formula weakens my body."
	icon_state = "debuff"

/datum/status_effect/debuff/formula_magic_stat_curse
	id = "formula_magic_stat_curse"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/formula_magic_stat_curse
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/debuff/formula_magic_stat_curse/on_creation(mob/living/new_owner, list/stat_debuffs, new_duration)
	if(length(stat_debuffs))
		effectedstats = stat_debuffs.Copy()
	if(new_duration)
		duration = new_duration
	. = ..()

/datum/status_effect/debuff/formula_magic_stat_curse/on_apply()
	. = ..()
	owner.add_filter("formula_stat_curse", 2, list("type" = "outline", "color" = "#8A8A8A", "alpha" = 45, "size" = 1))

/datum/status_effect/debuff/formula_magic_stat_curse/on_remove()
	. = ..()
	owner.remove_filter("formula_stat_curse")

/atom/movable/screen/alert/status_effect/buff/formula_magic_elemental_aura
	name = "Elemental Formula Aura"
	desc = "A formula dampens incoming elemental force."
	icon_state = "buff"

/datum/status_effect/buff/formula_magic_elemental_aura
	id = "formula_magic_elemental_aura"
	alert_type = /atom/movable/screen/alert/status_effect/buff/formula_magic_elemental_aura
	duration = 30 SECONDS
	var/list/resists = list()

/datum/status_effect/buff/formula_magic_elemental_aura/on_creation(mob/living/new_owner, list/new_resists, new_duration)
	if(length(new_resists))
		resists = new_resists.Copy()
	if(new_duration)
		duration = new_duration
	. = ..()

/datum/status_effect/buff/formula_magic_elemental_aura/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(handle_formula_aura_damage))
	owner.add_filter("formula_elemental_aura", 2, list("type" = "outline", "color" = "#8FA6D8", "alpha" = 35, "size" = 1))

/datum/status_effect/buff/formula_magic_elemental_aura/on_remove()
	. = ..()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	owner.remove_filter("formula_elemental_aura")

/datum/status_effect/buff/formula_magic_elemental_aura/proc/handle_formula_aura_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!owner || damage <= 0)
		return
	var/reduction = 0
	if(damagetype == BURN)
		reduction = max(resists["fire"] || 0, resists["cold"] || 0, resists["shock"] || 0)
	if(damagetype == BRUTE)
		reduction = resists["physical"] || 0
	if(reduction <= 0)
		return
	var/adjusted = max(0, round(damage * (1 - reduction)))
	if(adjusted <= 0)
		return COMPONENT_DAMAGE_HANDLED
	if(damagetype == BURN)
		owner.adjustFireLoss(adjusted)
	else if(damagetype == BRUTE)
		owner.adjustBruteLoss(adjusted)
	return COMPONENT_DAMAGE_HANDLED

/obj/projectile/magic/formula_magic_bolt
	name = "formula bolt"
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_orb"
	damage = 0
	nodamage = TRUE
	range = 7
	max_range = 7
	spell_impact_intensity = SPELL_IMPACT_LOW
	var/list/formula_summary
	var/pierce_remaining = 0

/obj/projectile/magic/formula_magic_bolt/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(out_of_effective_range())
		return
	var/mob/living/carbon/human/caster
	if(istype(firer, /mob/living/carbon/human))
		caster = firer
	var/turf/impact = get_turf(target)
	if(impact && formula_summary)
		resolve_formula_magic_area_effect(caster, formula_summary, impact)
	if(pierce_remaining > 0 && isliving(target))
		pierce_remaining--
		return BULLET_ACT_FORCE_PIERCE
	return BULLET_ACT_HIT

/obj/projectile/magic/formula_magic_bolt/can_hit_target(atom/target, list/passthrough, direct_target = FALSE, ignore_loc = FALSE)
	if(QDELETED(target))
		return FALSE
	if(!ignore_source_check && firer)
		var/mob/M = firer
		if((target == firer) || (target in firer.buckled_mobs) || (istype(M) && (M.buckled == target)))
			return FALSE
	if(!ignore_loc && (loc != target.loc))
		return FALSE
	if(target in passthrough)
		return FALSE
	if(isliving(target))
		return TRUE
	if(isobj(target))
		var/obj/O = target
		if(O.density || istype(O, /obj/structure) || istype(O, /obj/machinery))
			return TRUE
	return ..()

/obj/projectile/magic/formula_magic_bolt/Move(atom/newloc, dir = NONE)
	. = ..()
	if(!. || QDELETED(src) || !fired || !loc)
		return
	for(var/mob/living/L in loc)
		if(can_hit_target(L, permutated, L == original, TRUE))
			Bump(L)
			return
	for(var/obj/O in loc)
		if(O == src)
			continue
		if(can_hit_target(O, permutated, O == original, TRUE))
			Bump(O)
			return

/obj/effect/formula_magic_light
	name = "formula light"
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_orb"
	anchored = TRUE
	layer = ABOVE_MOB_LAYER

/obj/effect/formula_magic_light/Initialize(mapload, effect_color, lifespan)
	. = ..()
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
		set_light(4, 2, 1, l_color = effect_color)
	else
		set_light(4, 2, 1)
	QDEL_IN(src, max(10 SECONDS, lifespan || 60 SECONDS))

/obj/structure/formula_magic_forge
	name = "formula forge"
	desc = "A temporary arcyne working surface."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_summon"
	anchored = TRUE
	density = FALSE

/obj/structure/formula_magic_forge/proc/setup_formula_forge(mob/living/carbon/human/caster, lifespan)
	add_atom_colour("#36B36A", FIXED_COLOUR_PRIORITY)
	set_light(2, 1, 1, l_color = "#36B36A")
	QDEL_IN(src, max(30 SECONDS, lifespan || 5 MINUTES))

/obj/effect/temp_visual/formula_magic_zone
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_rune"
	randomdir = FALSE
	fade_time = 4
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/formula_magic_zone/Initialize(mapload, effect_color, state_override, custom_duration)
	if(custom_duration)
		duration = custom_duration
	if(state_override)
		icon_state = state_override
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
	. = ..()

/obj/effect/temp_visual/formula_magic_meteor
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_meteor"
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER
	pixel_y = 160
	fade_time = 3

/obj/effect/temp_visual/formula_magic_meteor/Initialize(mapload, effect_color, fall_delay)
	duration = max(1, fall_delay || 5 SECONDS)
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
	var/matrix/M = matrix()
	M.Scale(1.5)
	transform = M
	. = ..()
	animate(src, pixel_y = 0, transform = matrix(), time = duration)

/obj/effect/temp_visual/formula_magic_dragon_fire_particle
	name = "formula breath"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_fire"
	duration = 8
	layer = ABOVE_MOB_LAYER
	appearance_flags = RESET_TRANSFORM | PIXEL_SCALE

/obj/effect/temp_visual/formula_magic_dragon_fire_particle/Initialize(mapload, direction, effect_color)
	. = ..()
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
	var/dist = 3
	var/p_x = 0
	var/p_y = 0
	var/side_variance = rand(-48, 48)
	var/forward_dist = 32 * dist
	switch(direction)
		if(NORTH)
			p_y = forward_dist
			p_x = side_variance
		if(SOUTH)
			p_y = -forward_dist
			p_x = side_variance
		if(EAST)
			p_x = forward_dist
			p_y = side_variance
		if(WEST)
			p_x = -forward_dist
			p_y = side_variance
	animate(src, pixel_x = p_x, pixel_y = p_y, alpha = 0, time = duration, easing = SINE_EASING)

/obj/structure/trap/formula_magic
	name = "formula rune"
	desc = "A dormant spoken formula waits in the ground."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_rune"
	alpha = 140
	charges = 1
	time_between_triggers = 0
	sparks = FALSE
	scraptype = /obj/item/magic/manacrystal
	var/mob/living/carbon/human/caster
	var/list/formula_summary

/obj/structure/trap/formula_magic/Destroy()
	caster = null
	formula_summary = null
	. = ..()

/obj/structure/trap/formula_magic/proc/setup_formula_rune(mob/living/carbon/human/new_caster, list/new_summary, rune_duration)
	caster = new_caster
	formula_summary = new_summary?.Copy()
	if(caster?.mind)
		immune_minds |= caster.mind
	var/effect_color = formula_magic_color_for_summary(formula_summary)
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, max(10 SECONDS, rune_duration || 60 SECONDS))
	return TRUE

/obj/structure/trap/formula_magic/trap_effect(mob/living/L)
	if(!formula_summary)
		return
	var/list/trigger_summary = formula_magic_secondary_summary(formula_summary)
	trigger_summary["radius"] = max(0, trigger_summary["radius"] || 0)
	resolve_formula_magic_area_effect(caster, trigger_summary, get_turf(src))
