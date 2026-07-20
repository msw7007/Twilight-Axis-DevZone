/datum/formula_magic_context
	var/mob/living/carbon/human/caster
	var/atom/cast_on
	var/turf/target_turf
	var/turf/source_turf

/datum/formula_magic_part
	var/list/words = list()
	var/list/forms = list()
	var/list/schools = list()
	var/list/elements = list()
	var/list/modifiers = list()
	var/list/tags = list()
	var/form_id
	var/power = 0
	var/range = 7
	var/radius = 0
	var/duration = 0
	var/impact_damage_type = BRUTE
	var/impact_flag = "blunt"
	var/impact_woundclass = BCLASS_BLUNT
	var/impact_intdamfactor = BLUNT_DEFAULT_INT_DAMAGEFACTOR
	var/impact_color = "#B96DFF"
	var/projectile_count = 0
	var/mana_cost = 0
	var/cast_time = 0
	var/complexity = 0
	var/touch_cast_time = 0

/datum/formula_magic_part/proc/add_word(datum/formula_magic_word/word)
	if(!word)
		return FALSE
	words += word
	word.apply_to_part(src)
	return TRUE

/datum/formula_magic_part/proc/add_tag(tag, amount = 1)
	if(!tag)
		return
	tags[tag] = (tags[tag] || 0) + amount

/datum/formula_magic_part/proc/get_word_names()
	var/list/names = list()
	for(var/datum/formula_magic_word/word in words)
		names += word.name
	return names

/datum/formula_magic_part/proc/get_text()
	var/list/names = get_word_names()
	if(!length(names))
		return "Empty part"
	return jointext(names, " + ")

/datum/formula_magic_part/proc/can_execute()
	return length(forms) > 0

/proc/formula_magic_touch_cast_time(base_time, touch_count)
	var/time = max(1, base_time || 1)
	for(var/i in 2 to max(1, touch_count || 1))
		time *= 0.9
	return max(max(1, touch_count || 1), round(time))

/proc/formula_magic_part_has_payload_words(datum/formula_magic_part/part)
	if(!part)
		return FALSE
	if(length(part.elements) || length(part.schools))
		return TRUE
	for(var/tag in part.tags)
		switch(tag)
			if("projectile", "arcane_payload", "self", "aura", "point", "moment", "beam", "spiral", "summon", "wave", "touch", "guidance", "nova")
				continue
			if("widen", "existence", "existence_duration", "efficient", "ricochet", "chain", "pierce", "shrapnel")
				continue
			if("payload_repeat_delay", "payload_zone_duration")
				continue
		return TRUE
	return FALSE

/datum/formula_magic_part/proc/execute(datum/formula_magic_context/context)
	if(!can_execute() || !context)
		return FALSE
	return formula_magic_execute_part(context, src)

/datum/formula_magic_part/proc/get_summary()
	return list(
		"text" = get_text(),
		"forms" = forms.Copy(),
		"schools" = schools.Copy(),
		"elements" = elements.Copy(),
		"modifiers" = modifiers.Copy(),
		"tags" = tags.Copy(),
		"form_id" = form_id,
		"power" = power,
		"range" = range,
		"radius" = radius,
		"duration" = duration,
		"impact_damage_type" = impact_damage_type,
		"impact_flag" = impact_flag,
		"impact_woundclass" = impact_woundclass,
		"impact_color" = impact_color,
		"projectile_count" = projectile_count,
		"mana_cost" = mana_cost,
		"cast_time" = cast_time,
		"complexity" = complexity,
	)

/datum/formula_magic_formula
	var/list/words = list()
	var/list/parts = list()
	var/datum/formula_magic_combo_formula/combo_formula
	var/list/forms = list()
	var/list/schools = list()
	var/list/elements = list()
	var/list/modifiers = list()
	var/list/post_effects = list()
	var/list/links = list()
	var/list/tags = list()
	var/primary_form
	var/power = 0
	var/radius = 0
	var/range = 7
	var/duration = 0
	var/delay = 0
	var/projectile_count = 0
	var/mana_cost = 0
	var/cast_time = 0
	var/complexity = 0
	var/instability = 0
	var/interrupt_chance = 10
	var/list/word_cast_times = list()

/datum/formula_magic_formula/proc/add_word(word_or_path)
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_or_path)
	if(!word)
		return FALSE
	words += word
	rebuild_parts()
	return TRUE

/datum/formula_magic_formula/proc/rebuild_parts()
	parts = list()
	combo_formula = null
	forms = list()
	schools = list()
	elements = list()
	modifiers = list()
	post_effects = list()
	links = list()
	tags = list()
	primary_form = null
	power = 0
	radius = 0
	range = 7
	duration = 0
	delay = 0
	projectile_count = 0
	mana_cost = 0
	cast_time = 0
	complexity = 0
	instability = 0
	var/datum/formula_magic_part/current_part = new
	for(var/datum/formula_magic_word/word in words)
		current_part.add_word(word)
	if(length(current_part.words))
		parts += current_part
	else
		qdel(current_part)
	compile_from_parts()
	combo_formula = formula_magic_find_exact_combo_formula(get_word_ids())
	if(combo_formula)
		combo_formula.apply_to_formula(src)
	rebuild_word_cast_times()

/datum/formula_magic_formula/proc/rebuild_word_cast_times()
	word_cast_times = list()
	var/list/touch_indices = list()
	var/touch_base_time = 0
	for(var/i in 1 to length(words))
		var/datum/formula_magic_word/word = words[i]
		if(word?.id != FORMULA_FORM_TOUCH)
			continue
		touch_indices += i
		if(!touch_base_time)
			touch_base_time = word.cast_time
	var/touch_count = length(touch_indices)
	var/list/touch_delays = list()
	if(touch_count)
		var/touch_total = max(touch_count, formula_magic_touch_cast_time(touch_base_time, touch_count))
		var/touch_base_delay = FLOOR(touch_total / touch_count, 1)
		var/touch_remainder = touch_total - (touch_base_delay * touch_count)
		for(var/i in 1 to touch_count)
			touch_delays += max(1, touch_base_delay + (i <= touch_remainder ? 1 : 0))
	var/touch_delay_index = 1
	for(var/datum/formula_magic_word/word in words)
		if(word?.id == FORMULA_FORM_TOUCH && length(touch_delays))
			word_cast_times += touch_delays[touch_delay_index]
			touch_delay_index++
			continue
		word_cast_times += max(1, word?.cast_time || FORMULA_DEFAULT_WORD_DELAY)

/datum/formula_magic_formula/proc/compile_from_parts()
	for(var/datum/formula_magic_part/part in parts)
		mana_cost += part.mana_cost
		cast_time += part.cast_time
		complexity += part.complexity
		power = max(power, part.power)
		range = max(range, part.range)
		radius = max(radius, part.radius)
		duration = max(duration, part.duration)
		projectile_count += part.projectile_count
		for(var/form_id in part.forms)
			forms += form_id
			if(!primary_form)
				primary_form = form_id
		for(var/school_id in part.schools)
			add_school(school_id)
		for(var/element_id in part.elements)
			elements += element_id
		for(var/modifier_id in part.modifiers)
			modifiers += modifier_id
		for(var/tag in part.tags)
			add_tag(tag, part.tags[tag])

/datum/formula_magic_formula/proc/add_tag(tag, amount = 1)
	if(!tag)
		return
	tags[tag] = (tags[tag] || 0) + amount

/datum/formula_magic_formula/proc/add_school(school_id)
	if(!school_id || (school_id in schools))
		return
	schools += school_id

/datum/formula_magic_formula/proc/can_resolve()
	return combo_formula || (length(parts) && length(forms))

/datum/formula_magic_formula/proc/get_word_ids()
	var/list/word_ids = list()
	for(var/datum/formula_magic_word/word in words)
		word_ids += word.id
	return word_ids

/datum/formula_magic_formula/proc/get_word_names()
	var/list/names = list()
	for(var/datum/formula_magic_word/word in words)
		names += word.name
	return names

/datum/formula_magic_formula/proc/get_formula_text()
	if(combo_formula)
		return combo_formula.name
	var/list/names = get_word_names()
	if(!length(names))
		return "Empty formula"
	return jointext(names, " + ")

/datum/formula_magic_formula/proc/get_summary()
	var/list/part_summaries = list()
	for(var/datum/formula_magic_part/part in parts)
		part_summaries += list(part.get_summary())
	return list(
		"text" = get_formula_text(),
		"can_resolve" = can_resolve(),
		"combo_formula" = combo_formula?.get_entry(),
		"parts" = part_summaries,
		"forms" = forms.Copy(),
		"schools" = schools.Copy(),
		"elements" = elements.Copy(),
		"modifiers" = modifiers.Copy(),
		"post_effects" = post_effects.Copy(),
		"links" = links.Copy(),
		"tags" = tags.Copy(),
		"primary_form" = primary_form,
		"power" = power,
		"radius" = radius,
		"range" = range,
		"duration" = duration,
		"delay" = delay,
		"projectile_count" = projectile_count,
		"mana_cost" = mana_cost,
		"cast_time" = cast_time,
		"complexity" = complexity,
		"instability" = instability,
		"interrupt_chance" = interrupt_chance,
		"word_cast_times" = word_cast_times.Copy(),
	)

/datum/formula_magic_formula/proc/clear()
	words = list()
	word_cast_times = list()
	rebuild_parts()
