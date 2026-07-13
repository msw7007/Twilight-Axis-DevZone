/datum/formula_magic_word
	var/id
	var/name = "Word"
	var/desc = ""
	var/school_id
	var/role = FORMULA_WORD_ELEMENT
	var/tier = 1
	var/mana_cost = 1
	var/cast_time = 10
	var/complexity = 1
	var/instability = 0
	var/unlock_level = 1
	var/learn_cost = 1
	var/repeatable = TRUE
	var/is_stop_word = FALSE
	var/list/tags = list()
	var/list/phrases = list()

/datum/formula_magic_word/proc/apply_to(datum/formula_magic_formula/formula)
	if(!formula)
		return
	formula.mana_cost += mana_cost
	formula.cast_time += cast_time
	formula.complexity += complexity
	formula.instability += instability
	formula.add_school(school_id)
	for(var/tag in tags)
		formula.add_tag(tag)
	switch(role)
		if(FORMULA_WORD_FORM)
			formula.forms += id
			if(!formula.primary_form)
				formula.primary_form = id
		if(FORMULA_WORD_ELEMENT)
			formula.elements += id
		if(FORMULA_WORD_MODIFIER)
			formula.modifiers += id
		if(FORMULA_WORD_POST_EFFECT)
			formula.post_effects += id
		if(FORMULA_WORD_LINK)
			formula.links += id

/datum/formula_magic_word/proc/get_entry()
	return list(
		"id" = id,
		"name" = name,
		"desc" = desc,
		"school_id" = school_id,
		"role" = role,
		"tier" = tier,
		"mana_cost" = mana_cost,
		"cast_time" = cast_time,
		"complexity" = complexity,
		"instability" = instability,
		"unlock_level" = unlock_level,
		"learn_cost" = learn_cost,
		"repeatable" = repeatable,
		"is_stop_word" = is_stop_word,
		"tags" = tags.Copy(),
		"phrases" = phrases.Copy(),
	)

/datum/formula_magic_word/proc/get_phrase()
	if(length(phrases))
		return phrases[1]
	return "Asha."

/datum/formula_magic_word/form/orb
	id = FORMULA_FORM_ORB
	name = "Orb"
	desc = "A projectile sphere. Repeating the form creates additional spheres."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 12
	complexity = 2
	tags = list("projectile", "impact_bloom")
	phrases = list("Orbis nascitur.", "Globus ardet.", "Circulus volat.")

/datum/formula_magic_word/form/orb/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.projectile_count += 1

/datum/formula_magic_word/form/aura
	id = FORMULA_FORM_AURA
	name = "Aura"
	desc = "A defensive self-centered spell carried by the caster."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 10
	tags = list("self", "persistent")
	phrases = list("Circa me.", "Aegis spirat.", "Intra cutem.")

/datum/formula_magic_word/form/aura/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.duration += 30 SECONDS
	formula.radius += 1

/datum/formula_magic_word/form/cloak
	id = FORMULA_FORM_CLOAK
	name = "Cloak"
	desc = "An aggressive self-centered pulse around the caster."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 10
	complexity = 2
	tags = list("self", "persistent", "cloak")
	phrases = list("Pallium mordet.", "Circa feri.", "Ora mea ardet.")

/datum/formula_magic_word/form/cloak/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.duration += 30 SECONDS
	formula.radius += 1

/datum/formula_magic_word/form/instant
	id = FORMULA_FORM_INSTANT
	name = "Moment"
	desc = "Point-targeted immediate handling between caster and destination."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("point", "moment")
	phrases = list("Nunc et ibi.", "Punctum aperi.", "Interstitium.")

/datum/formula_magic_word/form/instant/apply_to(datum/formula_magic_formula/formula)
	..()
	var/moment_words = formula.tags["moment"] || 1
	formula.range = 4 + (moment_words - 1)

/datum/formula_magic_word/form/fall
	id = FORMULA_FORM_FALL
	name = "Meteor"
	desc = "A visible strike from above. Base fall time is one second plus one second per elemental word; repeated meteor words reduce the final delay by 10% each."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 12
	complexity = 2
	tags = list("point", "delayed", "meteor")
	phrases = list("Meteorum.", "De caelo veni.", "Cadat super.")

/datum/formula_magic_word/form/fall/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.delay = 1 SECONDS
	formula.radius = max(formula.radius, 1)

/datum/formula_magic_word/form/summon
	id = FORMULA_FORM_SUMMON
	name = "Summon"
	desc = "Conjures equipment, tools, weapons, or temporary matter."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 14
	complexity = 2
	tags = list("summon")
	phrases = list("Forma veni.", "Ex nihilo ferri.", "Vocatum tene.")

/datum/formula_magic_word/form/summon/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.duration += 120

/datum/formula_magic_word/form/rune
	id = FORMULA_FORM_RUNE
	name = "Rune"
	desc = "Places a delayed trap on the ground."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 14
	complexity = 2
	tags = list("trap", "ground")
	phrases = list("Signum sede.", "Rune dormi.", "Sub pede late.")

/datum/formula_magic_word/form/rune/apply_to(datum/formula_magic_formula/formula)
	..()
	var/rune_words = formula.tags["trap"] || 1
	formula.duration = max(formula.duration, 60 SECONDS + ((rune_words - 1) * 30 SECONDS))

/datum/formula_magic_word/form/guidance
	id = FORMULA_FORM_GUIDANCE
	name = "Guidance"
	desc = "Draws magic between two selected points."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 12
	complexity = 2
	tags = list("line", "two_points")
	phrases = list("Duo puncta iunge.", "Linea vivat.", "Trahe iter.")

/datum/formula_magic_word/form/guidance/apply_to(datum/formula_magic_formula/formula)
	..()
	var/guidance_words = formula.tags["line"] || 1
	formula.range = 3 + (guidance_words - 1)

/datum/formula_magic_word/form/wave
	id = FORMULA_FORM_WAVE
	name = "Wave"
	desc = "Sends the formula forward in three traveling lines."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 10
	complexity = 2
	tags = list("wave")
	phrases = list("Unda.", "In fronte curre.", "Via findatur.")

/datum/formula_magic_word/form/wave/apply_to(datum/formula_magic_formula/formula)
	..()
	var/wave_words = formula.tags["wave"] || 1
	formula.range = 6 + (wave_words - 1)

/datum/formula_magic_word/form/breath
	id = FORMULA_FORM_BREATH
	name = "Breath"
	desc = "Exhales the formula as a short expanding cone in front of the caster."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 10
	complexity = 2
	tags = list("breath", "cone")
	phrases = list("Halitus.", "Ex ore fluat.", "Spira vim.")

/datum/formula_magic_word/form/breath/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.range = 3

/datum/formula_magic_word/form/nova
	id = FORMULA_FORM_NOVA
	name = "Nova"
	desc = "Releases the formula outward from the caster."
	role = FORMULA_WORD_FORM
	mana_cost = 2
	cast_time = 10
	complexity = 2
	tags = list("self", "burst")
	phrases = list("Nova.", "Circa rumpat.", "Unda nascitur.")

/datum/formula_magic_word/form/nova/apply_to(datum/formula_magic_formula/formula)
	..()
	var/nova_words = formula.tags["burst"] || 1
	formula.radius = max(formula.radius, 2 + (nova_words - 1))

/datum/formula_magic_word/form/touch
	id = FORMULA_FORM_TOUCH
	name = "Touch"
	desc = "Releases the formula into an adjacent tile only."
	role = FORMULA_WORD_FORM
	mana_cost = 1
	cast_time = 6
	tags = list("touch")
	phrases = list("Tactus.", "Manus fert.", "Prope feri.")

/datum/formula_magic_word/form/touch/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.range = 1

/datum/formula_magic_word/element/fire
	id = "fire"
	name = "Fire"
	desc = "Adds fire damage as the base effect."
	school_id = FORMULA_SCHOOL_PYROMANCY
	tags = list("damage_burn")
	phrases = list("Ignis.", "Flamma surge.", "Calor morde.")

/datum/formula_magic_word/element/fire/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 8

/datum/formula_magic_word/post_effect/burning
	id = "burning"
	name = "Burning"
	desc = "Ignites struck targets."
	school_id = FORMULA_SCHOOL_PYROMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("ignite")
	phrases = list("Arde.", "Favilla haere.", "Carbo vivit.")

/datum/formula_magic_word/modifier/widen
	id = "widen"
	name = "Widen"
	desc = "Expands the area of a formula. Repeating it scales radius aggressively."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 2
	complexity = 2
	tags = list("radius")
	phrases = list("Amplia.", "Latius fiat.", "Circulus crescat.")

/datum/formula_magic_word/modifier/widen/apply_to(datum/formula_magic_formula/formula)
	..()
	var/repeats = formula.tags["radius"] || 1
	formula.radius += max(1, 2 ** (repeats - 1))
	formula.instability += max(0, repeats - 2)

/datum/formula_magic_word/element/frost
	id = "frost"
	name = "Frost"
	desc = "Adds cold damage as the base effect."
	school_id = FORMULA_SCHOOL_CRYOMANCY
	tags = list("damage_cold")
	phrases = list("Glacies.", "Rime sede.", "Frigus tene.")

/datum/formula_magic_word/element/frost/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 5

/datum/formula_magic_word/post_effect/frostbite
	id = "frostbite"
	name = "Frostbite"
	desc = "Adds escalating frost stacks and possible frost burst."
	school_id = FORMULA_SCHOOL_CRYOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("frost_stack")
	phrases = list("Morde gelu.", "Tertium frange.", "Nix in ossa.")

/datum/formula_magic_word/element/lightning
	id = "lightning"
	name = "Lightning"
	desc = "Adds fast lightning damage."
	school_id = FORMULA_SCHOOL_FULGURMANCY
	cast_time = 7
	tags = list("damage_shock")
	phrases = list("Fulmen.", "Scintilla currat.", "Tonitrus celer.")

/datum/formula_magic_word/element/lightning/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 6

/datum/formula_magic_word/post_effect/discharge
	id = "discharge"
	name = "Discharge"
	desc = "Adds electrocution and brief disruption."
	school_id = FORMULA_SCHOOL_FULGURMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("electrocute")
	phrases = list("Exsolve.", "Nervos percute.", "Arcus saliat.")

/datum/formula_magic_word/element/stone
	id = "stone"
	name = "Stone"
	desc = "Adds blunt earthen force."
	school_id = FORMULA_SCHOOL_GEOMANCY
	tags = list("damage_blunt")
	phrases = list("Terra.", "Saxum surgat.", "Pondus feri.")

/datum/formula_magic_word/element/stone/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 7

/datum/formula_magic_word/post_effect/shrapnel
	id = "shrapnel"
	name = "Shrapnel"
	desc = "Splinters impact into stone fragments."
	school_id = FORMULA_SCHOOL_GEOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("fragments")
	phrases = list("Frange in spicula.", "Lapides sparge.", "Grana vulnera.")

/datum/formula_magic_word/post_effect/repulse
	id = "repulse"
	name = "Repulse"
	desc = "Pushes struck targets away. Formula power increases push distance."
	school_id = FORMULA_SCHOOL_KINESIS
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	tags = list("push")
	phrases = list("Repelle.", "Retro cade.", "Spatium pulsa.")

/datum/formula_magic_word/post_effect/gravity
	id = "gravity"
	name = "Gravity"
	desc = "Adds crushing gravity and movement suppression."
	school_id = FORMULA_SCHOOL_KINESIS
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 3
	tags = list("gravity", "slow")
	phrases = list("Gravitas preme.", "Pondus mundi.", "Ad terram.")

/datum/formula_magic_word/post_effect/pull
	id = "pull"
	name = "Pull"
	desc = "Draws struck targets toward the impact."
	school_id = FORMULA_SCHOOL_KINESIS
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 1
	tags = list("pull")
	phrases = list("Trahe.", "Ad centrum.", "Veni huc.")

/datum/formula_magic_word/element/shift
	id = "shift"
	name = "Translation"
	desc = "Moves the caster or formula through the space between places."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	tags = list("teleport")
	phrases = list("Translatio.", "Gradus nullus.", "Spatium plica.")

/datum/formula_magic_word/post_effect/phase
	id = "phase"
	name = "Phase"
	desc = "Adds partial ethereal movement."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	tags = list("phase")
	phrases = list("Umbra corporis.", "Dimidium extra.", "Per carnem via.")

/datum/formula_magic_word/element/holdfast
	id = "holdfast"
	name = "Holdfast"
	desc = "Counters displacement by anchoring struck targets in place."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 2
	tags = list("anchor_target")
	phrases = list("Tene.", "Locus tene.", "Nodus figat.")

/datum/formula_magic_word/post_effect/stat_strength
	id = "stat_strength"
	name = "Strength"
	desc = "Augments strength."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("buff_strength")
	phrases = list("Robur brachii.", "Fortis esto.", "Vis carnis.")

/datum/formula_magic_word/post_effect/stat_speed
	id = "stat_speed"
	name = "Speed"
	desc = "Augments speed."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("buff_speed")
	phrases = list("Pes celer.", "Velox esto.", "Tempus curre.")

/datum/formula_magic_word/post_effect/stat_perception
	id = "stat_perception"
	name = "Perception"
	desc = "Augments perception."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("buff_perception")
	phrases = list("Oculus aperi.", "Vide plus.", "Sensus acue.")

/datum/formula_magic_word/post_effect/stat_intelligence
	id = "stat_intelligence"
	name = "Intelligence"
	desc = "Augments intelligence."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("buff_intelligence")
	phrases = list("Mens luceat.", "Ratio cresce.", "Cogitatio alta.")

/datum/formula_magic_word/post_effect/stat_constitution
	id = "stat_constitution"
	name = "Constitution"
	desc = "Augments constitution."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("buff_constitution")
	phrases = list("Corpus firma.", "Vita tene.", "Carne dura.")

/datum/formula_magic_word/post_effect/stat_willpower
	id = "stat_willpower"
	name = "Willpower"
	desc = "Augments willpower."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("buff_willpower")
	phrases = list("Voluntas ferrea.", "Animus sta.", "Cor noli frangi.")

/datum/formula_magic_word/post_effect/darkvision
	id = "formula_darkvision"
	name = "Darkvision"
	desc = "Grants improved sight in darkness."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("darkvision")
	phrases = list("Nox aperi.", "Vide tenebras.", "Oculus noctis.")

/datum/formula_magic_word/post_effect/nondetection
	id = "nondetection"
	name = "Nondetection"
	desc = "Softens the target's magical signature against notice."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("nondetection")
	phrases = list("Lateo.", "Signum taceat.", "Umbra mentis.")

/datum/formula_magic_word/post_effect/mind
	id = "mind"
	name = "Mind"
	desc = "Touches thought, memory, speech, and mental contact."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 1
	tags = list("mind")
	phrases = list("Mens aperi.", "Cogitatio iunge.", "Vox intus.")

/datum/formula_magic_word/post_effect/silence
	id = "silence"
	name = "Silence"
	desc = "Suppresses speech through mental pressure."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("silence")
	phrases = list("Tace.", "Vox claudatur.", "Silentium sede.")

/datum/formula_magic_word/post_effect/softfall
	id = "softfall"
	name = "Softfall"
	desc = "Turns falling momentum aside."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("softfall")
	phrases = list("Leniter cade.", "Aer sustine.", "Gradus mollis.")

/datum/formula_magic_word/post_effect/reduce_size
	id = "reduce_size"
	name = "Diminish"
	desc = "Draws the body inward and makes the target seem smaller."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("size_down")
	phrases = list("Minor esto.", "Forma intra.", "Corpus contrahatur.")

/datum/formula_magic_word/post_effect/curse_strength
	id = "curse_strength"
	name = "Wither Strength"
	desc = "Weakens strength."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("debuff_strength")
	phrases = list("Robur cadat.", "Brachium languescat.", "Vis solvatur.")

/datum/formula_magic_word/post_effect/curse_speed
	id = "curse_speed"
	name = "Wither Speed"
	desc = "Slows bodily tempo."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("debuff_speed")
	phrases = list("Pes haereat.", "Motus frange.", "Tardus esto.")

/datum/formula_magic_word/post_effect/curse_perception
	id = "curse_perception"
	name = "Wither Perception"
	desc = "Dulls perception."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("debuff_perception")
	phrases = list("Oculus claudat.", "Sensus obruat.", "Vide minus.")

/datum/formula_magic_word/post_effect/curse_intelligence
	id = "curse_intelligence"
	name = "Wither Intelligence"
	desc = "Clouds thought."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("debuff_intelligence")
	phrases = list("Mens caliget.", "Ratio rumpatur.", "Cogitatio labat.")

/datum/formula_magic_word/post_effect/curse_constitution
	id = "curse_constitution"
	name = "Wither Constitution"
	desc = "Weakens bodily endurance."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("debuff_constitution")
	phrases = list("Corpus marceat.", "Vita langueat.", "Carne fragilis.")

/datum/formula_magic_word/post_effect/curse_willpower
	id = "curse_willpower"
	name = "Wither Willpower"
	desc = "Breaks resolve."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("debuff_willpower")
	phrases = list("Animus cadat.", "Voluntas frange.", "Cor tremat.")

/datum/formula_magic_word/post_effect/curse_blindness
	id = "curse_blindness"
	name = "Blindness"
	desc = "Covers sight with a grey malediction."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("curse_blindness")
	phrases = list("Caecitas.", "Lux moriatur.", "Oculus cinis.")

/datum/formula_magic_word/post_effect/stumble
	id = "stumble"
	name = "Stumble"
	desc = "Turns footing against the target."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 1
	unlock_level = 1
	tags = list("stumble")
	phrases = list("Pes cadat.", "Gradus frange.", "Terra fallat.")

/datum/formula_magic_word/post_effect/enlarge
	id = "enlarge"
	name = "Enlarge"
	desc = "Bloats the target's presence and frame."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("size_up")
	phrases = list("Maior esto.", "Forma tumescat.", "Corpus crescat.")

/datum/formula_magic_word/post_effect/reveal
	id = "reveal"
	name = "Reveal"
	desc = "Presses hidden signatures into notice."
	school_id = FORMULA_SCHOOL_CURSES
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 2
	tags = list("reveal")
	phrases = list("Latebra pereat.", "Signum appare.", "Occultum nudetur.")

/datum/formula_magic_word/element/iron
	id = "iron"
	name = "Iron"
	desc = "Shapes metal, tools, wards, or blades."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	tags = list("metal")
	phrases = list("Ferrum.", "Chalybs pare.", "Malleus somni.")

/datum/formula_magic_word/element/iron/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 6

/datum/formula_magic_word/post_effect/blade
	id = "blade"
	name = "Blade"
	desc = "Forms cutting metal as the payload or trap."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	tags = list("cut", "weapon")
	phrases = list("Lamina.", "Acies aperi.", "Seca.")

/datum/formula_magic_word/post_effect/ward
	id = "ward"
	name = "Ward"
	desc = "Turns the formula into protection or a warding trigger."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	tags = list("ward")
	phrases = list("Custodia.", "Tutela sta.", "Sigillum serva.")

/datum/formula_magic_word/post_effect/armor
	id = "armor"
	name = "Armor"
	desc = "Shapes a protective metal shell."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 2
	tags = list("armor")
	phrases = list("Lorica.", "Ferrum protegat.", "Carapax sta.")

/datum/formula_magic_word/post_effect/mending
	id = "mending"
	name = "Mending"
	desc = "Repairs shaped matter and artificial bodies."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("repair")
	phrases = list("Reficio.", "Fractum iunge.", "Opera sana.")

/datum/formula_magic_word/element/life
	id = "life"
	name = "Life"
	desc = "Animates living patterns and familiar spirits."
	school_id = FORMULA_SCHOOL_LIFE
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 10
	complexity = 2
	unlock_level = 1
	tags = list("life")
	phrases = list("Vita.", "Spiritus surgat.", "Anima tene.")

/datum/formula_magic_word/element/death
	id = "death"
	name = "Death"
	desc = "Shapes bones, deadite echoes, and lifeless servants."
	school_id = FORMULA_SCHOOL_LIFE
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 10
	complexity = 2
	unlock_level = 1
	tags = list("death")
	phrases = list("Mors.", "Ossa surgant.", "Cinis pare.")

/datum/formula_magic_word/link/sequence
	id = "sequence"
	name = "Sequence"
	desc = "Links multiple forms in order, such as Orb + Arrow."
	role = FORMULA_WORD_LINK
	is_stop_word = TRUE
	mana_cost = 1
	complexity = 2
	tags = list("sequence")
	phrases = list("Deinde.", "Post hoc.", "Vinculum sequitur.")

/datum/formula_magic_word/link/sequence/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.projectile_count += max(0, length(formula.forms) - 1)

/datum/formula_magic_word/stabilizer/anchor
	id = "anchor"
	name = "Anchor"
	desc = "Stabilizes long formulae at the cost of time and mana."
	role = FORMULA_WORD_STABILIZER
	is_stop_word = TRUE
	mana_cost = 2
	cast_time = 16
	complexity = -2
	tags = list("stable")
	phrases = list("Ancora.", "Stabilis esto.", "Nodus tene.")

/datum/formula_magic_word/stabilizer/anchor/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.instability = max(0, formula.instability - 2)

/datum/formula_magic_word/modifier/efficient
	id = "efficient"
	name = "Efficiency"
	desc = "Reduces mana/fatigue cost."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 0
	cast_time = 8
	complexity = 1
	tags = list("efficient")
	phrases = list("Parce.", "Minor pretium.", "Levis sumptus.")

/datum/formula_magic_word/modifier/efficient/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.mana_cost = max(1, round(formula.mana_cost * 0.75))

/datum/formula_magic_word/modifier/trigger_child
	id = "trigger_child"
	name = "Triggered Chain"
	desc = "Marks the formula as able to trigger another prepared formula at impact in future scroll work."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 2
	complexity = 2
	tags = list("trigger_child")
	phrases = list("Post ictum.", "Altera porta.", "Ex vulnere sequitur.")

/datum/formula_magic_word/modifier/ricochet
	id = "ricochet"
	name = "Ricochet"
	desc = "After impact, the formula rebounds along the impact angle. Repeating the word adds another rebound."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("ricochet")
	phrases = list("Resilio.", "Angulus redit.", "Ictus reflectitur.")

/datum/formula_magic_word/modifier/chain
	id = "chain"
	name = "Chain"
	desc = "After impact, the formula leaps to the nearest other target. Repeating the word adds another leap."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("chain")
	phrases = list("Catena.", "Hostem quaere.", "Ictus sequitur.")

/datum/formula_magic_word/modifier/pierce
	id = "pierce"
	name = "Pierce"
	desc = "Lets projectiles pass through a struck target. Repeating it adds another pierced target."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("pierce")
	phrases = list("Perfora.", "Transi carnem.", "Iter per hostem.")
