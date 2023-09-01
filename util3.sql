DOC

  Author   :  Theo Stienissen
  Date     :  2017
  Purpose  :  Implement errorhandling routine
  Contact  :  theo.stienissen@gmail.com
  
  @C:\Users\Theo\OneDrive\Theo\Project\Generic\util3.sql
  procedure print_string (p_string in varchar2)
  This procedure is able to print text fields up to 32K bytes
  
 create table error_log
( id             integer,
  title          varchar2(200),
  info           clob,
  created_on     date default sysdate,
  created_by     varchar2(100),
  callstack      clob,
  errorstack     clob,
  errorbacktrace clob);

create sequence error_log_seq;

create or replace trigger error_log_briu
before insert or update on error_log
for each row
begin
 if :new.id is null
 then :new.id := error_log_seq.nextval;
 end if;
end error_log_briu;
/


#
set serveroutput on size 1000000

create or replace package util
as

type rowid_array_ty is table of rowid index by binary_integer;
pkg_rowid_aray rowid_array_ty;

type int_array_ty is table of integer index by binary_integer;
pkg_int_array int_array_ty;

procedure log_error (p_title_in error_log.title%type, p_info_in error_log.info%type, p_raise in boolean default false);

procedure print_string (p_string in varchar2);

procedure print_clob (p_clob in clob);

procedure show_error (p_message in varchar2, p_error in varchar2, p_save in boolean default true, p_raise in boolean default true);

end util;
/

create or replace package body util
as

procedure log_error (p_title_in error_log.title%type, p_info_in error_log.info%type, p_raise in boolean default false)
is
pragma autonomous_transaction;
begin
  insert into error_log (title, info, created_by, callstack, errorstack, errorbacktrace)
    values (p_title_in, p_info_in, user, dbms_utility.format_call_stack, dbms_utility.format_error_stack, dbms_utility.format_error_backtrace);
  commit;
  
  if p_raise then raise_application_error (-20005, 'Error raised from routine util.log_error.'); end if;
end log_error;

/*************************************************************************************************************************************************/

procedure print_string (p_string in varchar2) is
  l_array apex_application_global.vc_arr2;
begin
  l_array := apex_util.string_to_table (p_string, chr (10));
  for i in 1 .. l_array.count
  loop
    if i < l_array.count
    then
      dbms_output.put_line (l_array(i));
    else
      dbms_output.put (l_array(i));
    end if;
  end loop;
  
exception when others then
  show_error ('Error in procedure print_string.' , sqlerrm);
end print_string;

/*************************************************************************************************************************************************/

procedure print_clob (p_clob in clob)
is
  l_offset number := 1;
  l_amount   number := 8000;
  l_length     number := dbms_lob.getlength (p_clob);
  l_buffer      varchar2 (32767);
begin
  while l_offset < l_length loop
    dbms_lob.read (p_clob, l_amount, l_offset, l_buffer);
    l_offset := l_offset + l_amount;
    print_string (l_buffer);
  end loop;
  dbms_output.new_line;
  
exception when others then
  show_error ('Error in procedure print_clob.' , sqlerrm);
end print_clob;

/*************************************************************************************************************************************************/

procedure show_error (p_message in varchar2, p_error in varchar2, p_save in boolean default true, p_raise in boolean default true)
is
  pragma autonomous_transaction;
  l_depth pls_integer;
begin
l_depth := utl_call_stack.dynamic_depth;
dbms_output.put_line (chr(10) || '***** ' || p_message || '. ' || p_error || '  *****' || chr(10));
dbms_output.put_line ('***** Call Stack Start *****');
dbms_output.put_line ('Depth     Lexical   Line      Owner     Edition   Name');
dbms_output.put_line ('.         Depth     Number');
dbms_output.put_line ('--------- --------- --------- --------- --------- --------------------');

for i in 1 .. l_depth
loop
  dbms_output.put_line( rpad(i, 10) || rpad (utl_call_stack.lexical_depth (i), 10) || rpad (to_char (utl_call_stack.unit_line (i),'9990'), 10) ||
                        rpad (nvl (utl_call_stack.owner (i),' '), 10) || rpad (nvl (utl_call_stack.current_edition (i),' '), 10) ||
                        utl_call_stack.concatenate_subprogram (utl_call_stack.subprogram (i)));
end loop;
dbms_output.put_line ('Error_Backtrace: ' || trim (dbms_utility.format_error_backtrace ()));
dbms_output.put_line ('***** Call Stack End *****' || chr(10));

l_depth := utl_call_stack.error_depth;
dbms_output.put_line ('***** Error Stack Start *****');
dbms_output.put_line ('Depth     Error     Error');
dbms_output.put_line ('.         Code      Message');
dbms_output.put_line ('--------- --------- --------------------');

for i in 1 .. l_depth
loop
  dbms_output.put_line ( rpad(i, 10) || rpad('ORA-' || lpad (utl_call_stack.error_number (i), 5, '0'), 10) || utl_call_stack.error_msg (i));
end loop; 
dbms_output.put_line ('***** Error Stack End *****' || chr(10));

if p_save
then
  insert into error_log (title, info, created_on, created_by, errorstack, errorbacktrace)
    values (p_message, p_message, sysdate, user, dbms_utility.format_error_stack (), dbms_utility.format_error_backtrace ());
  commit;
end if;
if p_raise then raise_application_error (-20005, 'Error raised from routine util.show_error.'); end if;
end show_error;

end util;
/
