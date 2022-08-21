/*
	* Un simple contrôleur pour les capteurs à ultrasons
	  du type SRF05 ou HC-SR04
	  
	* Trigger et Echo séparés
	
   /-----------------------------\
   |      ultrasonic sensor      |
   |         controller          |
   |                             |	
   |                      trigger -->
   |                             |
   |                  new_measure -->
   |                      timeout -->
--> echo                         | 
   |           distance_raw[20:0] ==>
   |                             |
--> start                        |
--> clk                          |
   |                             |
   \-----------------------------/

	* clk : horloge (paramètre CLK_MHZ, 50 MHz par défaut)
	* start : lance une mesure sur impulsion
	* trigger : à connecter à la broche Trig du capteur
					(paramètre TRIGGER_PULSE_US, 12 us par défaut)
	* echo : à connecter sur la broche Echo du capteur
	* new_measure : 1 impulsion si la mesure est complète
	* timeout : 1 impulsion si timeout (paramètre TIMEOUT_MS, 20 ms par défaut
	* distance_raw: à lire sur impulsion de new_measure
						 donnée image de la largeur du signal Echo codée sur 21 bits
						 
	  duree du signal echo en microsecondes = distance_raw / CLK_MHZ
	 
	  Le capteur SRF05 a un timeout de 30 ms si aucun obtacle n'est rencontré.
	  On peut simuler un timeout inférieur avec le paramètre TIMEOUT_MS
	  Si le signal Echo n'est pas redescendu après ce TIME_OUT, le contrôleur
	  bloque distance_raw, délivre une impulsion sur la sorte new_measure et sur la sortie timeout.  	
*/


module ultrasonic(clk, start, trigger, echo, distance_raw, new_measure, timeout);

	input clk, start, echo;
	output trigger, new_measure, timeout;
	output reg [20:0] distance_raw;

	parameter 	CLK_MHZ = 50,			// fréquence horloge en MHz
			TRIGGER_PULSE_US = 12,  	// durée impulsion trigger en microsecondes
			TIMEOUT_MS = 25;		// timeout en millisecondes
	
	localparam	COUNT_TRIGGER_PULSE = CLK_MHZ * TRIGGER_PULSE_US;
	localparam  	COUNT_TIMEOUT = CLK_MHZ * TIMEOUT_MS * 1000;

	reg [20:0] counter;
	
	reg[2:0]  state, state_next;
	localparam 	IDLE 		= 0,
			TRIG 		= 1,
			WAIT_ECHO_UP 	= 2,
			MEASUREMENT 	= 3,
			MEASURE_OK 	= 4;
	
	always @(posedge clk) state <= state_next;
	
	wire measurement;
	assign measurement = (state == MEASUREMENT);
	
	assign new_measure = (state == MEASURE_OK);
	
	wire counter_timeout;
	assign counter_timeout = (counter >= COUNT_TIMEOUT);
	
	assign timeout = new_measure && counter_timeout;
	assign trigger = (state == TRIG);
	
	wire enable_counter;
	assign enable_counter = trigger || echo;	
	
	always @(posedge clk) begin
		if (enable_counter)
			counter <=  counter + 21'b1;
		else
			counter <= 21'b0;  
	end	
	
	always @(posedge clk) begin
		if (enable_counter && measurement)
			distance_raw <= counter;
	end
	
	always @(*) begin
		state_next <= state; // par défaut, l'état est maintenu

		case (state)
			IDLE: begin // signal trigger sur impulsion start
				if (start) state_next <= TRIG;
			end
			
			TRIG: begin // durée signal trig > 10us pour SRF05
				if (counter >= COUNT_TRIGGER_PULSE) state_next <= WAIT_ECHO_UP;
			end
			
			WAIT_ECHO_UP: begin
				// avec le SRF05, il y a un délai de 750us après le trig avant que le
				// signal echo bascule à l'état haut.
				if (echo) state_next <= MEASUREMENT;
			end
			
			MEASUREMENT: begin // attente echo qui redescend, ou timeout
				if (counter_timeout || (~echo)) state_next <= MEASURE_OK;
			end
			
			MEASURE_OK: begin
				state_next <= IDLE;			
			end

			default: begin
				state_next <= IDLE;
			end	
		endcase
		
	end
					
	
endmodule
