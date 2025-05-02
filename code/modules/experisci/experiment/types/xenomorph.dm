/datum/experiment/scanning/xenomorph_lifecycle
    name = "Xenomorph Lifecycle Scanning"
    description = "Study the lifecycle of xenomorphs by scanning a xenomorph embryo and an alien queen."
    exp_tag = "Xenomorph Lifecycle Scan"
    total_requirement = 2 // Requires scanning two items
    possible_atoms = list(
        /obj/item/organ/internal/body_egg/alien_embryo, // Xenomorph embryo
        /mob/living/carbon/alien/adult/nova/queen // Alien queen
    )
/datum/experiment/scanning/xenomorph_lifecycle/New(datum/techweb/techweb)
	. = ..()
	for(var/req_atom in required_atoms)
		var/chosen_gene = pick(possible_atoms)
		required_genes[req_atom] = chosen_gene

    // Serialize progress for the experiment
    serialize_progress_stage(atom/target, list/seen_instances)
        return EXPERIMENT_PROG_INT(
            "Scan samples of the following xenomorph lifecycle stages: embryo and queen.",
            seen_instances.len, // Count the number of seen instances
            required_atoms[target]
        )

    // Ensure only valid targets contribute to the experiment
    final_contributing_index_checks(atom/target, typepath)
        if (istype(target, /obj/item/organ/internal/body_egg/alien_embryo) || istype(target, /mob/living/carbon/alien/adult/nova/queen))
            return TRUE
        return FALSE

/datum/techweb_node/xenomorph_lifecycle
    id = "xenomorph_lifecycle"
    display_name = "Xenomorph Lifecycle Research"
    description = "Unlocks research into the lifecycle of xenomorphs."
    cost = TECHWEB_TIER_1_COST // Place it at the bottom level of the tech tree
    unlocks = list(/datum/experiment/scanning/xenomorph_lifecycle)
