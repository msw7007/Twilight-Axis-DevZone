GLOBAL_LIST_EMPTY(formula_magic_combo_formulas_by_id)
GLOBAL_LIST_EMPTY(formula_magic_combo_formula_entries)

/datum/formula_magic_combo_formula
	var/id
	var/name = "Fixed Formula"
	var/desc = ""
	var/list/word_ids = list()
	var/mana_cost = 0
	var/cast_time = 0
	var/complexity = 0

/datum/formula_magic_combo_formula/proc/get_entry()
	return list(
		"id" = id,
		"name" = name,
		"desc" = desc,
		"words" = word_ids.Copy(),
		"mana_cost" = mana_cost,
		"cast_time" = cast_time,
		"complexity" = complexity,
	)

/datum/formula_magic_combo_formula/proc/matches(list/normalized_words)
	return formula_magic_word_lists_match(word_ids, normalized_words)

/datum/formula_magic_combo_formula/proc/is_contained_in(list/normalized_words)
	if(!length(word_ids) || length(word_ids) > length(normalized_words))
		return FALSE
	var/max_start = length(normalized_words) - length(word_ids) + 1
	for(var/start_index in 1 to max_start)
		var/matched = TRUE
		for(var/offset in 1 to length(word_ids))
			if(normalized_words[start_index + offset - 1] != word_ids[offset])
				matched = FALSE
				break
		if(matched)
			return TRUE
	return FALSE

/datum/formula_magic_combo_formula/proc/apply_to_formula(datum/formula_magic_formula/formula)
	if(!formula)
		return
	if(mana_cost)
		formula.mana_cost = mana_cost
	if(cast_time)
		formula.cast_time = cast_time
	if(complexity)
		formula.complexity = complexity

/datum/formula_magic_combo_formula/proc/execute(datum/formula_magic_context/context, datum/formula_magic_formula/formula)
	return FALSE

/datum/formula_magic_combo_formula/create_campfire
	id = "create_campfire"
	name = "Create Campfire"
	desc = "A fixed hearthcraft formula. It raises a magical campfire and refuses all added words."
	word_ids = list(FORMULA_FORM_SUMMON, "fire")
	mana_cost = 5
	cast_time = 30
	complexity = 3

/datum/formula_magic_combo_formula/create_campfire/execute(datum/formula_magic_context/context, datum/formula_magic_formula/formula)
	var/mob/living/carbon/human/caster = context?.caster
	var/turf/target = context?.target_turf
	if(!caster || !target)
		return FALSE
	if(!target.Enter(caster) || is_type_in_list(target, list(/turf/open/water, /turf/open/transparent, /turf/closed/transparent)))
		to_chat(caster, span_warning("The fixed fire formula refuses this ground."))
		return FALSE
	new /obj/machinery/light/rogue/campfire/create_campfire(target)
	caster.visible_message(span_notice("[caster] calls a blue campfire from the formula."), span_notice("I call a blue campfire from the fixed formula."))
	return TRUE

/datum/formula_magic_combo_formula/fridigitation
	id = "fridigitation"
	name = "Fridigitation"
	desc = "A fixed cryomantic utility formula. It deep-freezes prepared food and rejects all additions."
	word_ids = list(FORMULA_FORM_SUMMON, "frost")
	mana_cost = 4
	cast_time = 12
	complexity = 2

/datum/formula_magic_combo_formula/fridigitation/execute(datum/formula_magic_context/context, datum/formula_magic_formula/formula)
	var/mob/living/carbon/human/caster = context?.caster
	if(!caster)
		return FALSE
	if(!istype(context?.cast_on, /obj/item/reagent_containers/food/snacks/rogue))
		to_chat(caster, span_warning("That is not valid food for Fridigitation."))
		return FALSE
	var/obj/item/reagent_containers/food/snacks/rogue/F = context.cast_on
	var/turf/T = get_turf(F)
	F.rotprocess = null
	F.add_filter("fridigitation_glow", 2, list("type" = "outline", "color" = "#87CEEB", "alpha" = 150, "size" = 1))
	if(T)
		var/mutable_appearance/chilly = mutable_appearance('icons/effects/effects.dmi', "mist", layer = 10)
		T.add_overlay(chilly)
		addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), chilly), 1 SECONDS)
	if(!findtext(F.name, "(frozen)"))
		F.name = "[F.name] (frozen)"
	to_chat(caster, span_notice("The [F.name] freezes hard and still."))
	return TRUE

/datum/formula_magic_combo_formula/mindlink
	id = "mindlink"
	name = "Mindlink"
	desc = "A fixed neuromantic formula. It binds two known minds for a short telepathic link."
	word_ids = list(FORMULA_FORM_AURA, "mind", "existence")
	mana_cost = 8
	cast_time = 20
	complexity = 4

/datum/formula_magic_combo_formula/mindlink/execute(datum/formula_magic_context/context, datum/formula_magic_formula/formula)
	var/mob/living/carbon/human/caster = context?.caster
	if(!caster || !caster.mind)
		return FALSE
	if(!caster.mind.known_people.len)
		to_chat(caster, span_warning("I know no people well enough to bind their thoughts."))
		return FALSE
	var/list/possible_targets = list()
	for(var/people in caster.mind.known_people)
		possible_targets += people
	possible_targets = sortList(possible_targets)
	if(caster.client)
		possible_targets = list(caster.real_name) + possible_targets
	var/first_target_name = tgui_input_list(caster, "Choose the first person to link", "Mindlink", possible_targets)
	if(!first_target_name)
		return FALSE
	var/mob/living/first_target
	for(var/mob/living/carbon/human/HL in GLOB.human_list)
		if(HL.real_name == first_target_name)
			first_target = HL
			break
	if(!first_target)
		to_chat(caster, span_warning("That mind slips beyond my reach."))
		return FALSE
	possible_targets -= first_target_name
	if(!length(possible_targets))
		to_chat(caster, span_warning("I have no second mind to bind."))
		return FALSE
	var/second_target_name = tgui_input_list(caster, "Choose the second person to link", "Mindlink", possible_targets)
	if(!second_target_name)
		return FALSE
	var/mob/living/second_target
	for(var/mob/living/carbon/human/HL in GLOB.human_list)
		if(HL.real_name == second_target_name)
			second_target = HL
			break
	if(!second_target)
		to_chat(caster, span_warning("That mind slips beyond my reach."))
		return FALSE
	for(var/datum/mindlink/ML in GLOB.mindlinks)
		if(ML && (ML.owner == first_target || ML.target == first_target || ML.owner == second_target || ML.target == second_target))
			to_chat(caster, span_warning("A mindlink already binds one of the targets."))
			return FALSE
	caster.emote("me", 1, "'s eyes briefly glow with an otherworldly light.", TRUE, custom_me = TRUE)
	caster.visible_message(span_notice("[caster] touches their temples and concentrates..."), span_notice("I establish a mental connection between [first_target] and [second_target]..."))
	var/datum/mindlink/link = new(first_target, second_target)
	GLOB.mindlinks += link
	to_chat(first_target, span_notice("A mindlink has been established with [second_target]! Use ,Y before a message to communicate telepathically. Use ,mst to break the link."))
	to_chat(second_target, span_notice("A mindlink has been established with [first_target]! Use ,Y before a message to communicate telepathically. Use ,mst to break the link."))
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_break_combo_mindlink), link), 3 MINUTES)
	return TRUE

/proc/formula_magic_break_combo_mindlink(datum/mindlink/link)
	if(!link || QDELETED(link))
		return
	if(link.owner)
		to_chat(link.owner, span_warning("The mindlink with [link.target] fades away..."))
	if(link.target)
		to_chat(link.target, span_warning("The mindlink with [link.owner] fades away..."))
	GLOB.mindlinks -= link
	qdel(link)

/proc/init_formula_magic_combo_formulas()
	GLOB.formula_magic_combo_formulas_by_id = list()
	GLOB.formula_magic_combo_formula_entries = list()
	for(var/path in subtypesof(/datum/formula_magic_combo_formula))
		var/datum/formula_magic_combo_formula/combo = new path
		if(!combo.id || !length(combo.word_ids))
			qdel(combo)
			continue
		GLOB.formula_magic_combo_formulas_by_id[combo.id] = combo
		GLOB.formula_magic_combo_formula_entries += list(combo.get_entry())

/proc/get_formula_magic_combo_templates()
	if(!length(GLOB.formula_magic_combo_formulas_by_id))
		init_formula_magic_combo_formulas()
	var/list/result = list()
	for(var/id in GLOB.formula_magic_combo_formulas_by_id)
		result += GLOB.formula_magic_combo_formulas_by_id[id]
	return result

/proc/get_formula_magic_combo_entries()
	if(!length(GLOB.formula_magic_combo_formula_entries))
		init_formula_magic_combo_formulas()
	return GLOB.formula_magic_combo_formula_entries.Copy()

/proc/formula_magic_normalized_word_sequence(list/word_ids)
	var/list/normalized_words = list()
	if(!islist(word_ids))
		return normalized_words
	for(var/word_id in word_ids)
		var/normalized_id = formula_magic_normalize_word_id(word_id)
		if(normalized_id)
			normalized_words += normalized_id
	return normalized_words

/proc/formula_magic_find_exact_combo_formula(list/word_ids)
	var/list/normalized_words = formula_magic_normalized_word_sequence(word_ids)
	for(var/datum/formula_magic_combo_formula/combo in get_formula_magic_combo_templates())
		if(combo.matches(normalized_words))
			return combo
	return null

/proc/formula_magic_find_contained_combo_formula(list/word_ids)
	var/list/normalized_words = formula_magic_normalized_word_sequence(word_ids)
	for(var/datum/formula_magic_combo_formula/combo in get_formula_magic_combo_templates())
		if(combo.is_contained_in(normalized_words))
			return combo
	return null
