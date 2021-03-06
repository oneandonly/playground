(*
 * From: Gordon Henriksen gordonhenriksen at mac.com
 *   http://lists.cs.uiuc.edu/pipermail/llvmdev/2007-October/010996.html
 *
 * Updated to work with LLVM 2.8.
 *)

open Llvm

let _ =
   let filename = Sys.argv.(1) in
   let ctx = global_context () in
   let m = create_module ctx filename in

   (* @greeting = global [14 x i8] c"Hello, world!\00" *)
   let greeting = define_global "greeting" (const_stringz ctx "Hello, world!") m in

   (* declare i32 @puts( i8* ) *)
   let puts = declare_function "puts" (function_type (i32_type ctx) [|
                                         pointer_type (i8_type ctx) |]) m in

   (* define i32 @main() {
      entry:               *)
   let main = define_function "main" (function_type
                                        (i32_type ctx) [| |] ) m in
   let at_entry = builder_at_end ctx (entry_block main) in

   (* %tmp = getelementptr [14 x i8]* @greeting, i32 0, i32 0 *)
   let zero = const_int (i32_type ctx) 0 in
   let str = build_gep greeting [| zero; zero |] "tmp" at_entry in

   (* call i32 @puts( i8* %tmp ) *)
   ignore (build_call puts [| str |] "" at_entry);

   (* ret void *)
   ignore (build_ret (const_null (i32_type ctx)) at_entry);

   (* write the module to a file *)
   if not (Llvm_bitwriter.write_bitcode_file m filename) then (
     print_string "Cannot write "; print_string filename; print_string "\n"; exit 1
   );
   dispose_module m
