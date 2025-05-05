/datum/techweb_node/xenomorph_lifecycle
	id = "xenomorph_lifecycle"
	display_name = "Xenomorph Lifecycle Research"
	prereq_ids = list("base")
	description = "The lifecycle of the xenomorphs is a complex and fascinating process. We have to learn more about their lifecycle from start to finish."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS)
	required_experiments = list(/datum/experiment/scanning/xenomorph)

/datum/techweb_node/xenomorph_hivenode
	id = "xenomorph_hivenode"
	display_name = "Xenomorph Hivenode Scanning"
	prereq_ids = list("xenomorph_lifecycle")
	description = "The xenomorph hive node is the psionic link between xenomorphs. If we can hijack it, we should be able to subjugate the xenomorph subjects."
	design_ids = list(
		"hivenode_hijacker",
	)
