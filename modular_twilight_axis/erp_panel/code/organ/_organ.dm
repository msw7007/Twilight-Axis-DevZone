/obj/item/organ
	var/datum/sex_organ/sex_organ

/obj/item/organ/breasts/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/breasts(src)
	
/obj/item/organ/penis/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/penis(src)

/obj/item/organ/vagina/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/vagina(src)

/obj/item/organ/anus/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/anus(src)

/obj/item/bodypart
	var/datum/sex_organ/sex_organ

/obj/item/bodypart/head/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/mouth(src)

/obj/item/bodypart/r_arm/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/hand/right(src)
	
/obj/item/bodypart/l_arrm/Initialize()
	. = ..()
	sex_organ = new /datum/sex_organ/hand(src)
