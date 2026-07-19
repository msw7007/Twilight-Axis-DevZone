// Shape handlers are the routing layer between parsed formula parts and payload execution.
// New form or combo behavior belongs here, not in the central executor.

/datum/formula_magic_shape
	var/id
	var/list/incompatible_modifiers = list()
	var/list/max_modifier_counts = list()

/datum/formula_magic_shape/proc/validation_error(datum/formula_magic_part/part)
	if(!part)
		return "missing formula part"
	for(var/modifier_id in incompatible_modifiers)
		if(part.tags[modifier_id])
			return "incompatible [id] modifier"
	for(var/modifier_id in max_modifier_counts)
		var/max_allowed = max_modifier_counts[modifier_id]
		if((part.tags[modifier_id] || 0) >= max_allowed)
			return "overloaded [id] modifier"
	return null

/datum/formula_magic_shape/proc/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return FALSE

/datum/formula_magic_shape/orb
	id = FORMULA_FORM_ORB

/datum/formula_magic_shape/orb/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_orb_part(context, part)

/datum/formula_magic_shape/touch
	id = FORMULA_FORM_TOUCH
	incompatible_modifiers = list("ricochet", "pierce", "shrapnel")

/datum/formula_magic_shape/touch/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_touch_part(context, part)

/datum/formula_magic_shape/moment
	id = FORMULA_FORM_INSTANT
	incompatible_modifiers = list("pierce", "shrapnel")

/datum/formula_magic_shape/moment/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_moment_part(context, part)

/datum/formula_magic_shape/spiral
	id = FORMULA_FORM_SPIRAL
	incompatible_modifiers = list("shrapnel")

/datum/formula_magic_shape/spiral/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_spiral_part(context, part)

/datum/formula_magic_shape/summon
	id = FORMULA_FORM_SUMMON
	incompatible_modifiers = list("ricochet", "chain", "pierce", "shrapnel")

/datum/formula_magic_shape/summon/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_summon_part(context, part)

/datum/formula_magic_shape/beam
	id = FORMULA_FORM_BEAM

/datum/formula_magic_shape/beam/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_beam_part(context, part)

/datum/formula_magic_shape/guidance
	id = FORMULA_FORM_GUIDANCE
	incompatible_modifiers = list("ricochet", "chain", "pierce", "shrapnel")

/datum/formula_magic_shape/guidance/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_guidance_part(context, part)

/datum/formula_magic_shape/wave
	id = FORMULA_FORM_WAVE
	incompatible_modifiers = list("pierce")

/datum/formula_magic_shape/wave/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_wave_part(context, part)

/datum/formula_magic_shape/aura
	id = FORMULA_FORM_AURA
	incompatible_modifiers = list("existence", "chain", "shrapnel")
	max_modifier_counts = list("pierce" = 5)

/datum/formula_magic_shape/aura/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_aura_part(context, part)

/datum/formula_magic_shape/nova
	id = FORMULA_FORM_NOVA
	incompatible_modifiers = list("pierce", "shrapnel")

/datum/formula_magic_shape/nova/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_nova_part(context, part)

/datum/formula_magic_shape/seeker
	id = "seeker"

/datum/formula_magic_shape/seeker/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_seeker_part(context, part)

/datum/formula_magic_shape/breath
	id = FORMULA_FORM_BREATH
	incompatible_modifiers = list("pierce", "shrapnel")

/datum/formula_magic_shape/breath/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_breath_part(context, part)

/datum/formula_magic_shape/fall
	id = FORMULA_FORM_FALL
	incompatible_modifiers = list("pierce")

/datum/formula_magic_shape/fall/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_meteor_part(context, part, repeat_index)

/datum/formula_magic_shape/cloak
	id = FORMULA_FORM_CLOAK
	incompatible_modifiers = list("pierce", "shrapnel")

/datum/formula_magic_shape/cloak/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_cloak_part(context, part)

/datum/formula_magic_shape/rune
	id = FORMULA_FORM_RUNE
	incompatible_modifiers = list("existence")

/datum/formula_magic_shape/rune/cast(datum/formula_magic_context/context, datum/formula_magic_part/part, repeat_index = 1)
	return formula_magic_execute_rune_part(context, part, repeat_index)

/proc/formula_magic_shape_type_for_id(shape_id)
	switch(shape_id)
		if(FORMULA_FORM_ORB)
			return /datum/formula_magic_shape/orb
		if(FORMULA_FORM_TOUCH)
			return /datum/formula_magic_shape/touch
		if(FORMULA_FORM_INSTANT)
			return /datum/formula_magic_shape/moment
		if(FORMULA_FORM_SPIRAL)
			return /datum/formula_magic_shape/spiral
		if(FORMULA_FORM_SUMMON)
			return /datum/formula_magic_shape/summon
		if(FORMULA_FORM_BEAM)
			return /datum/formula_magic_shape/beam
		if(FORMULA_FORM_GUIDANCE)
			return /datum/formula_magic_shape/guidance
		if(FORMULA_FORM_WAVE)
			return /datum/formula_magic_shape/wave
		if(FORMULA_FORM_AURA)
			return /datum/formula_magic_shape/aura
		if(FORMULA_FORM_NOVA)
			return /datum/formula_magic_shape/nova
		if("seeker")
			return /datum/formula_magic_shape/seeker
		if(FORMULA_FORM_BREATH)
			return /datum/formula_magic_shape/breath
		if(FORMULA_FORM_FALL)
			return /datum/formula_magic_shape/fall
		if(FORMULA_FORM_CLOAK)
			return /datum/formula_magic_shape/cloak
		if(FORMULA_FORM_RUNE)
			return /datum/formula_magic_shape/rune
	return null

/proc/formula_magic_shape_for_id(shape_id)
	var/shape_type = formula_magic_shape_type_for_id(shape_id)
	if(!shape_type)
		return null
	return new shape_type

/proc/formula_magic_cast_shape(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, repeat_index = 1)
	var/datum/formula_magic_shape/shape = formula_magic_shape_for_id(shape_id)
	if(!shape)
		return FALSE
	var/error = shape.validation_error(part)
	if(error)
		return formula_magic_detonate_formula_part(context.caster, part, error)
	return shape.cast(context, part, repeat_index)

/proc/formula_magic_validate_shape(datum/formula_magic_part/part, shape_id)
	var/datum/formula_magic_shape/shape = formula_magic_shape_for_id(shape_id)
	if(!shape)
		return "unknown formula shape"
	return shape.validation_error(part)

/datum/formula_magic_modifier_behavior
	var/id

/datum/formula_magic_modifier_behavior/proc/count(datum/formula_magic_part/part)
	if(!part || !id)
		return 0
	return max(0, part.tags[id] || 0)

/datum/formula_magic_modifier_behavior/proc/apply_area(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	return FALSE

/datum/formula_magic_modifier_behavior/existence
	id = "existence"

/datum/formula_magic_modifier_behavior/existence/apply_area(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	if(count(part) <= 0 || !length(affected_turfs))
		return FALSE
	return formula_magic_schedule_existence_repeats(context.caster, part, affected_turfs, power, 0)

/datum/formula_magic_modifier_behavior/chain
	id = "chain"

/datum/formula_magic_modifier_behavior/chain/apply_area(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	var/chain_count = count(part)
	if(chain_count <= 0)
		return FALSE
	switch(shape_id)
		if(FORMULA_FORM_TOUCH, FORMULA_FORM_INSTANT, FORMULA_FORM_SPIRAL)
			return formula_magic_apply_moment_chain(context.caster, part, center, power, hit_targets)
		if(FORMULA_FORM_NOVA, FORMULA_FORM_CLOAK)
			return formula_magic_apply_nova_chain(context.caster, part, center, power, max(1, radius || 1), hit_targets)
	return FALSE

/datum/formula_magic_modifier_behavior/ricochet
	id = "ricochet"

/datum/formula_magic_modifier_behavior/ricochet/apply_area(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	if(count(part) <= 0)
		return FALSE
	switch(shape_id)
		if(FORMULA_FORM_INSTANT)
			return formula_magic_apply_moment_ricochet(context.caster, part, center, power)
		if(FORMULA_FORM_NOVA, FORMULA_FORM_CLOAK)
			return formula_magic_apply_nova_ricochet(context.caster, part, center, power, max(1, radius || 1))
	return FALSE

/datum/formula_magic_modifier_behavior/shrapnel
	id = "shrapnel"

/datum/formula_magic_modifier_behavior/shrapnel/apply_area(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	if(count(part) <= 0)
		return FALSE
	if(shape_id == FORMULA_FORM_WAVE && length(hit_targets) > 1)
		return formula_magic_apply_wave_shrapnel(context.caster, part, center, power, hit_targets)
	return FALSE

/proc/formula_magic_modifier_behavior_for_id(modifier_id)
	switch(modifier_id)
		if("existence")
			return new /datum/formula_magic_modifier_behavior/existence
		if("chain")
			return new /datum/formula_magic_modifier_behavior/chain
		if("ricochet")
			return new /datum/formula_magic_modifier_behavior/ricochet
		if("shrapnel")
			return new /datum/formula_magic_modifier_behavior/shrapnel
	return null

/proc/formula_magic_apply_area_modifier_handlers(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	if(!context || !part)
		return FALSE
	var/applied = FALSE
	for(var/modifier_id in list("existence", "ricochet", "chain", "shrapnel"))
		if(formula_magic_apply_shape_modifier_behavior(context, part, shape_id, modifier_id, center, power, radius, affected_turfs, hit_targets))
			applied = TRUE
	return applied

/proc/formula_magic_apply_shape_modifier_behavior(datum/formula_magic_context/context, datum/formula_magic_part/part, shape_id, modifier_id, turf/center, power, radius, list/affected_turfs, list/hit_targets)
	if(!context || !part || !modifier_id || (part.tags[modifier_id] || 0) <= 0)
		return FALSE
	switch(modifier_id)
		if("existence")
			switch(shape_id)
				if(FORMULA_FORM_AURA, FORMULA_FORM_RUNE)
					return FALSE
				if(FORMULA_FORM_SUMMON)
					return formula_magic_schedule_existence_repeats(context.caster, part, affected_turfs, power, 0)
				else
					return formula_magic_apply_matrix_existence(context.caster, part, affected_turfs, power)
		if("ricochet")
			switch(shape_id)
				if(FORMULA_FORM_TOUCH, FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE)
					return FALSE
				if(FORMULA_FORM_INSTANT, FORMULA_FORM_CLOAK)
					return formula_magic_apply_moment_ricochet(context.caster, part, center, power)
				if(FORMULA_FORM_NOVA, FORMULA_FORM_BREATH)
					return formula_magic_apply_nova_ricochet(context.caster, part, center, power, max(1, radius || 1))
				if(FORMULA_FORM_SPIRAL)
					return FALSE // Spiral ricochet is handled by reversing the spiral runner.
		if("chain")
			switch(shape_id)
				if(FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE, FORMULA_FORM_AURA)
					return FALSE
				if(FORMULA_FORM_TOUCH, FORMULA_FORM_INSTANT, FORMULA_FORM_SPIRAL, FORMULA_FORM_CLOAK)
					return formula_magic_apply_moment_chain(context.caster, part, center, power, hit_targets)
				if(FORMULA_FORM_NOVA, FORMULA_FORM_BREATH)
					return formula_magic_apply_nova_chain(context.caster, part, center, power, max(1, radius || 1), hit_targets)
		if("shrapnel")
			switch(shape_id)
				if(FORMULA_FORM_WAVE)
					if(length(hit_targets) > 1)
						return formula_magic_apply_wave_shrapnel(context.caster, part, center, power, hit_targets)
				else
					return FALSE
	return FALSE
