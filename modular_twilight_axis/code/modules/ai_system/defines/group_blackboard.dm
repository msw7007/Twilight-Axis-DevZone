#ifndef GROUP_AI_BLACKBOARD_DM
#define GROUP_AI_BLACKBOARD_DM

// ---- Group BB keys (written by group, read by group_tactics subtree) ----
#define BB_GROUP_REF            "bb_group_ref"
#define BB_GROUP_ROLE           "bb_group_role"
#define BB_GROUP_TACTIC         "bb_group_tactic"
#define BB_GROUP_FOCUS_TARGET   "bb_group_focus_target"
#define BB_GROUP_SHOULD_NOT_KILL "bb_group_should_not_kill"
#define BB_GROUP_CAN_CAPTURE    "bb_group_can_capture"

// ---- Generic tactic IDs (reusable across species) ----
#define GROUP_TACTIC_RETREAT    "retreat"

// ---- Tunables ----
#define GROUP_AI_UPDATE_COOLDOWN  (1 SECONDS)
#define GROUP_AI_SCAN_RANGE       12
#define GROUP_AI_LOST_GRACE       (8 SECONDS)
#define GROUP_AI_COHESION_MULT    2
#define GROUP_AI_SIGNAL_COOLDOWN  (4 SECONDS)
#define GROUP_AI_CRIT_THRESHOLD   0.25

#endif
