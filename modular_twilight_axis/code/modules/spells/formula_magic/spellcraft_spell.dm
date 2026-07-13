/datum/action/cooldown/spell/formula_live_cast
	name = "Formula Craft"
	desc = "Compose a modular formula from known words on the fly, then invoke it with this same spell."
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

	var/list/formula_phrase_words = list()
	var/word_speak_index = 1
	var/turf/formula_press_turf

/datum/action/cooldown/spell/formula_live_cast/on_start_charge()
	. = ..()
	var/mob/living/carbon/human/H = owner
	formula_phrase_words = H?.mind?.formula_magic_live_words?.Copy() || list()
	if(!length(formula_phrase_words))
		return
	word_speak_index = 1
	INVOKE_ASYNC(src, PROC_REF(speak_formula_words))

/datum/action/cooldown/spell/formula_live_cast/start_casting(client/source, atom/_target, turf/location, control, params)
	formula_press_turf = get_turf(_target)
	if(!formula_press_turf)
		formula_press_turf = location
	if(!formula_press_turf)
		formula_press_turf = get_turf(owner)
	return ..()

/datum/action/cooldown/spell/formula_live_cast/proc/speak_formula_words()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return
	while(currently_charging && word_speak_index <= length(formula_phrase_words))
		var/datum/formula_magic_word/word = resolve_formula_magic_word(formula_phrase_words[word_speak_index])
		if(word)
			H.say(word.get_phrase(), forced = "spell", language = /datum/language/common)
		word_speak_index++
		var/rank = word?.school_id ? (H.mind?.formula_magic_known_words[word.id] || 0) : 0
		var/speed_mult = max(0.1, 1 - (rank * 0.1))
		sleep(max(2, round((word?.cast_time || charge_time) * speed_mult)))

/datum/action/cooldown/spell/formula_live_cast/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !H.mind)
		return FALSE
	var/list/live_words = H.mind.formula_magic_live_words?.Copy() || list()
	if(!length(live_words) || cast_on == H)
		var/datum/formula_magic_cast_panel/panel = new(H)
		panel.ui_interact(H)
		return TRUE
	return H.mind.perform_formula_magic_cast(H, live_words, cast_on, FALSE, formula_press_turf)

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
	var/word_speak_index = 1
	var/turf/formula_press_turf

/datum/action/cooldown/spell/formula_preset/New(list/preset, preset_index = 1)
	if(islist(preset))
		name = preset["name"] || "Formula [preset_index]"
		desc = preset["summary"] || "A prepared modular formula."
		var/list/preset_words = preset["words"]
		formula_words = preset_words?.Copy() || list()
		button_icon_state = formula_magic_icon_state_for_words(formula_words)
		var/mana = preset["mana_cost"] || 1
		var/cast_ticks = preset["cast_time"] || 10
		primary_resource_cost = max(1, round(mana * 2))
		charge_time = max(3, cast_ticks)
		cooldown_time = max(3 SECONDS, (preset["complexity"] || 1) * 2 SECONDS)
	. = ..()

/datum/action/cooldown/spell/formula_preset/on_start_charge()
	. = ..()
	word_speak_index = 1
	formula_phrase_words = formula_words.Copy()
	INVOKE_ASYNC(src, PROC_REF(speak_formula_words))

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
	while(currently_charging && word_speak_index <= length(formula_phrase_words))
		var/datum/formula_magic_word/word = resolve_formula_magic_word(formula_phrase_words[word_speak_index])
		if(word)
			H.say(word.get_phrase(), forced = "spell", language = /datum/language/common)
		word_speak_index++
		var/rank = word?.school_id ? (H.mind?.formula_magic_known_words[word.id] || 0) : 0
		var/speed_mult = max(0.1, 1 - (rank * 0.1))
		sleep(max(2, round((word?.cast_time || charge_time) * speed_mult)))

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
