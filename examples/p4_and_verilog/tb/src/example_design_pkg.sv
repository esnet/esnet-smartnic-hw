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
   // local data types 

   typedef string strArray[$];
   typedef bit [1023:0] bitArray;
  
   typedef struct {
      logic [TDATA_NUM_BYTES*8-1:0] tdata;
      logic [TDATA_NUM_BYTES-1:0]   tkeep;
      logic                         tlast;
   } AXIS_T;

   typedef struct {
      string Name;
      int    Value;
   } NameValuePair;

   typedef enum {
      TBL_ADD,
      TBL_MODIFY,
      TBL_DELETE,
      TBL_CLEAR,
      RST_STATE,
      RUN_TRAFFIC,
      NOP
   } CliCmdOp;
   
   typedef struct {
      CliCmdOp cmd_op;
      int      entry_id;
      string   traffic_filename;
      string   table_name;
      string   action_name;
      strArray match_fields;
      strArray action_params;
   } CliCmdStruct;

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
       
       if (str.substr(0, 1) == "0x")
           str = str.substr(2, str.len()-1);  
           
       for (int i = 0; i < str.len(); i++) begin
          char   = str.substr(i, i);
          nibble = char.atohex();
          hex    = {hex[$high(hex)-$size(nibble):0], nibble};
      end
      
       return hex;
   endfunction

   // return packet bytes from TEXT file
   function automatic string read_text_file (
      input string filename,       // path to file
      input bit    required  = 1,  // error if required and file not found
      input byte   delimiter = " " // delimiter between lines
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
            if (line[0] == "%" || line[0] == "#" || line[0] == "\n" || line.len() == 0)
                continue; // Comments allowed, but ignored
            lines = {lines, delimiter, line.substr(0, line.len()-2)};
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
      input  string filename,                                // path to *.meta file
      input  string metadata_formatStr,                      // metadata format used to parse the file
      output logic [USER_META_DATA_WIDTH-1:0] axis_words[$]  // metadata words array
   );

      NameValuePair metadata_format[$];
      string lines, fname, fvalue;
      bitArray metadata[string];
      strArray name_value_pairs;
      strArray name_value_pair;
      strArray line_array;
      strArray lines_array;
      int cnt, width;

      // read metadata
      lines_array = split(metadata_formatStr, ",");
      for (cnt = 0; cnt < lines_array.size(); cnt++) begin
        line_array = split(lines_array[cnt], "=");
        metadata_format[0] = '{Name: line_array[0], Value: str2hex(line_array[1])};
      end

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

            for (int j = 0; j < metadata_format.size(); j++) begin
                if ($sformatf("%s", metadata_format[j].Name) == $sformatf("%s", fname)) begin
                   fname = metadata_format[j].Name;
                   metadata[fname] = str2hex(fvalue);
                   break;
                end
            end             
        end
        
        // build AXIS word            
        for (int i = 0; i < metadata_format.size(); i++) begin            
            fname = metadata_format[i].Name;
            width = metadata_format[i].Value;
            
            if (metadata.exists(fname)) begin
                axis_words[cnt] = (axis_words[cnt] << width) | metadata[fname];
            end else begin
                axis_words[cnt] = (axis_words[cnt] << width) | 0;
            end
        end
      end
      
      $display("** Info: Finished reading metadata file %s", filename);
   endfunction

   // parse table math fields string and convert it to bit array
   function automatic void parse_match_fields (
      input  string   FormatStringPtr,     // table format string
      input  strArray match_fields_array,  // match fields string (space separated)
      output bitArray entry_key,           // entry key
      output bitArray entry_mask           // entry mask
   );
   
      strArray key_format_array;
      strArray match_fields;
      bitArray keys[$];
      bitArray masks[$];
      int key_len, mask_len, ret;
      string key, mask, key_type;
            
      // initialize variables
      entry_key = '0;
      entry_mask = '0;
      key_format_array = split(FormatStringPtr, ":");

      // match fields size check
      if (match_fields_array.size() != key_format_array.size()) begin
          $fatal(1, "** Error: invalid match fields. Expected %0d, specified %0d", key_format_array.size(), match_fields_array.size());
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
      input  int      action_arg_widths[$], // action args width list
      input  int      action_id,            // action ID
      input  int      action_id_width,      // action ID width
      input  strArray action_params,        // action parameters string (space separated)
      output bitArray entry_resp            // entry response
   );
   
      int field_width;

      // action parameters size check
      if (action_params.size() != action_arg_widths.size()) begin
          $fatal(1, "** Error: invalid parameters size. Expected %0d, specified %0d", action_params.size(), action_arg_widths.size());
      end

      // parse action parameters and build table response 
      entry_resp = 0;
      for (int i = 0; i < action_params.size(); i++) begin
          field_width = action_arg_widths[i];
          entry_resp = (entry_resp << field_width) | str2hex(action_params[i]);
      end
      entry_resp = (entry_resp << action_id_width) | action_id;
      
   endfunction
   
   // split action parameters and priority fields based on table mode
   function automatic void split_action_params_and_prio (
      input  int      table_is_ternary,
      input  strArray action_params_and_prio,
      output strArray action_params,
      output int      entry_priority
   );

      if (!table_is_ternary) begin
          action_params  = action_params_and_prio[0:action_params_and_prio.size()-1];
          entry_priority = 0;
      end else begin
          action_params  = action_params_and_prio[0:action_params_and_prio.size()-2];
          entry_priority = action_params_and_prio[action_params_and_prio.size()-1].atoi();   
      end
   
   endfunction

   function automatic void parse_cli_commands (
      input string        filename,    // path to *.txt file
      output CliCmdStruct cli_cmds[$]  // list of pre-parsed cli commands
   );

      int delim_idx;
      int entry_id;
      int cmd_idx;
      CliCmdStruct cli_cmd;
      string lines, line;
      string cmd_name;
      string table_name;
      strArray lines_array;
      strArray cmd_line;
      strArray table_entry_handles[string][$];
      strArray empty_strArray_list[$];
      strArray empty_strArray;    

      // open file
      lines = read_text_file(filename, 1, "\n");
      lines_array = split(lines, "\n");

      // read lines
      cmd_idx = 0;
      for (int cnt = 0; cnt < lines_array.size(); cnt++) begin
          cli_cmd = '{NOP, -1, "", "", "", empty_strArray, empty_strArray};
          line = lines_array[cnt];

          // split line and parse command
          cmd_line = split(line, " ");
          cmd_name = cmd_line[0];
          case (cmd_name)

            // table_add <table name> <action name> <match fields> => [action parameters] [priority]
            "table_add" : begin
                table_name = cmd_line[1];
                for (delim_idx = 1; delim_idx < cmd_line.size(); delim_idx++) begin
                    if (cmd_line[delim_idx] == "=>")
                        break;
                end
                cli_cmd.cmd_op        = TBL_ADD;
                cli_cmd.table_name    = table_name;
                cli_cmd.action_name   = cmd_line[2];
                cli_cmd.match_fields  = cmd_line[3:delim_idx-1];
                cli_cmd.action_params = cmd_line[delim_idx+1:cmd_line.size()-1];
                if (!table_entry_handles.exists(table_name))
                    table_entry_handles[table_name] = empty_strArray_list;
                for (int i = 0; i <= table_entry_handles[table_name].size(); i++) begin
                    if (i == table_entry_handles[table_name].size())
                       table_entry_handles[table_name][i] = empty_strArray;
                    if (table_entry_handles[table_name][i].size() == 0) begin
                        table_entry_handles[table_name][i] = cli_cmd.match_fields;
                        cli_cmd.entry_id = i;
                        break;
                    end
                end
            end

            // table_modify <table name> <action name> <entry handle> => [action parameters]
            "table_modify" : begin
                table_name = cmd_line[1];
                entry_id   = cmd_line[3].atoi();
                cli_cmd.cmd_op         = TBL_MODIFY; 
                cli_cmd.table_name     = table_name;
                cli_cmd.action_name    = cmd_line[2];
                cli_cmd.entry_id       = entry_id;
                cli_cmd.action_params  = cmd_line[5:cmd_line.size()-1];
                cli_cmd.match_fields   = table_entry_handles[table_name][entry_id];
            end

            // table_delete <table name> <entry handle>
            "table_delete" : begin
                table_name = cmd_line[1];
                entry_id   = cmd_line[2].atoi();
                cli_cmd.cmd_op       = TBL_DELETE;
                cli_cmd.table_name   = table_name;
                cli_cmd.entry_id     = entry_id;
                cli_cmd.match_fields = table_entry_handles[table_name][entry_id];
                table_entry_handles[table_name][entry_id] = empty_strArray;
            end

            // table_clear <table name>
            "table_clear" : begin
                table_name = cmd_line[1];
                cli_cmd.cmd_op     = TBL_CLEAR;
                cli_cmd.table_name = table_name;
                for (int i = 0; i <= table_entry_handles[table_name].size(); i++) begin
                    if (table_entry_handles[table_name][i].size() > 0) begin
                        table_entry_handles[table_name][i] = empty_strArray;
                    end
                end
            end

            // reset_state 
            "reset_state" : begin
                cli_cmd.cmd_op = RST_STATE;                      
            end
            
            // run_traffic <file name>
            "run_traffic" : begin
                cli_cmd.cmd_op = RUN_TRAFFIC;
                cli_cmd.traffic_filename = cmd_line[1];
            end
            
            // exit
            "exit" : begin
                break;
            end
    
            // ignore invalid commands
            default : begin
                $display("** Info: Ignoring invalid command '%0s'", cmd_name);
                continue;
            end

          endcase

          cli_cmds[cmd_idx] = cli_cmd;
          cmd_idx = cmd_idx + 1;
      end
   
      $display("** Info: Finished reading CLI commands file %s", filename);
   endfunction

endpackage
