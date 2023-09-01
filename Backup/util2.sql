DOC

  Author   :  Theo Stienissen
  Date     :  2017
  Purpose  :  Implement errorhandling routine
  Contact  :  theo.stienissen@gmail.com
  
  @C:\Users\Theo\OneDrive\Theo\Project\Generic
  procedure printstring (p_string in varchar2)
  This procedure is able to print text fields up to 4000 bytes

  procedure show_error

create table error_log
( id       number(6) generated always as identity
, log_date date
, message  varchar2(400));

#
set serveroutput on size 1000000

create or replace package util
as

type rowid_array_ty is table of rowid index by binary_integer;
pkg_rowid_aray rowid_array_ty;

type int_array_ty is table of integer index by binary_integer;
pkg_int_array int_array_ty;

procedure printstring (p_string in varchar2);

procedure show_error (p_message in varchar2, p_error in varchar2, p_save in boolean default true, p_raise in boolean default true);

end util;
/

create or replace package body util
as

procedure printstring (p_string in varchar2)
is
l_lines   constant number(5) := trunc(length(p_string) / 100);
begin
for j in 0 .. l_lines
loop
  dbms_output.put(substr(p_string, j * 100 +1, 100));
  if j != l_lines then dbms_output.put('  <'); end if;
  dbms_output.new_line;
end loop;

exception when others then
  show_error('Error in procedure printstring.' , sqlerrm);
end printstring;

/*************************************************************************************************************************************************/

procedure show_error (p_message in varchar2, p_error in varchar2, p_save in boolean default true, p_raise in boolean default true)
is
  l_depth pls_integer;
begin
l_depth := utl_call_stack.dynamic_depth;
dbms_output.put_line(chr(10) || '***** ' || p_message || '. ' || p_error || '  *****' || chr(10));
dbms_output.put_line('***** Call Stack Start *****');
dbms_output.put_line('Depth     Lexical   Line      Owner     Edition   Name');
dbms_output.put_line('.         Depth     Number');
dbms_output.put_line('--------- --------- --------- --------- --------- --------------------');

for i in 1 .. l_depth
loop
  dbms_output.put_line( rpad(i, 10) || rpad(utl_call_stack.lexical_depth(i), 10) || rpad(to_char(utl_call_stack.unit_line(i),'99'), 10) ||
                        rpad(nvl(utl_call_stack.owner(i),' '), 10) || rpad(nvl(utl_call_stack.current_edition(i),' '), 10) ||
                        utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(i)));
end loop;
dbms_output.put_line('Error_Backtrace: ' || trim(dbms_utility.format_error_backtrace()));
dbms_output.put_line('***** Call Stack End *****' || chr(10));

l_depth := utl_call_stack.error_depth;
dbms_output.put_line('***** Error Stack Start *****');
dbms_output.put_line('Depth     Error     Error');
dbms_output.put_line('.         Code      Message');
dbms_output.put_line('--------- --------- --------------------');

for i in 1 .. l_depth
loop
  dbms_output.put_line( rpad(i, 10) || rpad('ORA-' || lpad(utl_call_stack.error_number(i), 5, '0'), 10) || utl_call_stack.error_msg(i));
end loop; 
dbms_output.put_line('***** Error Stack End *****' || chr(10));

if p_save
then
  insert into error_log (log_date, message) values (sysdate, substr(p_message, 1, 400));
  insert into error_log (log_date, message) values (sysdate, substr(p_error, 1, 400));
  insert into error_log (log_date, message) values (sysdate, substr(trim(dbms_utility.format_error_stack()), 1, 400));
  insert into error_log (log_date, message) values (sysdate, substr(trim(dbms_utility.format_error_backtrace()), 1, 400));
  commit;
end if;
if p_raise then raise_application_error(-20005, 'Error raised from routine util.show_error.'); end if;
end show_error;

end util;
/


