%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This file is part of Logtalk <https://logtalk.org/>
%  Copyright 1998-2019 Paulo Moura <pmoura@logtalk.org>
%
%  Licensed under the Apache License, Version 2.0 (the "License");
%  you may not use this file except in compliance with the License.
%  You may obtain a copy of the License at
%
%      http://www.apache.org/licenses/LICENSE-2.0
%
%  Unless required by applicable law or agreed to in writing, software
%  distributed under the License is distributed on an "AS IS" BASIS,
%  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%  See the License for the specific language governing permissions and
%  limitations under the License.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


:- object(misspell).

	% call to an undefined but declared predicate
	:- public(foo/0).

	output :-
		foo.

	% call to an undefined local predicate
	output(A) :-
		bar(A).

	% misspelt call to Prolog built-in predicate
	output(A) :-
		writr(A).

:- end_object.



% singleton variables in opening object directive
:- object(singletons(L)).

	% singleton variables in predicate clause
	predicate(A) :-
		write(C).

:- end_object.



:- object(redefinitions).

	% redefinition of Logtalk built-in predicate
	current_object(_).

	% redefinition of a Prolog built-in predicate
	write(_).

:- end_object.



% references to unknown entities in object opening directive

:- object(unknownrefs,
	implements(some_protocol),
	imports(some_category),
	extends(some_object)).

	:- if(current_logtalk_flag(modules, supported)).
		:- use_module(some_module, [predicate/0]).
	:- endif.

:- end_object.



:- object(portability).

	:- public(predicate/0).

	% clause with calls to non-ISO Prolog standard predicates
	predicate :-
		compare(Result, first, second),
		retractall(result(Result, _)),
		sort([], []),
		tell(file).

:- end_object.



:- object(unused_predicate).

	:- uses(logtalk, [
		expand_library_path/2
	]).

:- end_object.



:- object(unused_non_terminal).

	:- uses(logtalk, [
		message_tokens//2
	]).

:- end_object.



:- object(mode_directive_typo).

	:- public(a/1).
	:- mode(a(+atom, -integer), one).

:- end_object.



:- object(missing_public_directive).

	:- multifile(m/2).

:- end_object.



:- object(missing_protocol_reference).

	before(_, _, _).

:- end_object.



:- object(tautology).

	% goals are always true (usually happens due to typos)

	oops :- x \== y.

	really :- \+ x == y.

:- end_object.



:- object(falsewood).

	% goals are always false (usually happens due to typos)

	damn :- x == y.

	rats :- \+ x \== y.

	jinx(X) :- a is X*2.

:- end_object.



:- object(trivial_fails).

	% no matching clause for a call to a local predicate

	foo :-
		bar(1).

	bar([]).
	bar([_| _]).

:- end_object.



:- object(duplicated_scope_directive).

	:- public(foo/1).

	foo(1).
	foo(2).
	foo(3).

	:- public(foo/1).

:- end_object.



:- object(duplicated_multifile_directive).

	:- public(foo/1).
	:- multifile(foo/1).

	foo(1).
	foo(2).
	foo(3).

	:- multifile(foo/1).

:- end_object.



:- object(duplicated_dynamic_directive).

	:- dynamic(foo/1).

	foo(1).
	foo(2).
	foo(3).

	:- dynamic(foo/1).

:- end_object.



:- object(duplicated_discontiguous_directive).

	:- discontiguous(foo/1).

	foo(1).
	foo(2).
	foo(3).

	:- discontiguous(foo/1).

:- end_object.



:- object(duplicated_meta_predicte_directive).

	:- meta_predicate(foo(0)).

	foo(X) :-
		call(X).

	:- meta_predicate(foo(0)).

:- end_object.



:- object(duplicated_meta_non_terminal_directive).

	:- meta_non_terminal(foo(0)).

	foo(X) --> call(X).

	:- meta_non_terminal(foo(0)).

:- end_object.



:- object(suspicious_calls).

	% calling local predicates doesn't require message sending

	recursive([]).
	recursive([H| T]) :-
		::single(H),
		::recursive(T).

	foo :-
		self(Self),
		Self::bar.

	bar :-
		this(This),
		This::baz.

	baz.

	% a cut in a clause of a multifile predicate can unwanted and
	% difficult to track consequences as the clauses are distributed
	% among several entities/files

	:- public(multi/0).
	:- multifile(multi/0).
	multi :-
		!.

	:- multifile(logtalk::message_prefix_stream/4).
	:- dynamic(logtalk::message_prefix_stream/4).
	logtalk::message_prefix_stream(comment, foo, ':> ', user_error) :-
		!.

:- end_object.



:- object(steadfastness).

	% incorrect max/3 definition (e.g. max(5,3,3) is true!)
	max(X, Y, X) :- X >= Y, !.
	max(_, Y, Y).

	nt(A, A) --> [A], {A >= 65}, !.
	nt(_, 0) --> [_].

:- end_object.



:- object(missing_else).

	% missing else in ->/2 and *->/2 calls are a frequent source of bugs
	% and should never be used

	foo :-
		bar -> baz.

	bar.

	baz.

	:- if(predicate_property('*->'(_,_), built_in)).

		qux :-
			quux -> corge.

		quux.

		corge.

	:- endif.

:- end_object.



:- object(existential_variables).

	% existentially-qualified variables must exist in the qualified goal

	foo(X,Y,Z,W,V) :-
		bagof(X, Y^Z^baz(Z,W,V), _).

	bar(X,Y,Z,W,V) :-
		setof(X, Y^Z^baz(Z,W,V), _).

	baz(_, _, _).

:- end_object.



:- object(redundant_univ).

	% =../2 calls are only necessary when the second argument is a partial list
	% (i.e. a variable or a list with a variable tail)
	foo :-
		_ =.. [foo, bar, baz].

:- end_object.



:- object(redundant_user).

	% no need to send a message to "user" to call a standard predicate
	foo :-
		user::atom(baz).

:- end_object.



:- object(repeat_loop).

	% repeat loops without a cut can result in trouble in case of
	% unexpected backtracking
	foo :-
		repeat,
			bar(X),
		X == 42.

	bar(3).
	bar(7).
	bar(42).

:- end_object.



:- object(arithmetic).

	% variable typo or misunderstading of arithmetic
	foo :-
		X is X - 1.

:- end_object.



:- object(all_solutions).

	% template variables are expected to exist in the goal

	foo(X, Y, Z) :-
		findall(X, corge(Y,Z), _).

	bar(X, Y, Z) :-
		findall(X, corge(Y,Z), _, _).

	baz(X, Y, Z) :-
		bagof(X, corge(Y,Z), _).

	qux(X, Y, Z) :-
		setof(X, corge(Y,Z), _).

	% generator and test are expected to share variables

	quux(X, Y) :-
		forall(grault(X), garply(Y)).

	corge(_, _).
	grault(_).
	garply(_).

:- end_object.



:- object(naming).

	:- public(fooBar/0).

	:- private(nonTerminal//0).

	bazQux.

	quux(Corge_Grault, Corge_Grault).

	noMoreTokens --> eos.

	predicate(List, LIST, List, LIST).

:- end_object.



:- object(someObject).

:- end_object.
