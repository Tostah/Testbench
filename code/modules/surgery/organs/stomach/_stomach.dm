//The contant in the rate of reagent transfer on life ticks
#define STOMACH_METABOLISM_CONSTANT 0.25

/obj/item/organ/internal/stomach
	name = "stomach"
	icon_state = "stomach"
	visual = FALSE
	w_class = WEIGHT_CLASS_SMALL
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_STOMACH
	attack_verb_continuous = list("gores", "squishes", "slaps", "digests")
	attack_verb_simple = list("gore", "squish", "slap", "digest")
	desc = "Onaka ga suite imasu."

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY * 1.15 // ~13 minutes, the stomach is one of the first organs to die

	low_threshold_passed = "<span class='info'>Your stomach flashes with pain before subsiding. Food doesn't seem like a good idea right now.</span>"
	high_threshold_passed = "<span class='warning'>Your stomach flares up with constant pain- you can hardly stomach the idea of food right now!</span>"
	high_threshold_cleared = "<span class='info'>The pain in your stomach dies down for now, but food still seems unappealing.</span>"
	low_threshold_cleared = "<span class='info'>The last bouts of pain in your stomach have died out.</span>"

	food_reagents = list(/datum/reagent/consumable/nutriment/organ_tissue = 5)
	//This is a reagent user and needs more then the 10u from edible component
	reagent_vol = 1000

	///The rate that disgust decays
	var/disgust_metabolism = 1

	///The rate that the stomach will transfer reagents to the body
	var/metabolism_efficiency = 0.05 // the lowest we should go is 0.025

	var/operated = FALSE //whether the stomach's been repaired with surgery and can be fixed again or not

	/// Typecache of food we can eat that will never give us disease.
	var/list/disease_free_foods
	///our hunger modifier
	var/hunger_modifier = 1

/obj/item/organ/internal/stomach/Initialize(mapload)
	. = ..()
	//None edible organs do not get a reagent holder by default
	if(!reagents)
		create_reagents(reagent_vol, REAGENT_HOLDER_ALIVE)
	else
		reagents.flags |= REAGENT_HOLDER_ALIVE

/obj/item/organ/internal/stomach/on_life(seconds_per_tick, times_fired)
	. = ..()

	//Manage species digestion
	if(ishuman(owner))
		var/mob/living/carbon/human/humi = owner
		if(!(organ_flags & ORGAN_FAILING))
			handle_hunger(humi, seconds_per_tick, times_fired)

	var/mob/living/carbon/body = owner

	// digest food, sent all reagents that can metabolize to the body
	for(var/datum/reagent/bit as anything in reagents.reagent_list)

		// If the reagent does not metabolize then it will sit in the stomach
		// This has an effect on items like plastic causing them to take up space in the stomach
		if(bit.metabolization_rate <= 0)
			continue

		//Ensure that the the minimum is equal to the metabolization_rate of the reagent if it is higher then the STOMACH_METABOLISM_CONSTANT
		var/rate_min = max(bit.metabolization_rate, STOMACH_METABOLISM_CONSTANT)
		//Do not transfer over more then we have
		var/amount_max = bit.volume

		//If the reagent is part of the food reagents for the organ
		//prevent all the reagents form being used leaving the food reagents
		var/amount_food = food_reagents[bit.type]
		if(amount_food)
			amount_max = max(amount_max - amount_food, 0)

		// Transfer the amount of reagents based on volume with a min amount of 1u
		var/amount = min((round(metabolism_efficiency * amount_max, 0.05) + rate_min) * seconds_per_tick, amount_max)

		if(amount <= 0)
			continue

		// transfer the reagents over to the body at the rate of the stomach metabolim
		// this way the body is where all reagents that are processed and react
		// the stomach manages how fast they are feed in a drip style
		reagents.trans_id_to(body, bit.type, amount=amount)

	//Handle disgust
	if(body)
		handle_disgust(body, seconds_per_tick, times_fired)

	//If the stomach is not damage exit out
	if(damage < low_threshold)
		return

	//We are checking if we have nutriment in a damaged stomach.
	var/datum/reagent/nutri = locate(/datum/reagent/consumable/nutriment) in reagents.reagent_list
	//No nutriment found lets exit out
	if(!nutri)
		return

	// remove the food reagent amount
	var/nutri_vol = nutri.volume
	var/amount_food = food_reagents[nutri.type]
	if(amount_food)
		nutri_vol = max(nutri_vol - amount_food, 0)

	// found nutriment was stomach food reagent
	if(!(nutri_vol > 0))
		return

	//The stomach is damage has nutriment but low on theshhold, lo prob of vomit
	if(SPT_PROB(0.0125 * damage * nutri_vol * nutri_vol, seconds_per_tick))
		body.vomit(damage)
		to_chat(body, span_warning("Your stomach reels in pain as you're incapable of holding down all that food!"))
		return

	// the change of vomit is now high
	if(damage > high_threshold && SPT_PROB(0.05 * damage * nutri_vol * nutri_vol, seconds_per_tick))
		body.vomit(damage)
		to_chat(body, span_warning("Your stomach reels in pain as you're incapable of holding down all that food!"))

/obj/item/organ/internal/stomach/proc/handle_hunger(mob/living/carbon/human/human, seconds_per_tick, times_fired)
	if(HAS_TRAIT(human, TRAIT_NOHUNGER))
		return //hunger is for BABIES

	//The fucking TRAIT_FAT mutation is the dumbest shit ever. It makes the code so difficult to work with
	if(HAS_TRAIT_FROM(human, TRAIT_FAT, OBESITY))//I share your pain, past coder.
		if(human.overeatduration < (200 SECONDS))
			to_chat(human, span_notice("You feel fit again!"))
			REMOVE_TRAIT(human, TRAIT_FAT, OBESITY)

	else
		if(human.overeatduration >= (200 SECONDS))
			to_chat(human, span_danger("You suddenly feel blubbery!"))
			ADD_TRAIT(human, TRAIT_FAT, OBESITY)

	// nutrition decrease and satiety
	if (human.nutrition > 0 && human.stat != DEAD)
		// THEY HUNGER
		var/hunger_rate = HUNGER_FACTOR * PASSIVE_HUNGER_MULTIPLIER
		if(human.mob_mood?.sanity > SANITY_DISTURBED)
			hunger_rate *= max(1 - 0.002 * human.mob_mood.sanity, 0.5) //0.85 to 0.75
		// Whether we cap off our satiety or move it towards 0
		if(human.satiety > 0)
			human.adjust_satiety(-1 * seconds_per_tick)

		else if(human.satiety < 0)
			human.adjust_satiety(1 * seconds_per_tick)
			if(SPT_PROB(round(-human.satiety/77), seconds_per_tick))
				human.set_jitter_if_lower(10 SECONDS)
			hunger_rate *= 3

		hunger_rate *= hunger_modifier
		hunger_rate *= human.physiology.hunger_mod
		human.adjust_nutrition(-1 * hunger_rate * seconds_per_tick)

	var/nutrition = human.nutrition
	if(nutrition > NUTRITION_LEVEL_FULL)
		if(human.overeatduration < 20 MINUTES) //capped so people don't take forever to unfat
			human.overeatduration = min(human.overeatduration + (1 SECONDS * seconds_per_tick), 20 MINUTES)
	else
		if(human.overeatduration > 0)
			human.overeatduration = max(human.overeatduration - (2 SECONDS * seconds_per_tick), 0) //doubled the unfat rate

	//metabolism change
	if(nutrition > NUTRITION_LEVEL_FAT)
		human.metabolism_efficiency = 1
	else if(nutrition > NUTRITION_LEVEL_FED && human.satiety > 80)
		if(human.metabolism_efficiency != 1.25)
			to_chat(human, span_notice("You feel vigorous."))
			human.metabolism_efficiency = 1.25
	else if(nutrition < NUTRITION_LEVEL_STARVING + 50)
		if(human.metabolism_efficiency != 0.8)
			to_chat(human, span_notice("You feel sluggish."))
		human.metabolism_efficiency = 0.8
	else
		if(human.metabolism_efficiency == 1.25)
			to_chat(human, span_notice("You no longer feel vigorous."))
		human.metabolism_efficiency = 1

	//Hunger slowdown for if mood isn't enabled
	if(CONFIG_GET(flag/disable_human_mood))
		handle_hunger_slowdown(human)

///for when mood is disabled and hunger should handle slowdowns
/obj/item/organ/internal/stomach/proc/handle_hunger_slowdown(mob/living/carbon/human/human)
	var/hungry = (500 - human.nutrition) / 5 //So overeat would be 100 and default level would be 80
	if(hungry >= 70)
		human.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/hunger, multiplicative_slowdown = (hungry / 50))
	else
		human.remove_movespeed_modifier(/datum/movespeed_modifier/hunger)

/obj/item/organ/internal/stomach/get_availability(datum/species/owner_species, mob/living/owner_mob)
	return owner_species.mutantstomach

///This gets called after the owner takes a bite of food
/obj/item/organ/internal/stomach/proc/after_eat(atom/edible)
	return

/obj/item/organ/internal/stomach/proc/handle_disgust(mob/living/carbon/human/disgusted, seconds_per_tick, times_fired)
	var/old_disgust = disgusted.old_disgust
	var/disgust = disgusted.disgust

	if(disgust)
		var/pukeprob = 2.5 + (0.025 * disgust)
		if(disgust >= DISGUST_LEVEL_GROSS)
			if(SPT_PROB(5, seconds_per_tick))
				disgusted.adjust_stutter(2 SECONDS)
				disgusted.adjust_confusion(2 SECONDS)
			if(SPT_PROB(5, seconds_per_tick) && !disgusted.stat)
				to_chat(disgusted, span_warning("You feel kind of iffy..."))
			disgusted.adjust_jitter(-6 SECONDS)
		if(disgust >= DISGUST_LEVEL_VERYGROSS)
			if(SPT_PROB(pukeprob, seconds_per_tick)) //iT hAndLeS mOrE ThaN PukInG
				disgusted.adjust_confusion(2.5 SECONDS)
				disgusted.adjust_stutter(2 SECONDS)
				disgusted.vomit(10, distance = 0, vomit_type = NONE)
				disgusted.adjust_disgust(-50)
			disgusted.set_dizzy_if_lower(10 SECONDS)
		if(disgust >= DISGUST_LEVEL_DISGUSTED)
			if(SPT_PROB(13, seconds_per_tick))
				disgusted.set_eye_blur_if_lower(6 SECONDS) //We need to add more shit down here

		disgusted.adjust_disgust(-0.25 * disgust_metabolism * seconds_per_tick)

	// I would consider breaking this up into steps matching the disgust levels
	// But disgust is used so rarely it wouldn't save a significant amount of time, and it makes the code just way worse
	// We're in the same state as the last time we processed, so don't bother
	if(old_disgust == disgust)
		return

	disgusted.old_disgust = disgust
	switch(disgust)
		if(0 to DISGUST_LEVEL_GROSS)
			disgusted.clear_alert(ALERT_DISGUST)
			disgusted.clear_mood_event("disgust")
		if(DISGUST_LEVEL_GROSS to DISGUST_LEVEL_VERYGROSS)
			disgusted.throw_alert(ALERT_DISGUST, /atom/movable/screen/alert/gross)
			disgusted.add_mood_event("disgust", /datum/mood_event/gross)
		if(DISGUST_LEVEL_VERYGROSS to DISGUST_LEVEL_DISGUSTED)
			disgusted.throw_alert(ALERT_DISGUST, /atom/movable/screen/alert/verygross)
			disgusted.add_mood_event("disgust", /datum/mood_event/verygross)
		if(DISGUST_LEVEL_DISGUSTED to INFINITY)
			disgusted.throw_alert(ALERT_DISGUST, /atom/movable/screen/alert/disgusted)
			disgusted.add_mood_event("disgust", /datum/mood_event/disgusted)

/obj/item/organ/internal/stomach/Insert(mob/living/carbon/receiver, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	receiver.hud_used?.hunger?.update_hunger_bar()

/obj/item/organ/internal/stomach/Remove(mob/living/carbon/stomach_owner, special = FALSE)
	if(ishuman(stomach_owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.clear_alert(ALERT_DISGUST)
		human_owner.clear_mood_event("disgust")
	stomach_owner.hud_used?.hunger?.update_hunger_bar()
	return ..()

/obj/item/organ/internal/stomach/bone
	desc = "You have no idea what this strange ball of bones does."
	metabolism_efficiency = 0.025 //very bad
	organ_traits = list(TRAIT_NOHUNGER)
	/// How much [BRUTE] damage milk heals every second
	var/milk_brute_healing = 2.5
	/// How much [BURN] damage milk heals every second
	var/milk_burn_healing = 2.5

/obj/item/organ/internal/stomach/bone/on_life(seconds_per_tick, times_fired)
	var/datum/reagent/consumable/milk/milk = locate(/datum/reagent/consumable/milk) in reagents.reagent_list
	if(milk)
		var/mob/living/carbon/body = owner
		if(milk.volume > 50)
			reagents.remove_reagent(milk.type, milk.volume - 5)
			to_chat(owner, span_warning("The excess milk is dripping off your bones!"))
		body.heal_bodypart_damage(milk_brute_healing * REM * seconds_per_tick, milk_burn_healing * REM * seconds_per_tick)

		for(var/datum/wound/iter_wound as anything in body.all_wounds)
			iter_wound.on_xadone(1 * REM * seconds_per_tick)
		reagents.remove_reagent(milk.type, milk.metabolization_rate * seconds_per_tick)
	return ..()

/obj/item/organ/internal/stomach/bone/plasmaman
	name = "digestive crystal"
	icon_state = "stomach-p"
	organ_traits = list()
	desc = "A strange crystal that is responsible for metabolizing the unseen energy force that feeds plasmamen."
	metabolism_efficiency = 0.06
	milk_burn_healing = 0

/obj/item/organ/internal/stomach/cybernetic
	name = "basic cybernetic stomach"
	icon_state = "stomach-c"
	desc = "A basic device designed to mimic the functions of a human stomach"
	organ_flags = ORGAN_ROBOTIC
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.5
	var/emp_vulnerability = 80 //Chance of permanent effects if emp-ed.
	metabolism_efficiency = 0.035 // not as good at digestion

/obj/item/organ/internal/stomach/cybernetic/tier2
	name = "cybernetic stomach"
	icon_state = "stomach-c-u"
	desc = "An electronic device designed to mimic the functions of a human stomach. Handles disgusting food a bit better."
	maxHealth = 1.5 * STANDARD_ORGAN_THRESHOLD
	disgust_metabolism = 2
	emp_vulnerability = 40
	metabolism_efficiency = 0.07

/obj/item/organ/internal/stomach/cybernetic/tier3
	name = "upgraded cybernetic stomach"
	icon_state = "stomach-c-u2"
	desc = "An upgraded version of the cybernetic stomach, designed to improve further upon organic stomachs. Handles disgusting food very well."
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD
	disgust_metabolism = 3
	emp_vulnerability = 20
	metabolism_efficiency = 0.1

/obj/item/organ/internal/stomach/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(!COOLDOWN_FINISHED(src, severe_cooldown)) //So we cant just spam emp to kill people.
		owner.vomit(stun = FALSE)
		COOLDOWN_START(src, severe_cooldown, 10 SECONDS)
	if(prob(emp_vulnerability/severity)) //Chance of permanent effects
		organ_flags |= ORGAN_EMP //Starts organ faliure - gonna need replacing soon.

// Lizard stomach to Let Them Eat Rat
/obj/item/organ/internal/stomach/lizard
	name = "lizardperson stomach"
	desc = "A stomach native to a Lizardperson of Tiziran... or maybe one of its colonies."
	color = COLOR_VERY_DARK_LIME_GREEN
	// Lizards don't homeostasize (they're cold blooded) so they get hungrier faster to offset that
	// Even with this modifier, note they still get hungrier like 1.5x slower than humans
	hunger_modifier = 2

/obj/item/organ/internal/stomach/lizard/Initialize(mapload)
	. = ..()
	var/static/list/rat_cache = typecacheof(/obj/item/food/deadmouse)
	disease_free_foods = rat_cache

#undef STOMACH_METABOLISM_CONSTANT
