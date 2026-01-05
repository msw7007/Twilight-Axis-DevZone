#define ART_POWDER_REAGENT /datum/reagent/artillery_powder

#define ART_POWDER_BARREL_MAX 300
#define ART_POWDER_HAND_MAX 25

#define ART_MORTAR_POWDER_MAX 200
#define ART_MORTAR_SAFE_POWDER 150

#define COMSIG_ARTILLERY_FIRE "artillery_fire"

#define ART_PERS_MIN 1
#define ART_PERS_NORMAL 10
#define ART_PERS_MAX 20

#define ART_WIND_MAX 5
#define ART_EXPLOSION_DEVASTATION (-1)

#define ART_RANGE_K (0.35 * 12)
#define ART_WIND_K 2.2

#define ART_POWDER_POTENCY_MIN 0.85
#define ART_POWDER_POTENCY_MAX 1.15

#define ART_ELEVATION_MIN 20
#define ART_ELEVATION_MAX 80
#define ART_ELEVATION_DEFAULT 45

GLOBAL_LIST_INIT(artillery_explode_sounds, list(
	'sound/misc/explode/incendiary (1).ogg',
	'sound/misc/explode/incendiary (2).ogg'
))

#define ART_INSTRUMENT_TIME (3 SECONDS)

#define ART_TURF_OPENSPACE /turf/open/transparent/openspace
