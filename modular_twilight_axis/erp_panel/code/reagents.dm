/datum/reagent/erpjuice/cum
	name = "Erotic Fluid"
	description = "A thick, sticky, cream like fluid, produced during an orgasm."
	reagent_state = LIQUID
	color = "#ebebeb"
	taste_description = "salty and tangy"
	metabolizing = TRUE

/datum/reagent/erpjuice/cum/on_mob_add(mob/living/carbon/carbon) //cum additional effect on nymphos and baotha's worshippers
	if(ishuman(carbon))
		if(HAS_TRAIT(carbon, TRAIT_CRACKHEAD))
			to_chat(carbon, "<span class='love_mid'>Она радуется, глядя на меня...</span>")
			carbon.add_stress(/datum/stressevent/nympho_taste/baotha)
		else if(carbon.has_flaw(/datum/charflaw/addiction/lovefiend))
			to_chat(carbon, "<span class='love_mid'>Как же мне нравится этот вкус...</span>")
			carbon.add_stress(/datum/stressevent/nympho_taste)
	..()

/datum/reagent/consumable/milk/erp
	name = "Breast Milk"
	description = "A thick, transparent milk that clearly doesn't come from a cow."
	reagent_state = LIQUID
	color = "#eee4e4"
	taste_description = "sweet and tart"

/datum/reagent/consumable/milk/erp/on_mob_add(mob/living/carbon/carbon) //milk additional effect on nymphos and baotha's worshippers
	if(ishuman(carbon))
		if(HAS_TRAIT(carbon, TRAIT_CRACKHEAD))
			to_chat(carbon, "<span class='love_mid'>Она радуется, глядя на меня...</span>")
			carbon.add_stress(/datum/stressevent/nympho_taste/baotha)
		else if(carbon.has_flaw(/datum/charflaw/addiction/lovefiend))
			to_chat(carbon, "<span class='love_mid'>Как же мне нравится этот вкус...</span>")
			carbon.add_stress(/datum/stressevent/nympho_taste)
	..()
