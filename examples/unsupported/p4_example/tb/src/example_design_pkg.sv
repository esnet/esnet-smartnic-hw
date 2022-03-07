// --------------------------------------------------------------------------
//   This file is owned and controlled by Xilinx and must be used solely
//   for design, simulation, implementation and creation of design files
//   limited to Xilinx devices or technologies. Use with non-Xilinx
//   devices or technologies is expressly prohibited and immediately
//   terminates your license.
//
//   XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION 'AS IS' SOLELY
//   FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//   PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE
//   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS
//   MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY
//   CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY
//   RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY
//   DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
//   IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//   REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
//   INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
//   PARTICULAR PURPOSE.
//
//   Xilinx products are not intended for use in life support appliances,
//   devices, or systems.  Use in such applications are expressly
//   prohibited.
//
//   (c) Copyright 1995-2018 Xilinx, Inc.
//   All rights reserved.
// --------------------------------------------------------------------------

package example_design_pkg;

   import sdnet_0_pkg::*;
   
   // --------------------------------------------------------------------------
   // test bench's configuration
   
`ifdef VITISNETP4_EXDES_QUIET
   localparam VERBOSE = 0;
`else
   localparam VERBOSE = 1;
`endif

`ifdef VITISNETP4_EXDES_AXI_DEBUG
   localparam AXI_DEBUG = 1;
`else
   localparam AXI_DEBUG = 0;
`endif

`ifdef VITISNETP4_EXDES_IPG_SIZE
   localparam IPG_SIZE = `VITISNETP4_EXDES_IPG_SIZE;
`else
   localparam IPG_SIZE = 0;
`endif

`ifdef VITISNETP4_EXDES_TRAFFIC_THROTTLE
   localparam TRAFFIC_THROTTLE = `VITISNETP4_EXDES_TRAFFIC_THROTTLE;
`else
   localparam TRAFFIC_THROTTLE = 0;
`endif

`ifdef VITISNETP4_EXDES_TRAFFIC_BACKPRESSURE
   localparam TRAFFIC_BACKPRESSURE = `VITISNETP4_EXDES_TRAFFIC_BACKPRESSURE;
`else
   localparam TRAFFIC_BACKPRESSURE = 0;
`endif

   // --------------------------------------------------------------------------
   // parameters
   
   export sdnet_0_pkg::TDATA_NUM_BYTES;
   export sdnet_0_pkg::USER_META_DATA_WIDTH;
   export sdnet_0_pkg::S_AXI_DATA_WIDTH;
   export sdnet_0_pkg::S_AXI_ADDR_WIDTH;
   export sdnet_0_pkg::NUM_USER_EXTERNS;
   export sdnet_0_pkg::AXIS_CLK_FREQ_MHZ;
   export sdnet_0_pkg::CAM_MEM_CLK_FREQ_MHZ;
   
   localparam CTL_CLK_FREQ_MHZ = 100;
   localparam HBM_CLK_FREQ_MHZ = 325;
   
   // --------------------------------------------------------------------------
   // Custom data types
  
   typedef struct {
      logic [TDATA_NUM_BYTES*8-1:0] tdata;
      logic [TDATA_NUM_BYTES-1:0]   tkeep;
      logic                         tlast;
   } AXIS_T;
   
   typedef string strArray[$];
   typedef bit [1023:0] bitArray;

   // --------------------------------------------------------------------------
   // Functions 
   
   // split string using delimiter
   function automatic strArray split (
      input string str_in,      // input string 
      input byte   delim = " "  // delimited character. Default ' ' (white space)
   );
   
      int str_idx = 0;  
      string str_tmp = "";
      strArray str_out;

      for (int i = 0; i <= str_in.len(); i++) begin
          if (str_in[i] == delim || i == str_in.len()) begin
            if (str_tmp.len() > 0) begin
              str_out[str_idx] = str_tmp;
              str_tmp = "";
              str_idx++;
            end
          end else begin
            str_tmp = {str_tmp, str_in[i]};
          end
      end

      return str_out;
    endfunction
    
   // check if string contains character 
   function automatic bit contains (
       input string str,  // input string
       input byte   char  // character to find
   );
   
       for (int i = 0; i <= str.len(); i++) begin
          if (str[i] == char) begin
             return 1;
          end 
       end
   
      return 0;
   endfunction
   
   // interprets the string as hexadecimal
   function automatic bitArray str2hex (
       input string str // string with hex value. May or may not contain '0x' at the beginning
   );
   
       string char;
       bit [3:0] nibble;
       bitArray hex = '0;
       
       if (str.substr(0, 2) == "0x")
           str = str.substr(3, str.len()-1);  
           
       for (int i = 0; i < str.len(); i++) begin
          char   = str.substr(i, i);
          nibble = char.atohex();
          hex    = {hex[$high(hex)-$size(nibble):0], nibble};
      end
      
       return hex;
   endfunction
   
   // return packet bytes from TEXT file
   function automatic string read_text_file (
      input string filename,     // path to file
      input bit    required = 1  // error if required and file not found
   );
   
      string line, lines;
      int fd;
      
      // open file
      fd = $fopen(filename, "r");
      if (!fd) begin
         if (required) begin
            $fatal(1, "** Error: Problem opening file %s", filename);
         end else begin
            return "";
         end
      end
      
      // read lines
      while(!$feof(fd)) begin
        if($fgets(line, fd)) begin
            if (line.getc(0) == "%")
                continue; // Comments allowed, but ignored
            lines = {lines, " ", line.substr(0, line.len()-2)};
        end
      end
   
      $fclose(fd);
      return lines;
   endfunction
   
   // return packet bytes from PCAP file
   function automatic string read_pcap_file (
       input string filename // path to file
   );
       byte data_in_8b, pcap_file_hdr [0:23], pcap_pkt_hdr [0:15];
       integer fd, r, packet_length, disk_length, byte_count, swapped;
       string lines;

       // open file
       fd = $fopen(filename, "rb");
       if (!fd) begin
          $fatal(1, "** Error: Problem opening file %s", filename);
       end
       
       // read file header
       r = $fread(pcap_file_hdr, fd); 
       if (pcap_file_hdr[0] == 8'hD4 && pcap_file_hdr[1] == 8'hC3) begin
           swapped = 1;
       end else if (pcap_file_hdr[0] == 8'hA1 && pcap_file_hdr[1] == 8'hB2) begin
           swapped = 0;
       end else begin
           $fatal(1, "** Error: Problem parsing file %s", filename);
       end       

       // get packets
       while(!$feof(fd)) begin
           
            // read packet header
		    r = $fread(pcap_pkt_hdr, fd);
		    if (swapped == 1) begin
		        packet_length = {pcap_pkt_hdr[11],pcap_pkt_hdr[10],pcap_pkt_hdr[9] ,pcap_pkt_hdr[8] };
		        disk_length   = {pcap_pkt_hdr[15],pcap_pkt_hdr[14],pcap_pkt_hdr[13],pcap_pkt_hdr[12]};
		    end else begin
		        packet_length = {pcap_pkt_hdr[ 8],pcap_pkt_hdr[ 9],pcap_pkt_hdr[10],pcap_pkt_hdr[11]};
		        disk_length   = {pcap_pkt_hdr[12],pcap_pkt_hdr[13],pcap_pkt_hdr[14],pcap_pkt_hdr[15]};
		    end

            if ($feof(fd) || packet_length == 0 || disk_length == 0)
                continue;
               
            // get bytes
            byte_count = 0;
            while(byte_count < packet_length) begin
                r = $fread(data_in_8b, fd); 
                lines = {lines, $sformatf(" %x", data_in_8b)};
                byte_count++;
            end
            
            lines = {lines, " ; "};
       end

       $fclose(fd);
       return lines;
   endfunction
   
   // parse packet file and reformat to AXI Stream words
   function automatic void parse_packet_file (
      input  string filename,       // path to *.user or *.user file
      output AXIS_T axis_words[$]   // AXI stream words array
   );
   
      int fd, byte_cnt, wrd_cnt;
      string lines, char, file_ext;
      strArray packets, pkt_bytes;

      // open file and get lines (.pcap or .user file)
      fd = $fopen($sformatf("%s.pcap", filename), "rb");      
      if (!fd) begin
         fd = $fopen($sformatf("%s.user", filename), "r");
         
         if (!fd) begin
            $fatal(1, "** Error: Packet input file format not found %s.[pcap|user]", filename);
         end else begin
            $fclose(fd);
            lines = read_text_file($sformatf("%s.user", filename));
            file_ext = "user";
         end
         
      end else begin
         $fclose(fd);
         lines = read_pcap_file($sformatf("%s.pcap", filename));
         file_ext = "pcap";
      end
      
      // parse packets
      packets = split(lines, ";");
      for (int i = 0; i < packets.size(); i++) begin 
        pkt_bytes = split(packets[i], " ");
        
        // parse bytes
        for (int j = 0; j < pkt_bytes.size(); j++) begin       
            char = pkt_bytes[j]; 
            
            if (byte_cnt == TDATA_NUM_BYTES) begin
                byte_cnt = 0;
                wrd_cnt++;
            end
            
            axis_words[wrd_cnt].tdata = char.atohex() << (8*byte_cnt) | (byte_cnt > 0 ? axis_words[wrd_cnt].tdata : 0);
            axis_words[wrd_cnt].tkeep = 1'h1 << byte_cnt | (byte_cnt > 0 ? axis_words[wrd_cnt].tkeep : 0);
            axis_words[wrd_cnt].tlast = (j == pkt_bytes.size()-1) ? 1 : 0;
            
            byte_cnt++;
        end

        wrd_cnt++;
        byte_cnt = 0;
      end
   
      $display("** Info: Finished reading packet file %s.%s", filename, file_ext);
   endfunction
   
   // parse metadata file and reformat to AXI Stream words
   function automatic void parse_metadata_file (
      input string filename,                                // path to *.meta file
      output logic [USER_META_DATA_WIDTH-1:0] axis_words[$] // metadata words array
   );

      string lines, fname, fvalue;
      bitArray metadata[string];
      strArray name_value_pairs;
      strArray name_value_pair;
      strArray lines_array;
      int fd, cnt, width;

      // open file
      lines = read_text_file($sformatf("%s.meta", filename), 0);
      lines_array = split(lines, ";");
      
      // read lines
      for (cnt = 0; cnt < lines_array.size(); cnt++) begin
        metadata.delete();
        axis_words[cnt] = 0;

        // Split string into sub-strings 'name=value'
        name_value_pairs = split(lines_array[cnt], " ");            
            
        // store metadata value
        for (int i = 0; i < name_value_pairs.size(); i++) begin               
            name_value_pair = split(name_value_pairs[i], "=");
            fname  = name_value_pair[0];
            fvalue = name_value_pair[1];

            for (int j = 0; j < XilVitisNetP4UserMetadataFields.size(); j++) begin
                if (XilVitisNetP4UserMetadataFields[j].NameStringPtr == fname) begin
                   metadata[fname] = str2hex(fvalue);
                   break;
                end
            end             
        end
        
        // build AXIS word            
        for (int i = 0; i < XilVitisNetP4UserMetadataFields.size(); i++) begin            
            fname = XilVitisNetP4UserMetadataFields[i].NameStringPtr;
            width = XilVitisNetP4UserMetadataFields[i].Value;
            
            if (metadata.exists(fname)) begin
                axis_words[cnt] = (axis_words[cnt] << width) | metadata[fname];
            end else begin
                axis_words[cnt] = (axis_words[cnt] << width) | 0;
            end
        end
      end
      
      $fclose(fd);
      $display("** Info: Finished reading metadata file %s", filename);
   endfunction

   // parse table math fields string and convert it to bit array
   function automatic void parse_match_fields (
      input  string   table_name,          // table name string
      input  strArray match_fields_array,  // match fields string (space separated)
      output bitArray entry_key,           // entry key
      output bitArray entry_mask           // entry mask
   );
   
      strArray key_format_array;
      strArray match_fields;
      bitArray keys [$];
      bitArray masks [$];
      int key_len, mask_len, ret;
      string key, mask, key_type;
      int tbl_id;
            
      // initialize variables
      entry_key = '0;
      entry_mask = '0;
      tbl_id = get_table_id(table_name);
      key_format_array = split(XilVitisNetP4TableList[tbl_id].Config.CamConfig.FormatStringPtr, ":");
      
      // table_name check
      if (tbl_id < 0) begin
          $fatal(1, "** Error: table name '%0s' not found", table_name);
      end
    
      // match fields size check
      if (match_fields_array.size() != key_format_array.size()) begin
          $fatal(1, "** Error: invalid match fields for table '%0s'. \
          Expected %0d, specified %0d", table_name, key_format_array.size(), match_fields_array.size());
      end
      
      // parse match fields
      for (int i = 0; i < match_fields_array.size(); i++) begin
          ret = $sscanf(key_format_array[match_fields_array.size()-1-i], "%d%s", key_len, key_type);
          // ternary (delimiter '&&&')
          if (contains(match_fields_array[i], "&")) begin
              match_fields = split(match_fields_array[i], "&");
              keys[i]  = str2hex(match_fields[0]);
              masks[i] = str2hex(match_fields[1]);
          // lpm (delimiter '/')
          end else if (contains(match_fields_array[i], "/")) begin
              match_fields = split(match_fields_array[i], "/");
              keys[i]  = str2hex(match_fields[0]);
              mask_len = match_fields[1].atoi();
              masks[i] = ((2**mask_len)-1) << (key_len - mask_len);
          // range (delimiter '->')
          end else if (contains(match_fields_array[i], "-")) begin
              match_fields = split(match_fields_array[i], "-");
              keys[i]  = str2hex(match_fields[0]);
              masks[i] = str2hex(match_fields[1].substr(1, match_fields[1].len()-1));
          // no-mask
          end else begin
              keys[i]  = str2hex(match_fields_array[i]);
              masks[i] = (2**key_len)-1;
          end
      end
          
      // concatenate fields
      for (int i = 0; i < match_fields_array.size(); i++) begin
          ret = $sscanf(key_format_array[match_fields_array.size()-1-i], "%d%s", key_len, key_type);
          entry_key  = (entry_key  << key_len) | keys[i];
          entry_mask = (entry_mask << key_len) | masks[i];
      end
     
   endfunction
   
   // parse action parameters string and convert it to bit array
   function automatic void parse_action_parameters (
      input  string   table_name,      // table name string 
      input  string   action_name,     // action name string
      input  strArray action_params,   // action parameters string (space separated)
      output bitArray entry_resp       // entry response
   );
   
      int act_id, tbl_id;
      int field_width;
      
      // initialize variables
      tbl_id = get_table_id(table_name);
      act_id = get_action_id(table_name, action_name);
      entry_resp = 0;
      
      // table name check
      if (tbl_id < 0) begin
          $fatal(1, "** Error: table name '%0s' not found", table_name);
      end
      
      // action name check
      if (act_id < 0) begin
          $fatal(1, "** Error: action name '%0s' not found", action_name);
      end

      // action parameters size check
      if (action_params.size() != XilVitisNetP4TableList[tbl_id].Config.ActionListPtr[act_id].ParamListPtr.size()) begin
          $fatal(1, "** Error: invalid parameters for action '%0s'. \
          Expected %0d, specified %0d", action_name, action_params.size(), 
          XilVitisNetP4TableList[tbl_id].Config.ActionListPtr[act_id].ParamListPtr.size());
      end

      // parse action parameters and build table response 
      for (int i = 0; i < action_params.size(); i++) begin
          field_width = XilVitisNetP4TableList[tbl_id].Config.ActionListPtr[act_id].ParamListPtr[i].Value;
          entry_resp = (entry_resp << field_width) | str2hex(action_params[i]);
      end
      entry_resp = (entry_resp << XilVitisNetP4TableList[tbl_id].Config.ActionIdWidthBits) | act_id;
      
   endfunction
   
   // split action parameters and priority fields based on table mode
   function automatic void split_action_params_and_prio (
      input  string   table_name,
      input  strArray action_params_and_prio,
      output strArray action_params,
      output int      entry_priority
   );

      int tbl_id;
      tbl_id = get_table_id(table_name);
      
      // table name check
      if (tbl_id < 0) begin
          $fatal(1, "** Error: table name '%0s' not found", table_name);
      end
      
      if (XilVitisNetP4TableList[tbl_id].Config.Mode == XIL_VITIS_NET_P4_TABLE_MODE_BCAM || 
          XilVitisNetP4TableList[tbl_id].Config.Mode == XIL_VITIS_NET_P4_TABLE_MODE_TINY_BCAM || 
          XilVitisNetP4TableList[tbl_id].Config.Mode == XIL_VITIS_NET_P4_TABLE_MODE_DCAM) begin
          action_params  = action_params_and_prio[0:action_params_and_prio.size()-1];
          entry_priority = 0;
      end else begin
          action_params  = action_params_and_prio[0:action_params_and_prio.size()-2];
          entry_priority = action_params_and_prio[action_params_and_prio.size()-1].atoi();   
      end
   
   endfunction

endpackage

