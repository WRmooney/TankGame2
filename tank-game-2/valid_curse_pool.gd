extends Node

@export var valid_curse_names: Array[String] = []

func filter_curses(curses: Array[String]):
	var valid_curses: Array[String] = []
	for curse in curses:
		if curse in valid_curse_names:
			valid_curses.append(curse)
	return valid_curses
