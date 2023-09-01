DOC

Inspired by : Steven Feuerstein

Author      : Theo stienissen

Last update : December 2019

E-mail      : theo.stienissen@gmail.com

Purpose     : Basic errorhandling


  procedure log_error
  Simple errorhandling routine

  procedure printstring (p_string in varchar2)
  This procedure is able to print text fields up to 4000 bytes

  procedure show_error
  Simple errorhandling routine

 -- 12C and higher: id       number(6) generated always as identity
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

create public synonym util for theo.util;
grant execute on util to pentomino, bkp, mpp;	
#

create or replace package util authid definer
as

procedure log_error (p_title_in error_log.title%type, p_info_in error_log.info%type, p_raise in boolean default false);

procedure printstring (p_string in varchar2);

procedure show_error (p_message in varchar2, p_error in varchar2, p_save in boolean default true, p_raise in boolean default false);

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
  
  if p_raise then raise_application_error(-20005, 'Error raised from routine util.log_error.'); end if;
end log_error;

/*************************************************************************************************************************************************/

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
  show_error('Error in procedure util.printstring.' , sqlerrm);
end printstring;

/*************************************************************************************************************************************************/

procedure show_error (p_message in varchar2, p_error in varchar2, p_save in boolean default true, p_raise in boolean default false)
is
begin
  if p_save
  then
    log_error (p_message, p_error);
  end if;
  printstring (p_message);
  printstring (p_error);
  commit;
  
  if p_raise then raise_application_error(-20005, 'Error raised from routine util.show_error.'); end if;
end show_error;

end util;
/
