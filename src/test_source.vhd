library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_source is
    port ( 
        clk    : in  std_logic;
        data0  : out std_logic_vector(7 downto 0);
        data0k : out std_logic;
        data1  : out std_logic_vector(7 downto 0);
        data1k : out std_logic
    );
end test_source;

architecture arch of test_source is 
    type a_test_data_blocks is array (0 to 64*7-1) of std_logic_vector(8 downto 0);
    
    constant DUMMY  : std_logic_vector(8 downto 0) := "000000011";   -- 0xAA
    constant SPARE  : std_logic_vector(8 downto 0) := "011111111";   -- 0xFF
    constant ZERO   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00
    constant PIX_R  : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant PIX_G  : std_logic_vector(8 downto 0) := "010000000";   -- 0x80
    constant PIX_B  : std_logic_vector(8 downto 0) := "010000000";   -- 0x80

    constant SS     : std_logic_vector(8 downto 0) := "101011100";   -- K28.2
    constant SE     : std_logic_vector(8 downto 0) := "111111101";   -- K29.7
    constant BE     : std_logic_vector(8 downto 0) := "111111011";   -- K27.7
    constant BS     : std_logic_vector(8 downto 0) := "110111100";   -- K28.5
    constant SR     : std_logic_vector(8 downto 0) := "100011100";   -- K28.0
    constant FS     : std_logic_vector(8 downto 0) := "111111110";   -- K30.7
    constant FE     : std_logic_vector(8 downto 0) := "111110111";   -- K23.7

    constant VB_VS  : std_logic_vector(8 downto 0) := "000000001";   -- 0x00  VB-ID with Vertical blank asserted 
    constant VB_NVS : std_logic_vector(8 downto 0) := "000000000";   -- 0x00  VB-ID without Vertical blank asserted
	constant Mvid   : std_logic_vector(8 downto 0) := "000000010";   -- 0x02
    constant Maud   : std_logic_vector(8 downto 0) := "000000000";   -- 0x00    

	constant HtotH  : std_logic_vector(8 downto 0) := "000000100";   -- Total 1056
    constant HTotL  : std_logic_vector(8 downto 0) := "000100000";  
    constant HstH   : std_logic_vector(8 downto 0) := "000000000";   -- Start 128 + 88 = 216
    constant HstL   : std_logic_vector(8 downto 0) := "011011000";   
    constant HswH   : std_logic_vector(8 downto 0) := "000000000";   -- Sync width 128
    constant HswL   : std_logic_vector(8 downto 0) := "010000000";   
    constant HwidH  : std_logic_vector(8 downto 0) := "000000011";   -- Active width 800  
    constant HwidL  : std_logic_vector(8 downto 0) := "000100000";   

    constant VtotH  : std_logic_vector(8 downto 0) := "000000010";   -- Total Lines 628  
    constant VtotL  : std_logic_vector(8 downto 0) := "001110100";   
    constant VstH   : std_logic_vector(8 downto 0) := "000000000";   -- Start = 4+23 = 27
    constant VstL   : std_logic_vector(8 downto 0) := "000011011";   
    constant VswH   : std_logic_vector(8 downto 0) := "000000000";   -- Vert Sync Width 4
    constant VswL   : std_logic_vector(8 downto 0) := "000000100";   
    constant VheiH  : std_logic_vector(8 downto 0) := "000000010";   -- Active lines   600    
    constant VheiL  : std_logic_vector(8 downto 0) := "001011000";   
    
    constant MISC0  : std_logic_vector(8 downto 0) := "000100001";   -- MISC0 - Sync, RGB, Full range, 8bpp
    constant MISC1  : std_logic_vector(8 downto 0) := "000000000";   -- MISC1

	constant MvidH  : std_logic_vector(8 downto 0) := "000000000";   -- M = 8    8/54*270MHz = 40MHz
	constant MvidM  : std_logic_vector(8 downto 0) := "000000000";
	constant MvidL  : std_logic_vector(8 downto 0) := "000001000";
    constant NvidH  : std_logic_vector(8 downto 0) := "000000000";   -- N = 54   8/54*270MHz = 40MHz
    constant NvidM  : std_logic_vector(8 downto 0) := "000000000";   
    constant NvidL  : std_logic_vector(8 downto 0) := "000110110";   
	
    
    constant test_data_blocks : a_test_data_blocks := (
	--- Block 0 - Junk
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, 

	--- Block 1 - Mains Stream attribuutes, junk and blank end
	SS,    SS,    MvidH, MvidM, MvidL, HtotH,  
    HTotL, VtotH, VtotL, HswH,  HswL,  MvidH, 
    MvidM, MvidL, HstH,  HstL,  VstH,  VstL, 
    VswH,  VswL,  MvidH, MvidM, MvidL, HwidH,  
    HwidL, VheiH, VheiL, ZERO,  ZERO,  MvidH, 
    MvidM, MvidL, NvidH, NvidM, NvidL, MISC0,
    MISC1, ZERO,  SE,    DUMMY, DUMMY, DUMMY,
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, BE,  
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, 


	--- Block 2 - 8 pixels and padding
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B,
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	FS,    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, FE,  
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, 

	--- Block 3 - 8 pixels, Blank Start, VB-ID (no vsync), Mvid, MAud and junk
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B,
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	BS,    VB_NVS,MVID,  MAUD,  VB_NVS,MVID,  
    MAUD,  VB_NVS,MVID,  MAUD,  VB_NVS,MVID,      
    MAUD,  DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, 

	--- Block 4 - 8 pixels, Blank Start, VB-ID (+vsync), Mvid, MAud and junk
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B,
	PIX_R, PIX_G, PIX_B, PIX_R, PIX_G, PIX_B, 
	BS,    VB_VS, MVID,  MAUD,  VB_VS, MVID,  
    MAUD,  VB_VS, MVID,  MAUD,  VB_VS, MVID,      
    MAUD,  DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, 

	--- Block 5 - DUMMY,Blank Start, VB-ID (+vsync), Mvid, MAud and junk
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	BS,    VB_VS, MVID,  MAUD,  VB_VS, MVID,  
    MAUD,  VB_VS, MVID,  MAUD,  VB_VS, MVID,      
    MAUD,  DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE,

	--- Block 6 - just blank end
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, 
    DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, DUMMY,
	DUMMY, DUMMY, DUMMY, DUMMY, DUMMY, BE,  
	SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE, SPARE); 

    signal index : unsigned (8 downto 0) := (others => '0');  -- Index up to 8 x 64 symbol blocks
    signal d0: std_logic_vector(8 downto 0);
    signal d1: std_logic_vector(8 downto 0);
    signal line_count : unsigned(9 downto 0) := (others => '0');
    signal row_count  : unsigned(7 downto 0) := (others => '0');
begin
    data0   <= d0(7 downto 0);
    data0k  <= d0(8);
    data1   <= d1(7 downto 0);
    data1k  <= d1(8);

process(clk)
     begin
        if rising_edge(clk) then
            d0   <= test_data_blocks(to_integer(index+0));
            d1   <= test_data_blocks(to_integer(index+1));
            if index(5 downto 0) = 52 then
                index(5 downto 0) <= (others => '0');
                if row_count = 131 then 
                    row_count <= (others => '0');
                    if line_count = 627 then
                        line_count <= (others => '0');
                    else
                        line_count <= line_count + 1;
                    end if;
                else  
                    row_count <= row_count +1;
                end if;
                
                if line_count = 0 then
                    if row_count = 0 then  -- First line of active video
                        index(8 downto 6) <= "001";  -- Main stream attribues plus BE                        
                    elsif row_count < 100 then
                        index(8 downto 6) <= "010";  -- Pixels plus fill
                    elsif row_count = 100 then
                        index(8 downto 6) <= "011";  -- Pixels BS and VS-ID block (no VBLANK flag)       
                    else
                        index(8 downto 6) <= "000";  -- Dummy symbols
                    end if;
                elsif line_count < 599 then -- lines of active video (except first and last)
                    if row_count = 0 then
                        index(8 downto 6) <= "110";  -- just BE                        
                    elsif row_count < 100 then
                        index(8 downto 6) <= "010";  -- Pixels plus fill
                    elsif row_count = 100 then
                        index(8 downto 6) <= "011";  -- Pixels BS and VS-ID block (no VBLANK flag)                        
                    else
                        index(8 downto 6) <= "000";  -- Dummy symbols
                    end if;
                elsif line_count = 599 then  -- Last line of active video
                    if row_count = 0 then
                        index(8 downto 6) <= "110";  -- just BE                        
                    elsif row_count < 100 then
                        index(8 downto 6) <= "010";  -- Pixels plus fill
                    elsif row_count = 100 then
                        index(8 downto 6) <= "100";  -- Pixels BS and VS-ID block (with VBLANK flag)                        
                    else
                        index(8 downto 6) <= "000";  -- Dummy symbols
                    end if;
                else                        
                    if row_count = 0 then
                        index(8 downto 6) <= "000";  -- Dummy symbols                        
                    elsif row_count < 100 then
                        index(8 downto 6) <= "000";  -- Dummy symbols
                    elsif row_count = 100 then
                        index(8 downto 6) <= "101";  -- Dummy symbols, BS and VS-ID block (with VBLANK flag)                        
                    else
                        index(8 downto 6) <= "000";  -- Dummy symbols
                    end if;
                end if;
            else
                index <= index + 2;
            end if;
        end if;
            
     end process;
end architecture;