/datum/emote/living/pat
	key = "pat"
	key_third_person = "pats"
	message = "pats gently."
	message_param = "pats %t gently."
	emote_type = EMOTE_VISIBLE
	use_params_for_runechat = TRUE

/mob/living/carbon/human/verb/emote_pat()
	set name = "Pat"
	set category = "Emotes"

	emote("pat", intentional = TRUE, targetted = TRUE)

/datum/emote/living/pat/adjacentaction(mob/user, mob/target)
	. = ..()
	if(!user || !target)
		return

	message_param = "pats %t on the head."

	playsound(target.loc, 'sound/vo/hug.ogg', 50, FALSE, -1)

/datum/emote/living/kiss/adjacentaction(mob/user, mob/target)
	. = ..()
	message_param = initial(message_param)
	if(!user || !target)
		return

	if(ishuman(user) && ishuman(target))
		var/mob/living/carbon/human/H = user
		var/mob/living/carbon/human/T = target
		var/do_change

		if(target.loc == user.loc)
			do_change = TRUE
		if(!do_change && H.pulling == target)
			do_change = TRUE

		if(do_change)
			if(H.zone_selected == BODY_ZONE_PRECISE_MOUTH)
				message_param = "kisses %t deeply."
			else if(H.zone_selected == BODY_ZONE_PRECISE_EARS)
				message_param = "kisses %t on the ear."
				var/mob/living/carbon/human/E = T
				if(iself(E) || ishalfelf(E) || isdarkelf(E) || iswoodelf(E))
					if(!E.cmode)
						to_chat(E, span_love("It tickles..."))
						E.apply_soft_arousal(0.33)
			else if(H.zone_selected == BODY_ZONE_PRECISE_R_EYE || H.zone_selected == BODY_ZONE_PRECISE_L_EYE)
				message_param = "kisses %t on the brow."
			else if(H.zone_selected == BODY_ZONE_PRECISE_SKULL)
				message_param = "kisses %t on the forehead."
			else if(H.zone_selected == BODY_ZONE_HEAD)
				message_param = "kisses %t on the cheek."
			else if(H.zone_selected == BODY_ZONE_PRECISE_GROIN)
				message_param = "kisses %t between the legs."
				var/mob/living/carbon/human/L = T
				if(!L.cmode)
					to_chat(L, span_love("It somewhat stimulating..."))
					L.apply_soft_arousal(1)
			else
				message_param = "kisses %t on \the [parse_zone(H.zone_selected)]."

	playsound(target.loc, pick('sound/vo/kiss (1).ogg','sound/vo/kiss (2).ogg'), 100, FALSE, -1)

	if(user.mind)
		record_round_statistic(STATS_KISSES_MADE)

/datum/emote/living/lick/adjacentaction(mob/user, mob/target)
	. = ..()
	message_param = initial(message_param)
	if(!user || !target)
		return

	if(ishuman(user) && ishuman(target))
		var/mob/living/carbon/human/user_mob = user
		var/mob/living/carbon/human/target_mob = target
		var/do_change

		if(target_mob.loc == user.loc)
			do_change = TRUE
		if(!do_change && user_mob.pulling == target_mob)
			do_change = TRUE

		if(do_change)
			if(user_mob.zone_selected == BODY_ZONE_PRECISE_MOUTH)
				message_param = "licks %t lips."
			else if(user_mob.zone_selected == BODY_ZONE_PRECISE_EARS)
				message_param = "licks the ear of %t."
				var/mob/living/carbon/human/applied_mob = target
				if(iself(applied_mob) || ishalfelf(applied_mob) || isdarkelf(applied_mob) || iswoodelf(applied_mob))
					if(!applied_mob.cmode)
						to_chat(applied_mob, span_love("It tickles..."))
						applied_mob.apply_soft_arousal(0.5)
			else if(user_mob.zone_selected == BODY_ZONE_PRECISE_GROIN)
				message_param = "licks %t between the legs."
				if(!target.cmode)
					to_chat(target_mob, span_love("It somewhat stimulating..."))
					target_mob.apply_soft_arousal(1.5)
			else if(user_mob.zone_selected == BODY_ZONE_HEAD)
				message_param = "licks %t cheek"
			else
				message_param = "licks %t [parse_zone(user_mob.zone_selected)]."

	playsound(target.loc, "sound/vo/lick.ogg", 100, FALSE, -1)
