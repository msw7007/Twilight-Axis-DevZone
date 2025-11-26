/obj/item/organ
	var/datum/sex_organ/sex_organ

/obj/item/organ/breasts/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/breasts(src)
	
/obj/item/organ/penis/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/penis(src)

/obj/item/organ/vagina/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/vagina(src)

/obj/item/organ/tail/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/tail(src)

/obj/item/bodypart
	var/datum/sex_organ/sex_organ

/obj/item/bodypart/head/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/mouth(src)

/obj/item/bodypart/r_arm/attach_limb(mob/living/carbon/C)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/hand/right(src)
	
/obj/item/bodypart/l_arm/attach_limb(mob/living/carbon/C)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/hand(src)

/mob/living/carbon/human
	var/datum/sex_organ/legs/legs_organ

/obj/item/bodypart/l_leg/attach_limb(mob/living/carbon/C)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(H)
		if(!H.legs_organ)
			H.legs_organ = new /datum/sex_organ/legs(src)
		sex_organ = H.legs_organ

/obj/item/bodypart/r_leg/attach_limb(mob/living/carbon/C)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(H)
		if(!H.legs_organ)
			H.legs_organ = new /datum/sex_organ/legs(src)
		sex_organ = H.legs_organ

/obj/item/bodypart/chest/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/anus(src)
