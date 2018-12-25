open Evaluator


(* if m then {z=z+1} else {z=2} *)
let exp= If ("m",
                Bnvar ( AsgnV ("z", AddInt ( Var "z",(Value (Int 1)) ))),
                Bnvar ( AsgnV ("z", Value (Int 2) ))
            );;


(*-------------------------------------------------------------------------------------*)
(*
class A extends Object
    {
        int f1;
        #
        int m1(int a, int b) { (int c)
        c=a+b;this.f1=this.f1+c;c};
    }
*)



(* classDecl *)
let a  = ("A", "Object",

        (* fields Declaration List *)
        [ (Tprim Tint),"f1"],

        (* methods Declaration List *)
        [
            (
                (Tprim Tint), "m1",

                (* parameters List *)
                [
                    (Tprim Tint, "a" );
                    (Tprim Tint, "b" )
                ],

                (* body *)
                Blk ( Bvar (  (Tprim Tint), "c",   

                        (* Seq(  exp, Seq ( exp, exp)  ) *)
                        Seq(  AsgnV ("c", AddInt ( Var "a", Var "b"))   ,
                            Seq ( 
                                AsgnF("this","f1", AddInt( Vfld ("this","f1"), Var "c") ),
                                (Var "c")
                            ) 
                        )
                    )
                )  
            )         
        ]

    );;

(*-------------------------------------------------------------------------------------*)

(*
class B extends A
{
    A f2;
    #
    A m2(A x, A y) {
        (A z) 
            { (int n)
                n=x.m1(1,2)-y.m1(2,1);
                {
                    (bool m) m=(x.f1-y.f1)>n;
    
                    if m then {z=new A(m)} else {z=new A(n)}
                }
            };
        this.f2=z;z
    }
}
*)


(* classDecl *)
let b = ("B", "A",

            (* fields Declaration List *)
            [
               (Tclass "A", "f2") 
            ],


            (* methods Declaration List *)
            [
                (
                    (Tclass "A") , "m2",

                    (* parameters List *)
                    [
                        ( Tclass "A", "x");
                        ( Tclass "A", "y")
                    ],

                    (* body *)
                   Blk (
                        Bvar(
                            (Tclass "A"), "z",
                            Seq ( 
                                Blk(
                                    Bvar( 
                                        (Tprim Tint), "n",
                                        Seq( 
                                            AsgnV( "n",
                                                DiffInt (
                                                    MthCall ("x","m1", [ Value (Int 1);  Value (Int 2)  ]),
                                                    MthCall ("y","m1", [ Value (Int 2); Value (Int 1)  ])
                                                )
                                            ),
                                            Blk(
                                                Bvar(
                                                    (Tprim Tbool), "m",
                                                    Seq(
                                                        AsgnV("m", 
                                                            Gt(    
                                                                DiffInt(  Vfld("x", "f1"), Vfld("y", "f1")),
                                                                (Var "n")
                                                            )                                                        
                                                        ) 
                                                        , 
                                                        If ("m",
                                                            Bnvar ( AsgnV ("z", NewObj ("A", [ (Var "m") ] ))  ),
                                                            Bnvar ( AsgnV ("z", NewObj ("A", [ (Var "n") ] ) ))
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                ),
                                Seq(
                                    AsgnF("this","f2", (Var "z") ),
                                    (Var "z")
                                )
                            )
                        )
                   )
                )
            ]
 );;

 (*-------------------------------------------------------------------------------------*)

(*
Class Main extends Object
{ #
    Void main(){ 
        (B o1) o1=new B(0,null);
        { 
            (A o2) o2=new A(2);
            {  
                (A o3) o3=new A(3);
                o2 =o1.m2(o2,o3)
            }
        }
    }
}
*)
(*class decl*)
let main=("Main", "Object",
    (*fields decl list*)
    [],
    (*methods decl list*)
    [
        (Tprim Tvoid), "main", 
        (*param list*)
        [],
        (*body*)
        Blk(
            Bvar( 
                (Tclass "B"), "o1",
                Seq(
                    AsgnV( "o1", NewObj ( "B", [ Value (Int 0); Value (Vnull)])),
                    Blk(
                        Bvar( (Tclass "A"), "o2",
                            Seq (
                                AsgnV("o2", NewObj ( "A", [Value (Int 2) ])), 
                                Blk(
                                    Bvar(
                                        (Tclass "A"), "o3",
                                        Seq(
                                            AsgnV("o3", NewObj ("A", [(Value (Int 3))])),
                                            AsgnV("o2", MthCall ("o1", "m2", [ ( Var "o2"); (Var "o3")]))
                                        )
                                    )
                                )
                            ) 
                        )
                    )
                )
            )
        )
    ]
);;

let myProgram = [ ("A",a ); ("B",b); ("Main", main)  ];;

(*-------------------------------------------------------------------------------------*)


 (* *********************************         EXCEPTIONS          *********************************       *)


exception VariableNotDefinedException of string;;
exception ClassNotDefinedException of string;;
exception TypesDontMatchException of string;;
exception FieldNotFoundException of string;;
exception IncorrectVariableType of string;;
exception Exception of string;;



 (* *********************************         PRINTING FUNCTIONS          *********************************       *)


let print_typ givenType = match givenType with
    | (Tprim Tint) -> Printf.printf "int \n"
    | (Tprim Tfloat) -> Printf.printf "float \n"
    | (Tprim Tbool) -> Printf.printf "bool \n"
    | (Tprim Tvoid) -> Printf.printf "void \n"
    | (Tclass className) -> Printf.printf "Class: %s \n" className
    | (Tbot) -> Printf.printf "bottom \n"
    


 let rec print_field_list list = match list with
    | [] -> Printf.printf "\n"
    | h::t -> match h with 
        | (fName, fType) ->  Printf.printf "Field name: %s " fName;  (print_typ fType);  Printf.printf " \n"; (print_field_list t);;

       

(*-------------------------------------------------------------------------------------*)

 (* *********************************         SUBTYPING          *********************************       *)


let rec existsClassInProgram program className = match program with
    | [] -> false
    | _ when className="Object" -> true
    | head::tail -> match head with 
        | (cName, cDeclaration) when cName = className ->  true 
        | (_, classDeclaration) -> (existsClassInProgram tail className);;


(* B extends A => subtype B A = true *)
(* needed wholeProgram parameter in order to search again in the whole program whether class B is a subtype of a subtype of class A *)
 let rec isSubclassRec wholeProgram program className1 className2 = match program, className1, className2 with
    | _, c1,c2 when  c1 = c2  -> true
    | [],_,_ -> false
    | head::tail,c1,c2 -> match head with
        | (className, classDecl) when c1 = className -> (match classDecl with 
            | (_, baseClass, _, _) -> if baseClass = c2 then true else (isSubclassRec wholeProgram wholeProgram baseClass c2) )
        | (_ , _)-> ( isSubclassRec wholeProgram tail c1 c2 ) ;;

let isSubclass program className1 className2 = (isSubclassRec program program className1 className2);;



let subtype program type1 type2 = match type1, type2 with
    | Tprim(Tint), Tprim(Tint) -> true
    | Tprim(Tfloat), Tprim(Tfloat) -> true
    | Tprim(Tbool), Tprim(Tbool) -> true
    | Tprim(Tvoid), Tprim(Tvoid) -> true
    | Tclass(className), Tclass("Object") -> (existsClassInProgram program className)
    | Tbot, Tclass(className) -> (existsClassInProgram program className)
    | Tclass(className1), Tclass(className2) -> (existsClassInProgram program className1) && (existsClassInProgram program className2) && (isSubclass program className1 className2 )
    | _ , _ -> false;;


Printf.printf "\n \n----------- SUBTYPING TESTS -------------\n \n";;

(* Testing FUNCTION: existsClassInProgram *)
let response = (existsClassInProgram myProgram "Main");;
Printf.printf "Exists in program: %b\n" response;;

(* Testing FUNCTION: subtype *)
let subtypeResponse1 =  subtype myProgram (Tclass "B") (Tclass "Object") ;;
Printf.printf "%b --> subtype: B is subtype of Object \n" subtypeResponse1;;
let subtypeResponse2 =  subtype myProgram Tbot (Tclass "Main") ;;
Printf.printf "%b --> subtype: bottom is subtype of Main \n" subtypeResponse2;;
let subtypeResponse3=  subtype myProgram (Tclass "B") (Tclass "A") ;;
Printf.printf "%b --> subtype: B is subtype of A \n" subtypeResponse3;;
let subtypeResponse4=  subtype myProgram (Tclass "Main") (Tclass "A") ;;
Printf.printf "%b --> subtype: Main is subtype of A \n" subtypeResponse4;;


 (* *********************************         FIELDLIST          *********************************       *)



(* -------------------------------------------------------------------------------------------------------- *)

(*doesn't work*)
(* 
let rec fieldlist program className = match program with
    | [] -> []
    | h::t -> match h with 
        | (cName, cDecl) when cName = className -> 
           ( match cDecl with (_,b,f,_) ->List.append f ( fieldlist program b ) )
        | (_ , cDecl) -> (fieldlist t className);;
*)

(*transform field list from (type,string) to (string,type) *)
let rec reverse_list lst = match lst with
    | [] -> []
    | h::t -> match h with 
         (fType,fName) -> (fName,fType):: (reverse_list t);;

let rec fieldlist program className = match program with
    | [] -> []
    | h::t -> match h with 
        | (cName, cDecl) when cName = className -> 
           ( match cDecl with (_,_,f,_) -> (reverse_list f) )
        | (_ , cDecl) -> (fieldlist t className);;

let rec getBaseClass program className = match program with 
    | [] -> "" 
    | h::t -> match h with 
        | (cName, cDecl) when cName = className ->
            (match cDecl with (_,base,_,_) -> base)
        | (_, cDecl) -> (getBaseClass t className);;

let rec getFields program className = match className with
  | "Object" -> []
  | aux -> List.append (fieldlist program aux) (getFields program (getBaseClass program aux ));;
 (* 
    | aux -> (fieldList program aux) ;; (*varianta 2*)
*)




Printf.printf "\n \n----------- FIELDLIST TESTS -------------\n \n";;

let ast = [("A",a);("B",b);("Main",main)];;

let result1=(getFields ast "A");; (*list of evaluator.typ and string *)
Printf.printf "\t  Field list of classss A: \n";;
(print_field_list result1);;


let result2=(getFields ast "B");; (*list of evaluator.typ and string *)
Printf.printf "\t  Field list of classss B: \n";;
(print_field_list result2);;



(*---------------------Well-typed expressions------------- *)
(* looks for a field with given name in env= list of (string*type) and returns its type*)


  
let getClassNameFromClassType classType =  match classType with 
    | Tclass className -> className
    | _ -> raise (Exception "The provided parameter is not of type Tclass");;
  

let rec typeFromEnv env vName = match env with
    | [] -> raise (VariableNotDefinedException vName)
    | h::t -> match h with
        | (name,vType) when name=vName -> vType
        | (_,vType) -> (typeFromEnv t vName);; 
        


let rec fieldTypeFromClass fieldList fieldName = match fieldList with 
|   [] -> raise (FieldNotFoundException fieldName)
    | h::t -> match h with
        | (name,vType) when name=fieldName -> vType
        | (_,vType) -> (fieldTypeFromClass t fieldName);; 

  let rec wellTypedExpr program environment expCrt = match expCrt with
    | Value (Vnull) -> Tbot
    | Value (Int v ) -> Tprim Tint 
    | Value (Float v ) -> Tprim Tfloat
    | Value (Vvoid) -> Tprim Tvoid
    | Value (Bool v ) -> Tprim Tbool 
    | Var v -> typeFromEnv environment v

    (*value field= classInstanceName + fieldName *)
    (* First we get the type of classInstanceN, that type must be a class
    Second we get the type of the field fieldN *)
            (* Won't work for (Vfld "this" "fieldName") *)
    | Vfld (classInstanceN, fieldN) -> (
                            let className = (getClassNameFromClassType (typeFromEnv environment classInstanceN) )
                                in 
                                ( let classFields = ( getFields program className )
                                    in (fieldTypeFromClass classFields fieldN)  ) 
                            )

    | AsgnV (varN,exp) -> (
        let varType= ( wellTypedExpr program environment (Var varN)) and expType= (wellTypedExpr program environment exp) in
        if (subtype program expType varType ) then
            (Tprim Tvoid)
        else 
            raise (TypesDontMatchException "@Assign var")
    )

    | AsgnF (classInstanceN, fieldN, exp) -> 
    
        let className = (getClassNameFromClassType (typeFromEnv environment classInstanceN) ) in
        if (existsClassInProgram program className) then
        (
            let fieldType = (typeFromEnv (getFields program className) fieldN) 
                and expType= (wellTypedExpr program environment exp) in
            if (subtype program expType fieldType) then
                (Tprim Tvoid)
            else
                raise (TypesDontMatchException "@Assign field")
        )
        else raise (ClassNotDefinedException className)
    
    | Blk (Bvar(typ,var,exp)) -> (wellTypedExpr program ((var,typ)::environment) exp)
    | Blk (Bnvar exp) -> (wellTypedExpr program environment exp)
    | Seq (_,exp2) -> (wellTypedExpr program environment exp2)
    
    (* | If of string * blkExp * blkExp|   ->  exp1 =then blk, exp2 = else blk *)
    
    (* | If (varName, blk1, blk2 ) ->
        if ( subtype program (typeFromEnv environment varName) (Tprim Tbool) ) then raise (Exception "e bineeeeeeeeeee")
        else (
            raise (IncorrectVariableType "A subtype of bool was expected") 
        ) *)


    | AddInt ( exp1, exp2) | MulInt ( exp1, exp2) | DivInt ( exp1, exp2)  | DiffInt ( exp1, exp2)  -> 
        let typeExp1 = (wellTypedExpr program environment exp1) and typeExp2 = (wellTypedExpr program environment exp2)
        in 
        if (  (subtype program typeExp1 (Tprim Tint)) && (subtype program typeExp2 (Tprim Tint)) )
            then (Tprim Tint)
        else 
            raise (TypesDontMatchException "Subtypes of int were expected for optint")
    
     | AddFloat ( exp1, exp2) | MulFloat ( exp1, exp2) | DivFloat ( exp1, exp2)  | DiffFloat ( exp1, exp2)  -> 
        let typeExp1 = (wellTypedExpr program environment exp1) and typeExp2 = (wellTypedExpr program environment exp2)
        in 
        if (  (subtype program typeExp1 (Tprim Tfloat)) && (subtype program typeExp2 (Tprim Tfloat)) )
            then (Tprim Tfloat)
        else 
            raise (TypesDontMatchException "Subtypes of float were expected for optfloat")

    | And ( exp1, exp2) | Or ( exp1, exp2)  -> 
        let typeExp1 = (wellTypedExpr program environment exp1) and typeExp2 = (wellTypedExpr program environment exp2)
        in 
        if (  (subtype program typeExp1 (Tprim Tbool)) && (subtype program typeExp2 (Tprim Tbool)) )
            then (Tprim Tbool)
        else 
            raise (TypesDontMatchException "Subtypes of bool were expected for AND/OR operators")

    | Not ( exp )  -> 
        let typeExp1 = (wellTypedExpr program environment exp)
        in 
        if (  (subtype program typeExp1 (Tprim Tbool)) )
            then (Tprim Tbool)
        else 
            raise (TypesDontMatchException "Subtype of bool was expected for NOT operator")

    | Eq ( exp1, exp2 ) |  NEq ( exp1, exp2 ) |  Ge ( exp1, exp2 ) |  Gt ( exp1, exp2 ) |  Le ( exp1, exp2 ) |  Lt ( exp1, exp2 ) ->
        let typeExp1 = (wellTypedExpr program environment exp1) and typeExp2 = (wellTypedExpr program environment exp2) in

            if ( not ( (subtype program typeExp1 typeExp2) && (subtype program typeExp2 typeExp1) ) ) then
                raise (TypesDontMatchException "The exp types should be subtypes of each other")
            else
            (
                match typeExp1, typeExp2 with 
                    | (Tclass class1),(Tclass class2) when ((existsClassInProgram program class1) || (existsClassInProgram program class2)  ) ->   raise (TypesDontMatchException "The exp types shouldn't be declared classes")
                    | (Tclass class1) , _ when (existsClassInProgram program class1) ->  raise (TypesDontMatchException "The exp types shouldn't be declared classes")
                    | _ , (Tclass class2) when (existsClassInProgram program class2) ->  raise (TypesDontMatchException "The exp types shouldn't be declared classes")
                    | _ , _ -> (Tprim Tbool) 
            )

    | _ -> raise (Exception " DELETE ME ") ;;
   
   
Printf.printf "\n \n----------- WELL-TYPED EXPRESSIONS TESTS -------------\n \n";;

let env =  [("f2",(Tclass "A"));("f1",(Tprim Tint)); ( "z", (Tprim Tint) ); ("m", (Tprim Tbool) )];; 

Printf.printf "wellTypedExpr ast env (Value (Bool true))   :  ";;
print_typ ( wellTypedExpr ast env (Value (Bool true)));;

Printf.printf "wellTypedExpr (Var 'f1')   :  ";;
print_typ (wellTypedExpr myProgram env (Var "f1"));;

Printf.printf "wellTypedExpr (Var 'f2')   :  ";;
print_typ (wellTypedExpr myProgram env (Var "f2"));;

(* 
    A f2;
    f2.f1 has type int
    f2 is instace of class A => we copmpute ValueField f1 of instance f2 
 *)

Printf.printf "wellTypedExpr (Vfld 'f2' 'f1')   :  ";;
print_typ (wellTypedExpr myProgram env (Vfld ("f2","f1")));;


Printf.printf "wellTypedExpr (AsgnV ('z', Value (Int 1)) )  :  ";;
print_typ (wellTypedExpr myProgram env (AsgnV ("z", Value (Int 1)) ));; 

Printf.printf "wellTypedExpr (AsgnF('f2','f1', Value (Int 1))  ) :  ";;
print_typ (wellTypedExpr myProgram env (AsgnF("f2","f1", Value (Int 1)) ));; 

Printf.printf "wellTypedExpr (Blk(Bvar ( (Tprim Tint), 'c',(AsgnV ('c', Value (Int 1)) ) )) ) :";;
print_typ (wellTypedExpr myProgram env (Blk(Bvar ( (Tprim Tint), "c",(AsgnV ("c", Value (Int 1)) ) ))   ));; 

Printf.printf "wellTypedExpr (Blk(Bnvar (AsgnV ('z', Value (Int 1)) )) ) :";;
print_typ (wellTypedExpr myProgram env (Blk(Bnvar (AsgnV ("z", Value (Int 1)) ))  ));; 

Printf.printf "wellTypedExpr (Seq ( AsgnV ('z', Value (Int 1)) , AsgnF ('f2','f1', Value (Int 1))  ) ) :";;
print_typ (wellTypedExpr myProgram env (Seq (  AsgnV ("z", Value (Int 1)) , AsgnF ("f2","f1", Value (Int 1))  )  ));; 



        (* Uncomment this when wellTypedExp is implemented for If stmt *)

(* let ifStmt = If ("m",
        Bnvar ( (AsgnV ("z", Value (Int 1)) )),
        Bnvar ( (AsgnF("f2","f1", Value (Int 1))  ) )
);;

Printf.printf "wellTypedExpr ( If ('m',
        Bnvar ( (AsgnV ('z', Value (Int 1)) )),
        Bnvar ( (AsgnF('f2','f1', Value (Int 1))  ) )) 
)";;
print_typ (wellTypedExpr myProgram env ifStmt ) ;;  *)

Printf.printf "wellTypedExpr (AddInt ( Var 'z',(Value (Int 1)) ) ) : ";;
print_typ (wellTypedExpr myProgram env (AddInt ( Var "z",(Value (Int 1)) )));; 

Printf.printf "wellTypedExpr (And ( Var 'm', Var 'm') ) :";;
print_typ (wellTypedExpr myProgram env (And ( Var "m", Var "m") ));; 

Printf.printf "wellTypedExpr ( Gt ((Var 'z'), (Vfld 'f2' 'f1')) ) : ";;
print_typ (wellTypedExpr myProgram env (Gt ( Var "z" , Vfld ("f2", "f1")    ))) ;; 



Printf.printf "\n \n----------- *********************** -------------\n \n";;