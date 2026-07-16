/datum/formula_magic_word/element/force
	id = "force"
	name = "Force"
	desc = "Changes the payload into direct kinetic force."
	school_id = FORMULA_SCHOOL_KINESIS
	cast_time = 7
	complexity = 2
	tags = list("damage_force")
	phrases = list("Vis.", "Ictus animi.", "Contere.")

/datum/formula_magic_word/element/force/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BRUTE
	part.impact_flag = "blunt"
	part.impact_color = "#D7A51E"

/datum/formula_magic_word/element/repulse
	id = "repulse"
	name = "Repulse"
	desc = "Pushes struck targets away."
	school_id = FORMULA_SCHOOL_KINESIS
	mana_cost = 2
	complexity = 2
	tags = list("push")
	phrases = list("Repelle.", "Retro cade.", "Spatium pulsa.")

/datum/formula_magic_word/element/gravity
	id = "gravity"
	name = "Gravity"
	desc = "Adds crushing gravity and movement suppression."
	school_id = FORMULA_SCHOOL_KINESIS
	mana_cost = 3
	complexity = 3
	tags = list("gravity", "slow")
	phrases = list("Gravitas preme.", "Pondus mundi.", "Ad terram.")

/datum/formula_magic_word/element/pull
	id = "pull"
	name = "Pull"
	desc = "Draws struck targets toward the impact."
	school_id = FORMULA_SCHOOL_KINESIS
	mana_cost = 2
	complexity = 2
	tags = list("pull")
	phrases = list("Trahe.", "Ad centrum.", "Veni huc.")

/datum/formula_magic_word/element/cleanse
	id = "cleanse"
	name = "Cleanse"
	desc = "Scours grime and debris from affected ground and objects."
	school_id = FORMULA_SCHOOL_KINESIS
	mana_cost = 1
	cast_time = 5
	complexity = 1
	tags = list("cleanse")
	phrases = list("Purga.", "Mundus fiat.", "Sordes abi.")

/datum/formula_magic_word/element/shift
	id = "shift"
	name = "Translation"
	desc = "Bends space for movement and displacement effects."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	tags = list("teleport")
	phrases = list("Translatio.", "Gradus nullus.", "Spatium plica.")

/datum/formula_magic_word/element/phase
	id = "phase"
	name = "Phase"
	desc = "Adds partial ethereal movement."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	mana_cost = 2
	complexity = 2
	tags = list("phase")
	phrases = list("Umbra corporis.", "Dimidium extra.", "Per carnem via.")

/datum/formula_magic_word/element/holdfast
	id = "holdfast"
	name = "Holdfast"
	desc = "Anchors struck targets in place."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 2
	tags = list("anchor_target")
	phrases = list("Tene.", "Locus tene.", "Nodus figat.")

