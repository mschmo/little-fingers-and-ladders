extends Control

const MIN_DICE_ROLL: int = 1
const MAX_DICE_ROLL: int = 7
const BOARD_SIZE: int = 67
# Neither finger nor ladder
const IS_NEUTRAL_CHANCE: float = 0.6
# scales to 100% as nearing end of board
const BASE_FINGER_CHANCE: float = 0.5

enum SPACE_TYPES {
	NEUTRAL,
	FINGER,
	LADDER,
	WIN
}
enum GameStates {
	READY,
	LADDER_PROMPT,
	FOUND_ITEM
	COMBAT,
	SHOP,
	WIN
}

# TODO: Hard-coded board for initial game jam. Should be generated dynamically
# also to-do, calculate steps-forward and back mathematically
const BOARD = [
	# Row 1
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 4, 'spaces_forward': 34},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 2, 'spaces_forward': 22},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 4, 'spaces_forward': 34},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 2, 'spaces_forward': 8},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	
	{'type': SPACE_TYPES.NEUTRAL},  # stairss
	# Row 2
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 4},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 4, 'spaces_forward': 34},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 20},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	
	{'type': SPACE_TYPES.NEUTRAL},  # stairs
	# Row 3
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 2, 'spaces_forward': 30},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 10},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 20},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.LADDER, 'steps': 2, 'spaces_forward': 6},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},

	{'type': SPACE_TYPES.NEUTRAL},  # stairs
	# Row 4
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 8},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 16},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.FINGER, 'spaces_back': 28},
	{'type': SPACE_TYPES.NEUTRAL},
	{'type': SPACE_TYPES.WIN},
]

var rng = RandomNumberGenerator.new()
var board: Array = []
var _player_position: int = 0
var _current_dice_roll: int = 0
var _show_prompt: bool = false
# Figure out better way to set state (state machine?)
var _ladder_prompt = false
var _state = {'id': GameStates.READY}

onready var _roll_display = $UIZone/DiceZone/RollDisplay;
onready var _progress_text = $UIZone/InfoZone/ProgressText;
onready var _spot_detail_text = $UIZone/InfoZone/SpotDetailText;
onready var _prompt_message = $UIZone/PromptZone/PromptMessage;
onready var _player = $Player;



func _ready():
	rng.randomize()
	
	# Generate the board
	# Hard-coding the board for MVP
#	for position in range(BOARD_SIZE):
#		var is_neutral: bool = rng.randf() > (1 - IS_NEUTRAL_CHANCE)
#		if is_neutral:
#			board.append({'type': SPACE_TYPES.NEUTRAL})
#			continue
#		var position_progress: float = float(position) / BOARD_SIZE
#		var is_finger = rng.randf() > (1 - (BASE_FINGER_CHANCE * (1 + position_progress)))
#		if is_finger:
#			board.append({'type': SPACE_TYPES.FINGER})
#		else:
#			board.append({'type': SPACE_TYPES.LADDER})
	board = BOARD


func _input(event):
	if event is InputEventKey and event.pressed:
		if _player.tween.is_active():
			print('Player is currently moving. Ignoring input.')  # hmmm dumb?
			return
		
		var state_id = _state['id']
		if state_id == GameStates.READY:
			if event.scancode == KEY_A:
				roll_dice()

		elif state_id == GameStates.LADDER_PROMPT:
			if event.scancode == KEY_A:
				_player.climb_ladder(_state['steps'])
				_player_position += _state['spaces_forward']
				if _state['steps'] == 2:
					_player.flop_direction()
				_progress_text.text = 'Progress: %s / %s' % [_player_position + 1, BOARD_SIZE]
				_set_state_ready()
				# How to get new position???
			elif event.scancode == KEY_X:
				_set_state_ready()

		elif state_id == GameStates.COMBAT:
			# TODO: Use actual jrpg cutscene
			if event.scancode == KEY_A:
				_prompt_message.text = 'You are too weak. The finger will eat you. Press "X" to flee.'
			elif event.scancode == KEY_X:
				_player.move_tween(Vector2.DOWN, 2)
				# Always flop at moment since all fingers is down a single level
				_player.flop_direction()
				_player_position -= _state['spaces_back']
				_progress_text.text = 'Progress: %s / %s' % [_player_position + 1, BOARD_SIZE]
				_set_state_ready()


# Change to when "A" is pressed
func roll_dice() -> void:
	_current_dice_roll = rng.randf_range(MIN_DICE_ROLL, MAX_DICE_ROLL)
	_player_position += _current_dice_roll
	if _player_position >= BOARD_SIZE:
		_prompt_message.text = 'Hey cool, I think you just won.'
		_player.win_position()
		return
		
	_roll_display.text = "%d" % _current_dice_roll
	var progress_pct = (float(_player_position) / BOARD_SIZE) * 100
	_progress_text.text = 'Progress: %s / %s' % [_player_position + 1, BOARD_SIZE]
	
	# Move player
	_player.move(_current_dice_roll)

	# Space details
	var space = board[_player_position]
	var space_type = space.get('type', SPACE_TYPES.NEUTRAL)
	if space_type == SPACE_TYPES.NEUTRAL:
		_spot_detail_text.text = 'Spot Type: Neutral'
		_set_state_ready()
	elif space_type == SPACE_TYPES.FINGER:
		_spot_detail_text.text = 'Spot Type: Finger'
		_prompt_message.text = 'Oh darn, a finger. Press "A" to fight it, or "X" to flee away.'
		_state = {
			'id': GameStates.COMBAT,
			'spaces_back': space.get('spaces_back')
		}
	elif space_type == SPACE_TYPES.LADDER:
		_spot_detail_text.text = 'Spot Type: Ladder'
		_prompt_message.text = 'Do you want to take the ladder? Press "A" for yes and "X" for no'
		_state = {
			'id': GameStates.LADDER_PROMPT,
			'steps': space.get('steps'),
			'spaces_forward': space.get('spaces_forward'),
		}
	elif space_type == SPACE_TYPES.WIN:
		# TODO: Actually just gonna use player position to determine this for time being
		_spot_detail_text.text = 'Spot type: Win'
	else:
		_spot_detail_text.text = 'Please inform the devs that there is a bug.'


func _set_state_ready():
	_prompt_message.text = 'Press "A" to roll the dice'
	_state = {'id': GameStates.READY}
