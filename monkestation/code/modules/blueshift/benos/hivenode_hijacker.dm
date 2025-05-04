/obj/item/assembly/flash/xenomorph
	name = "Hivenode Hijacker"
	desc = "A modified flash device, programmed to flash xenos"
	icon_state = "flash" //need CUSTOM ICON
	light_color = LIGHT_COLOR_PINK
	var/contains_node = FALSE //does NOT contain node by default
	burnout_resistance = 1 //NO BURNOUTS

/obj/item/assembly/flash/xenomorph/attack(mob/living/M, mob/user)
	if(!try_use_flash(user))
		return FALSE

	. = TRUE
	if(isalien(M))
		if(contains_node)
			log_combat(user, M, "flashed", src)
			update_icon(ALL, TRUE)
			M.mind.remove_all_antag_datums()
			var/datum/antagonist/xeno/xeno_datum = new
			var/datum/objective/protect/protect_objective = new
			var/datum/objective/custom/listen_objective = new
			protect_objective.target = user.mind
			protect_objective.update_explanation_text()
			listen_objective.explanation_text = "Listen to any commands given by [user.name]"
			listen_objective.completed = TRUE // its just an objective for flavor less-so than for greentext
			xeno_datum.objectives += protect_objective
			xeno_datum.objectives += listen_objective
			M.mind.add_antag_datum(xeno_datum)

//some function to use a hive node to turn the contains_node variable true
