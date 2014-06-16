(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

(** * Finite map library *)

(** Map interfaces, inspired by the previous finite map implementaiton in FMap,
    as well as the improved finite set interfaces in MSet.
*)


Require Export Bool SetoidList RelationClasses Morphisms
 RelationPairs Equalities Orders OrdersFacts.
Set Implicit Arguments.

Unset Strict Implicit.

Definition Cmp (elt:Type)(cmp:elt->elt->bool) e1 e2 := cmp e1 e2 = true.

Module Type TypElt.
 Parameter t : Type -> Type.
 Parameter key : Type.
End TypElt.

Module Type HasWOps (Import T:TypElt).

  Section Foo.
  Variable  A : Type.

  Parameter empty : t A.
  (** The empty map. *)

  Parameter is_empty : t A -> bool.
  (** Test whether a map is empty or not. *)

  Parameter mem : key -> t A -> bool.
  (** [mem k m] tests whether [k] belongs to the map [m]. *)
 
  Parameter find : key -> t A -> option A.

  Parameter add : key -> A -> t A -> t A.
  (** [add k m] returns a map containing all elements of [m],
  plus one mapping [k] to [v]. If [k] was already in [m], then its value
  is replaced by [v]. *)

  Parameter singleton : key -> A -> t A.
  (** [singleton k v] returns the one-element map containing only the key [k]
  that maps to [v]. *)

  Parameter remove : key -> t A -> t A.
  (** [remove k m] returns a map containing all elements of [m],
  except [k]. If [k] was not in [m], [m] is returned unchanged. *)

  (*
  TODO: Does not exist in FSet, OCaml has merge. What to do?

  Parameter union : t A -> t A -> t A.
  (** Set union. *)

  Parameter inter : t -> t -> t.
  (** Set intersection. *)

  Parameter diff : t -> t -> t.
  (** Set difference. *)
  *)

  Parameter equal : (A -> A -> bool) -> t A -> t A -> bool.
  (** [equal val_eq m1 m2] tests whether the maps [m1] and [m2] are
  equal, that is, contains the same keys, and values [v1] in [m1]
  and [v2] in [m2] for a common key [k] must be equal according to
  [val_eq]. *)

  Parameter subset : (A -> A -> bool) -> t A -> t A -> bool.
  (** [subset val_eq m1 m2] tests whether the map [m1] is a subset of
  the map [m2], where the values [v1] and [v2] for a common key [k]
  must be equal according to [val_eq]. *)

  Parameter fold : forall X : Type, (key -> A -> X -> X) -> t A -> X -> X.
  (** [fold f m a] computes [(f kN vN ... (f k2 v2 (f k1 v1 a))...)],
  where [k1 ... kN] are the keys, and [v1 ... vN] the corresponding values
  of [m]. The order in which elements of [m] are presented to [f] is
  unspecified. *)

  Parameter for_all : (key -> A -> bool) -> t A -> bool.
  (** [for_all p m] checks if all elements of the map [m]
  satisfy the predicate [p]. *)

  Parameter exists_ : (key -> A -> bool) -> t A -> bool.
  (** [exists p m] checks if at least one element of
  the map [m] satisfies the predicate [p]. *)

  Parameter filter : (key -> A -> bool) -> t A -> t A.
  (** [filter p m] returns the map of all elements in [m]
  that satisfy predicate [p]. *)

  Parameter partition : (key -> A -> bool) -> t A -> t A * t A.
  (** [partition p m] returns a pair of maps [(m1, m2)], where
  [m1] is the map of all the elements of [m] that satisfy the
  predicate [p], and [m2] is the map of all the elements of
  [m] that do not satisfy [p]. *)

  Parameter cardinal : t A -> nat.
  (** Return the number of elements of a map. *)

  Parameter elements : t A -> list (key * A).
  (** Return the list of all keys and values of the given map,
  in any order. *)

  Parameter choose : t A -> option (key * A).
  (** Return one key and value of the given map, or [None] if
  the map is empty. Which key is chosen is unspecified.
  Equal maps could return different elements. *)
  End Foo.
End HasWOps.


Module Type WOps (E : DecidableType).
  Definition key := E.t.
  Parameter t : Type -> Type. (** the abstract type of maps (given a value type) *)
  Include HasWOps.
End WOps.


(** ** Functorial signature for weak maps

    Weak maps are maps without ordering on keys, only
    a decidable equality. *)

Module Type WMapsOn (E : DecidableType).
  (** First, we ask for all the functions *)
  Include WOps E.

  Section Foo.
  Variable A : Type.

  (** Logical predicates *)

  Parameter MapsTo : key -> A -> t A -> Prop.
  Definition In (k:key)(m: t A) : Prop := exists e:A, MapsTo k e m.
  Declare Instance In_compat : Proper (E.eq==>eq==>iff) In.


  (* TODO: Copy explanation from FMap *)
  Definition Equal m m' := forall k, @find A k m = find k m'.
  Definition Equiv (eq_elt: A -> A -> Prop) m m' :=
         (forall k, In k m <-> In k m') /\
         (forall k e e', MapsTo k e m -> MapsTo k e' m' -> eq_elt e e').
  Definition Equivb (cmp: A -> A -> bool) := Equiv (Cmp cmp).

  Definition Empty m := forall k a, ~ MapsTo k a m.
  Definition For_all (P : key -> A -> Prop) m := forall k a, MapsTo k a m -> P k a.
  Definition Exists (P : key -> A -> Prop) m := exists k a, MapsTo k a m /\ P k a.

  Definition eq : t A -> t A -> Prop := Equal.
 
  (*
  Include IsEq. (** [eq] is obviously an equivalence, for subtyping only *)
  Include HasEqDec.
  *)

  (** Specifications of map operators *)

  Section Spec.

  Variable m m': t A.
  Variable k k' : key.
  Variable v v' : A.
  Variable f : key -> A -> bool.
  Notation compatb := (Proper (E.eq==>Logic.eq==>Logic.eq)) (only parsing).

  Parameter MapsTo_spec : E.eq k k' -> MapsTo k v m -> MapsTo k' v m.

  Parameter unique: MapsTo k v m -> MapsTo k v' m -> v = v'.

  Parameter find_spec : find k m = Some v <-> MapsTo k v m.
  Parameter mem_spec : mem k m = true <-> In k m.
  Section EqSpec.
     Variable cmp : A -> A -> bool.
     Parameter equal_1 : Equivb cmp m m' -> equal cmp m m' = true.
     Parameter equal_2 : equal cmp m m' = true -> Equivb cmp m m'.
  End EqSpec.

  Parameter empty_spec : Empty (empty A).
  Parameter is_empty_spec : is_empty m = true <-> Empty m.
  (* Parameter add_spec : In k1 (add k2 v m) <-> E.eq y x \/ In y m. *)
  Parameter add_spec1: E.eq k k' -> MapsTo k v (add k' v m).
  Parameter add_spec2: ~ E.eq k k' -> (MapsTo k v (add k' v' m) <-> MapsTo k v m).

  Parameter remove_spec1: E.eq k k' -> ~ In k (remove k' m).
  Parameter remove_spec2: ~ E.eq k k' -> MapsTo k' v (remove k m) <-> MapsTo k' v m.

  Parameter singleton_spec: E.eq k k' <-> MapsTo k v (singleton k' v).

  (*
  Parameter union_spec : In x (union m m') <-> In x m \/ In x m'.
  Parameter inter_spec : In x (inter m m') <-> In x m /\ In x m'.
  Parameter diff_spec : In x (diff m m') <-> In x m /\ ~In x m'.
  *)

  Parameter fold_spec : forall (X : Type) (i : X) (f : key -> A -> X -> X),
    fold f m i = fold_left (fun a p => f (fst p) (snd p) a ) (elements m) i.
  Parameter cardinal_spec : cardinal m = length (elements m).
  Parameter filter_spec : compatb f ->
    (MapsTo k v (filter f m) <-> MapsTo k v m /\ f k v = true).
  Parameter for_all_spec : compatb f ->
    (for_all f m = true <-> For_all (fun k v => f k v = true) m).
  Parameter exists_spec : compatb f ->
    (exists_ f m = true <-> Exists (fun k v => f k v = true) m).
  Parameter partition_spec1 : compatb f ->
    Equal (fst (partition f m)) (filter f m).
  Parameter partition_spec2 : compatb f ->
    Equal (snd (partition f m)) (filter (fun k x => negb (f k x)) m).
  
  Parameter elements_spec1 : InA (fun p1 p2 => E.eq (fst p1) (fst p2) /\ snd p1 = snd p2) (k, v) (elements m) <-> MapsTo k v m.
  (** When compared with ordered maps, here comes the only
      property that is really weaker: *)
  Parameter elements_spec2w : NoDupA  (fun p1 p2 => E.eq (fst p1) (fst p2) /\ snd p1 = snd p2) (elements m).
  Parameter choose_spec1 : choose m = Some (k,v) -> MapsTo k v m.
  Parameter choose_spec2 : choose m = None -> Empty m.

  End Spec.
  End Foo.

End WMapsOn.

(** ** Static signature for weak maps

    Similar to the functorial signature [WMapsOn], except that the
    module [E] of base elements is incorporated in the signature. *)

Module Type WMaps.
  Declare Module E : DecidableType.
  Include WMapsOn E.
End WMaps.

(** ** Functorial signature for maps on ordered elements

    Based on [WMapsOn], plus ordering on keys and [min_elt] and [max_elt]
    and some stronger specifications for other functions. *)

Module Type HasOrdOps (Import T:TypElt).
  Section Foo.
  Variable A : Type.

  (* TODO: Does this make sense? We'd have to compare values
  Parameter compare : t A -> t A -> comparison.
  *)
  (** Total ordering between maps. Can be used as the ordering function
  for doing maps of maps. *)

  Parameter min_elt : t A -> option (key * A).
  (** Return the smallest key and the associated value of the given map
  (with respect to the [E.compare] ordering),
  or [None] if the map is empty. *)

  Parameter max_elt : t A -> option (key * A).
  (** Same as [min_elt], but returns the largest key and the associated
  value of the given map. *)
  End Foo.
End HasOrdOps.

Module Type Ops (E : OrderedType) := WOps E <+ HasOrdOps.


Module Type MapsOn (E : OrderedType).

  Include WMapsOn E <+ HasOrdOps.
  (* TODO: type of HasLt not matched (like Eq above)
  Include WMapsOn E <+ HasOrdOps <+ HasLt <+ IsStrOrder.
  *)

  Section Spec.
  Variable A : Type.
  Variable m m': t A.
  Variable k k' : key.
  Variable v v' : A.

  (* TODO: Requires HasLt or IsStrOrder
  Parameter compare_spec : CompSpec eq lt m m' (compare m m').
  *)

  (** Additional specification of [elements] *)
  Parameter elements_spec2 : sort (fun p1 p2 => E.lt (fst p1) (fst p2)) (elements m).

  (** Remark: since [fold] is specified via [elements], this stronger
   specification of [elements] has an indirect impact on [fold],
   which can now be proved to receive elements in increasing order.
  *)

  Parameter min_elt_spec1 : min_elt m = Some (k,v) -> MapsTo k v m.
  Parameter min_elt_spec2 : min_elt m = Some (k,v) -> MapsTo k' v' m -> ~ E.lt k' k.
  Parameter min_elt_spec3 : min_elt m = None -> Empty m.

  Parameter max_elt_spec1 : max_elt m = Some (k,v) -> MapsTo k v m.
  Parameter max_elt_spec2 : max_elt m = Some (k,v) -> MapsTo k' v' m -> ~ E.lt k k'.
  Parameter max_elt_spec3 : max_elt m = None -> Empty m.

  (** Additional specification of [choose] *)
  Parameter choose_spec3 : choose m = Some (k, v) -> choose m' = Some (k', v') ->
    Equal m m' -> E.eq k k'.

  End Spec.

End MapsOn.


(** ** Static signature for maps on ordered keys

    Similar to the functorial signature [MapsOn], except that the
    module [E] of base elements is incorporated in the signature. *)

Module Type Maps.
  Declare Module E : OrderedType.
  Include MapsOn E.
End Maps.

Module Type M := Maps.


(** ** Some subtyping tests
<<
WMapsOn ---> WMaps
 |           |
 |           |
 V           V
MapsOn  ---> Maps

Module S_WS (M' : Maps) <: WMaps := M'.
Module Sfun_WSfun (E:OrderedType)(M' : MapsOn E) <: WMapsOn E := M'.
Module S_Sfun (M' : Maps) <: MapsOn M'.E := M'.
Module WS_WSfun (M' : WMaps) <: WMapsOn M'.E := M'.
>>
*)



(** ** Signatures for map representations with ill-formed values.

   Motivation:

   For many implementation of finite maps (AVL trees, sorted
   lists, lists without duplicates), we use the same two-layer
   approach:

   - A first module deals with the datatype (eg. list or tree) without
   any restriction on the values we consider. In this module (named
   "Raw" in the past), some results are stated under the assumption
   that some invariant (e.g. sortedness) holds for the input maps. We
   also prove that this invariant is preserved by map operators.

   - A second module implements the exact Maps interface by
   using a subtype, for instance [{ l : list A | sorted l }].
   This module is a mere wrapper around the first Raw module.

   With the interfaces below, we give some respectability to
   the "Raw" modules. This allows the interested users to directly
   access them via the interfaces. Even better, we can build once
   and for all a functor doing the transition between Raw and usual Maps.

   Description:

   The type [t] of maps may contain ill-formed values on which our
   map operators may give wrong answers. In particular, [mem]
   may not see a element in a ill-formed map (think for instance of a
   unsorted list being given to an optimized [mem] that stops
   its search as soon as a strictly larger element is encountered).

   Unlike optimized operators, the [In] predicate is supposed to
   always be correct, even on ill-formed maps. Same for [Equal] and
   other logical predicates.

   A predicate parameter [Ok] is used to discriminate between
   well-formed and ill-formed values. Some lemmas hold only on maps
   validating [Ok]. This predicate [Ok] is required to be
   preserved by map operators. Moreover, a boolean function [isok]
   should exist for identifying (at least some of) the well-formed maps.

*)

Module Type WRawMaps (E : DecidableType).
  (** First, we ask for all the functions *)
  Include WOps E.

  (** Is a set well-formed or ill-formed ? *)
  Variable A : Type.

  Parameter IsOk : t A -> Prop.
  Class Ok (s:t A) : Prop := ok : IsOk s.

  (** In order to be able to validate (at least some) particular sets as
      well-formed, we ask for a boolean function for (semi-)deciding
      predicate [Ok]. If [Ok] isn't decidable, [isok] may be the
      always-false function. *)
  Parameter isok : t A -> bool.
  Declare Instance isok_Ok s `(isok s = true) : Ok s | 10.

  (** Logical predicates *)
  Parameter In : key -> t A -> Prop.
  Parameter MapsTo : key -> A -> t A -> Prop.
  Declare Instance In_compat : Proper (E.eq==>eq==>iff) In.

  Definition Equal m m' := forall k, @find A k m = find k m'.
  Definition Equiv (eq_elt: A -> A -> Prop) m m' :=
         (forall k, In k m <-> In k m') /\
         (forall k e e', MapsTo k e m -> MapsTo k e' m' -> eq_elt e e').
  Definition Equivb (cmp: A -> A -> bool) := Equiv (Cmp cmp).

  Definition Empty s := forall a : key, ~ In a s.
  Definition For_all (P : key -> A -> Prop) s := forall x a, MapsTo x a s -> P x a.
  Definition Exists (P : key -> A -> Prop) s := exists x a, MapsTo x a s /\ P x a.

  Definition eq : t A -> t A -> Prop := Equal.
  Declare Instance eq_equiv : Equivalence eq.

  (** First, all operations are compatible with the well-formed predicate. *)

  Declare Instance empty_ok : Ok (empty A).
  Declare Instance add_ok s x a `(Ok s) : Ok (add x a s).
  Declare Instance remove_ok s x `(Ok s) : Ok (remove x s).
  Declare Instance singleton_ok x a : Ok (singleton x a).
  (* Set functionality not usefull in MAP
  Declare Instance union_ok s s' `(Ok s, Ok s') : Ok (union s s').
  Declare Instance inter_ok s s' `(Ok s, Ok s') : Ok (inter s s').
  Declare Instance diff_ok s s' `(Ok s, Ok s') : Ok (diff s s').
  *)
  Declare Instance filter_ok s f `(Ok s) : Ok (filter f s).
  Declare Instance partition_ok1 s f `(Ok s) : Ok (fst (partition f s)).
  Declare Instance partition_ok2 s f `(Ok s) : Ok (snd (partition f s)).

  (** Now, the specifications, with constraints on the input sets. *)

  Section Spec.
  Variable s s': t A.
  Variable k k' : key.
  Variable v : A.
  Variable f : key -> A -> bool.
  Notation compatb := (Proper (E.eq==>Logic.eq==>Logic.eq)) (only parsing).

  Parameter mem_spec : forall `{Ok s}, mem k s = true <-> In k' s.

 Section EqSpec.
     Variable cmp : A -> A -> bool.
     Parameter equal_1 : 
       forall `{Ok s, Ok s'},
       Equivb cmp s s' -> equal cmp s s' = true.
     Parameter equal_2 :
       forall `{Ok s, Ok s'},
       equal cmp s s' = true -> Equivb cmp s s'.
  End EqSpec.

  Parameter empty_spec : Empty (empty A).
  Parameter is_empty_spec : is_empty s = true <-> Empty s.
  Parameter add_spec : forall `{Ok s},
    In k' (add k v s) <-> E.eq k' k \/ In k' s.
  Parameter remove_spec : forall `{Ok s},
    In k' (remove k s) <-> In k' s /\ ~E.eq k' k.
  Parameter singleton_spec : In k' (singleton k v) <-> E.eq k' k.
  (* TODO set operations nor usefull for maps 
  Parameter union_spec : forall `{Ok s, Ok s'},
    In x (union s s') <-> In x s \/ In x s'.
  Parameter inter_spec : forall `{Ok s, Ok s'},
    In x (inter s s') <-> In x s /\ In x s'.
  Parameter diff_spec : forall `{Ok s, Ok s'},
    In x (diff s s') <-> In x s /\ ~In x s'.
  *)
  Parameter fold_spec : forall (X : Type) (i : X) (f : key -> A -> X -> X),
    fold f s i = fold_left (fun (x:X) (p:key*A) => f (fst p) (snd p) x ) (elements s) i.
  Parameter cardinal_spec : forall `{Ok s},
    cardinal s = length (elements s).
  Parameter filter_spec : compatb f ->
    (MapsTo k v (filter f s) <-> MapsTo k v s /\ f k v = true).
  Parameter for_all_spec : compatb f ->
    (for_all f s = true <-> For_all (fun x a => f x a = true) s).
  Parameter exists_spec : compatb f ->
    (exists_ f s = true <-> Exists (fun x a => f x a = true) s).
  Parameter partition_spec1 : compatb f ->
    Equal (fst (partition f s)) (filter f s).
  Parameter partition_spec2 : compatb f ->
    Equal (snd (partition f s)) (filter (fun x a => negb (f x a)) s).
  Parameter elements_spec1 : InA (fun p1 p2 => E.eq (fst p1) (fst p2) /\ snd p1 = snd p2) (k, v) (elements s) <-> MapsTo k v s.
  (** When compared with ordered sets, here comes the only
      property that is really weaker: *)
  Parameter elements_spec2w : NoDupA  (fun p1 p2 => E.eq (fst p1) (fst p2) /\ snd p1 = snd p2) (elements s).
  Parameter choose_spec1 : choose s = Some (k,v) -> MapsTo k v s.
  Parameter choose_spec2 : choose s = None -> Empty s.

  End Spec.

End WRawMaps.

(** From weak raw sets to weak usual sets *)

(*
Module WRaw2SetsOn (E:DecidableType)(M:WRawSets E) <: WSetsOn E.

 (** We avoid creating induction principles for the Record *)
 Local Unset Elimination Schemes.

 Definition key := E.t.

 Record t_ := Mkt {this :> M.t; is_ok : M.Ok this}.
 Definition t := t_.
 Arguments Mkt this {is_ok}.
 Hint Resolve is_ok : typeclass_instances.

 Definition In (x : key)(s : t) := M.In x s.(this).
 Definition Equal (s s' : t) := forall a : key, In a s <-> In a s'.
 Definition Subset (s s' : t) := forall a : key, In a s -> In a s'.
 Definition Empty (s : t) := forall a : key, ~ In a s.
 Definition For_all (P : key -> Prop)(s : t) := forall x, In x s -> P x.
 Definition Exists (P : key -> Prop)(s : t) := exists x, In x s /\ P x.

 Definition mem (x : key)(s : t) := M.mem x s.
 Definition add (x : key)(s : t) : t := Mkt (M.add x s).
 Definition remove (x : key)(s : t) : t := Mkt (M.remove x s).
 Definition singleton (x : key) : t := Mkt (M.singleton x).
 Definition union (s s' : t) : t := Mkt (M.union s s').
 Definition inter (s s' : t) : t := Mkt (M.inter s s').
 Definition diff (s s' : t) : t := Mkt (M.diff s s').
 Definition equal (s s' : t) := M.equal s s'.
 Definition subset (s s' : t) := M.subset s s'.
 Definition empty : t := Mkt M.empty.
 Definition is_empty (s : t) := M.is_empty s.
 Definition elements (s : t) : list key := M.elements s.
 Definition choose (s : t) : option key := M.choose s.
 Definition fold (A : Type)(f : key -> A -> A)(s : t) : A -> A := M.fold f s.
 Definition cardinal (s : t) := M.cardinal s.
 Definition filter (f : key -> bool)(s : t) : t := Mkt (M.filter f s).
 Definition for_all (f : key -> bool)(s : t) := M.for_all f s.
 Definition exists_ (f : key -> bool)(s : t) := M.exists_ f s.
 Definition partition (f : key -> bool)(s : t) : t * t :=
   let p := M.partition f s in (Mkt (fst p), Mkt (snd p)).

 Instance In_compat : Proper (E.eq==>eq==>iff) In.
 Proof. repeat red. intros; apply M.In_compat; congruence. Qed.

 Definition eq : t -> t -> Prop := Equal.

 Instance eq_equiv : Equivalence eq.
 Proof. firstorder. Qed.

 Definition eq_dec : forall (s s':t), { eq s s' }+{ ~eq s s' }.
 Proof.
  intros (s,Hs) (s',Hs').
  change ({M.Equal s s'}+{~M.Equal s s'}).
  destruct (M.equal s s') eqn:H; [left|right];
   rewrite <- M.equal_spec; congruence.
 Defined.


 Section Spec.
  Variable s s' : t.
  Variable x y : key.
  Variable f : key -> bool.
  Notation compatb := (Proper (E.eq==>Logic.eq)) (only parsing).

  Lemma mem_spec : mem x s = true <-> In x s.
  Proof. exact (@M.mem_spec _ _ _). Qed.
  Lemma equal_spec : equal s s' = true <-> Equal s s'.
  Proof. exact (@M.equal_spec _ _ _ _). Qed.
  Lemma subset_spec : subset s s' = true <-> Subset s s'.
  Proof. exact (@M.subset_spec _ _ _ _). Qed.
  Lemma empty_spec : Empty empty.
  Proof. exact M.empty_spec. Qed.
  Lemma is_empty_spec : is_empty s = true <-> Empty s.
  Proof. exact (@M.is_empty_spec _). Qed.
  Lemma add_spec : In y (add x s) <-> E.eq y x \/ In y s.
  Proof. exact (@M.add_spec _ _ _ _). Qed.
  Lemma remove_spec : In y (remove x s) <-> In y s /\ ~E.eq y x.
  Proof. exact (@M.remove_spec _ _ _ _). Qed.
  Lemma singleton_spec : In y (singleton x) <-> E.eq y x.
  Proof. exact (@M.singleton_spec _ _). Qed.
  Lemma union_spec : In x (union s s') <-> In x s \/ In x s'.
  Proof. exact (@M.union_spec _ _ _ _ _). Qed.
  Lemma inter_spec : In x (inter s s') <-> In x s /\ In x s'.
  Proof. exact (@M.inter_spec _ _ _ _ _). Qed.
  Lemma diff_spec : In x (diff s s') <-> In x s /\ ~In x s'.
  Proof. exact (@M.diff_spec _ _ _ _ _). Qed.
  Lemma fold_spec : forall (A : Type) (i : A) (f : key -> A -> A),
      fold f s i = fold_left (fun a e => f e a) (elements s) i.
  Proof. exact (@M.fold_spec _). Qed.
  Lemma cardinal_spec : cardinal s = length (elements s).
  Proof. exact (@M.cardinal_spec s _). Qed.
  Lemma filter_spec : compatb f ->
    (In x (filter f s) <-> In x s /\ f x = true).
  Proof. exact (@M.filter_spec _ _ _). Qed.
  Lemma for_all_spec : compatb f ->
    (for_all f s = true <-> For_all (fun x => f x = true) s).
  Proof. exact (@M.for_all_spec _ _). Qed.
  Lemma exists_spec : compatb f ->
    (exists_ f s = true <-> Exists (fun x => f x = true) s).
  Proof. exact (@M.exists_spec _ _). Qed.
  Lemma partition_spec1 : compatb f -> Equal (fst (partition f s)) (filter f s).
  Proof. exact (@M.partition_spec1 _ _). Qed.
  Lemma partition_spec2 : compatb f ->
      Equal (snd (partition f s)) (filter (fun x => negb (f x)) s).
  Proof. exact (@M.partition_spec2 _ _). Qed.
  Lemma elements_spec1 : InA E.eq x (elements s) <-> In x s.
  Proof. exact (@M.elements_spec1 _ _). Qed.
  Lemma elements_spec2w : NoDupA E.eq (elements s).
  Proof. exact (@M.elements_spec2w _ _). Qed.
  Lemma choose_spec1 : choose s = Some x -> In x s.
  Proof. exact (@M.choose_spec1 _ _). Qed.
  Lemma choose_spec2 : choose s = None -> Empty s.
  Proof. exact (@M.choose_spec2 _). Qed.

 End Spec.

End WRaw2SetsOn.

Module WRaw2Sets (D:DecidableType)(M:WRawSets D) <: WSets with Module E := D.
  Module E := D.
  Include WRaw2SetsOn D M.
End WRaw2Sets.

(** Same approach for ordered sets *)

Module Type RawSets (E : OrderedType).
  Include WRawSets E <+ HasOrdOps <+ HasLt <+ IsStrOrder.

  Section Spec.
  Variable s s': t.
  Variable x y : key.

  (** Specification of [compare] *)
  Parameter compare_spec : forall `{Ok s, Ok s'}, CompSpec eq lt s s' (compare s s').

  (** Additional specification of [elements] *)
  Parameter elements_spec2 : forall `{Ok s}, sort E.lt (elements s).

  (** Specification of [min_key] *)
  Parameter min_key_spec1 : min_key s = Some x -> In x s.
  Parameter min_key_spec2 : forall `{Ok s}, min_key s = Some x -> In y s -> ~ E.lt y x.
  Parameter min_key_spec3 : min_key s = None -> Empty s.

  (** Specification of [max_key] *)
  Parameter max_key_spec1 : max_key s = Some x -> In x s.
  Parameter max_key_spec2 : forall `{Ok s}, max_key s = Some x -> In y s -> ~ E.lt x y.
  Parameter max_key_spec3 : max_key s = None -> Empty s.

  (** Additional specification of [choose] *)
  Parameter choose_spec3 : forall `{Ok s, Ok s'},
    choose s = Some x -> choose s' = Some y -> Equal s s' -> E.eq x y.

  End Spec.

End RawSets.

(** From Raw to usual sets *)

Module Raw2SetsOn (O:OrderedType)(M:RawSets O) <: SetsOn O.
  Include WRaw2SetsOn O M.

  Definition compare (s s':t) := M.compare s s'.
  Definition min_key (s:t) : option key := M.min_key s.
  Definition max_key (s:t) : option key := M.max_key s.
  Definition lt (s s':t) := M.lt s s'.

  (** Specification of [lt] *)
  Instance lt_strorder : StrictOrder lt.
  Proof. constructor ; unfold lt; red.
    unfold complement. red. intros. apply (irreflexivity H).
    intros. transitivity y; auto.
  Qed.

  Instance lt_compat : Proper (eq==>eq==>iff) lt.
  Proof.
  repeat red. unfold eq, lt.
  intros (s1,p1) (s2,p2) E (s1',p1') (s2',p2') E'; simpl.
  change (M.eq s1 s2) in E.
  change (M.eq s1' s2') in E'.
  rewrite E,E'; intuition.
  Qed.

  Section Spec.
  Variable s s' s'' : t.
  Variable x y : key.

  Lemma compare_spec : CompSpec eq lt s s' (compare s s').
  Proof. unfold compare; destruct (@M.compare_spec s s' _ _); auto. Qed.

  (** Additional specification of [elements] *)
  Lemma elements_spec2 : sort O.lt (elements s).
  Proof. exact (@M.elements_spec2 _ _). Qed.

  (** Specification of [min_key] *)
  Lemma min_key_spec1 : min_key s = Some x -> In x s.
  Proof. exact (@M.min_key_spec1 _ _). Qed.
  Lemma min_key_spec2 : min_key s = Some x -> In y s -> ~ O.lt y x.
  Proof. exact (@M.min_key_spec2 _ _ _ _). Qed.
  Lemma min_key_spec3 : min_key s = None -> Empty s.
  Proof. exact (@M.min_key_spec3 _). Qed.

  (** Specification of [max_key] *)
  Lemma max_key_spec1 : max_key s = Some x -> In x s.
  Proof. exact (@M.max_key_spec1 _ _). Qed.
  Lemma max_key_spec2 : max_key s = Some x -> In y s -> ~ O.lt x y.
  Proof. exact (@M.max_key_spec2 _ _ _ _). Qed.
  Lemma max_key_spec3 : max_key s = None -> Empty s.
  Proof. exact (@M.max_key_spec3 _). Qed.

  (** Additional specification of [choose] *)
  Lemma choose_spec3 :
    choose s = Some x -> choose s' = Some y -> Equal s s' -> O.eq x y.
  Proof. exact (@M.choose_spec3 _ _ _ _ _ _). Qed.

  End Spec.

End Raw2SetsOn.

Module Raw2Sets (O:OrderedType)(M:RawSets O) <: Sets with Module E := O.
  Module E := O.
  Include Raw2SetsOn O M.
End Raw2Sets.


(** It is in fact possible to provide an ordering on sets with
    very little information on them (more or less only the [In]
    predicate). This generic build of ordering is in fact not
    used for the moment, we rather use a simplier version
    dedicated to sets-as-sorted-lists, see [MakeListOrdering].
*)

Module Type IN (O:OrderedType).
 Parameter Inline t : Type.
 Parameter Inline In : O.t -> t -> Prop.
 Declare Instance In_compat : Proper (O.eq==>eq==>iff) In.
 Definition Equal s s' := forall x, In x s <-> In x s'.
 Definition Empty s := forall x, ~In x s.
End IN.

Module MakeSetOrdering (O:OrderedType)(Import M:IN O).
 Module Import MO := OrderedTypeFacts O.

 Definition eq : t -> t -> Prop := Equal.

 Instance eq_equiv : Equivalence eq.
 Proof. firstorder. Qed.

 Instance : Proper (O.eq==>eq==>iff) In.
 Proof.
 intros x x' Ex s s' Es. rewrite Ex. apply Es.
 Qed.

 Definition Below x s := forall y, In y s -> O.lt y x.
 Definition Above x s := forall y, In y s -> O.lt x y.

 Definition EquivBefore x s s' :=
   forall y, O.lt y x -> (In y s <-> In y s').

 Definition EmptyBetween x y s :=
   forall z, In z s -> O.lt z y -> O.lt z x.

 Definition lt s s' := exists x, EquivBefore x s s' /\
   ((In x s' /\ Below x s) \/
    (In x s  /\ exists y, In y s' /\ O.lt x y /\ EmptyBetween x y s')).

 Instance : Proper (O.eq==>eq==>eq==>iff) EquivBefore.
 Proof.
  unfold EquivBefore. intros x x' E s1 s1' E1 s2 s2' E2.
  setoid_rewrite E; setoid_rewrite E1; setoid_rewrite E2; intuition.
 Qed.

 Instance : Proper (O.eq==>eq==>iff) Below.
 Proof.
  unfold Below. intros x x' Ex s s' Es.
  setoid_rewrite Ex; setoid_rewrite Es; intuition.
 Qed.

 Instance : Proper (O.eq==>eq==>iff) Above.
 Proof.
  unfold Above. intros x x' Ex s s' Es.
  setoid_rewrite Ex; setoid_rewrite Es; intuition.
 Qed.

 Instance : Proper (O.eq==>O.eq==>eq==>iff) EmptyBetween.
 Proof.
  unfold EmptyBetween. intros x x' Ex y y' Ey s s' Es.
  setoid_rewrite Ex; setoid_rewrite Ey; setoid_rewrite Es; intuition.
 Qed.

 Instance lt_compat : Proper (eq==>eq==>iff) lt.
 Proof.
  unfold lt. intros s1 s1' E1 s2 s2' E2.
  setoid_rewrite E1; setoid_rewrite E2; intuition.
 Qed.

 Instance lt_strorder : StrictOrder lt.
 Proof.
  split.
  (* irreflexive *)
  intros s (x & _ & [(IN,Em)|(IN & y & IN' & LT & Be)]).
  specialize (Em x IN); order.
  specialize (Be x IN LT); order.
  (* transitive *)
  intros s1 s2 s3 (x & EQ & [(IN,Pre)|(IN,Lex)])
                  (x' & EQ' & [(IN',Pre')|(IN',Lex')]).
  (* 1) Pre / Pre --> Pre *)
  assert (O.lt x x') by (specialize (Pre' x IN); auto).
  exists x; split.
  intros y Hy; rewrite <- (EQ' y); auto; order.
  left; split; auto.
  rewrite <- (EQ' x); auto.
  (* 2) Pre / Lex *)
  elim_compare x x'.
  (* 2a) x=x' --> Pre *)
  destruct Lex' as (y & INy & LT & Be).
  exists y; split.
  intros z Hz. split; intros INz.
   specialize (Pre z INz). rewrite <- (EQ' z), <- (EQ z); auto; order.
   specialize (Be z INz Hz). rewrite (EQ z), (EQ' z); auto; order.
  left; split; auto.
  intros z Hz. transitivity x; auto; order.
  (* 2b) x<x' --> Pre *)
  exists x; split.
  intros z Hz. rewrite <- (EQ' z) by order; auto.
  left; split; auto.
  rewrite <- (EQ' x); auto.
  (* 2c) x>x' --> Lex *)
  exists x'; split.
  intros z Hz. rewrite (EQ z) by order; auto.
  right; split; auto.
  rewrite (EQ x'); auto.
  (* 3) Lex / Pre --> Lex *)
  destruct Lex as (y & INy & LT & Be).
  specialize (Pre' y INy).
  exists x; split.
  intros z Hz. rewrite <- (EQ' z) by order; auto.
  right; split; auto.
  exists y; repeat split; auto.
  rewrite <- (EQ' y); auto.
  intros z Hz LTz; apply Be; auto. rewrite (EQ' z); auto; order.
  (* 4) Lex / Lex *)
  elim_compare x x'.
  (* 4a) x=x' --> impossible *)
  destruct Lex as (y & INy & LT & Be).
  setoid_replace x with x' in LT; auto.
  specialize (Be x' IN' LT); order.
  (* 4b) x<x' --> Lex *)
  exists x; split.
  intros z Hz. rewrite <- (EQ' z) by order; auto.
  right; split; auto.
  destruct Lex as (y & INy & LT & Be).
  elim_compare y x'.
   (* 4ba *)
   destruct Lex' as (y' & Iny' & LT' & Be').
   exists y'; repeat split; auto. order.
   intros z Hz LTz. specialize (Be' z Hz LTz).
    rewrite <- (EQ' z) in Hz by order.
    apply Be; auto. order.
   (* 4bb *)
   exists y; repeat split; auto.
   rewrite <- (EQ' y); auto.
   intros z Hz LTz. apply Be; auto. rewrite (EQ' z); auto; order.
   (* 4bc*)
   assert (O.lt x' x) by auto. order.
  (* 4c) x>x' --> Lex *)
  exists x'; split.
  intros z Hz. rewrite (EQ z) by order; auto.
  right; split; auto.
  rewrite (EQ x'); auto.
 Qed.

 Lemma lt_empty_r : forall s s', Empty s' -> ~ lt s s'.
 Proof.
  intros s s' Hs' (x & _ & [(IN,_)|(_ & y & IN & _)]).
  elim (Hs' x IN).
  elim (Hs' y IN).
 Qed.

 Definition Add x s s' := forall y, In y s' <-> O.eq x y \/ In y s.

 Lemma lt_empty_l : forall x s1 s2 s2',
  Empty s1 -> Above x s2 -> Add x s2 s2' -> lt s1 s2'.
 Proof.
  intros x s1 s2 s2' Em Ab Ad.
  exists x; split.
  intros y Hy; split; intros IN.
  elim (Em y IN).
  rewrite (Ad y) in IN; destruct IN as [EQ|IN]. order.
  specialize (Ab y IN). order.
  left; split.
  rewrite (Ad x). now left.
  intros y Hy. elim (Em y Hy).
 Qed.

 Lemma lt_add_lt : forall x1 x2 s1 s1' s2 s2',
   Above x1 s1 -> Above x2 s2 -> Add x1 s1 s1' -> Add x2 s2 s2' ->
   O.lt x1 x2 -> lt s1' s2'.
  Proof.
  intros x1 x2 s1 s1' s2 s2' Ab1 Ab2 Ad1 Ad2 LT.
  exists x1; split; [ | right; split]; auto.
  intros y Hy. rewrite (Ad1 y), (Ad2 y).
  split; intros [U|U]; try order.
  specialize (Ab1 y U). order.
  specialize (Ab2 y U). order.
  rewrite (Ad1 x1); auto with *.
  exists x2; repeat split; auto.
  rewrite (Ad2 x2); now left.
  intros y. rewrite (Ad2 y). intros [U|U]. order.
  specialize (Ab2 y U). order.
  Qed.

  Lemma lt_add_eq : forall x1 x2 s1 s1' s2 s2',
   Above x1 s1 -> Above x2 s2 -> Add x1 s1 s1' -> Add x2 s2 s2' ->
   O.eq x1 x2 -> lt s1 s2 -> lt s1' s2'.
  Proof.
  intros x1 x2 s1 s1' s2 s2' Ab1 Ab2 Ad1 Ad2 Hx (x & EQ & Disj).
  assert (O.lt x1 x).
   destruct Disj as [(IN,_)|(IN,_)]; auto. rewrite Hx; auto.
  exists x; split.
  intros z Hz. rewrite (Ad1 z), (Ad2 z).
  split; intros [U|U]; try (left; order); right.
  rewrite <- (EQ z); auto.
  rewrite (EQ z); auto.
  destruct Disj as [(IN,Em)|(IN & y & INy & LTy & Be)].
  left; split; auto.
  rewrite (Ad2 x); auto.
  intros z. rewrite (Ad1 z); intros [U|U]; try specialize (Ab1 z U); auto; order.
  right; split; auto.
  rewrite (Ad1 x); auto.
  exists y; repeat split; auto.
  rewrite (Ad2 y); auto.
  intros z. rewrite (Ad2 z). intros [U|U]; try specialize (Ab2 z U); auto; order.
  Qed.

End MakeSetOrdering.


Module MakeListOrdering (O:OrderedType).
 Module MO:=OrderedTypeFacts O.

 Local Notation t := (list O.t).
 Local Notation In := (InA O.eq).

 Definition eq s s' := forall x, In x s <-> In x s'.

 Instance eq_equiv : Equivalence eq := _.

 Inductive lt_list : t -> t -> Prop :=
    | lt_nil : forall x s, lt_list nil (x :: s)
    | lt_cons_lt : forall x y s s',
        O.lt x y -> lt_list (x :: s) (y :: s')
    | lt_cons_eq : forall x y s s',
        O.eq x y -> lt_list s s' -> lt_list (x :: s) (y :: s').
 Hint Constructors lt_list.

 Definition lt := lt_list.
 Hint Unfold lt.

 Instance lt_strorder : StrictOrder lt.
 Proof.
 split.
 (* irreflexive *)
 assert (forall s s', s=s' -> ~lt s s').
  red; induction 2.
  discriminate.
  inversion H; subst.
  apply (StrictOrder_Irreflexive y); auto.
  inversion H; subst; auto.
 intros s Hs; exact (H s s (eq_refl s) Hs).
 (* transitive *)
 intros s s' s'' H; generalize s''; clear s''; elim H.
 intros x l s'' H'; inversion_clear H'; auto.
 intros x x' l l' E s'' H'; inversion_clear H'; auto.
 constructor 2. transitivity x'; auto.
 constructor 2. rewrite <- H0; auto.
 intros.
 inversion_clear H3.
 constructor 2. rewrite H0; auto.
 constructor 3; auto. transitivity y; auto. unfold lt in *; auto.
 Qed.

 Instance lt_compat' :
  Proper (eqlistA O.eq==>eqlistA O.eq==>iff) lt.
 Proof.
 apply proper_sym_impl_iff_2; auto with *.
 intros s1 s1' E1 s2 s2' E2 H.
 revert s1' E1 s2' E2.
 induction H; intros; inversion_clear E1; inversion_clear E2.
 constructor 1.
 constructor 2. MO.order.
 constructor 3. MO.order. unfold lt in *; auto.
 Qed.

 Lemma eq_cons :
  forall l1 l2 x y,
  O.eq x y -> eq l1 l2 -> eq (x :: l1) (y :: l2).
 Proof.
  unfold eq; intros l1 l2 x y Exy E12 z.
  split; inversion_clear 1.
  left; MO.order. right; rewrite <- E12; auto.
  left; MO.order. right; rewrite E12; auto.
 Qed.
 Hint Resolve eq_cons.

 Lemma cons_CompSpec : forall c x1 x2 l1 l2, O.eq x1 x2 ->
  CompSpec eq lt l1 l2 c -> CompSpec eq lt (x1::l1) (x2::l2) c.
 Proof.
  destruct c; simpl; inversion_clear 2; auto with relations.
 Qed.
 Hint Resolve cons_CompSpec.

End MakeListOrdering.

*)
