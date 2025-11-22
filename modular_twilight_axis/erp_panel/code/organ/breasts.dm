/datum/sex_organ/breasts
	organ_type = SEX_ORGAN_BREASTS
	stored_liquid_max = 0
	var/stored_milk = 0
	var/max_milk = 0

/datum/sex_organ/breasts/New(obj/item/organ/breasts/organ)
	. = ..()
	stored_milk = organ.milk_stored
	max_milk = organ.milk_max
