'fft.st -- fast frugal trees. Cuis Smalltalk port of fft.lisp.
Multi-objective regression trees over CSV data.
(c) 2026 Tim Menzies timm@ieee.org, MIT license.

FileIn this file, then in a Workspace:
    FFT egMain.     best tree
    FFT egTrees.    all trees
    FFT egGrows.    timing
Command line, no window (see run-fft.sh):
    run-fft.sh rebuild   bake fft-cuis.image (one window
                         flash; -headless hangs class
                         creation on the Mac VM)
    run-fft.sh egMain    then run headless from that image
Output goes to stdout (and Transcript when not headless).
Data path: edit FFT class >> file.'!

Object subclass: #FFT
	instanceVariableNames: ''
	classVariableNames: 'Seed'
	poolDictionaries: ''
	category: 'FFT'!

Object subclass: #FftNum
	instanceVariableNames: 'n mu m2'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FFT'!

Object subclass: #FftSym
	instanceVariableNames: 'counts'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FFT'!

Object subclass: #FftSpan
	instanceVariableNames: 'at lo hi'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FFT'!

FftSpan subclass: #FftCut
	instanceVariableNames: 'ys'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FFT'!

FftSpan subclass: #FftSplit
	instanceVariableNames: 'left right'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FFT'!

Object subclass: #FftData
	instanceVariableNames: 'names x y goal cols all rows'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FFT'!

!FFT class methodsFor: 'settings'!
seed
	^ 1234567891!

p
	^ 2!

bins
	^ 7!

depth
	^ 4!

big
	^ 1.0e32!

file
	^ '/Users/timm/gits/moot/optimize/misc/auto93.csv'! !

!FFT class methodsFor: 'utils'!
trim: aString
	| a b |
	a := 1.
	b := aString size.
	[a <= b and: [(aString at: a) isSeparator]]
		whileTrue: [a := a + 1].
	[b >= a and: [(aString at: b) isSeparator]]
		whileTrue: [b := b - 1].
	^ aString copyFrom: a to: b!

split: aString on: sep
	| out w |
	out := OrderedCollection new.
	w := WriteStream on: String new.
	aString do: [:c |
		c = sep
			ifTrue: [out add: w contents.
				w := WriteStream on: String new]
			ifFalse: [w nextPut: c]].
	out add: w contents.
	^ out!

thing: aString
	| s rs num |
	s := self trim: aString.
	s = '?' ifTrue: [^ nil].
	s = 'True' ifTrue: [^ true].
	s = 'False' ifTrue: [^ false].
	rs := ReadStream on: s.
	num := [Number readFrom: rs] on: Error do: [:e | nil].
	^ (num notNil and: [rs atEnd]) ifTrue: [num] ifFalse: [s]!

csv: path
	| out l |
	out := OrderedCollection new.
	(self split: path asFileEntry fileContents on: Character lf)
		do: [:line |
			l := self trim: line.
			(l isEmpty or: [l first = $#]) ifFalse: [
				out add: ((self split: l on: $,)
					collect: [:cell | self thing: cell]) asArray]].
	^ out!

least: aCollection by: aBlock
	^ aCollection inject: aCollection first into: [:a :b |
		(aBlock value: a) <= (aBlock value: b)
			ifTrue: [a] ifFalse: [b]]!

most: aCollection by: aBlock
	^ aCollection inject: aCollection first into: [:a :b |
		(aBlock value: a) >= (aBlock value: b)
			ifTrue: [a] ifFalse: [b]]!

mink: nums
	| s |
	s := nums inject: 0 into: [:acc :v |
		acc + (v abs raisedTo: self p)].
	^ (s / nums size) raisedTo: (1.0 / self p)!

fmt: x places: k
	| v s |
	v := (x abs * (10 raisedTo: k)) rounded.
	s := v printString.
	[s size <= k] whileTrue: [s := '0', s].
	s := (s copyFrom: 1 to: s size - k), '.',
		(s copyFrom: s size - k + 1 to: s size).
	^ (x < 0 and: [v > 0]) ifTrue: ['-', s] ifFalse: [s]!

pad: aString to: k
	| s |
	s := aString.
	[s size < k] whileTrue: [s := s, ' '].
	^ s!

padLeft: aString to: k
	| s |
	s := aString.
	[s size < k] whileTrue: [s := ' ', s].
	^ s!

str: x
	^ x isString ifTrue: [x] ifFalse: [x printString]!

prn: aString
	(Smalltalk at: #StdIOWriteStream ifAbsent: [nil])
		ifNotNil: [:cls |
			cls stdout nextPutAll: aString;
				nextPut: Character lf; flush].
	Smalltalk isHeadless ifFalse: [
		Transcript show: aString; newLine]! !

!FFT class methodsFor: 'random'!
resetSeed
	Seed := self seed!

rand: anInteger
	Seed ifNil: [self resetSeed].
	Seed := Seed * 16807 \\ 2147483647.
	^ anInteger * (Seed / 2147483647.0)!

rint: anInteger
	^ (self rand: anInteger) floor!

shuffle: aCollection
	| v |
	v := aCollection asArray copy.
	v size to: 2 by: -1 do: [:i |
		v swap: i with: (self rint: i) + 1].
	^ v!

few: aCollection count: k
	^ (self shuffle: aCollection) copyFrom: 1 to: k! !

!FFT class methodsFor: 'demos'!
egMain
	| i y ts |
	i := FftData fromCsv: self file.
	y := [:r | i disty: r].
	ts := (i growsFor: y root: i depth: 0)
		collect: [:pair | pair at: 2].
	i show: (i tune: ts y: y)!

egTrees
	| i y k err |
	i := FftData fromCsv: self file.
	y := [:r | i disty: r].
	k := 0.
	(i growsFor: y root: i depth: 0) do: [:pair |
		k := k + 1.
		err := i err: (pair at: 2) y: y.
		self prn: '===== tree ',
			(self padLeft: k printString to: 2),
			'   bias ', (self pad: (pair at: 1) to: 5),
			'   err ', (self fmt: err places: 3), ' ====='.
		i show: (pair at: 2).
		self prn: '']!

egGrows
	^ self egGrows: 10 sample: 100!

egGrows: reps sample: k
	| all m ms |
	self resetSeed.
	all := self csv: self file.
	m := 0.
	ms := Time millisecondsToRun: [
		reps timesRepeat: [
			| i |
			i := FftData names: all first
				rows: (self few: all allButFirst count: k).
			m := (i growsFor: [:r | i disty: r]
				root: i depth: 0) size]].
	self prn: reps printString, 'x (sample ', k printString,
		', ', m printString, ' trees): ',
		(self fmt: ms / 1000.0 places: 3), ' s -> ',
		(self fmt: ms / reps places: 1), ' ms'! !

!FftNum class methodsFor: 'instance creation'!
new
	^ self basicNew initialize! !

!FftNum methodsFor: 'initialization'!
initialize
	n := 0.
	mu := 0.0.
	m2 := 0.0! !

!FftNum methodsFor: 'accessing'!
n
	^ n!

mu
	^ mu!

m2
	^ m2!

setN: n1 mu: mu1 m2: m21
	n := n1.
	mu := mu1.
	m2 := m21! !

!FftNum methodsFor: 'stats'!
add: v
	^ self add: v weight: 1!

add: v weight: w
	| d |
	v ifNil: [^ self].
	n := n + w.
	n < 1 ifTrue: [n := 0. mu := 0.0. m2 := 0.0. ^ self].
	d := v - mu.
	mu := mu + (w * d / n).
	m2 := m2 + (w * d * (v - mu)).
	^ self!

sd
	n < 2 ifTrue: [^ 0].
	^ ((m2 max: 0) / (n - 1)) sqrt!

norm: v
	| z |
	z := (v - mu) / (self sd + 1.0e-32).
	^ 1 / (1 + ((-1.7 * ((z min: 3) max: -3)) exp))!

mix: j weight: w
	| m d |
	m := n + (w * (j n)).
	m < 1 ifTrue: [^ FftNum new].
	d := (j mu) - mu.
	^ FftNum new
		setN: m
		mu: ((n * mu) + (w * (j n) * (j mu))) / m
		m2: m2 + (w * (j m2))
			+ ((w * d * d * n * (j n)) / m)! !

!FftNum methodsFor: 'columns'!
bin: v
	^ (FFT bins * (self norm: v)) floor!

top: v old: old
	^ (old ifNil: [FFT big negated]) max: v!

cutsFrom: bins hi: hi at: at
	| l ks out |
	l := FftNum new.
	ks := (bins keys asSortedCollection: [:a :b | a < b])
		asArray.
	out := OrderedCollection new.
	1 to: ks size - 1 do: [:idx |
		l := l mix: (bins at: (ks at: idx)) weight: 1.
		out add: (FftCut new
			setAt: at
			lo: FFT big negated
			hi: (hi at: (ks at: idx))
			ys: l)].
	^ out! !

!FftNum methodsFor: 'trees'!
predictRow: row
	^ mu!

showOn: data
	FFT prn: (FFT pad: '' to: 33), ' leaf  d2h ',
		(FFT fmt: mu places: 2), ' n=', n printString! !

!FftSym class methodsFor: 'instance creation'!
new
	^ self basicNew initialize! !

!FftSym methodsFor: 'initialization'!
initialize
	counts := Dictionary new! !

!FftSym methodsFor: 'accessing'!
counts
	^ counts! !

!FftSym methodsFor: 'stats'!
add: v
	^ self add: v weight: 1!

add: v weight: w
	v ifNil: [^ self].
	counts at: v put: (counts at: v ifAbsent: [0]) + w.
	^ self!

mix: j weight: w
	| out |
	out := FftSym new.
	counts keysAndValuesDo: [:k :c |
		out add: k weight: c].
	j counts keysAndValuesDo: [:k :c |
		out add: k weight: w * c].
	^ out! !

!FftSym methodsFor: 'columns'!
bin: v
	^ v!

top: v old: old
	^ v!

cutsFrom: bins hi: hi at: at
	| out |
	out := OrderedCollection new.
	bins keysAndValuesDo: [:k :ys |
		out add: (FftCut new
			setAt: at
			lo: (hi at: k)
			hi: (hi at: k)
			ys: ys)].
	^ out! !

!FftSpan methodsFor: 'accessing'!
setAt: at1 lo: lo1 hi: hi1
	at := at1.
	lo := lo1.
	hi := hi1!

at
	^ at!

lo
	^ lo!

hi
	^ hi! !

!FftSpan methodsFor: 'testing'!
has: v
	v ifNil: [^ true].
	^ v isNumber
		ifTrue: [v between: lo and: hi]
		ifFalse: [v = lo]! !

!FftCut methodsFor: 'accessing'!
setAt: at1 lo: lo1 hi: hi1 ys: ys1
	self setAt: at1 lo: lo1 hi: hi1.
	ys := ys1!

ys
	^ ys! !

!FftSplit methodsFor: 'accessing'!
setAt: at1 lo: lo1 hi: hi1 left: l right: r
	self setAt: at1 lo: lo1 hi: hi1.
	left := l.
	right := r!

left
	^ left!

right
	^ right!

branchTo: r
	^ FftSplit new
		setAt: at lo: lo hi: hi left: left right: r! !

!FftSplit methodsFor: 'trees'!
predictRow: row
	^ (self has: (row at: at))
		ifTrue: [left predictRow: row]
		ifFalse: [right predictRow: row]!

showOn: data
	FFT prn: 'if ', (FFT pad: (data ruleFor: self) to: 30),
		' then d2h ', (FFT fmt: left mu places: 2),
		' n=', left n printString.
	right showOn: data! !

!FftData class methodsFor: 'instance creation'!
new
	^ self basicNew initialize!

names: nameArray rows: rowList
	^ self new setNames: nameArray rows: rowList!

fromCsv: path
	| lst |
	lst := FFT csv: path.
	^ self names: lst first rows: lst allButFirst! !

!FftData methodsFor: 'initialization'!
initialize
	x := OrderedCollection new.
	y := OrderedCollection new.
	goal := Dictionary new.
	cols := Dictionary new.
	all := OrderedCollection new.
	rows := OrderedCollection new!

setNames: nameArray rows: rowList
	names := nameArray.
	rows := rowList.
	1 to: names size do: [:at |
		self role: (names at: at) at: at].
	rows do: [:r |
		all with: r do: [:c :v | c add: v]]!

role: s at: at
	| z c |
	z := s last.
	c := s first isLowercase
		ifTrue: [FftSym new] ifFalse: [FftNum new].
	cols at: at put: c.
	all add: c.
	('-+!!' includes: z)
		ifTrue: [
			goal at: at put: (z = $+ ifTrue: [1] ifFalse: [0]).
			y add: at]
		ifFalse: [z = $X ifFalse: [x add: at]]! !

!FftData methodsFor: 'accessing'!
names
	^ names!

rows
	^ rows!

col: at
	^ cols at: at! !

!FftData methodsFor: 'distances'!
disty: row
	^ FFT mink: (y collect: [:at |
		((self col: at) norm: (row at: at)) - (goal at: at)])! !

!FftData methodsFor: 'discretize'!
cuts: c at: at ys: ys
	| bins hi k |
	bins := Dictionary new.
	hi := Dictionary new.
	rows with: ys do: [:r :y1 |
		(r at: at) ifNotNil: [:v |
			k := c bin: v.
			bins at: k put:
				((bins at: k ifAbsent: [FftNum new]) add: y1).
			hi at: k put:
				(c top: v old: (hi at: k ifAbsent: [nil]))]].
	^ c cutsFrom: bins hi: hi at: at!

cutsFor: yBlock
	| ys out |
	ys := rows collect: yBlock.
	out := OrderedCollection new.
	x do: [:at |
		out addAll: (self cuts: (self col: at) at: at ys: ys)].
	^ out! !

!FftData methodsFor: 'trees'!
splitsFor: yBlock root: root
	| enough cs out best no |
	enough := root rows size raisedTo: 0.33.
	cs := (self cutsFor: yBlock)
		reject: [:c | c ys n <= enough].
	out := OrderedCollection new.
	cs isEmpty ifTrue: [^ out].
	{ '0'. '1' } do: [:bit |
		best := bit = '0'
			ifTrue: [FFT least: cs by: [:c | c ys mu]]
			ifFalse: [FFT most: cs by: [:c | c ys mu]].
		no := rows reject: [:r |
			best has: (r at: (best at))].
		no isEmpty ifFalse: [
			out add: (Array
				with: bit
				with: (FftSplit new
					setAt: (best at)
					lo: (best lo)
					hi: (best hi)
					left: (best ys)
					right: nil)
				with: no)]].
	^ out!

growsFor: yBlock root: root depth: d
	| out leaf kid |
	out := OrderedCollection new.
	d < FFT depth ifTrue: [
		(self splitsFor: yBlock root: root) do: [:trip |
			kid := FftData names: names rows: (trip at: 3).
			(kid growsFor: yBlock root: root depth: d + 1)
				do: [:pair |
					out add: (Array
						with: (trip at: 1), (pair at: 1)
						with: ((trip at: 2)
							branchTo: (pair at: 2)))]]].
	out isEmpty ifTrue: [
		leaf := FftNum new.
		rows do: [:r | leaf add: (yBlock value: r)].
		out add: (Array with: '' with: leaf)].
	^ out!

err: tree y: yBlock
	^ (rows inject: 0 into: [:acc :r |
		acc + ((yBlock value: r)
			- (tree predictRow: r)) abs])
		/ rows size!

tune: cands y: yBlock
	^ FFT least: cands by: [:t | self err: t y: yBlock]!

ruleFor: sp
	| s |
	s := names at: (sp at).
	(sp lo) = (sp hi)
		ifTrue: [^ s, ' == ', (FFT str: sp lo)].
	(sp lo) = FFT big negated
		ifTrue: [^ s, ' <= ', (FFT str: sp hi)].
	^ s, ' >= ', (FFT str: sp lo)!

show: tree
	tree showOn: self! !
