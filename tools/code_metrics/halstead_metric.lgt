%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This file is part of Logtalk <https://logtalk.org/>
%  Copyright 2017 Ebrahim Azarisooreh <ebrahim.azarisooreh@gmail.com> and
%  Paulo Moura <pmoura@logtalk.org>
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


:- object(halstead_metric,
	imports((code_metrics_utilities, code_metric))).

	:- info([
		version is 0.5,
		author is 'Paulo Moura',
		date is 2018/06/08,
		comment is 'Computes Halstead complexity numbers for an entity.',
		remarks is [
			'Definition of operators' - 'Predicates declared, user-defined, and called are interpreted as operators. Built-in predicates and built-in control constructs are ignored.',
			'Definition of operands' - 'Predicate arguments are abstracted and interpreted as operands. Note that this definition of operands is a significant deviation from the original definition, which used syntactic literals.',
			'Pn'  - 'Number of distinct predicates (declared, defined, or called)',
			'PAn' - 'Number of predicate arguments (assumed distinct)',
			'Cn'  - 'Number of predicate calls + number of clauses',
			'CAn' - 'Number of predicate call arguments + number of arguments in facts',
			'EV'  - 'Entity vocabulary: EV = Pn + PAn',
			'EL'  - 'Entity length: EL = Cn + CAn',
			'V'   - 'Volume: V = EL * log2(EV)',
			'D'   - 'Difficulty: D = (Pn/2) * (CAn/An)',
			'E'   - 'Effort: E = D * V',
			'T'   - 'Time required to program: T = E/18 seconds',
			'B'   - 'Number of delivered bugs: B = V/3000',
			'Entity score' - 'Represented as the compound term pn_pan_cn_can_ev_el_v_d_e_t_b/11.'
		]
	]).

	:- uses(list, [length/2, memberchk/2]).
	:- uses(numberlist, [sum/2]).
	:- uses(pairs, [values/2]).

	entity_score(Entity, pn_pan_cn_can_ev_el_v_d_e_t_b(Pn,PAn,Cn,CAn,EV,EL,V,D,E,T,B)) :-
		(	var(Entity) ->
			^^current_entity(Entity)
		;	true
		),
		^^entity_kind(Entity, Kind),
		predicate_data(Kind, Entity, Pn, PAn, Cn, CAn),
		EV is Pn + PAn,
		EL is Cn + CAn,
		(	EV > 0 ->
			V is EL * log(EV) / log(2)
		;	V is 0.0
		),
		(	PAn > 0 ->
			D is (Pn /2 ) * (CAn / PAn)
		;	D is 0.0
		),
		E is D * V,
		T is round(E / 18),
		B is V / 3000.

	predicate_data(protocol, Entity, Pn, PAn, 0, 0) :-
		findall(
			Arity,
			protocol_property(Entity, declares(_/Arity, _)),
			Arities
		),
		length(Arities, Pn),
		sum(Arities, PAn).
	predicate_data(category, Entity, Pn, PAn, Cn, CAn) :-
		findall(
			Predicate-Arity,
			(	(	category_property(Entity, declares(Predicate, _))
				;	category_property(Entity, defines(Predicate, _))
				;	category_property(Entity, calls(Predicate, _))
				),
				callee_arity(Predicate, Arity)
			),
			PredicatesArities
		),
		sort(PredicatesArities, DistinctPredicatesArities),
		length(DistinctPredicatesArities, Pn),
		values(DistinctPredicatesArities, PredicateArities),
		sum(PredicateArities, PAn),
		findall(
			CalleeArity,
			(	category_property(Entity, calls(Predicate, _)),
				callee_arity(Predicate, CalleeArity)
			),
			CalleeArities
		),
		length(CalleeArities, Cn0),
		category_property(Entity, number_of_user_clauses(Cls)),
		Cn is Cn0 + Cls,
		sum(CalleeArities, CAn0),
		findall(
			CallerDatum,
			(	category_property(Entity, defines(_/CallerArity, Properties)),
				memberchk(number_of_clauses(NumberOfClauses), Properties),
				memberchk(number_of_rules(NumberOfRules), Properties),
				CallerDatum is CallerArity * (NumberOfClauses - NumberOfRules)
			),
			CallerData
		),
		sum(CallerData, CAn1),
		CAn is CAn0 + CAn1.
	predicate_data(object, Entity, Pn, PAn, Cn, CAn) :-
		findall(
			Predicate-Arity,
			(	(	object_property(Entity, declares(Predicate, _))
				;	object_property(Entity, defines(Predicate, _))
				;	object_property(Entity, calls(Predicate, _))
				),
				callee_arity(Predicate, Arity)
			),
			PredicatesArities
		),
		sort(PredicatesArities, DistinctPredicatesArities),
		length(DistinctPredicatesArities, Pn),
		values(DistinctPredicatesArities, PredicateArities),
		sum(PredicateArities, PAn),
		findall(
			CalleeArity,
			(	object_property(Entity, calls(Callee, _)),
				callee_arity(Callee, CalleeArity)
			),
			CalleeArities
		),
		length(CalleeArities, Cn0),
		object_property(Entity, number_of_user_clauses(Cls)),
		Cn is Cn0 + Cls,
		sum(CalleeArities, CAn0),
		findall(
			CallerDatum,
			(	object_property(Entity, defines(_/CallerArity, Properties)),
				memberchk(number_of_clauses(NumberOfClauses), Properties),
				memberchk(number_of_rules(NumberOfRules), Properties),
				CallerDatum is CallerArity * (NumberOfClauses - NumberOfRules)
			),
			CallerData
		),
		sum(CallerData, CAn1),
		CAn is CAn0 + CAn1.

	callee_arity(_::_/Arity, Arity).
	callee_arity(::_/Arity, Arity).
	callee_arity(^^_/Arity, Arity).
	callee_arity(_:_/Arity, Arity).
	callee_arity(_/Arity, Arity).

	entity_score(_Entity, pn_pan_cn_can_ev_el_v_d_e_t_b(Pn,PAn,Cn,CAn,EV,EL,V,D,E,T,B)) -->
		['Number of distinct predicates (declared, defined, or called): ~d'-[Pn], nl],
		['Number of predicate arguments (assumed distinct): ~d'-[PAn], nl],
		['Number of predicate calls + number of clauses: ~d'-[Cn], nl],
		['Number of predicate call arguments + number of arguments in facts: ~d'-[CAn], nl],
		['Entity vocabulary: ~d'-[EV], nl],
		['Entity length: ~d'-[EL], nl],
		['Volume: ~f'-[V], nl],
		['Difficulty: ~f'-[D], nl],
		['Effort: ~f'-[E], nl],
		['Time required to program: ~d seconds'-[T], nl],
		['Number of delivered bugs: ~f'-[B], nl].

:- end_object.
