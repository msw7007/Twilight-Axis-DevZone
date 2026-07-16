/datum/formula_magic_word/element/fire
	id = "fire"
	name = "Fire"
	desc = "Changes the payload into fire damage."
	school_id = FORMULA_SCHOOL_PYROMANCY
	tags = list("damage_burn")
	phrases = list("Ignis.", "Flamma surge.", "Calor morde.")

/datum/formula_magic_word/element/fire/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BURN
	part.impact_flag = "fire"
	part.impact_color = "#FF5A1F"

/datum/formula_magic_word/element/burning
	id = "burning"
	name = "Burning"
	desc = "Ignites struck targets. More ranks add more fire stacks."
	school_id = FORMULA_SCHOOL_PYROMANCY
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("ignite")
	phrases = list("Arde.", "Favilla haere.", "Carbo vivit.")

/datum/formula_magic_word/element/frost
	id = "frost"
	name = "Frost"
	desc = "Changes the payload into cold damage."
	school_id = FORMULA_SCHOOL_CRYOMANCY
	tags = list("damage_cold")
	phrases = list("Glacies.", "Rime sede.", "Frigus tene.")

/datum/formula_magic_word/element/frost/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BURN
	part.impact_flag = "cold"
	part.impact_color = "#8FE8FF"

/datum/formula_magic_word/element/frostbite
	id = "frostbite"
	name = "Frostbite"
	desc = "Adds frost stacks and damps fire."
	school_id = FORMULA_SCHOOL_CRYOMANCY
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("frost_stack", "extinguish")
	phrases = list("Morde gelu.", "Tertium frange.", "Nix in ossa.")

/datum/formula_magic_word/element/lightning
	id = "lightning"
	name = "Lightning"
	desc = "Changes the payload into shock damage."
	school_id = FORMULA_SCHOOL_FULGURMANCY
	cast_time = 7
	tags = list("damage_shock")
	phrases = list("Fulmen.", "Scintilla currat.", "Tonitrus celer.")

/datum/formula_magic_word/element/lightning/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BURN
	part.impact_flag = "electric"
	part.impact_color = "#FFFFFF"

/datum/formula_magic_word/element/discharge
	id = "discharge"
	name = "Discharge"
	desc = "Adds electrocution and brief disruption."
	school_id = FORMULA_SCHOOL_FULGURMANCY
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("electrocute")
	phrases = list("Exsolve.", "Nervos percute.", "Arcus saliat.")

/datum/formula_magic_word/element/stone
	id = "stone"
	name = "Stone"
	desc = "Changes the payload into blunt earthen force."
	school_id = FORMULA_SCHOOL_GEOMANCY
	tags = list("damage_blunt")
	phrases = list("Terra.", "Saxum surgat.", "Pondus feri.")

/datum/formula_magic_word/element/stone/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BRUTE
	part.impact_flag = "blunt"
	part.impact_color = "#8B5E34"

/datum/formula_magic_word/element/dirt
	id = "dirt"
	name = "Dirt"
	desc = "Slows struck targets. Summon can shape temporary earth."
	school_id = FORMULA_SCHOOL_GEOMANCY
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("dirt", "slow")
	phrases = list("Lutum.", "Terra lenta.", "Pedem tene.")

