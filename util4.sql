DOC

  Author   :  Theo Stienissen
  Created  :  2017
  Last update: 
  Purpose  :  Implement errorhandling routine
  Contact  :  theo.stienissen@gmail.com
  
  @C:\Users\Theo\OneDrive\Theo\Project\Generic\util4.sql
  procedure print_string (in_string in varchar2)
  This procedure is able to print text fields up to 32K bytes
   $$plsql_unit, $$PLSQL_LINE, $$PLSQL_UNIT_OWNER, $$PLSQL_UNIT_TYPE

#


 create table error_log
( id             integer generated always as identity,
  title          varchar2(200),
  info           clob,
  created_on     date default sysdate,
  created_by     varchar2(100),
  callstack      clob,
  errorstack     clob,
  errorbacktrace clob);

/*
create sequence errors_log_seq;

create or replace trigger error_log_br_iu
before insert or update on error_log
for each row
begin
 if :new.id is null
 then :new.id := error_log_seq.nextval;
 end if;
end errors_log_briu;
/
*/

set serveroutput on size 1000000

create or replace package util
as

procedure log_error (in_title in error_log.title%type, in_info in error_log.info%type, in_raise in boolean default false);

procedure print_string (in_string in varchar2);

procedure print_clob (in_clob in clob);

procedure show_error (in_message in varchar2, in_error in varchar2, in_save in boolean default true, in_raise in boolean default true);

end util;
/

create or replace package body util
as

procedure log_error (in_title in error_log.title%type, in_info in error_log.info%type, in_raise in boolean default false)
is
pragma autonomous_transaction;
begin
  insert into error_log (title, info, created_by, callstack, errorstack, errorbacktrace)
    values (in_title, in_info, user, sys.dbms_utility.format_call_stack, sys.dbms_utility.format_error_stack, sys.dbms_utility.format_error_backtrace);
  commit;
  
  if in_raise then raise_application_error (-20005, 'Error raised from routine util.log_error.'); end if;
end log_error;

/*************************************************************************************************************************************************/

procedure print_string (in_string in varchar2) is
  l_array apex_application_global.vc_arr2;
begin
  l_array := apex_util.string_to_table (in_string, chr (10));
  for i in 1 .. l_array.count
  loop
    if i < l_array.count
    then
      sys.dbms_output.put_line (l_array(i));
    else
      sys.dbms_output.put (l_array(i));
    end if;
  end loop;
  
exception when others then
  show_error ('Error in procedure print_string.' , sqlerrm);
end print_string;

/*************************************************************************************************************************************************/

procedure print_clob (in_clob in clob)
is
  l_offset     pls_integer := 1;
  l_amount     pls_integer := 8000;
  l_length     pls_integer := sys.dbms_lob.getlength (in_clob);
  l_buffer     varchar2 (32767 char);
begin
  while l_offset < l_length loop
    sys.dbms_lob.read (in_clob, l_amount, l_offset, l_buffer);
    l_offset := l_offset + l_amount;
    print_string (l_buffer);
  end loop;
  sys.dbms_output.new_line;
  
exception when others then
  show_error ('Error in procedure print_clob.' , sqlerrm);
end print_clob;

/*************************************************************************************************************************************************/

procedure show_error (in_message in varchar2, in_error in varchar2, in_save in boolean default true, in_raise in boolean default true)
is
  pragma autonomous_transaction;
  l_depth pls_integer;
begin
  l_depth := utl_call_stack.dynamic_depth;
  sys.dbms_output.put_line (chr(10) || '***** ' || in_message || '. ' || in_error || '  *****' || chr(10));
  sys.dbms_output.put_line ('***** Call Stack Start *****');
  sys.dbms_output.put_line ('Depth     Lexical   Line      Owner     Edition   Name');
  sys.dbms_output.put_line ('.         Depth     Number');
  sys.dbms_output.put_line ('--------- --------- --------- --------- --------- --------------------');

  for i in 1 .. l_depth
  loop
    sys.dbms_output.put_line( rpad (i, 10) || rpad (sys.utl_call_stack.lexical_depth (i), 10) || rpad (to_char (sys.utl_call_stack.unit_line (i),'9990'), 10) ||
                          rpad (nvl (sys.utl_call_stack.owner (i),' '), 10) || rpad (nvl (sys.utl_call_stack.current_edition (i),' '), 10) ||
                          sys.utl_call_stack.concatenate_subprogram (sys.utl_call_stack.subprogram (i)));
  end loop;
  sys.dbms_output.put_line ('Error_Backtrace: ' || trim (sys.dbms_utility.format_error_backtrace ()));
  sys.dbms_output.put_line ('***** Call Stack End *****' || chr(10));

  l_depth := sys.utl_call_stack.error_depth;  
  sys.dbms_output.put_line ('***** Error Stack Start *****');
  sys.dbms_output.put_line ('Depth     Error     Error');
  sys.dbms_output.put_line ('.         Code      Message');
  sys.dbms_output.put_line ('--------- --------- --------------------');

  for i in 1 .. l_depth
  loop
    sys.dbms_output.put_line ( rpad(i, 10) || rpad ('ORA-' || lpad (sys.utl_call_stack.error_number (i), 5, '0'), 10) || sys.utl_call_stack.error_msg (i));
  end loop; 
  sys.dbms_output.put_line ('***** Error Stack End *****' || chr(10));

  if in_save
  then
    insert into error_log (title, info, created_on, created_by, errorstack, errorbacktrace)
      values (in_message, in_message, sysdate, user, sys.dbms_utility.format_error_stack (), sys.dbms_utility.format_error_backtrace ());
    commit;
  end if;
  if in_raise then raise_application_error (-20005, 'Error raised from routine util.show_error.'); end if;
end show_error;

end util;
/


grant execute on util to public;
create public synonym util for <user>.util;