/**
 * # Experimental Implanter
 *
 * Small implanter for implanting a hive node and disrupting local xenomorph hive minds
 */

 /obj/item/experimental_implanter
	name = "Experimental Implanter"
	desc = "A Small implanter for implanting a hive node and disrupting local xenomorph hive minds"
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/device.dmi'
	icon_state = "experiscanner"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'

/obj/item/experi_scanner/Initialize(mapload)
	..()
	return INITIALIZE_HINT_LATELOAD

	//fix but next is the code for a hive node implanter device which targets any xenomorph players
	// on the using players screen, removing their antag datum and any xenos on their teams antag datum
	// replacing it with listen_objective and follow_objective like the corritcal borers.
