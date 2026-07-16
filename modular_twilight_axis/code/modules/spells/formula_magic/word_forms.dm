/datum/formula_magic_word/form/orb
	id = FORMULA_FORM_ORB
	name = "Orb"
	desc = "A projectile arcyne sphere. Repeating the word adds another full-strength orb to the same part."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 2
	cast_time = 12
	complexity = 2
	tags = list("projectile", "arcane_payload")
	phrases = list("Orbis.", "Globus.", "Arcanum volat.")

/datum/formula_magic_word/form/orb/apply_to_part(datum/formula_magic_part/part)
	..()
	part.projectile_count += 1
	part.power = max(part.power, 30)

/datum/formula_magic_word/form/aura
	id = FORMULA_FORM_AURA
	name = "Aura"
	desc = "A self-centered defensive form unlocked from Summon. Repeating it extends the protected working."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 2
	cast_time = 10
	complexity = 2
	tags = list("self", "aura")
	phrases = list("Aura.", "Circa me.", "Intra cutem.")

/datum/formula_magic_word/form/aura/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.duration += 30 SECONDS

/datum/formula_magic_word/form/instant
	id = FORMULA_FORM_INSTANT
	name = "Moment"
	desc = "A point form. Repeating it increases maximum target distance; point impact is slightly below baseline force."
	role = FORMULA_WORD_FORM
	learn_cost = 2
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("point", "moment")
	phrases = list("Momentum.", "Nunc ibi.", "Punctum.")

/datum/formula_magic_word/form/instant/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.range = max(part.range, 3 + max(0, part.tags["moment"] || 0))

/datum/formula_magic_word/form/beam
	id = FORMULA_FORM_BEAM
	name = "Beam"
	desc = "A direct instant line. Cursor sets direction; it strikes 10 tiles plus one per extra word. Damage starts below baseline and fades by 10% per tile, reduced by 1% per extra word."
	role = FORMULA_WORD_FORM
	learn_cost = 2
	mana_cost = 3
	cast_time = 4
	complexity = 3
	tags = list("beam")
	phrases = list("Radius.", "Linea.", "Lux recta.")

/datum/formula_magic_word/form/beam/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.range = max(part.range, 10 + max(0, (part.tags["beam"] || 1) - 1))

/datum/formula_magic_word/form/spiral
	id = FORMULA_FORM_SPIRAL
	name = "Spiral"
	desc = "A rotating form around the caster. One word makes one full circle at half payload force; Widen increases travel radius, and extra words split additional arms evenly around the circle."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 2
	cast_time = 10
	complexity = 2
	tags = list("spiral")
	phrases = list("Spira.", "Gyro.", "Circulus ambulat.")

/datum/formula_magic_word/form/spiral/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.duration += 1 SECONDS

/datum/formula_magic_word/form/summon
	id = FORMULA_FORM_SUMMON
	name = "Summon"
	desc = "A creation form at the target point. Direct impact is below baseline, while created payloads may use their own behavior."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 1
	cast_time = 10
	complexity = 2
	tags = list("summon")
	phrases = list("Evoca.", "Forma veni.", "Ex nihilo.")

/datum/formula_magic_word/form/summon/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.duration = max(part.duration, 5 MINUTES)
	part.duration += max(0, (part.tags["summon"] || 1) - 1) * 10 SECONDS

/datum/formula_magic_word/form/wave
	id = FORMULA_FORM_WAVE
	name = "Wave"
	desc = "A moving line. Each contact is below baseline force to preserve damage over travel."
	role = FORMULA_WORD_FORM
	learn_cost = 3
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("wave")
	phrases = list("Unda.", "Impulsus.", "Frons procedit.")

/datum/formula_magic_word/form/wave/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.range = max(part.range, 6 + max(0, (part.tags["wave"] || 1) - 1))

/datum/formula_magic_word/form/touch
	id = FORMULA_FORM_TOUCH
	name = "Touch"
	desc = "A fast close form for the adjacent tile. It hits above baseline because it is melee range."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 1
	cast_time = 7
	complexity = 1
	tags = list("touch")
	phrases = list("Tango.", "Manus.", "Prope.")

/datum/formula_magic_word/form/touch/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)

/datum/formula_magic_word/form/guidance
	id = FORMULA_FORM_GUIDANCE
	name = "Guidance"
	desc = "A line designation form. Its hits are slightly below baseline force."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("guidance")
	phrases = list("Ductio.", "Linea signa.", "Iter iube.")

/datum/formula_magic_word/form/guidance/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.range = max(part.range, 3 + max(0, (part.tags["guidance"] || 1) - 1))

/datum/formula_magic_word/form/nova
	id = FORMULA_FORM_NOVA
	name = "Nova"
	desc = "A circular pulse. Each hit is below baseline because the shape is broad."
	role = FORMULA_WORD_FORM
	learn_cost = 1
	mana_cost = 3
	cast_time = 10
	complexity = 3
	tags = list("nova")
	phrases = list("Nova.", "Circulus rumpit.", "Omne latus.")

/datum/formula_magic_word/form/nova/apply_to_part(datum/formula_magic_part/part)
	..()
	part.power = max(part.power, 30)
	part.radius = max(part.radius, 1 + max(0, (part.tags["nova"] || 1) - 1))

