/**
 * ABSTRACT TYPES FOR MUTANT BODYPART PREFS
 */

/datum/preference/choiced/mutant
	abstract_type = /datum/preference/choiced/mutant
	/// Feature that will be changed on apply_on_human()
	var/relevant_feature
	/// Supplemental feature, generally used for coloring
	var/supplemental_feature_key

/datum/preference/choiced/mutant/compile_constant_data()
	var/list/data = ..()

	if(supplemental_feature_key)
		data[SUPPLEMENTAL_FEATURE_KEY] = supplemental_feature_key

	return data

/datum/preference/choiced/mutant/create_informed_default_value(datum/preferences/preferences)
	if(!relevant_cosmetic_organ)
		return ..()
	var/species_type = preferences.read_preference(/datum/preference/choiced/species)
	var/datum/species/species = new species_type
	return species.cosmetic_organs[relevant_cosmetic_organ] ? species.cosmetic_organs[relevant_cosmetic_organ] : "None"

/datum/preference/choiced/mutant/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/prefs)
	// Doesn't make sense
	if(!relevant_feature)
		return
	// Mutant preferences do not apply if not accessible
	else if(!is_accessible(prefs))
		return
	target.dna.features[relevant_feature] = value

/datum/preference/tricolor/mutant
	abstract_type = /datum/preference/tricolor/mutant
	/// Feature that will be changed on apply_on_human()
	var/relevant_feature
	/// What we use to display the right amount of colors, basically the feature that actually uses this color
	var/primary_feature_key

/datum/preference/tricolor/mutant/compile_ui_data(mob/user, value, datum/preferences/preferences)
	// if this is not a normal color and there is no associated primary feature, i'm assuming you want to display all three colors
	if(!primary_feature_key)
		return ..()
	var/datum/preference/choiced/primary_feature = GLOB.preference_entries_by_key[primary_feature_key]
	//primary feature is invalid... somehow?
	if(!istype(primary_feature))
		return ..()
	var/list/feature_list = get_global_feature_list()
	// we don't have a valid sprite accessory list
	if(!length(feature_list))
		return ..()
	var/datum/sprite_accessory/accessory = feature_list[preferences.read_preference(primary_feature.type)]
	//accessory is invalid... somehow?
	if(!istype(accessory))
		return ..()

	var/return_value = list()
	for(var/index = 1, index <= clamp(accessory.color_amount, 1, 3), index++)
		return_value += value[index]

	return jointext(return_value, ";")

/datum/preference/tricolor/mutant/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/prefs)
	// Doesn't make sense
	if(!relevant_feature)
		return
	// Mutant preferences do not apply if inaccessible
	else if(!is_accessible(prefs))
		return
	target.dna.features[relevant_feature] = value

/// Feature list we use to fetch a sprite accessory, should be overriden by subtypes
/datum/preference/tricolor/mutant/proc/get_global_feature_list()
	RETURN_TYPE(/list)
	return list()
