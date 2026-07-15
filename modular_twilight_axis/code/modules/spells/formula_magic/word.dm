#if 0
// OLD FORMULA MAGIC REFERENCE. DO NOT EXECUTE.
// Full rewrite starts below this reference block. Port old behavior only by explicit request.
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
	var/list/required_school_points = list()
	var/list/phrases = list()
	var/list/spoken_phrases = list()

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
			formula.forms.Insert(length(formula.forms) + 1, id)
			if(!formula.primary_form)
				formula.primary_form = id
		if(FORMULA_WORD_ELEMENT)
			formula.elements.Insert(length(formula.elements) + 1, id)
		if(FORMULA_WORD_MODIFIER)
			formula.modifiers.Insert(length(formula.modifiers) + 1, id)
		if(FORMULA_WORD_POST_EFFECT)
			formula.post_effects.Insert(length(formula.post_effects) + 1, id)
		if(FORMULA_WORD_LINK)
			formula.links.Insert(length(formula.links) + 1, id)

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
		"required_school_points" = required_school_points.Copy(),
		"phrases" = phrases.Copy(),
	)

/datum/formula_magic_word/proc/get_phrase()
	if(length(phrases))
		return phrases[1]
	return "Asha."

/datum/formula_magic_word/proc/get_speech_phrases()
	if(length(spoken_phrases))
		return spoken_phrases.Copy()
	return list(get_phrase())

/proc/formula_magic_widen_step(repeat_index)
	return 1

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
	formula.range = 3 + (moment_words - 1)

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
	var/breath_words = formula.tags["breath"] || 1
	formula.range = 3
	formula.duration = max(formula.duration, 3 SECONDS + ((breath_words - 1) * 1 SECONDS))

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
	formula.radius = max(formula.radius, 1 + (nova_words - 1))

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
	desc = "Expands the formula according to its form. Each repeat adds one step."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 2
	complexity = 2
	tags = list("widen")
	phrases = list("Amplia.", "Latius fiat.", "Circulus crescat.")

/datum/formula_magic_word/modifier/widen/apply_to(datum/formula_magic_formula/formula)
	..()
	var/repeats = formula.tags["widen"] || 1
	formula.tags["widen_amount"] = (formula.tags["widen_amount"] || 0) + formula_magic_widen_step(repeats)
	formula.instability += max(0, repeats - 2)

/datum/formula_magic_word/modifier/existence
	id = "existence"
	name = "Existence"
	desc = "Keeps the triggered effect zone alive after the formula resolves. Each repeat adds ten seconds."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("existence")
	phrases = list("Mane.", "Esse tene.", "Vestigium vivat.")

/datum/formula_magic_word/modifier/existence/apply_to(datum/formula_magic_formula/formula)
	..()
	var/repeats = formula.tags["existence"] || 1
	formula.tags["existence_duration"] = repeats * 10 SECONDS

/datum/formula_magic_word/modifier/recall
	id = "recall"
	name = "Recall"
	desc = "After the initial resolution, randomly recalls struck tiles with short delays. Each word recalls up to three tiles; a widened area will not recall the same tile twice."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 3
	cast_time = 10
	complexity = 3
	instability = 1
	tags = list("recall")
	phrases = list("Revoca.", "Ictus redi.", "Memoria ferit.")

/datum/formula_magic_word/modifier/shrapnel
	id = "shrapnel"
	name = "Shrapnel"
	desc = "Splinters the resolved formula into stone fragments. Each word releases three shards, each carrying 40% formula power."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 3
	cast_time = 8
	complexity = 3
	tags = list("shrapnel")
	phrases = list("Frange in spicula.", "Lapides sparge.", "Grana vulnera.")

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
	desc = "Adds escalating frost stacks, dampens fire, and can burst frozen targets."
	school_id = FORMULA_SCHOOL_CRYOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("frost_stack", "extinguish")
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

/datum/formula_magic_word/post_effect/immobilize
	id = "immobilize"
	name = "Dirt"
	desc = "Turns earth against movement. Struck targets are slowed for 3 seconds plus 3 per extra word; Summon shapes a temporary muddy patch."
	school_id = FORMULA_SCHOOL_GEOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 6
	complexity = 2
	tags = list("dirt", "slow")
	phrases = list("Lutum.", "Terra lenta.", "Pedem tene.")

/datum/formula_magic_word/element/force
	id = "force"
	name = "Force"
	desc = "Adds direct kinetic crushing force."
	school_id = FORMULA_SCHOOL_KINESIS
	cast_time = 7
	complexity = 2
	tags = list("damage_force")
	phrases = list("Vis.", "Ictus animi.", "Contere.")

/datum/formula_magic_word/element/force/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 8

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

/datum/formula_magic_word/post_effect/cleanse
	id = "cleanse"
	name = "Cleanse"
	desc = "Scours grime and debris from affected ground and objects."
	school_id = FORMULA_SCHOOL_KINESIS
	role = FORMULA_WORD_ELEMENT
	mana_cost = 1
	cast_time = 5
	complexity = 1
	tags = list("cleanse")
	phrases = list("Purga.", "Mundus fiat.", "Sordes abi.")

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

/datum/formula_magic_word/prebuilt/teleport_rune
	id = "prebuilt_teleport_rune"
	name = "Teleport Rune"
	desc = "Fixed displacement formula. Creates a permanent travel rune. Arcane skill limits how many a mage may hold."
	school_id = FORMULA_SCHOOL_DISPLACEMENT
	mana_cost = 12
	cast_time = 30
	complexity = 4
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_teleport_rune")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Locus memor.", "Porta sine via.", "Nodus redit.")

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

/datum/formula_magic_word/prebuilt/guidance
	id = "prebuilt_guidance"
	name = "Guidance"
	desc = "Fixed augmentation formula. Sharpens a target's senses."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 4
	cast_time = 18
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_guidance")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Ducere.", "Oculus aperi.")

/datum/formula_magic_word/prebuilt/surge
	id = "prebuilt_surge"
	name = "Surge"
	desc = "Fixed augmentation formula. Hauls a target back from stun and exhaustion."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 8
	cast_time = 16
	complexity = 3
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_surge")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Impetus.", "Surge et sta.")

/datum/formula_magic_word/prebuilt/precognition
	id = "prebuilt_precognition"
	name = "Precognition"
	desc = "Fixed augmentation formula. Readies a target's next combat motions."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 6
	cast_time = 20
	complexity = 3
	unlock_level = 3
	tags = list("prebuilt_formula", "prebuilt_precognition")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Praevidere.", "Momentum redi.")

/datum/formula_magic_word/prebuilt/ascension
	id = "prebuilt_ascension"
	name = "Ascension"
	desc = "Fixed high augmentation formula. Channels every bodily attunement into another."
	school_id = FORMULA_SCHOOL_AUGMENTATION
	mana_cost = 16
	cast_time = 40
	complexity = 8
	instability = 3
	unlock_level = 6
	tags = list("prebuilt_formula", "prebuilt_ascension")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Ascende.", "Ultra omnia.", "Corpus perfectum.", "Virtus plena.")

/datum/formula_magic_word/prebuilt/read_omen
	id = "prebuilt_read_omen"
	name = "Read Omen"
	desc = "Fixed general formula. Reads the current divine pressure on the land."
	school_id = FORMULA_SCHOOL_GENERAL
	mana_cost = 3
	cast_time = 20
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_read_omen")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Miror quid.", "Signum audi.")

/datum/formula_magic_word/post_effect/mind
	id = "mind"
	name = "Mind"
	desc = "Touches thought, memory, speech, and mental contact. On a hostile target it confuses for two seconds per spoken word."
	school_id = FORMULA_SCHOOL_GENERAL
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	unlock_level = 1
	tags = list("mind")
	phrases = list("Mens aperi.", "Cogitatio iunge.", "Vox intus.")

/datum/formula_magic_word/prebuilt/message
	id = "prebuilt_message"
	name = "Message"
	desc = "Fixed general formula. Sends a short private thought to the selected target."
	school_id = FORMULA_SCHOOL_GENERAL
	mana_cost = 3
	cast_time = 14
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_message")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Mens aperi.", "Vox intus.")

/datum/formula_magic_word/prebuilt/mindlink
	id = "prebuilt_mindlink"
	name = "Mindlink"
	desc = "Fixed general formula. Opens a brief two-way thought thread with the selected target."
	school_id = FORMULA_SCHOOL_GENERAL
	mana_cost = 5
	cast_time = 22
	complexity = 3
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_mindlink")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Cogitatio iunge.", "Duo corda audiant.")

/datum/formula_magic_word/post_effect/silence
	id = "silence"
	name = "Silence"
	desc = "Suppresses speech through mental pressure."
	school_id = FORMULA_SCHOOL_CURSES
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
	school_id = FORMULA_SCHOOL_BIOMANCY
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

/datum/formula_magic_word/post_effect/enlarge
	id = "enlarge"
	name = "Enlarge"
	desc = "Bloats the target's presence and frame."
	school_id = FORMULA_SCHOOL_BIOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	complexity = 2
	unlock_level = 2
	tags = list("size_up")
	phrases = list("Maior esto.", "Forma tumescat.", "Corpus crescat.")

/datum/formula_magic_word/prebuilt/blood_rush
	id = "prebuilt_blood_rush"
	name = "Blood Rush"
	desc = "Fixed biomantic formula. Drives blood into a brief surge of vigor."
	school_id = FORMULA_SCHOOL_BIOMANCY
	mana_cost = 5
	cast_time = 14
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_blood_rush")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Sanguis fervet.", "Corpus arde.")

/datum/formula_magic_word/prebuilt/fortitude
	id = "prebuilt_fortitude"
	name = "Fortitude"
	desc = "Fixed biomantic formula. Hardens the body against fatigue."
	school_id = FORMULA_SCHOOL_BIOMANCY
	mana_cost = 5
	cast_time = 16
	complexity = 2
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_fortitude")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Corpus firma.", "Pondus leve.")

/datum/formula_magic_word/prebuilt/mirror_transform
	id = "prebuilt_mirror_transform"
	name = "Mirror Transform"
	desc = "Fixed biomantic formula. Opens the body to mirror-wrought reshaping."
	school_id = FORMULA_SCHOOL_BIOMANCY
	mana_cost = 5
	cast_time = 20
	complexity = 2
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_mirror_transform")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Speculum carnis.", "Forma fluat.")

/datum/formula_magic_word/prebuilt/airhead
	id = "prebuilt_airhead"
	name = "Airhead"
	desc = "Fixed curse formula. Scatters focus and breaks arcyne guidance."
	school_id = FORMULA_SCHOOL_CURSES
	mana_cost = 4
	cast_time = 16
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_airhead")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Mens vacua.", "Ducere frange.")

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
	desc = "Shapes hard metal force, tools, and iron impact."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	tags = list("metal")
	phrases = list("Ferrum.", "Chalybs pare.", "Malleus somni.")

/datum/formula_magic_word/element/iron/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 6

/datum/formula_magic_word/element/blade
	id = "blade"
	name = "Blade"
	desc = "Plants a spinning arcyne blade in the affected zone."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	complexity = 2
	tags = list("blade_field")
	phrases = list("Lamina.", "Acies aperi.", "Seca.")

/datum/formula_magic_word/prebuilt/mending
	id = "mending"
	name = "Mending"
	desc = "Fixed artifice formula. Repairs shaped matter and artificial bodies."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 4
	cast_time = 18
	complexity = 3
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_mending")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Reficio.", "Fractum iunge.", "Opera sana.")

/datum/formula_magic_word/prebuilt/lesser_knock
	id = "prebuilt_lesser_knock"
	name = "Knock"
	desc = "Fixed artifice formula. Conjures a spectral lockpick."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 10
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_lesser_knock")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Parvus pulso.", "Ferrum pateat.")

/datum/formula_magic_word/prebuilt/conjure_spectacles
	id = "prebuilt_conjure_spectacles"
	name = "Conjure Spectacles"
	desc = "Fixed artifice formula. Conjures a harmless pair of spectacles."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 2
	cast_time = 10
	complexity = 1
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_conjure_spectacles")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Caeca sum.", "Vitrum pare.")

/datum/formula_magic_word/prebuilt/great_shelter
	id = "prebuilt_great_shelter"
	name = "Great Shelter"
	desc = "Fixed artifice formula. Raises a short-lived arcyne shelter wall around the caster."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 7
	cast_time = 28
	complexity = 5
	unlock_level = 3
	required_school_points = list(FORMULA_SCHOOL_GEOMANCY = 1)
	tags = list("prebuilt_formula", "prebuilt_great_shelter")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Domus parva.", "Saxum protegat.", "Tectum sta.")

/datum/formula_magic_word/prebuilt/form_blade
	id = "prebuilt_form_blade"
	name = "Form Blade"
	desc = "Fixed artifice formula. Conjures a chosen arcyne weapon."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 5
	cast_time = 18
	complexity = 3
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_form_blade")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Forma ferri.", "Manus armetur.")

/datum/formula_magic_word/prebuilt/bind_armament
	id = "prebuilt_bind_armament"
	name = "Bind Armament"
	desc = "Fixed artifice formula. Binds a held weapon to Arcyne Armament, or releases such bonds with an empty hand."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 12
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_bind_armament")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Vinculum ferri.", "Arma pare.")

/datum/formula_magic_word/prebuilt/summon_instrument
	id = "prebuilt_summon_instrument"
	name = "Summon Instrument"
	desc = "Fixed artifice formula. Conjures a chosen musical instrument."
	school_id = FORMULA_SCHOOL_ARTIFICE_WARDING
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 14
	complexity = 2
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_summon_instrument")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Tempus spectaculi.", "Carmen forma.")

/datum/formula_magic_word/element/creation
	id = "creation"
	name = "Creation"
	desc = "Animates short-lived predatory plant matter for ten seconds per spoken word."
	school_id = FORMULA_SCHOOL_BIOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 10
	complexity = 2
	unlock_level = 1
	tags = list("creation")
	phrases = list("Vita.", "Spiritus surgat.", "Anima tene.")

/datum/formula_magic_word/element/bone
	id = "bone"
	name = "Bone"
	desc = "Hurls a bone-hard arcyne impact."
	school_id = FORMULA_SCHOOL_NECROMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 10
	complexity = 2
	unlock_level = 1
	tags = list("bone")
	phrases = list("Mors.", "Ossa surgant.", "Cinis pare.")

/datum/formula_magic_word/prebuilt/familiar
	id = "prebuilt_familiar"
	name = "Familiar"
	desc = "Fixed biomancy formula. Calls a fae familiar shape."
	school_id = FORMULA_SCHOOL_BIOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 4
	cast_time = 18
	complexity = 3
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_familiar")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Vita minor.", "Spiritus comes.")

/datum/formula_magic_word/prebuilt/elemental_familiar
	id = "prebuilt_elemental_familiar"
	name = "Elemental Familiar"
	desc = "Fixed biomancy formula. Calls an elemental familiar shape."
	school_id = FORMULA_SCHOOL_BIOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 5
	cast_time = 20
	complexity = 3
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_elemental_familiar")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Vita elementi.", "Spiritus comes.")

/datum/formula_magic_word/prebuilt/raise_deadite
	id = "prebuilt_raise_deadite"
	name = "Raise Deadite"
	desc = "Fixed necromancy formula. Calls a weak deadite guard."
	school_id = FORMULA_SCHOOL_NECROMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 6
	cast_time = 30
	complexity = 4
	unlock_level = 1
	tags = list("prebuilt_formula", "prebuilt_raise_deadite")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Ossa surgant.", "Servus mortis.")

/datum/formula_magic_word/prebuilt/conjure_undead
	id = "prebuilt_conjure_undead"
	name = "Conjure Undead"
	desc = "Fixed necromancy formula. Calls a sturdier undead servant."
	school_id = FORMULA_SCHOOL_NECROMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 8
	cast_time = 36
	complexity = 5
	unlock_level = 2
	tags = list("prebuilt_formula", "prebuilt_conjure_undead")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Manus mortua.", "Custos surge.")

/datum/formula_magic_word/prebuilt/raise_skeleton
	id = "prebuilt_raise_skeleton"
	name = "Raise to Skeleton"
	desc = "Fixed necromancy formula. Raises a skeleton servant."
	school_id = FORMULA_SCHOOL_NECROMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 9
	cast_time = 40
	complexity = 6
	unlock_level = 3
	tags = list("prebuilt_formula", "prebuilt_raise_skeleton")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Corpus vacuum.", "Miles ossium.")

/datum/formula_magic_word/element/time
	id = "time"
	name = "Time"
	desc = "Binds the formula to Origin timeflow. By itself it adds light temporal stress."
	school_id = FORMULA_SCHOOL_CHRONOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 3
	cast_time = 10
	complexity = 2
	unlock_level = 1
	tags = list("time")
	phrases = list("Tempus.", "Origo temporis.", "Momentum ligat.")

/datum/formula_magic_word/element/time/apply_to(datum/formula_magic_formula/formula)
	..()
	formula.power += 4

/datum/formula_magic_word/post_effect/restoration
	id = "restoration"
	name = "Restoration"
	desc = "Recalls an earlier bodily state, removing embedded objects or bleeding before restoring damage."
	school_id = FORMULA_SCHOOL_CHRONOMANCY
	role = FORMULA_WORD_ELEMENT
	mana_cost = 25
	cast_time = 16
	complexity = 4
	unlock_level = 2
	tags = list("time", "temporal_restore", "chronomancy_full")
	phrases = list("Memoria corporis.", "Redi integer.", "Forma prior.")

/datum/formula_magic_word/prebuilt/reversion
	id = "reversion"
	name = "Reversion"
	desc = "Fixed chronomancy formula. Marks affected bodies with a brief temporal anchor; on injury, the mark snaps them back toward the stored moment."
	school_id = FORMULA_SCHOOL_CHRONOMANCY
	mana_cost = 6
	cast_time = 18
	complexity = 5
	instability = 1
	unlock_level = 3
	tags = list("prebuilt_formula", "prebuilt_reversion", "chronomancy_full")
	phrases = list("Imagana.")
	spoken_phrases = list("Imagana.", "Nodus originis.", "Tempus serva.", "Reditus paratus.")

/datum/formula_magic_word/link/sequence
	id = "sequence"
	name = "Sequence"
	desc = "Links formula segments in order. The next segment starts after the previous one resolves."
	role = FORMULA_WORD_LINK
	is_stop_word = TRUE
	mana_cost = 5
	cast_time = 18
	complexity = 4
	instability = 2
	tags = list("sequence")
	phrases = list("Deinde.", "Post hoc.", "Vinculum sequitur.")

/datum/formula_magic_word/link/sequence/apply_to(datum/formula_magic_formula/formula)
	..()
	return

/datum/formula_magic_word/stabilizer/anchor
	id = "anchor"
	name = "Anchor"
	desc = "Stabilizes long formulae at the cost of time and mana, reducing interruption risk."
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
	return

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

#endif


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
	var/list/required_school_points = list()
	var/list/phrases = list()
	var/list/spoken_phrases = list()

/datum/formula_magic_word/proc/apply_to_part(datum/formula_magic_part/part)
	if(!part)
		return
	part.mana_cost += mana_cost
	part.cast_time += cast_time
	part.complexity += complexity
	for(var/tag in tags)
		part.add_tag(tag)
	switch(role)
		if(FORMULA_WORD_FORM)
			part.forms += id
			if(!part.form_id)
				part.form_id = id
		if(FORMULA_WORD_ELEMENT)
			part.elements += id
		if(FORMULA_WORD_MODIFIER)
			part.modifiers += id

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
		"required_school_points" = required_school_points.Copy(),
		"phrases" = phrases.Copy(),
	)

/datum/formula_magic_word/proc/get_phrase()
	if(length(phrases))
		return phrases[1]
	return "Asha."

/datum/formula_magic_word/proc/get_speech_phrases()
	if(length(spoken_phrases))
		return spoken_phrases.Copy()
	return list(get_phrase())

/datum/formula_magic_word/form/orb
	id = FORMULA_FORM_ORB
	name = "Orb"
	desc = "A projectile arcyne sphere. Repeating the word adds another orb to the same part."
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
	part.power += 30

/datum/formula_magic_word/modifier/widen
	id = "widen"
	name = "Widen"
	desc = "Expands the resolved form. For Orb, it adds one tile of arcane impact radius per word."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 1
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("widen")
	phrases = list("Amplia.", "Latius fiat.", "Circulus crescat.")

/datum/formula_magic_word/modifier/widen/apply_to_part(datum/formula_magic_part/part)
	..()
	part.radius += 1

/datum/formula_magic_word/modifier/existence
	id = "existence"
	name = "Existence"
	desc = "Extends lasting formulae. For instant formulae, each word echoes the payload across up to three randomly affected tiles after a short delay."
	role = FORMULA_WORD_MODIFIER
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("existence")
	phrases = list("Mane.", "Esse tene.", "Vestigium vivat.")

/datum/formula_magic_word/modifier/existence/apply_to_part(datum/formula_magic_part/part)
	..()
	part.duration += 5 SECONDS

/datum/formula_magic_word/modifier/efficient
	id = "efficient"
	name = "Efficient"
	desc = "Lowers the part's mana cost by 15% after this word is spoken."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 1
	mana_cost = 1
	cast_time = 6
	complexity = 1
	tags = list("efficient")
	phrases = list("Parce.", "Minus da.", "Vena clauditur.")

/datum/formula_magic_word/modifier/efficient/apply_to_part(datum/formula_magic_part/part)
	..()
	part.mana_cost = max(1, round(part.mana_cost * 0.85))

/datum/formula_magic_word/modifier/ricochet
	id = "ricochet"
	name = "Ricochet"
	desc = "After impact, the orb rebounds along the impact angle. Repeating the word adds another rebound."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 1
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("ricochet")
	phrases = list("Resilio.", "Angulus redit.", "Ictus reflectitur.")

/datum/formula_magic_word/modifier/chain
	id = "chain"
	name = "Chain"
	desc = "After impact, the orb flies to the nearest other target. Repeating the word adds another leap."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 1
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("chain")
	phrases = list("Catena.", "Hostem quaere.", "Ictus sequitur.")

/datum/formula_magic_word/modifier/pierce
	id = "pierce"
	name = "Pierce"
	desc = "Lets the orb pass through struck targets. Repeating it adds another pierced target."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 1
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("pierce")
	phrases = list("Perfora.", "Transi carnem.", "Iter per hostem.")

/datum/formula_magic_word/modifier/shrapnel
	id = "shrapnel"
	name = "Shrapnel"
	desc = "After impact, releases extra payload orbs in random directions. Shrapnel-born orbs do not carry modifiers."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 1
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("shrapnel")
	phrases = list("Scindere.", "Frange globum.", "Fragmenta volant.")
