#define SEX_ORGAN_HANDS (1<<0)
#define SEX_ORGAN_LEGS (1<<1)
#define SEX_ORGAN_TAIL (1<<2)
#define SEX_ORGAN_MOUTH (1<<3)
#define SEX_ORGAN_ANUS (1<<4)
#define SEX_ORGAN_BREASTS (1<<5)
#define SEX_ORGAN_VAGINA (1<<6)
#define SEX_ORGAN_PENIS (1<<7)

#define SEX_CHAT_FREQUENCY 3

#define SEX_SENSITIVITY_MAX  2
#define SEX_PAIN_MAX         2

#define SEX_SENSITIVITY_GAIN          0.1
#define SEX_PAIN_GAIN_HIGH_PASSIVE    0.05
#define SEX_PAIN_GAIN_EXTREME_PASSIVE 0.1
#define SEX_PAIN_GAIN_EXTREME_ACTIVE  0.03

#define SEX_POSE_BOTH_STANDING "both_standing"
#define SEX_POSE_USER_LYING    "user_lying"
#define SEX_POSE_TARGET_LYING  "target_lying"
#define SEX_POSE_BOTH_LYING    "both_lying"

#define ERP_UI_MAX_AROUSAL 100

#define PAIN_BASE_SCALE 5
#define FORCE_HIGH_PAIN_CRIT_CHANCE 20
#define FORCE_EXTREME_PAIN_CRIT_CHANCE 40
#define FORCE_PAIN_CRIT_MULT 2.0

#define ORG_SENS_GAIN_RATE 0.05
#define ORG_PAIN_GAIN_RATE 0.05

#define BREAST_SPENT_PROD_MULT 1.5
#define PENIS_SPENT_PROD_MULT 0.0

GLOBAL_LIST_INIT(sex_panel_actions, build_sex_panel_actions())

#define SEX_PANEL_ACTION(sex_action_type) (GLOB.sex_panel_actions[sex_action_type])

/proc/build_sex_panel_actions()
	var/list/L = list()
	for(var/path in subtypesof(/datum/sex_panel_action))
		if(is_abstract(path))
			continue

		var/datum/sex_panel_action/A = new path()
		var/key = "[path]"
		L[key] = A

	return L

/proc/is_sex_toy(obj/item/I)
	if(!I)
		return FALSE

	if(istype(I, /obj/item/dildo))
		return TRUE

	return FALSE

/proc/get_speed_multiplier(s)
	switch(s)
		if(SEX_SPEED_LOW) return 1.0
		if(SEX_SPEED_MID) return 1.5
		if(SEX_SPEED_HIGH) return 2.0
		if(SEX_SPEED_EXTREME) return 2.5
	return 1.0

/proc/get_stamina_cost_multiplier(f)
	switch(f)
		if(SEX_FORCE_LOW) return 1.0
		if(SEX_FORCE_MID) return 1.5
		if(SEX_FORCE_HIGH) return 2.0
		if(SEX_FORCE_EXTREME) return 2.5
	return 1.0
