extends RefCounted
class_name BigNumRef
## A class that holds a number that can be larger or smaller than the floating point limit.
##
## A [RefCounted] that stores a single number that uses 3 values (Sign, Layer, Magnitude) to represent it. [br]
## 
## In addition, this library supports operations with the bare 3 values, in Dictionary form, as following: [br]
## [codeblock]
## {
##     "sign": int
##     "layer": float
##     "mag": float
## }
## [/codeblock]
## For more information, see [url]https://github.com/Patashu/break_eternity.js[/url][br]
## [b]Note:[/b] All static/singleton methods on this class that returns a Dictionary, excluding [method normalize_n],
## do not mutate the old Dictionaries.

# signals
signal n_changed()

# constants
const MAX_FLOAT_PRECISION = 17
const LAYER_UP: float = 9.0e15
const LAYER_DOWN = 15.954242509439325 #log(9e15)/log(10) # Godot doesn't support log10() or log2()
const FIRST_NEG_LAYER: float = 1 / 9.0e15
# floor(log(2^1023 * (1 + (1 - 2^-52)))/log(10))
const NUMBER_EXP_MAX = 308

const NUMBER_EXP_MIN = -324
## Lambert W(1,0). Also known as Omega Constant.
const LAMBERTW_ONE_ZERO = 0.56714329040978387299997

const CRITICAL_HEADERS = [2.0, exp(1), 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

const CRITICAL_TETR_VALUES = [[
	# Base 2 (using http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html )
	1.0, 1.0891180521811202527, 1.1789767925673958433, 1.2701455431742086633, 1.3632090180450091941, 1.4587818160364217007, 1.5575237916251418333, 1.6601571006859253673, 1.7674858188369780435, 1.8804192098842727359, 2.0], [
	# Base E (using http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html )
	1.0, 1.1121114330934078681, 1.2310389249316089299, 1.3583836963111376089, 1.4960519303993531879, 1.6463542337511945810, 1.8121385357018724464, 1.9969713246183068478, 2.2053895545527544330, 2.4432574483385252544, exp(1)
	], [
	# Base 3
	1.0, 1.1187738849693603, 1.2464963939368214, 1.38527004705667, 1.5376664685821402, 1.7068895236551784, 1.897001227148399, 2.1132403089001035, 2.362480153784171, 2.6539010333870774, 3.0], [
	# Base 4
	1.0, 1.1367350847096405, 1.2889510672956703, 1.4606478703324786, 1.6570295196661111, 1.8850062585672889, 2.1539465047453485, 2.476829779693097, 2.872061932789197, 3.3664204535587183, 4.0], [
	# Base 5
	1.0, 1.1494592900767588, 1.319708228183931, 1.5166291280087583, 1.748171114438024, 2.0253263297298045, 2.3636668498288547, 2.7858359149579424, 3.3257226212448145, 4.035730287722532, 5.0], [
	# Base 6
	1.0, 1.159225940787673, 1.343712473580932, 1.5611293155111927, 1.8221199554561318, 2.14183924486326, 2.542468319282638, 3.0574682501653316, 3.7390572020926873, 4.6719550537360774, 6.0], [
	# Base 7
	1.0, 1.1670905356972596, 1.3632807444991446, 1.5979222279405536, 1.8842640123816674, 2.2416069644878687, 2.69893426559423, 3.3012632110403577, 4.121250340630164, 5.281493033448316, 7.0], [
	# Base 8
	1.0, 1.1736630594087796, 1.379783782386201, 1.6292821855668218, 1.9378971836180754, 2.3289975651071977, 2.8384347394720835, 3.5232708454565906, 4.478242031114584, 5.868592169644505, 8.0], [
	# Base 9
	1.0, 1.1793017514670474, 1.394054150657457, 1.65664127441059, 1.985170999970283, 2.4069682290577457, 2.9647310119960752, 3.7278665320924946, 4.814462547283592, 6.436522247411611, 9.0], [
	# Base 10 (using http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html )
	1.0, 1.1840100246247336579, 1.4061375836156954169, 1.6802272208863963918, 2.026757028388618927, 2.4770056063449647580, 3.0805252717554819987, 3.9191964192627283911, 5.1351528408331864230, 6.9899611795347148455, 10.0]]

const CRITICAL_SLOG_VALUES = [[
  # Base 2
  -1.0, -0.9194161097107025, -0.8335625019330468, -0.7425599821143978, -0.6466611521029437, -0.5462617907227869, -0.4419033816638769, -0.3342645487554494, -0.224140440909962, -0.11241087890006762, 0.0], [
  # Base E
  -1.0, -0.90603157029014, -0.80786507256596, -0.7064666939634, -0.60294836853664, -0.49849837513117, -0.39430303318768, -0.29147201034755, -0.19097820800866, -0.09361896280296, 0.0 # 1.0
  ], [
  # Base 3
  -1.0, -0.9021579584316141, -0.8005762598234203, -0.6964780623319391, -0.5911906810998454, -0.486050182576545, -0.3823089430815083, -0.28106046722897615, -0.1831906535795894, -0.08935809204418144, 0.0], [
  # Base 4
  -1.0, -0.8917227442365535, -0.781258746326964, -0.6705130326902455, -0.5612813129406509, -0.4551067709033134, -0.35319256652135966, -0.2563741554088552, -0.1651412821106526, -0.0796919581982668, 0.0], [
  # Base 5
  -1.0, -0.8843387974366064, -0.7678744063886243, -0.6529563724510552, -0.5415870994657841, -0.4352842206588936, -0.33504449124791424, -0.24138853420685147, -0.15445285440944467, -0.07409659641336663, 0.0], [
  # Base 6
  -1.0, -0.8786709358426346, -0.7577735191184886, -0.6399546189952064, -0.527284921869926, -0.4211627631006314, -0.3223479611761232, -0.23107655627789858, -0.1472057700818259, -0.07035171210706326, 0.0], [
  # Base 7
  -1.0, -0.8740862815291583, -0.7497032990976209, -0.6297119746181752, -0.5161838335958787, -0.41036238255751956, -0.31277212146489963, -0.2233976621705518, -0.1418697367979619, -0.06762117662323441, 0.0], [
  # Base 8
  -1.0, -0.8702632331800649, -0.7430366914122081, -0.6213373075161548, -0.5072025698095242, -0.40171437727184167, -0.30517930701410456, -0.21736343968190863, -0.137710238299109, -0.06550774483471955, 0.0], [
  # Base 9
  -1.0, -0.8670016295947213, -0.7373984232432306, -0.6143173985094293, -0.49973884395492807, -0.394584953527678, -0.2989649949848695, -0.21245647317021688, -0.13434688362382652, -0.0638072667348083, 0.0], [
  # Base 10
  -1.0, -0.8641642839543857, -0.732534623168535, -0.6083127477059322, -0.4934049257184696, -0.3885773075899922, -0.29376029055315767, -0.2083678561173622, -0.13155653399373268, -0.062401588652553186, 0.0]
]
## Zero.
const BIGNUM_ZERO = {
	"sign" : 0,
	"layer" : 0.0,
	"mag" : 0.0
}
## One.
const BIGNUM_ONE = {
	"sign" : 1,
	"layer" : 0.0,
	"mag": 1.0
}
## Negative one.
const BIGNUM_NEG_ONE = {
	"sign" : -1,
	"layer" : 0.0,
	"mag": 1.0
}
## Invalid number.
const BIGNUM_NAN = {
	"sign": 0,
	"layer": NAN,
	"mag": NAN
}
## Lookup table for powers of 10.[br]
## [b]Note:[/b] This should be treated as a constant.
static var powers_of_ten: Array[float]:
	get:
		var value: Array[float] = []
		for i in range((NUMBER_EXP_MIN + 1), (NUMBER_EXP_MAX + 1)):
			value.push_back("1e{exp}".format({"exp": i}).to_float())
		return value

# static variables
## Maximum amount of exponent symbols that [method g_to_str] is allowed to write.
static var max_es_in_str: int = 5
## Maximum amount of iterations for LambertW functions.
static var max_i_lambertw: int = 100
## Maximum amount of iterations for [method g_tetrate].
static var max_i_tetra: int = 10000
## Maximum amount of iterations for [method g_pentate].
static var max_i_penta: int = 10
## Maximum amount of iterations for miscellaneous functions.
static var max_i_other: int = 100
## Default round to that [method g_to_str] will use.
static var default_round_to: int = 2
# static functions
static func power_of_ten(e: int) -> float:
	return powers_of_ten[(e - NUMBER_EXP_MIN - 1)]

# from https://math.stackexchange.com/a/465183
# Please don't change the tolerance unless you know what you're doing
## Returns the solution of [code]W(x) = x * (e ^ x)[/code]. 
## [url]https://en.wikipedia.org/wiki/Lambert_W_function[/url]
## [br]This is a multi-valued function in the complex plane, but only two branches matter for real numbers: the "principal branch" W0, and the "non-principal branch" W-1.
static func f_lambertw(z: float, principal: bool = true, tolerance: float = 1e-10) -> float:
	var w: float
	var wn: float
	if principal:
		if !is_finite(z) or z == 0:
			return z
		if z == 1:
			return LAMBERTW_ONE_ZERO

		if (z < 10):
			w = 0
		else:
			w = log(z) - log(log(z))
	else:
		if z == 0:
			return -INF
		if z <= -0.1:
			w = -2
		else:
			w = log(z) - log(-log(-z))
	for i in range(max_i_lambertw):
		wn = (z * exp(-w) + w * w) / (w + 1)
		if absf(wn - w) < tolerance * absf(wn):
			return wn
		else:
			w = wn
		
	assert(false, "f_lambertw: Number {num} failed to converge after {i} iterations".format({
		"num": z,
		"i": max_i_lambertw
	}))
	return NAN


## Normalizes [param n].[br] 
## This is done in-place. If you want to make another normalized number Dictionary, use [method duplicate_num_only]. [br]
## Does the following stuff:[br]
## - If sign is 0 or (mag and layer is 0), makes all of them 0.[br]
## - If layer is 0 and mag < [constant FIRST_NEG_LAYER] (1/9e15), shifts to first negative layer.[br]
## - increases the layer and lowers the mag (log10(mag)) if mag is above threshold (9e15)
## or lowers the layer and raises the mag (10^mag) if mag is below the layer threshold (15.954).[br]
## [b]Note:[/b] Users of this library should not need to use this function.
static func normalize_n(n: Dictionary) -> void:

	# Make all partial 0s full 0s
	if n.sign == 0 or (n.mag == 0 and n.layer == 0) or (n.mag == INF and 0 > n.layer and n.layer > -INF):
		n.sign = 0
		n.mag = 0.0
		n.layer = 0.0
		return

	n.layer = floorf(n.layer)
	# Extract sign from negative mag at layer 0
	if n.layer == 0 and n.mag < 0:
		n.mag = -n.mag
		n.sign = -n.sign

	# Handle infinities
	if absf(n.layer) == INF or absf(n.mag) == INF:
		n.mag = INF
		n.layer = INF

	# Shift from layer 0 to negative layers
	if n.layer == 0 and n.mag < FIRST_NEG_LAYER:
		n.layer += 1
		n.mag = log(n.mag)/log(10)
		return

	var absmag := absf(n.mag)
	var signmag := signf(n.mag)
	if absmag >= LAYER_UP:
		n.layer += 1
		n.mag = signmag * log(absmag)/log(10)
	else:
		while absmag < LAYER_DOWN and n.layer > 0:
			n.layer -= -1
			if n.layer == 0:
				n.mag = pow(10, n.mag)
			else:
				n.mag = signmag * pow(10, absmag)
				absmag = absf(n.mag)
				signmag = signf(n.mag)
		if n.layer == 0:
			if n.mag < 0:
				n.mag = -n.mag
				n.sign = -n.sign
			elif n.mag == 0:
				push_warning("Magnitude may have been excessively rounded. Your number has been normalized to 0. Sorry!")
				n.sign = 0
	# Handle NANs
	if is_nan(n.layer) or is_nan(n.mag):
	
		n.sign = 0
		n.layer = NAN
		n.mag = NAN



## A randomized number struct for testing purposes. Does not have proper random distribution.
static func testable_random_num_struct(max_layer: float = 2.0 ** 1023.0) -> Dictionary:
	var v: Dictionary = {
			"sign": 0,
			"layer": 0.0,
			"mag": 0.0
		}
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()

	# WEIGHTS: 5% 0, 2.5% each for 1 or -1;
	# Otherwise, pick a random layer, 
	# then 10% to make it a simple power of 10
	# then 10% to trunc the mag

	var roll1 := random.randf()

	if roll1 <= 0.05:
		return v # 0

	if roll1 <= 0.1:
		v.mag = 1.0
		v.sign = 1
		if roll1 <= 0.075:
			v.sign = -1
		return v # -1, 1
	v.layer = random.rand_range(0, max_layer + 1)

	var roll2 := random.randf()
	var random_exp :float
	if v.layer == 0:
		random_exp = random.randf() * 616 - 308
	else:
		random_exp = random.randf() * 16
	if roll2 <= 0.1:
		random_exp = floorf(random_exp)
	v.mag = pow(10, random_exp)
	var roll3 := random.randf()
	if roll3 <= 0.1:
		v.mag = floorf(v.mag)
	return v

## Converts the number back to a [float].
## This may return 0 or [constant INF] since floats cannot support numbers as large as numbers of this library.
static func to_float(n: Dictionary) -> float:
	if is_nan(n.layer):
		return NAN
	if not is_finite(n.mag):
		return n.mag
	if n.layer == 0:
		return n.sign * n.mag
	if n.layer == 1:
		return n.sign * (10 ** n.mag)
	if n.mag > 0: # Should be overflowing for normalized numbers
		return INF * n.sign
	return 0

## Creates a new normalized number from the given components.
static func from_components(num_sign: int, layer: float, mag: float) -> Dictionary:
	var v: Dictionary = from_components_no_normalize(num_sign, layer, mag)
	
	normalize_n(v)
	
	return v

## Creates a new number from the given components.
static func from_components_no_normalize(num_sign: int, layer: float, mag: float) -> Dictionary:
	return {
		"sign": num_sign,
		"layer": layer,
		"mag": mag
	}

## Creates a new normalized number from the given [float].[br]
## [b]Note:[/b] Godot should be able to coerce an [int] to a [float].
static func from_float(num: float) -> Dictionary:
	var v: Dictionary = from_float_no_normalize(num)
	
	normalize_n(v)
	
	return v

## Creates a new number from the given [float].[br]
## [b]Note:[/b] Godot should be able to coerce an [int] to a [float].
static func from_float_no_normalize(num: float) -> Dictionary:
	return { "sign": (signf(num) as int), "layer": 0.0, "mag": absf(num) }

## Return a normalized copy of [param n].
static func duplicate_num_only(n: Dictionary) -> Dictionary:
	var v: Dictionary = duplicate_num_only_no_normalize(n)
	
	normalize_n(v)
	
	return v

## Return an exact copy of [param n].
static func duplicate_num_only_no_normalize(n: Dictionary) -> Dictionary:
	return {
		"sign": n.sign,
		"layer": n.layer,
		"mag": n.mag
	}

# Accepted input formats:
# M === M
# eX === 10^X
# MeX === M*10^X
# eXeY === 10^(XeY)
# MeXeY === M*10^(XeY)
# eeX === 10^10^X
# eeXeY === 10^10^(XeY)
# eeeX === 10^10^10^X
# eeeXeY === 10^10^10^(XeY)
# eeee... (N es) X === 10^10^10^ ... (N 10^s) X
# (e^N)X === 10^10^10^ ... (N 10^s) X
# N PT X === 10^10^10^ ... (N 10^s) X
# N PT (X) === 10^10^10^ ... (N 10^s) X
# NpX === 10^10^10^ ... (N 10^s) X
# FN === 10^10^10^ ... (N 10^s)
# XFN === 10^10^10^ ... (N 10^s) X
# X^Y === X^Y
# X^^N === X^X^X^ ... (N X^s) 1
# X^^N;Y === X^X^X^ ... (N X^s) Y
# X^^^N === X^^X^^X^^ ... (N X^^s) 1
# X^^^N;Y === X^^X^^X^^ ... (N X^^s) Y

# number engine @ from_str(): Exponent too high
## Converts a string into the number form.
static func from_str(text: String, linear_hyper: bool = false) -> Dictionary:
	text = text.to_lower()
	# Handle X^^^Y;Z format
	
	if text.get_slice_count("^^^") == 2:
		var base := text.get_slice("^^^", 0).to_float()
		var height := text.get_slice("^^^", 1).to_float()
		var height_parts := text.get_slice("^^^", 1).split(";")
		var payload: float = 1.0
		if len(height_parts) == 2:
			payload = height_parts[1].to_float()
			if not is_finite(payload):
				payload = 1
				if is_finite(base) and is_finite(height):
					return g_pentate(from_float(base), height, from_float(base), true)
	# Handle X^^Y;Z format
	if text.get_slice_count("^^") == 2:
		var tetra_parts := text.split("^^")
		var base := tetra_parts[0].to_float()
		var height_parts := tetra_parts[1].split_floats(";")
		var n_exp := height_parts[0]
		var payload: float = 1
		if len(height_parts) == 2:
			payload = height_parts[1]
			if not is_finite(payload):
				payload = 1
		if is_finite(base) and is_finite(n_exp):
			return g_tetrate(from_float(base), n_exp, from_float(payload), linear_hyper)

	# Handle X ^ Y format.
	# JS's parseFloat() returns NaN if the whole string isn't a valid float. Godot's String.to_float() doesn't do that, so I have to check if the first slice ends at e instead.
	if text.get_slice_count("^") == 2 and (not text.get_slice("^", 0).ends_with("e")):
		var pow_parts := text.split("^")
		var base := pow_parts[0].to_float()
		var n_exp := pow_parts[1].to_float()
		if is_finite(base) and is_finite(n_exp):
			return g_pow(from_float(base), from_float(n_exp))

	# Non ^ bignum notations
	text = text.strip_edges()
	
	# Handle the 10^^X;Y tetras (X PT Y, X P(Y) and X F(Y))
	const BASE10_TETRA_SYMBOLS = ["pt", "p", "f"]
	for s in BASE10_TETRA_SYMBOLS:
		if text.get_slice_count(s) == 2:
			var text2 := text.replace("(", "").replace(")", "")
			var base := from_float(10)
			var base10_tetra_parts := text2.split(s)
			var j: int = 1 if s == "f" else 0 # SORRY
			var k: int = 0 if s == "f" else 1
			var payload := base10_tetra_parts[j].to_float()
			var n_exp := base10_tetra_parts[k].to_float()
			if not is_finite(payload):
				payload = 1
			if is_finite(n_exp):
				return g_tetrate(base, n_exp, from_float(payload), linear_hyper)
	var is_neg := text.begins_with("-")
	# Handle the current (e^x)y format.

	if text.get_slice_count("e^") == 2:
		var current: Dictionary = {
			"sign": -1 if is_neg else 1
		}
		var s2 := text.get_slice("e^", 1)
		for c in s2:
			var c_code := c.unicode_at(0) 
			# character is "0" to "9" or "+" or "-" or "." or "e" (or "," or "/")
			if not((43 <= c_code and c_code <= 57) or c_code == 101):
				# we found the end of the layer count
				print(c)
				var new_parts := s2.split_floats(c)

				current.layer = new_parts[0]
				current.mag = new_parts[1]
				# Handle invalid cases like (e^-8)1 and (e^10.5)1 by just calling tetrate
				if (current.layer < 0) or (not is_zero_approx(fposmod(current.layer, 1))):
					current = g_tetrate(from_float(10), current.layer, from_float(current.mag), linear_hyper)
				normalize_n(current)
				return current
	var ecount: int = text.get_slice_count("e") - 1
	if ecount == 0 or ecount == 1:
		# Very small numbers ("2e-3000" and so on) may look like valid floats but round to 0.
		#ignore_warning: Exponent too high # i know what i'm doing godot, shut up with your runtime errors
		var n := text.to_float()
		# Use is_zero_approx to check if the number is in the subnormal range
		#if is_finite(n) and (not absf(n) > LOWEST_POSITIVE_NORMAL_DOUBLE):
		if is_finite(n) and not is_zero_approx(n):
			return from_float(n)
	var v: Dictionary = from_float(0.0)

	if ecount < 1:
		return from_float(0)
	# Godot can't split a valid but beyond range float to (mantissa, exponent) values
	# with the String.split_floats() method
	var m := text.split("e")[0].to_float()
	if m == 0:
		return from_float(0)
	var n_exp2 := text.split("e")[ecount].to_float()
	# handle numbers like XeYeZ, Xe... (N es) YeZ  
	if ecount >= 2:
		var me := text.split("e")[ecount - 1].to_float()
		if is_finite(me):
			n_exp2 *= signf(me)
			n_exp2 += signf(me) * log(absf(me))/log(10)
	# handle numbers like eee... (N es) X
	if not is_finite(m): 
		if is_neg:
			v.sign = -1
		else:
			v.sign = 1
		v.layer = ecount
		v.mag = n_exp2
	# handle numbers like XeY
	elif ecount == 1:
		v.sign = (signf(m) as int)
		v.layer = 1
		v.mag = n_exp2 + log(absf(m))/log(10)
	# handle numbers like Xe...Y
	elif ecount == 2:
		return g_mul(from_components(1, 2, n_exp2), from_float(m))
	else:
		v.mag = n_exp2
		

	return v

## Tries to create a new number from a [Variant].
static func from_v_no_normalize(arg) -> Dictionary:
	match typeof(arg):
		TYPE_FLOAT, TYPE_INT:
			return from_float_no_normalize(arg)
		TYPE_STRING:
			return from_str(arg)
		TYPE_DICTIONARY:
			return duplicate_num_only_no_normalize(arg)
		TYPE_OBJECT:
			if arg is BigNumRef:
				return arg.d
			push_error("Cannot construct number from object '{arg}'.".format({"arg": arg}))
			return from_float(NAN)
		_:
			push_error("Cannot construct number from parameter '{arg}'.".format({"arg": arg}))
			return from_float(NAN)

## Tries to create a new normalized number from a [Variant].
static func from_v(arg) -> Dictionary:
	var v = from_v_no_normalize(arg)

	normalize_n(v)

	return v

static func g_get_mantissa(n: Dictionary) -> float:
	if n.sign == 0:
		return 0
	if n.layer == 0:
		var e: int = floori(log(n.mag)/log(10))
		if is_equal_approx(5e-324, n.mag):
			return 5 * n.sign
		return n.sign * n.mag / power_of_ten(e)
	if n.layer == 1:
		return n.sign * 10 ** fposmod(n.mag, 1)
	return n.sign

static func g_get_exp(n: Dictionary) -> float:
	if n.sign == 0:
		return 0
	if n.layer == 0:
		return floorf(log(n.mag)/log(10))
	if n.layer == 1:
		return floorf(n.mag)
	if n.layer == 2:
		return n.sign * 10 ** floorf(absf(n.mag))
	return INF

## Returns a string representation of [param n].
static func g_to_str(n: Dictionary) -> String:
	if g_is_nan(n):
		return "NaN"
	if !g_is_finite(n):
		if n.sign == -1:
			return "-Infinity" if n.sign == -1 else "Infinity"
	if n.layer == 0:
		if (1e-7 < n.mag and n.mag < 1e21) or n.mag == 0:
			return var_to_str(n.mag * n.sign)
		return "{m}e{e}".format({"m": g_get_mantissa(n), "e": g_get_exp(n)})
	if n.layer == 1:
		return "{m}e{e}".format({"m": g_get_mantissa(n), "e": g_get_exp(n)})
	if n.layer <= max_es_in_str:
		if n.sign == -1:
			return "-1{l}{e}".format({"e": n.mag, "l": "e".repeat(floori(n.layer))})
		return "1{l}{e}".format({"e": n.mag, "l": "e".repeat(floori(n.layer))})
	if n.sign == -1:
		return "-1(e^{l}){e}".format({"e": n.mag, "l": n.layer})
	return "1(e^{l}){e}".format({"e": n.mag, "l": n.layer})

## Returns a string representation of [param n], with up to [member round_to] decimal digits.
static func g_to_str_to_decimal_places(n: Dictionary, round_to: int = default_round_to) -> String:
	if g_is_nan(n):
		return "NaN"
	if !g_is_finite(n):
		if n.sign == -1:
			return "-Infinity"
		return "Infinity"
	if n.layer == 0:
		if (1e-7 < n.mag and n.mag < 1e21) or n.mag == 0:
			return var_to_str(snappedf((n.mag * n.sign), power_of_ten(-round_to)))
		return "{m}e{e}".format({"m": snappedf(g_get_mantissa(n),power_of_ten(-round_to)), "e": g_get_exp(n)})
	if n.layer == 1:
		return "{m}e{e}".format({"m": snappedf(g_get_mantissa(n),power_of_ten(-round_to)), "e": g_get_exp(n)})
	if n.layer <= max_es_in_str:
		if n.sign == -1:
			return "-1{l}{e}".format({"e": n.mag, "l": "e".repeat(floori(n.layer))})
		return "1{l}{e}".format({"e": n.mag, "l": "e".repeat(floori(n.layer))})
	if n.sign == -1:
		return "-1(e^{l}){e}".format({"e": n.mag, "l": n.layer})
	return "1(e^{l}){e}".format({"e": n.mag, "l": n.layer})

## Returns [code]n1 == n2[/code].
static func g_eq(n1: Dictionary, n2: Dictionary)-> bool:
	return (
		n1.sign == n2.sign and 
		n1.layer == n2.layer and
		n1.mag == n2.mag
	)

## Returns 1 if [param n1] is greater, 0 if equal, -1 if [param n2] is greater.
static func g_compare(n1: Dictionary, n2: Dictionary) -> int:
	if n1.sign != n2.sign:
		return signi(n1.sign - n2.sign)
	return g_compare_abs(n1, n2)

## Returns 1 if [param n1] is greater, 0 if equal, -1 if [param n2] is greater.
static func g_compare_abs(n1: Dictionary, n2: Dictionary) -> int:
	var l_a: float = signf(n1.mag) * n2.layer
	var l_b: float = signf(n2.mag) * n2.layer
	if l_a != l_b:
		return signi(floor(l_a - l_b))
	if n1.mag != n2.mag:
		return signi(n1.mag - n2.mag)
	return 0

## Returns the greater number between two numbers.
static func g_num_max(n1: Dictionary, n2: Dictionary) -> Dictionary:
	if g_compare(n1, n2) == 1:
		return duplicate_num_only(n1)
	return duplicate_num_only(n2)

## Returns the greater number between the absolute value of two numbers.
static func g_num_max_abs(n1: Dictionary, n2: Dictionary) -> Dictionary:
	if g_compare_abs(n1, n2) == 1:
		return duplicate_num_only(n1)
	return duplicate_num_only(n2)

## Returns the lesser number between two numbers.
static func g_num_min(n1: Dictionary, n2: Dictionary) -> Dictionary:
	if g_compare(n1, n2) == -1:
		return duplicate_num_only(n1)
	return n2

## Returns the lesser number between the absolute value of two numbers.
static func g_num_min_abs(n1: Dictionary, n2: Dictionary) -> Dictionary:
	if g_compare_abs(n1, n2) == -1:
		return duplicate_num_only(n1)
	return duplicate_num_only(n2)

## Returns [code]n1 > n2[code].
static func g_gt(n1: Dictionary, n2: Dictionary) -> bool:
	return g_compare(n1, n2) > 0

## Returns [code]n1 >= n2[code].
static func g_gte(n1: Dictionary, n2: Dictionary) -> bool:
	return g_compare(n1, n2) >= 0

## Returns [code]n1 < n2[code].
static func g_lt(n1: Dictionary, n2: Dictionary) -> bool:
	return g_compare(n1, n2) < 0

## Returns [code]n1 <= n2[code].
static func g_lte(n1: Dictionary, n2: Dictionary) -> bool:
	return g_compare(n1, n2) <= 0

## Clamps the value of [param n] between [param n_min] and [n_max].
static func g_clamp(n: Dictionary, n_min: Dictionary, n_max: Dictionary) -> Dictionary:
	return g_num_max(g_num_min(n, n_min), n_max)

static func g_is_nan(n: Dictionary)-> bool:
	return is_nan(n.mag) or is_nan(n.layer)

## Returns whether the number is finite or not (by this library's standards).
static func g_is_finite(n: Dictionary)-> bool:
	return (is_finite(n.mag) or is_finite(n.layer)) and (not g_is_nan(n))

## Returns true if [param n1] and [param n2] are approximately equal to each other.[br]
## [param rel_e] is a relative epsilon, multiplied by the greater of the magnitudes of the two arguments.
static func g_eq_approx(n1: Dictionary, n2: Dictionary, rel_e: float = 1e-7) -> bool:
	# Can't multiply two positive numbers to become a negative number
	if g_is_nan(n1) or g_is_nan(n2):
		return false
	if n1.sign != n2.sign:
		return false
	if abs(n1.layer - n2.layer) > 1:
		return false
	# https://stackoverflow.com/a/33024979
	# return abs(a-b) <= tolerance * max(abs(a), abs(b))
	var mag_a: float = n1.mag
	var mag_b: float = n2.mag
	if n1.layer > n2.layer:
		mag_a = signf(mag_a) * log(absf(mag_a))/log(10)
	elif n2.layer > n1.layer:
		mag_b = signf(mag_b) * log(absf(mag_b))/log(10)
	return absf(mag_a - mag_b) <= rel_e * maxf(absf(mag_a), absf(mag_b))

## Returns 1 if [param n1] is greater, 0 if approximately equal, -1 if [param n2] is greater.[br]
## [param rel_e] is a relative tolerance, multiplied by the greater of the magnitudes of the two arguments.
## See [method g_eq_approx].
static func g_compare_approx(n1: Dictionary, n2: Dictionary, rel_e: float = 1e-7) -> int:
	if g_eq_approx(n1, n2, rel_e):
		return 0
	return g_compare(n1, n2)

## Returns [code]n1 > n2[/code], with approximately equal values also being FALSE.
## See [method g_eq_approx].
static func g_gt_approx(n1: Dictionary, n2: Dictionary, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) > 0

## Returns [code]n1 >= n2[/code], with approximately equal values also being TRUE.
## See [method g_eq_approx].
static func g_gte_approx(n1: Dictionary, n2: Dictionary, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) >= 0

## Returns [code]n1 < n2[/code], with approximately equal values also being FALSE.
## See [method g_eq_approx].
static func g_lt_approx(n1: Dictionary, n2: Dictionary, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) < 0

## Returns [code]n1 <= n2[/code], with approximately equal values also being TRUE.
## See [method g_eq_approx].
static func g_lte_approx(n1: Dictionary, n2: Dictionary, rel_e: float = 1e-7) -> bool:
	return g_compare_approx(n1, n2, rel_e) <= 0


## Rounds the number downwards(towards negative infinity).
static func g_floor(n: Dictionary) -> Dictionary:
	if n.layer > 1:
		return duplicate_num_only(n)
	if n.mag < 0:
		if n.sign == -1:
			return from_float(-1)
		else:
			return from_float(0)
	if n.sign == -1:
		return from_components(n.sign, 0.0, ceilf(n.mag))
	return from_components(n.sign, 0.0, floorf(n.mag))

## Rounds the number upwards(towards positive infinity).
static func g_ceil(n: Dictionary) -> Dictionary:
	return g_neg(g_floor(g_neg(n)))

## Rounds the number towards 0.
## This is equivalent to coercing a [float] to an [int], excluding very large floats.
static func g_trunc(n: Dictionary) -> Dictionary:
	if n.mag < 0:
		return from_float(0)
	if n.layer == 0:
		return from_components(n.sign, 0, floor(n.mag) if n.mag > 0 else ceil(n.mag)) 
	return duplicate_num_only(n)

## Returns -n.
static func g_neg(n: Dictionary) -> Dictionary:
	return {
		"sign": -n.sign,
		"layer": n.layer,
		"mag": n.mag
	}

## Returns the absolute value of [param n]. (i.e. non-negative value)
static func g_abs(n: Dictionary) -> Dictionary:
	return from_components(absi(n.sign), n.layer, n.mag)

## Returns [code]1/n[/code].
static func g_recip(dec: Dictionary) -> Dictionary:
	if dec.mag == 0:
		return from_float(NAN)
	if dec.layer == 0:
		return from_components(dec.sign, 0, 1 / dec.mag)
	return from_components(dec.sign, dec.layer, -dec.mag)

## Returns the remainder of [param n1] divided by [param n2], keeping the sign of [param n1].
static func g_mod(n1: Dictionary, n2: Dictionary)-> Dictionary:
	if g_eq(n2, BIGNUM_ZERO.duplicate()) or g_eq(n1, BIGNUM_ZERO.duplicate()) or g_eq(n2, n1):
		return BIGNUM_ZERO.duplicate()
	
	# Special case: To avoid precision issues, if both numbers are valid floats, just call fmod on those
	if is_finite(to_float(n1)) and is_finite(to_float(n2)):
		return from_float(fmod(to_float(n1), to_float(n2)))
	
	if g_eq(n1, g_sub(n1, n2)):
	# Godot returns 0 on n1 way greater than n2
		return from_float(0)

	# Special case: if n2 is greater than n1, just return n1
	if g_compare_abs(n1, n2) < 0:
		return duplicate_num_only(n1)

	return g_sub(n1,g_mul(g_trunc(g_div(n1,n2)),n2))

## Returns the modulo of [param n1] divided by [param n2], keeping the sign of [param n2].
static func g_posmod(n1: Dictionary, n2: Dictionary) -> Dictionary:
	if g_eq(n2, BIGNUM_ZERO.duplicate()) or g_eq(n1, BIGNUM_ZERO.duplicate()) or g_eq(n2, n1):
		return BIGNUM_ZERO.duplicate()

	# Special case: To avoid precision issues, if both numbers are valid floats, just call fposmod on those
	if is_finite(to_float(n1)) and is_finite(to_float(n2)):
		return from_float(fposmod(to_float(n1), to_float(n2)))

	if g_eq(n1, g_sub(n1, n2)):
	# Godot returns 0 on n1 way greater than n2
		return from_float(0)

	return g_sub(n1,g_mul(g_floor(g_div(n1,n2)),n2))

## Returns [code]n1 + n2[/code].
static func g_add(n1: Dictionary, n2: Dictionary)-> Dictionary:

	var dec1 = duplicate_num_only(n1)
	var dec2 = duplicate_num_only(n2)
	# Inf/NAN check
	if not g_is_finite(n1):
		return dec1 
	if not g_is_finite(n2):
		return dec2 

	if dec1.sign == 0:
		return dec2
	if dec2.sign == 0:
		return dec1
	# n - n = 0
	if (
		dec1.sign == -dec2.sign and 
		dec1.layer == dec2.layer and
		dec1.mag == dec2.mag
	):
		return from_float(0)

	# If one of the numbers is layer 2 or bigger, just take the higher number.
	if (dec1.layer >= 2 || dec2.layer >= 2):
		return g_num_max_abs(dec1, dec2)
	
	if (dec1.layer == 0 and dec2.layer == 0):
		# Simply add the numbers together.
		return from_float((dec1.sign * dec1.mag) + (dec2.sign * dec2.mag))

	if g_compare_abs(dec1, dec2) < 0:
		var dec3: Dictionary = dec2
		dec2 = dec1
		dec1 = dec3

	var layer1 = dec1.layer * signf(dec1.mag)
	var layer2 = dec2.layer * signf(dec2.mag)
	
	# If one of the numbers is 2+ layers higher than the other, just take the bigger number.
	if absi(layer1 - layer2) >= 2:
		return dec1
	
	if layer1 == 0 and layer2 == -1:
		if absf(dec2.mag - (log(dec1.mag)/log(10))) > MAX_FLOAT_PRECISION:
			return dec1
		else:
			var magdiff = pow(10, log(dec1.mag)/log(10) - dec2.mag)
			var mantissa = dec1.sign * magdiff + dec2.sign
			return from_components(signi(mantissa), 1, dec2.mag + log(absf(mantissa))/log(10))

	if layer1 == 1 and layer2 == 0:
		if absf(dec1.mag - (log(dec2.mag)/log(10))) > MAX_FLOAT_PRECISION:
			return dec1
		else:
			var magdiff = pow(10, dec1.mag + log(dec2.mag)/log(10))
			var mantissa = dec2.sign * magdiff + dec1.sign
			return from_components(
				signi(mantissa), 
				1, 
				log(dec2.mag)/log(10) + log(absf(mantissa))/log(10)
			)

	if absf(dec1.mag - dec2.mag) > MAX_FLOAT_PRECISION:
		return dec1
	else:
		var magdiff = pow(10, dec1.mag - dec2.mag)
		var mantissa = dec1.sign * magdiff + dec2.sign
		return from_components(signi(mantissa), 1, dec2.mag + log(absf(mantissa))/log(10))
	# Unreachable
	#assert(false, "Failed to add {dec1} and {dec2}, throwing out 0".format({
		#"dec1": dec1,
		#"dec2": dec2
	#}))
	#return from_float(0)

## Returns [code]n1 - n2[/code].
static func g_sub(n1: Dictionary, n2: Dictionary) -> Dictionary:
	return g_add(n1, g_neg(n2))

## Returns [code]n1 * n2[/code].
static func g_mul(n1: Dictionary, n2: Dictionary) -> Dictionary:

	if g_is_nan(n1) or g_is_nan(n2):
		return from_float(NAN)
	# n * 0 yields 0
	if n1.sign == 0 or n2.sign == 0:
		return from_float(0.0)
	# n * (1 / n) yields 1
	if n1.layer == n2.layer and n1.mag == -n2.mag:
		return from_float(1.0)
	var new_sign = n1.sign * n2.sign

	if n1.layer == 0 and n2.layer == 0:
		# Number is not enough to get into the power tower, just multiply it normally
		return from_float(new_sign * n1.mag * n2.mag)

	var m: Dictionary
	var n: Dictionary
	if n1.layer > n2.layer or (n1.layer == n2.layer and absf(n1.mag) > absf(n2.mag)):
		m = n1
		n = n2
	else:
		m = n2
		n = n1

	# Multiplication is insigficant, return the bigger number instead.
	if m.layer >= 3 or (m.layer - n.layer) >= 2:
		return from_components(new_sign , m.layer, m.mag)

	if m.layer == 1 and n.layer == 0:
		return from_components(new_sign , 1, m.mag + log(n.mag)/log(10))

	if m.layer == 1 and n.layer == 1:
		return from_components(new_sign , 1, m.mag + n.mag)

	if m.layer == 2 and (n.layer == 1 or n.layer == 2):
		var newmag := from_components(signi(m.mag), 1, absf(m.mag))
		newmag = g_add(newmag, from_components(signi(n.mag), n.layer - 1, absf(n.mag)))
		return from_components(new_sign, newmag.layer + 1, newmag.sign * newmag.mag)
	
	assert(false, "Failed to multiply {n1} and {n2}, throwing out NaN".format({
		"n1": n1,
		"n2": n2
	}))
	return from_float(NAN)

## Returns [code]n1 / n2[/code].
static func g_div(n1: Dictionary, n2: Dictionary) -> Dictionary:
	return g_mul(n1, g_recip(n2))

## Returns the number so that 
## [code]abs(10 ** result == n)[/code].
static func g_abs_log10(n: Dictionary) -> Dictionary:
	if n.sign == 0:
		return from_float(NAN)
	if n.layer > 0:
		return from_components(signi(n.mag), n.layer - 1, absf(n.mag))
	return from_components(1, 0, log(n.mag)/log(10))

## Returns the number so that 
## [code]10 ** result == n[/code].
static func g_log10(n: Dictionary) -> Dictionary:
	if n.sign <= 0:
		return from_float(NAN)
	if n.layer > 0:
		return from_components(signi(n.mag), n.layer - 1, absf(n.mag))
	return from_components(signi(n.sign), 0, log(n.mag)/log(10))

## The natural exponential function. Returns [i]e[/i] ** n, where [i]e[/i] is a mathematical constant with an approximate value of 2.71828.
static func g_exp(n: Dictionary) -> Dictionary:
	if n.mag < 0:
		return from_float(1.0)
	if n.layer == 0:
		if n.mag <= 709.7:
			return from_float(exp(n.sign * n.mag))
		return from_components(1, 1, n.sign / log(10) * n.mag)
	if n.layer == 1:
		return from_components(1, 2, n.sign * ((1/log(10)) + n.mag))
	return from_components(1, n.layer + 1, n.sign * n.mag)

## Returns the number you need to raise [param base] with in order to result in [param to].
static func g_log(base: Dictionary, to: Dictionary) -> Dictionary:
	if to.sign < 0 or base.sign <= 0:
		return from_float(NAN)
	if to.sign == 0:
		return from_components_no_normalize(-1, 0.0, INF)
	if base.sign == 1 and base.layer == 0 and base.mag == 1:
		return from_float(NAN)
	if base.layer == 0 and to.layer == 0:
		return from_components(to.sign, 0, log(to.mag) / log(base.mag))
	
	return g_div(g_log10(to), g_log10(base))

## Raises [param base] to the power of [param n_exp].
static func g_pow(base: Dictionary, n_exp: Dictionary) -> Dictionary:
	# Godot returns NAN on 0^0
	if base.sign == 0 and n_exp.sign == 0:
		push_error("Cannot raise 0 to the power of 0")
		return from_float(NAN)
	# n^0 == 1
	if n_exp.sign == 0:
		return from_float(1)
	# 0^x == 0 
	if base.sign == 0:
		return from_float(0)
	# n^1 == n # 1^x == 1
	if n_exp.sign == 1 and n_exp.layer == 0 and n_exp.mag == 1 or (base.sign == 1 and base.layer == 0 and base.mag == 1):
		return duplicate_num_only(base)
	
	var n2: Dictionary = duplicate_num_only(base)
	n2 = g_abs_log10(n2)
	n2 = g_mul(n2, n_exp)
	n2 = g_pow10(n2)
	
	
	if base.sign == -1:
		if abs(n_exp.mag) % 1 != 0: # Fractional: Complex
			return from_float(NAN)
		if abs(n_exp.mag) % 2 == 0: # Even
			return n2
		else: # Odd
			return g_neg(n2)
		
	return n2

## Returns what number raised to [param n_exp] would result in [param to].
static func g_root(n_exp: Dictionary, to: Dictionary)-> Dictionary:
	return g_pow(n_exp, g_recip(to))


# http://mrob.com/pub/comp/hypercalc/hypercalc.txt
# by Robert P. Munafo
## Gamma Function. For a given [param n], this returns [code](n - 1) * (n - 2) * ... * 1[/code].
## This function is able to return an approximation if [param n] is not an integer.
static func f_gamma(n: float) -> float: 

# For very low negative arguments, the gamma function is so
# close to zero that we treat it as zero. However, for negative
# integers it's infinite, so we handle that case explicitly.
	if !is_finite(n):
		return n
	if n < 0:
		if n == floorf(n):
			return -INF
		if n < -50:
			return 0

	# Current precision allows for n^10.
	var scal1 = n ** 10
# Since we're using Stirling's series for factorials, we have
# to subtract 1 to make it be a gamma function series.
	n -= 1
	var l: float = log(TAU)/2
	l += ((n + 0.5)* log(n))
	l -= n
	var n2: float = n ** 2
	var np: float = n
	l += 1 / (12 * np)
	np *= n2
	l += 1 / (360 * np)
	np *= n2
	l += 1 / (1260 * np)
	np *= n2
	l += 1 / (1680 * np)
	np *= n2
	l += 1 / (1188 * np)
	np *= n2
	l += 691 / (360360 * np)
	np *= n2
	l += 7 / (1092 * np)
	np *= n2
	l += 3617 / (122440 * np)
	
	return exp(l) / scal1

# http://mrob.com/pub/comp/hypercalc/hypercalc.txt
# by Robert P. Munafo
## Gamma Function. For a given [param n], this returns [code](n - 1) * (n - 2) * ... * 1[/code].
## This function is able to return an approximation if [param n] is not an integer.
static func g_gamma(n: Dictionary) -> Dictionary:
	if n.mag < 0:
		return g_recip(n)
	if n.layer == 0:
		# Patashu's source code generates the number struct, but at layer 0 sign * mag IS the whole number
		if n.sign * n.mag < 24:
			return from_float(f_gamma(n.sign * n.mag))
		
		var t: float = n.mag - 1
		var l: float = log(TAU)/2
		l += (t + 0.5)* log(t)
		l -= t
		var t2 = t ** 2
		var np = t
		var lm = 12 * np
		var adj = 1 / lm
		var l2 = l + adj
		if l2 == l:
			return from_float(exp(l))
		
		l = l2
		np *= t2
		lm = 360 * np
		adj = 1 / lm
		l2 = l - adj
		if l2 == l:
			return from_float(exp(l))
		
		l = l2
		np *= t2
		lm = 1260 * np
		adj = 1 / lm
		l += adj
		np *= t2
		lm = 1680 * np
		adj = 1 / lm
		l -= adj
		return from_float(exp(l))
	if n.layer == 1:
		return g_exp(
			g_mul(
				n, 
				g_sub(
					g_log(
						from_float(exp(1)), 
						n
					),
					from_float(1)
				)
			)
		)
	return from_components(1, n.layer + 1, n.sign * n.mag)

## Returns the natural logarithm of gamma [param n].
static func g_lngamma(n: Dictionary) -> Dictionary:
	return g_log(from_float(exp(1)), g_gamma(n))

## For a given [param n], this returns [code](n) * (n - 1) * ... * 1[/code].
## This function is able to return an approximation if [param n] is not an integer.
static func g_factorial(n: Dictionary) -> Dictionary:
	if n.mag < 0 or n.layer == 0:
		return g_gamma(g_add(from_float(1), n))
	if n.layer == 1:
		return g_exp(
			g_mul(
				n, 
				g_sub(
					g_log(
						from_float(exp(1)), 
						n
					),
					from_float(1)
				)
			)
		)
	return from_components(1, n.layer + 1, n.sign * n.mag)

## Returns [code]10 ** n[/code].
static func g_pow10(n: Dictionary) -> Dictionary:
	# There are four cases we need to consider:
	# 1) positive sign, positive mag (e15, ee15): +1 layer (e.g. 10^15 becomes e15, 10^e15 becomes ee15)
	# 2) negative sign, positive mag (-e15, -ee15): +1 layer but sign and mag sign are flipped (e.g. 10^-15 becomes e-15, 10^-e15 becomes ee-15)
	# 3) positive sign, negative mag (e-15, ee-15): layer 0 case would have been handled in the pow check, so just return 1
	# 4) negative sign, negative mag (-e-15, -ee-15): layer 0 case would have been handled in the pow check, so just return 1

	if (not is_finite(n.mag)) or (not is_finite(n.layer)):
		return from_float(NAN)
	var n2: Dictionary = duplicate_num_only(n)
	if n.layer == 0:
		var newmag: float = 10 ** (n.sign * n.mag)
		# Is any precision lost?
		if is_finite(newmag) and absf(newmag) >= 0.1:
			return from_components(1, 0, newmag)
		if n.sign == 0:
			return from_float(1.0)
		
		n2 = from_components_no_normalize(n.sign, n.layer + 1, log(n.mag)/log(10))

	# Handle all 4 layer +1 layer cases individually.
	if n2.sign > 0 and n2.mag >= 0:
		return from_components(n2.sign, n2.layer + 1, n2.mag)
	if n2.sign < 0 and n2.mag >= 0:
		return from_components(-n2.sign, n2.layer + 1, -n2.mag)
	
	return from_float(1)

# from https://github.com/scipy/scipy/blob/8dba340293fe20e62e173bdf2c10ae208286692f/scipy/special/lambertw.pxd
## Returns the solution of [code]W(x) = x * (e ** x)[/code]. [url]https://en.wikipedia.org/wiki/Lambert_W_function[/url]
## 
static func g_lambertw(z: Dictionary, principal: bool = true, tolerance: float = 1e-10) -> Dictionary:
	var w: Dictionary 
	if g_compare(from_float(-0.3678794411710499), z) == 1:
		push_error("complex")
		return from_float_no_normalize(NAN)
	if principal:
		if z.mag < 0:
			return from_float(f_lambertw(to_float(z)))
		if z.layer == 0:
			return from_float(f_lambertw(z.sign * z.mag))
		if z.layer >= 3: # Numbers this large would sometimes fail to converge using Halley's method, and at this size ln(z) is close enough
			return g_log(from_float(exp(1)), z)

		if not is_finite(z.mag):
			return duplicate_num_only_no_normalize(z)
		
		if z.mag == 0:
			return from_float(0.0)

		if z.sign == 1 and z.mag == 1: # Split out this case because the asymptotic series blows up
			return from_float(LAMBERTW_ONE_ZERO)
		w = g_log(from_float(exp(1)), z)
	else:
		if z.sign == 1:
			return from_float(NAN)
		if z.layer == 0:
			return from_float(f_lambertw(to_float(z), false))
		if z.layer == 1:
			w = g_log(from_float(exp(1)), g_neg(z))
		else:
			return g_neg(g_lambertw(g_recip(g_neg(z))))
			
	var ew: Dictionary
	var wewz: Dictionary
	var wn: Dictionary
	
	# See 5.9 in [1]
	for i in range(max_i_lambertw):
		ew = g_exp(g_neg(w))
		wewz = g_sub(w, g_mul(z, ew))
		# let me build my family sized nest in peece
		wn = g_sub(
			w, 
			g_div(
				g_sub(
					g_add(
						w, 
						from_float(1)
					), 
					g_div(
						g_add(w, from_float(2)), 
						g_add(g_mul(w, from_float(2)), from_float(2))
					)
				), 
				wewz
			)
		)
		if g_compare(g_mul(from_float(tolerance), wn), g_abs(g_sub(wn, w))) > 1:
			return wn
		else:
			w = wn
	
	push_error("Number {n} failed to converge after {i} iterations".format({
		"n": z,
		"i": max_i_lambertw
	}))
	return from_float_no_normalize(NAN)
	


static func g_critical_section(base: float, n_exp:float, grid: Array) -> float:
	# this part is simple at least, since it's just 0.1 to 0.9
	n_exp = clampf(n_exp, 0, 1)
	n_exp *= 10
	# have to do this complicated song and dance since one of the critical_headers is exp(1), and in the future I'd like 1.5 as well
	base = clampf(base, 2, 10)
	var lower = 0
	var upper = 0
	# basically, if we're between bases, we interpolate each bases' relevant values together
	# then we interpolate based on what the fractional height is.
	# accuracy could be improved by doing a non-linear interpolation (maybe), by adding more bases and heights (definitely) but this is AFAIK the best you can get without running some pari.gp or mathematica program to calculate exact values
	# however, do note http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html can do it for arbitrary heights but not for arbitrary bases (2, e, 10 present)
	for i in range(len(CRITICAL_HEADERS)):
		if CRITICAL_HEADERS[i] == base: # exact match
			lower = grid[i][floor(n_exp)]
			upper = grid[i][ceil(n_exp)]
			break
		elif CRITICAL_HEADERS[i] < base and base < CRITICAL_HEADERS[i + 1]: # interpolate between this and the next
			var basefrac = (base - CRITICAL_HEADERS[i]) / (CRITICAL_HEADERS[i + 1] - CRITICAL_HEADERS[i])
			lower = lerp(grid[i][floor(n_exp)], grid[i + 1][floor(n_exp)], basefrac)
			upper = lerp(grid[i][ceil(n_exp)], grid[i][floor(n_exp)], basefrac)
			break
	var frac = fposmod(n_exp, 1)

	# improvement - you get more accuracy (especially around 0.9-1.0) by doing log, then frac, then powing the result
	# (we could pre-log the lookup table, but then fractional bases would get Weird)
	# also, use old linear for slog (values 0 or less in critical section). maybe something else is better but haven't thought about what yet
	if lower <= 0 or upper <= 0:
		return lower * (1 - frac) + upper * frac
	return base ** ((log(lower) / log(base) * (1 - frac)) + (log(upper) / log(base) * frac))

## Returns ([param base] ** [param from]) repeated [param diff] times, from the top. See [method g_tetrate].
## [codeblock]base ** (base ** (base ** ... (base ** from) ... )))[/codeblock]
## This function is able to return an approximation if [param diff] is not an integer.[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_layer_add(from: Dictionary, diff: float, base: Dictionary, linear: bool = false) -> Dictionary:
	var slogthis := g_slog(from, base)
	var slogdest := slogthis + diff
	if slogdest >= 0:
		return g_tetrate(base, slogdest, from_float(1), linear)
	elif not is_finite(slogdest):
		return from_float_no_normalize(NAN)
	elif slogdest >= -1:
		return g_log(base, g_tetrate(base, slogdest + 1, from_float(1), linear))
	else: 
		return g_log(base, g_log(base, g_tetrate(base, slogdest + 2, from_float(1), linear)))


## Returns (10 ** [param from]) repeated [param diff] times, from the top. See [method g_tetrate].
## [codeblock]10 ** (10 ** (10 ** ... (10 ** from) ... )))[/codeblock]
## This function is able to return an approximation if [param diff] is not an integer.[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_layer_add_10(from: Dictionary, diff: float, linear: bool = false) -> Dictionary:
	var n := diff
	var v := duplicate_num_only(from)
	if n >= 1:
		if v.mag < 0 and v.layer > 0:
			# bug fix: if result is very smol (mag < 0, layer > 0) turn it into 0 first
			v = from_float(0)
		elif v.sign == -1 and v.layer == 0:
			# bug fix - for stuff like -3.layeradd10(1) we need to move the sign to the mag
			v.sign = 1
			v.mag = -v.mag
		var layeradd: float = floorf(n)
		n -= layeradd
		v.layer += layeradd
	if n <= -1:
		var layeradd2: float = floorf(n)
		n -= layeradd2
		v.layer += layeradd2
		if v.layer < 0:
			for i in range(max_i_other):
				v.layer += 1
				v.mag = log(v.mag)/log(10)
				if not is_finite(v.mag):
					# another bugfix: if we hit -Infinity mag, then we should return negative infinity, not 0. 0.layeradd10(-1) h its this
					if v.sign == 0:
						v.sign = 1
					# also this, for 0.layeradd10(-2)
					if v.layer < 0:
						v.layer = 0
					normalize_n(v)
					return v
				if v.layer >= 0:
					break
	while v.layer < 0:
		v.layer += 1
		v.mag = log(v.mag)/log(10)
	# bugfix: before we normalize: if we started with 0, we now need to manually fix a layer ourselves!
	if v.sign == 0:
		v.sign = 1
		if v.mag == 0 and v.layer >= 1:
			v.layer -= 1
			v.mag = 1
	normalize_n(v)

	if n != 0:
		return g_layer_add(v, diff, from_float(10), linear)
	
	return v

## Returns [param base] raised to the power of [param base], [param n_exp]-1 times, starting from the top. 
## [url]https://en.wikipedia.org/wiki/Tetration[/url][br]
## If [param payload] is not 1, then first raises [param base] to the power of [param payload] once, that is, without repeating [param payload] in the [param n_exp] repetition.
## [codeblock] 
## base ** (base ** (base ** (base ** ...(base ** payload)...)))
## [/codeblock]
## [url]https://andydude.github.io/tetration/archives/tetration2/ident.html[/url][[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.[br]
static func g_tetrate(base: Dictionary, n_exp: float, payload: Dictionary = BIGNUM_ONE, linear: bool = false) -> Dictionary:
	
	# x ^^ 1 = x
	if n_exp == 1:
		return g_pow(base, payload)
	# x ^^ 0 = 1
	if n_exp == 0:
		return duplicate_num_only(payload)
	# 1 ^^ x = 1, 
	if g_eq(from_float(1), base):
		return from_float(1)
	# -1 ^^ x = -1
	if  g_eq(from_float(-1), base):
		return g_pow(base, payload)
	
	if n_exp == INF:
		if  exp(-exp(1)) < base.mag and base.mag < exp(1/exp(1)):
			if base.mag > 1.444667861009099: # hotfix for the very edge of the number range not being handled properly
				return from_float(exp(1))
			# formula for infinite height power tower
			var negln = g_neg(g_log(from_float(exp(1)), base))
			return g_div(g_lambertw(negln), negln)
		elif base.mag > exp(1/exp(1)):
			return from_components_no_normalize(1, INF, INF)
		else:
			# 0.06598803584531253708 > this_num >= 0: never converges
			# this_num < 0: All returns a complex number
			return from_components_no_normalize(0, NAN, NAN)
	
	# pow(0,0) is undefined in Godot
	if g_eq(from_float(0), base):
		return from_float_no_normalize(NAN)
	
	if n_exp < 0:
		return g_i_log(payload, base, -n_exp, linear)
	
	var frac_exp: float = fposmod(n_exp, 1)
	n_exp = floorf(n_exp)

	var v: Dictionary = duplicate_num_only(payload)
	if g_compare(from_float(0), base) == -1 and g_compare(base, from_float(exp(1) ** (1/exp(1)))) > 0:
		# flip-flops between two values, converging slowly (or if it's below 0.06598803584531253708, never).
		var old_exp := n_exp
		n_exp = minf(max_i_tetra, n_exp)
		for i in range(n_exp):
			var old_v = duplicate_num_only(v)
			v = g_pow(base, v)
			# Stop early if we converge
			if g_eq(v, old_v):
				return v
		if frac_exp != 0 or old_exp > max_i_tetra:
			# Raise a number to a power fraction times... Just do linear approx
			if old_exp <= max_i_tetra or fmod(old_exp, 2) == 0:
				return g_add(g_mul(v, from_float(frac_exp)), g_mul(g_pow(base, v), from_float(1 - frac_exp)))
			return g_add(g_mul(v, from_float(1 - frac_exp)), g_mul(g_pow(base, v), from_float(frac_exp)))
		return v
	
	#if g_compare(from_float(0), base) == -1:
		#pass
	
	if frac_exp != 0:
		if g_eq(from_float(1), payload):
			if g_compare(from_float(10), base) == -1 or linear:
				# Linear approx.
				v = g_pow(base, from_float(frac_exp))
			else:
				v = from_float(g_critical_section(to_float(base), frac_exp, CRITICAL_TETR_VALUES))
				# TODO: until the critical section grid can handle numbers below 2, scale them to the base
				# TODO: maybe once the critical section grid has very large bases, this math can be appropriate for them too? I'll think about it
				if g_compare(base, from_float(2)) == -1:
					v = g_add(
						from_float(1), 
						g_mul(
							g_sub(base, from_float(1)), g_sub(v, from_float(1))
						)
					)
		else:
			if g_eq(base, from_float(10)):
				v = g_layer_add_10(v, frac_exp, linear)
			else:
				v = g_layer_add(v, frac_exp, base, linear)
	for i in range(min(n_exp, max_i_tetra)):
			v = g_pow(base, v)
			# Bail if we're NAN (or INF, somehow)
			if (not is_finite(v.layer)) or not (is_finite(v.mag)):
				return duplicate_num_only(v)
			# Shortcut
			if v.layer - base.layer > 3:
				return from_components_no_normalize(v.sign, v.layer + (n_exp - i - 1), v.mag)
	return v


## Returns the result of repeating[code]log{base}(to)[/code] [param i] times.
## [codeblock]
## log{base}(log{base}(log{base}(...(log{base}(to))...)))
## [/codeblock]
static func g_i_log(to: Dictionary, base: Dictionary, i: float, linear: bool = false) -> Dictionary:
	if i < 0:
		return g_tetrate(base, -i, to, linear)
	var frac: float = fposmod(i, 1)
	i = floorf(i)
	var v = duplicate_num_only(to)
	for j in range(mini(floori(i), max_i_tetra)):
		v = g_log(base, v)
		if (not is_finite(v.mag)) or (not is_finite(v.layer)):
			return duplicate_num_only(v)
	if 0 < frac:
		if g_eq(from_float(10), base):
			v = g_layer_add_10(v, -frac, linear)
		else:
			v = g_layer_add(v, -frac, base, linear)
	return v

static func g_slog_start(to: Dictionary, base: Dictionary, linear: bool = false) -> float:
	# Handle special cases first.
	if g_compare(base, from_float(0)) <= 0 or g_eq(base, from_float(1)): 
		return NAN
	# need to handle these small, wobbling bases specially
	if g_compare(base, from_float(1)) == 1:
		if g_eq(to, from_float(1)):
			return 0
		if g_eq(to, from_float(0)):
			return -1
		# 0 < this < 1: ambiguous (happens multiple times)
	# this < 0: impossible (as far as I can tell)
	# this > 1: partially complex (http://myweb.astate.edu/wpaulsen/tetcalc/tetcalc.html base 0.25 for proof)
		return NAN
	# slog(0) is -1
	if to.mag < 0 or g_eq(to, from_float(0)):
		return -1
	var v = 0
	var t = duplicate_num_only(to)
	if t.layer - base.layer > 3:
		var layerloss = t.layer - base.layer - 3
		v += layerloss
		t.layer -= layerloss
	for i in range(max_i_other):
		if g_compare(t, from_float(0)) < 0:
			t = g_pow(base, t)
			v -= 1
		elif g_compare(t, from_float(1)) <= 0:
			# If base > 10, revert to linear
			# Not a good fix... - H4zardZ1
			if linear or g_compare(base, from_float(10)) == 1: 
				return v + to_float(t)
			else:
				return v + g_critical_section(to_float(base), to_float(t), CRITICAL_SLOG_VALUES)
		else:
			v += 1
			t = g_log(base, t)
	return v

## Returns how many times you have to raise [param base] to itself in order to get [param to].
## [url]https://en.wikipedia.org/wiki/Super-logarithm[/url][br]
## Due to how the data structure is built, this will never be higher than the limit of floating-point numbers ~(1.8e308).[br]
## Use [param max_i_other] to change the amount of iterations.[br]
## This function returns a [float].[br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_slog(to: Dictionary, base: Dictionary, linear: bool = false) -> float:
	var step_size := 0.001
	var has_changed_directions_once: bool = false
	var risen: bool = false
	var v: float = g_slog_start(to, base, linear)
	for i in range(max_i_other):
		var t = g_tetrate(base, v, from_float(1), linear)
		var rising: bool = g_compare(to, t) == -1
		if i > 1:
			if rising != risen:
				has_changed_directions_once = true
		risen = rising
		if has_changed_directions_once:
			step_size /= 2
		else:
			step_size *= 2
		step_size = absf(step_size)
		if rising:
			step_size *= -1
		v += step_size
		if step_size == 0:
			break
	return v

## Returns how many times you have to raise [param base] to itself in order to get [param to].
## [url]https://en.wikipedia.org/wiki/Super-logarithm[/url][br]
## Due to how the data structure is built, this will never be higher than the limit of floating-point numbers ~(1.8e308).[br]
## Change [param max_i_other] to change the amount of iterations.[br]
## This function returns the number Dictionary. [br]
## [b]Note:[/b]
## Tetration for non-integer heights does not have a single agreed-upon definition,
## so this library uses an analytic approximation for bases <= 10, but it reverts to the linear approximation for bases > 10.
## If you want to use the linear approximation even for bases <= 10, set [param linear] to true.
## Analytic approximation is not currently supported for bases > 10.
static func g_slog_n(to: Dictionary, base: Dictionary, linear: bool = false) -> Dictionary:
	return from_float(g_slog(to, base, linear))

## Returns what number raised to itself [code]degree - 1[/code] times will be equal to [param to].[br]
## This function returns the number Dictionary.[br]
## [b]Note:[/b]
## Only works with the linear approximation of tetration, as starting with analytic and then switching to linear would result in inconsistent behavior for super-roots.
## This only matters for non-integer degrees.[br]
## [b]Note:[/b]
## This function may be slow for 0 < [param to] < 1
static func g_sroot(to: Dictionary, degree: float) -> Dictionary:
	# TODO: Optimize this like how slog is optimized (if it isn't already)
	# 1st-degree super root just returns its input
	if degree == 1:
		return duplicate_num_only_no_normalize(to)
	if g_eq(from_float(INF), to):
		return from_float(INF)
	if not g_is_finite(to):
		return from_float(NAN)
	# Using linear approximation, x^^n = x^n if 0 < n < 1
	if 0 < degree and degree < 1:
		return g_root(to, from_float(degree))
	# Using linear approximation, there actually is a single solution for super roots with -2 < degree <= -1
	if -2 < degree and degree < -1:
		return g_root(from_float(degree + 2), to)
	# Super roots with -1 <= degree < 0 have either no solution or infinitely many solutions, and tetration with height <= -2 returns NaN, so super roots of degree <= -2 don't work
	if degree <= 0:
		return from_float(NAN)
	if g_eq(from_float(1), to):
		return from_float(1)
	# Infinite degree super-root is x^(1/x) between 1/e <= x <= e, undefined otherwise
	if degree == INF:
		var t := to_float(to)
		if exp(-1) < t and t < exp(1):
			return g_root(to, to)
		else:
			return from_float(NAN)
	# base < 0 (It'll probably be NaN anyway)
	if g_compare(to, from_float(0)) <= 0:
		return from_float(NAN)
	# Treat all numbers of layer <= -2 as zero, because they effectively are
	if g_compare(to, from_str("1ee-16")) <= 0:
		if fmod(degree, 2) == 1:
			return duplicate_num_only(to)
		else:
			return from_float(NAN)
	# I'll see if the guesswork of ssqrt() on the lambertw function or the guesswork of sroot(2, n) is faster later; for now i'll leave this in- H4zardZ1
	if degree == 2:
		return g_ssqrt(to)
	if g_compare(to, from_float(1)) == 1:
		# Uses guess-and-check to find the super-root.
		# If this > 10^^(degree), then the answer is under iteratedlog(10, degree - 1): for example, ssqrt(x) < log(x, 10) as long as x > 10^10, and linear_sroot(x, 3) < log(log(x, 10), 10) as long as x > 10^10^10
		# On the other hand, if this < 10^^(degree), then clearly the answer is less than 10
		# Since the answer could be a higher-layered number itself (whereas slog's maximum is 1.8e308), the guess-and-check is scaled to the layer of the upper bound, so the guess is set to the average of some higher-layer exponents of the bounds rather than the bounds itself (as taking plain averages on tetrational-scale numbers would go nowhere)
		var upper_bound_local := from_float(10)
		if g_compare(to, g_tetrate(from_float(10), degree, from_float(1), true)):
			upper_bound_local = g_i_log(to, from_float(10), degree, true)
		if degree <= 1:
			upper_bound_local = g_root(to, from_float(degree))
		var lower_local := from_float(0)
		var layer: float= upper_bound_local.layer
		var upper_local := g_i_log(upper_bound_local, from_float(10), layer, true)
		var previous_local = upper_local
		var guess_local := g_div(upper_local, from_float(2))
		while true:
			guess_local = g_div(g_add(upper_local, lower_local), from_float(2))
			var direction := g_compare(g_tetrate(g_tetrate(from_float(10), layer, guess_local, true), degree, from_float(1), true), to)
			if direction == 1:
				upper_local = guess_local
			else:
				lower_local = guess_local
			if g_eq(previous_local, guess_local):
				break
			else:
				previous_local = guess_local
		return g_tetrate(from_float(10), layer, guess_local, true)
	# 0 < to < 1
	# A tetration of decimal degree can potentially have three different portions, as shown at https://www.desmos.com/calculator/ayvqks6mxa, which is a graph of x^^2.05:
	# The portion where the function is increasing, extending from a minimum (which may be at x = 0 or at some x between 0 and 1) up to infinity (I'll call this the "increasing" range)
	# The portion where the function is decreasing (I'll call this the "decreasing" range)
	# A small, steep increasing portion very close to x = 0 (I'll call this the "zero" range)
	# If ceiling(degree) is even, then the tetration will either be strictly increasing, or it will have the increasing and decreasing ranges, but not the zero range (because if ceiling(degree) is even, 0^^degree == 1).
	# If ceiling(degree) is odd, then the tetration will either be strictly increasing, or it will have all three ranges (because if ceiling(degree) is odd, 0^^degree == 0).
	# The existence of these ranges means that a super-root could potentially have two or three valid answers.
	# Out of these, we'd prefer the increasing range value if it exists, otherwise we'll take the zero range value (it can't have a decreasing range value if it doesn't have an increasing range value) if the zero range exists.
	# It's possible to identify which range that "this" is in:
	# If the tetration is decreasing at that point, the point is in the decreasing range.
	# If the tetration is increasing at that point and ceiling(degree) is even, the point is in the increasing range since there is no zero range.
	# If the tetration is increasing at that point and ceiling(degree) is odd, look at the second derivative at that point. If the second derivative is positive, the point is in the increasing range. If the second derivative is negative, the point is the zero range.
	# We need to find the local minimum (separates decreasing and increasing ranges) and the local maximum (separates zero and decreasing ranges).
	# (stage) is which stage of the loop we're in: stage 1 is finding the minimum, stage 2 means we're between the stages, and stage 3 is finding the maximum.
	# The boundary between the decreasing range and the zero range can be very small, so we want to use layer -1 numbers. Therefore, all numbers involved are log10(recip()) of their actual values.
	var stage = 1
	var minimum := from_components(1, 10, 1)
	var maximum := from_components(1, 10, 1)
	var lower := from_components(1, 10, 1) # 1eeeeeeeeee-10
	var upper := from_components(1, 1, -16) # 1e-16
	var prev_span := from_float(0)
	var difference := from_components(1, 10, 1)
	var upper_bound := g_recip(g_pow10(upper))
	var distance := from_float(0)
	var guess := from_float(0)
	var prev_point := upper_bound
	var next_point := upper_bound
	var even_degree := ceili(degree) % 2 == 0
	var dir = 0
	var last_valid := from_components(1, 10, 1)
	var inf_loop_detector := false
	var previous_upper := from_float(0)
	var decreasing_found := false
	# JS allows you to dupe stuff with just the assignment operator. Godot... doesn't do that -H4zardZ1
	while stage < 4:
		if stage == 2:
			# The minimum has been found. If ceiling(degree) is even, there's no zero range and thus no local maximum, so end the loop here. Otherwise, begin finding the maximum.
			if even_degree:
				break
			else:
				lower = from_components(1, 10, 1)
				upper = duplicate_num_only(minimum)
				stage = 3
				difference = from_components(1, 10, 1)
				last_valid = from_components(1, 10, 1)
		inf_loop_detector = false
		while not g_eq(upper, lower):
			previous_upper = upper
			if g_eq(from_float(1), g_tetrate(g_recip(g_pow10(upper)), degree, from_float(1), true)) and g_gte(from_float(0.4), g_recip(g_pow10(upper))):
				upper_bound = g_recip(g_pow10(upper))
				prev_point = g_recip(g_pow10(upper))
				next_point = g_recip(g_pow10(upper))
				distance = from_float(0)
				dir = -1 # This would cause problems with degree < 1 in the linear approximation... but those are already covered as a special case
				if stage == 3:
					last_valid = duplicate_num_only(upper)
			elif g_eq(g_recip(g_pow10(upper)), g_tetrate(g_recip(g_pow10(upper)), degree, from_float(1), true)) and (not even_degree) and g_gte(from_float(0.4), g_recip(g_pow10(upper))):
				upper_bound = g_recip(g_pow10(upper))
				prev_point = g_recip(g_pow10(upper))
				next_point = g_recip(g_pow10(upper))
				distance = from_float(0)
				dir = 0
			elif g_eq(g_tetrate(g_recip(g_pow10(upper)), degree, from_float(1), true), g_tetrate(g_mul(from_float(2), g_recip(g_pow10(upper))), degree, from_float(1), true)):
				# If the upper bound is closer to zero than the next point with a discernable tetration, so surely it's in whichever range is closest to zero?
				# //This won't happen in a strictly increasing tetration, as there x^^degree ~= x as x approaches zero
				upper_bound = g_recip(g_pow10(upper))
				prev_point = from_float(0)
				next_point = g_mul(upper_bound, from_float(2))
				distance = duplicate_num_only(upper_bound)
				if even_degree:
					dir = 1
				else:
					dir = 0
			else:
				prev_span = g_mul(upper, from_float(1.2e-16))
				upper_bound = g_recip(g_pow10(upper))
				prev_point = g_recip(g_pow10(g_add(upper, prev_span)))
				distance = g_sub(upper_bound, prev_point)
				next_point = g_add(upper_bound, distance)
				# L A G T I M E !
				while g_eq(g_tetrate(next_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true)) or \
				g_eq(g_tetrate(prev_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true)) or \
				g_gte(prev_point, upper_bound) or g_lte(next_point, upper_bound):
					prev_span = g_mul(prev_span, from_float(2))
					prev_point = g_recip(g_pow10(g_add(prev_span, upper)))
					distance = g_sub(upper_bound, prev_point)
					next_point = g_add(upper_bound, distance)
					if (stage == 1 and g_gt(g_tetrate(next_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true)) and \
					g_gt(g_tetrate(prev_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true))) or \
					g_gte(prev_point, upper_bound) or g_lte(next_point, upper_bound):
						last_valid = duplicate_num_only(upper)
					if g_lt(g_tetrate(next_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true)):
						# Derivative is negative, so we're in decreasing range
						dir = -1
					elif even_degree:
						# No zero range, so we're in increasing range
						dir = 1
					elif stage == 3 and g_gt_approx(upper, minimum, 1e-8):
						# We're already below the minimum, so we can't be in range 1
						dir = 0
					else: # Number imprecision has left the second derivative somewhat untrustworthy, so we need to expand the bounds to ensure it's correct
						while g_eq_approx(g_tetrate(prev_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true), 1e-8) or \
						g_eq_approx(g_tetrate(next_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true), 1e-8) or \
						g_gte(prev_point, upper_bound) or g_lte(next_point, upper_bound):
							prev_span = g_mul(prev_span, from_float(2))
							prev_point = g_recip(g_pow10(g_add(upper, prev_span)))
							distance = g_sub(upper_bound, prev_point)
							next_point = g_add(upper_bound, distance)
						if g_lt(g_sub(g_tetrate(next_point, degree, from_float(1), true), g_tetrate(upper_bound, degree, from_float(1), true)), g_sub(g_tetrate(upper_bound, degree, from_float(1), true), g_tetrate(prev_point, degree, from_float(1), true))):
							# Second derivative is negative, so we're in zero range
							dir = 0
						else: # By process of elimination, we're in increasing range
							dir = 1
			decreasing_found = (dir == -1)
			if (stage == 1 and dir == 3) or (stage == 3 and dir != 0):
				# The upper bound is too high
				if g_eq(lower, from_components(1, 10, 1)):
					upper = g_mul(upper, from_float(2))
				else:
					upper = g_div(g_add(upper, lower),from_float(2))
					if inf_loop_detector and ((dir == 1 and stage == 1) or (dir == -1 and stage == 3)):
						# Avoid infinite loops from floating point imprecision
						break 
			else:
				if g_eq(lower, from_components(1, 10, 1)):
					# We've now found an actual lower bound
					lower = duplicate_num_only(upper)
					upper = g_div(upper, from_float(2))
				else:
					# The upper bound is too low, meaning last time we decreased the upper bound, we should have gone to the other half of the new range instead
					lower = g_sub(lower, difference)
					upper = g_sub(upper, difference)
					if inf_loop_detector and ((dir == 1 and stage == 1) or (dir == -1 and stage == 3)):
						# Avoid infinite loops from floating point imprecision
						break 
		# can't use the set bool value hack, have to do it this way because it might be false next pass
		if g_gt(g_abs(g_div(g_sub(lower, upper),from_float(2))), g_mul(difference, from_float(1.5))):
			inf_loop_detector = true
		difference = g_abs(g_div(g_sub(lower, upper),from_float(2)))
		if g_gt(upper, from_float(1e18)):
			break
		if g_eq(upper, previous_upper): # Since this isnt an invariant somehow this sanity check has to be done
			break
		if g_gt(upper, from_float(1e18)):
			break
		if not decreasing_found: # If there's no decreasing range, then even if an error caused lastValid to gain a value, the minimum can't exist
			break
		if last_valid == from_components(1, 10, 1):
			# Whatever we're searching for, it doesn't exist. If there's no minimum, then there's no maximum either, so either way we can end the loop here.
			break
		if stage == 1:
			minimum = duplicate_num_only(last_valid)
		elif stage == 3:
			maximum = duplicate_num_only(last_valid)
		stage += 1
	#	Now we have the minimum and maximum, so it's time to calculate the actual super-root.
	# First, check if the root is in the increasing range.
	lower = duplicate_num_only(minimum)
	upper = from_components(1, 1, -18)
	var previous := duplicate_num_only(upper)
	guess = BIGNUM_ZERO.duplicate()
	var loop_going = true
	while loop_going:
		if g_eq(lower, from_components(1, 10, 1)):
			guess = g_mul(upper, from_float(2))
		else:
			guess = g_div(g_add(upper, lower), from_float(2))
		if g_gt(g_tetrate(g_recip(g_pow(from_float(10), guess)), degree, from_float(1), true), to):
			upper = duplicate_num_only(guess)
		else:
			lower = duplicate_num_only(guess)
		if g_eq(guess, previous):
			loop_going = false
		else:
			previous = duplicate_num_only(guess)
		if g_gt(upper, from_float(1e18)):
			return from_float(NAN)
	# using guess.neq(minimum) led to imprecision errors, so here's a fixed version of that
	if not g_eq_approx(minimum, from_float(1e-15)):
		return g_recip(g_pow10(guess))
	# If guess == minimum, we haven't actually found the super-root, the algorithm just kept going down trying to find a super-root that's not in the increasing range.
	# Check if the root is in the zero range.
	elif g_eq(maximum, from_components(1, 10, 1)):
		# There is no zero range, so the super root doesn't exist
		return from_float(NAN)
	lower = from_components(1, 10, 1)
	upper = duplicate_num_only(maximum)
	previous = duplicate_num_only(upper)
	guess = BIGNUM_ZERO.duplicate()
	loop_going = true
	while loop_going:
		if g_eq(lower, from_components(1, 10, 1)):
			guess = g_mul(upper, from_float(2))
		else:
			guess = g_div(g_add(lower, upper), from_float(2))
		if g_gt(g_tetrate(g_recip(g_pow(from_float(10), guess)), degree, from_float(1), true), to):
			upper = duplicate_num_only(guess)
		else:
			lower = duplicate_num_only(guess)
		if g_eq(guess, previous):
			loop_going = false
		else:
			previous = duplicate_num_only(guess)
		if g_gt(upper, from_float(1e18)):
			return from_float(NAN)

	return g_recip(g_pow10(guess))

# https://math.stackexchange.com/questions/4152393/square-rooting-in-tetration
## Returns what number raised to itself will be equal to [param to].[br]
## See [method g_sroot]. This method is separate due to easier implementation.
static func g_ssqrt(to: Dictionary)-> Dictionary:
	if to.sign == 1 and to.layer >= 3:
		return from_components_no_normalize(to.sign, to.layer - 1, to.mag)
	var lnx := g_log(from_float(exp(1)), to)
	return g_div(lnx, g_lambertw(lnx))

## Returns [param base] tetrated to [param base], [param n_exp] times, starting from the top. [url]https://en.wikipedia.org/wiki/Pentation [/url][br]
## [codeblock]
## tetrate(base, tetrate(base, tetrate(base, tetrate...(base, base)...)))
## [/codeblock]
## This is an absurdly strong operator. [code]pentate(2, 4.28)[/code] and [/code]pentate(10, 2.37)[/code] are already too huge for this library!
## [br]
## [b]Note:[/b]
## For non-whole pentation heights, the linear approximation of pentation is always used, as there is no defined analytic approximation of pentation.
static func g_pentate(base: Dictionary, n_exp: float, payload: Dictionary = BIGNUM_ONE, linear: bool = false):
	var v := duplicate_num_only(payload)
	var frac_exp := fmod(n_exp, 1)
	# I have no idea if this is a meaningful approximation for pentation to continuous heights, but it is monotonic and continuous.
	if frac_exp != 0:
		if g_eq(from_float(1), payload):
			n_exp += 1
			v = from_float(n_exp)
		else:
			if g_eq(from_float(10), base):
				v = g_layer_add_10(v, frac_exp, linear)
			else:
				v = g_layer_add(v, frac_exp, base, linear)
	for i in range(min(max_i_tetra, floori(n_exp))):
		v = g_tetrate(base, to_float(v), from_float(1), linear)
		if (not is_finite(v.layer)) or (not is_finite(v.mag)):
			return duplicate_num_only(v)
	return v
# Trigonometry functions

# @GlobalScope.sin
## Returns the sine of angle [param n] in radians.
static func g_sin(n: Dictionary):
	if n.mag < 0:
		return duplicate_num_only_no_normalize(n)
	if n.layer == 0:
		return from_float(sin(n.sign * n.mag))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.cos
## Returns the cosine of angle [param n] in radians.
static func g_cos(n: Dictionary):
	if n.mag < 0:
		return BIGNUM_ONE.duplicate()
	if n.layer == 0:
		return from_float(cos(n.sign * n.mag))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.tan
## Returns the tangent of angle [param n] in radians.
static func g_tan(n: Dictionary):
	if n.mag < 0:
		return duplicate_num_only_no_normalize(n)
	if n.layer == 0:
		return from_float(tan(n.sign * n.mag))
	return BIGNUM_ZERO.duplicate()

# @GlobalScope.asin
## Returns the arc sine of [param n] in radians. See [method @GlobalScope.asin][br]
## [b]Note[/b]: This function returns 0 on large numbers (instead of NAN).
static func g_asin(n: Dictionary):
	if n.mag < 0:
		return duplicate_num_only_no_normalize(n)
	if n.layer == 0:
		return from_float(asin(n.sign * n.mag))
	return from_float(0)

# @GlobalScope.acos
## Returns the arc cosine of [param n] in radians. See [method @GlobalScope.acos][br]
## [b]Note[/b]: This function returns [constant @GDScript.TAU]/4 on large numbers (instead of NAN).
static func g_acos(n: Dictionary):
	if n.mag < 0:
		return from_float(acos(to_float(n)))
	if n.layer == 0:
		return from_float(acos(n.sign * n.mag))
	return from_float(TAU/4)

# @GlobalScope.atan
## Returns the arc tangent of [param n] in radians. See [method @GlobalScope.atan]
static func g_atan(n: Dictionary):
	if n.mag < 0:
		return duplicate_num_only_no_normalize(n)
	if n.layer == 0:
		return from_float(atan(n.sign * n.mag))
	# 9e15 < 1.8e308
	return from_float(atan(to_float(g_num_min(n, from_float(1.7e308)))))

# @GlobalScope.sinh # (e^x - e^-x)/2
static func g_sinh(n: Dictionary):
	# Special Case: since Godot has sinh, use it on layer 0 numbers
	if n.layer == 0:
		return from_float(sinh(n.sign * n.mag))
	return g_div(g_sub(g_exp(n), g_exp(g_neg(n))), from_float(2))

# @GlobalScope.cosh # (e^x + e^-x)/2
static func g_cosh(n: Dictionary):
	# Special Case: since Godot has cosh, use it on layer 0 numbers
	if n.layer == 0:
		return from_float(cosh(n.sign * n.mag))
	return g_div(g_add(g_exp(n), g_exp(g_neg(n))), from_float(2))

# @GlobalScope.tanh # Sinh(x)/Cosh(x)
static func g_tanh(n: Dictionary):
	# Special Case: since Godot has tanh, use it on layer 0 numbers
	if n.layer == 0:
		return from_float(tanh(n.sign * n.mag))
	return g_div(g_sinh(n), g_cosh(n))
	
# @GlobalScope.asinh
static func g_asinh(n: Dictionary):
	# Special Case: Since Godot has asinh, use it on layer 0 numbers
	if n.layer == 0:
		return from_float(asinh(n.sign * n.mag))
	return g_log(from_float(exp(1)), g_add(n, g_root(from_float(2), g_add(from_float(1), g_pow(n, from_float(2))))))

# @GlobalScope.acosh
static func g_acosh(n: Dictionary):
	if n.layer == 0:
		return from_float(acosh(n.sign * n.mag))
	# Godot wants to return 0 instead of NAN on x < 1. Let's do that
	if n.mag <= 1:
		return BIGNUM_ZERO.duplicate()
	return g_log(from_float(exp(1)), g_add(n, g_root(from_float(2), g_add(from_float(-1), g_pow(n, from_float(2))))))

# @ GlobalScope.atanh
static func g_atanh(n: Dictionary):
	if n.mag >= 1: 
		# Godot wants to return signed INF instead of NAN on x > 1 or x < -1. Let's do that
		return from_components_no_normalize(n.sign, INF, INF)
	return g_div(g_log(from_float(exp(1)), g_div(g_add(from_float(1), n), g_sub(from_float(1), n))), from_float(2))

# Godot helper math functions BEGIN
## Returns the linear interpolation (or extrapolation) between [param from] and [param to]. See [method @GlobalScope.lerp]
static func g_lerp(from: Dictionary, to: Dictionary, weight: Dictionary) -> Dictionary:
	return g_add(from, g_mul(weight, g_sub(to, from)))

## Returns the interpolation (or extrapolation) factor of [param current]
## between the range specified by [param from] and [param to].[br]
## See [method @GlobalScope.inverse_lerp]
static func g_inverse_lerp(from: Dictionary, to: Dictionary, current: Dictionary) -> Dictionary:
	return g_div(g_sub(current, from), g_sub(to, from))

## Wraps [param value] between [param min] and [param max]. 
## See [method @GlobalScope.wrap].
static func g_wrap(value: Dictionary, from: Dictionary, to: Dictionary):
	return g_add(from, g_posmod(value, g_sub(from, to)))

# Godot helper math functions END


## Returns the linear interpolation between [param from] and [param to], with [param weight] values above 1 or below 0 wrapped around.
static func g_wraplerp(from: Dictionary, to: Dictionary, weight: Dictionary) -> Dictionary:
	return g_add(from, g_mul(g_posmod(weight, from_float(1)), g_sub(to, from)))


	## Returns the length of the sum of a geometric series starting at [param price_start] additionally offset by [param current_owned]
	## where its value is the highest possible that is lower than or equal to [param res].[br]
	## This is an inverse of [method sum_geometric_series], where the returned result is always an integer.
static func afford_geometric_series(
	res: Dictionary, 
	price_start: Dictionary, 
	ratio: Dictionary, 
	current_owned: Dictionary = BIGNUM_ZERO
) -> Dictionary:
	var actual_start := g_mul(g_pow(ratio, current_owned), price_start)
	return g_floor(
		g_div(
			g_log10(
				g_add(
					g_mul(
						g_div(res, actual_start),
						g_sub(ratio, from_float(1))
					), 
					from_float(1)
				)
			), 
			g_log10(ratio)
		)
	)

## Returns the sum of a geometric series starting at [param price_start], additionally offset by [param current_owned], up to the [param items]-th item.
static func sum_geometric_series(
	items: Dictionary,
	price_start: Dictionary,
	ratio: Dictionary,
	current_owned: Dictionary = BIGNUM_ZERO
) -> Dictionary :
	return g_div(
		g_mul(
			g_mul(price_start, g_pow(ratio, current_owned)),
			g_sub(from_float(1), g_pow(ratio, items))
		), 
		g_sub(from_float(1), ratio)
	)

## Returns the length of the sum of an arithmetic series starting at [param price_start], additionally offset by [param current_owned]
## where its value is the highest possible that is lower than or equal to [param res].[br]
## This is an inverse of [method sum_arithmetic_series], where the returned result is always an integer.
static func afford_arithmetic_series(
	res: Dictionary,
	price_start: Dictionary,
	increase: Dictionary,
	current_owned: Dictionary = BIGNUM_ZERO
) -> Dictionary :
	var actual_start := g_add(price_start, g_mul(increase, current_owned))
	var b := g_sub(actual_start, g_div(increase, from_float(2)))
	var b2 := g_pow(b, from_float(2))
	return g_floor(
		g_div(
			g_add(
				g_neg(b), 
				g_add(
					b2, 
					g_root(
						from_float(2), 
						g_mul(g_mul(increase, res), from_float(2))
					)
				)
			), 
			increase
		)
	)

## Returns the sum of an arithmetic series starting at [param price_start], additionally offset by [param current_owned], up to the [param items]-th item.
static func sum_arithmetic_series(
	items: Dictionary,
	price_start: Dictionary,
	increase: Dictionary,
	current_owned: Dictionary = BIGNUM_ZERO
) -> Dictionary :
	var actual_start := g_add(price_start, g_mul(increase, current_owned))
	return g_mul(
		g_div(items, from_float(2)),
		g_add(
			g_mul(actual_start, from_float(2)), 
			g_mul(g_sub(items, from_float(1)), increase)
		)
	)




# variables
## The Dictionary representation of this reference's own number.
var d: Dictionary:
	set(value):
		d = BigNumRef.duplicate_num_only(value)
		n_changed.emit()
	get:
		return d
var _dirty_l_normalize: bool
var n_is_nan: bool:
	get:
		return BigNumRef.g_is_nan(d)

func _init(arg = 0):
	d = BigNumRef.from_v(arg)

## Changes the number inside the reference to [param text], and then returns the reference.
func l_from_str(text: String) -> BigNumRef:
	d = BigNumRef.from_str(text)
	return self

## Changes the number inside the reference to [param n], and then returns the reference.
func n_replace(n: Dictionary) -> BigNumRef:
	d = BigNumRef.duplicate_num_only(n)
	return self

## Changes the number inside the reference to the number that [param obj] holds, and then returns the reference.
func replace(obj: BigNumRef) -> BigNumRef:
	d = obj.d.duplicate()
	return self

## Adds the number the reference holds with [param n], and then returns the reference.
func n_add(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_add(n, d)
	return self

## Adds the number the reference holds with the number that [param obj] holds,
## then returns the reference this function was called on.
func add(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_add(obj.d, d)
	return self

## Subtracts the number the reference holds with [param n], and then returns the reference.
func n_sub(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_sub(d, n)
	return self

## Multiplies the number the reference holds with [param n], and then returns the reference.
func n_mul(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_mul(n, d)
	return self

## Multiplies the number the reference holds with the number that [param obj] holds,
## then returns the reference this function was called on.
func mul(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_mul(obj.d, d)
	return self

## Negates the number the reference holds, then returns the reference this function was called on.
func neg() -> BigNumRef:
	d = BigNumRef.g_neg(d)
	return self

## Recipocates the number the reference holds, then returns the reference this function was called on.
func recip() -> BigNumRef:
	d = BigNumRef.g_recip(d)
	return self

## Raises the number the reference holds by [param n], and then returns the reference.
func n_pow(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_pow(d, n)
	return self

## Raises the number this reference holds by the number that [param obj] holds,
## then returns the reference this function was called on.
func o_pow(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_pow(d, obj.d)
	return self

## Raises [param n] by the number the reference holds, and then returns the reference.
func n_pow_base(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_pow(n, d)
	return self

## Raises the number that [param obj] holds by the number the reference holds,
## mutating the reference [i]the function was called on [b]instead of[/b][/i] [param obj],
## then returns the reference the function was called on.
func pow_base(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_pow(obj.d, d)
	return self

# @GlobalScope.log
## Sets the number the reference holds to the logarithm of the number the reference previously holds by the base of [param obj].
## Returns the reference the function was called on.
func o_log(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_log(obj.d, d)
	return self

## Sets the number the reference holds to the logarithm of [param obj] by the base of the number the reference previously holds.
## Returns the reference the function was called on.
func log_base(obj: BigNumRef) -> BigNumRef:
	d = BigNumRef.g_log(d, obj.d)
	return self

## Sets the number the reference holds to the logarithm of the number the reference previously holds by the base of [param n].
## Returns the reference the function was called on.
func n_log(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_log(n, d)
	return self

## Sets the number the reference holds to the logarithm of [param n] by the base of the number the reference previously holds.
## Returns the reference the function was called on.
func n_log_base(n: Dictionary) -> BigNumRef:
	d = BigNumRef.g_log(d, n)
	return self

## Returns the string representation of the number this reference holds.
func n_str() -> String:
	return BigNumRef.g_to_str(d)

func n_str_to_decimal_places(round_to: int = default_round_to) -> String:
	return BigNumRef.g_to_str_to_decimal_places(d, round_to)

## Returns whether the number held by this reference is equal to [param n].
func n_eq(n: Dictionary) -> bool:
	return BigNumRef.g_eq(n, d)

## Returns whether then number held by this reference is equal to the number [param obj] holds.
func eq(obj: BigNumRef) -> bool:
	return BigNumRef.g_eq(obj.d, d)

func n_compare(n: Dictionary) -> int:
	return BigNumRef.g_compare(d, n)

func n_gt(n: Dictionary) -> bool:
	return BigNumRef.g_gt(d, n)

func n_gte(n: Dictionary) -> bool:
	return BigNumRef.g_gte(d, n)

func defer_l_normalize() -> void:
	if _dirty_l_normalize == false:
		call_deferred("l_normalize")
		_dirty_l_normalize = true

# usually you don't need to use this
## Normalizes the number currently held by this reference.[br]
## [b]Note:[/b] Users of this library should not need to use this function.
func l_normalize() -> void:
	d = BigNumRef.duplicate_num_only(d) # SORRY
	_dirty_l_normalize = false
