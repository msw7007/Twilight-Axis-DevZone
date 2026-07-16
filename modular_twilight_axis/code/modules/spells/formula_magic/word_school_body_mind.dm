/datum/formula_magic_word/element/stat_strength
	id = "stat_strength"
	name = "Strength"
	desc = "Augments strength when carried by a protective form."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("buff_strength")
	phrases = list("Robur brachii.", "Fortis esto.", "Vis carnis.")

/datum/formula_magic_word/element/stat_speed
	id = "stat_speed"
	name = "Speed"
	desc = "Augments speed when carried by a protective form."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("buff_speed")
	phrases = list("Pes celer.", "Velox esto.", "Tempus curre.")

/datum/formula_magic_word/element/stat_perception
	id = "stat_perception"
	name = "Perception"
	desc = "Augments perception when carried by a protective form."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("buff_perception")
	phrases = list("Oculus aperi.", "Vide plus.", "Sensus acue.")

/datum/formula_magic_word/element/stat_intelligence
	id = "stat_intelligence"
	name = "Intelligence"
	desc = "Augments intelligence when carried by a protective form."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("buff_intelligence")
	phrases = list("Mens luceat.", "Ratio cresce.", "Cogitatio alta.")

/datum/formula_magic_word/element/stat_constitution
	id = "stat_constitution"
	name = "Constitution"
	desc = "Augments constitution when carried by a protective form."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("buff_constitution")
	phrases = list("Corpus firma.", "Vita tene.", "Carne dura.")

/datum/formula_magic_word/element/stat_willpower
	id = "stat_willpower"
	name = "Willpower"
	desc = "Augments willpower when carried by a protective form."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("buff_willpower")
	phrases = list("Voluntas ferrea.", "Animus sta.", "Cor noli frangi.")

/datum/formula_magic_word/element/darkvision
	id = "formula_darkvision"
	name = "Darkvision"
	desc = "Grants improved sight in darkness."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("darkvision")
	phrases = list("Nox aperi.", "Vide tenebras.", "Oculus noctis.")

/datum/formula_magic_word/element/nondetection
	id = "nondetection"
	name = "Nondetection"
	desc = "Softens the target's magical signature against notice."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("nondetection")
	phrases = list("Lateo.", "Signum taceat.", "Umbra mentis.")

/datum/formula_magic_word/element/softfall
	id = "softfall"
	name = "Softfall"
	desc = "Turns falling momentum aside."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 2
	complexity = 1
	tags = list("softfall")
	phrases = list("Leniter cade.", "Aer sustine.", "Gradus mollis.")

/datum/formula_magic_word/element/mind
	id = "mind"
	name = "Mind"
	desc = "Touches thought, speech, and mental contact. Hostile hits confuse briefly."
	school_id = FORMULA_SCHOOL_GENERAL
	mana_cost = 2
	complexity = 2
	tags = list("mind")
	phrases = list("Mens aperi.", "Cogitatio iunge.", "Vox intus.")

/datum/formula_magic_word/element/silence
	id = "silence"
	name = "Silence"
	desc = "Suppresses speech through mental pressure."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("silence")
	phrases = list("Tace.", "Vox claudatur.", "Silentium sede.")

/datum/formula_magic_word/element/curse_strength
	id = "curse_strength"
	name = "Wither Strength"
	desc = "Weakens strength."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 1
	tags = list("debuff_strength")
	phrases = list("Robur cadat.", "Brachium languescat.", "Vis solvatur.")

/datum/formula_magic_word/element/curse_speed
	id = "curse_speed"
	name = "Wither Speed"
	desc = "Slows bodily tempo."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 1
	tags = list("debuff_speed")
	phrases = list("Pes haereat.", "Motus frange.", "Tardus esto.")

/datum/formula_magic_word/element/curse_perception
	id = "curse_perception"
	name = "Wither Perception"
	desc = "Dulls perception."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 1
	tags = list("debuff_perception")
	phrases = list("Oculus claudat.", "Sensus obruat.", "Vide minus.")

/datum/formula_magic_word/element/curse_intelligence
	id = "curse_intelligence"
	name = "Wither Intelligence"
	desc = "Clouds thought."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 1
	tags = list("debuff_intelligence")
	phrases = list("Mens caliget.", "Ratio rumpatur.", "Cogitatio labat.")

/datum/formula_magic_word/element/curse_constitution
	id = "curse_constitution"
	name = "Wither Constitution"
	desc = "Weakens bodily endurance."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 1
	tags = list("debuff_constitution")
	phrases = list("Corpus marceat.", "Vita langueat.", "Carne fragilis.")

/datum/formula_magic_word/element/curse_willpower
	id = "curse_willpower"
	name = "Wither Willpower"
	desc = "Breaks resolve."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 1
	tags = list("debuff_willpower")
	phrases = list("Animus cadat.", "Voluntas frange.", "Cor tremat.")

/datum/formula_magic_word/element/curse_blindness
	id = "curse_blindness"
	name = "Blindness"
	desc = "Covers sight with a grey malediction."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("curse_blindness")
	phrases = list("Caecitas.", "Lux moriatur.", "Oculus cinis.")

/datum/formula_magic_word/element/reveal
	id = "reveal"
	name = "Reveal"
	desc = "Presses hidden signatures into notice."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 2
	complexity = 2
	unlock_level = 2
	tags = list("reveal")
	phrases = list("Latebra pereat.", "Signum appare.", "Occultum nudetur.")

