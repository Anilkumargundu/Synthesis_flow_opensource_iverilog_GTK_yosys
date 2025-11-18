# Synthesis_flow_opensource_iverilog_GTK_yosys
Yet to update day-by-day
wire

Represents a physical connection or signal.

You cannot store values in a wire—it always reflects the value being driven by something else.

You cannot use procedural assignment (= in always) on a wire.

You can drive it using:

assign statement (continuous assignment)

Outputs of modules or primitives

Example:

wire a, b, c;
assign c = a & b;  // continuous assignment


reg

Can store a value. Think of it as a small memory element.

You can assign to a reg inside procedural blocks (always or initial).

It does not imply hardware flip-flop unless you assign in a clocked always block.

Example:

reg q;
always @(posedge clk) begin
    q <= d;  // stores value of d on rising edge of clk
end


Important subtlety:

reg does not always create a flip-flop. It only stores values in procedural blocks. If you do always @(*) (combinational), it’s just combinational logic.

reg y;
always @(*) begin
    y = a & b;  // combinational, no storage
end


✅ Summary:

wire → connection, cannot store, driven by assign/module outputs

reg → can store value, assigned in procedural blocks
