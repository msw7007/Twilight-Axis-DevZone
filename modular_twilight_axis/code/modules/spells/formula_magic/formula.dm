#if 0
// OLD FORMULA MAGIC REFERENCE. DO NOT EXECUTE.
// Full rewrite starts below this reference block. Port old behavior only by explicit request.
/datum/formula_magic_formula
	var/list/words = list()
	var/list/forms = list()
	var/list/schools = list()
	var/list/elements = list()
	var/list/modifiers = list()
	var/list/post_effects = list()
	var/list/links = list()
	var/list/tags = list()
	var/primary_form
	var/power = 10
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
	var/list/sequence_segments = list()

/datum/formula_magic_formula/proc/add_word(word_or_path)
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_or_path)
	if(!word)
		return FALSE
	words.Insert(length(words) + 1, word)
	word.apply_to(src)
	word_cast_times.Insert(length(word_cast_times) + 1, max(1, word.cast_time))
	return TRUE

/datum/formula_magic_formula/proc/add_tag(tag, amount = 1)
	if(!tag)
		return
	tags[tag] = (tags[tag] || 0) + amount

/datum/formula_magic_formula/proc/add_school(school_id)
	if(!school_id)
		return
	if(!(school_id in schools))
		schools += school_id

/datum/formula_magic_formula/proc/can_resolve()
	return length(forms) || tags["prebuilt_formula"]

/datum/formula_magic_formula/proc/get_word_names()
	var/list/names = list()
	for(var/datum/formula_magic_word/word in words)
		names.Insert(length(names) + 1, word.name)
	return names

/datum/formula_magic_formula/proc/get_formula_text()
	var/list/names = get_word_names()
	if(!length(names))
		return "Empty formula"
	return jointext(names, " + ")

/datum/formula_magic_formula/proc/get_summary()
	return list(
		"text" = get_formula_text(),
		"can_resolve" = can_resolve(),
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
		"sequence_segments" = sequence_segments.Copy(),
	)

/datum/formula_magic_formula/proc/clear()
	words = list()
	forms = list()
	schools = list()
	elements = list()
	modifiers = list()
	post_effects = list()
	links = list()
	tags = list()
	primary_form = null
	power = 10
	radius = 0
	range = 7
	duration = 0
	delay = 0
	projectile_count = 0
	mana_cost = 0
	cast_time = 0
	complexity = 0
	instability = 0
	interrupt_chance = 10
	word_cast_times = list()
	sequence_segments = list()

#endif


/datum/formula_magic_context
	var/mob/living/carbon/human/caster
	var/atom/cast_on
	var/turf/target_turf
	var/turf/source_turf

/datum/formula_magic_part
	var/list/words = list()
	var/list/forms = list()
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
	return form_id == FORMULA_FORM_ORB && projectile_count > 0

/datum/formula_magic_part/proc/execute(datum/formula_magic_context/context)
	if(!can_execute() || !context)
		return FALSE
	if(form_id == FORMULA_FORM_ORB)
		return formula_magic_execute_orb_part(context, src)
	return FALSE

/datum/formula_magic_part/proc/get_summary()
	return list(
		"text" = get_text(),
		"forms" = forms.Copy(),
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
	var/list/sequence_segments = list()

/datum/formula_magic_formula/proc/add_word(word_or_path)
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_or_path)
	if(!word)
		return FALSE
	words += word
	word_cast_times += max(1, word.cast_time)
	rebuild_parts()
	return TRUE

/datum/formula_magic_formula/proc/rebuild_parts()
	parts = list()
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
	return length(parts) && projectile_count > 0

/datum/formula_magic_formula/proc/get_word_names()
	var/list/names = list()
	for(var/datum/formula_magic_word/word in words)
		names += word.name
	return names

/datum/formula_magic_formula/proc/get_formula_text()
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
		"sequence_segments" = sequence_segments.Copy(),
	)

/datum/formula_magic_formula/proc/clear()
	words = list()
	word_cast_times = list()
	rebuild_parts()
