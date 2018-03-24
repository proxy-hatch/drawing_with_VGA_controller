-- Filename: lab3_Task4_Final.vhd
-- Author 1: Sheung Yau (Gary) Chung
-- Author 1 Student #: 301236546
-- Author 2: Yu Xuan (Shawn) Wang
-- Author 2 Student #: 301227972
-- Group Number: 40
-- Lab Section: LA04
-- Lab: ASB 10808
-- Task Completed: 2, 3, 4, Challenge
-- Date: February 23, 2018 
------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3_q3 is
	port(CLOCK_50            : in  std_logic;
		KEY                 : in  std_logic_vector(3 downto 0);
		SW                  : in  std_logic_vector(17 downto 0);
		VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
		VGA_HS              : out std_logic;
		VGA_VS              : out std_logic;
		VGA_BLANK           : out std_logic;
		VGA_SYNC            : out std_logic;
		VGA_CLK             : out std_logic);
end lab3_q3;

architecture rtl of lab3_q3 is

	--Component from the Verilog file: vga_adapter.v

	component vga_adapter
	generic(RESOLUTION : string);
	port (resetn                                     : in  std_logic;
		clock                                        : in  std_logic;
		colour                                       : in  std_logic_vector(2 downto 0);
		x                                            : in  std_logic_vector(7 downto 0);
		y                                            : in  std_logic_vector(6 downto 0);
		plot                                         : in  std_logic;
		VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
		VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
	end component;

	signal x      : std_logic_vector(7 downto 0);
	signal y      : std_logic_vector(6 downto 0);
	signal colour : std_logic_vector(2 downto 0);
	signal plot   : std_logic;
	-- I/O
	signal resetn : std_logic;
	signal clk : std_logic;
	-- FSM control signals
	subtype graycodeInput is integer range 0 to 7;
	signal gcInput : graycodeInput;
	--signal i : unsigned(3 downto 0) := "0001"; 	-- range 1 to 14
	signal i: integer := 1;
	
	signal gray_colour: std_logic_vector(2 downto 0);
	
	
begin

	-- includes the vga adapter, which should be in your project 
	vga_u0 : vga_adapter
	generic map(RESOLUTION => "160x120") 
	port map(resetn    => KEY(3),
	clock     => CLOCK_50,
	colour    => colour,
	x         => x,
	y         => y,
	plot      => plot,
	VGA_R     => VGA_R,
	VGA_G     => VGA_G,
	VGA_B     => VGA_B,
	VGA_HS    => VGA_HS,
	VGA_VS    => VGA_VS,
	VGA_BLANK => VGA_BLANK,
	VGA_SYNC  => VGA_SYNC,
	VGA_CLK   => VGA_CLK);


	-- rest of your code goes here, as well as possibly additional files

	-- Map I/O
	resetn <= not KEY(3);	-- change to active high
	clk <= CLOCK_50;

	-- clk_process: process
		-- constant c_off_period:time:=10ns;
		-- constant c_on_period:time:=10ns;
	-- begin
		-- clk<='0';
		-- wait for c_off_period;
		-- clk<='1';
		-- wait for c_on_period;
	-- end process;
	
	-- reset_process: process
	-- begin
		-- resetn <='1';
		-- wait for 5 ns;
		-- resetn <= '0';
		-- wait;
	-- end process;
	

	-- Use Bresenham Line Algorithm to draw A SINGLE line
	DRAWLINES_TASK3 : process (clk, resetn)
	-- states
	type statetype is (prepNextLine, init, setPixelAndCheckExit, updatePixel, updatei, wait1s, done, clear);
	variable curr_state: statetype := prepNextLine;
	-- variables
	variable x0, x1, y0, y1, dx, dy, err, e2, sx, sy : integer;
	-- control signal
	variable doneDraw : std_logic := '0';
	variable count: integer := 0;
	begin
		if resetn = '1' then
			i <= 1;
			x0 := 0;
			y0 := 0;
			plot <= '0';
			colour <= "000"; 
			curr_state := clear;
			
		elsif rising_edge(clk) then
			case curr_state is
			when prepNextLine =>
				if doneDraw = '1'then
					colour <= "000";
				else
					colour <= gray_colour;
				end if;
				
				x0 := 0;
				y0 := i*8; 
				x1 := 159;
				y1 := 120-(i*8);
				curr_state := init;	
				
			when init =>
				dx := abs(x1 - x0);
				dy := abs(y1 - y0);
				if x0 < x1 then
					sx := 1;
				else
					sx := -1;
				end if;
				if y0 < y1 then
					sy := 1;
				else
					sy := -1;
				end if;
				
				err := dx - dy;
				curr_state := setPixelAndCheckExit;
				
			when setPixelAndCheckExit =>
				-- setPixel(x0, y0, colour)
				plot <= '1';
				-- colour already set when i changed
				x <= std_logic_vector(to_signed(x0, x'length));
				y <= std_logic_vector(to_signed(y0, y'length));				
				
				-- check if done drawing line
				if x0 = x1 and y0 = y1 then
					if doneDraw = '0' then
						curr_state := wait1s;
					else 
						curr_state := updatei;
					end if;
					doneDraw := not(doneDraw);	-- negate doneDraw flag
												-- 0->1: finished drawing, should erase next time
												-- 1->0: finished erasing, should draw (after updating i) next time
				else
					curr_state := updatePixel;
				end if;
					
			when updatePixel =>
				plot <= '0';

				e2 := err + err;
				if e2 > -dy then
					err := err - dy;
					x0 := x0 + sx;
				end if;
				if e2 < dx then
					err := err + dx;
					y0 := y0 + sy;
				end if;
				curr_state := setPixelAndCheckExit;
				
			when wait1s => 
				plot <= '0';
				if(count < 50000000) then	-- 50MHz clk -> 1Hz
					count := count + 1;
					curr_state := wait1s;
				else
					count := 0;
					curr_state := prepNextLine;
				end if;	
				
			when updatei =>
				plot <= '0';
				if i < 15 then
					i <= i + 1;
				else
					i <= 1;
				end if;
				curr_state := prepNextLine;
				
			when clear =>
			
				plot <= '1';
				x <= std_logic_vector(to_signed(x0, x'length));
				y <= std_logic_vector(to_signed(y0, y'length));		
				curr_state := clear;
				
				if y0 < 159 then
					-- increment x
					y0 := y0 + 1;
				elsif x0 < 160 then
					-- reset y and increment x
					y0 := 0;
					x0 := x0 + 1;
				else 
					-- done, turn off display
					plot <= '0';
					curr_state := prepNextLine;
				end if;
				
			when others =>	-- corner case
				curr_state := clear;
				
			end case;
		end if;
	end process; 
	
	gcInput <= i mod 8;
	-- used to determine colour
	GRAYCODE : process(all)
	begin	
		case gcInput is
			when 0 =>
				gray_colour <= "000";
			when 1 =>
				gray_colour <= "001";
			when 2 =>
				gray_colour <= "011";
			when 3 =>
				gray_colour <= "010";
			when 4 =>
				gray_colour <= "110";
			when 5 =>
				gray_colour <= "111";
			when 6 =>
				gray_colour <= "101";
			when 7 =>
				gray_colour <= "100";
			when others =>
				gray_colour <= "000";
		end case;
	end process;
	
	

end RTL;


