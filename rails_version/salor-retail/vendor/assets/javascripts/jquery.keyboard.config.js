$.keyboard.layouts['gn'] = {
	'default' : [
		"\u0302 1 2 3 4 5 6 7 8 9 0 \u00df \u0301 {b}",
		"{tab} q w e r t z u i o p \u00fc +",
		"a s d f g h j k l \u00f6 \u00e4 #",
		"{shift} < y x c v b n m , . - {shift}",
		"{c} {clear} {alt} {space} {alt} {a}"
	],
	'shift' : [
		'\u00b0 ! " \u00a7 $ % & / ( ) = ? \u0300 {b}',
		"{tab} Q W E R T Z U I O P \u00dc *",
		"A S D F G H J K L \u00d6 \u00c4 '",
		"{shift} > Y X C V B N M ; : _ {shift}",
		"{c} {clear} {alt} {space} {alt} {a}"
	],
	'alt' : [
		'\u0302 1 \u00b2 \u00b3 4 5 6 { [ ] } \\ \u0301 {b}',
		"{tab} @ w \u20ac r t z u i o p \u00fc \u0303",
		"a s d f g h j k l \u00f6 \u00e4 #",
		"{shift} \u007c y x c v b n \u00b5 , . - {shift}",
		"{c} {clear} {alt} {space} {alt} {a}"
	]
};

$.keyboard.layouts['num'] = {
	'default' : [
		"7 8 9",
		"4 5 6",
		"1 2 3",
		"- 0 ,",
		"{clear} {c} {a}"
	]
};



	$.keyboard.defaultOptions = {

		// *** choose layout & positioning ***
		layout       : 'gn',
		customLayout : null,

		position     : {
			of : null, // optional - null (attach to input/textarea) or a jQuery object (attach elsewhere)
			my : 'center top',
			at : 'center top',
			at2: 'center bottom' // used when "usePreview" is false (centers the keyboard at the bottom of the input/textarea)
		},

		// preview added above keyboard if true, original input/textarea used if false
		usePreview   : true,

		// if true, keyboard will remain open even if the input loses focus.
		stayOpen     : false,

		// *** change keyboard language & look ***
		display : {
			'a'      : '\u2714:Accept (Shift-Enter)', // check mark - same action as accept
			'accept' : 'Accept:Accept (Shift-Enter)',
			'alt'    : 'AltGr:Alternate Graphemes',
			'b'      : '\u2190:Backspace',    // Left arrow (same as &larr;)
			'bksp'   : 'Bksp:Backspace',
			'c'      : '\u2716:Cancel (Esc)', // big X, close - same action as cancel
			'cancel' : 'Cancel:Cancel (Esc)',
			'clear'  : 'C:Clear',             // clear num pad
			'combo'  : '\u00f6:Toggle Combo Keys',
			'dec'    : '.:Decimal',           // decimal point for num pad (optional), change '.' to ',' for European format
			'e'      : '\u21b5:Enter',        // down, then left arrow - enter symbol
			'enter'  : 'Enter:Enter',
			's'      : '\u21e7:Umschalt',        // thick hollow up arrow
			'shift'  : '\u21E7:Umschalt',
			'sign'   : '\u00b1:Change Sign',  // +/- sign for num pad
			'space'  : ' :Space',
			't'      : '\u21e5:Tab',          // right arrow to bar (used since this virtual keyboard works with one directional tabs)
			'tab'    : '\u21e5 Tab:Tab'       // \u21b9 is the true tab symbol (left & right arrows)
		},

		// Message added to the key title while hovering, if the mousewheel plugin exists
		wheelMessage : 'Use mousewheel to see other keys',

		// Class added to the Accept and cancel buttons (originally 'ui-state-highlight')
		actionClass  : 'ui-state-active',

		// *** Useability ***
		// Auto-accept content when clicking outside the keyboard (popup will close)
		autoAccept   : true,

		// Prevents direct input in the preview window when true
		lockInput    : false,

		// Prevent keys not in the displayed keyboard from being typed in
		restrictInput: false,

		// Prevent pasting content into the area
		preventPaste : false,

		// Set the max number of characters allowed in the input, setting it to false disables this option
		maxLength    : false,

		// Event (namespaced) on the input to reveal the keyboard. To disable it, just set it to ''.
		openOn       : 'focus',

		// Event (namepaced) for when the character is added to the input (clicking on the keyboard)
		keyBinding   : 'mousedown',

		// combos (emulate dead keys : http://en.wikipedia.org/wiki/Keyboard_layout#US-International)
		// if user inputs `a the script converts it to à, ^o becomes ô, etc.
		useCombos : true,
      combos : {},
// 		combos    : {
// 			'`' : { a:"\u00e0", A:"\u00c0", e:"\u00e8", E:"\u00c8", i:"\u00ec", I:"\u00cc", o:"\u00f2", O:"\u00d2", u:"\u00f9", U:"\u00d9", y:"\u1ef3", Y:"\u1ef2" }, // grave
// 			"'" : { a:"\u00e1", A:"\u00c1", e:"\u00e9", E:"\u00c9", i:"\u00ed", I:"\u00cd", o:"\u00f3", O:"\u00d3", u:"\u00fa", U:"\u00da", y:"\u00fd", Y:"\u00dd", c:"\u00e7", C:"\u00c7" }, // acute & cedilla
// 			'"' : { a:"\u00e4", A:"\u00c4", e:"\u00eb", E:"\u00cb", i:"\u00ef", I:"\u00cf", o:"\u00f6", O:"\u00d6", u:"\u00fc", U:"\u00dc", y:"\u00ff", Y:"\u0178" }, // umlaut/trema
// 			'^' : { a:"\u00e2", A:"\u00c2", e:"\u00ea", E:"\u00ca", i:"\u00ee", I:"\u00ce", o:"\u00f4", O:"\u00d4", u:"\u00fb", U:"\u00db", y:"\u0177", Y:"\u0176" }, // circumflex
// 			'~' : { a:"\u00e3", A:"\u00c3", e:"\u1ebd", E:"\u1ebc", i:"\u0129", I:"\u0128", o:"\u00f5", O:"\u00d5", u:"\u0169", U:"\u0168", y:"\u1ef9", Y:"\u1ef8", n:"\u00f1", N:"\u00d1" }, // tilde
// 			'a' : { e:"\u00e6" }, // ae ligature
// 			'A' : { E:"\u00c6" },
// 			'o' : { e:"\u0153" }, // oe ligature
// 			'O' : { E:"\u0152" }
// 		},

		// *** Methods ***
		// Callbacks - attach a function to any of these callbacks as desired
		accepted : null,
		canceled : null,
		hidden   : null,
		visible  : null,
		beforeClose: null

	};




