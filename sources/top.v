module top(CLOCK_50, TRIG, ECHO, LED);

	input 		 CLOCK_50;
	output 		 TRIG;
	input		 ECHO;  // /!\  Alim. du capteur 5V, abaisser le signal ECHO à 3v3 (diviseur tension)
	output [7:0] 	 LED;
	
	wire start, new_measure, timeout;
	wire [20:0] distance_raw;

	reg [24:0] counter_ping;
	
	localparam CLK_MHZ = 50;	 // horloge 50MHz
	localparam PERIOD_PING_MS = 60;  // période des ping en ms
	
	localparam COUNTER_MAX_PING = CLK_MHZ * PERIOD_PING_MS * 1000;

	// avec horloge 50MHz et c=345m/s, distance_raw = 2900 * D(cm)
	localparam D = 2900;


	ultrasonic #(	.CLK_MHZ(50), 
			.TRIGGER_PULSE_US(12), 
			.TIMEOUT_MS(3)
					) U1
						(	.clk(CLOCK_50),
							.trigger(TRIG),
							.echo(ECHO),
							.start(start),
							.new_measure(new_measure),
							.timeout(timeout),
							.distance_raw(distance_raw)
						);
		
	assign LED[6] = (distance_raw > 40*D); // distance > 40cm				  
	assign LED[5] = (distance_raw > 30*D);
	assign LED[4] = (distance_raw > 25*D);
	assign LED[3] = (distance_raw > 20*D);
	assign LED[2] = (distance_raw > 15*D);
	assign LED[1] = (distance_raw > 10*D);
	assign LED[0] = (distance_raw >  5*D); // distance > 5cm
	assign LED[7] = timeout;	// avec timeout=3ms => distance > 52cm						

	assign start = (counter_ping == COUNTER_MAX_PING - 1);

	always @(posedge CLOCK_50) begin
		if (counter_ping == COUNTER_MAX_PING - 1)
			counter_ping <= 25'd0;
		else begin	
			counter_ping <= counter_ping + 25'd1;
		end
	end


endmodule
