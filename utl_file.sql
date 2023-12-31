

-- UTL_FILE routine does not seem to work

declare 
l_fhandle                  utl_file.file_type;
l_string                   varchar2 (32767);
l_pos                      integer;
l_tag_type                 varchar2 (30);
l_next varchar2 (100);
  function next_item return varchar2 
  is 
  l_return varchar2 (30);
  begin
    l_string := ltrim (l_string, ',');
	if substr (l_string, 1, 1) = '"'
	then 
	  l_pos    := instr  (l_string, '"', 2, 1);
	  l_return := substr (l_string, 2, l_pos - 2);
	else
	  l_pos    := instr  (l_string, ',');
	  l_return := substr (l_string, 1, l_pos - 1);
	end if;
      l_string := substr (l_string, l_pos + 1);	
	return l_return;
	
  exception when others then
    util.show_error ('Error in function next_item', sqlerrm);
    return null;
  end next_item;
begin 
    l_fhandle := utl_file.fopen ('GARMIN' , 'fit.csv', 'r' );
	dbms_output.put_line ('file opened');
loop
  begin 
    utl_file.get_line (l_fhandle, l_string, 32767);
	l_next := next_item;
	if l_next = 'Data'
	then
	  l_next     := next_item;
	  l_tag_type := next_item;
	  while l_string is not null
	  loop
	    begin
		   l_next := next_item;
		   insert into tags values (l_tag_type, l_next);
		   commit;
		   l_next := next_item;
	       l_next := next_item;
		exception when dup_val_on_index then null;
		end;
	  end loop;
	end if;
  exception when no_data_found then utl_file.fclose (l_fhandle); exit;
  end;
end loop;

exception
   when utl_file.invalid_path then
      utl_file.fclose_all;
      raise_application_error(-20051, 'Invalid Path');
    when utl_file.invalid_mode then
      utl_file.fclose_all;
      raise_application_error(-20052, 'Invalid Mode');
    when utl_file.internal_error then
      utl_file.fclose_all;
      raise_application_error(-20053, 'Internal Error');
    when utl_file.invalid_operation then
      utl_file.fclose_all;
      raise_application_error(-20054, 'Invalid Operation');
    when utl_file.invalid_filehandle then
      utl_file.fclose_all;
      raise_application_error(-20055, 'Invalid filehandle');
    when utl_file.write_error then
      utl_file.fclose_all;
      raise_application_error(-20056, 'Write error');
end;
/
