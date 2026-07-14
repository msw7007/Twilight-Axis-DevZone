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
