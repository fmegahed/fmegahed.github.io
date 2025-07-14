

# * Context ---------------------------------------------------------------

# We downloaded the https://static.nhtsa.gov/odi/ffdd/rcl/FLAT_RCL.zip dataset
# and unzipped it. The dataset contains information about vehicle and equipment 
# recalls in the USA.
# The dataset is in tab-delimited format. The metadata is available in:
# https://static.nhtsa.gov/odi/ffdd/rcl/RCL.txt (used for column names and types)



# * Reading and Filtering the Dataset -------------------------------------

recalls = readr::read_delim(
  "data/FLAT_RCL.txt", 
  delim = "\t",
  # based on https://static.nhtsa.gov/odi/ffdd/rcl/RCL.txt (name or desc based)
  col_names = c(
    "record_id", "campaign_number", "make", "model", "year", 
    "manf_campaign_number", "component_desc", "manufacturer", "begin_manf_date",
    "end_manf_date", "vehicle_equipment_tire_report", "potential_vehicles_affected",
    "date_owner_notified_by_manf", "recall_initatior", "manufactuerers_of_recalled",
    "report_receieved_date", "record_creation_date", "regulation_part_number",
    "federal_motor_vehicle_safety_standard_number", "defect_description",
    "consequence_description", "corrective_action_description", "recall_notes",
    "recall_component_id", "manufacturer_component_name", 
    "manufacturer_component_description",
    "manufacturer_component_number"
  )
) |> 
  # removing unknown years
  dplyr::filter(year >= 2024 & year < 9999) |> 
  # keeping only unique recall_descriptions since a recall can impact multiple models and makes
  dplyr::distinct(defect_description, .keep_all = TRUE)



# * Initial Testing with Ellmer -------------------------------------------

# Ref: https://ellmer.tidyverse.org/articles/structured-data.html 

chat = ellmer::chat_ollama(model = 'gemma3:27b')

type_recall = ellmer::type_object(
  manufacturer   = ellmer::type_string("The name of the company recalling the vehicles.", required = FALSE),
  models         = ellmer::type_string("List of affected vehicle models.", required = FALSE),
  model_years    = ellmer::type_string("List of model years affected.", required = FALSE),
  defect_summary = ellmer::type_string("Summary of the main defect.", required = FALSE),
  component      = ellmer::type_string("The part or system affected by the defect.", required = FALSE),
  fmvss_number   = ellmer::type_string("The FMVSS number mentioned, if any.", required = FALSE),
  root_cause     = ellmer::type_string("The root cause of the defect.", required = FALSE),
  risk           = ellmer::type_string("The risk or consequence posed by the defect.", required = FALSE)
)

extract_fn = function(x, chat_object, custom_type_object){
  
  return( chat_object$extract_data(x, type = custom_type_object) )
}

extracted_data = purrr::map_df(
  .x = recalls$defect_description[1:2], # for testing purposes before we map multiple models and repeats in the next section
  .f = extract_fn,
  chat_object = chat,
  custom_type_object = type_recall
  ) 



# * Looping Over Multiple Models and Repeats ------------------------------
# Re-introduced some of the objects from above so this can be standalone

# Define your chat models
chat_list = list(
  gemma3_27b = ellmer::chat_ollama(model = "gemma3:27b"),
  gemma3_1b  = ellmer::chat_ollama(model = "gemma3:1b")
)

# Define the extraction type
type_recall = ellmer::type_object(
  manufacturer   = ellmer::type_string("The name of the company recalling the vehicles.", required = FALSE),
  models         = ellmer::type_string("List of affected vehicle models.", required = FALSE),
  model_years    = ellmer::type_string("List of model years affected.", required = FALSE),
  defect_summary = ellmer::type_string("Summary of the main defect.", required = FALSE),
  component      = ellmer::type_string("The part or system affected by the defect.", required = FALSE),
  fmvss_number   = ellmer::type_string("The FMVSS number mentioned, if any.", required = FALSE),
  root_cause     = ellmer::type_string("The root cause of the defect.", required = FALSE),
  risk           = ellmer::type_string("The risk or consequence posed by the defect.", required = FALSE)
)

# Number of repeats per model
n_repeats = 3

# Create model x repeat grid
model_runs = tidyr::crossing(
  model_name = names(chat_list),
  repeat_id = seq_len(n_repeats)
)

# Extract function
extract_fn = function(x, chat_object, custom_type_object){
  
  return( chat_object$extract_data(x, type = custom_type_object) )
}

# Using possibly to handle errors
safe_extract_fn = purrr::possibly(
  .f = extract_fn,
  otherwise = tibble::tibble(
    manufacturer = NA_character_,
    models = NA_character_,
    model_years = NA_character_,
    defect_summary = NA_character_,
    component = NA_character_,
    fmvss_number = NA_character_,
    root_cause = NA_character_,
    risk = NA_character_
  )
)

# Run all combinations
all_results = model_runs |> 
  purrr::pmap_df(function(model_name, repeat_id) {
    
    chat_object = chat_list[[model_name]]
    
    data = purrr::map_df(
      recalls$defect_description, 
      safe_extract_fn,
      chat_object = chat_object,
      custom_type_object = type_recall
    )
    
    data$model_name = model_name
    data$repeat_id = repeat_id
    data$chat_timestamp = Sys.time()
    
    return(data)
  })

# Save the results
readr::write_csv(
  all_results,
  "results/recalls_extracted.csv"
)
