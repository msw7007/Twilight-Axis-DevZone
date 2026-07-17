/mob/living/carbon/human/verb/open_formula_spellcraft()
	set name = "Formula Spellcraft"
	set category = "RoleUnique"
	if(!mind)
		return
	var/datum/formula_magic_panel/panel = new(src)
	panel.ui_interact(src)
