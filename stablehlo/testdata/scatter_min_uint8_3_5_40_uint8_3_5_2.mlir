// RUN: stablehlo-opt -inline %s | stablehlo-translate --interpret
// RUN: stablehlo-translate --serialize --target=current %s | stablehlo-translate --deserialize | stablehlo-opt > %t.0
// RUN: stablehlo-opt %s > %t.1
// RUN: diff %t.0 %t.1

module @jit_main attributes {mhlo.num_partitions = 1 : i32, mhlo.num_replicas = 1 : i32} {
  func.func public @main() -> (tensor<3x5x40xui8> {jax.result_info = "", mhlo.layout_mode = "default"}) {
    %c = stablehlo.constant dense<1> : tensor<2x1xi64>
    %0:2 = call @inputs() : () -> (tensor<3x5x40xui8>, tensor<3x5x2xui8>)
    %1 = call @expected() : () -> tensor<3x5x40xui8>
    %2 = "stablehlo.scatter"(%0#0, %c, %0#1) <{scatter_dimension_numbers = #stablehlo.scatter<update_window_dims = [0, 1], inserted_window_dims = [2], scatter_dims_to_operand_dims = [2], index_vector_dim = 1>}> ({
    ^bb0(%arg0: tensor<ui8>, %arg1: tensor<ui8>):
      %3 = stablehlo.minimum %arg0, %arg1 : tensor<ui8>
      stablehlo.return %3 : tensor<ui8>
    }) : (tensor<3x5x40xui8>, tensor<2x1xi64>, tensor<3x5x2xui8>) -> tensor<3x5x40xui8>
    stablehlo.custom_call @check.expect_eq(%2, %1) {has_side_effect = true} : (tensor<3x5x40xui8>, tensor<3x5x40xui8>) -> ()
    return %2 : tensor<3x5x40xui8>
  }
  func.func private @inputs() -> (tensor<3x5x40xui8> {mhlo.layout_mode = "default"}, tensor<3x5x2xui8> {mhlo.layout_mode = "default"}) {
    %c = stablehlo.constant dense<"0x01000001020103000003000000000100020104060303010300000104020203050105030004000003030100040304000202000002010004020104030002010204010301010000010501010103010202030001010000050400020300040200040003010204030102060001000400020000020002000201010100050002000000020002020300040402080200010000030300010000010203000003000300000002020001030300000001050400060004040203000303000002020001030302050000000104010101000000030002000401000204000206020401010004030202040301000000050300020000000002000102010102030205010102020102050003040404010500000001000302020301010003000203010502000002010102050003000100030102030003000006000000020303000300080503000404010103010103000304050301070201030004010104020001020503020002010002010200030100020300000200020002040002040302050501030107050402040300020000020000030000010001010103060208010100000203000000060004040004030002010000010200030004000100070003010301010004000305040003000000000304010402050202020000010302020402010301040001000000010001050004020300010005010101010101000302040202020200010101000103010400020A050304010402020102040200020400020101040500000206000400000600000500040102040000010406030100040100060100020402010003040600000001020301070001010201050301010202010304040203000404"> : tensor<3x5x40xui8>
    %c_0 = stablehlo.constant dense<[[[2, 0], [6, 1], [1, 4], [1, 2], [2, 0]], [[1, 3], [0, 0], [2, 0], [0, 0], [1, 2]], [[1, 2], [0, 0], [0, 5], [2, 1], [0, 1]]]> : tensor<3x5x2xui8>
    return %c, %c_0 : tensor<3x5x40xui8>, tensor<3x5x2xui8>
  }
  func.func private @expected() -> (tensor<3x5x40xui8> {mhlo.layout_mode = "default"}) {
    %c = stablehlo.constant dense<"0x01000001020103000003000000000100020104060303010300000104020203050105030004000003030100040304000202000002010004020104030002010204010301010000010501010103010202030001010000050400020300040200040003010204030102060001000400020000020002000201010100010002000000020002020300040402080200010000030300010000010203000003000300000002020001030300000001050400060004040203000303000002020001030302050000000104010101000000030002000401000204000206020401010004030202040301000000050300020000000002000102000102030205010102020102050003040404010500000001000302020301010003000203010502000002010102050003000100030102030003000006000000020303000300080503000404010103010100000304050301070201030004010104020001020503020002010002010200030100020300000200010002040002040302050501030107050402040300020000020000030000010001010103060208010100000203000000060004040004030002010000010200030004000100070003010301010004000300040003000000000304010402050202020000010302020402010301040001000000010001050004000300010005010101010101000302040202020200010101000103010400020A050304010402020101040200020400020101040500000206000400000600000500040102040000010406030100040100000100020402010003040600000001020301070001010201050301010202010304040203000404"> : tensor<3x5x40xui8>
    return %c : tensor<3x5x40xui8>
  }
}