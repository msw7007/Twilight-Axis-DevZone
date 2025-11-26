/datum/sex_panel_action/other
	abstract_type = TRUE

	name = "Корневое действие на другого"

	can_knot = FALSE
	continous = TRUE
	interaction_timer = 2 SECONDS
	stamina_cost = 0.2

	check_incapacitated = TRUE
	check_same_tile = FALSE
	require_grab = FALSE
	required_grab_state = null

/datum/sex_panel_action/other/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	if(user == target)
		return FALSE

	return TRUE

/datum/sex_panel_action/other/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	SEND_SIGNAL(user, COMSIG_SEX_RECEIVE_ACTION, affects_self_arousal, affects_self_pain)
	SEND_SIGNAL(target, COMSIG_SEX_RECEIVE_ACTION, affects_arousal, affects_pain)
