class_name FighterRoster
extends RefCounted

const CSM_IDS := ["cr", "lady_don", "shiva_fighter", "fighter_51", "fighter_52", "fighter_53", "second_cr", "arabian_horse"]
const OPPOSITE_IDS := ["swapna_taker", "coa", "chubby_cheeks", "cheshma_girl"]

const CHARACTERS: Array[Dictionary] = [
	{"id":"cr", "name":"CR", "team":"CSM GANG", "team_key":"csm", "role":"Class representative", "signature":"Chairman's Order", "color":"#43E9FF", "secondary":"#197FBB", "avatar":"res://assets/game/characters/fighter_01.png", "blurb":"Every round begins with roll call.", "quips":{"start":["Orey, internal exam anukunnava?", "First attendance veyyi ra!"], "punch":["Side ivvu ra babu!", "Present, sir!"], "kick":["Homework submit chey ra!"], "special":["Chairman's Order!", "Dheenamma, mass entry!"], "low":["Ayyayyo, debba padindhi!"], "win":["Naa range veru ra!", "Pass avvadam kuda oka art ra!"], "loss":["Friendship cancelled ra!"]}},
	{"id":"lady_don", "name":"Lady Don", "team":"CSM GANG", "team_key":"csm", "role":"Campus queenpin", "signature":"Don's Fury", "color":"#FF4EB5", "secondary":"#9A337C", "avatar":"res://assets/game/characters/fighter_02.png", "blurb":"She runs this campus—and the rematch.", "quips":{"start":["Ready aa, mass entry ki?"], "punch":["Line lo nilchuko!"], "kick":["Rules nene raastha!"], "special":["Don's Fury!", "Chusava naa style?"], "low":["Ayyayyo, konchem aagu!"], "win":["Campus motham naa side!"], "loss":["Rematch compulsory ra!"]}},
	{"id":"shiva_fighter", "name":"Shiva Fighter", "team":"CSM GANG", "team_key":"csm", "role":"Calm training ace", "signature":"Shiva Strike", "color":"#70B8FF", "secondary":"#4056A4", "avatar":"res://assets/game/characters/fighter_03.png", "blurb":"Quiet in class. Thunder in the arena.", "quips":{"start":["Calm ga start cheddama?"], "punch":["Light ga teesko!"], "kick":["Attendance laga pakka!"], "special":["Shiva Strike!", "Dheenamma, mass entry!"], "low":["Oho, baaga tagilindhi!"], "win":["Naa range veru ra!"], "loss":["Next time full practice!" ]}},
	{"id":"fighter_51", "name":"51", "team":"CSM GANG", "team_key":"csm", "role":"Lightning fast", "signature":"Fifty-One Blast", "color":"#AA79FF", "secondary":"#6350C6", "avatar":"res://assets/game/characters/fighter_04.png", "blurb":"Always one step ahead of the syllabus.", "quips":{"start":["51 ready, nuvvu ready aa?"], "punch":["Fast ga ayipoyindhi!"], "kick":["Side ivvu ra babu!"], "special":["Fifty-One Blast!"], "low":["Health kuda 51 ki vachindi!"], "win":["Easy pass ra!"], "loss":["Supplementary round ivvu!"]}},
	{"id":"fighter_52", "name":"52", "team":"CSM GANG", "team_key":"csm", "role":"Built like a deadline", "signature":"Fifty-Two Smash", "color":"#A6F05A", "secondary":"#54854A", "avatar":"res://assets/game/characters/fighter_05.png", "blurb":"Thinks best when snacks are involved.", "quips":{"start":["Snack break tarvata fight!"], "punch":["Ayy, sorry ra!"], "kick":["Dheenamma, padipo!"], "special":["Fifty-Two Smash!"], "low":["Cheeks kadu, HP taggindhi!"], "win":["Tiffin time, victory time!"], "loss":["Snacks levu, energy ledu!"]}},
		{"id":"fighter_53", "name":"53", "team":"CSM GANG", "team_key":"csm", "role":"Deadline sprinter", "signature":"Fifty-Three Explosion", "color":"#FFAF45", "secondary":"#C45E2A", "avatar":"res://assets/game/characters/fighter_06.png", "blurb":"The last-minute submission specialist.", "quips":{"start":["Deadline mundu win kavali!"], "punch":["Submit ayipoyindhi!"], "kick":["Fast forward ra!"], "special":["Fifty-Three Explosion!"], "low":["HP ki extension unda?"], "win":["Last minute lo pass!"], "loss":["Re-submit chestha ra!"]}},
		{"id":"second_cr", "name":"2nd CR", "team":"CSM GANG", "team_key":"csm", "role":"Deputy captain", "signature":"Second Command", "color":"#4EDFC5", "secondary":"#347F98", "avatar":"res://assets/game/characters/fighter_07.png", "blurb":"Has the attendance sheet and a backup plan.", "quips":{"start":["First CR lekapothe nenu!"], "punch":["Order follow avvu!"], "kick":["Proxy attendance ledu!"], "special":["Second Command!"], "low":["Backup plan activate cheyyi!"], "win":["Deputy nunchi champion!"], "loss":["Minutes of meeting raastha!"]}},
		{"id":"arabian_horse", "name":"Arabian Horse", "team":"CSM GANG", "team_key":"csm", "role":"Campus mascot", "signature":"Arabian Charge", "color":"#7EE7E3", "secondary":"#297F92", "avatar":"res://assets/game/characters/arabian_horse.png", "blurb":"A friendly horse-mascot with unstoppable momentum.", "quips":{"start":["Gurram ready, whistle veyyi!"], "punch":["Neigh—nice try!"], "kick":["Hooves mundu, assignments venaka!"], "special":["Arabian Charge!"], "low":["Water break please!"], "win":["Campus track naade!"], "loss":["Slow lap tarvata rematch!"]}},
		{"id":"swapna_taker", "name":"Swapna Taker", "team":"OPPOSITE GANG", "team_key":"opposite", "role":"Dreamy trickster", "signature":"Dream Breaker", "color":"#C893FF", "secondary":"#684BB0", "avatar":"res://assets/game/characters/fighter_09.png", "blurb":"Turns your best combo into a daydream.", "quips":{"start":["Swapna lo kuda nenu gelustha!"], "punch":["Dream lo hit ayindhi!"], "kick":["Wake up ra!"], "special":["Dream Breaker!"], "low":["Naa dream konchem blur ayindhi!"], "win":["Dream come true!"], "loss":["Just a bad dream ra!"]}},
	{"id":"coa", "name":"COA", "team":"OPPOSITE GANG", "team_key":"opposite", "role":"Architecture ace", "signature":"Architecture Attack", "color":"#56A7FF", "secondary":"#3659B9", "avatar":"res://assets/game/characters/fighter_10.png", "blurb":"Every move is measured to the millimetre.", "quips":{"start":["Plan ready. Defence ready."], "punch":["Design lo flaw undhi!"], "kick":["Scale perfect!"], "special":["Architecture Attack!"], "low":["Structure konchem weak ayindhi!"], "win":["Built to win!"], "loss":["Revised drawing tho vastha!"]}},
	{"id":"chubby_cheeks", "name":"Chubby Cheeks", "team":"OPPOSITE GANG", "team_key":"opposite", "role":"Snack-powered tank", "signature":"Cheek Blast", "color":"#FF9A75", "secondary":"#C94D69", "avatar":"res://assets/game/characters/fighter_11.png", "blurb":"Big grin. Bigger bounce-back.", "quips":{"start":["Cheeks ready. Punches ready."], "punch":["Boop!"], "kick":["Side ivvu ra babu!"], "special":["Cheek Blast!"], "low":["Ayyayyo, debba padindhi!"], "win":["Big cheeks, big win!"], "loss":["Friendship cancelled ra!"]}},
	{"id":"cheshma_girl", "name":"Cheshma Girl", "team":"OPPOSITE GANG", "team_key":"opposite", "role":"Laser-vision scientist", "signature":"Laser Vision", "color":"#9A8BFF", "secondary":"#4C59AB", "avatar":"res://assets/game/characters/fighter_12.png", "blurb":"Spots openings before the professor spots late slips.", "quips":{"start":["Focus sharp ga undhi!"], "punch":["Target lock!"], "kick":["Clear vision, clean hit!"], "special":["Laser Vision!"], "low":["Specs fog ayyay!"], "win":["Naa range crystal clear!"], "loss":["Lens adjust chesi vastha!"]}}
]

static func all_characters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fighter: Dictionary in CHARACTERS:
		result.append(fighter.duplicate(true))
	return result


static func team_ids(team_key: String) -> Array:
	return CSM_IDS.duplicate() if team_key == "csm" else OPPOSITE_IDS.duplicate()


static func fighter_by_id(fighter_id: String) -> Dictionary:
	for fighter: Dictionary in CHARACTERS:
		if str(fighter.id) == fighter_id:
			return fighter.duplicate(true)
	return {}


static func name_for_id(fighter_id: String) -> String:
	return str(fighter_by_id(fighter_id).get("name", "Fighter"))
