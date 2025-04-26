// A spawner which spawns either a xeno larva or a cortical borer

/obj/item/worm_spawner
    name = "Worm Spawner"
    desc = "A spawner that can release a worm."
    icon = 'monkestation/code/modules/antagonists/borers/icons/items.dmi' // file has larva and borer items named accordingly
    icon_state = "cage"
    var/opened = FALSE
    var/delayed = FALSE
    var/polling_time = 10 SECONDS
    var/datum/worm_type/worm = new /datum/worm_type/borer // Default to borer

/obj/item/worm_spawner/Initialize(mapload)
    . = ..()
    update_appearance()

/obj/item/worm_spawner/update_appearance()
    icon_state = worm.icon_state
    if (opened)
        icon_state += "_doors_open"
    else
        icon_state += "_doors_closed"

/obj/item/worm_spawner/proc/do_wriggler_messages()
    if (!opened)
        return
    sleep(polling_time * 0.2)
    visible_message(span_notice("The [worm.name] seems to have woken up."))
    if (!opened)
        return
    sleep(polling_time * 0.2)
    visible_message(span_notice("The [worm.name] has perked up their head, finally noticing the opened cage..."))
    sleep(polling_time * 0.2)
    visible_message(span_notice("The [worm.name] seems to slither cautiously to the cage entrance..."))
    sleep(polling_time * 0.1)
    visible_message(span_notice("The [worm.name]'s head peeks outside of the cage..."))

/obj/item/worm_spawner/attack_self(mob/living/user)
    if (opened)
        return
    user.visible_message("[user] opens [src].", "You have opened the [src], awaiting for the [worm.name] to come out.", "You hear a metallic thunk.")
    opened = TRUE
    playsound(src, 'sound/machines/boltsup.ogg', 30, TRUE)
    if (delayed)
        sleep(delayed)
    INVOKE_ASYNC(src, PROC_REF(do_wriggler_messages))
    update_appearance()

    var/list/candidates = worm.poll_candidates(polling_time)

    if (QDELETED(src))
        return
    if (!LAZYLEN(candidates))
        opened = FALSE
        to_chat(user, "Yet the [worm.name] after looking at you quickly retreats back into their cage, visibly scared. Perhaps try later?")
        playsound(src, 'sound/machines/boltsup.ogg', 30, TRUE)
        update_appearance()
        return

    var/mob/dead/observer/picked_candidate = pick(candidates)
    var/mob/living/new_mob = worm.create_worm(drop_location(), picked_candidate)

    var/datum/objective/protect/protect_objective = new
    var/datum/objective/custom/listen_objective = new

    protect_objective.target = user.mind
    protect_objective.update_explanation_text()

    listen_objective.explanation_text = "Listen to any commands given by [user.name]"
    listen_objective.completed = TRUE

    new_mob.mind.remove_all_antag_datums()
    new_mob.mind.add_antag_datum(worm.create_antagonist_datum(protect_objective, listen_objective))

    notify_ghosts(
        "[new_mob] has been chosen from the ghost pool!",
        source = new_mob,
        action = NOTIFY_ORBIT,
        header = "Someone just got a new friend!"
    )
    message_admins("[ADMIN_LOOKUPFLW(new_mob)] has been made into a [worm.name] via a traitor item used by [user].")
    log_game("[key_name(new_mob)] was spawned as a [worm.name] by [key_name(user)].")
    visible_message("A [worm.name] wriggles out of the [src]!")

    var/obj/item/cortical_cage/empty_cage = new(drop_location())
    var/user_held = user.get_held_index_of_item(src)
    if (user_held)
        user.dropItemToGround(src, force = TRUE, silent = TRUE)
        user.put_in_hand(empty_cage, user_held, ignore_anim = TRUE)
    qdel(src)

/datum/worm_type
    var/name = "worm"
    var/icon_state = "worm"
    var/role = null
    var/alert_pic = null

    proc/poll_candidates(polling_time)
    var/list/candidates = list()
    for (var/mob/dead/observer/ghost in world) // Iterate over all ghosts in the world
        if (!ghost.client) // Skip ghosts without a client
            continue
        if (ghost.mind && ghost.mind.assigned_role) // Skip ghosts with assigned roles
            continue
        candidates += ghost // Add valid ghost to the list
    sleep(polling_time) // Wait for the polling time
    return candidates

    proc/create_worm(location, candidate)
        return null // To be overridden by subtypes

    proc/create_antagonist_datum(protect_objective, listen_objective)
        return null // To be overridden by subtypes

/datum/worm_type/larva
    name = "larva"
    icon_state = "larva"
    role = ROLE_ALIEN
    alert_pic = /mob/living/carbon/alien/larva

    proc/create_worm(location, candidate)
        var/mob/living/carbon/alien/larva/new_mob = new(location, TRUE)
        new_mob.PossessByPlayer(candidate.ckey)
        return new_mob

    proc/create_antagonist_datum(protect_objective, listen_objective)
        return list(protect_objective, listen_objective)

/datum/worm_type/borer
    name = "borer"
    icon_state = "borer"
    role = ROLE_CORTICAL_BORER
    alert_pic = /mob/living/basic/cortical_borer/neutered

    proc/create_worm(location, candidate)
        var/mob/living/basic/cortical_borer/neutered/new_mob = new(location)
        new_mob.PossessByPlayer(candidate.ckey)
        return new_mob

    proc/create_antagonist_datum(protect_objective, listen_objective)
        return list(protect_objective, listen_objective)
