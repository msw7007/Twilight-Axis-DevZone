/obj/item/organ
	var/datum/sex_organ/sex_organ

/obj/item/organ/breasts/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/breasts(src)
	
/obj/item/organ/penis/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/penis(src)

/obj/item/organ/vagina/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/vagina(src)

/obj/item/organ/tail/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/tail(src)

/obj/item/bodypart
	var/datum/sex_organ/sex_organ

/obj/item/bodypart/head/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/mouth(src)

/obj/item/bodypart/r_arm/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/hand/right(src)
	
/obj/item/bodypart/l_arm/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/hand(src)

/mob/living/carbon/human
	var/datum/sex_organ/legs/legs_organ

/obj/item/bodypart/l_leg/Initialize()
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(H)
		if(!H.legs_organ)
			H.legs_organ = new /datum/sex_organ/legs(H)
		sex_organ = H.legs_organ

/obj/item/bodypart/r_leg/Initialize()
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(H)
		if(!H.legs_organ)
			H.legs_organ = new /datum/sex_organ/legs(H)
		sex_organ = H.legs_organ

/obj/item/bodypart/chest/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/anus(H)
