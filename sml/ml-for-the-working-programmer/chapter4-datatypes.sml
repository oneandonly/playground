datatype degree = Duke | Marquis | Earl | Viscount | Baron;

datatype person = King
                | Peer of degree * string * int
                | Knight of string
                | Peasant of string;

fun lady Duke     = "Duchess"
  | lady Marquis  = "Marchioness"
  | lady Earl     = "Countess"
  | lady Viscount = "Viscountess"
  | lady Baron    = "Baroness";

fun degreeToString Duke     = "Duke"
  | degreeToString Marquis  = "Marquis"
  | degreeToString Earl     = "Earl"
  | degreeToString Viscount = "Viscount"
  | degreeToString Baron    = "Baron";

King;
Peer;
Knight;
Peasant;

fun title _ King                                    = "His Majesty the King"
  | title degreeToString (Peer(degree,territory,_)) = "The " ^ (degreeToString degree) ^ " of " ^ territory
  | title _ (Knight name)                           = "Sir " ^ name
  | title _ (Peasant name)                          = name;

fun superior (Knig, Peer _)        = true
  | superior (King, Knight _)      = true
  | superior (King, Peasant _)     = true
  | superior (Peer _, Knight _)    = true
  | superior (Peer _, Peasant _)   = true
  | superior (Knight _, Peasant _) = true
  | superior _                     = false;

(* Not the same as above, here Kings are superior to Kings *)
fun superior' (King, _)             = true
  | superior' (Peer _, Knight _)    = true
  | superior' (Peer _, Peasant _)   = true
  | superior' (Knight _, Peasant _) = true
  | superior' _                     = false;

fun rank King              = 4
  | rank (Peer _)          = 3
  | rank (Knight _)        = 2
  | rank (Peasant _)       = 1;

(* faithfully matches function 'superior' *)
fun superior'' p1 p2 = (rank p1) > (rank p2);

datatype ('a, 'b) sum = In1 of 'a | In2 of 'b;

type Person = ((unit, degree * string * int) sum, (string, string) sum) sum;

fun personToPerson King            = In1(In1 ()) : Person
  | personToPerson (Peer(d, t, n)) = In1(In2(d, t, n))
  | personToPerson (Knight(s))     = In2(In1(s))
  | personToPerson (Peasant(s))    = In2(In2(s));
