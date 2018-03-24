-- Filename: lab3_Task2_Final.vhd
-- Author 1: Sheung Yau (Gary) Chung
-- Author 1 Student #: 301236546
-- Author 2: Yu Xuan (Shawn) Wang
-- Author 2 Student #: 301227972
-- Group Number: 40
-- Lab Section: LA04
-- Lab: ASB 10808
-- Task Completed: 2, 3, 4, Challenge
-- Date: February 23, 2018 
-------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3 is
	port(CLOCK_50            : in  std_logic;
		KEY                 : in  std_logic_vector(3 downto 0);
		SW                  : in  std_logic_vector(17 downto 0);
		VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
		VGA_HS              : out std_logic;
		VGA_VS              : out std_logic;
		VGA_BLANK           : out std_logic;
		VGA_SYNC            : out std_logic;
		VGA_CLK             : out std_logic);
end lab3;

architecture rtl of lab3 is

	--Component from the Verilog file: vga_adapter.v

	component vga_adapter
	generic(RESOLUTION : string);
	port (resetn                                       : in  std_logic;
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

	subtype x_cord is integer range 0 to 160;
	subtype y_cord is integer range 0 to 120;
	type pixel is record
		x : x_cord;
		y : y_cord;
	end record;
	signal pixelPos : pixel;
	

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

	fill_screen : process (clk, resetn)
	begin
		if resetn = '1' then
			pixelPos.x <= 0;	
			pixelPos.y <= 0;
			plot <= '1';
		elsif rising_edge(clk) then
			if pixelPos.y < 120 then
				-- increment x
				pixelPos.y <= pixelPos.y + 1;
			elsif pixelPos.x < 160 then
				-- reset y and increment x
				pixelPos.y <= 0;
				pixelPos.x <= pixelPos.x + 1;
			else 
				-- done, turn off display
				plot <= '0';
			end if;
		end if;
		
		x <= std_logic_vector(to_signed(pixelPos.x, x'length));
		y <= std_logic_vector(to_signed(pixelPos.y, y'length));
	end process; 
	
	colour <= std_logic_vector(to_signed(pixelPos.x, 8)(2 downto 0)); -- lower 3 bits is the result of mod8

end RTL;


