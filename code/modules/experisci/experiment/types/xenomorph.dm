/datum/experiment/scanning/xenomorph
	name = "xenomorph scanning experiment"
	description = "Base experiment for scanning xenomorphs"
	exp_tag = "xeno_scan"
	possible_types = list(/obj/item/organ/internal/body_egg/alien_embryo, /mob/living/carbon/alien/adult/nova/queen)
	///List of possible plant genes the experiment may ask for.
	var/list/possible_scan = list()
	///List of plant genes actually required, indexed by the atom that is required.
	var/list/required = list()

/datum/experiment/scanning/random/plants/New(datum/techweb/techweb)
	. = ..()
	if(possible_scan.len)
		for(var/req_atom in required_atoms)
			var/chosen = pick(possible_scan)
			required[req_atom] = chosen
