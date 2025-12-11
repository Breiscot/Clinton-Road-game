extends Node

# Segnali globali per comunicazione tra scene
signal show_interaction_prompt(text: String)
signal hide_interaction_prompt
signal player_damaged(amount: float)
signal player_died
signal enemy_alerted
signal objective_updated(text: String)
