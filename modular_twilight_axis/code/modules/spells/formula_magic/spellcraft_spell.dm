/datum/action/cooldown/spell/formula_preset
	name = "Formula"
	desc = "A prepared modular formula."
	button_icon = 'modular_twilight_axis/icons/effects/formula_magic.dmi'
	button_icon_state = "formula_rune"

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
	var/list/formula_phrase_words = list()
	var/list/formula_phrase_texts = list()
	var/list/formula_phrase_delays = list()
	var/list/formula_word_cast_times = list()
	var/word_speak_index = 1
	var/turf/formula_press_turf
	var/interrupt_chance = 10

/datum/action/cooldown/spell/formula_preset/New(list/preset, preset_index = 1)
	if(islist(preset))
		name = preset["name"] || "Formula [preset_index]"
		desc = preset["summary"] || "A prepared modular formula."
		var/list/preset_words = preset["words"]
		formula_words = preset_words?.Copy() || list()
		var/list/preset_word_cast_times = preset["word_cast_times"]
		formula_word_cast_times = preset_word_cast_times?.Copy() || list()
		button_icon_state = formula_magic_icon_state_for_words(formula_words)
		var/mana = preset["mana_cost"] || 1
		var/cast_ticks = preset["cast_time"] || 10
		interrupt_chance = clamp(preset["interrupt_chance"] || 10, 10, 90)
		if(length(formula_word_cast_times))
			cast_ticks = 0
			for(var/word_time in formula_word_cast_times)
				cast_ticks += max(1, word_time || 1)
		primary_resource_cost = max(1, round(mana * 2))
		charge_time = max(3, cast_ticks)
		cooldown_time = max(3 SECONDS, (preset["complexity"] || 1) * 2 SECONDS)
	. = ..()

/datum/action/cooldown/spell/formula_preset/on_start_charge()
	. = ..()
	word_speak_index = 1
	formula_phrase_words = formula_words.Copy()
	if(!length(formula_word_cast_times) && owner?.mind)
		var/mob/living/carbon/human/H = owner
		var/datum/formula_magic_formula/formula = H.mind.build_formula_magic_formula(formula_words)
		if(formula)
			formula_word_cast_times = formula.word_cast_times.Copy()
			charge_time = max(3, formula.cast_time)
			interrupt_chance = formula.interrupt_chance
			qdel(formula)
	formula_phrase_texts = formula_magic_speech_phrases_for_words(formula_words)
	formula_phrase_delays = formula_magic_speech_delays_for_words(formula_words, formula_word_cast_times)
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
	formula_press_turf = get_turf(_target)
	if(!formula_press_turf)
		formula_press_turf = location
	if(!formula_press_turf)
		formula_press_turf = get_turf(owner)
	return ..()

/datum/action/cooldown/spell/formula_preset/proc/speak_formula_words()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	while(currently_charging && word_speak_index <= length(formula_phrase_texts))
		var/phrase = formula_phrase_texts[word_speak_index]
		if(phrase)
			H.say(phrase, forced = "spell", language = /datum/language/common)
		word_speak_index++
		var/speak_time = formula_phrase_delays[word_speak_index - 1] || charge_time
		sleep(max(2, round(speak_time)))

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
			if(FORMULA_FORM_ORB)
				return "formula_orb"
			if(FORMULA_FORM_INSTANT)
				return "formula_blink"
			if(FORMULA_FORM_RUNE)
				return "formula_rune"
			if(FORMULA_FORM_AURA)
				return "formula_aura"
			if(FORMULA_FORM_CLOAK)
				return "formula_aura"
			if(FORMULA_FORM_SUMMON)
				return "formula_summon"
			if(FORMULA_FORM_GUIDANCE)
				return "formula_guidance"
			if(FORMULA_FORM_WAVE)
				return "formula_guidance"
			if(FORMULA_FORM_FALL)
				return "formula_meteor"
			if(FORMULA_FORM_BREATH)
				return "formula_breath"
			if(FORMULA_FORM_NOVA)
				return "formula_nova"
			if(FORMULA_FORM_TOUCH)
				return "formula_touch"
	return "formula_rune"

/proc/formula_magic_speech_phrases_for_words(list/word_ids)
	var/list/result = list()
	var/list/spoken_prebuilt = list()
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word)
			continue
		if(word.tags?["prebuilt_formula"])
			if(spoken_prebuilt[word.id])
				continue
			spoken_prebuilt[word.id] = TRUE
		result += word.get_speech_phrases()
	return result

/proc/formula_magic_speech_delays_for_words(list/word_ids, list/word_delays)
	var/list/result = list()
	var/list/spoken_prebuilt = list()
	var/word_index = 1
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word)
			word_index++
			continue
		var/list/phrases = word.get_speech_phrases()
		var/word_delay = word_delays?[word_index] || word.cast_time || FORMULA_DEFAULT_WORD_DELAY
		word_index++
		if(word.tags?["prebuilt_formula"])
			if(spoken_prebuilt[word.id])
				continue
			spoken_prebuilt[word.id] = TRUE
		var/phrase_delay = max(2, round(word_delay / max(1, length(phrases))))
		for(var/i in 1 to length(phrases))
			result += phrase_delay
	return result
