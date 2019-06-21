//Coffee Vending Machine

`timescale 1 ns / 100 ps
// State definition
`define NORMAL   2'b00
`define BUSY   	2'b01
`define GIVE_CH  2'b10
`define ERROR    2'b11

module Coffee_Vending_machine(
//Input
	Clock,
	nReset,
	Input_Money,
	Req_Change,
	Click_Black,
	Click_Cream,
	Click_Cream_Sugar,
//Output	
	Money,
	Change,
	Coffee,
	Water,
	Cream,
	Sugar
	)		  ;
	
//Input
input		Clock;
input		nReset;
input 	Input_Money;
input		Req_Change;
input		Click_Black;
input		Click_Cream;
input		Click_Cream_Sugar;

//Output	
output	[4:0]	Money;
output	[4:0]	Change;
output		Coffee;
output		Water;
output		Cream;
output		Sugar;


reg	[4:0]	Money;
reg	[4:0]	Change;
reg		Coffee;
reg		Water;
reg		Cream;
reg		Sugar;
reg	[1:0]	CurrST;
reg	[1:0]	NextST;
wire 		Click;
reg		Busy;
reg		Busy_CH = 1'b0;
wire		Enable_Buy;
wire		Enable_CH;
reg	[1:0]   Time;
reg [1:0]   Time_Click;

reg		Sig_CH = 1'b0;

assign Click = Click_Black | Click_Cream | Click_Cream_Sugar;
assign Enable_Buy = (Money[4:0] >= 5'b0010)? 1'b1 : 1'b0;
assign Enable_CH =  (Money[4:0] != 5'b0000)? 1'b1 : 1'b0;


// state transition condition
always@(CurrST or nReset or Input_Money or Req_Change or Click or Busy or Busy_CH or Enable_Buy or Enable_CH)
begin
	case (CurrST)
	  `NORMAL	: begin
	               		if(~nReset)
	                	 begin
	               		     NextST = `NORMAL;
	                	 end
	               	  	else if(Click && Enable_Buy)
	                  	 begin
	                    	     NextST = `BUSY;
	                 	 end
	                 	else if(Req_Change && Enable_CH)
	                 	 begin
	                    	     NextST = `GIVE_CH;
	                 	 end
	                 	else
	                 	  NextST = CurrST;
	                  end
	   `BUSY	: begin
	   			if(~nReset)
	                	 begin
	               		     NextST = `NORMAL;
	                	 end
	                	else if(~Busy)
	                	 begin
	                	     NextST = `NORMAL;
	                	 end
	                	else 
	                	 NextST = CurrST;
	                  end
	   `GIVE_CH	: begin
	   			if(~nReset)
	                	 begin
	               		     NextST = `NORMAL;
	                	 end
	                	else if(~Busy_CH)
	                	 begin
	                	     NextST = `NORMAL;
	                	 end
							 else if(Sig_CH)
								begin
									NextST = `NORMAL;
								end
	                	else 
	                	 NextST = CurrST;
	                  end
	   default	:begin
	   			NextST = `NORMAL;
	   		 end
	 endcase
end

// state transition to next state
  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      CurrST <= `NORMAL;
    else 
     begin
			if(~Busy && ~Busy_CH) // only when all process is done
				begin
					CurrST <= NextST;
				end
     end
  end 
  
// money, change handle
  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Money  <= 5'b0;
        Change <= 5'b0;
      end
    else if(CurrST == `NORMAL )
      begin
        if(Input_Money && Money != 5'b10000) // maximum 16
       	 Money  <= Money +5'b1;
       	else if(Click && Enable_Buy)
       	 Money  <= Money -5'b10;
       	else if(Req_Change)
       	 begin
       	    Change <= Money;      
       	    Money  <= 5'b0;
				 Busy_CH <= 1'b1;
       	 end
      end
		else if(CurrST == `GIVE_CH && Money != 5'b0 && Sig_CH)
			begin
				Change <= Money;      
       	    Money  <= 5'b0;
				 Busy_CH <= 1'b1;
			end
    else if((CurrST == `GIVE_CH) && (Change != 5'b0)) // return change for each cycle
      begin			
            Change <= Change - 5'b1;
      end
	 else if((CurrST == `GIVE_CH) && (Change == 5'b0)) // change return finish
		begin
				Busy_CH <= 1'b0;
		end
  end
  
  // coffee
  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
			Coffee   <= 1'b0;
			Water    <= 1'b0;
			Cream		<= 1'b0;
			Sugar		<= 1'b0;
      end
    else if(NextST == `NORMAL)
      begin
         Coffee  <= 1'b0;
			Water   <= 1'b0;
			Cream	  <= 1'b0;
			Sugar	  <= 1'b0;
      end
    else if(NextST == `BUSY && CurrST !=`BUSY) // only when it's not running
      begin
        if(Click_Black)
          begin
            	Coffee   <= 1'b1;
					Water    <= 1'b1;
					Cream		<= 1'b0;
					Sugar		<= 1'b0;
          end
        else if(Click_Cream)
          begin
            	Coffee   <= 1'b1;
					Water    <= 1'b1;
					Cream		<= 1'b1;
					Sugar		<= 1'b0;
          end
        else if(Click_Cream_Sugar)
          begin
            	Coffee  <= 1'b1;
					Water   <= 1'b1;
					Cream	  <= 1'b1;
					Sugar	  <= 1'b1;
          end
      end
  end
  
  // when busy
  always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Busy <= 1'b0;
      end
    else if((NextST == `BUSY) &&(CurrST == `NORMAL))
      begin
        Busy <= 1'b1;
      end
    else if(Time_Click == 2'b1)
      begin
        Busy <= 1'b0;
      end
  end 
  
// clock
always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Time_Click <= 2'b00;
      end
    else if(NextST == `NORMAL)
      begin
        Time_Click <= 2'b00;
      end
    else if((NextST == `BUSY) &&(CurrST == `NORMAL))
      begin
        Time_Click <= 2'b01;
      end
    else if((CurrST == `BUSY) && (Time_Click != 2'b00))
      begin
        Time_Click <= Time_Click - 2'b1;
      end
  end
 
 /*
 // no button input for 3 cycles
 always @(negedge nReset or posedge Clock)
  begin
    if (~nReset) 
      begin
        Time <= 2'b00;
      end
    else if((CurrST == `NORMAL) && (NextST != `NORMAL))
      begin
        Time <= 2'b00;
      end
    else if((CurrST == `NORMAL) && (NextST != `BUSY) && (Money != 5'b0) && (Time != 2'b00))
      begin
        Time <= Time - 2'b1;
      end
	else if((CurrST == `NORMAL) && (NextST != `BUSY) && (Money != 5'b0) && (Time == 2'b00))
      begin
        CurrST <= `GIVE_CH;
		  Sig_CH <= 1'b1;
		  Busy_CH <= 1'b1;
		  Sig_CH <= #3 1'b0;
      end
	else
		begin
				Time <= 2'b10;
		end
  end
*/
endmodule
 
/*
  1. 최대 인풋 16원o
  2. 거스름돈 버튼 눌리면 1사이클에 1씩 반환o
  3. 아무 입력 없으면 3클락 뒤에 머니 반환 
  4. 커피 동작중에는 다른 커피 입력이 방해 못하게 
*/