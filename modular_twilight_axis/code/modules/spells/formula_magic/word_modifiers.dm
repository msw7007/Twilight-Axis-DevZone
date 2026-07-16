/datum/formula_magic_word/modifier/widen
	id = "widen"
	name = "Widen"
	desc = "Expands the resolved form. For Orb, it adds one tile of arcane impact radius per word."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 0
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
	learn_cost = 0
	mana_cost = 3
	cast_time = 10
	complexity = 2
	tags = list("existence")
	phrases = list("Mane.", "Esse tene.", "Vestigium vivat.")

/datum/formula_magic_word/modifier/existence/apply_to_part(datum/formula_magic_part/part)
	..()
	part.duration += 5 SECONDS
	part.tags["existence_duration"] = (part.tags["existence_duration"] || 0) + 5 SECONDS

/datum/formula_magic_word/modifier/efficient
	id = "efficient"
	name = "Efficient"
	desc = "Lowers the part's mana cost by 15% after this word is spoken."
	role = FORMULA_WORD_MODIFIER
	learn_cost = 0
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
	learn_cost = 0
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
	learn_cost = 0
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
	learn_cost = 0
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
	learn_cost = 0
	mana_cost = 2
	cast_time = 8
	complexity = 2
	tags = list("shrapnel")
	phrases = list("Scindere.", "Frange globum.", "Fragmenta volant.")

