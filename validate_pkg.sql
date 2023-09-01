/*************************************************************************************************************************************************

Name:        validate_pkg.sql

Last update : January 2023
Author      : Theo stienissen
E-mail      : theo.stienissen@gmail.com
@C:\Users\Theo\OneDrive\Theo\Project\Generic\validate_pkg.sql

*************************************************************************************************************************************************/


create or replace package validate_pkg
is
function validate_isbn (p_isbn in varchar2) return boolean;

function valid_email (p_email in varchar2) return boolean;

function valid_dutch_bank_account(p_reknr in varchar2) return boolean;

end validate_pkg;
/

create or replace package body validate_pkg
is 
function validate_isbn (p_isbn in varchar2) return boolean
is
l_isbn varchar2(20) :=  replace (p_isbn,'-');
l_result number(3) := 0;
begin
  if length (l_isbn) != 13 then return false; end if;
  for j in 1 .. 12
  loop
    l_result := l_result + case mod (j,2) when 0 then 3 * substr (l_isbn, j, 1) else substr (l_isbn, j, 1) end;
  end loop;
  return mod (10 - mod (l_result, 10), 10) = substr (l_isbn, -1);

exception when others then
  util.show_error ('Error in function validate_isbn.', sqlerrm);
  return false;
end validate_isbn;

/*************************************************************************************************************************************************/

function valid_email (p_email in varchar2) return boolean
is
cemailregexp constant varchar2 (1000) := '^[a-z0-9!#$%&''*+/=?^_`{|}~-]+(\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+([A-Z]{2}|arpa|biz|com|info|intww|name|net|org|pro|aero|asia|cat|coop|edu|gov|jobs|mil|mobi|museum|pro|tel|travel|post)$';
begin
 return regexp_like (p_email, cemailregexp, 'i');

exception when others then
  util.show_error ('Error in function validate_isbn.', sqlerrm);
  return false;
end valid_email;

/*************************************************************************************************************************************************/

function valid_dutch_bank_account(p_reknr in varchar2) return boolean
is
l_reknr varchar2(20);
l_check number(3) := 0;
begin
  if length (p_reknr) not between 7 and 10 then return false; end if;
  if translate (p_reknr,'0123456789', '') is not null then return false; end if;

  l_reknr := lpad (p_reknr,10,'0');
  for i in 1 .. 10
  loop
    l_check := l_check + (11 - i) * substr (l_reknr, i, 1);
  end loop;
  return mod(l_check, 11) = 0;

exception when others then
  util.show_error ('Error in function valid_dutch_bank_account.', sqlerrm);
  return false;
end valid_dutch_bank_account;

end validate_pkg;
/


-- examples
begin
if validate_pkg.valid_dutch_bank_account(314804129)
then
  db.ms_output.put_line('Ok');
else
  dbms_output.put_line('Error');
end if;
end;
/

begin
if validate_pkg.validate_isbn('978-0-11-000222-4')
then
  dbms_output.put_line('Ok');
else
  dbms_output.put_line('Error');
end if;
end;
/
/

begin
if validate_pkg.valid_email('theo.stienissen@gmail.com')
then
  dbms_output.put_line('Ok');
else
  dbms_output.put_line('Error');
end if;
end;
/