/datum/advclass/rogue/soundbreaker
	name = "Soundbreaker"
	tutorial = "You are a brawling bard who turns rhythm and motion into weapons. Your fists, feet, and music break bones and shatter morale."
	outfit = /datum/outfit/job/roguetown/adventurer/soundbreaker
	cmode_music = 'sound/music/cmode/adventurer/combat_outlander3.ogg'
	traits_applied = list(
		TRAIT_DODGEEXPERT,
	)
	class_select_category = CLASS_CAT_ROGUE
	category_tags = list(CTAG_ADVENTURER)
	subclass_stats = list(
		STATKEY_STR = 2,
		STATKEY_SPD = 1,
		STATKEY_WIL = -1,
		STATKEY_CON = -1,
	)
	subclass_skills = list(
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/music = SKILL_LEVEL_MASTER,
		/datum/skill/combat/unarmed = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/climbing = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/swimming = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/sneaking = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/stealing = SKILL_LEVEL_NOVICE,
		/datum/skill/misc/reading = SKILL_LEVEL_JOURNEYMAN
	)

/datum/outfit/job/roguetown/adventurer/soundbreaker/pre_equip(mob/living/carbon/human/H)
	..()
	to_chat(H, span_warning("You are a Soundbreaker – a brawling bard who weaves strikes into melody. Your fists keep the rhythm, your enemies keep the bruises."))

	pants = /obj/item/clothing/under/roguetown/trou/leather
	shirt = /obj/item/clothing/suit/roguetown/shirt/shortshirt
	armor = /obj/item/clothing/suit/roguetown/armor/leather/vest
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather
	gloves = /obj/item/clothing/gloves/roguetown/fingerless_leather
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
	neck = /obj/item/storage/belt/rogue/pouch/coins/poor
	cloak = /obj/item/clothing/cloak/half/red
	backl = /obj/item/storage/backpack/rogue/satchel
	belt = /obj/item/storage/belt/rogue/leather
	beltl = /obj/item/flashlight/flare/torch/lantern

	backpack_contents = list(
		/obj/item/lockpick = 1,
		/obj/item/recipe_book/survival = 1,
	)

	var/datum/inspiration/I = new /datum/inspiration(H)
	I.grant_inspiration(H, bard_tier = BARD_T3)

	if(H.mind)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/soundbreaker/sound_strike)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/soundbreaker/resonant_wave)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/soundbreaker/dulce_step)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/soundbreaker/overload_chord)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/soundbreaker/encore_line)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/soundbreaker/solo_break)
		var/weapons = list("Lute","Guitar","Hurdy-Gurdy")
		var/weapon_choice = tgui_input_list(H, "Choose your instrument.", "TAKE UP ARMS", weapons)
		H.set_blindness(0)
		switch(weapon_choice)
			if("Lute")
				backr = /obj/item/rogue/instrument/lute
			if("Guitar")
				backr = /obj/item/rogue/instrument/guitar
			if("Hurdy-Gurdy")
				backr = /obj/item/rogue/instrument/hurdygurdy

		to_chat(H, span_notice("You feel a fighting rhythm pulsing in your veins. Your music belongs in a brawl."))
