/datum/action/cooldown/spell/formula_preset
	name = "Formula"
	desc = "A prepared orb formula."
	button_icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	button_icon_state = "formula_orb"
	click_to_activate = TRUE
	self_cast_possible = TRUE
	charge_required = TRUE
	charge_time = 1 SECONDS
	charge_slowdown = CHARGING_SLOWDOWN_SMALL
	charge_sound = 'sound/magic/charging.ogg'
	hold_drain = 1
	cooldown_time = 5 SECONDS
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = 1
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC | SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z
	spell_impact_intensity = SPELL_IMPACT_LOW
	var/list/formula_words = list()
	var/list/formula_word_cast_times = list()
	var/word_speak_index = 1
	var/turf/formula_press_turf
	var/interrupt_chance = 10

/datum/action/cooldown/spell/formula_preset/New(list/preset, preset_index = 1)
	if(islist(preset))
		name = preset["name"] || "Orb Formula [preset_index]"
		desc = preset["summary"] || "A prepared orb formula."
		var/list/preset_words = preset["words"]
		formula_words = preset_words?.Copy() || list()
		var/list/preset_word_cast_times = preset["word_cast_times"]
		formula_word_cast_times = preset_word_cast_times?.Copy() || list()
		primary_resource_cost = max(1, round((preset["mana_cost"] || 1) * 2))
		charge_time = max(3, preset["cast_time"] || 10)
		cooldown_time = max(3 SECONDS, (preset["complexity"] || 1) * 2 SECONDS)
	. = ..()

/datum/action/cooldown/spell/formula_preset/on_start_charge()
	. = ..()
	word_speak_index = 1
	if(owner)
		RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_formula_charge_damage))
	INVOKE_ASYNC(src, PROC_REF(speak_formula_words))

/datum/action/cooldown/spell/formula_preset/on_end_charge(success)
	if(owner)
		UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	return ..()

/datum/action/cooldown/spell/formula_preset/proc/on_formula_charge_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!currently_charging || damage <= 0)
		return
	if(prob(interrupt_chance))
		var/mob/living/carbon/human/H = owner
		if(H)
			to_chat(H, span_warning("The pain breaks my formula."))
		cancel_casting()

/datum/action/cooldown/spell/formula_preset/start_casting(client/source, atom/_target, turf/location, control, params)
	formula_press_turf = get_turf(_target) || location || get_turf(owner)
	return ..()

/datum/action/cooldown/spell/formula_preset/proc/speak_formula_words()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	while(currently_charging && word_speak_index <= length(formula_words))
		var/datum/formula_magic_word/word = resolve_formula_magic_word(formula_words[word_speak_index])
		if(word)
			H.say(word.get_phrase(), forced = "spell", language = /datum/language/common)
		word_speak_index++
		sleep(max(2, formula_word_cast_times?[word_speak_index - 1] || FORMULA_DEFAULT_WORD_DELAY))

/datum/action/cooldown/spell/formula_preset/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !H.mind)
		return FALSE
	return H.mind.perform_formula_magic_cast(H, formula_words, cast_on, FALSE, formula_press_turf)

/proc/formula_magic_icon_state_for_words(list/word_ids)
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word || word.role != FORMULA_WORD_FORM)
			continue
		switch(word.id)
			if(FORMULA_FORM_BEAM)
				return "formula_guidance"
			if(FORMULA_FORM_ORB)
				return "formula_orb"
			if(FORMULA_FORM_INSTANT)
				return "formula_blink"
			if(FORMULA_FORM_GUIDANCE)
				return "formula_guidance"
			if(FORMULA_FORM_WAVE)
				return "formula_wave"
			if(FORMULA_FORM_AURA)
				return "formula_aura"
			if(FORMULA_FORM_SUMMON)
				return "formula_summon"
			if(FORMULA_FORM_NOVA)
				return "formula_nova"
			if(FORMULA_FORM_TOUCH)
				return "formula_touch"
			if(FORMULA_FORM_FALL)
				return "formula_meteor"
			if(FORMULA_FORM_RUNE)
				return "formula_rune"
			if(FORMULA_FORM_BREATH)
				return "formula_breath"
			if(FORMULA_FORM_CLOAK)
				return "formula_aura"
	return "formula_orb"

/proc/formula_magic_speech_phrases_for_words(list/word_ids)
	var/list/result = list()
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(word)
			result += word.get_speech_phrases()
	return result

/proc/formula_magic_speech_delays_for_words(list/word_ids, list/word_delays)
	var/list/result = list()
	for(var/i in 1 to length(word_ids))
		result += max(2, word_delays?[i] || FORMULA_DEFAULT_WORD_DELAY)
	return result

/obj/item/paper/scroll/formula_magic
	name = "formula scroll"
	desc = "A scroll bearing an orb formula."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll"
	var/list/formula_words = list()
	var/formula_name = "Formula"
	var/formula_json = ""
	var/arcane_required = 1
	var/reading_required = 1

/obj/item/paper/scroll/formula_magic/proc/set_formula_magic_scroll(new_name, list/word_ids, datum/mind/writer)
	formula_name = sanitize(copytext("[new_name || "Formula Scroll"]", 1, 48))
	formula_words = writer?.formula_magic_normalized_word_list(word_ids) || list()
	arcane_required = writer?.get_formula_magic_arcane_requirement(formula_words) || 1
	reading_required = arcane_required
	formula_json = writer?.formula_magic_export_json(formula_name, formula_words) || json_encode(list("kind" = "twilight_axis_formula", "version" = 2, "name" = formula_name, "words" = formula_words))
	name = "[formula_name] formula scroll"
	desc = "A scroll bearing [formula_name]. It requires Reading [reading_required] to read or invoke."

/obj/item/paper/scroll/formula_magic/attack_self(mob/user)
	if(!ishuman(user))
		return ..()
	var/mob/living/carbon/human/H = user
	if(H.get_skill_level(/datum/skill/misc/reading) < reading_required)
		to_chat(H, span_warning("I need Reading [reading_required] to read this formula."))
		return TRUE
	to_chat(H, span_notice("[formula_name]: [formula_json]"))
	return TRUE

/obj/item/paper/scroll/formula_magic/afterattack(atom/target, mob/living/user, proximity, click_parameters)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.get_skill_level(/datum/skill/misc/reading) < reading_required)
		to_chat(H, span_warning("I need Reading [reading_required] to invoke this scroll."))
		return
	if(!H.mind)
		return
	H.mind.perform_formula_magic_cast(H, formula_words, target, TRUE)
