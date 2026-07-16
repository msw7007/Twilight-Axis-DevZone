/datum/formula_magic_word/element/iron
	id = "iron"
	name = "Iron"
	desc = "Shapes hard metal force and iron impact."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	tags = list("metal")
	phrases = list("Ferrum.", "Chalybs pare.", "Malleus somni.")

/datum/formula_magic_word/element/iron/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BRUTE
	part.impact_flag = "blunt"
	part.impact_color = "#36B36A"

/datum/formula_magic_word/element/blade
	id = "blade"
	name = "Blade"
	desc = "Plants a spinning arcyne blade in the affected zone."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	mana_cost = 2
	complexity = 2
	tags = list("blade_field")
	phrases = list("Lamina.", "Acies aperi.", "Seca.")

/datum/formula_magic_word/element/repair
	id = "repair"
	name = "Repair"
	desc = "Restores shaped matter and artificial bodies."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	mana_cost = 4
	cast_time = 18
	complexity = 3
	unlock_level = 2
	tags = list("repair")
	phrases = list("Reficio.", "Fractum iunge.", "Opera sana.")

/datum/formula_magic_word/element/creation
	id = "creation"
	name = "Creation"
	desc = "Animates short-lived predatory plant matter."
	school_id = FORMULA_SCHOOL_BIOMANCY
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("creation")
	phrases = list("Vita.", "Spiritus surgat.", "Anima tene.")

/datum/formula_magic_word/element/enlarge
	id = "enlarge"
	name = "Enlarge"
	desc = "Bloats the target's presence and frame."
	school_id = FORMULA_SCHOOL_BIOMANCY
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("size_up")
	phrases = list("Maior esto.", "Forma tumescat.", "Corpus crescat.")

/datum/formula_magic_word/element/reduce_size
	id = "reduce_size"
	name = "Diminish"
	desc = "Draws the body inward and makes the target seem smaller."
	school_id = FORMULA_SCHOOL_BIOMANCY
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("size_down")
	phrases = list("Minor esto.", "Forma intra.", "Corpus contrahatur.")

/datum/formula_magic_word/element/bone
	id = "bone"
	name = "Bone"
	desc = "Hurls a bone-hard arcyne impact."
	school_id = FORMULA_SCHOOL_NECROMANCY
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("bone")
	phrases = list("Mors.", "Ossa surgant.", "Cinis pare.")

/datum/formula_magic_word/element/bone/apply_to_part(datum/formula_magic_part/part)
	..()
	part.impact_damage_type = BRUTE
	part.impact_flag = "blunt"
	part.impact_color = "#6B6B6B"
	part.power = max(part.power, 40)

/datum/formula_magic_word/element/time
	id = "time"
	name = "Time"
	desc = "Binds the formula to Origin timeflow and adds temporal stress."
	school_id = FORMULA_SCHOOL_CHRONOMANCY
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("time")
	phrases = list("Tempus.", "Origo temporis.", "Momentum ligat.")

/datum/formula_magic_word/element/restoration
	id = "restoration"
	name = "Restoration"
	desc = "Recalls an earlier bodily state at a high mana cost."
	school_id = FORMULA_SCHOOL_CHRONOMANCY
	mana_cost = 25
	cast_time = 16
	complexity = 4
	unlock_level = 2
	tags = list("time", "temporal_restore", "chronomancy_full")
	phrases = list("Memoria corporis.", "Redi integer.", "Forma prior.")
