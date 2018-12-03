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
let exp3=("Main", "Object",
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
                                            AsgnV( "o3", NewObj ("A", [(Value (Int 3))])),
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
(*-------------------------------------------------------------------------------------*)





let rec existsClassInProgram program className =  match program with
    | [] -> false
    | h::t -> match h with 
        | (cName, cDeclaration) when cName = className ->  true 
        | (_, classDeclaration) -> (existsClassInProgram t className);;


(* todo incomplete!! *)
let subtype program type1 type2 = match type1 type2 with
    | Tprim(Tint), Tprim(Tint) -> true
    | Tprim(Tfloat), Tprim(Tfloat) -> true
    | Tprim(Tbool), Tprim(Tbool) -> true
    | Tprim(Tvoid), Tprim(Tvoid) -> true
    | Tclass(className), Tclass("Object") -> (existsClassInProgram program className)
    | _ , _ -> false;;
    

let response = (existsClassInProgram [ ("A",a) ] "A");;

Printf.printf "%b\n" response;;