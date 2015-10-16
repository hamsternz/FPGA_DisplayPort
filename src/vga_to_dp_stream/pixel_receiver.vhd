----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:32:01 10/12/2015 
-- Design Name: 
-- Module Name:    pixel_receiver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_receiver is
    Port ( pixel_clk     : in  STD_LOGIC;
           pixel_data    : in  STD_LOGIC_VECTOR (23 downto 0);
           pixel_hblank  : in  STD_LOGIC;
           pixel_hsync   : in  STD_LOGIC;
           pixel_vblank  : in  STD_LOGIC;
           pixel_vsync   : in  STD_LOGIC;
           
           --------------------------------------------------
           -- These should be stable when ready is asserted
           --------------------------------------------------
           h_visible     : in  STD_LOGIC_VECTOR (12 downto 0) := (others => '0');

           dp_clk        : in  STD_LOGIC;
           ch0_data_0    : out  STD_LOGIC_VECTOR (8 downto 0);
           ch0_data_1    : out  STD_LOGIC_VECTOR (8 downto 0));
end pixel_receiver;

architecture Behavioral of pixel_receiver is
   constant BLANK_END   : std_logic_vector(8 downto 0) := "111111011";  -- 0x1FB
   constant BLANK_START : std_logic_vector(8 downto 0) := "110111100";  -- 0x1BC
   constant FILL_END    : std_logic_vector(8 downto 0) := "111110111";  -- 0x1F7
   constant FILL_START  : std_logic_vector(8 downto 0) := "111111110";  -- 0x1FE
   constant VBID        : std_logic_vector(8 downto 0) := "000000000";  -- 0x1FE
   constant Mvid        : std_logic_vector(8 downto 0) := "000000001";  -- 0x1FE
   constant Maud        : std_logic_vector(8 downto 0) := "000000000";  -- 0x1FE
   constant dummy       : std_logic_vector(8 downto 0) := "000001111";  -- 0x00F
   
   constant use_Zero    : std_logic_vector(3 downto 0) := "0000";
   constant use_data    : std_logic_vector(3 downto 0) := "0001";
   constant use_BE      : std_logic_vector(3 downto 0) := "0010";
   constant use_BS      : std_logic_vector(3 downto 0) := "0011";
   constant use_FS      : std_logic_vector(3 downto 0) := "0100";
   constant use_FE      : std_logic_vector(3 downto 0) := "0101";
   constant use_VBID    : std_logic_vector(3 downto 0) := "0110";
   constant use_MVID    : std_logic_vector(3 downto 0) := "0111";
   constant use_MAUD    : std_logic_vector(3 downto 0) := "1000";
   
   
   component memory_32x36_r128x9 is
    Port ( clk_a  : in  STD_LOGIC;
           data_a : in  STD_LOGIC_VECTOR (35 downto 0);
           addr_a : in  STD_LOGIC_VECTOR (4 downto 0);
           we_a   : in  STD_LOGIC;
           
           clk_bc   : in  STD_LOGIC;
           addr_b   : in  STD_LOGIC_VECTOR (6 downto 0);
           data_b_0 : out STD_LOGIC_VECTOR (8 downto 0);
           data_b_1 : out STD_LOGIC_VECTOR (8 downto 0));
   end component;

   constant TU_SIZE     : natural := 54;
   constant DATA_PER_TU : natural := 24;
   -----------------------------
   -- In the pixel clock domain
   -----------------------------
   signal pc_mem_data_formatted    : std_logic_vector(35 downto 0) := (others => '0');
   signal pc_mem_we                : std_logic := '0';
   signal pc_mem_addr              : STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
   signal pc_line_start_toggle     : std_logic := '0';
   signal pixel_blank              : std_logic := '0';
   signal pc_hblank_last           : std_logic := '0';
   -----------------------------
   -- Between clock domain
   -----------------------------
   signal line_start_toggle_meta_0p0 : std_logic := '0';
   signal line_start_toggle_meta_0p5 : std_logic := '0';
   signal vblank_meta                : std_logic := '0';
   ----------------------------------
   -- In the DisplayPort clock domain
   ----------------------------------
   signal dp_output_selector        : STD_LOGIC_VECTOR(7 downto 0);
   signal dp_line_start_toggle_last : std_logic := '0'; 
   signal dp_line_start_toggle_0p0  : std_logic := '0';
   signal dp_line_start_toggle_0p5  : std_logic := '0';
   signal dp_sending                : std_logic := '0';
   signal dp_mem_addr               : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');
   signal dp_word_in_tu             : unsigned(5 downto 0)  := (others => '0');
   signal dp_countdown_to_start     : unsigned(5 downto 0)  := (others => '0');
   signal dp_pixels_sent            : unsigned(11 downto 0)  := (others => '0');
   signal dp_mem_data_ch0_0         : STD_LOGIC_VECTOR(8 downto 0)  := (others => '0');
   signal dp_mem_data_ch0_1         : STD_LOGIC_VECTOR(8 downto 0)  := (others => '0');
   signal dp_vblank                 : std_logic := '0';
   signal dp_send_vbid_count           : unsigned(3 downto 0) := (others => '0');
begin
   pixel_blank <= pixel_hblank or pixel_vblank;
ch0_buffer: memory_32x36_r128x9 port map (
      clk_a  => pixel_clk,
      addr_a => pc_mem_addr,
      data_a => pc_mem_data_formatted,
      we_a   => pc_mem_we,
      
      clk_bc   => dp_clk,
      addr_b   => dp_mem_addr,
      data_b_0 => dp_mem_data_ch0_0,
      data_b_1 => dp_mem_data_ch0_1
      );
                    
data_transfer_proc: process(pixel_clk)
   begin
      --------------------------------
      -- Just write all the pixels to 
      -- memory, but reset address to  
      -- zero when hbank drops.
      --------------------------------
      if rising_edge(pixel_clk) then
         pc_mem_data_formatted               <= (others => '0');
         pc_mem_data_formatted( 8 downto  0) <= pixel_blank & pixel_data( 7 downto  0);
         pc_mem_data_formatted(17 downto  9) <= pixel_blank & pixel_data(15 downto  8);
         pc_mem_data_formatted(26 downto 18) <= pixel_blank & pixel_data(23 downto 16);
         pc_mem_we                           <= '1';
         pc_mem_addr                         <= std_logic_vector(unsigned(pc_mem_addr)+ 1);

         if pc_hblank_last = '1' and pixel_hblank = '0' then
            ---------------------------------------------
            -- Reset the write address, so the DP side an 
            -- sync up in 64 DisplayPort cycles
            ---------------------------------------------
            pc_mem_addr <= (others => '0');
            ---------------------------------------------
            -- Signal to the DP domain that we have 
            -- started receiving a new line
            ---------------------------------------------
            pc_line_start_toggle <= not pc_line_start_toggle; 
         end if;
         pc_hblank_last <= pixel_hblank;
      end if;
   end process;
   
process(dp_clk)
   begin
      if falling_edge(dp_clk) then
         line_start_toggle_meta_0p5 <= pc_line_start_toggle; 
      end if;
      if rising_edge(dp_clk) then
         ---------------------------------------
         -- This can just be continually updated.
         -- It might get ovewritten later on
         ---
         -- (and relies on delayed asignments to
         -- work).
         ---------------------------------------         
         dp_word_in_tu <= dp_word_in_tu + 2;

         ------------------------------------------------------------
         -- The tricky bits - advancing the memory address
         -- for the dual ported RAMs. Once again relies on 
         -- delayed assignments to work.
         --
         -- Option 1: Advance by two. When two data words are sent
         -- Option 2: Advance by one. When only one data word is sent
         -- Option 3: No advancing
         ------------------------------------------------------------
          if dp_countdown_to_start = 2 then
            -- Set to 0
            dp_mem_addr    <= (0=>'0', others => '1');
         elsif dp_countdown_to_start = 1     then       -- BE followed with data 
            -- Set to -1;
            dp_mem_addr    <= (others => '1');
         elsif dp_word_in_tu = DATA_PER_TU-1 or    -- Data follows by BE or FS
            dp_word_in_tu = TU_SIZE-1     then     -- FE followed with first data of new TU
            -- Advance by one, skipping over the adresses that end in "11" 
            if dp_mem_addr( 1 downto 0) = "10" then
               dp_mem_addr    <= std_logic_vector(unsigned(dp_mem_addr) + 2);
               dp_pixels_sent <= dp_pixels_sent + 1;
            else
               dp_mem_addr    <= std_logic_vector(unsigned(dp_mem_addr) + 1);
            end if;
         elsif dp_word_in_tu < DATA_PER_TU-1 then
            -- Advance by two, skipping over the adresses that end in "11" 
            if dp_mem_addr( 1 downto 0) = "01" or dp_mem_addr( 1 downto 0) = "10" then
               dp_mem_addr    <= std_logic_vector(unsigned(dp_mem_addr) + 3);
            else
               dp_mem_addr    <= std_logic_vector(unsigned(dp_mem_addr) + 2);
               dp_pixels_sent <= dp_pixels_sent + 1;
            end if;
         end if;                     

         ---------------------------------
         -- Set the output for this cycle
         ---------------------------------
         case dp_output_selector(3 downto 0) is 
            when use_BE   => ch0_data_0 <= BLANK_END;
            when use_data => ch0_data_0 <= dp_mem_data_ch0_0;
            when use_BS   => ch0_data_0 <= BLANK_START; 
            when use_FS   => ch0_data_0 <= FILL_START; 
            when use_FE   => ch0_data_0 <= FILL_END; 
            when use_VBID => ch0_data_0 <= VBID; 
            when use_Mvid => ch0_data_0 <= Mvid;
            when use_Maud => ch0_data_0 <= Maud;
            when others   => ch0_data_0 <= "000000000";
         end case;

         case dp_output_selector(7 downto 4) is 
            when use_BE   => ch0_data_1 <= BLANK_END;
            when use_data => ch0_data_1 <= dp_mem_data_ch0_1;
            when use_BS   => ch0_data_1 <= BLANK_START; 
            when use_FS   => ch0_data_1 <= FILL_START; 
            when use_FE   => ch0_data_1 <= FILL_END; 
            when use_VBID => ch0_data_1 <= VBID; 
            when use_Mvid => ch0_data_1 <= Mvid;
            when use_Maud => ch0_data_0 <= Maud;
            when others   => ch0_data_1 <= "000000000";
         end case;
         
         ---------------------------------
         -- Default to sending 00F
         ---------------------------------
         dp_output_selector <= use_Zero &  use_Zero;

         ---------------------------------------
         -- Do we need to set up for a new line?
         ---------------------------------------
         if dp_line_start_toggle_0p0 /= dp_line_start_toggle_last then
            -- Starting in the first alignment
            dp_countdown_to_start <= to_unsigned(TU_SIZE-2,6);
            dp_sending <= '0';            
         elsif dp_line_start_toggle_0p5 /= dp_line_start_toggle_0p0 then
            -- Starting in the other alignment
            dp_countdown_to_start <= to_unsigned(TU_SIZE-1,6);
            dp_sending <= '0';
         end if;
         
         if dp_countdown_to_start = 2 then
            if dp_vblank = '0' then
               dp_output_selector <= use_BE & use_Zero;
            end if;
            dp_sending     <= '1';
            dp_mem_addr    <= (others => '1');         -- NOTE -1
            dp_word_in_tu  <= (others => '0');
            dp_pixels_sent <= (others => '0');
            dp_countdown_to_start <= dp_countdown_to_start - 2;
         elsif dp_countdown_to_start = 1 then
            if dp_vblank = '0' then
               dp_output_selector <= use_data & use_BE;
            end if;
            dp_sending     <= '1';
            dp_mem_addr    <= (others => '1');  -- NOTE -1
            dp_word_in_tu  <= (1=>'1',others => '0');
            dp_pixels_sent <= (others => '0');
            dp_countdown_to_start <= dp_countdown_to_start - 2;
         elsif dp_countdown_to_start > 0 then
            dp_countdown_to_start <= dp_countdown_to_start - 2;
         end if;

         if dp_sending = '1' then
            if dp_word_in_tu < DATA_PER_TU then               
               if dp_vblank = '0' then
                  dp_output_selector <= use_Data & use_Data;
               end if;
            elsif dp_word_in_tu = DATA_PER_TU  then
               -----------------------------------
               -- Did we just send the last active
               -- pixe data for the line?
               -----------------------------------
               if dp_pixels_sent = unsigned(h_visible) then
                  ----------------------------------
                  -- Yes, start the blanking interval
                  ----------------------------------
                  dp_output_selector <= use_VBID & use_BS;
                  dp_sending         <= '0';
                  dp_send_vbid_count    <= "1011";
               else
                  -----------------------------------
                  -- No, we need to add fill sequence
                  -- However there are three different 
                  -- options depending on how much of
                  -- the TU is holding active data.
                  -----------------------------------                           
                  if dp_vblank = '0' then
                     if DATA_PER_TU = TU_SIZE-1 then
                        dp_output_selector <= use_Data & use_FE;
                     elsif DATA_PER_TU = TU_SIZE-2 then
                        dp_output_selector <= use_FE & use_FS;
                     else
                        dp_output_selector <= use_Zero & use_FS;
                     end if;
                  end if;
               end if;               
            elsif dp_word_in_tu = DATA_PER_TU-1  then
               -----------------------------------
               -- Did we just send the last active
               -- pixe data for the line?
               -----------------------------------
               if dp_pixels_sent = unsigned(h_visible)-1 then
                  ----------------------------------
                  -- Yes, start the blaning interval
                  ----------------------------------
                  dp_output_selector <= use_BS & use_DATA;
                  dp_sending    <= '0';
               else
                  -----------------------------------
                  -- No, we need to add fill sequence
                  -- 
                  -- Only one special case when all but 
                  -- one word in the TU is used for active
                  -- data - the FS must be replaced with a a FE
                  -----------------------------------         
                  if dp_vblank = '0' then
                     if DATA_PER_TU = TU_SIZE-1 then
                        dp_output_selector <= use_FS & use_DATA;
                     else
                        dp_output_selector <= use_FE & use_DATA;
                     end if;
                  end if;
               end if;
            elsif dp_word_in_tu = TU_SIZE-2 then
               if dp_vblank = '0' then                 
                  dp_output_selector <= use_FS & use_Zero;
               end if;
            elsif dp_word_in_tu = TU_SIZE-1 then
               if dp_vblank = '0' then
                  dp_output_selector <= use_DATA & use_FS;
               end if;
            end if;
         end if;

         
         case dp_send_vbid_count is 
            when "1100" => dp_output_selector <= use_Mvid & use_VBID;
            when "1011" => dp_output_selector <= use_Maud & use_Mvid;
            when "1010" => dp_output_selector <= use_VBID & use_Maud;
            when "1001" => dp_output_selector <= use_Mvid & use_VBID;
            when "1000" => dp_output_selector <= use_Maud & use_Mvid;
            when "0111" => dp_output_selector <= use_VBID & use_Maud;
            when "0110" => dp_output_selector <= use_Mvid & use_VBID;
            when "0101" => dp_output_selector <= use_Maud & use_Mvid;
            when "0100" => dp_output_selector <= use_VBID & use_Maud; 
            when "0011" => dp_output_selector <= use_Mvid & use_VBID;
            when "0010" => dp_output_selector <= use_Maud & use_Mvid;
            when "0001" => dp_output_selector <= use_zero & use_Maud; 
            when others => NULL;
         end case;
         --------------------------------------------------
         -- Deciding when to send VBID and how much to send
         --------------------------------------------------
         if dp_sending = '1' then
            ----------------------------------------
            -- Assuming one active channel, so send
            -- VBID, MVID and MAUD 4 times.
            --
            -- WHen dp_word_in_tu is even, the first
            -- VBID is sent in the same transfer as 
            -- the BS symbol, so we don't need it
            ----------------------------------------
            
            if dp_word_in_tu = DATA_PER_TU  then
               dp_send_vbid_count <= "1011";   
            elsif dp_word_in_tu = DATA_PER_TU - 1 then
               dp_send_vbid_count <= "1100";   
            end if;
         elsif dp_send_vbid_count > 1 then
             dp_send_vbid_count <= dp_send_vbid_count - 2;
         else
             dp_send_vbid_count <= (others => '0');         
         end if;

         -------------------------------------
         -- Remeber the state of the toggle, 
         -- to see when a new line has started
         -------------------------------------
         dp_line_start_toggle_last <= dp_line_start_toggle_0p0;

         ---------------------------------------------------------------
         -- Bring the linestart toggle into the DisplayPort clock domain
         ---------------------------------------------------------------
         dp_line_start_toggle_0p0   <= line_start_toggle_meta_0p0;
         dp_line_start_toggle_0p5   <= line_start_toggle_meta_0p5;
         line_start_toggle_meta_0p0 <= pc_line_start_toggle; 
         
         dp_vblank              <= vblank_meta;
         vblank_meta            <= pixel_vblank;
      end if;
   end process;
end Behavioral;

