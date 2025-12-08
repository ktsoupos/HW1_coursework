module calc_enc(input wire btnl,
               input wire btnr,
               input wire btnd,
               output wire [3:0] alu_op);

    wire not_btnl, not_btnr, not_btnd;

    not n1 (not_btnl, btnl);
    not n2 (not_btnr, btnr);
    not n3 (not_btnd, btnd);

    wire op0_and1, op0_and2, op0_and3;
    and (op0_and1, not_btnl, btnd);
    and (op0_and2, btnl, btnr);
    and (op0_and3, op0_and2, not_btnd);
    or  (alu_op[0], op0_and1, op0_and3);

    wire op1_or1;
    or (op1_or1, not_btnr, not_btnd);
    and (alu_op[1], btnl, op1_or1); 

    wire op2_and1, op2_and2, op2_xor, op2_not;
    and (op2_and1, not_btnl, btnr);
    xor (op2_xor, btnd, btnr);
    not (op2_not, op2_xor);
    and (op2_and2, btnl, op2_not);
    or  (alu_op[2], op2_and1, op2_and2);


    wire op3_and1, op3_and2;
    and (op3_and1, btnl, btnr);
    and (op3_and2, btnl, btnd);
    or  (alu_op[3], op3_and1, op3_and2);

endmodule