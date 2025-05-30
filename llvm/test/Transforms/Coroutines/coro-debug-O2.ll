; RUN: opt < %s -passes='module(coro-early),cgscc(coro-split<reuse-storage>),function(sroa)' -S | FileCheck %s

; Checks the dbg informations about promise and coroutine frames under O2.

; CHECK-LABEL: define internal fastcc void @f.resume({{.*}})
; CHECK:       entry.resume:
; CHECK:        #dbg_value(ptr poison, ![[PROMISEVAR_RESUME:[0-9]+]], !DIExpression(DW_OP_deref, DW_OP_plus_uconst, 16
; CHECK:        #dbg_value(ptr %begin, ![[CORO_FRAME:[0-9]+]], !DIExpression(DW_OP_deref)
;
; CHECK: ![[CORO_FRAME]] = !DILocalVariable(name: "__coro_frame"
; CHECK: ![[PROMISEVAR_RESUME]] = !DILocalVariable(name: "__promise"
%promise_type = type { i32, i32, double }

define void @f() presplitcoroutine !dbg !8  {
entry:
    %__promise = alloca %promise_type, align 8
    %id = call token @llvm.coro.id(i32 16, ptr %__promise, ptr null, ptr null)
    %alloc = call i1 @llvm.coro.alloc(token %id)
    br i1 %alloc, label %coro.alloc, label %coro.init

coro.alloc:                                       ; preds = %entry
    %size = call i64 @llvm.coro.size.i64()
    %memory = call ptr @new(i64 %size)
    br label %coro.init

coro.init:                                        ; preds = %coro.alloc, %entry
    %phi.entry.alloc = phi ptr [ null, %entry ], [ %memory, %coro.alloc ]
    %begin = call ptr @llvm.coro.begin(token %id, ptr %phi.entry.alloc)
    call void @llvm.dbg.declare(metadata ptr %__promise, metadata !6, metadata !DIExpression()), !dbg !18
    store i32 1, ptr %__promise, align 8
    %j.i = getelementptr inbounds %promise_type, ptr %__promise, i64 0, i32 1
    store i32 2, ptr %j.i, align 4
    %k.i = getelementptr inbounds %promise_type, ptr %__promise, i64 0, i32 2
    store double 3.000000e+00, ptr %k.i, align 8
    %ready = call i1 @await_ready()
    br i1 %ready, label %init.ready, label %init.suspend

init.suspend:                                     ; preds = %coro.init
    %save = call token @llvm.coro.save(ptr null)
    call void @await_suspend()
    %suspend = call i8 @llvm.coro.suspend(token %save, i1 false)
    switch i8 %suspend, label %coro.ret [
        i8 0, label %init.ready
        i8 1, label %init.cleanup
    ]

init.cleanup:                                     ; preds = %init.suspend
    br label %cleanup

init.ready:                                       ; preds = %init.suspend, %coro.init
    call void @await_resume()
    %ready.again = call zeroext i1 @await_ready()
    br i1 %ready.again, label %await.ready, label %await.suspend

await.suspend:                                    ; preds = %init.ready
    %save.again = call token @llvm.coro.save(ptr null)
    %from.address = call ptr @from_address(ptr %begin)
    call void @await_suspend()
    %suspend.again = call i8 @llvm.coro.suspend(token %save.again, i1 false)
    switch i8 %suspend.again, label %coro.ret [
        i8 0, label %await.ready
        i8 1, label %await.cleanup
    ]

await.cleanup:                                    ; preds = %await.suspend
    br label %cleanup

await.ready:                                      ; preds = %await.suspend, %init.ready
    call void @await_resume()
    call void @return_void()
    br label %coro.final

coro.final:                                       ; preds = %await.ready
    call void @final_suspend()
    %coro.final.await_ready = call i1 @await_ready()
    br i1 %coro.final.await_ready, label %final.ready, label %final.suspend

final.suspend:                                    ; preds = %coro.final
    %final.suspend.coro.save = call token @llvm.coro.save(ptr null)
    %final.suspend.from_address = call ptr @from_address(ptr %begin)
    call void @await_suspend()
    %final.suspend.coro.suspend = call i8 @llvm.coro.suspend(token %final.suspend.coro.save, i1 true)
    switch i8 %final.suspend.coro.suspend, label %coro.ret [
        i8 0, label %final.ready
        i8 1, label %final.cleanup
    ]

final.cleanup:                                    ; preds = %final.suspend
    br label %cleanup

final.ready:                                      ; preds = %final.suspend, %coro.final
    call void @await_resume()
    br label %cleanup

cleanup:                                          ; preds = %final.ready, %final.cleanup, %await.cleanup, %init.cleanup
    %cleanup.dest.slot.0 = phi i32 [ 0, %final.ready ], [ 2, %final.cleanup ], [ 2, %await.cleanup ], [ 2, %init.cleanup ]
    %free.memory = call ptr @llvm.coro.free(token %id, ptr %begin)
    %free = icmp ne ptr %free.memory, null
    br i1 %free, label %coro.free, label %after.coro.free

coro.free:                                        ; preds = %cleanup
    call void @delete(ptr %free.memory)
    br label %after.coro.free

after.coro.free:                                  ; preds = %coro.free, %cleanup
    switch i32 %cleanup.dest.slot.0, label %unreachable [
        i32 0, label %cleanup.cont
        i32 2, label %coro.ret
    ]

cleanup.cont:                                     ; preds = %after.coro.free
    br label %coro.ret

coro.ret:                                         ; preds = %cleanup.cont, %after.coro.free, %final.suspend, %await.suspend, %init.suspend
    %end = call i1 @llvm.coro.end(ptr null, i1 false, token none)
    ret void

unreachable:                                      ; preds = %after.coro.free
    unreachable

}

declare void @llvm.dbg.declare(metadata, metadata, metadata)
declare token @llvm.coro.id(i32, ptr readnone, ptr nocapture readonly, ptr)
declare i1 @llvm.coro.alloc(token)
declare i64 @llvm.coro.size.i64()
declare token @llvm.coro.save(ptr)
declare ptr @llvm.coro.begin(token, ptr writeonly)
declare i8 @llvm.coro.suspend(token, i1)
declare ptr @llvm.coro.free(token, ptr nocapture readonly)
declare i1 @llvm.coro.end(ptr, i1, token)

declare ptr @new(i64)
declare void @delete(ptr)
declare i1 @await_ready()
declare void @await_suspend()
declare void @await_resume()
declare void @print(i32)
declare ptr @from_address(ptr)
declare void @return_void()
declare void @final_suspend()

!llvm.dbg.cu = !{!0}
!llvm.linker.options = !{}
!llvm.module.flags = !{!3, !4}
!llvm.ident = !{!5}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 11.0.0", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, enums: !2, retainedTypes: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "coro-debug.cpp", directory: ".")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 4}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = !{!"clang version 11.0.0"}
!6 = !DILocalVariable(name: "__promise", scope: !7, file: !1, line: 24, type: !10)
!7 = distinct !DILexicalBlock(scope: !8, file: !1, line: 23, column: 12)
!8 = distinct !DISubprogram(name: "foo", linkageName: "_Z3foov", scope: !8, file: !1, line: 23, type: !9, scopeLine: 23, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !2)
!9 = !DISubroutineType(types: !2)
!10 = !DIDerivedType(tag: DW_TAG_typedef, name: "promise_type", scope: !8, file: !1, line: 15, baseType: !11)
!11 = distinct !DICompositeType(tag: DW_TAG_structure_type, name: "promise_type", scope: !8, file: !1, line: 10, size: 128, flags: DIFlagTypePassByValue | DIFlagNonTrivial, elements: !12, identifier: "_ZTSN4coro12promise_typeE")
!12 = !{!13, !14, !15}
!13 = !DIDerivedType(tag: DW_TAG_member, name: "i", scope: !8, file: !1, line: 10, baseType: !16, size: 32)
!14 = !DIDerivedType(tag: DW_TAG_member, name: "j", scope: !8, file: !1, line: 10, baseType: !16, size: 32, offset: 32)
!15 = !DIDerivedType(tag: DW_TAG_member, name: "k", scope: !8, file: !1, line: 10, baseType: !17, size: 64, offset: 64)
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!18 = !DILocation(line: 0, scope: !7)






