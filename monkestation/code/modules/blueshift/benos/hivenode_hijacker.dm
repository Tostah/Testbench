/obj/item/assembly/flash/xenomorph
	name = "Hivenode Hijacker"
	desc = "A flash device, that, when a xenomorph hive node is added, allows the user to hijack xenomorph hiveminds."
	icon_state = "flash" //need CUSTOM ICON
	light_color = LIGHT_COLOR_PINK
	var/contains_node = FALSE //does NOT contain node by default
	burnt_out = TRUE //burnt out by default, unusable without a node

/obj/item/assembly/flash/xenomorph/attack(mob/living/M, mob/user)
	if(!try_use_flash(user))
		return FALSE

	. = TRUE
	if(isalien(M) && contains_node)
		log_combat(user, M, "brainwashed", src)
		update_icon(ALL, TRUE)
		M.mind.remove_all_antag_datums()
		var/datum/antagonist/xeno/xeno_datum = new
		var/datum/objective/custom/brainwashed_xenomorph = new
		brainwashed_xenomorph.explanation_text = "[user.name] is the Queen of the Hive. Obey and protect them."
		brainwashed_xenomorph.completed = TRUE // its just an objective for flavor less-so than for greentext
		xeno_datum.objectives += brainwashed_xenomorph
		M.mind.add_antag_datum(xeno_datum)


/obj/item/assembly/flash/xenomorph/attackby(obj/item/organ/internal/alien/hivenode/H, mob/living/user)
	if(contains_node)
		to_chat(user, "The hijacker already contains a hive node")
	else
		contains_node = TRUE
		burnt_out = FALSE
		qdel(H) //GET IT OUT OF HERE
		to_chat(user, "You sucessfully insert the hive node into the hijacker")
	return

