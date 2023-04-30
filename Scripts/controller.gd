extends Node

const letter_obj = preload("res://Objects/letter.tscn")
const enemy = preload("res://Objects/enemy.tscn")
const highscore_obj = preload("res://Objects/highscore.tscn")
const ROW_SEPERATION = 65
const SHIFT_DELAY = 1.1
const MAX_DELAY = 1.7
const BRAZIER_EFFECT = 2.0
const WILDCARD_INTERVAL = 10
const ENEMY_ROW_COUNT = 3
const ENEMY_COLUMN_COUNT = 5

var consonants_common =   "rtnslcdpmhgbrtnslcdpmhrtnslcdprtnslcrtnsrtn"
var consonants_normal =   "rtnslcdpmhgbfywkrtnslcdpmhgbfyrtnslcdpmsrtn"
var consonants_rare =     "bcdfghjklmnpqrstvwxyzbcdfghjklmnpqrstvwxyzu"
var consonants_column_4 = "nrlstcmdkgpvfbnrlstcmdgpnrlstcmdnrlstcnrlsp"
var consonants_column_5 = "sydtrnklpmgfbwsydtrnklpmgsydtrnklsydtrnsydt"
var vowels = "aaaeeeeiiiooouu"
var grace_consonants = "rstlnrstlnstncd"
var letter_templates = ["c", "r", "n"]
var letter_template_index = 0
var bonus_values = [0,0,0,100,350,1100]
var next_letter
var enemy_grid = {}
var delay = SHIFT_DELAY
var is_shifting = false
var enemy_list
var limit_barrier
var score = 0
var global_game_speed = 2.0
var match_made = false
var match_shift = false
var rows_to_shift = []
var brazier_timer = BRAZIER_EFFECT
var last_word = "---"
var can_shoot = true
var is_checking = false
var game_over = false
var letters_before_wildcard = WILDCARD_INTERVAL
var vp
var mouse_position = Vector2.ZERO
var last_mouse_position = Vector2.ZERO
var difficulty = 0.0
var difficulty_scaler = 0.001
var is_tutorial = false
var tutorial_step = 1
var tutorial_complete = false

var words_3 = []
var words_4 = []
var words_5 = []

func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	randomize()
	words_3 = get_node("WordLists/Length_3").data.split('\n')
	words_4 = get_node("WordLists/Length_4").data.split('\n')
	words_5 = get_node("WordLists/Length_5").data.split('\n')
	enemy_list = get_node("Enemies")
	limit_barrier = get_node("Limit")
	vp = get_viewport()
	is_tutorial = get_tree().root.get_node("Tutorial") != null
	for i in range(ENEMY_ROW_COUNT):
		add_row(i)
	next_letter = vowels[randi_range(0, 14)]
	add_letter_to_player()
	$BGM.play()

func sort_arr(a, b):
	if a.value > b.value:
		return true
	return false

func _process(delta):
	if game_over:
		if Input.is_action_just_released("reset"):
			get_tree().reload_current_scene()
		return
	
	if is_shifting or match_made:
		delay -= delta
		if match_made:
			if delay < SHIFT_DELAY:
				delay = SHIFT_DELAY
				match_made = false
				match_shift = true
				for shift in rows_to_shift:
					shift_row(shift.x, shift.y)
				rows_to_shift = []
				create_new_blocks()
		else:
			if delay < 0.0:
				delay = SHIFT_DELAY
				is_shifting = false
				match_shift = false
				check_for_matches(true)
	if !is_tutorial:
		if match_shift:
			brazier_timer *= 0.975
			enemy_list.position.y = clamp(enemy_list.position.y - brazier_timer, -30, 1000)
		elif not is_shifting and not match_made:
			enemy_list.position.y += (delta * global_game_speed)
			global_game_speed += difficulty_scaler
			difficulty += difficulty_scaler
	elif tutorial_complete and Input.is_action_just_released("ui_accept"):
		get_tree().change_scene_to_file("res://Scenes/base.tscn")
	
	limit_barrier.position.y = enemy_list.position.y - 675
	
	if enemy_list.position.y > 550:
		game_over = true
		can_shoot = false
		$BGM.stop()
		$CanvasLayer/Game_Over.visible = true
		var game_over_text = "You've scored: " + str(score) + "\nLeaderboard:"
		$CanvasLayer/Game_Over/Text_2.text = game_over_text
		$CanvasLayer/BarLeft.material = null
		$CanvasLayer/BarRight.material = null
		get_node("Player").destroy()
		var sw_result: Dictionary = await SilentWolf.Scores.save_score(Variables.player_name, score).sw_save_score_complete
		get_highscores()
	
	if !is_tutorial:
		if difficulty > 30.0:
			difficulty_scaler = 0.005
		elif difficulty > 12.0:
			difficulty_scaler = 0.004
		elif difficulty > 1.0:
			difficulty_scaler = 0.003
		elif difficulty > 0.1:
			difficulty_scaler = 0.002
	
	$CanvasLayer/BarRight/Score.text = str(score).lpad(6, '0')
	$CanvasLayer/BarRight/Next_Letter.text = next_letter
	$CanvasLayer/BarRight/Last_Word.text = last_word
	
	if !is_tutorial:
		$ParallaxBackground.scroll_offset += Vector2.DOWN
	
	last_mouse_position = mouse_position
	mouse_position = vp.get_mouse_position()
	mouse_position.x = clamp(mouse_position.x, 140, 560)
	mouse_position.y = clamp(mouse_position.y, enemy_list.position.y + 200, 540 if is_tutorial else 755)
	var mouse_playroom = ((mouse_position.x - 400) * 0.01)
	$CanvasLayer/BarLeft.position.x = -200 + mouse_playroom
	$CanvasLayer/BarRight.position.x = 606 + mouse_playroom
	enemy_list.position.x = mouse_playroom + 3

func add_row(column = 1):
	var row = enemy_grid.size()
	var new_row = ""
	if is_tutorial:
		var test = ["mbnng", "tlnss", "strpn"]
		new_row = test[column]
	else:
		new_row = rand_string(true)
	enemy_grid[row] = new_row
	for i in range(ENEMY_COLUMN_COUNT):
		var new_enemy = enemy.instantiate()
		new_enemy.position = Vector2(150 + (i * 100), column * ROW_SEPERATION)
		new_enemy.row = row
		new_enemy.column = i
		new_enemy.get_node("Sprite/Label").text = new_row[i]
		new_enemy.original_letter = new_row[i]
		enemy_list.add_child(new_enemy)

func add_letter_to_player():
	var new_letter = letter_obj.instantiate()
	var player = get_node("Player")
	if player.attached_letter != null:
		return
	new_letter.state = 1
	new_letter.player = player
	new_letter.get_node("Label").text = next_letter
	if next_letter == '?':
		new_letter.is_wildcard = true
	add_child(new_letter)
	new_letter.add_to_player()
	var regex = RegEx.new()
	regex.compile("[aeiou]")
	if letters_before_wildcard <= 0 and (!is_tutorial or tutorial_step > 6):
		letters_before_wildcard = WILDCARD_INTERVAL
		next_letter = '?'
	elif regex.search_all(enemy_grid[ENEMY_ROW_COUNT - 1]).size() > 3:
		next_letter = grace_consonants[randi_range(0, 14)]
	else:
		next_letter = vowels[randi_range(0, 14)]
		if next_letter == new_letter.get_node("Label").text:
			next_letter = vowels[randi_range(0, 14)]

func rand_string(forgiving = false):
	var result = ""
	letter_templates.shuffle()
	for i in letter_templates:
		if i == 'c':
			result += consonants_common[randi_range(0, 42)]
		elif i == 'r' and not forgiving:
			result += consonants_rare[randi_range(0, 42)]
		else:
			result += consonants_normal[randi_range(0, 42)]
	result += consonants_column_4[randi_range(0, 42)]
	result += consonants_column_5[randi_range(0, 42)]
	for i in range(ENEMY_COLUMN_COUNT - 1):
		if result[i] == result[i + 1]:
			result[i + 1] = consonants_normal[randi_range(0, 42)]
	if result[0] == 'x':
		result[0] = consonants_common[randi_range(0, 42)]
	var rnd = randi() % 290
	if result[ENEMY_COLUMN_COUNT - 2] == 'c':
		if rnd <= 100:
			result[ENEMY_COLUMN_COUNT - 1] = 'k'
		elif rnd <= 200:
			result[ENEMY_COLUMN_COUNT - 3] = 't'
			result[ENEMY_COLUMN_COUNT - 1] = 'h'
	elif result[ENEMY_COLUMN_COUNT - 1] == 'k':
		if rnd <= 100:
			result[ENEMY_COLUMN_COUNT - 2] = 'c'
		elif rnd <= 180:
			result[ENEMY_COLUMN_COUNT - 2] = 'n'
		elif rnd <= 240:
			result[ENEMY_COLUMN_COUNT - 2] = 'r'
	elif result[ENEMY_COLUMN_COUNT - 1] == 'l' and rnd < 200:
		result[ENEMY_COLUMN_COUNT - 2] == 'l'
	elif result[ENEMY_COLUMN_COUNT - 1] == 'f' and rnd < 180:
		result[ENEMY_COLUMN_COUNT - 2] == 'f'
	elif result[ENEMY_COLUMN_COUNT - 1] == 's' and rnd < 160:
		result[ENEMY_COLUMN_COUNT - 2] == 's'
	elif result[ENEMY_COLUMN_COUNT - 2] == 'k':
		result[ENEMY_COLUMN_COUNT - 3] = 'c'
	
	var qpos = result.find('q')
	if qpos >= 0 and qpos < (ENEMY_COLUMN_COUNT - 1):
		result[qpos + 1] = 'u'
	if check_for_words(result).match_found:
		return "snert"
	return result

func shift_row(row, column, factor = 1):
	is_shifting = true
	var enemies = enemy_list.get_children()
	for enemy in enemies:
		if enemy.column == column and enemy.row < row:
			enemy.move_down(factor)

func remove_entire_row():
	is_shifting = true
	var stored_letters = enemy_grid[ENEMY_ROW_COUNT - 1] + '|'
	enemy_grid[ENEMY_ROW_COUNT - 1] = "*****"
	var enemies = enemy_list.get_children()
	for enemy in enemies:
		if enemy.row < ENEMY_ROW_COUNT - 1:
			enemy.move_down(1)
		else:
			enemy.erase_remove()

func create_new_blocks():
	for i in enemy_grid:
		for j in range(ENEMY_COLUMN_COUNT):
			if enemy_grid[i][j] == '-':
				var new_letter = 's'
				if j == 3:
					new_letter = consonants_column_4[randi_range(0, 42)]
				elif j == 4:
					new_letter = consonants_column_5[randi_range(0, 42)]
				else:
					var k = letter_templates[letter_template_index]
					if k == 'c':
						new_letter = consonants_common[randi_range(0, 42)]
					elif k == 'n':
						new_letter = consonants_normal[randi_range(0, 42)]
					else:
						new_letter = consonants_rare[randi_range(0, 42)]
				var new_enemy = enemy.instantiate()
				new_enemy.position = Vector2(150 + (j * 100), i * ROW_SEPERATION)
				new_enemy.row = i
				new_enemy.column = j
				new_enemy.get_node("Sprite/Label").text = new_letter
				new_enemy.original_letter = new_letter
				enemy_list.add_child(new_enemy)
				enemy_grid[i][j] = new_letter
				letter_template_index = (letter_template_index + 1) % 3

func check_for_words(text_to_check : String):
	var found_info = {"match_found": false, "index": 0, "length": 5, "word": ""}
	for word in words_5:
		if text_to_check == word:
			found_info.match_found = true
			found_info.word = word
			return found_info
	for word in words_4:
		var index = text_to_check.find(word)
		if index >= 0:
			found_info.match_found = true
			if index == 0 && text_to_check[ENEMY_COLUMN_COUNT - 1] == 's' && text_to_check[ENEMY_COLUMN_COUNT - 2] != 's':
				return {"match_found": true, "index": 0, "length": 5, "word": word + 's'}
			found_info.index = index
			found_info.length = 4
			found_info.word = word
	if found_info.match_found:
		return found_info
	for word in words_3:
		var index = text_to_check.find(word)
		if index >= 0:
			found_info.match_found = true
			if index == 0 && text_to_check[ENEMY_COLUMN_COUNT - 2] == 's' && text_to_check[ENEMY_COLUMN_COUNT - 3] != 's':
				return {"match_found": true, "index": 0, "length": 4, "word": word + 's'}
			if index == 1 && text_to_check[ENEMY_COLUMN_COUNT - 1] == 's' && text_to_check[ENEMY_COLUMN_COUNT - 2] != 's':
				return {"match_found": true, "index": 1, "length": 4, "word": word + 's'}
			found_info.index = index
			found_info.length = 3
			found_info.word = word
	return found_info

func check_for_matches(is_recursive = false):
	var i = ENEMY_ROW_COUNT - 1
	var result_for_row = check_for_words(enemy_grid[i])
	if result_for_row.match_found:
		delay = MAX_DELAY
		letters_before_wildcard -= 1
		for j in range(result_for_row.length):
			enemy_grid[i][result_for_row.index + j] = "*"
		var enemies = enemy_list.get_children()
		for enemy in enemies:
			if enemy.row == i and enemy.column >= result_for_row.index and enemy.column < result_for_row.index + result_for_row.length:
				enemy.match_remove(result_for_row.index, result_for_row.length)
				rows_to_shift.push_front(Vector2(enemy.row, enemy.column))
				match_made = true
				match_shift = false
				brazier_timer = result_for_row.length
				score += bonus_values[result_for_row.length]
				last_word = result_for_row.word.capitalize()
	if not is_shifting:
		create_new_blocks()
		add_letter_to_player()
		if !match_made:
			can_shoot = true
			if !is_recursive:
				$sfx_no_match.play()
				if is_tutorial and tutorial_step == 1:
					set_tutorial_step(2)
			elif is_tutorial and tutorial_step == 1:
				set_tutorial_step(2)
			elif tutorial_step == 2:
				set_tutorial_step(3)
			elif tutorial_step == 3:
				set_tutorial_step(4)
			elif tutorial_step == 7:
				set_tutorial_step(8)
			elif tutorial_step == 8:
				set_tutorial_step(9)

func set_tutorial_step(step):
	var tutorial_text = $CanvasLayer/Tutorial/Label
	tutorial_step = step
	if step == 2:
		tutorial_text.text = "Create words to remove mailboxes and score points."
	elif step == 3:
		tutorial_text.text = "Longer words score more points!"
	elif step == 4:
		tutorial_text.text = "Click the right mouse button to destroy an entire row.\nThis is useful when a row contains a lot of bad letters."
	elif step == 5:
		tutorial_text.text = "This will also drop the letters from the mailboxes, which you can pick up."
		next_letter = '?'
	elif step == 6:
		tutorial_text.text = "When a ? appears, you must select a letter yourself using the keys on your keyboard."
	elif step == 7:
		tutorial_text.text = "Outside of this tutorial, the mailboxes will creep towards you. If they come too close, it's game over."
	elif step == 8:
		tutorial_text.text = "Outside of this tutorial, the mailboxes will creep towards you. If they come too close, it's game over."
	elif step == 9:
		tutorial_text.text = "You may keep practicing until you've got the hang of it.\nPress ENTER to start the game."
		tutorial_complete = true
		JavaScriptBridge.eval("localStorage.setItem('dlis_tutorial_complete', true)")

func get_highscores():
	var sw_result: Dictionary = await SilentWolf.Scores.get_scores().sw_get_scores_complete
	var i = 1
	for score in sw_result.scores:
		if i > 5:
			break
		var position = Vector2(20, 175 + (40 * i))
		var new_record = highscore_obj.instantiate()
		new_record.get_node("Position").text = str(i) + '.'
		new_record.get_node("Name").text = score.player_name
		new_record.get_node("Score").text = str(int(score.score))
		new_record.position = position
		$CanvasLayer/Game_Over.add_child(new_record)
		i += 1
