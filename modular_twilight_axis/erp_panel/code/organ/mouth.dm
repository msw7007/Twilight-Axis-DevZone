/datum/sex_organ/mouth
	organ_type = SEX_ORGAN_MOUTH
	stored_liquid_max = MOUTH_MAX_UNITS

/datum/sex_organ/mouth/add_reagent(datum/reagent/R, amount)
	. = ..()
	//Добавить мудлет - нажал и выпил. Что-то сказал - вылил
