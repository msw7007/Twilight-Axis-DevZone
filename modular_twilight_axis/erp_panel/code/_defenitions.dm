#define SEX_ORGAN_MOUTH (1<<0)
#define SEX_ORGAN_HANDS (1<<1)
#define SEX_ORGAN_PENIS (1<<2)
#define SEX_ORGAN_VAGINA (1<<3)
#define SEX_ORGAN_ANUS (1<<4)
#define SEX_ORGAN_BREASTS (1<<5)
#define SEX_ORGAN_TAIL (1<<6)
#define SEX_ORGAN_LEGS (1<<7)

#define SEX_CHAT_FREQUENCY 3

#define SEX_SENSITIVITY_MAX  2
#define SEX_PAIN_MAX         2

#define SEX_SENSITIVITY_GAIN          0.1
#define SEX_PAIN_GAIN_HIGH_PASSIVE    0.05
#define SEX_PAIN_GAIN_EXTREME_PASSIVE 0.1
#define SEX_PAIN_GAIN_EXTREME_ACTIVE  0.03

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
