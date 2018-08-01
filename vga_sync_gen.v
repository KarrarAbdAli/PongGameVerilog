																							   																		//=============================================================================
//`default_nettype none
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns
//=============================================================================
module vga_sync_gen
(
input wire          CLK,    
input wire          RST,    

// Wyjscie VGA

output wire         GEN_ACTIVE,
output wire  [23:0] GEN_RGB,

output wire  [10:0] GEN_HCNT,
output wire         GEN_HSYNC,
output wire         GEN_HSYNCP,

output wire  [10:0] GEN_VCNT,
output wire         GEN_VSYNC,
output wire         GEN_VSYNCP,

// Parametry

input wire   [10:0] V_FRONT_PORCH,
input wire   [10:0] V_SYNC,
input wire   [10:0] V_BACK_PORCH,
input wire   [10:0] V_ACTIVE,
input wire          V_SYNC_POL,

input wire   [10:0] H_FRONT_PORCH,
input wire   [10:0] H_SYNC,
input wire   [10:0] H_BACK_PORCH,
input wire   [10:0] H_ACTIVE,
input wire          H_SYNC_POL
);
//=============================================================================
// local variables
//=============================================================================
//-----------------------------------------------------------------------------
// Stany
//-----------------------------------------------------------------------------
localparam  FSM_IDLE                = 0;
localparam  FSM_SYNC                = 30;
localparam  FSM_BACK_PORCH          = 40;
localparam  FSM_ACTIVE              = 50;
localparam  FSM_FRONT_PORCH         = 60;
//-----------------------------------------------------------------------------
// Rejestry
//-----------------------------------------------------------------------------
reg   [7:0] fsm_h;
reg         fsm_tic;
reg         fsm_cv;
reg   [7:0] fsm_v;
//-----------------------------------------------------------------------------
reg  [10:0] cnt_h;
reg  [10:0] cnt_ha;
//-----------------------------------------------------------------------------
reg  [10:0] cnt_v;
reg  [10:0] cnt_va;
//-----------------------------------------------------------------------------
reg  [23:0] test_pattern;
//-----------------------------------------------------------------------------
reg         active_v;
reg         active_h;
reg         active_hv;
//-----------------------------------------------------------------------------
reg         sync_h;
reg         sync_hp;
reg         sync_v;
reg         sync_vp;
//-----------------------------------------------------------------------------
// test pattern
//-----------------------------------------------------------------------------
wire                             [7:0] test_y = cnt_ha[7:0];
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
 if(RST)                                  test_pattern <= 24'h000000;
 else if(cnt_ha[3:0]==4'd0)               test_pattern <= 24'hFFFFFF;
 else if(cnt_va[3:0]==4'd0)               test_pattern <= 24'hFFFFFF;
 else if(cnt_va[5:4]==2'd0)               test_pattern <= {test_y,test_y,test_y};
 else if(cnt_va[5:4]==2'd1)               test_pattern <= {test_y,8'd0  ,8'd0  };
 else if(cnt_va[5:4]==2'd2)               test_pattern <= {8'd0  ,test_y,8'd0  };
 else if(cnt_va[5:4]==2'd3)               test_pattern <= {8'd0  ,8'd0  ,test_y};
//-----------------------------------------------------------------------------
// Sterowanie H
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                                 fsm_h   <= FSM_IDLE;
    else case(fsm_h)                      
    FSM_IDLE:                               fsm_h   <= FSM_SYNC;
    FSM_SYNC:           if(cnt_h==1)        fsm_h   <= FSM_BACK_PORCH;
    FSM_BACK_PORCH:     if(cnt_h==1)        fsm_h   <= FSM_ACTIVE;
    FSM_ACTIVE:         if(cnt_h==1)        fsm_h   <= FSM_FRONT_PORCH;   
    FSM_FRONT_PORCH:    if(cnt_h==1)        fsm_h   <= FSM_SYNC;  
    endcase
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                                 fsm_tic <= 1'b0;
    else if(fsm_h == FSM_FRONT_PORCH)       fsm_tic <= cnt_h == 2;
    else                                    fsm_tic <= 1'b0;
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                                 fsm_cv <= 1'b0;
    else if(fsm_h == FSM_ACTIVE)            fsm_cv <= cnt_h == 1;
    else                                    fsm_cv <= 1'b0;
//-----------------------------------------------------------------------------
// Sterowanie V
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                                 fsm_v  <= FSM_IDLE;
    else if(fsm_tic) case(fsm_v)                   
    FSM_IDLE:                               fsm_v  <= FSM_SYNC;
    FSM_SYNC:           if(cnt_v==1)        fsm_v  <= FSM_BACK_PORCH;
    FSM_BACK_PORCH:     if(cnt_v==1)        fsm_v  <= FSM_ACTIVE;
    FSM_ACTIVE:         if(cnt_v==1)        fsm_v  <= FSM_FRONT_PORCH;   
    FSM_FRONT_PORCH:    if(cnt_v==1)        fsm_v  <= FSM_SYNC;  
    endcase
//-----------------------------------------------------------------------------
// Licznik punktow(H)
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)          cnt_h <= 1;
    else case(fsm_h)
    FSM_IDLE:           cnt_h <=              H_SYNC;
    FSM_SYNC:           cnt_h <= (cnt_h==1) ? H_BACK_PORCH      : (cnt_h - 1);
    FSM_BACK_PORCH:     cnt_h <= (cnt_h==1) ? H_ACTIVE          : (cnt_h - 1);
    FSM_ACTIVE:         cnt_h <= (cnt_h==1) ? H_FRONT_PORCH     : (cnt_h - 1);
    FSM_FRONT_PORCH:    cnt_h <= (cnt_h==1) ? H_SYNC            : (cnt_h - 1);
    endcase
//-----------------------------------------------------------------------------
// Licznik linii(V)
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)          cnt_v <= 1;
    else if(fsm_tic) case(fsm_v)
    FSM_IDLE:           cnt_v <=              V_SYNC;
    FSM_SYNC:           cnt_v <= (cnt_v==1) ? V_BACK_PORCH     : (cnt_v - 1);
    FSM_BACK_PORCH:     cnt_v <= (cnt_v==1) ? V_ACTIVE         : (cnt_v - 1);
    FSM_ACTIVE:         cnt_v <= (cnt_v==1) ? V_FRONT_PORCH    : (cnt_v - 1);
    FSM_FRONT_PORCH:    cnt_v <= (cnt_v==1) ? V_SYNC           : (cnt_v - 1);
    endcase
//-----------------------------------------------------------------------------
// HSYNC
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                      sync_hp   <=        1'b0;
    else if(fsm_h == FSM_SYNC)   sync_hp   <=  H_SYNC_POL;
    else                         sync_hp   <= !H_SYNC_POL;
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                      sync_h    <=        1'b0;
    else if(fsm_h == FSM_SYNC)   sync_h    <=        1'b1;
    else                         sync_h    <=        1'b0;
//-----------------------------------------------------------------------------
// VSYNC
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                      sync_vp   <=        1'b0;
    else if(fsm_v == FSM_SYNC)   sync_vp   <=  V_SYNC_POL;
    else                         sync_vp   <= !V_SYNC_POL;
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                      sync_v    <=        1'b0;
    else if(fsm_v == FSM_SYNC)   sync_v    <=        1'b1;
    else                         sync_v    <=        1'b0;
//-----------------------------------------------------------------------------
// active
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                     active_h  <= 1'b0;
    else if(fsm_h != FSM_ACTIVE)active_h  <= 1'b0;
   else                         active_h  <= 1'b1;  
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                     active_v  <= 1'b0;
    else if(fsm_v != FSM_ACTIVE)active_v  <= 1'b0;
   else                         active_v  <= 1'b1;  
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                     active_hv <= 1'b0;
    else if(fsm_v != FSM_ACTIVE)active_hv <= 1'b0;
    else if(fsm_h != FSM_ACTIVE)active_hv <= 1'b0;
   else                         active_hv <= 1'b1;  
//-----------------------------------------------------------------------------
// licznik aktywnych punktow
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                     cnt_ha    <= 11'd0;
    else if(active_h)           cnt_ha    <= cnt_ha + 11'd1;
    else                        cnt_ha    <= 11'd0;
//-----------------------------------------------------------------------------
// licznik aktywnych lini
//-----------------------------------------------------------------------------
always @(posedge CLK or posedge RST)
    if(RST)                     cnt_va    <= 11'd0;
    else if( active_v && fsm_cv)cnt_va    <= cnt_va + 11'd1;
    else if(!active_v)          cnt_va    <= 11'd0;
//=============================================================================
// output
//=============================================================================
assign GEN_ACTIVE  = active_hv;
assign GEN_RGB     = test_pattern;

assign GEN_HCNT    = cnt_ha;
assign GEN_VCNT    = cnt_va;

assign GEN_HSYNC   = sync_h;
assign GEN_VSYNC   = sync_v;

assign GEN_HSYNCP  = sync_hp;
assign GEN_VSYNCP  = sync_vp;
//=============================================================================
endmodule
