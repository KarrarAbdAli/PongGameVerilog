 module pong_main
#(
  parameter SCR_W = 1280,
  parameter SCR_H = 720
)
(
	input wire        CLK, // CLK 75MHz
	input wire        RST, // Active high reset
  
	input wire [10:0] H_CNT, // horizontal pixel pointer		* when we change to wider screen, we have to change the bit size
	input wire [10:0] V_CNT, // vertical   pixel pointer	  * when we change to wider screen, we have to change the bit size
	
	input wire        EncA_QA, 
	input wire        EncA_QB,
	input wire        EncB_QA,
	input wire        EncB_QB,
	
	output wire [7:0] RED,
	output wire [7:0] GREEN,
	output wire [7:0] BLUE,
	
	output wire [3:0] LED
  );

  // Constant output 	
								 
	reg [5:0] state, next_state;				  					
	reg [10:0] posb_H;
	reg [10:0] posb_V;
	localparam bsize = 16;	   
	//------------------------------------------------	 	  	
reg [10:0] paddleL_H;
reg [10:0] paddleL_V;
reg [10:0] paddleR_H;
reg [10:0] paddleR_V;   

reg [25:0] C;
//reg [31:0] C1; initial C1 <=0;	
//reg [31:0] C2; initial C2 <=0;
wire TR, TL, MR, ML, BR, BL;
localparam  paddlesize = (SCR_H/4);

	//-------------------------------Control Variables to control show on the screen-------------------------------														  										   
	wire inside_ball_hu = (H_CNT > (posb_H-bsize/2)) ;
	wire inside_ball_hl = (H_CNT < (posb_H+bsize/2));
	wire inside_ball_vl = (V_CNT >(posb_V-bsize/2));
	wire inside_ball_vr = (V_CNT <(posb_V+bsize/2));
	wire inside_ball = inside_ball_hu && inside_ball_hl && inside_ball_vl && inside_ball_vr;  
	//---------------------------------------------------------
 wire upper_touch = ((posb_V - (bsize/2))==2);
 wire lower_touch = ((posb_V + (bsize/2))==SCR_H-1);		
 //------------------------------
wire top = ((V_CNT == 0)||(V_CNT ==SCR_H-1));	 
//-------------------------------
wire paddlel=(V_CNT>=(paddleL_V - (paddlesize /2)))&&(V_CNT<=(paddleL_V + (paddlesize /2)))&&(H_CNT==paddleL_H||H_CNT==paddleL_H+8);
wire paddler=(V_CNT>=(paddleR_V - (paddlesize /2)))&&(V_CNT<=(paddleR_V + (paddlesize /2)))&&(H_CNT==paddleR_H||H_CNT==paddleR_H-8);
 //------------------------------------------------
// ball cordinates	 to display only
/*
wire ball_up =(V_CNT == (posb_V-(bsize/2)));
wire ball_down = (V_CNT == (posb_V+(bsize/2)));
wire ball_left =  (H_CNT ==(posb_H-(bsize/2)));
wire ball_right = (H_CNT ==(posb_H+(bsize/2)));

wire upper_right_corner = ball_right && ball_up;
wire upper_left_corner =ball_left && ball_up;
wire lower_right_corner = ball_down && ball_right;
wire lower_left_corner = ball_left && ball_down;
	*/

//_______________paddles cordinates						   


reg Apre,Bpre;
	


always@(posedge CLK)  
		Apre <= EncA_QA;
												
always@(posedge CLK or posedge RST)
	if(RST) 
		begin 
		//	C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
		//	posb_H <= (SIM==1'b0)? SCR_W/2 :14	;posb_V <=(SIM==1'b0)? SCR_H/2 : 9; 
		
			paddleL_H <=(3);
           paddleR_H <=(SCR_W);			
	end	
	
always@(posedge CLK or posedge RST)
	
	if(RST) 
			paddleL_V <= (SCR_H/2);                    
	else if (Apre==1 && EncA_QA==0) 
		if (EncA_QB==0) begin if (paddleL_V+(paddlesize/2) >= ((SIM==1'b0)? (SCR_H-(paddlesize/2)): (19-(paddlesize/2))))
			                paddleL_V <= paddleL_V;
			               
			            else paddleL_V <= paddleL_V + 5;	end  
		else if	(EncA_QB==1)  begin	if 	 (paddleL_V-(paddlesize/2) <= (1+ (paddlesize/2)))
						 paddleL_V <= paddleL_V;
			        else paddleL_V <= paddleL_V - 5; end 
	else  paddleL_V <= paddleL_V;
			   
				

 //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		 	  
always@(posedge CLK)
	    Bpre <= EncB_QA;
	

always@(posedge RST or posedge CLK)
	if(RST) 
		begin 
			paddleR_V <= (SCR_H/2);
		
			end

	else if (Bpre==1 && EncB_QA==0)
		
		if (EncB_QB==0) begin	if (paddleR_V+(paddlesize/2) >= ((SIM==1'b0)? (SCR_H-(paddlesize/2)): (19-(paddlesize/2))))
						     paddleR_V <= paddleR_V;
			            else paddleR_V <= paddleR_V + 5;end
		
		else if (EncB_QB==1)        begin   if 	 (paddleR_V-(paddlesize/2) <= (1+(paddlesize/2)))
			                  paddleR_V <= paddleR_V;
			else paddleR_V <= paddleR_V - 5;
			   end
				
 	 else paddleR_V <= paddleR_V;

 
 //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




 assign TR = ((posb_H + (bsize/2)) == (paddleR_H-8))&& ( posb_V >= (paddleR_V-(paddlesize/2)) ) &&(posb_V < (paddleR_V));//tr1 && tr2 && tr3 && tr4 && tr5;
 assign MR = ((posb_H + (bsize/2)) == (paddleL_H-8))&& ( posb_V < (paddleR_V+(paddlesize/2)) ) &&(posb_V > (paddleR_V-(paddlesize/2))); //(posb_V == paddleR_V - 1) && (posb_V + (bsize/2));
 assign BR = ((posb_H + (bsize/2)) == (paddleR_H-8))&& ( posb_V <= (paddleR_V+(paddlesize/2)) ) &&(posb_V > (paddleR_V));//br1 && br2 && br3 && br4 && br5;//((posb_V == 1) && (((posb_H+(bsize/2) > paddleR_H)&&(posb_H+bsize/2 < paddleR_H+paddlesize/3))||(  posb_H-bsize/2 > paddleR_H)&&(posb_H-bsize/2 < paddleR_H+paddlesize/3));
///----------------------------------------------------------------------------
//left paddle	 
   /*
wire tl1= (posb_H + (bsize/2) == (paddleL_H + 1)); //(posb_V + (bsize/2) == (paddleR_V - 1)); (upper_right_corner)==((paddleR_V - (paddlesize/2)));
wire tl2=(posb_V + (bsize/2) >= (paddleL_V - (paddlesize/3))) ;
wire tl3=(posb_V +( bsize/2) < paddleL_V);
wire tl4=(posb_V -(bsize/2) >= (paddleL_V - (paddlesize /3)));
wire tl5=(posb_V - (bsize/2) < paddleL_V); 				 

wire bl1=(posb_H + (bsize/2) == (paddleL_H + 1));
wire bl2=(posb_V + (bsize/2) <= (paddleL_V + (paddlesize/3))) ;
wire bl3=(posb_V +( bsize/2) > (paddleL_V));
wire bl4 =(posb_V -(bsize/2) <= (paddleL_V + (paddlesize /3))) ;
wire bl5 =(posb_V - (bsize/2) > paddleL_V);


*/

assign TL = ((posb_H - (bsize/2)) == (paddleL_H+8))&& ( posb_V >= (paddleL_V-(paddlesize/2)) ) &&(posb_V < (paddleL_V));  //tl1 && tl2 && tl3 && tl4 && tl5;//(posb_H + (bsize/2) == paddleL_H + 1) && (posb_V - (bsize/2) <= paddleL_V - paddlesize/3) && (posb_V -( bsize/2) >= paddleL_V) && (posb_V +(bsize/2)) <= paddleR_V - (paddlesize /3) && (posb_V + (bsize/2) >= paddleR_V;
 assign ML = ((posb_H - (bsize/2)) == (paddleL_H+8))&& ( posb_V < (paddleL_V+(paddlesize/2)) ) &&(posb_V > (paddleL_V-(paddlesize/2)));//(posb_H == paddleR_H - 1) && (posb_V + (bsize/2));
assign BL = ((posb_H - (bsize/2)) == (paddleL_H+8))&& ( posb_V <= (paddleL_V+(paddlesize/2)) ) &&(posb_V > (paddleL_V));
   



//-------------------------------------------------------------------------------
	assign RED   = (inside_ball || top||paddlel||paddler)?8'hFF : 0; //8'hFD;
    assign GREEN = inside_ball || top?8'hFF : 0;  //8'h67;
    assign BLUE  =inside_ball || top?8'hFF : 0; //8'hDF; 
  	

   //-----------------------------------------
  // assign LED to counter bits to indicate FPGA is working
  reg [31:0] heartbeat;
  always@(posedge CLK or posedge RST)
  if(RST) heartbeat <=             32'd0;
  else    heartbeat <= heartbeat + 32'd1;
  
  assign LED[3:0] = heartbeat[26:23];
  //-----------------------------------------
  localparam start = 0, PRLM=1, DRLM=2,  RLM = 3,PLRM=4, DLRM=5, LRM = 6, PRLU=7, DRLU=8, RLU = 9, PRLL=10, DRLL=11, RLL =12, PLRU=13, DLRU=14, LRU =15,PLRL=16, DLRL=17, LRL =18, PBTR=19, DBTR=20, BTR =21, PTBR=22, DTBR=23, TBR =24 , PBTL=25, DBTL=26, BTL =27, PTBL=28, DTBL=29, TBL =30;
  always@(posedge CLK or posedge RST)
	if (RST) state <= start;
	else state <= next_state;

always@(*)															   																																																					
			begin 
				case (state)
				    start : next_state <= PRLM;//check;
															  								
				   /* check : if (PLM) next_state <= RLM ;
					        else next_state <= RLM;
					*/
					PRLM: next_state <= DRLM;
					DRLM:if	(C==0)next_state <= RLM;
					else next_state <= DRLM;  
						
						
				    RLM: 	if (((posb_H)==0)||(posb_H==SCR_W))next_state <= start;
							else if (BL) next_state <= PLRL; 
						else if (TL) next_state <= PLRU;
						else if (ML) next_state <= PLRM ;
						else next_state <= PRLM;	   
							
							
							PLRM: next_state <= DLRM;
					DLRM:if	(C==0)next_state <= LRM;
					else next_state <= DLRM;
						
					LRM: if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W-1))next_state <= start;
						else if (TR) next_state <= PLRU ;
					     else if (BR) next_state <= PRLL;
	                     else if (MR) next_state <= PRLM;	  
						 else next_state <= PLRM; 
							 
						PRLU: next_state <= DRLU;
					DRLU:if	(C==0)next_state <= RLU;
					else next_state <= DRLU;
						
					RLU:  if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W-1))next_state <= start;
						  else if (upper_touch != 1) next_state <= PRLU;
						 else next_state <= PTBL; 
							 
						PRLL: next_state <= DRLL;
					DRLL:if	(C==0)next_state <= RLL;
					else next_state <= DRLL;
						
					RLL : if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start;
						 else if (lower_touch != 1) next_state <= PRLL;
						 else next_state <= PBTL;
							 
							 PLRU: next_state <= DLRU;
					DLRU:if	(C==0)next_state <= LRU;
					else next_state <= DLRU;
						
					LRU: if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start;
						 else if (upper_touch != 1) next_state <= PLRU;	
						 else next_state <= PTBR; 
							 
							 PLRL: next_state <= DLRL;
					DLRL:if	(C==0)next_state <= LRL;
					else next_state <= DLRL;
						
					LRL:   if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start;
						   else if (lower_touch != 1) next_state <= PLRL;
						   else next_state <= PBTR; 
							   
						PTBL: next_state <= DTBL;
					DTBL:if	(C==0)next_state <= TBL;
					else next_state <= DTBL;
						
					TBL:   if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start;
						   else if (TL) next_state <= PLRU;
						   else if (ML) next_state <= PLRM;
			   			   else if (BL) next_state <= PLRL;
						   else if ((posb_H + (bsize/2)) == 0) next_state <= start;
						   else next_state <= PTBL;
					
					
										 
						 	PBTL: next_state <= DBTL;
					DBTL:if	(C==0)next_state <= BTL;
					else next_state <= DBTL;
					
					
					
					
					
	
					BTL:   if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start;
						   else if (TL) next_state <= PLRU;
							else if (ML)next_state <= PLRM;
						else if (BL) next_state <= PLRL;
							else if ((posb_H + (bsize/2)) == 0) next_state <= start;
								else next_state <= PBTL;
					  
							  
							  			   
						PTBR: next_state <= DTBR;
					DTBR:if	(C==0)next_state <= TBR;
					else next_state <= DTBR;	  
							  
							  
							  
					TBR: 		if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start;
								else if (TR)next_state <= PRLU;
			    		   else if (MR)next_state <= PRLM;
						   else if (BR)next_state <= PRLL;
					       else if ((posb_H + (bsize/2)) == 29)next_state <= start;
						   else next_state <= TBR; 
							 
						PBTR: next_state <= DBTR;
					DBTR:if	(C==0)next_state <= BTR;
					else next_state <= DBTR;	 	 
							 
							 
							 
					BTR :if (((posb_H-(bsize/2))==0)||(posb_H+(bsize/2)==SCR_W))next_state <= start; 
					else if (TR) next_state <= PRLU;
			                else if (MR)next_state <= PRLM;
						    else if (BR)next_state <= PRLL;
						   	else if ((posb_H + (bsize/2)) == 1280) next_state <= start;
							else  next_state <= PBTR;
							  
							  
					default : next_state <= start;

			    endcase
		    end 


//-----------------------------here we write the code for the other always block--------------------------------
 parameter SIM = 1'b0;

always@( posedge CLK)
	 if (next_state == start)
		begin
			C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
			posb_H <= (SIM==1'b0)? SCR_W/2 :14	;posb_V <=(SIM==1'b0)? SCR_H/2 : 9;
			end
			
			
	else if (next_state == PRLM)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
	else if (next_state == DRLM)C <= C-25'b1;	
	
	else if (next_state == RLM)
		begin
			
			posb_H <= posb_H - 1;
			posb_V <= posb_V;
		end
		
	else if (next_state == PLRM)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/:32'h2A9 ;
	else if (next_state == DLRM)C <= C-25'b1;
		
	else if (next_state == LRM)
		begin
			
			posb_H <= posb_H + 1;
			posb_V <= posb_V;
		end								 
		
		else if (next_state == PRLU)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
	else if (next_state == DRLU)C <= C-25'b1;
		
	else if (next_state == RLU)
			
				begin
					
					posb_H <= posb_H - 1;
					posb_V <= posb_V - 1;
				end
			 else if (next_state == PRLL)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
	
			 else if (next_state == DRLL)C <= C-25'b1;
	
		 else if (next_state == RLL)
	
				begin
					
					posb_H <= posb_H - 1;
					posb_V <= posb_V + 1;
				end
		   else if (next_state == PLRU)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/:32'h2A9 ;
	
			 else if (next_state == DLRU)C <= C-25'b1;
	
	else if (next_state == LRU)
	
				begin
					
					posb_H <= posb_H + 1;
					posb_V <= posb_V - 1;
				end
		  	else if (next_state == PLRL)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/:32'h2A9 ;
	
			 else if (next_state == DLRL)C <= C-25'b1;	
	else if (next_state == LRL)
					begin
						//C <= C-32'b1;
						posb_H <= posb_H + 1;
					posb_V <= posb_V + 1;
				end
		
		else if (next_state == PBTR)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/:32'h2A9 ;
	
			 else if (next_state == DBTR)C <= C-25'b1;	
	else if (next_state == BTR)
		begin
				//C <= C-32'b1;
				posb_V <= posb_V - 1;
				posb_H <= posb_H + 1;
		end
		 else if (next_state == PTBR)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
	
			 else if (next_state == DTBR)C <= C-25'b1;	
	else if (next_state == TBR)
		begin
			  // C <= C-32'b1;
				posb_V <= posb_V + 1;
				posb_H <= posb_H + 1;
		end
	else if (next_state == PBTL)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
	
			 else if (next_state == DBTL)C <= C-25'b1;	
	else if (next_state == BTL)
		begin
			   	 // C <= C-32'b1;
				posb_V <= posb_V - 1;
				posb_H <= posb_H - 1;
		end
		
		else if (next_state == PTBL)C <=(SIM==1'b0)?25'h1FE01/*0120FE01*/  :32'h2A9 ;
	
		else if (next_state == DTBL)C <= C-25'b1;	
			
	else if (next_state == TBL)
		begin
				//C <= C-32'b1;
				posb_V <= posb_V + 1;
				posb_H <= posb_H - 1;
		end
				
								
endmodule

