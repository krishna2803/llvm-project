; RUN: llc -simplifycfg-require-and-preserve-domtree=1 < %s -mtriple=sparc   -relocation-model=static | FileCheck -check-prefix=V8ABS %s
; RUN: llc -simplifycfg-require-and-preserve-domtree=1 < %s -mtriple=sparc   -relocation-model=pic    | FileCheck -check-prefix=V8PIC %s
; RUN: llc -simplifycfg-require-and-preserve-domtree=1 < %s -mtriple=sparcv9 -relocation-model=static | FileCheck -check-prefix=V9ABS %s
; RUN: llc -simplifycfg-require-and-preserve-domtree=1 < %s -mtriple=sparcv9 -relocation-model=pic    | FileCheck -check-prefix=V9PIC %s

; RUN: llc -simplifycfg-require-and-preserve-domtree=1 < %s -mtriple=sparcv9 -relocation-model=static -filetype=obj | llvm-readobj -r - | FileCheck -check-prefix=V9ABS-REL %s
; RUN: llc -simplifycfg-require-and-preserve-domtree=1 < %s -mtriple=sparcv9 -relocation-model=pic -filetype=obj | llvm-readobj -r - | FileCheck -check-prefix=V9PIC-REL %s

%struct.__fundamental_type_info_pseudo = type { %struct.__type_info_pseudo }
%struct.__type_info_pseudo = type { ptr, ptr }

@_ZTIi = external constant %struct.__fundamental_type_info_pseudo
@_ZTIf = external constant %struct.__fundamental_type_info_pseudo
@.cst = private unnamed_addr constant [12 x i8] c"catched int\00", align 64
@.cst1 = private unnamed_addr constant [14 x i8] c"catched float\00", align 64

; V8ABS-LABEL: main:
; V8ABS:        .cfi_startproc
; V8ABS:        .cfi_personality 0, __gxx_personality_v0
; V8ABS:        .cfi_lsda 0,
; V8ABS:        .cfi_def_cfa_register {{30|%fp}}
; V8ABS:        .cfi_window_save
; V8ABS:        .cfi_register %o7, %i7

; V8ABS:        call __cxa_throw
; V8ABS:        call __cxa_throw

; V8ABS:        call __cxa_begin_catch
; V8ABS:        call __cxa_end_catch

; V8ABS:        call __cxa_begin_catch
; V8ABS:        call __cxa_end_catch

; V8ABS:        .cfi_endproc

; V8PIC-LABEL: main:
; V8PIC:        .cfi_startproc
; V8PIC:        .cfi_personality 155, DW.ref.__gxx_personality_v0
; V8PIC:        .cfi_lsda 27,
; V8PIC:        .cfi_def_cfa_register {{30|%fp}}
; V8PIC:        .cfi_window_save
; V8PIC:        .cfi_register %o7, %i7
; V8PIC:        .section .gcc_except_table
; V8PIC-NOT:    .section
; V8PIC:        .word %r_disp32(.L_ZTIi.DW.stub)
; V8PIC:        .data
; V8PIC: .L_ZTIi.DW.stub:
; V8PIC-NEXT:   .word _ZTIi


; V9ABS-LABEL: main:
; V9ABS:        .cfi_startproc
; V9ABS:        .cfi_personality 0, __gxx_personality_v0
; V9ABS:        .cfi_lsda 27,
; V9ABS:        .cfi_def_cfa_register {{30|%fp}}
; V9ABS:        .cfi_window_save
; V9ABS:        .cfi_register %o7, %i7
; V9ABS:        .section .gcc_except_table
; V9ABS-NOT:    .section
; V9ABS:        .xword _ZTIi

; V9ABS-REL:      .rela.gcc_except_table {
; V9ABS-REL-NEXT:   0x14 R_SPARC_64 _ZTIi 0x0
; V9ABS-REL-NEXT:   0x1C R_SPARC_64 _ZTIf 0x0
; V9ABS-REL-NEXT: }
; V9ABS-REL-NEXT: .rela.eh_frame {
; V9ABS-REL-NEXT:   0x13 R_SPARC_UA64 __gxx_personality_v0 0x0
; V9ABS-REL-NEXT:   0x2C R_SPARC_DISP32 .text 0x0
; V9ABS-REL-NEXT:   0x35 R_SPARC_DISP32 .gcc_except_table 0x0
; V9ABS-REL-NEXT: }

; V9PIC-LABEL: main:
; V9PIC:        .cfi_startproc
; V9PIC:        .cfi_personality 155, DW.ref.__gxx_personality_v0
; V9PIC:        .cfi_lsda 27,
; V9PIC:        .cfi_def_cfa_register {{30|%fp}}
; V9PIC:        .cfi_window_save
; V9PIC:        .cfi_register %o7, %i7
; V9PIC:        .section .gcc_except_table
; V9PIC-NOT:    .section
; V9PIC:        .word %r_disp32(.L_ZTIi.DW.stub)
; V9PIC:        .data
; V9PIC: .L_ZTIi.DW.stub:
; V9PIC-NEXT:   .xword _ZTIi

; V9PIC-REL:      .rela.gcc_except_table {
; V9PIC-REL-NEXT:   0x14 R_SPARC_DISP32 .data 0x8
; V9PIC-REL-NEXT:   0x18 R_SPARC_DISP32 .data 0x0
; V9PIC-REL-NEXT: }
; V9PIC-REL-NEXT: .rela.data {
; V9PIC-REL:      .rela.data.DW.ref.__gxx_personality_v0 {
; V9PIC-REL:      .rela.eh_frame {
; V9PIC-REL-NEXT:   0x13 R_SPARC_DISP32 DW.ref.__gxx_personality_v0 0x0
; V9PIC-REL-NEXT:   0x28 R_SPARC_DISP32 .text 0x0
; V9PIC-REL-NEXT:   0x31 R_SPARC_DISP32 .gcc_except_table 0x0
; V9PIC-REL-NEXT: }

define i32 @main(i32 %argc, ptr nocapture readnone %argv) unnamed_addr #0 personality ptr @__gxx_personality_v0 {
entry:
  %0 = icmp eq i32 %argc, 2
  %1 = tail call ptr @__cxa_allocate_exception(i32 4) #1
  br i1 %0, label %"3", label %"4"

"3":                                              ; preds = %entry
  %2 = bitcast ptr %1 to ptr
  store i32 0, ptr %2, align 4
  invoke void @__cxa_throw(ptr %1, ptr @_ZTIi, ptr null) #2
          to label %3 unwind label %"8"

; <label>:3                                       ; preds = %"3"
  unreachable

"4":                                              ; preds = %entry
  %4 = bitcast ptr %1 to ptr
  store float 1.000000e+00, ptr %4, align 4


  invoke void @__cxa_throw(ptr %1, ptr @_ZTIf, ptr null) #2
          to label %5 unwind label %"8"

; <label>:5                                       ; preds = %"4"
  unreachable

"5":                                              ; preds = %"13", %"11"
  %6 = phi i32 [ 2, %"13" ], [ 0, %"11" ]
  ret i32 %6

"8":                                              ; preds = %"4", %"3"
  %exc = landingpad { ptr, i32 }
          catch ptr @_ZTIi
          catch ptr @_ZTIf
  %exc_ptr12 = extractvalue { ptr, i32 } %exc, 0
  %filter13 = extractvalue { ptr, i32 } %exc, 1
  %typeid = tail call i32 @llvm.eh.typeid.for(ptr @_ZTIi)
  %7 = icmp eq i32 %filter13, %typeid
  br i1 %7, label %"11", label %8

; <label>:8                                       ; preds = %"8"
  %typeid8 = tail call i32 @llvm.eh.typeid.for(ptr @_ZTIf)
  %9 = icmp eq i32 %filter13, %typeid8
  br i1 %9, label %"13", label %"9"

"9":                                              ; preds = %8
  resume { ptr, i32 } %exc

"11":                                             ; preds = %"8"
  %10 = tail call ptr @__cxa_begin_catch(ptr %exc_ptr12) #1
  %11 = tail call i32 @puts(ptr @.cst)
  tail call void @__cxa_end_catch() #1
  br label %"5"

"13":                                             ; preds = %8
  %12 = tail call ptr @__cxa_begin_catch(ptr %exc_ptr12) #1
  %13 = tail call i32 @puts(ptr @.cst1)
  tail call void @__cxa_end_catch() #1
  br label %"5"
}

; Function Attrs: nounwind
declare ptr @__cxa_allocate_exception(i32) #1

; Function Attrs: noreturn
declare void @__cxa_throw(ptr, ptr, ptr) #2

declare void @__cxa_end_catch()

; Function Attrs: nounwind readnone
declare i32 @llvm.eh.typeid.for(ptr) #3

; Function Attrs: nounwind
declare ptr @__cxa_begin_catch(ptr) #1

; Function Attrs: nounwind
declare i32 @puts(ptr nocapture readonly) #1

declare i32 @__gxx_personality_v0(i32, i64, ptr, ptr)

attributes #0 = { "frame-pointer"="none" }
attributes #1 = { nounwind }
attributes #2 = { noreturn }
attributes #3 = { nounwind readnone }
