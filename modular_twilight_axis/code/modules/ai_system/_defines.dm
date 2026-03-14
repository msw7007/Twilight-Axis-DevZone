/// group modes
#define GROUP_MODE_IDLE "idle"
#define GROUP_MODE_HUNT "hunt"
#define GROUP_MODE_PRESSURE "pressure"
#define GROUP_MODE_LIQUIDATE "liquidate"
#define GROUP_MODE_FALLBACK "fallback"

/// roles
#define AIROLE_NONE "none"

/// orders
#define AIORDER_NONE "none"
#define AIORDER_FOLLOW_LEADER "follow_leader"
#define AIORDER_APPROACH_TARGET "approach_target"
#define AIORDER_RETREAT_TARGET "retreat_target"
#define AIORDER_MELEE_TARGET "melee_target"
#define AIORDER_RANGED_TARGET "ranged_target"
#define AIORDER_FINISH_TARGET "finish_target"
#define AIORDER_FILL_MELEE_SLOT "fill_melee_slot"
#define AIORDER_YIELD_MELEE_SLOT "yield_melee_slot"

/// signals
#define AISIG_SEE_ENEMY "see_enemy"
#define AISIG_TAKE_DAMAGE "take_damage"
#define AISIG_TARGET_PRONE "target_prone"
#define AISIG_TARGET_DEAD "target_dead"
#define AISIG_TARGET_LOST "target_lost"
#define AISIG_PULL "pull"
#define AISIG_TAUNT "taunt"

/// order states
#define AI_ORDER_PENDING 1
#define AI_ORDER_RUNNING 2
#define AI_ORDER_DONE 3
#define AI_ORDER_FAILED 4
#define AI_ORDER_CANCELLED 5
