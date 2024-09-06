// RUN: stablehlo-opt -inline %s | stablehlo-translate --interpret
// RUN: stablehlo-translate --serialize --target=current %s | stablehlo-translate --deserialize | stablehlo-opt > %t.0
// RUN: stablehlo-opt %s > %t.1
// RUN: diff %t.0 %t.1

module @jit_main attributes {mhlo.num_partitions = 1 : i32, mhlo.num_replicas = 1 : i32} {
  func.func public @main() -> (tensor<5x6x7xui16> {jax.result_info = "", mhlo.layout_mode = "default"}) {
    %c = stablehlo.constant dense<[[[0], [1]], [[2], [3]]]> : tensor<2x2x1xi64>
    %0:2 = call @inputs() : () -> (tensor<5x6x7xui16>, tensor<5x2x2x7xui16>)
    %1 = call @expected() : () -> tensor<5x6x7xui16>
    %2 = "stablehlo.scatter"(%0#0, %c, %0#1) <{scatter_dimension_numbers = #stablehlo.scatter<update_window_dims = [0, 3], inserted_window_dims = [1], scatter_dims_to_operand_dims = [1], index_vector_dim = 2>, unique_indices = true}> ({
    ^bb0(%arg0: tensor<ui16>, %arg1: tensor<ui16>):
      %3 = stablehlo.add %arg0, %arg1 : tensor<ui16>
      stablehlo.return %3 : tensor<ui16>
    }) : (tensor<5x6x7xui16>, tensor<2x2x1xi64>, tensor<5x2x2x7xui16>) -> tensor<5x6x7xui16>
    stablehlo.custom_call @check.expect_eq(%2, %1) {has_side_effect = true} : (tensor<5x6x7xui16>, tensor<5x6x7xui16>) -> ()
    return %2 : tensor<5x6x7xui16>
  }
  func.func private @inputs() -> (tensor<5x6x7xui16> {mhlo.layout_mode = "default"}, tensor<5x2x2x7xui16> {mhlo.layout_mode = "default"}) {
    %c = stablehlo.constant dense<"0x020000000000030004000200060006000000000000000000060003000000040004000400020002000000000006000200050002000000030000000100000001000100010002000200010003000300000002000100050002000200020000000200040003000100010000000500020003000000040004000500020004000400050003000000030001000000000005000400000001000200010003000200020001000200010001000100000004000000000003000000000000000300030001000200020002000000000002000100010001000200000002000000050004000300040001000000010002000000010000000000010000000300040005000100000002000000000000000300030001000300020000000200010000000000000000000000020007000000000003000200020003000200040001000200010001000200020000000200000002000000010004000100010000000100020001000100010000000100010000000000010007000000010003000000020000000200050003000000010003000400010000000300020000000000010002000000030004000300020004000000"> : tensor<5x6x7xui16>
    %c_0 = stablehlo.constant dense<"0x01000500010001000000060003000100020000000000000000000000010000000100050001000000060002000000010000000000040002000000050002000200060001000200020003000100020006000400030000000000010005000000000001000200020003000100000000000000020001000300010003000100040005000100020002000100010003000700020000000300010003000100060001000100030002000300040000000200000006000000000000000100030004000100030000000300010003000000000002000200010003000200030004000000040000000400020000000400010000000500000002000400030000000200010000000100060003000100020001000100000008000200040000000200"> : tensor<5x2x2x7xui16>
    return %c, %c_0 : tensor<5x6x7xui16>, tensor<5x2x2x7xui16>
  }
  func.func private @expected() -> (tensor<5x6x7xui16> {mhlo.layout_mode = "default"}) {
    %c = stablehlo.constant dense<"0x030005000100040004000800090007000200000000000000060003000100040005000900030002000600020006000300050002000400050000000100000001000100010002000200010003000300000002000100050007000400040006000300060005000400020002000B00060006000000040005000A00020004000500070005000300040001000000000005000400000001000200010003000200020001000200010001000100020005000300010006000100040005000400050003000300030005000700020002000400020004000300060003000100080006000600080001000000010002000000010000000000010000000300040005000100000004000000060000000300030002000600060001000500010003000100030000000000040009000100030005000500060003000600040001000200010001000200020000000200000002000000010004000100050002000100060002000100060000000300050003000000030008000000020009000300030002000300060003000800030007000400030000000300020000000000010002000000030004000300020004000000"> : tensor<5x6x7xui16>
    return %c : tensor<5x6x7xui16>
  }
}