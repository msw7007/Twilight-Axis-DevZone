/datum/sex_category_lock
	var/mob/living/carbon/human/locked_host
	var/category // "mouth" | "left_hand" | "right_hand" | "genital"

/datum/sex_category_lock/New(mob/living/carbon/human/_host, _category)
	. = ..()
	locked_host = _host
	category = _category

/datum/sex_category_lock/Destroy(force, ...)
	. = ..()
	locked_host = null
	category = null
