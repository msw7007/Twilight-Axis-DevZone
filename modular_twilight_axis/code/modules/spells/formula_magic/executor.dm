#if 0
// OLD FORMULA MAGIC REFERENCE. DO NOT EXECUTE.
// Full rewrite starts below this reference block. Port old behavior only by explicit request.
/datum/mind/proc/perform_formula_magic_cast(mob/living/carbon/human/caster, list/word_ids, atom/cast_on, speak_words = TRUE, atom/guidance_start)
	if(!caster || !length(word_ids))
		return FALSE
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(word_ids)
	if(!formula || !formula.can_resolve())
		to_chat(caster, span_warning("The formula refuses to resolve."))
		qdel(formula)
		return FALSE

	if(speak_words)
		var/list/speech_phrases = formula_magic_speech_phrases_for_words(word_ids)
		var/list/speech_delays = formula_magic_speech_delays_for_words(word_ids, formula.word_cast_times)
		for(var/i in 1 to length(speech_phrases))
			caster.say(speech_phrases[i], forced = "spell", language = /datum/language/common)
			caster.stamina_add(max(1, round(formula.mana_cost / max(1, length(speech_phrases)))))
			var/speak_delay = max(2, speech_delays[i] || FORMULA_DEFAULT_WORD_DELAY)
			if(!do_after(caster, speak_delay, target = caster))
				to_chat(caster, span_warning("My formula breaks apart before it can resolve."))
				qdel(formula)
				return FALSE

	resolve_formula_magic_effect(caster, formula, cast_on, guidance_start)
	qdel(formula)
	return TRUE

/datum/mind/proc/perform_formula_magic_scroll_cast(mob/living/carbon/human/caster, list/word_ids, atom/cast_on)
	if(!caster || !length(word_ids))
		return FALSE
	var/arcane_required = get_formula_magic_arcane_requirement(word_ids)
	if(caster.get_skill_level(/datum/skill/misc/reading) < arcane_required)
		to_chat(caster, span_warning("I need Reading [arcane_required] to follow this formula scroll."))
		return FALSE
	var/datum/formula_magic_formula/formula = build_formula_magic_raw_formula(word_ids)
	if(!formula || !formula.can_resolve())
		to_chat(caster, span_warning("The scroll's formula refuses to resolve."))
		qdel(formula)
		return FALSE
	var/list/speech_phrases = formula_magic_speech_phrases_for_words(word_ids)
	for(var/phrase in speech_phrases)
		caster.say(phrase, forced = "spell", language = /datum/language/common)
	resolve_formula_magic_effect(caster, formula, cast_on)
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
		return formula_magic_detonate_caster(caster, formula, "opposed formula")
	if(formula.tags["unstable_prebuilt"])
		return formula_magic_detonate_caster(caster, formula, "corrupted fixed formula")
	if(formula.tags["unstable_fixed_combo"])
		return formula_magic_detonate_caster(caster, formula, "overloaded fixed formula")
	if(formula.tags["prebuilt_formula"])
		return resolve_formula_magic_prebuilt(caster, formula, cast_on)

	formula_magic_configure_trailing_orb_seeker(caster, formula, target)

	if("sequence" in formula.links)
		return resolve_formula_magic_sequence(caster, formula, cast_on, guidance_start)

	var/resolved_any = FALSE
	var/list/form_counts = formula_magic_form_counts(formula)
	var/meteor_count = formula_magic_consume_form_pair_count(form_counts, FORMULA_FORM_ORB, FORMULA_FORM_INSTANT)
	if(meteor_count)
		var/turf/meteor_target = formula_magic_limited_target_from_caster(caster, target, formula_magic_form_repeat_range(formula, FORMULA_FORM_INSTANT, 3))
		for(var/i in 1 to meteor_count)
			var/turf/current_target = formula_magic_combo_offset_target(meteor_target, i)
			if(resolve_formula_magic_meteor(caster, formula, current_target || meteor_target))
				resolved_any = TRUE
	var/breath_count = formula_magic_consume_form_pair_count(form_counts, FORMULA_FORM_CLOAK, FORMULA_FORM_TOUCH)
	if(breath_count)
		var/old_breath_range = formula.range
		formula.range = max(formula.range, 3)
		for(var/i in 1 to breath_count)
			if(resolve_formula_magic_breath(caster, formula, target))
				resolved_any = TRUE
		formula.range = old_breath_range
	var/nova_count = formula_magic_consume_form_pair_count(form_counts, FORMULA_FORM_AURA, FORMULA_FORM_WAVE)
	if(nova_count)
		var/list/nova_summary = formula.get_summary()
		nova_summary["skip_center_visual"] = TRUE
		nova_summary["radius"] = max(1, nova_summary["radius"] || 0)
		for(var/i in 1 to nova_count)
			if(resolve_formula_magic_area_effect(caster, nova_summary, source))
				resolved_any = TRUE
	var/rune_count = formula_magic_consume_form_pair_count(form_counts, FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE)
	if(rune_count)
		for(var/i in 1 to rune_count)
			var/turf/current_target = formula_magic_combo_offset_target(target, i)
			if(resolve_formula_magic_rune(caster, formula, current_target || target))
				resolved_any = TRUE
	if(formula_magic_uncombined_form_type_count(form_counts) > 1)
		return formula_magic_detonate_caster(caster, formula, "unjoined formula")
	var/list/resolved_forms = list()
	for(var/form_id in formula.forms)
		if(form_id in resolved_forms)
			continue
		if((form_counts[form_id] || 0) <= 0)
			continue
		resolved_forms += form_id
		if(resolve_formula_magic_single_form(caster, formula, form_id, target, guidance_start, cast_on))
			resolved_any = TRUE

	if(resolved_any)
		return TRUE

	resolve_formula_magic_area_effect(caster, formula.get_summary(), target)
	return TRUE

/proc/resolve_formula_magic_sequence(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, atom/cast_on, atom/guidance_start)
	if(!caster?.mind || !formula)
		return FALSE
	var/list/segments = formula_magic_sequence_segments_from_formula(formula)
	if(!length(segments))
		return FALSE
	var/list/first_segment = segments[1]
	var/datum/formula_magic_formula/segment_formula = caster.mind.build_formula_magic_formula(first_segment)
	if(!segment_formula)
		return FALSE
	var/list/remaining_segments = length(segments) > 1 ? segments.Copy(2) : list()
	if(FORMULA_FORM_ORB in segment_formula.forms)
		remaining_segments = formula_magic_configure_orb_sequence(caster, segment_formula, remaining_segments, cast_on)
	if(length(remaining_segments))
		segment_formula.sequence_segments = remaining_segments
	var/result = resolve_formula_magic_effect(caster, segment_formula, cast_on, guidance_start)
	qdel(segment_formula)
	return result

/proc/formula_magic_configure_orb_sequence(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, list/segments, atom/cast_on)
	if(!caster?.mind || !formula || !length(segments))
		return segments
	var/list/remaining_segments = segments.Copy()
	var/list/carrier_summaries = list()
	var/chase_orb_count = 0
	while(length(remaining_segments))
		var/list/segment = remaining_segments[1]
		var/orb_count = formula_magic_word_count_in_segment(segment, FORMULA_FORM_ORB)
		if(!orb_count)
			break
		chase_orb_count += orb_count
		if(formula_magic_segment_is_only_word(segment, FORMULA_FORM_ORB))
			remaining_segments.Cut(1, 2)
			continue
		var/datum/formula_magic_formula/carrier_formula = caster.mind.build_formula_magic_formula(segment)
		if(!carrier_formula)
			break
		var/list/carrier_summary = carrier_formula.get_summary()
		carrier_summary["radius"] = 0
		carrier_summary["silent"] = TRUE
		carrier_summary["sequence_segments"] = list()
		carrier_summaries += list(carrier_summary)
		qdel(carrier_formula)
		remaining_segments.Cut(1, 2)
	if(chase_orb_count)
		var/atom/chase_target = formula_magic_nearest_target_to_point(caster, get_turf(cast_on), 7)
		if(chase_target)
			formula.tags["orb_sequence_chase"] = chase_orb_count
			formula.tags["orb_seeker"] = max(formula.tags["orb_seeker"] || 0, chase_orb_count)
			formula.tags["orb_seeker_target"] = chase_target
			formula.tags["pierce"] = max(formula.tags["pierce"] || 0, 99)
	if(length(carrier_summaries))
		formula.tags["orb_carrier"] = length(carrier_summaries)
		formula.tags["pierce"] = max(formula.tags["pierce"] || 0, 99)
		formula.sequence_segments = list()
		formula.tags["orb_carrier_summaries"] = carrier_summaries
	return remaining_segments

/proc/formula_magic_configure_trailing_orb_seeker(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target)
	if(!caster || !formula || length(formula.links))
		return FALSE
	if(!(FORMULA_FORM_ORB in formula.forms) || length(formula.forms) < 2)
		return FALSE
	var/trailing_orbs = 0
	for(var/i = length(formula.words), i >= 1, i--)
		var/datum/formula_magic_word/word = formula.words[i]
		if(!word || word.id != FORMULA_FORM_ORB)
			break
		trailing_orbs++
	if(trailing_orbs <= 0 || trailing_orbs >= length(formula.forms))
		return FALSE
	formula.tags["orb_seeker"] = trailing_orbs
	formula.tags["orb_seeker_target"] = formula_magic_nearest_target_to_point(caster, target, 7)
	formula.power = max(1, round(formula.power * 0.6))
	formula.projectile_count = max(1, (formula.projectile_count || 1) - trailing_orbs)
	return TRUE

/proc/formula_magic_word_count_in_segment(list/segment, word_id)
	var/count = 0
	for(var/current_id in segment)
		if(current_id == word_id)
			count++
	return count

/proc/formula_magic_segment_is_only_word(list/segment, word_id)
	if(!length(segment))
		return FALSE
	for(var/current_id in segment)
		if(current_id != word_id)
			return FALSE
	return TRUE

/proc/formula_magic_sequence_segments_from_formula(datum/formula_magic_formula/formula)
	var/list/segments = list()
	var/list/current_segment = list()
	for(var/datum/formula_magic_word/word in formula?.words)
		if(!word)
			continue
		if(word.id == "sequence")
			if(length(current_segment))
				segments += list(current_segment)
				current_segment = list()
			continue
		current_segment += word.id
	if(length(current_segment))
		segments += list(current_segment)
	return segments

/proc/formula_magic_detonate_caster(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, reason)
	if(!caster || !formula)
		return FALSE
	caster.visible_message(span_danger("[caster]'s [reason || "formula"] detonates in their hands!"), span_userdanger("The [reason || "formula"] detonates through me!"))
	caster.adjustBruteLoss(max(10, formula.power))
	caster.safe_throw_at(get_ranged_target_turf(caster, turn(caster.dir, 180), 3), 3, 1, caster, force = MOVE_FORCE_STRONG)
	return FALSE

/proc/resolve_formula_magic_prebuilt(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, atom/cast_on)
	if(!caster || !formula)
		return FALSE
	var/list/tags = formula.tags || list()
	var/mob/living/target = formula_magic_prebuilt_target(caster, cast_on)
	if(!target)
		to_chat(caster, span_warning("The fixed formula finds no valid target."))
		return FALSE
	if(tags["prebuilt_guidance"])
		apply_buff_to(target, /datum/status_effect/buff/guidance, STAT_BUFF_SELF_DURATION)
		target.visible_message(span_notice("[target] briefly shines orange."))
		return TRUE
	if(tags["prebuilt_surge"])
		if(target == caster)
			to_chat(caster, span_warning("This surge cannot be turned inward."))
			return FALSE
		formula_magic_apply_surge(target)
		target.visible_message(span_warning("[target] surges back up, wreathed in energy!"), span_notice("Arcyne energy floods my body - I rise!"))
		return TRUE
	if(tags["prebuilt_precognition"])
		var/hastened = formula_magic_reduce_combat_cooldowns(target)
		if(hastened)
			target.balloon_alert_to_viewers("<font color='#66ffcc'>cooldowns -30s!</font>")
			to_chat(target, span_notice("I glimpse the moments ahead, and ready myself for the next move."))
		else
			to_chat(target, span_notice("I glimpse the moments ahead, but there is nothing left to hasten."))
		return TRUE
	if(tags["prebuilt_ascension"])
		if(target == caster)
			to_chat(caster, span_warning("This power is too great to channel into myself."))
			return FALSE
		apply_buff_to(target, /datum/status_effect/buff/attune_haste, STAT_BUFF_ALLY_DURATION)
		apply_buff_to(target, /datum/status_effect/buff/attune_giant, STAT_BUFF_ALLY_DURATION)
		apply_buff_to(target, /datum/status_effect/buff/fortitude, STAT_BUFF_ALLY_DURATION)
		apply_buff_to(target, /datum/status_effect/buff/attune_hawk, STAT_BUFF_ALLY_DURATION)
		apply_buff_to(target, /datum/status_effect/buff/guidance, STAT_BUFF_ALLY_DURATION)
		target.visible_message(span_warning("[target] radiates with overwhelming arcyne energy!"))
		return TRUE
	if(tags["prebuilt_blood_rush"])
		target.apply_status_effect(/datum/status_effect/buff/adrenaline_rush)
		if(target != caster)
			caster.apply_status_effect(/datum/status_effect/buff/adrenaline_rush)
		target.visible_message(span_warning("[target]'s veins flush with sudden vigor."))
		return TRUE
	if(tags["prebuilt_fortitude"])
		apply_buff_to(target, /datum/status_effect/buff/fortitude, STAT_BUFF_SELF_DURATION)
		return TRUE
	if(tags["prebuilt_mirror_transform"])
		if(!istype(target, /mob/living/carbon/human))
			to_chat(caster, span_warning("The mirror formula needs a humen body."))
			return FALSE
		var/mob/living/carbon/human/H = target
		ADD_TRAIT(H, TRAIT_MIRROR_MAGIC, TRAIT_GENERIC)
		H.visible_message(span_notice("[H]'s reflection shimmers briefly."))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_remove_mirror_magic), H), 5 MINUTES)
		return TRUE
	if(tags["prebuilt_airhead"])
		var/had_guidance = target.has_status_effect(/datum/status_effect/buff/guidance)
		if(had_guidance)
			target.remove_status_effect(/datum/status_effect/buff/guidance)
		else
			target.apply_status_effect(/datum/status_effect/debuff/formula_magic_reverse_guidance, 30 SECONDS)
		var/list/airhead_debuff = list(STATKEY_PER = -3, STATKEY_INT = -1)
		target.apply_status_effect(/datum/status_effect/debuff/formula_magic_stat_curse, airhead_debuff, 30 SECONDS)
		target.balloon_alert_to_viewers("<font color='#8A8A8A'>airhead!</font>")
		return TRUE
	if(tags["prebuilt_mending"])
		var/turf/repair_turf = get_turf(cast_on) || get_turf(target)
		if(!formula_magic_repair_atoms(caster, repair_turf, formula.power))
			to_chat(caster, span_warning("The mending formula finds nothing broken enough to repair."))
			return FALSE
		return TRUE
	if(tags["prebuilt_form_blade"])
		return formula_magic_prebuilt_form_blade(caster)
	if(tags["prebuilt_bind_armament"])
		return formula_magic_prebuilt_bind_armament(caster)
	if(tags["prebuilt_summon_instrument"])
		return formula_magic_prebuilt_summon_instrument(caster)
	if(tags["prebuilt_familiar"])
		return formula_magic_prebuilt_familiar(caster, cast_on, FALSE)
	if(tags["prebuilt_elemental_familiar"])
		return formula_magic_prebuilt_familiar(caster, cast_on, TRUE)
	if(tags["prebuilt_raise_deadite"])
		return formula_magic_prebuilt_necromancy_summon(caster, cast_on, /mob/living/simple_animal/hostile/rogue/skeleton/guard, "calls a weak deadite guard.")
	if(tags["prebuilt_conjure_undead"])
		return formula_magic_prebuilt_necromancy_summon(caster, cast_on, /mob/living/carbon/human/species/skeleton/npc/bogguard/necromancer, "calls a deadite guardian.")
	if(tags["prebuilt_raise_skeleton"])
		return formula_magic_prebuilt_necromancy_summon(caster, cast_on, /mob/living/carbon/human/species/skeleton/npc/summon, "raises a skeleton servant.")
	if(tags["prebuilt_read_omen"])
		return formula_magic_prebuilt_read_omen(caster)
	if(tags["prebuilt_message"])
		return formula_magic_prebuilt_message(caster)
	if(tags["prebuilt_mindlink"])
		return formula_magic_prebuilt_mindlink(caster)
	if(tags["prebuilt_teleport_rune"])
		return formula_magic_prebuilt_teleport_rune(caster, cast_on)
	if(tags["prebuilt_reversion"])
		return formula_magic_prebuilt_reversion(caster, cast_on, formula)
	if(tags["prebuilt_lesser_knock"])
		return formula_magic_prebuilt_lesser_knock(caster)
	if(tags["prebuilt_conjure_spectacles"])
		return formula_magic_prebuilt_conjure_spectacles(caster)
	if(tags["prebuilt_great_shelter"])
		return formula_magic_prebuilt_great_shelter(caster)
	return FALSE

/proc/formula_magic_prebuilt_target(mob/living/carbon/human/caster, atom/cast_on)
	if(isliving(cast_on))
		return cast_on
	var/turf/T = get_turf(cast_on)
	if(!T)
		T = get_turf(caster)
	for(var/mob/living/L in T)
		if(L == caster)
			continue
		return L
	return caster

/proc/formula_magic_prebuilt_turf(mob/living/carbon/human/caster, atom/cast_on)
	var/turf/T = get_turf(cast_on)
	if(!T)
		T = get_step(caster, caster.dir)
	if(!T)
		T = get_turf(caster)
	return T

/proc/formula_magic_bind_summon_to_caster(mob/living/summon, mob/living/carbon/human/caster)
	if(!summon || !caster)
		return
	var/faction_key = caster.mind?.current?.real_name ? "[caster.mind.current.real_name]_faction" : "[caster.real_name]_faction"
	if(!(faction_key in caster.faction))
		caster.faction |= faction_key
	summon.faction |= caster.faction
	summon.faction |= faction_key
	if("summoner" in summon.vars)
		summon.vars["summoner"] = caster.real_name

/proc/formula_magic_prebuilt_familiar(mob/living/carbon/human/caster, atom/cast_on, elemental = FALSE)
	if(!caster)
		return FALSE
	var/turf/T = formula_magic_prebuilt_turf(caster, cast_on)
	if(!isopenturf(T))
		to_chat(caster, span_warning("The familiar formula needs open ground."))
		return FALSE
	var/familiar_type = elemental ? /mob/living/simple_animal/pet/familiar/elemental : /mob/living/simple_animal/pet/familiar/fae
	var/mob/living/simple_animal/pet/familiar/familiar = new familiar_type(T)
	familiar.familiar_summoner = caster
	formula_magic_bind_summon_to_caster(familiar, caster)
	caster.visible_message(span_notice("[caster] calls [familiar] through a fixed formula."))
	return TRUE

/proc/formula_magic_summon_primordial(mob/living/carbon/human/caster, turf/T, primordial_type)
	if(!caster || !ispath(primordial_type, /mob/living/simple_animal/hostile/retaliate/rogue/primordial))
		return FALSE
	if(!isopenturf(T))
		to_chat(caster, span_warning("The primordial formula needs open ground."))
		return FALSE
	var/mob/living/primordial = new primordial_type(T, caster)
	formula_magic_bind_summon_to_caster(primordial, caster)
	if(!locate(/obj/effect/proc_holder/spell/invoked/minion_order) in caster.mind?.spell_list)
		caster.mind?.AddSpell(new /obj/effect/proc_holder/spell/invoked/minion_order)
	caster.visible_message(span_warning("[caster] tears open a primordial shape from a spoken formula."))
	return TRUE

/proc/formula_magic_prebuilt_necromancy_summon(mob/living/carbon/human/caster, atom/cast_on, summon_type, message)
	if(!caster || !ispath(summon_type))
		return FALSE
	var/turf/T = formula_magic_prebuilt_turf(caster, cast_on)
	if(!isopenturf(T))
		to_chat(caster, span_warning("The necromantic formula needs open ground."))
		return FALSE
	new /obj/effect/temp_visual/gib_animation(T, "gibbed-h")
	var/mob/living/summon = new summon_type(T, caster)
	formula_magic_bind_summon_to_caster(summon, caster)
	if(!locate(/obj/effect/proc_holder/spell/invoked/minion_order) in caster.mind?.spell_list)
		caster.mind?.AddSpell(new /obj/effect/proc_holder/spell/invoked/minion_order)
	caster.visible_message(span_warning("[caster] [message]"))
	return TRUE

/proc/formula_magic_spawn_ratmouse(mob/living/carbon/human/caster, turf/T, lifespan)
	if(!T || !isopenturf(T) || T.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	var/mob/living/simple_animal/hostile/retaliate/rogue/bigrat/rat = new(T)
	QDEL_IN(rat, max(10 SECONDS, lifespan || 30 SECONDS))
	new /obj/effect/temp_visual/spell_impact(T, "#8A8A8A", SPELL_IMPACT_LOW)
	return TRUE

/proc/formula_magic_prebuilt_read_omen(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	caster.visible_message(span_info("The eyes of [caster] roll back into their head for a moment!"), span_info("My eyes roll into the back of my head!"))
	var/datum/storyteller/current_god = SSgamemode.storytellers[SSgamemode.ruling_god]
	if(!current_god)
		to_chat(caster, span_warning("The omen is silent."))
		return TRUE
	to_chat(caster, span_warning("The leylines bend toward [current_god.name]."))
	return TRUE

/proc/formula_magic_prebuilt_message(mob/living/carbon/human/caster)
	if(!caster?.mind?.known_people?.len)
		to_chat(caster, span_warning("I don't know anyone to contact."))
		return FALSE
	var/list/eligible_players = sortList(caster.mind.known_people.Copy())
	var/target_name = tgui_input_list(caster, "Who do I contact?", "Message", eligible_players)
	if(!target_name)
		return FALSE
	var/mob/living/carbon/human/target
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.real_name == target_name)
			target = H
			break
	if(!target)
		to_chat(caster, span_warning("I seek a mental connection, but cannot find [target_name]."))
		return FALSE
	var/message = stripped_input(caster, "What thought do I send?", "Message", "", 160)
	if(!message)
		return FALSE
	target.playsound_local(target, 'sound/magic/message.ogg', 100)
	caster.playsound_local(caster, 'sound/magic/message.ogg', 100)
	var/message_color = ishuman(caster) ? caster.voice_color : "7246ff"
	to_chat(target, span_big("Arcyne whispers slip into my mind, resolving into [caster]'s voice: <font color=#[message_color]><i>\"[message]\"</i></font>"))
	to_chat(caster, span_big("I whisper into [target]'s mind: <font color=#[message_color]><i>\"[message]\"</i></font>"))
	log_game("[key_name(caster)] sent a formula magic message to [key_name(target)] with contents [message]")
	return TRUE

/proc/formula_magic_prebuilt_mindlink(mob/living/carbon/human/caster)
	if(!caster?.mind?.known_people?.len)
		to_chat(caster, span_warning("I know no minds to bind."))
		return FALSE
	var/list/possible_targets = sortList(caster.mind.known_people.Copy())
	possible_targets = list(caster.real_name) + possible_targets
	var/first_target_name = tgui_input_list(caster, "Choose the first mind.", "Mindlink", possible_targets)
	if(!first_target_name)
		return FALSE
	possible_targets -= first_target_name
	var/second_target_name = tgui_input_list(caster, "Choose the second mind.", "Mindlink", possible_targets)
	if(!second_target_name)
		return FALSE
	var/mob/living/first_target
	var/mob/living/second_target
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.real_name == first_target_name)
			first_target = H
		if(H.real_name == second_target_name)
			second_target = H
	if(!first_target || !second_target)
		to_chat(caster, span_warning("One of the chosen minds is absent."))
		return FALSE
	for(var/datum/mindlink/ML in GLOB.mindlinks)
		if(ML && (ML.owner == first_target || ML.target == first_target || ML.owner == second_target || ML.target == second_target))
			to_chat(caster, span_warning("A mindlink already binds one of the targets."))
			return FALSE
	caster.visible_message(span_notice("[caster] touches their temples and threads two minds together."))
	var/datum/mindlink/link = new(first_target, second_target)
	GLOB.mindlinks += link
	to_chat(first_target, span_notice("A mindlink has been established with [second_target]. Use ,Y before a message to communicate telepathically."))
	to_chat(second_target, span_notice("A mindlink has been established with [first_target]. Use ,Y before a message to communicate telepathically."))
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_break_mindlink), link), 3 MINUTES)
	return TRUE

/proc/formula_magic_break_mindlink(datum/mindlink/link)
	if(!link)
		return
	to_chat(link.owner, span_warning("The mindlink with [link.target] fades away..."))
	to_chat(link.target, span_warning("The mindlink with [link.owner] fades away..."))
	GLOB.mindlinks -= link
	qdel(link)

/proc/formula_magic_prebuilt_lesser_knock(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	if(!length(caster.get_empty_held_indexes()))
		to_chat(caster, span_warning("I need a free hand for the lockpick."))
		return FALSE
	var/obj/item/melee/touch_attack/lesserknock/lockpick = new(caster.drop_location())
	caster.put_in_hands(lockpick)
	caster.visible_message(span_notice("[caster] conjures a spectral lockpick."))
	return TRUE

/proc/formula_magic_prebuilt_conjure_spectacles(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	if(!length(caster.get_empty_held_indexes()))
		to_chat(caster, span_warning("I need a free hand for the spectacles."))
		return FALSE
	var/list/spectacles = list(
		"Spectacles" = /obj/item/clothing/mask/rogue/spectacles,
		"Nocshades" = /obj/item/clothing/mask/rogue/spectacles/inq_lesser_summoned,
		"Golden Spectacles" = /obj/item/clothing/mask/rogue/spectacles/golden_lesser_summoned,
		"Silver Monocle" = /obj/item/clothing/mask/rogue/spectacles/monocle,
		"Smokey Onyxa Spectacles" = /obj/item/clothing/mask/rogue/spectacles/onyxa_lesser_summoned,
	)
	var/choice = tgui_input_list(caster, "Choose spectacles.", "Conjure Spectacles", spectacles)
	if(!choice)
		return FALSE
	var/spectacles_type = spectacles[choice]
	var/obj/item/clothing/mask/rogue/spectacles/R = new spectacles_type(caster.drop_location())
	R.AddComponent(/datum/component/conjured_item, GLOW_COLOR_ARCANE, FALSE, caster, null)
	R.sellprice = 0
	caster.put_in_hands(R)
	caster.visible_message(span_notice("[caster] conjures [R] from shaped glass-light."))
	return TRUE

/proc/formula_magic_prebuilt_great_shelter(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	var/turf/center = get_turf(caster)
	if(!center)
		return FALSE
	var/raised = 0
	for(var/turf/T in range(1, center))
		if(T == center || !isopenturf(T) || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/obj/structure/formula_magic_wall/wall = new(T)
		wall.setup_formula_wall("#C000FF", 60 SECONDS)
		raised++
	if(!raised)
		to_chat(caster, span_warning("The shelter formula finds no open ground."))
		return FALSE
	caster.visible_message(span_notice("[caster] raises a brief arcyne shelter."))
	return TRUE

/proc/formula_magic_prebuilt_teleport_rune(mob/living/carbon/human/caster, atom/cast_on)
	if(!caster?.mind)
		return FALSE
	var/turf/T = formula_magic_prebuilt_turf(caster, cast_on)
	if(!T || !isopenturf(T) || T.is_blocked_turf(exclude_mobs = TRUE))
		to_chat(caster, span_warning("The teleport rune needs open ground."))
		return FALSE
	if(!caster.mind.can_register_formula_magic_teleport_rune())
		to_chat(caster, span_warning("My arcane memory can only bind [caster.mind.get_formula_magic_teleport_rune_limit()] teleport rune(s)."))
		return FALSE
	if(locate(/obj/structure/formula_magic_teleport_rune) in T)
		to_chat(caster, span_warning("A teleport rune already holds this ground."))
		return FALSE
	var/obj/structure/formula_magic_teleport_rune/rune = new(T)
	if(!rune.setup_formula_teleport_rune(caster))
		qdel(rune)
		return FALSE
	caster.visible_message(span_notice("[caster] fixes a displacement rune into the ground."))
	return TRUE

/proc/formula_magic_apply_surge(mob/living/target)
	if(!target)
		return
	target.SetUnconscious(0)
	target.SetSleeping(0)
	target.SetParalyzed(0)
	target.SetImmobilized(0)
	target.SetStun(0)
	target.SetKnockdown(0)
	if(target.has_status_effect(/datum/status_effect/incapacitating/off_balanced))
		target.remove_status_effect(/datum/status_effect/incapacitating/off_balanced)
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		carbon_target.stam_paralyzed = FALSE
	target.stamina_reset()
	target.set_resting(FALSE)

/proc/formula_magic_reduce_combat_cooldowns(mob/living/target)
	if(!target)
		return FALSE
	var/hastened = FALSE
	hastened |= formula_magic_reduce_status_duration(target, /datum/status_effect/debuff/clashcd, 30 SECONDS)
	hastened |= formula_magic_reduce_status_duration(target, /datum/status_effect/debuff/feintcd, 30 SECONDS)
	hastened |= formula_magic_reduce_status_duration(target, /datum/status_effect/debuff/baitcd, 30 SECONDS)
	hastened |= formula_magic_reduce_status_duration(target, /datum/status_effect/debuff/specialcd, 30 SECONDS)
	return hastened

/proc/formula_magic_reduce_status_duration(mob/living/target, effect_type, amount)
	var/datum/status_effect/S = target?.has_status_effect(effect_type)
	if(!S)
		return FALSE
	S.duration -= amount
	if(S.duration <= world.time)
		target.remove_status_effect(effect_type)
	return TRUE

/proc/formula_magic_remove_mirror_magic(mob/living/carbon/human/H)
	if(QDELETED(H))
		return
	REMOVE_TRAIT(H, TRAIT_MIRROR_MAGIC, TRAIT_GENERIC)
	to_chat(H, span_warning("My connection to mirrors fades away."))

/proc/formula_magic_prebuilt_form_blade(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	if(!length(caster.get_empty_held_indexes()))
		to_chat(caster, span_warning("I need a free hand to shape an arcyne blade."))
		return FALSE
	var/list/forms = list(
		"Khopesh" = /obj/item/rogueweapon/sword/sabre/ferramancy,
		"Rapier" = /obj/item/rogueweapon/sword/rapier/ferramancy,
		"Greatsword" = /obj/item/rogueweapon/greatsword/ferramancy,
		"Greataxe" = /obj/item/rogueweapon/greataxe/steel/doublehead/ferramancy,
		"Halberd" = /obj/item/rogueweapon/halberd/ferramancy,
		"Greatbow" = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/greatbow,
	)
	var/choice = tgui_input_list(caster, "Choose an arcyne weapon form.", "Form Blade", forms)
	if(!choice)
		return FALSE
	formula_magic_clear_conjured_types(caster, list(
		/obj/item/rogueweapon/sword/sabre/ferramancy,
		/obj/item/rogueweapon/sword/rapier/ferramancy,
		/obj/item/rogueweapon/greatsword/ferramancy,
		/obj/item/rogueweapon/greataxe/steel/doublehead/ferramancy,
		/obj/item/rogueweapon/halberd/ferramancy,
		/obj/item/gun/ballistic/revolver/grenadelauncher/bow/greatbow,
	))
	var/weapon_type = forms[choice]
	var/obj/item/W = new weapon_type(caster.drop_location())
	if(W.max_integrity)
		W.max_integrity = round(W.max_integrity * 0.5)
		W.obj_integrity = W.max_integrity
	W.AddComponent(/datum/component/conjured_item, "#5c7cff", FALSE, caster, null)
	caster.put_in_hands(W)
	caster.visible_message(span_notice("[caster] shapes [W] from arcyne metal."))
	return TRUE

/proc/formula_magic_prebuilt_bind_armament(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	var/obj/item/weapon = caster.get_active_held_item()
	if(!weapon)
		var/released = formula_magic_release_skill_binds(caster)
		if(released)
			to_chat(caster, span_notice("The arcyne bonds on my armaments fade."))
			return TRUE
		to_chat(caster, span_warning("I have no held weapon or bound armament to release."))
		return FALSE
	if(!istype(weapon, /obj/item/rogueweapon) || !ispath(weapon.associated_skill, /datum/skill/combat))
		to_chat(caster, span_warning("[weapon] is not something my arts can guide."))
		return FALSE
	if(weapon.GetComponent(/datum/component/skill_bind))
		to_chat(caster, span_warning("[weapon] already carries an arcyne bond."))
		return FALSE
	weapon.AddComponent(/datum/component/skill_bind, /datum/skill/combat/arcyne, caster)
	to_chat(caster, span_notice("I lay an arcyne bond on [weapon]; it answers to my conjurer's training now."))
	playsound(get_turf(caster), 'sound/magic/charged.ogg', 50, TRUE)
	caster.visible_message(span_notice("[caster] passes a hand over [weapon], which glows faintly."))
	return TRUE

/proc/formula_magic_release_skill_binds(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	var/released = FALSE
	for(var/obj/item/I in caster.GetAllContents())
		var/datum/component/skill_bind/existing = I.GetComponent(/datum/component/skill_bind)
		if(!existing)
			continue
		qdel(existing)
		released = TRUE
	return released

/proc/formula_magic_prebuilt_summon_instrument(mob/living/carbon/human/caster)
	if(!caster)
		return FALSE
	if(!length(caster.get_empty_held_indexes()))
		to_chat(caster, span_warning("I need a free hand to hold the instrument."))
		return FALSE
	var/list/instruments = list(
		"Harp" = /obj/item/rogue/instrument/harp,
		"Lute" = /obj/item/rogue/instrument/lute,
		"Accordion" = /obj/item/rogue/instrument/accord,
		"Guitar" = /obj/item/rogue/instrument/guitar,
		"Hurdy-Gurdy" = /obj/item/rogue/instrument/hurdygurdy,
		"Viola" = /obj/item/rogue/instrument/viola,
		"Vocal Talisman" = /obj/item/rogue/instrument/vocals,
		"Psyaltery" = /obj/item/rogue/instrument/psyaltery,
		"Flute" = /obj/item/rogue/instrument/flute,
		"Drum" = /obj/item/rogue/instrument/drum,
		"Shamisen" = /obj/item/rogue/instrument/shamisen,
	)
	var/choice = tgui_input_list(caster, "Choose a musical instrument.", "Summon Instrument", instruments)
	if(!choice)
		return FALSE
	formula_magic_clear_conjured_types(caster, list(/obj/item/rogue/instrument))
	var/instrument_type = instruments[choice]
	var/obj/item/rogue/instrument/R = new instrument_type(caster.drop_location())
	R.AddComponent(/datum/component/conjured_item, GLOW_COLOR_ARCANE, FALSE, caster, null)
	caster.put_in_hands(R)
	caster.visible_message(span_notice("[caster] conjures [R] from ringing arcyne wire."))
	return TRUE

/proc/formula_magic_clear_conjured_types(mob/living/carbon/human/caster, list/type_list)
	if(!caster || !length(type_list))
		return
	for(var/obj/item/I in caster.GetAllContents())
		if(!I.GetComponent(/datum/component/conjured_item))
			continue
		if(!is_type_in_list(I, type_list))
			continue
		I.visible_message(span_warning("[I] shimmers and fades away!"))
		qdel(I)

/proc/resolve_formula_magic_single_form(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, form_id, turf/target, atom/guidance_start, atom/cast_on)
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
				target = formula_magic_limited_target_from_caster(caster, target, formula_magic_form_repeat_range(formula, FORMULA_FORM_INSTANT, 3))
				do_teleport(caster, target, channel = TELEPORT_CHANNEL_MAGIC)
				playsound(source, 'sound/magic/blink.ogg', 60, TRUE)
				resolve_formula_magic_departure_effect(caster, formula, source)
				caster.visible_message(span_notice("[caster] folds through space."), span_notice("I step through the formula."))
				return TRUE
			return resolve_formula_magic_moment(caster, formula, target, cast_on)
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
			return resolve_formula_magic_summon(caster, formula, target, cast_on)
	return FALSE

/proc/formula_magic_form_counts(datum/formula_magic_formula/formula)
	var/list/result = list()
	for(var/form_id in formula?.forms)
		result[form_id] = (result[form_id] || 0) + 1
	return result

/proc/formula_magic_consume_form_pair_count(list/form_counts, first_form, second_form)
	if(!form_counts || (form_counts[first_form] || 0) <= 0 || (form_counts[second_form] || 0) <= 0)
		return 0
	var/pair_count = min(form_counts[first_form] || 0, form_counts[second_form] || 0)
	form_counts[first_form] -= pair_count
	form_counts[second_form] -= pair_count
	return pair_count

/proc/formula_magic_uncombined_form_type_count(list/form_counts)
	var/form_type_count = 0
	for(var/form_id in form_counts)
		if((form_counts[form_id] || 0) > 0)
			form_type_count++
	return form_type_count

/proc/formula_magic_combo_offset_target(turf/target, index)
	if(!target || index <= 1)
		return target
	var/list/offset_dirs = list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
	var/offset_dir = offset_dirs[((index - 2) % length(offset_dirs)) + 1]
	var/ring = round((index - 2) / length(offset_dirs)) + 1
	var/turf/current = target
	for(var/i in 1 to ring)
		if(current)
			current = get_step(current, offset_dir)
	return current || target

/proc/resolve_formula_magic_moment(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target, atom/cast_on)
	if(!caster || !formula || !target)
		return FALSE
	target = formula_magic_limited_target_from_caster(caster, target, formula_magic_form_repeat_range(formula, FORMULA_FORM_INSTANT, 3))
	var/list/summary = formula.get_summary()
	var/mob/living/point_target = formula_magic_moment_target(caster, target, cast_on)
	var/list/summary_tags = summary["tags"] || list()
	if(point_target && !summary["radius"] && !summary_tags["widen_amount"])
		var/turf/point_turf = get_turf(point_target)
		summary["single_target"] = point_target
		if((FORMULA_SCHOOL_KINESIS in formula.schools) || (FORMULA_SCHOOL_DISPLACEMENT in formula.schools))
			resolve_formula_magic_area_effect(caster, summary, point_turf)
		else
			new /obj/effect/temp_visual/spell_impact(point_turf, formula_magic_color_for_summary(summary), SPELL_IMPACT_LOW)
			addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(resolve_formula_magic_area_effect), caster, summary, point_turf), 1 SECONDS)
		return TRUE
	if((FORMULA_SCHOOL_KINESIS in formula.schools) || (FORMULA_SCHOOL_DISPLACEMENT in formula.schools))
		return resolve_formula_magic_area_effect(caster, summary, target)
	new /obj/effect/temp_visual/spell_impact(target, formula_magic_color_for_summary(summary), SPELL_IMPACT_LOW)
	addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(resolve_formula_magic_area_effect), caster, summary, target), 1 SECONDS)
	return TRUE

/proc/formula_magic_moment_target(mob/living/carbon/human/caster, turf/target, atom/cast_on)
	if(isliving(cast_on))
		return cast_on
	if(!target)
		return null
	for(var/mob/living/L in target)
		if(L == caster)
			continue
		return L
	return null

/proc/formula_magic_form_repeat_range(datum/formula_magic_formula/formula, form_id, base_range)
	var/repeats = 0
	for(var/current_form_id in formula?.forms)
		if(current_form_id == form_id)
			repeats++
	return max(1, (base_range || 1) + max(0, repeats - 1))

/proc/formula_magic_limited_target_from_caster(mob/living/carbon/human/caster, turf/target, max_distance)
	var/turf/source = get_turf(caster)
	if(!source || !target)
		return target
	max_distance = max(1, max_distance || 1)
	if(get_dist(source, target) <= max_distance)
		return target
	var/list/line = getline(source, target)
	if(length(line) > max_distance + 1)
		return line[max_distance + 1]
	var/limited_dir = get_dir(source, target) || caster.dir
	return get_step(source, limited_dir) || source

/proc/resolve_formula_magic_departure_effect(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/source)
	if(!caster || !formula || !source)
		return FALSE
	var/list/summary = formula.get_summary()
	var/list/source_tags = summary["tags"] || list()
	var/list/tags = source_tags.Copy()
	tags -= "teleport"
	tags -= "self"
	tags -= "persistent"
	if(!formula_magic_has_pulse_payload(tags) && !tags["metal"] && !tags["weapon"] && !tags["cut"] && !tags["blade_field"] && !tags["repair"] && !tags["bone"])
		return FALSE
	summary["tags"] = tags
	summary["radius"] = max(0, min(summary["radius"] || 0, 2))
	if(tags["metal"] && !tags["damage_blunt"] && !tags["damage_force"])
		tags["damage_blunt"] = 1
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
	var/list/wave_summary = formula_magic_summary_with_radius(formula.get_summary(), 0)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(progressive_formula_magic_wave), caster, wave_summary, turfs, wave_dir, max(0, formula.tags["wave_width"] || 0))
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
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(progressive_formula_magic_dragon_breath), caster, breath_summary, max(1, min(formula.range, 8)), max(3 SECONDS, formula.duration || 3 SECONDS))
	return TRUE

/proc/progressive_formula_magic_dragon_breath(mob/living/carbon/human/caster, list/summary, breath_range, breath_duration)
	if(!caster || !summary)
		return FALSE
	var/duration = max(1, breath_duration || 3 SECONDS)
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
	var/rune_spread = formula.tags["rune_spread"] || 0
	if(rune_spread > 0)
		if(target)
			result += target
		var/list/spread_dirs = list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
		for(var/spread_dir in spread_dirs)
			for(var/distance in 1 to rune_spread)
				var/turf/T = target
				for(var/i in 1 to distance)
					if(T)
						T = get_step(T, spread_dir)
				if(T)
					result |= T
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
	var/line_dir = get_dir(start, end) || caster.dir
	var/line_width = max(0, formula.tags["guidance_width"] || 0)
	new /obj/effect/temp_visual/formula_magic_zone(start, formula_magic_color_for_summary(summary), "formula_guidance", 12)
	new /obj/effect/temp_visual/formula_magic_zone(end, formula_magic_color_for_summary(summary), "formula_guidance", 12)
	for(var/turf/T in getline(start, end))
		if(!T || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/list/line_turfs = formula_magic_wave_step_turfs(T, line_dir, line_width)
		for(var/turf/line_turf in line_turfs)
			if(!line_turf || line_turf.is_blocked_turf(exclude_mobs = TRUE))
				continue
			new /obj/effect/temp_visual/formula_magic_zone(line_turf, formula_magic_color_for_summary(summary), "formula_guidance", 6)
			resolve_formula_magic_area_effect(caster, line_summary, line_turf, hit_list)
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
		caster.apply_status_effect(/datum/status_effect/buff/formula_magic_nondetection, duration)
	if(tags["temporal_acceleration"] || tags["temporal_deceleration"] || tags["temporal_restore"] || tags["temporal_reversion"] || tags["time"])
		formula_magic_apply_chronomancy_payload(caster, caster, formula.get_summary())
	var/list/resists = list()
	if(tags["damage_burn"])
		resists["fire"] = min(0.9, 0.1 * tags["damage_burn"])
	if(tags["damage_cold"])
		resists["cold"] = min(0.9, 0.1 * tags["damage_cold"])
	if(tags["damage_shock"])
		resists["shock"] = min(0.9, 0.1 * tags["damage_shock"])
	if(tags["damage_blunt"] || tags["damage_force"])
		resists["physical"] = min(0.9, 0.1 * max(tags["damage_blunt"] || 0, tags["damage_force"] || 0))
	if(tags["metal"])
		resists["physical"] = max(resists["physical"] || 0, min(0.9, 0.1 * tags["metal"]))
	if(length(resists))
		caster.apply_status_effect(/datum/status_effect/buff/formula_magic_elemental_aura, resists, duration)
	if(tags["metal"])
		caster.visible_message(span_notice("[caster] shapes a protective iron ring around themselves."))
	new /obj/effect/temp_visual/spell_impact(get_turf(caster), formula_magic_color_for_summary(formula.get_summary()), SPELL_IMPACT_MEDIUM)
	caster.visible_message(span_notice("[caster] is wrapped in a formula aura."))
	return TRUE

/proc/resolve_formula_magic_cloak(mob/living/carbon/human/caster, datum/formula_magic_formula/formula)
	if(!caster || !formula)
		return FALSE
	var/duration = max(30, formula.duration || 30)
	if(formula.tags["metal"])
		var/list/resists = list("physical" = min(0.9, 0.15 * formula.tags["metal"]))
		caster.apply_status_effect(/datum/status_effect/buff/formula_magic_elemental_aura, resists, duration)
		new /obj/effect/temp_visual/spell_impact(get_turf(caster), formula_magic_color_for_summary(formula.get_summary()), SPELL_IMPACT_MEDIUM)
		caster.visible_message(span_notice("[caster]'s skin hardens into a dragon-hide formula cloak."))
		return TRUE
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
	if(tags["damage_arcane"] || tags["damage_burn"] || tags["ignite"] || tags["damage_cold"] || tags["frost_stack"] || tags["damage_shock"] || tags["electrocute"] || tags["damage_blunt"] || tags["damage_force"] || tags["metal"] || tags["bone"] || tags["blade_field"] || tags["shrapnel"] || tags["push"] || tags["pull"] || tags["gravity"] || tags["cleanse"] || tags["shift_target"] || tags["anchor_target"] || tags["dirt"] || tags["silence"] || tags["repair"] || tags["mind"] || tags["time"] || tags["temporal_acceleration"] || tags["temporal_deceleration"] || tags["temporal_restore"] || tags["temporal_reversion"])
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
		if(formula.tags["orb_seeker"])
			bolt.speed = 1.1 + (0.2 * max(0, (formula.tags["orb_seeker"] || 1) - 1))
			bolt.homing_turn_speed = 25 + (10 * max(0, (formula.tags["orb_seeker"] || 1) - 1))
			var/atom/seeker_target = formula.tags["orb_seeker_target"] || formula_magic_nearest_target_to_point(caster, get_turf(target), 7)
			if(seeker_target)
				bolt.set_homing_target(seeker_target)
		bolt.preparePixelProjectile(target, caster, null, start_spread + ((i - 1) * spread_step))
		bolt.fire()
	return TRUE

/proc/resolve_formula_magic_summon(mob/living/carbon/human/caster, datum/formula_magic_formula/formula, turf/target, atom/cast_on)
	if(!caster || !formula)
		return FALSE
	if(!target)
		target = get_turf(caster)
	if(formula.tags["damage_burn"])
		if(formula.tags["creation"])
			return formula_magic_summon_primordial(caster, target, /mob/living/simple_animal/hostile/retaliate/rogue/primordial/fire)
		if(target && !locate(/obj/machinery/light/rogue/campfire/create_campfire) in target)
			new /obj/machinery/light/rogue/campfire/create_campfire(target)
			caster.visible_message(span_notice("[caster] calls a temporary campfire into being."))
			return TRUE
	if(formula.tags["ignite"])
		new /obj/effect/temp_visual/fire(target)
		target.fire_act()
		caster.visible_message(span_notice("[caster] summons a brief burning tile."))
		return TRUE
	if(formula.tags["damage_cold"] && formula.tags["frost_stack"])
		var/list/mist_summary = formula.get_summary()
		var/mist_radius = max(1, formula.radius || 1)
		var/mist_duration = max(10 SECONDS, mist_summary["duration"] || 10 SECONDS)
		mist_summary["tags"]["existence_duration"] = mist_duration
		formula_magic_create_lingering_zones(caster, mist_summary, target, mist_radius)
		caster.visible_message(span_notice("[caster] summons a frozen mist."))
		return TRUE
	if(formula.tags["damage_cold"])
		if(formula.tags["creation"])
			return formula_magic_summon_primordial(caster, target, /mob/living/simple_animal/hostile/retaliate/rogue/primordial/water)
		var/atom/chill_target = formula_magic_chill_container_target(cast_on)
		if(!chill_target)
			to_chat(caster, span_warning("The frost-summon formula needs a container to chill."))
			return FALSE
		var/obj/effect/formula_magic_fridge/fridge = new(chill_target)
		fridge.setup_formula_fridge(chill_target, max(60 SECONDS, formula.duration || 5 MINUTES))
		caster.visible_message(span_notice("[caster] wraps [chill_target] in a temporary cryomantic chill."))
		return TRUE
	if(formula.tags["frost_stack"])
		new /obj/effect/temp_visual/snap_freeze(target)
		caster.visible_message(span_notice("[caster] freezes the ground into brittle ice."))
		return TRUE
	if(formula.tags["blade_field"])
		new /obj/effect/formula_magic_blade_field(target, caster, max(1, round(formula.power * 0.35)), max(10 SECONDS, formula.duration || 10 SECONDS), formula.radius || 0)
		caster.visible_message(span_warning("[caster] plants a spinning formula blade."))
		return TRUE
	if(formula.tags["damage_shock"])
		if(formula.tags["creation"])
			return formula_magic_summon_primordial(caster, target, /mob/living/simple_animal/hostile/retaliate/rogue/primordial/air)
		new /obj/effect/formula_magic_light(target, formula_magic_color_for_summary(formula.get_summary()), max(30 SECONDS, formula.duration || 60 SECONDS))
		caster.visible_message(span_notice("[caster] binds a small formula light."))
		return TRUE
	if(formula.tags["electrocute"])
		new /obj/effect/temp_visual/small_smoke(target)
		caster.visible_message(span_notice("[caster] summons a smoking discharge mark."))
		return TRUE
	if(formula.tags["dirt"])
		var/existence_words = max(0, formula.tags["existence"] || 0)
		if(existence_words > 0)
			var/obj/structure/earthen_wall/formula/wall = new(target)
			var/wall_integrity = 150 + (existence_words * 50)
			wall.setup_formula_earthen_wall(max(30 SECONDS, formula.duration || 60 SECONDS), wall_integrity)
			caster.visible_message(span_notice("[caster] hardens formula mud into a temporary wall."))
		else
			var/obj/effect/formula_magic_dirt/dirt = new(target)
			dirt.setup_formula_dirt(max(10 SECONDS, formula.duration || 30 SECONDS), max(1, formula.tags["dirt"] || 1))
			caster.visible_message(span_notice("[caster] churns the ground into formula mud."))
		return TRUE
	if(formula.tags["anchor_target"])
		resolve_formula_magic_area_effect(caster, formula.get_summary(), target)
		caster.visible_message(span_notice("[caster] anchors the target space."))
		return TRUE
	if(formula.tags["ratmouse"])
		return formula_magic_spawn_ratmouse(caster, target, max(10 SECONDS, formula.duration || 30 SECONDS))
	if(formula.tags["damage_blunt"])
		var/count = max(1, formula.tags["damage_blunt"] || 1)
		for(var/i in 1 to count)
			var/obj/item/rogueweapon/magicbrick/brick = new(caster.drop_location())
			brick.name = "formula brick"
			brick.desc = "A temporary brick shaped from spoken stone."
			brick.force = max(brick.force, round(formula.power / 2))
			brick.throwforce = max(brick.throwforce, formula.power)
			brick.AddComponent(/datum/component/conjured_item, null, FALSE, caster, null)
			if(i == 1)
				caster.put_in_hands(brick)
		caster.visible_message(span_notice("[caster] summons [count] formula brick[count == 1 ? "" : "s"]."))
		return TRUE
	if(formula.tags["creation"])
		var/creation_words = max(1, formula.tags["creation"] || 1)
		var/obj/structure/flora/roguegrass/maneater/real/juvenile/maneater = new(target)
		maneater.planter = caster
		QDEL_IN(maneater, creation_words * 10 SECONDS)
		caster.visible_message(span_notice("[caster] gives a formula a brief man-eater shape."))
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
	var/obj/structure/formula_magic_wall/wall = new(target)
	wall.setup_formula_wall("#C000FF", max(30 SECONDS, formula.duration || 60 SECONDS))
	caster.visible_message(span_notice("[caster] summons an arcyne wall."))
	return TRUE

/proc/formula_magic_chill_container_target(atom/cast_on)
	if(!cast_on)
		return null
	if(istype(cast_on, /obj/item/storage) || istype(cast_on, /obj/structure/closet))
		return cast_on
	return null

/proc/resolve_formula_magic_area_effect(mob/living/carbon/human/caster, list/summary, turf/center, list/shared_hit_list)
	if(!center || !summary)
		return FALSE
	var/list/tags = summary["tags"] || list()
	var/power = summary["power"] || 10
	var/radius = max(0, summary["radius"] || 0)
	var/effective_radius = min(radius, 16)
	var/effect_color = formula_magic_color_for_summary(summary)
	var/skip_center_visual = summary["skip_center_visual"]
	var/mob/living/single_target = summary["single_target"]

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
	if(!skip_center_visual && tags["bone"])
		new /obj/effect/temp_visual/spell_impact(center, "#6B6B6B", SPELL_IMPACT_MEDIUM)
	if(!skip_center_visual && tags["gravity"])
		new /obj/effect/temp_visual/gravity(center)
	if(!skip_center_visual && tags["cleanse"])
		new /obj/effect/temp_visual/cleaning_pulse(center)
	if(!skip_center_visual && (tags["time"] || tags["temporal_acceleration"] || tags["temporal_deceleration"] || tags["temporal_restore"] || tags["temporal_reversion"]))
		new /obj/effect/temp_visual/origin_restoration(center)

	var/list/hit_targets = list()
	for(var/turf/T in range(effective_radius, center))
		if(T != center)
			new /obj/effect/temp_visual/spell_impact(T, effect_color, SPELL_IMPACT_LOW)
		if(tags["cleanse"])
			formula_magic_cleanse_turf(T)
		if(tags["blade_field"])
			new /obj/effect/formula_magic_blade_field(T, caster, max(1, round(power * 0.35)), max(10 SECONDS, summary["duration"] || 10 SECONDS), 0)
		if(tags["extinguish"])
			formula_magic_extinguish_turf(T)
		if(tags["ignite"])
			new /obj/effect/temp_visual/fire(T)
			T.fire_act()
		else if(tags["damage_burn"])
			new /obj/effect/temp_visual/spell_impact(T, "#FF5A1F", SPELL_IMPACT_LOW)
		if(tags["damage_cold"] || tags["frost_stack"])
			new /obj/effect/temp_visual/snap_freeze(T)
		if(tags["damage_arcane"])
			new /obj/effect/temp_visual/spell_impact(T, "#B7B3FF", SPELL_IMPACT_LOW)
		if(tags["bone"])
			new /obj/effect/temp_visual/spell_impact(T, "#6B6B6B", SPELL_IMPACT_LOW)
		if(tags["gravity"])
			new /obj/effect/temp_visual/gravity(T)
		if(tags["cleanse"] && T != center)
			new /obj/effect/temp_visual/cleaning_pulse(T)
		if(tags["time"] || tags["temporal_acceleration"] || tags["temporal_deceleration"] || tags["temporal_restore"] || tags["temporal_reversion"])
			new /obj/effect/temp_visual/spell_impact(T, "#66FFCC", SPELL_IMPACT_LOW)
		if(tags["ratmouse"])
			formula_magic_spawn_ratmouse(caster, T, max(10 SECONDS, summary["duration"] || 30 SECONDS))

		for(var/mob/living/L in T)
			if(single_target && L != single_target)
				continue
			if(shared_hit_list && (L in shared_hit_list))
				continue
			if(shared_hit_list)
				shared_hit_list |= L
			if(L == caster && !(tags["buff"] || tags["self"]))
				continue
			hit_targets |= L
			if(tags["damage_arcane"])
				formula_magic_apply_damage(L, max(1, power), BRUTE)
			if(tags["damage_burn"])
				formula_magic_apply_damage(L, max(1, round(power * 0.6)), BURN)
			if(tags["ignite"])
				var/ignite_words = max(1, tags["ignite"] || 1)
				var/applied_ignite = FALSE
				for(var/i in 1 to ignite_words)
					if(!formula_magic_stack_chance_succeeds(summary))
						continue
					L.adjust_fire_stacks(1)
					applied_ignite = TRUE
				if(applied_ignite)
					L.ignite_mob()
			if(tags["damage_cold"] || tags["frost_stack"])
				formula_magic_apply_damage(L, max(1, round(power * 0.35)), BURN)
				if(tags["extinguish"] && L.on_fire)
					L.adjust_fire_stacks(-1)
					L.visible_message(span_warning("The frost dampens the flames on [L]!"))
				if(tags["frost_stack"] && formula_magic_stack_chance_succeeds(summary))
					apply_frost_stack(L)
			if(tags["damage_shock"])
				L.electrocute_act(max(1, round(power * 0.45)), caster, 1, SHOCK_NOSTUN)
			if(tags["electrocute"] && formula_magic_stack_chance_succeeds(summary))
				L.electrocute_act(1, caster, 1, SHOCK_NOSTUN)
			if(tags["anchor_target"] && formula_magic_stack_chance_succeeds(summary))
				L.apply_status_effect(STATUS_EFFECT_IMMOBILIZED, max(1 SECONDS, tags["anchor_target"] * 2 SECONDS))
				new /obj/effect/temp_visual/gravity(get_turf(L))
			if(tags["dirt"] && formula_magic_stack_chance_succeeds(summary))
				var/dirt_words = max(1, tags["dirt"] || 1)
				L.Slowdown(3 + ((dirt_words - 1) * 3))
				new /obj/effect/temp_visual/spell_impact(get_turf(L), "#7A5B35", SPELL_IMPACT_LOW)
			if(tags["damage_blunt"] || tags["damage_force"])
				formula_magic_apply_damage(L, max(1, round(power * 0.5)), BRUTE)
			if(tags["metal"])
				formula_magic_apply_iron_armor_damage(L, 15 * max(1, tags["metal"] || 1), caster?.zone_selected || BODY_ZONE_CHEST)
			if(tags["bone"] && !tags["ratmouse"])
				formula_magic_apply_damage(L, max(1, power + 10), BRUTE)
			if(tags["shrapnel"])
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
			if(tags["softfall"])
				L.apply_status_effect(/datum/status_effect/buff/featherfall)
			if(tags["mind"])
				if(tags["self"] || L == caster)
					to_chat(L, span_notice("A formula opens a quiet thread of thought."))
				else
					L.confused = max(L.confused, max(1, tags["mind"]) * 2 SECONDS)
					L.do_jitter_animation(3)
					to_chat(L, span_warning("A brief formula whisper tangles my thoughts."))
			if(tags["size_down"])
				L.add_filter("formula_size_down", 2, list("type" = "outline", "color" = "#2F80FF", "alpha" = 35, "size" = 1))
				addtimer(CALLBACK(L, TYPE_PROC_REF(/atom/movable, remove_filter), "formula_size_down"), max(10 SECONDS, min(60 SECONDS, power * 2)))
			if(tags["size_up"])
				L.add_filter("formula_size_up", 2, list("type" = "outline", "color" = "#8A8A8A", "alpha" = 40, "size" = 2))
				addtimer(CALLBACK(L, TYPE_PROC_REF(/atom/movable, remove_filter), "formula_size_up"), max(10 SECONDS, min(60 SECONDS, power * 2)))
			if(tags["time"] || tags["temporal_acceleration"] || tags["temporal_deceleration"] || tags["temporal_restore"] || tags["temporal_reversion"])
				formula_magic_apply_chronomancy_payload(caster, L, summary)

		if(tags["repair"])
			formula_magic_repair_atoms(caster, T, power)

	if(tags["chain"])
		resolve_formula_magic_chain(caster, summary, center, hit_targets, tags["chain"])
	if(tags["ricochet"])
		resolve_formula_magic_ricochet(caster, summary, center, tags["ricochet"])
	if(tags["recall"])
		formula_magic_schedule_recall(caster, summary, center, effective_radius, tags["recall"])
	if(tags["shrapnel"])
		formula_magic_release_shrapnel(caster, summary, center, tags["shrapnel"])
	formula_magic_create_lingering_zones(caster, summary, center, effective_radius)
	if(!summary["silent"])
		center.visible_message(span_warning("A spoken formula resolves at [center]."))
	return TRUE

/proc/formula_magic_extinguish_turf(turf/T)
	if(!T)
		return
	for(var/obj/O in T.contents)
		O.extinguish()
	var/obj/effect/hotspot/hotspot = (locate(/obj/effect/hotspot) in T)
	if(hotspot)
		new /obj/effect/temp_visual/small_smoke(T)
		qdel(hotspot)

/proc/formula_magic_cleanse_turf(turf/T)
	if(!T)
		return
	wash_atom(T, CLEAN_MEDIUM)
	for(var/atom/A in T)
		if(istype(A, /obj/effect/decal/cleanable) || ismob(A) || (isobj(A) && !istype(A, /obj/effect)))
			wash_atom(A, CLEAN_MEDIUM)

/proc/formula_magic_schedule_recall(mob/living/carbon/human/caster, list/summary, turf/center, radius, recall_count)
	if(!center || !summary)
		return
	var/repeats = max(0, recall_count || 0) * 3
	if(repeats <= 0)
		return
	var/list/candidates = list()
	var/effective_radius = min(max(0, radius || 0), 16)
	for(var/turf/T in range(effective_radius, center))
		if(!T || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		candidates += T
	if(!length(candidates))
		return
	var/list/recall_summary = formula_magic_secondary_summary(summary)
	var/list/recall_tags = recall_summary["tags"] || list()
	recall_tags -= "recall"
	recall_summary["tags"] = recall_tags
	recall_summary["radius"] = 0
	recall_summary["silent"] = TRUE
	recall_summary["power"] = max(1, round((recall_tags["pre_widen_power"] || summary["power"] || 10) * 0.35))
	var/list/selected = list()
	while(length(selected) < repeats && length(candidates))
		var/turf/picked_turf = pick(candidates)
		selected += picked_turf
		candidates -= picked_turf
	var/delay = 4
	for(var/turf/selected_turf in selected)
		addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(formula_magic_recall_strike), caster, recall_summary, selected_turf), delay)
		delay += 4

/proc/formula_magic_recall_strike(mob/living/carbon/human/caster, list/summary, turf/target)
	if(!target || !summary)
		return
	new /obj/effect/temp_visual/spell_impact(target, formula_magic_color_for_summary(summary), SPELL_IMPACT_LOW)
	resolve_formula_magic_area_effect(caster, summary, target)

/proc/formula_magic_release_shrapnel(mob/living/carbon/human/caster, list/summary, turf/source, shrapnel_count)
	if(!caster || !summary || !source)
		return
	var/shard_count = max(0, shrapnel_count || 0) * 3
	if(shard_count <= 0)
		return
	var/list/shard_summary = formula_magic_secondary_summary(summary)
	var/list/shard_tags = shard_summary["tags"] || list()
	shard_tags -= "shrapnel"
	shard_summary["tags"] = shard_tags
	shard_summary["radius"] = 0
	shard_summary["power"] = max(1, round((summary["power"] || 10) * 0.4))
	shard_summary["range"] = max(3, min(summary["range"] || 7, 7))
	for(var/i in 1 to shard_count)
		var/angle = rand(0, 359)
		formula_magic_fire_summary_bolt(caster, shard_summary, source, null, angle)

/proc/formula_magic_create_lingering_zones(mob/living/carbon/human/caster, list/summary, turf/center, radius)
	if(!center || !summary)
		return
	var/list/tags = summary["tags"] || list()
	var/existence_duration = tags["existence_duration"] || 0
	if(existence_duration <= 0)
		return
	var/effective_radius = min(max(0, radius || 0), 16)
	for(var/turf/T in range(effective_radius, center))
		if(!T || T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		var/obj/effect/formula_magic_lingering_zone/zone = new(T)
		zone.setup_formula_zone(caster, summary, existence_duration)

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
	tags -= "shrapnel"
	tags -= "orb_carrier"
	tags -= "orb_carrier_summaries"
	tags -= "orb_sequence_chase"
	tags -= "orb_seeker"
	tags -= "orb_seeker_target"
	result["tags"] = tags
	return result

/proc/formula_magic_summary_with_radius(list/summary, new_radius)
	var/list/result = summary.Copy()
	result["radius"] = max(0, new_radius || 0)
	return result

/proc/formula_magic_color_for_summary(list/summary)
	var/list/tags = summary?["tags"] || list()
	var/list/schools = summary?["schools"] || list()
	if(tags["bone"])
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
	if(FORMULA_SCHOOL_BIOMANCY in schools)
		return "#75D86F"
	if(FORMULA_SCHOOL_NECROMANCY in schools)
		return "#6B6B6B"
	if(FORMULA_SCHOOL_CHRONOMANCY in schools)
		return "#66FFCC"
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
	if(tags["cleanse"])
		return "#E8F4FF"
	if(tags["teleport"] || tags["phase"] || tags["shift_target"] || tags["anchor_target"])
		return "#5B1A8E"
	if(tags["metal"] || tags["weapon"] || tags["blade_field"])
		return "#36B36A"
	if(tags["curse"] || tags["curse_blindness"])
		return "#8A8A8A"
	if(tags["creation"])
		return "#75D86F"
	if(tags["bone"])
		return "#6B6B6B"
	if(tags["time"] || tags["temporal_acceleration"] || tags["temporal_deceleration"] || tags["temporal_restore"] || tags["temporal_reversion"])
		return "#66FFCC"
	return "#C000FF"

/proc/formula_magic_apply_damage(mob/living/target, amount, damagetype)
	if(!target || amount <= 0)
		return
	target.apply_damage(amount, damagetype, forced = TRUE)

/proc/formula_magic_apply_iron_armor_damage(mob/living/target, amount, zone = BODY_ZONE_CHEST)
	if(!target || amount <= 0)
		return
	if(!ishuman(target))
		formula_magic_apply_damage(target, amount, BRUTE)
		return
	var/mob/living/carbon/human/human_target = target
	var/list/layers = human_target.get_best_worn_armor_layered(zone || BODY_ZONE_CHEST, "blunt")
	var/damaged_layer = FALSE
	for(var/obj/item/clothing/armor_piece as anything in layers)
		if(QDELETED(armor_piece) || !armor_piece.max_integrity || armor_piece.obj_integrity <= 0)
			continue
		armor_piece.take_damage(amount, BRUTE, "blunt", sound_effect = FALSE, armor_penetration = 100)
		damaged_layer = TRUE
	if(!damaged_layer)
		formula_magic_apply_damage(human_target, amount, BRUTE)
	else
		new /obj/effect/temp_visual/soundbreaker_fx/note_shatter(get_turf(human_target))

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

/proc/formula_magic_apply_chronomancy_payload(mob/living/carbon/human/caster, mob/living/target, list/summary)
	if(!target || !summary)
		return FALSE
	var/list/tags = summary["tags"] || list()
	var/power = summary["power"] || 10
	if(tags["temporal_acceleration"] && formula_magic_stack_chance_succeeds(summary))
		var/duration = max(2 SECONDS, min(8 SECONDS, (2 + tags["temporal_acceleration"]) SECONDS))
		if(!target.has_status_effect(/datum/status_effect/buff/accel) && !target.has_status_effect(/datum/status_effect/buff/attune_haste))
			target.apply_status_effect(/datum/status_effect/buff/accel, duration)
			target.visible_message(span_blue("Origin formulae throw [target]'s body ahead of the present."))
	if(tags["temporal_deceleration"] && formula_magic_stack_chance_succeeds(summary))
		var/duration = max(2 SECONDS, min(8 SECONDS, (2 + tags["temporal_deceleration"]) SECONDS))
		target.apply_status_effect(/datum/status_effect/debuff/decel, duration)
		target.visible_message(span_warning("Origin formulae drag [target]'s body behind the present."))
	if(tags["temporal_restore"] && formula_magic_stack_chance_succeeds(summary))
		formula_magic_temporal_restore(caster, target, power)
	if(tags["temporal_reversion"] && formula_magic_stack_chance_succeeds(summary))
		var/duration = max(5 SECONDS, min(25 SECONDS, (8 + tags["temporal_reversion"] * 4) SECONDS))
		target.apply_status_effect(/datum/status_effect/buff/formula_magic_reversion_mark, get_turf(target), duration)
		target.visible_message(span_purple("Origin formulae mark [target]'s present state."))
	if(tags["time"] && !tags["temporal_acceleration"] && !tags["temporal_deceleration"] && !tags["temporal_restore"] && !tags["temporal_reversion"])
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.add_stress(/datum/stressevent/formula_magic_temporal_stress)
		target.visible_message(span_warning("Origin formulae put temporal strain on [target]."))
	return TRUE

/proc/formula_magic_prebuilt_reversion(mob/living/carbon/human/caster, atom/cast_on, datum/formula_magic_formula/formula)
	var/mob/living/target = formula_magic_prebuilt_target(caster, cast_on)
	var/list/tags = formula?.tags || list()
	var/duration = max(5 SECONDS, min(25 SECONDS, 8 SECONDS + max(1, tags["prebuilt_reversion"] || 1) * 4 SECONDS))
	target.apply_status_effect(/datum/status_effect/buff/formula_magic_reversion_mark, get_turf(target), duration)
	target.visible_message(span_purple("Origin formulae mark [target]'s present state."))
	return TRUE

/proc/formula_magic_temporal_restore(mob/living/carbon/human/caster, mob/living/target, power)
	if(!target)
		return FALSE
	if(!iscarbon(target))
		target.adjustBruteLoss(-max(1, round(power * 0.25)))
		target.adjustFireLoss(-max(1, round(power * 0.25)))
		return TRUE
	var/mob/living/carbon/C = target
	var/changed = FALSE
	if(length(C.bodyparts))
		for(var/obj/item/bodypart/BP in C.bodyparts)
			if(!BP || !length(BP.embedded_objects))
				continue
			for(var/obj/item/embedded as anything in BP.embedded_objects)
				if(!embedded)
					continue
				BP.remove_embedded_object(embedded)
				changed = TRUE
	if(length(C.simple_embedded_objects))
		for(var/obj/item/embedded as anything in C.simple_embedded_objects)
			if(!embedded)
				continue
			C.simple_remove_embedded_object(embedded)
			changed = TRUE
	if(changed)
		C.visible_message(span_info("Origin formulae undo [C]'s embedded objects."))
		return TRUE
	var/list/wounds = C.get_wounds()
	if(length(wounds))
		for(var/datum/wound/W as anything in wounds)
			if(!W || W.bleed_rate <= 0)
				continue
			W.set_bleed_rate(0)
			changed = TRUE
	if(changed)
		C.visible_message(span_info("Origin formulae reverse [C]'s bleeding."))
		return TRUE
	C.adjustBruteLoss(-max(1, round(power * 0.35)))
	C.adjustFireLoss(-max(1, round(power * 0.35)))
	C.adjustOxyLoss(-max(1, round(power * 0.2)))
	C.adjustToxLoss(-max(1, round(power * 0.2)))
	new /obj/effect/temp_visual/origin_restoration(get_turf(C))
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

/atom/movable/screen/alert/status_effect/buff/formula_magic_nondetection
	name = "Formula Nondetection"
	desc = "A formula shrouds me from divination."
	icon_state = "buff"

/datum/status_effect/buff/formula_magic_nondetection
	id = "formula_magic_nondetection"
	alert_type = /atom/movable/screen/alert/status_effect/buff/formula_magic_nondetection
	duration = 1 HOURS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/buff/formula_magic_nondetection/on_creation(mob/living/new_owner, new_duration)
	if(new_duration)
		duration = new_duration
	. = ..()

/datum/status_effect/buff/formula_magic_nondetection/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_ANTISCRYING, MAGIC_TRAIT)
	owner.add_filter("formula_nondetection", 2, list("type" = "outline", "color" = "#2F80FF", "alpha" = 25, "size" = 1))
	to_chat(owner, span_notice("I feel hidden from divination magic."))

/datum/status_effect/buff/formula_magic_nondetection/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_ANTISCRYING, MAGIC_TRAIT)
	owner.remove_filter("formula_nondetection")
	to_chat(owner, span_warning("I feel my anti-scrying shroud failing."))

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

/atom/movable/screen/alert/status_effect/debuff/formula_magic_reverse_guidance
	name = "Reverse Guidance"
	desc = "My thoughts turn against their own direction."
	icon_state = "debuff"

/datum/status_effect/debuff/formula_magic_reverse_guidance
	id = "formula_magic_reverse_guidance"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/formula_magic_reverse_guidance
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/debuff/formula_magic_reverse_guidance/on_creation(mob/living/new_owner, new_duration)
	if(new_duration)
		duration = new_duration
	. = ..()

/datum/status_effect/debuff/formula_magic_reverse_guidance/on_apply()
	. = ..()
	ADD_TRAIT(owner, TRAIT_REVERSE_GUIDANCE, MAGIC_TRAIT)
	owner.add_filter("formula_reverse_guidance", 2, list("type" = "outline", "color" = "#6F6F6F", "alpha" = 45, "size" = 1))
	to_chat(owner, span_warning("My thoughts stumble in their own wake."))

/datum/status_effect/debuff/formula_magic_reverse_guidance/on_remove()
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_REVERSE_GUIDANCE, MAGIC_TRAIT)
	owner.remove_filter("formula_reverse_guidance")
	to_chat(owner, span_notice("My thoughts find their old road again."))

/datum/stressevent/formula_magic_temporal_stress
	timer = 5 MINUTES
	stressadd = 2
	desc = span_red("My place in time feels strained.")

/atom/movable/screen/alert/status_effect/buff/formula_magic_reversion_mark
	name = "Formula Reversion"
	desc = "A formula has marked this moment of my body."
	icon_state = "buff"

/datum/status_effect/buff/formula_magic_reversion_mark
	id = "formula_magic_reversion_mark"
	alert_type = /atom/movable/screen/alert/status_effect/buff/formula_magic_reversion_mark
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	var/turf/origin
	var/brute = 0
	var/burn = 0
	var/oxy = 0
	var/toxin = 0
	var/blood = 0
	var/list/datum/wound/snapshot_wounds
	var/triggered = FALSE

/datum/status_effect/buff/formula_magic_reversion_mark/on_creation(mob/living/new_owner, turf/snapshot_turf, new_duration)
	origin = snapshot_turf || get_turf(new_owner)
	if(new_duration)
		duration = new_duration
	if(istype(new_owner, /mob/living/carbon))
		var/mob/living/carbon/C = new_owner
		brute = C.getBruteLoss()
		burn = C.getFireLoss()
		oxy = C.getOxyLoss()
		toxin = C.getToxLoss()
		blood = C.blood_volume
		snapshot_wounds = C.get_wounds()
	. = ..()

/datum/status_effect/buff/formula_magic_reversion_mark/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(handle_reversion_damage))
	owner.add_filter("formula_reversion_mark", 2, list("type" = "outline", "color" = "#66FFCC", "alpha" = 45, "size" = 1))
	to_chat(owner, span_purple("A formula anchors this moment of my body."))

/datum/status_effect/buff/formula_magic_reversion_mark/on_remove()
	. = ..()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	owner.remove_filter("formula_reversion_mark")
	origin = null
	snapshot_wounds = null

/datum/status_effect/buff/formula_magic_reversion_mark/proc/handle_reversion_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(triggered || damage <= 0)
		return
	triggered = TRUE
	addtimer(CALLBACK(src, PROC_REF(perform_formula_reversion)), 1)

/datum/status_effect/buff/formula_magic_reversion_mark/proc/perform_formula_reversion()
	if(QDELETED(src) || !owner || !origin)
		return
	var/mob/living/carbon/C = owner
	if(!istype(C))
		return
	var/turf/departure = get_turf(C)
	if(departure)
		new /obj/effect/temp_visual/origin_restoration(departure)
	do_teleport(C, origin, no_effects = TRUE)
	C.adjustBruteLoss(C.getBruteLoss() * -1 + brute)
	C.adjustFireLoss(C.getFireLoss() * -1 + burn)
	C.adjustOxyLoss(C.getOxyLoss() * -1 + oxy)
	C.adjustToxLoss(C.getToxLoss() * -1 + toxin)
	C.blood_volume = blood
	for(var/datum/wound/wound as anything in C.get_wounds())
		if(wound in snapshot_wounds)
			continue
		if(wound.bodypart_owner)
			wound.bodypart_owner.remove_wound(wound)
		else
			C.simple_remove_wound(wound)
	playsound(get_turf(C), 'sound/magic/timereverse.ogg', 80, FALSE)
	C.visible_message(span_purple("[C] snaps backward through a formula mark."))
	C.remove_status_effect(/datum/status_effect/buff/formula_magic_reversion_mark)

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
	var/list/orb_carrier_hit_atoms = list()

/obj/projectile/magic/formula_magic_bolt/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(out_of_effective_range())
		return
	var/mob/living/carbon/human/caster
	if(istype(firer, /mob/living/carbon/human))
		caster = firer
	var/turf/impact = get_turf(target)
	if(impact && formula_summary)
		var/list/impact_summary = formula_magic_secondary_summary(formula_summary)
		resolve_formula_magic_area_effect(caster, impact_summary, impact)
		formula_magic_resolve_projectile_followups(caster, formula_summary, impact, Angle, target)
		formula_magic_resolve_next_sequence_segment(caster, formula_summary, impact)
	var/list/tags = formula_summary?["tags"] || list()
	if(tags["orb_sequence_chase"] && target == homing_target)
		return BULLET_ACT_HIT
	if(pierce_remaining > 0 && isliving(target))
		pierce_remaining--
		return BULLET_ACT_FORCE_PIERCE
	return BULLET_ACT_HIT

/proc/formula_magic_resolve_projectile_followups(mob/living/carbon/human/caster, list/summary, turf/impact, impact_angle, atom/hit_atom)
	if(!caster || !summary || !impact)
		return
	var/list/tags = summary["tags"] || list()
	if(tags["chain"])
		var/list/chain_summary = formula_magic_summary_with_reduced_tag(summary, "chain")
		var/mob/living/next_target = formula_magic_nearest_chain_target(caster, impact, hit_atom)
		if(next_target)
			formula_magic_fire_summary_bolt(caster, chain_summary, impact, next_target)
	if(tags["ricochet"])
		var/list/ricochet_summary = formula_magic_summary_with_reduced_tag(summary, "ricochet")
		var/new_angle = SIMPLIFY_DEGREES((impact_angle || 0) + pick(120, 240))
		formula_magic_fire_summary_bolt(caster, ricochet_summary, impact, null, new_angle)

/proc/formula_magic_nearest_chain_target(mob/living/carbon/human/caster, turf/source, atom/exclude)
	var/mob/living/next_target
	var/best_distance = 999
	for(var/mob/living/L in view(7, source))
		if(L == caster || L == exclude)
			continue
		var/distance = get_dist(source, L)
		if(distance < best_distance)
			best_distance = distance
			next_target = L
	return next_target

/proc/formula_magic_nearest_target_to_point(mob/living/carbon/human/caster, turf/source, search_range = 7, atom/exclude)
	if(!source)
		return null
	var/mob/living/next_target
	var/best_distance = 999
	for(var/mob/living/L in view(max(1, search_range || 7), source))
		if(L == caster || L == exclude || QDELETED(L))
			continue
		var/distance = get_dist(source, L)
		if(distance < best_distance)
			best_distance = distance
			next_target = L
	return next_target

/proc/formula_magic_fire_summary_bolt(mob/living/carbon/human/caster, list/summary, turf/start, atom/target, forced_angle)
	if(!caster || !summary || !start)
		return FALSE
	var/obj/projectile/magic/formula_magic_bolt/bolt = new(start)
	bolt.firer = caster
	bolt.fired_from = start
	bolt.def_zone = caster.zone_selected
	bolt.formula_summary = summary.Copy()
	bolt.range = max(1, min(summary["range"] || 7, 14))
	bolt.max_range = bolt.range
	var/list/summary_tags = summary["tags"] || list()
	bolt.pierce_remaining = summary_tags["pierce"] || 0
	bolt.spell_impact_color = formula_magic_color_for_summary(summary)
	bolt.light_color = bolt.spell_impact_color
	bolt.icon_state = "formula_orb"
	bolt.speed = 1.1
	if(summary_tags["orb_seeker"])
		bolt.speed = 1.1 + (0.2 * max(0, (summary_tags["orb_seeker"] || 1) - 1))
		bolt.homing_turn_speed = 25 + (10 * max(0, (summary_tags["orb_seeker"] || 1) - 1))
		var/atom/seeker_target = summary_tags["orb_seeker_target"] || formula_magic_nearest_target_to_point(caster, get_turf(target) || start, 7)
		if(seeker_target)
			bolt.set_homing_target(seeker_target)
	if(target)
		bolt.preparePixelProjectile(target, start)
	else
		bolt.preparePixelProjectile(get_ranged_target_turf(start, angle2dir(forced_angle), bolt.range), start)
		bolt.setAngle(forced_angle)
	bolt.fire()
	return TRUE

/proc/formula_magic_summary_with_reduced_tag(list/summary, tag)
	var/list/result = summary.Copy()
	var/list/source_tags = summary["tags"] || list()
	var/list/tags = source_tags.Copy()
	if((tags[tag] || 0) > 1)
		tags[tag]--
	else
		tags -= tag
	result["tags"] = tags
	return result

/proc/formula_magic_resolve_next_sequence_segment(mob/living/carbon/human/caster, list/summary, turf/impact)
	if(!caster?.mind || !summary || !impact)
		return FALSE
	var/list/segments = summary["sequence_segments"]
	if(!length(segments))
		return FALSE
	var/list/next_words = segments[1]
	var/datum/formula_magic_formula/next_formula = caster.mind.build_formula_magic_formula(next_words)
	if(!next_formula)
		return FALSE
	if(length(segments) > 1)
		next_formula.sequence_segments = segments.Copy(2)
	var/result = resolve_formula_magic_effect(caster, next_formula, impact, impact)
	qdel(next_formula)
	return result

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
		if(istype(target, /obj/projectile))
			return FALSE
		var/obj/O = target
		if(O.density || istype(O, /obj/structure) || istype(O, /obj/machinery))
			return TRUE
	return ..()

/obj/projectile/magic/formula_magic_bolt/Move(atom/newloc, dir = NONE)
	. = ..()
	if(!. || QDELETED(src) || !fired || !loc)
		return
	for(var/mob/living/L in loc)
		if(formula_magic_resolve_orb_carrier_touch(L))
			continue
		if(formula_magic_should_sequence_chase_ignore(L))
			continue
		if(can_hit_target(L, permutated, L == original, TRUE))
			Bump(L)
			return
	for(var/obj/O in loc)
		if(O == src)
			continue
		if(istype(O, /obj/projectile))
			continue
		if(can_hit_target(O, permutated, O == original, TRUE))
			Bump(O)
			return

/obj/projectile/magic/formula_magic_bolt/proc/formula_magic_resolve_orb_carrier_touch(mob/living/L)
	if(!L || !formula_summary)
		return FALSE
	var/list/tags = formula_summary["tags"] || list()
	var/list/carrier_summaries = tags["orb_carrier_summaries"]
	if(!length(carrier_summaries))
		return FALSE
	if(L == firer)
		return TRUE
	if(L in orb_carrier_hit_atoms)
		return TRUE
	orb_carrier_hit_atoms |= L
	var/mob/living/carbon/human/caster
	if(istype(firer, /mob/living/carbon/human))
		caster = firer
	var/turf/touch_turf = get_turf(L)
	for(var/list/carrier_summary as anything in carrier_summaries)
		resolve_formula_magic_area_effect(caster, carrier_summary, touch_turf, list())
	if(tags["orb_sequence_chase"] && L == homing_target)
		return FALSE
	permutated |= L
	return TRUE

/obj/projectile/magic/formula_magic_bolt/proc/formula_magic_should_sequence_chase_ignore(mob/living/L)
	if(!L || !formula_summary)
		return FALSE
	var/list/tags = formula_summary["tags"] || list()
	if(!tags["orb_sequence_chase"])
		return FALSE
	if(L == homing_target)
		return FALSE
	permutated |= L
	return TRUE

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

/obj/effect/formula_magic_fridge
	name = "formula chill"
	desc = "A temporary cryomantic field bound to a container."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_aura"
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	var/atom/chill_target
	var/list/chilled_foods = list()

/obj/effect/formula_magic_fridge/proc/setup_formula_fridge(atom/new_target, lifespan)
	chill_target = new_target || loc
	if(ismovable(chill_target))
		var/atom/movable/movable_target = chill_target
		movable_target.add_filter("formula_fridge_glow", 2, list("type" = "outline", "color" = "#87CEEB", "alpha" = 120, "size" = 1))
	set_light(2, 1, 1, l_color = "#8FE8FF")
	chill_foods()
	START_PROCESSING(SSprocessing, src)
	QDEL_IN(src, max(30 SECONDS, lifespan || 5 MINUTES))

/obj/effect/formula_magic_fridge/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	if(ismovable(chill_target))
		var/atom/movable/movable_target = chill_target
		movable_target.remove_filter("formula_fridge_glow")
	chill_target = null
	chilled_foods = null
	return ..()

/obj/effect/formula_magic_fridge/process(delta_time)
	chill_foods()

/obj/effect/formula_magic_fridge/proc/chill_foods()
	if(!chill_target)
		return
	for(var/obj/item/reagent_containers/food/snacks/food in chill_target.contents)
		if(food in chilled_foods)
			continue
		if(!food.rotprocess)
			continue
		chilled_foods += food
		food.warming += 15 MINUTES
		food.add_filter("formula_chilled_food_glow", 2, list("type" = "outline", "color" = "#87CEEB", "alpha" = 120, "size" = 1))
		addtimer(CALLBACK(food, TYPE_PROC_REF(/atom/movable, remove_filter), "formula_chilled_food_glow"), 15 MINUTES)

/obj/effect/formula_magic_blade_field
	name = "formula blade"
	desc = "A spinning arcyne blade fixed in the air."
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	light_outer_range = 1
	light_color = "#36B36A"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/mob/living/carbon/human/caster
	var/tick_damage = 4
	var/effect_radius = 0
	var/list/blade_visuals = list()

/obj/effect/formula_magic_blade_field/Initialize(mapload, mob/living/carbon/human/new_caster, new_damage, lifespan, radius)
	. = ..()
	caster = new_caster
	tick_damage = max(1, new_damage || 4)
	effect_radius = max(0, min(radius || 0, 3))
	add_atom_colour("#36B36A", FIXED_COLOUR_PRIORITY)
	set_light(2, 1, 1, l_color = "#36B36A")
	INVOKE_ASYNC(src, PROC_REF(setup_visuals), max(10 SECONDS, lifespan || 10 SECONDS))
	playsound(src, 'sound/magic/scrapeblade.ogg', 50, TRUE, 4)
	START_PROCESSING(SSprocessing, src)
	QDEL_IN(src, max(10 SECONDS, lifespan || 10 SECONDS))

/obj/effect/formula_magic_blade_field/Destroy()
	QDEL_LIST(blade_visuals)
	caster = null
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/effect/formula_magic_blade_field/proc/setup_visuals(lifespan)
	var/visual_radius = max(1, effect_radius)
	for(var/dx in -visual_radius to visual_radius)
		for(var/dy in -visual_radius to visual_radius)
			if(effect_radius && max(abs(dx), abs(dy)) > effect_radius)
				continue
			if(!effect_radius && (dx || dy))
				continue
			var/obj/effect/temp_visual/spinning_dagger/D = new(null, lifespan + 1 SECONDS, FALSE)
			D.pixel_x = dx * 32
			D.pixel_y = dy * 32
			blade_visuals += D
			vis_contents += D
			D.start_spinning()

/obj/effect/formula_magic_blade_field/process(delta_time)
	var/turf/center = get_turf(src)
	if(!center)
		qdel(src)
		return
	playsound(src, pick('sound/combat/hits/bladed/genstab (1).ogg', 'sound/combat/hits/bladed/genstab (2).ogg', 'sound/combat/hits/bladed/genstab (3).ogg'), 35, TRUE)
	for(var/turf/T in range(effect_radius, center))
		for(var/mob/living/L in T.contents)
			if(L == caster)
				continue
			if(L.anti_magic_check())
				continue
			formula_magic_apply_damage(L, tick_damage, BRUTE)
			new /obj/effect/temp_visual/spell_impact(get_turf(L), "#36B36A", SPELL_IMPACT_LOW)

/obj/structure/formula_magic_wall
	name = "arcyne wall"
	desc = "A temporary wall shaped from a spoken formula."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_rune"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	max_integrity = 100

/obj/structure/formula_magic_wall/proc/setup_formula_wall(effect_color, lifespan)
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
		set_light(1, 1, 1, l_color = effect_color)
	QDEL_IN(src, max(10 SECONDS, lifespan || 60 SECONDS))

/obj/structure/earthen_wall/formula
	name = "formula earthen wall"
	timeleft = 0

/obj/structure/earthen_wall/formula/proc/setup_formula_earthen_wall(lifespan, integrity)
	max_integrity = max(1, integrity || 150)
	obj_integrity = max_integrity
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

/obj/effect/formula_magic_dirt
	name = "formula mud"
	desc = "A temporary patch of earth churned by spoken geomancy."
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

/obj/structure/formula_magic_teleport_rune
	name = "formula teleport rune"
	desc = "A permanent displacement rune fixed into the ground."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_rune"
	anchored = TRUE
	density = FALSE
	alpha = 190
	layer = ABOVE_NORMAL_TURF_LAYER
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/datum/mind/creator_mind

/obj/structure/formula_magic_teleport_rune/Destroy()
	if(creator_mind)
		creator_mind.unregister_formula_magic_teleport_rune(src)
	creator_mind = null
	. = ..()

/obj/structure/formula_magic_teleport_rune/proc/setup_formula_teleport_rune(mob/living/carbon/human/caster)
	if(!caster?.mind)
		return FALSE
	creator_mind = caster.mind
	add_atom_colour("#A040FF", FIXED_COLOUR_PRIORITY)
	set_light(1, 1, 1, l_color = "#A040FF")
	return creator_mind.register_formula_magic_teleport_rune(src)

/obj/structure/formula_magic_teleport_rune/examine(mob/user)
	. = ..()
	var/mob/living/carbon/human/H = user
	if(istype(H) && H.mind)
		H.mind.remember_formula_magic_teleport_rune(src)
		. += span_notice("The rune settles into my arcane memory.")

/obj/structure/formula_magic_teleport_rune/attack_hand(mob/user)
	. = ..()
	var/mob/living/carbon/human/H = user
	if(!istype(H) || !H.mind)
		return
	if(!H.mind.formula_magic_committed)
		to_chat(H, span_warning("I do not know how to wake this rune."))
		return
	H.mind.remember_formula_magic_teleport_rune(src)
	var/list/known_runes = H.mind.get_formula_magic_remembered_teleport_runes(src)
	if(!length(known_runes))
		H.mind.remember_formula_magic_teleport_rune(src)
		to_chat(H, span_notice("I commit this rune to memory."))
		return
	var/list/rune_choices = list()
	for(var/obj/structure/formula_magic_teleport_rune/rune as anything in known_runes)
		var/turf/T = get_turf(rune)
		if(!T)
			continue
		rune_choices["Rune at [T.x], [T.y], [T.z]"] = rune
	if(!length(rune_choices))
		to_chat(H, span_warning("No remembered rune can answer this one."))
		return
	var/choice = tgui_input_list(H, "Choose the remembered rune to travel to.", "Teleport Rune", rune_choices)
	if(!choice)
		return
	var/obj/structure/formula_magic_teleport_rune/destination = rune_choices[choice]
	if(!destination || QDELETED(destination) || destination == src)
		to_chat(H, span_warning("The chosen rune slips from memory."))
		return
	formula_magic_teleport_rune_group(H, destination)

/obj/structure/formula_magic_teleport_rune/proc/formula_magic_teleport_rune_group(mob/living/carbon/human/user, obj/structure/formula_magic_teleport_rune/destination)
	var/turf/source = get_turf(src)
	var/turf/destination_center = get_turf(destination)
	if(!source || !destination_center)
		return FALSE
	var/moved = 0
	for(var/mob/living/L in range(1, source))
		if(!L || QDELETED(L))
			continue
		var/turf/current = get_turf(L)
		if(!current)
			continue
		var/dx = current.x - source.x
		var/dy = current.y - source.y
		var/turf/landing = locate(destination_center.x + dx, destination_center.y + dy, destination_center.z)
		if(!landing || !isopenturf(landing) || landing.is_blocked_turf(exclude_mobs = FALSE))
			landing = destination_center
		if(do_teleport(L, landing, channel = TELEPORT_CHANNEL_MAGIC))
			moved++
	if(moved)
		playsound(source, 'sound/magic/teleport_diss.ogg', 80, TRUE)
		playsound(destination_center, 'sound/magic/teleport_diss.ogg', 80, TRUE)
		user.visible_message(span_notice("[user] wakes the displacement rune."))
		return TRUE
	to_chat(user, span_warning("The remembered rune rejects the passage."))
	return FALSE

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

/obj/effect/formula_magic_lingering_zone
	name = "lingering formula"
	desc = "A spoken formula lingers here as a temporary trigger."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_rune"
	anchored = TRUE
	density = FALSE
	alpha = 120
	layer = ABOVE_NORMAL_TURF_LAYER
	var/mob/living/carbon/human/caster
	var/list/formula_summary
	var/lifespan = 10 SECONDS
	var/pulse_interval = 2 SECONDS

/obj/effect/formula_magic_lingering_zone/Destroy()
	caster = null
	formula_summary = null
	. = ..()

/obj/effect/formula_magic_lingering_zone/proc/setup_formula_zone(mob/living/carbon/human/new_caster, list/new_summary, new_lifespan)
	caster = new_caster
	formula_summary = formula_magic_lingering_summary(new_summary)
	lifespan = max(1 SECONDS, new_lifespan || 10 SECONDS)
	var/effect_color = formula_magic_color_for_summary(formula_summary)
	if(effect_color)
		add_atom_colour(effect_color, FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, lifespan)
	addtimer(CALLBACK(src, PROC_REF(pulse_formula_zone)), pulse_interval)
	return TRUE

/obj/effect/formula_magic_lingering_zone/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		trigger_formula_zone(AM)

/obj/effect/formula_magic_lingering_zone/proc/pulse_formula_zone()
	if(QDELETED(src) || !formula_summary)
		return
	for(var/mob/living/L in loc)
		trigger_formula_zone(L)
	addtimer(CALLBACK(src, PROC_REF(pulse_formula_zone)), pulse_interval)

/obj/effect/formula_magic_lingering_zone/proc/trigger_formula_zone(mob/living/L)
	if(!L || !formula_summary)
		return
	resolve_formula_magic_area_effect(caster, formula_summary, get_turf(src), list())

/proc/formula_magic_lingering_summary(list/summary)
	var/list/result = formula_magic_secondary_summary(summary)
	var/list/source_tags = result["tags"] || list()
	var/list/tags = source_tags.Copy()
	tags -= "existence"
	tags -= "existence_duration"
	result["tags"] = tags
	result["radius"] = 0
	result["silent"] = TRUE
	result["skip_center_visual"] = TRUE
	return result

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
	var/triggered = FALSE

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
	if(triggered || !formula_summary)
		return
	if(caster?.mind && L?.mind == caster.mind)
		return
	triggered = TRUE
	var/list/trigger_summary = formula_magic_secondary_summary(formula_summary)
	trigger_summary["radius"] = max(0, trigger_summary["radius"] || 0)
	resolve_formula_magic_area_effect(caster, trigger_summary, get_turf(src))
	qdel(src)

/obj/structure/trap/formula_magic/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		trap_effect(AM)

#endif


/datum/mind/proc/perform_formula_magic_cast(mob/living/carbon/human/caster, list/word_ids, atom/cast_on, speak_words = TRUE, atom/guidance_start)
	if(!caster)
		return FALSE
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(word_ids)
	if(!formula || !validate_formula_magic_formula(formula, TRUE))
		qdel(formula)
		return FALSE
	var/datum/formula_magic_context/context = new
	context.caster = caster
	context.cast_on = cast_on
	context.source_turf = get_turf(caster)
	context.target_turf = get_turf(cast_on) || context.source_turf
	var/resolved = FALSE
	for(var/datum/formula_magic_part/part in formula.parts)
		if(part.execute(context))
			resolved = TRUE
	qdel(context)
	qdel(formula)
	return resolved

/proc/formula_magic_execute_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	if(!context?.caster || !part || !length(part.forms))
		return FALSE
	var/list/form_counts = formula_magic_part_form_counts(part)
	var/resolved = FALSE
	var/seeker_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_ORB, FORMULA_FORM_WAVE)
	if(seeker_count > 0 && formula_magic_cast_shape(context, part, "seeker", 1))
		resolved = TRUE
	var/breath_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_TOUCH, FORMULA_FORM_NOVA)
	if(breath_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_BREATH, 1))
		resolved = TRUE
	var/meteor_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_INSTANT, FORMULA_FORM_BEAM)
	if(meteor_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_FALL, 1))
		resolved = TRUE
	var/cloak_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_SPIRAL, FORMULA_FORM_AURA)
	if(cloak_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_CLOAK, 1))
		resolved = TRUE
	var/rune_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE)
	if(rune_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_RUNE, 1))
		resolved = TRUE
	if(formula_magic_remaining_part_form_type_count(form_counts) > 1)
		return formula_magic_detonate_formula_part(context.caster, part, "unjoined forms")
	for(var/form_id in form_counts)
		var/count = form_counts[form_id] || 0
		if(count > 0 && formula_magic_cast_shape(context, part, form_id, 1))
			resolved = TRUE
	return resolved

/proc/formula_magic_part_form_counts(datum/formula_magic_part/part)
	var/list/result = list()
	for(var/form_id in part?.forms)
		result[form_id] = (result[form_id] || 0) + 1
	return result

/proc/formula_magic_consume_part_form_pair(list/form_counts, first_form, second_form)
	if(!form_counts)
		return 0
	var/count = min(form_counts[first_form] || 0, form_counts[second_form] || 0)
	if(count <= 0)
		return 0
	form_counts[first_form] -= count
	form_counts[second_form] -= count
	return count

/proc/formula_magic_part_count_form(datum/formula_magic_part/part, form_id)
	if(!part || !form_id)
		return 0
	var/count = 0
	for(var/current_form in part.forms)
		if(current_form == form_id)
			count++
	return count

/proc/formula_magic_consume_same_part_form_pair(list/form_counts, form_id)
	if(!form_counts)
		return 0
	var/count = round((form_counts[form_id] || 0) / 2)
	if(count <= 0)
		return 0
	form_counts[form_id] -= count * 2
	return count

/proc/formula_magic_remaining_part_form_type_count(list/form_counts)
	var/count = 0
	for(var/form_id in form_counts)
		if((form_counts[form_id] || 0) > 0)
			count++
	return count

/proc/formula_magic_detonate_formula_part(mob/living/carbon/human/caster, datum/formula_magic_part/part, reason)
	if(!caster || !part)
		return FALSE
	var/turf/center = get_turf(caster)
	if(!center)
		return FALSE
	var/toxin_force = max(1, part.mana_cost || 1)
	var/splash_toxin = max(1, round(toxin_force * 0.25))
	var/knockback = max(1, length(part.words))
	caster.visible_message(span_danger("[caster]'s formula detonates from [reason || "instability"], blooming into sickly green flame!"), span_userdanger("My formula detonates from [reason || "instability"]!"))
	caster.adjustToxLoss(toxin_force)
	var/turf/caster_throw_target = get_ranged_target_turf(caster, turn(caster.dir, 180), knockback)
	if(caster_throw_target)
		caster.safe_throw_at(caster_throw_target, knockback, 1, caster, force = MOVE_FORCE_STRONG)
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/fire/shortduration/formula_magic_toxic(T)
		for(var/mob/living/L in T)
			if(L == caster)
				continue
			L.adjustToxLoss(splash_toxin)
			var/push_dir = get_dir(center, L) || pick(NORTH, SOUTH, EAST, WEST)
			var/turf/throw_target = get_ranged_target_turf(L, push_dir, knockback)
			if(throw_target)
				L.safe_throw_at(throw_target, knockback, 1, caster, force = MOVE_FORCE_STRONG)
	return TRUE

/obj/effect/temp_visual/fire/shortduration/formula_magic_toxic
	name = "toxic green flame"
	color = "#36B36A"
	light_color = "#36B36A"
	duration = 4

/obj/item/formula_magic_mud_clod
	name = "formula mud clod"
	desc = "A brief lump of churned formula earth."
	icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	icon_state = "formula_summon"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/formula_magic_mud_clod/Initialize(mapload)
	. = ..()
	add_atom_colour("#7A5B35", FIXED_COLOUR_PRIORITY)
	QDEL_IN(src, 30 SECONDS)

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

/obj/structure/formula_magic_part_rune
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

/obj/structure/formula_magic_part_rune/Destroy()
	caster = null
	part = null
	. = ..()

/obj/structure/formula_magic_part_rune/proc/setup_formula_rune(mob/living/carbon/human/new_caster, datum/formula_magic_part/new_part, lifespan, trigger_count)
	caster = new_caster
	part = new_part
	remaining_triggers = max(1, trigger_count || 1)
	if(part?.impact_color)
		add_atom_colour(part.impact_color, FIXED_COLOUR_PRIORITY)
		set_light(1, 1, 1, l_color = part.impact_color)
	QDEL_IN(src, max(10 SECONDS, lifespan || 60 SECONDS))
	return TRUE

/obj/structure/formula_magic_part_rune/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		trigger_formula_rune(AM)

/obj/structure/formula_magic_part_rune/proc/trigger_formula_rune(mob/living/L)
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

/obj/effect/formula_magic_part_lingering_zone
	name = "lingering formula"
	desc = "A spoken formula hangs here as a temporary payload zone."
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_ABSTRACT
	layer = ABOVE_NORMAL_TURF_LAYER
	var/mob/living/carbon/human/caster
	var/datum/formula_magic_part/part
	var/power = 1
	var/pulse_interval = 2 SECONDS
	var/expire_time = 0
	var/pulse_started = FALSE

/obj/effect/formula_magic_part_lingering_zone/Destroy()
	caster = null
	part = null
	. = ..()

/obj/effect/formula_magic_part_lingering_zone/proc/setup_formula_zone(mob/living/carbon/human/new_caster, datum/formula_magic_part/new_part, new_power, lifespan)
	caster = new_caster
	part = new_part
	power = max(power, new_power || 1)
	expire_time = max(expire_time, world.time + max(1 SECONDS, lifespan || 5 SECONDS))
	if(!pulse_started)
		pulse_started = TRUE
		addtimer(CALLBACK(src, PROC_REF(pulse_formula_zone)), pulse_interval)
	return TRUE

/obj/effect/formula_magic_part_lingering_zone/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(isliving(AM))
		trigger_formula_zone(AM)

/obj/effect/formula_magic_part_lingering_zone/proc/pulse_formula_zone()
	if(QDELETED(src) || !part)
		return
	if(world.time >= expire_time)
		qdel(src)
		return
	for(var/mob/living/L in loc)
		trigger_formula_zone(L)
	if(QDELETED(src) || !loc || !part)
		return
	addtimer(CALLBACK(src, PROC_REF(pulse_formula_zone)), pulse_interval)

/obj/effect/formula_magic_part_lingering_zone/proc/trigger_formula_zone(mob/living/L)
	if(!L || !part || L == caster)
		return FALSE
	return formula_magic_apply_payload_hit(L, caster, power, part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor)

/proc/formula_magic_part_incompatible_modifier(datum/formula_magic_part/part, form_id)
	return formula_magic_validate_shape(part, form_id)

/proc/formula_magic_part_modifier_count(datum/formula_magic_part/part, modifier_id)
	if(!part || !modifier_id)
		return 0
	return max(0, part.tags[modifier_id] || 0)

/proc/formula_magic_part_form_repeat_count(datum/formula_magic_part/part, form_id)
	return max(0, formula_magic_part_count_form(part, form_id))

/proc/formula_magic_random_living_target(mob/living/carbon/human/caster, turf/source, list/excluded)
	if(!source)
		return null
	if(!excluded)
		excluded = list()
	var/list/candidates = list()
	for(var/mob/living/L in view(7, source))
		if(L == caster || (L in excluded) || QDELETED(L))
			continue
		candidates += L
	if(!length(candidates))
		return null
	return pick(candidates)

/proc/formula_magic_random_turf_from(turf/source, radius = 5)
	if(!source)
		return null
	var/list/candidates = orange(max(1, radius || 1), source)
	if(!length(candidates))
		return source
	return pick(candidates)

/proc/formula_magic_apply_lingering_zones(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/affected_turfs, power, lifespan)
	if(!caster || !part || !length(affected_turfs) || lifespan <= 0)
		return FALSE
	for(var/turf/T as anything in affected_turfs)
		if(!T)
			continue
		var/obj/effect/formula_magic_part_lingering_zone/zone
		for(var/obj/effect/formula_magic_part_lingering_zone/existing in T)
			if(existing.caster == caster)
				zone = existing
				break
		if(!zone)
			zone = new(T)
		zone.setup_formula_zone(caster, part, max(1, power || part.power || 1), lifespan)
	return TRUE

/proc/formula_magic_apply_form_payload_area(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/center, radius, power, list/excluded)
	if(!center || !part)
		return list("turfs" = list(), "targets" = list())
	var/list/result_turfs = list()
	var/list/hit_targets = excluded?.Copy() || list()
	var/effective_radius = max(0, min(radius || 0, 8))
	for(var/turf/T in range(effective_radius, center))
		result_turfs |= T
		new /obj/effect/temp_visual/spell_impact(T, part.impact_color, SPELL_IMPACT_LOW)
		for(var/mob/living/L in T)
			if(L == caster || (hit_targets && (L in hit_targets)))
				continue
			hit_targets |= L
			formula_magic_apply_payload_hit(L, caster, max(1, power || part.power || 1), part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor)
	return list("turfs" = result_turfs, "targets" = hit_targets)

/proc/formula_magic_apply_instant_existence(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/affected_turfs, power)
	var/existence_count = formula_magic_part_modifier_count(part, "existence")
	if(existence_count <= 0 || !length(affected_turfs))
		return FALSE
	var/existence_lifespan = max(0, part.tags["existence_duration"] || 0)
	if(existence_lifespan > 0)
		return formula_magic_apply_lingering_zones(caster, part, affected_turfs, power, existence_lifespan)
	return FALSE

/proc/formula_magic_apply_matrix_existence(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/affected_turfs, power)
	return formula_magic_apply_instant_existence(caster, part, affected_turfs, power)

/proc/formula_magic_apply_touch_chain(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, list/excluded)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	if(chain_count <= 0)
		return FALSE
	var/list/visited = excluded?.Copy() || list(caster)
	for(var/i in 1 to chain_count)
		var/mob/living/target = formula_magic_random_living_target(caster, source, visited)
		if(!target)
			break
		formula_magic_apply_form_payload_area(caster, part, get_turf(target), 0, max(1, round((power || part.power || 1) * 0.7)), visited)
		visited |= target
	return TRUE

/proc/formula_magic_apply_moment_ricochet(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power)
	var/ricochet_count = formula_magic_part_modifier_count(part, "ricochet")
	if(ricochet_count <= 0)
		return FALSE
	for(var/i in 1 to ricochet_count)
		var/turf/random_turf = formula_magic_random_turf_from(source, max(1, part.radius || 1))
		if(random_turf)
			formula_magic_apply_form_payload_area(caster, part, random_turf, 0, max(1, power || part.power || 1), list(caster))
	return TRUE

/proc/formula_magic_apply_moment_chain(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, list/excluded)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	if(chain_count <= 0)
		return FALSE
	var/list/visited = excluded?.Copy() || list(caster)
	for(var/i in 1 to chain_count)
		var/mob/living/target = formula_magic_random_living_target(caster, source, visited)
		if(!target)
			break
		formula_magic_apply_form_payload_area(caster, part, get_turf(target), 0, max(1, round((power || part.power || 1) * 0.7)), visited)
		visited |= target
	return TRUE

/proc/formula_magic_apply_nova_ricochet(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, max_distance)
	var/ricochet_count = formula_magic_part_modifier_count(part, "ricochet")
	if(ricochet_count <= 0)
		return FALSE
	for(var/i in 1 to ricochet_count)
		var/turf/random_target = get_ranged_target_turf(source, pick(GLOB.alldirs), max(1, max_distance || 1))
		if(random_target)
			formula_magic_apply_form_payload_area(caster, part, random_target, 0, max(1, power || part.power || 1), list(caster))
	return TRUE

/proc/formula_magic_apply_nova_chain(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, max_distance, list/excluded)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	if(chain_count <= 0)
		return FALSE
	var/list/visited = excluded?.Copy() || list(caster)
	for(var/i in 1 to chain_count)
		var/mob/living/target = formula_magic_nearest_chain_target(caster, source, visited)
		if(!target || get_dist(source, target) > max(1, max_distance || 1))
			break
		formula_magic_apply_form_payload_area(caster, part, get_turf(target), 0, max(1, round((power || part.power || 1) * 0.7)), visited)
		visited |= target
	return TRUE

/proc/formula_magic_apply_wave_shrapnel(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, list/excluded)
	var/shrapnel_count = formula_magic_part_modifier_count(part, "shrapnel")
	if(shrapnel_count <= 0)
		return FALSE
	return formula_magic_apply_form_payload_area(caster, part, source, shrapnel_count, max(1, power || part.power || 1), excluded)

/proc/formula_magic_apply_fall_payload(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/target, power, allow_followups = TRUE)
	if(!caster || !part || !target)
		return FALSE
	var/list/result = formula_magic_apply_form_payload_area(caster, part, target, max(0, part.radius || 0), max(1, power || part.power || 1), null)
	var/list/affected_turfs = result["turfs"] || list()
	var/list/hit_targets = result["targets"] || list()
	formula_magic_apply_instant_existence(caster, part, affected_turfs, max(1, power || part.power || 1))
	if(!allow_followups)
		return TRUE
	var/ricochet_count = formula_magic_part_modifier_count(part, "ricochet")
	for(var/i in 1 to ricochet_count)
		var/turf/random_target = formula_magic_random_turf_from(target, 5)
		if(random_target)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_fall_payload), caster, part, random_target, power, FALSE), i * 0.5 SECONDS)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	var/list/visited = hit_targets?.Copy() || list(caster)
	if(length(hit_targets) > 1)
		for(var/i in 1 to chain_count)
			var/mob/living/next_target = formula_magic_nearest_chain_target(caster, target, visited)
			if(!next_target || get_dist(target, next_target) > 4)
				break
			visited |= next_target
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_fall_payload), caster, part, get_turf(next_target), power, FALSE), i * 0.5 SECONDS)
	var/shrapnel_count = formula_magic_part_modifier_count(part, "shrapnel")
	if(shrapnel_count > 0)
		formula_magic_fire_orb_shrapnel(caster, target, max(1, power || part.power || 1), part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor, part.impact_color, shrapnel_count)
	return TRUE

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
		formula_magic_fire_orb_followup(context.caster, source, target, formula_magic_part_power(part, FORMULA_FORM_ORB), max(0, part.radius || 0), max(0, part.tags["chain"] || 0), max(0, part.tags["ricochet"] || 0), max(0, part.tags["pierce"] || 0), max(0, part.tags["existence"] || 0), max(0, part.tags["shrapnel"] || 0), part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor, part.impact_color, list(), null, 0.2, TRUE)
	context.caster.visible_message(span_notice("[context.caster] releases a seeking formula orb."))
	return TRUE

/proc/formula_magic_execute_aura_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	if(!source)
		return FALSE
	new /obj/effect/temp_visual/spell_impact(source, part.impact_color, SPELL_IMPACT_LOW)
	var/aura_words = max(1, formula_magic_part_form_repeat_count(part, FORMULA_FORM_AURA) || 1)
	formula_magic_apply_aura_status(context.caster, part, max(30 SECONDS, part.duration || (aura_words * 30 SECONDS)), 1)
	var/widen_count = formula_magic_part_modifier_count(part, "widen")
	if(widen_count > 0 && context.caster.current_fellowship)
		var/list/members = context.caster.current_fellowship.get_members()
		members -= context.caster
		for(var/i in 1 to min(length(members), aura_words))
			var/mob/living/member = pick(members)
			members -= member
			if(member)
				new /obj/effect/temp_visual/spell_impact(get_turf(member), part.impact_color, SPELL_IMPACT_LOW)
				formula_magic_apply_aura_status(member, part, max(10 SECONDS, round((part.duration || (aura_words * 30 SECONDS)) * 0.3)), 0.3)
	var/pierce_count = max(0, part.tags["pierce"] || 0)
	if(pierce_count > 0)
		var/pierce_fraction = min(1, pierce_count * 0.3)
		for(var/mob/living/L in range(1, source))
			if(L == context.caster)
				continue
			new /obj/effect/temp_visual/spell_impact(get_turf(L), part.impact_color, SPELL_IMPACT_LOW)
			formula_magic_apply_aura_status(L, part, max(10 SECONDS, round((part.duration || (aura_words * 30 SECONDS)) * pierce_fraction)), pierce_fraction)
	var/ricochet_count = max(0, part.tags["ricochet"] || 0)
	if(ricochet_count > 0 && context.caster.current_fellowship)
		var/list/members = context.caster.current_fellowship.get_members()
		members -= context.caster
		for(var/i in 1 to ricochet_count)
			if(!length(members))
				break
			var/mob/living/member = pick(members)
			members -= member
			if(member)
				new /obj/effect/temp_visual/spell_impact(get_turf(member), part.impact_color, SPELL_IMPACT_LOW)
				formula_magic_apply_aura_status(member, part, max(10 SECONDS, round((part.duration || (aura_words * 30 SECONDS)) * 0.3)), 0.3)
	context.caster.visible_message(span_notice("[context.caster] gathers a formula aura."))
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
	new /obj/effect/temp_visual/spell_impact(target, part.impact_color, SPELL_IMPACT_LOW)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_part_area), context.caster, part, target, part.radius, formula_magic_part_power(part, FORMULA_FORM_INSTANT), null, FORMULA_FORM_INSTANT), 1 SECONDS)
	return TRUE

/proc/formula_magic_execute_beam_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	var/turf/source = get_turf(context.caster)
	var/beam_dir = get_dir(source, context.target_turf) || context.caster.dir
	var/turf/target = get_ranged_target_turf(source, beam_dir, max(1, part.range))
	if(!source || !target)
		return FALSE
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
		for(var/turf/T in range(min(8, widen_count), target))
			summon_targets |= T
	for(var/turf/T as anything in summon_targets)
		for(var/i in 1 to FLOOR(summon_words / 2, 1))
			var/obj/item/natural/clay/clay = new(T)
			QDEL_IN(clay, summon_lifespan)
		if(summon_words % 2)
			var/obj/item/formula_magic_mud_clod/clod = new(T)
			QDEL_IN(clod, summon_lifespan)
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
	new /obj/effect/temp_visual/spell_impact(target, part.impact_color, SPELL_IMPACT_MEDIUM)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_fall_payload), context.caster, part, target, round(formula_magic_part_power(part, FORMULA_FORM_FALL) * 1.5)), delay)
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
		var/obj/structure/formula_magic_part_rune/rune = new(T)
		rune.setup_formula_rune(context.caster, part, lifespan, trigger_count)
	return TRUE

/proc/formula_magic_part_power(datum/formula_magic_part/part, form_id)
	if(!part)
		return 0
	var/multiplier = 1
	switch(form_id)
		if(FORMULA_FORM_ORB)
			multiplier = 1
		if(FORMULA_FORM_TOUCH)
			multiplier = 1.2
		if(FORMULA_FORM_INSTANT)
			multiplier = 0.9
		if(FORMULA_FORM_BEAM)
			multiplier = 0.7
		if(FORMULA_FORM_SUMMON)
			multiplier = 0.6
		if(FORMULA_FORM_WAVE)
			multiplier = 0.65
		if(FORMULA_FORM_SPIRAL)
			multiplier = 0.5
		if(FORMULA_FORM_AURA)
			multiplier = 0
		if(FORMULA_FORM_GUIDANCE)
			multiplier = 0.8
		if(FORMULA_FORM_NOVA)
			multiplier = 0.6
		if(FORMULA_FORM_BREATH)
			multiplier = 0.4
		if(FORMULA_FORM_CLOAK)
			multiplier = 0.1
		if(FORMULA_FORM_FALL)
			multiplier = 1
		if(FORMULA_FORM_RUNE)
			multiplier = 0.8
	return max(0, round((part.power || 0) * multiplier))

/proc/formula_magic_limited_part_target(datum/formula_magic_context/context, datum/formula_magic_part/part, max_distance)
	var/turf/source = get_turf(context?.caster)
	var/turf/target = context?.target_turf
	if(!source)
		return target
	if(!target)
		target = get_ranged_target_turf(context.caster, context.caster.dir, max(1, max_distance || part?.range || 1))
	if(!target)
		return source
	max_distance = max(1, max_distance || part?.range || 1)
	if(get_dist(source, target) <= max_distance)
		return target
	var/list/line = getline(source, target)
	if(length(line) > max_distance + 1)
		return line[max_distance + 1]
	return get_ranged_target_turf(source, get_dir(source, target) || context.caster.dir, max_distance) || target

/proc/formula_magic_apply_part_area(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/center, radius, power, list/excluded, form_id = null)
	if(!center || !part)
		return null
	var/list/result = formula_magic_apply_form_payload_area(caster, part, center, radius, power, excluded)
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
	var/beam_dir = get_dir(source, target) || caster.dir
	var/effective_radius = apply_modifiers ? max(0, part.radius || 0) : 0
	var/beam_width = 0
	if(form_id == FORMULA_FORM_BEAM)
		beam_width = FLOOR(effective_radius / 2, 1)
	else if(form_id == FORMULA_FORM_GUIDANCE)
		beam_width = effective_radius
	var/pierce_grace = (apply_modifiers && form_id == FORMULA_FORM_BEAM) ? max(0, part.tags["pierce"] || 0) : 0
	var/list/hit = list(caster)
	var/list/affected_turfs = list()
	var/list/existence_turfs = list()
	for(var/turf/T in getline(source, target))
		if(T == source)
			continue
		distance++
		beam_end = T
		var/fade_distance = max(0, distance - pierce_grace)
		var/current_power = max(1, round(formula_magic_part_power(part, form_id) * (power_multiplier || 1) * max(0.1, 1 - ((fade_percent || 0) * fade_distance / 100))))
		affected_turfs |= T
		var/hit_count_before = length(hit)
		formula_magic_apply_beam_turf(caster, part, T, current_power, hit)
		if(length(hit) > hit_count_before)
			existence_turfs |= T
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
				if(right_turf)
					affected_turfs |= right_turf
					hit_count_before = length(hit)
					formula_magic_apply_beam_turf(caster, part, right_turf, current_power, hit)
					if(length(hit) > hit_count_before)
						existence_turfs |= right_turf
		if(T.density)
			break
	if(form_id == FORMULA_FORM_BEAM && beam_end != source)
		generate_tracer_between_points(RETURN_PRECISE_POINT(source), RETURN_PRECISE_POINT(beam_end), /obj/effect/projectile/tracer/stun, part.impact_color, 5)
	if(apply_modifiers && (part.tags["existence"] || 0) > 0)
		var/list/existence_targets = (form_id == FORMULA_FORM_GUIDANCE) ? affected_turfs : existence_turfs
		if(length(existence_targets))
			formula_magic_apply_matrix_existence(caster, part, existence_targets, max(1, formula_magic_part_power(part, form_id)))
	if(apply_modifiers && allow_followups && form_id == FORMULA_FORM_BEAM && beam_end != source)
		if((part.tags["chain"] || 0) > 0)
			var/list/visited = hit.Copy()
			for(var/i in 1 to max(0, part.tags["chain"] || 0))
				var/mob/living/next_target = formula_magic_nearest_chain_target(caster, beam_end, visited)
				if(!next_target)
					break
				visited |= next_target
				formula_magic_apply_beam_line(caster, part, beam_end, get_turf(next_target), fade_percent, form_id, FALSE, 1)
		if((part.tags["ricochet"] || 0) > 0)
			var/current_angle = Get_Angle(source, beam_end)
			var/turf/approach = beam_end ? get_step(beam_end, angle2dir(SIMPLIFY_DEGREES((current_angle || 0) + 180))) : source
			var/new_angle = formula_magic_reflected_angle(approach, beam_end, current_angle)
			var/turf/start = beam_end
			for(var/i in 1 to max(0, part.tags["ricochet"] || 0))
				if(!start)
					break
				var/turf/reflected_target = get_ranged_target_turf(start, angle2dir(new_angle), max(1, part.range))
				if(!reflected_target)
					break
				formula_magic_apply_beam_line(caster, part, start, reflected_target, fade_percent, form_id, FALSE, 1)
				start = reflected_target
		if((part.tags["shrapnel"] || 0) > 0)
			for(var/i in 1 to max(0, part.tags["shrapnel"] || 0))
				var/turf/random_target = get_ranged_target_turf(beam_end, pick(GLOB.alldirs), max(1, part.range))
				if(random_target)
					formula_magic_apply_beam_line(caster, part, beam_end, random_target, fade_percent, form_id, FALSE, 1, FALSE)
	return TRUE

/proc/formula_magic_apply_beam_turf(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/target, power, list/hit)
	if(!caster || !part || !target)
		return FALSE
	new /obj/effect/temp_visual/spell_impact(target, part.impact_color, SPELL_IMPACT_LOW)
	for(var/mob/living/L in target)
		if(L in hit)
			continue
		hit |= L
		formula_magic_apply_payload_hit(L, caster, max(1, power), part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor)
	return TRUE

/proc/formula_magic_progressive_part_line(mob/living/carbon/human/caster, datum/formula_magic_part/part, list/line, width, delay, form_id = FORMULA_FORM_WAVE)
	if(!caster || !part || !length(line))
		return FALSE
	var/list/hit = list(caster)
	for(var/turf/T in line)
		if(!T)
			continue
		formula_magic_apply_part_area(caster, part, T, width, formula_magic_part_power(part, form_id), hit, form_id)
		for(var/mob/living/L in range(max(0, width || 0), T))
			hit |= L
		if(form_id == FORMULA_FORM_WAVE && (part.tags["ricochet"] || 0) > 0 && length(hit) > 1)
			var/turf/random_target = get_ranged_target_turf(T, pick(GLOB.alldirs), max(1, part.range))
			if(random_target)
				var/list/new_line = getline(T, random_target)
				new_line -= T
				INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_progressive_part_line), caster, part, new_line, width, delay, form_id)
				return TRUE
		if(form_id == FORMULA_FORM_WAVE && (part.tags["chain"] || 0) > 0 && length(hit) > 1)
			var/mob/living/next_target = formula_magic_nearest_chain_target(caster, T, hit)
			if(next_target)
				var/list/chain_line = getline(T, get_turf(next_target))
				chain_line -= T
				INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_progressive_part_line), caster, part, chain_line, width, delay, form_id)
				return TRUE
		sleep(max(1, delay || 1))
	return TRUE

/proc/formula_magic_spiral_loop(mob/living/carbon/human/caster, datum/formula_magic_part/part, arms, radius, cycles, form_id = FORMULA_FORM_SPIRAL, reverse = FALSE)
	if(!caster || !part)
		return FALSE
	var/list/path_dirs = list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST)
	if(reverse)
		path_dirs = list(NORTH, NORTHWEST, WEST, SOUTHWEST, SOUTH, SOUTHEAST, EAST, NORTHEAST)
	arms = max(1, min(8, arms || 1))
	radius = max(1, min(8, radius || 1))
	cycles = max(1, min(8, cycles || 1))
	var/ricochet_remaining = max(0, part.tags["ricochet"] || 0)
	var/list/arm_pierce = list()
	for(var/arm_index in 1 to arms)
		arm_pierce["[arm_index]"] = max(0, part.tags["pierce"] || 0)
	for(var/cycle in 1 to cycles)
		for(var/step_index in 1 to length(path_dirs))
			var/turf/source = get_turf(caster)
			if(!source)
				return FALSE
			for(var/arm in 1 to arms)
				if(isnull(arm_pierce["[arm]"]))
					continue
				var/path_index = ((step_index - 1 + round((arm - 1) * length(path_dirs) / arms)) % length(path_dirs)) + 1
				var/turf/target = get_ranged_target_turf(source, path_dirs[path_index], radius)
				if(target)
					var/list/result = formula_magic_apply_part_area(caster, part, target, 0, formula_magic_part_power(part, form_id), list(caster), form_id)
					var/list/hit_targets = islist(result) ? (result["targets"] || list()) : list()
					if(length(hit_targets) > 1)
						if(ricochet_remaining > 0)
							ricochet_remaining--
							reverse = !reverse
							path_dirs = reverse ? list(NORTH, NORTHWEST, WEST, SOUTHWEST, SOUTH, SOUTHEAST, EAST, NORTHEAST) : list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST)
							continue
						var/pierce_left = max(0, arm_pierce["[arm]"] || 0)
						if(pierce_left <= 0)
							arm_pierce["[arm]"] = null
						else
							arm_pierce["[arm]"] = pierce_left - 1
			sleep(2)
	return TRUE

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

/proc/formula_magic_fire_orb_followup(mob/living/carbon/human/caster, turf/start, atom/target, power, radius, chain_remaining, ricochet_remaining, pierce_remaining, existence_repeats, shrapnel_remaining, damage_type, damage_flag, woundclass, intdamfactor, impact_color, list/chain_visited, forced_angle = null, speed_multiplier = 1, homing = FALSE)
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

/proc/formula_magic_fire_orb_shrapnel(mob/living/carbon/human/caster, turf/start, power, damage_type, damage_flag, woundclass, intdamfactor, impact_color, shrapnel_count)
	if(!caster || !start)
		return FALSE
	var/count = max(0, shrapnel_count || 0)
	if(count <= 0)
		return FALSE
	for(var/i in 1 to count)
		formula_magic_fire_orb_followup(caster, start, null, power, 0, 0, 0, 0, 0, 0, damage_type, damage_flag, woundclass, intdamfactor, impact_color, list(), rand(0, 359))
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

/datum/status_effect/buff/formula_magic_aura
	id = "formula_magic_aura"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/blocks_all_formula = TRUE
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

/proc/formula_magic_apply_orb_impact(mob/living/carbon/human/caster, turf/impact, atom/direct_target, power, radius, damage_type = BRUTE, damage_flag = "blunt", woundclass = BCLASS_BLUNT, intdamfactor = BLUNT_DEFAULT_INT_DAMAGEFACTOR, impact_color = "#B96DFF")
	if(!impact)
		return FALSE
	var/effective_radius = max(0, min(radius || 0, 8))
	if(!effective_radius)
		return TRUE
	for(var/turf/T in range(effective_radius, impact))
		new /obj/effect/temp_visual/spell_impact(T, impact_color || "#B96DFF", SPELL_IMPACT_LOW)
		for(var/mob/living/L in T)
			if(L == caster)
				continue
			formula_magic_apply_payload_hit(L, caster, max(1, power || 1), damage_type, damage_flag, woundclass, intdamfactor)
	return TRUE

/proc/formula_magic_impact_turfs(turf/impact, radius)
	var/list/result = list()
	if(!impact)
		return result
	var/effective_radius = max(0, min(radius || 0, 8))
	for(var/turf/T in range(effective_radius, impact))
		result += T
	return result

/proc/formula_magic_nearest_chain_target(mob/living/carbon/human/caster, turf/source, list/excluded)
	if(!source)
		return null
	if(!excluded)
		excluded = list()
	var/mob/living/next_target
	var/best_distance = 999
	for(var/mob/living/L in view(7, source))
		if(L == caster || (L in excluded) || QDELETED(L))
			continue
		var/distance = get_dist(source, L)
		if(distance < best_distance)
			best_distance = distance
			next_target = L
	return next_target

/proc/formula_magic_reflected_angle(turf/approach, atom/target, current_angle)
	if(!target)
		return SIMPLIFY_DEGREES((current_angle || 0) + 180)
	var/face_direction = get_dir(target, approach) || angle2dir(SIMPLIFY_DEGREES((current_angle || 0) + 180))
	var/face_angle = dir2angle(face_direction)
	var/incidence = GET_ANGLE_OF_INCIDENCE(face_angle, ((current_angle || 0) + 180))
	return SIMPLIFY_DEGREES(face_angle + incidence)

/proc/formula_magic_ricochet_start_turf(turf/approach, atom/target, new_angle)
	var/turf/impact = get_turf(target)
	if(!impact)
		return approach
	if(isliving(target))
		return impact
	if(!target.density)
		return impact
	var/turf/reflected_step = get_step(impact, angle2dir(new_angle))
	if(reflected_step && !reflected_step.density)
		return reflected_step
	if(approach && !approach.density)
		return approach
	var/turf/back_step = get_step(impact, angle2dir(SIMPLIFY_DEGREES((new_angle || 0) + 180)))
	if(back_step && !back_step.density)
		return back_step
	return impact

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
	formula_magic_apply_orb_impact(caster, impact, target, damage, arcane_radius, damage_type, flag, woundclass, intdamfactor, spell_impact_color)
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
			lingering_part.tags = list()
			formula_magic_apply_lingering_zones(caster, lingering_part, affected_turfs, damage, existence_lifespan)
	if(shrapnel_remaining > 0 && impact)
		formula_magic_fire_orb_shrapnel(caster, impact, damage, damage_type, flag, woundclass, intdamfactor, spell_impact_color, shrapnel_remaining)
	if(chain_remaining > 0 && impact)
		if(target && !(target in chain_visited))
			chain_visited += target
		var/mob/living/next_target = formula_magic_nearest_chain_target(caster, impact, chain_visited)
		if(next_target)
			var/list/next_visited = chain_visited.Copy()
			next_visited += next_target
			formula_magic_fire_orb_followup(caster, impact, next_target, max(1, round(damage * 0.7)), arcane_radius, chain_remaining - 1, ricochet_remaining, pierce_remaining, existence_repeats, shrapnel_remaining, damage_type, flag, woundclass, intdamfactor, spell_impact_color, next_visited)
	if(ricochet_remaining > 0 && target)
		var/new_angle = formula_magic_reflected_angle(approach, target, current_angle)
		var/turf/start = formula_magic_ricochet_start_turf(approach, target, new_angle)
		if(start)
			formula_magic_fire_orb_followup(caster, start, null, damage, arcane_radius, chain_remaining, ricochet_remaining - 1, pierce_remaining, existence_repeats, shrapnel_remaining, damage_type, flag, woundclass, intdamfactor, spell_impact_color, chain_visited, new_angle)
	if(pierce_remaining > 0)
		pierce_remaining--
		return BULLET_ACT_FORCE_PIERCE
	return BULLET_ACT_HIT
