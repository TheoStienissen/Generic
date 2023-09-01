Doc

created			Dec 2022
Author			Theo Stienissen
Purpose			Alternative way to check if a number is divisible by another number. No practical use
Contact			theo.stienissen@gmail.com


Procedure voor Tiental T
0. 10x + y => y = 0 ^ T / x
1. T(10x + y) = T10x + Ty = (10T + 1) x - x +Ty = Mx - x + y => M / x - Ty
2. T * (10x + y) = 10Tx + 2x -2x + Ty = (10T + 2)x - 2x + Ty = Mx - 2x + Ty => M / 2x - Ty
3. (3T + 1) * (10x + y) = (3T + 1) * 10x + (3T + 1) * y => M / x + (3T + 1)*y
4. (2T + 1) * (10x + y) = (2T + 1) * 10x + (2T + 1) * y = (20T + 8)x + 2x + (2T + 1) * y => M / 2x + (2T + 1) * y
5. T * (10x + y) = T10x + Ty => -5x + TY => M / 5x - Ty
6. T * (10x + y) = T10x + Ty => -6x + tY => M / 6x - Ty
7. (3T + 2) * (10x + y) = (3T + 2) * 10x + (3T + 2) * y => M / x - (3T + 2) * y
8. (2T + 1) * (10x + y) = (2T + 1) * 10x + (2T + 1) * y => M / 2x - (2T + 1) * y
9. (T + 1) * (10x + y) => M / x + (T + 1)y

#

drop type div_tab;
drop type div_row;

create or replace type div_row as object (check_nr integer, divisor integer, x_part integer, t_part integer, y_part integer, new_check_nr integer);
/
create or replace type div_tab as table of div_row;
/

create or replace function check_divisibility (p_integer in integer, p_divisor in integer, p_max_counter in integer default 10) return div_tab pipelined 
is
type int_array_ty is table of pls_integer index by pls_integer;
type mod_division_row is record (x_part integer, T_part integer, y_part integer);
type mod_division_tab is table of mod_division_row index by pls_integer;
l_array        int_array_ty;
l_div_array    mod_division_tab;
l_dummy        integer;
l_y            integer;
l_x            integer;
l_T            integer := trunc (p_divisor / 10);
l_a            integer := mod   (p_divisor, 10);
l_new_check_nr integer := p_integer;
l_prev_check_nr integer;
--
function exists_in_array (p_integer in integer) return boolean 
is 
l_found  boolean := FALSE;
begin
  if l_array.count = 0 then return FALSE;
  else
    for j in l_array.first .. l_array.last 
    loop 
      l_found := l_array (j) = p_integer;
      exit when l_found;
    end loop;
  end if;
  return l_found;
end exists_in_array;
--
procedure set_new_checkval (p_last_digit in integer)
is 
begin
  l_new_check_nr := abs (l_div_array (p_last_digit).x_part * l_x + l_div_array (p_last_digit).T_part * l_T * l_y + l_div_array (p_last_digit).y_part * l_y); 
end set_new_checkval;
--
begin
if l_a = 0  then pipe row (div_row (p_integer, p_divisor, null, null, null, mod (l_x, l_t)));
else
l_div_array := mod_division_tab (
    1 => mod_division_row (1, -1, 0), 2 => mod_division_row (2, -1, 0), 3 => mod_division_row (1,  3, 1), 4 => mod_division_row (2,  2, 1), 5 => mod_division_row (5, -1, 0),
    6 => mod_division_row (6, -1, 0), 7 => mod_division_row (1, -3,-2), 8 => mod_division_row (2, -2,-1), 9 => mod_division_row (1,  1, 1));
--
  while l_array.count <= p_max_counter
  loop
    l_prev_check_nr := l_new_check_nr;
    l_y := mod (l_new_check_nr, 10); l_x := trunc (l_new_check_nr / 10);
    set_new_checkval (l_a);
    exit when exists_in_array (l_new_check_nr);
    pipe row (div_row (l_prev_check_nr, p_divisor, l_div_array (l_a).x_part, l_div_array (l_a).T_part, l_div_array (l_a).y_part, l_new_check_nr));
    exit when l_new_check_nr <= p_divisor;
    l_array (l_array.count + 1) := l_new_check_nr;
  end loop;
--
  pipe row (div_row (l_new_check_nr, p_divisor, l_div_array (l_a).x_part, l_div_array (l_a).T_part, l_div_array (l_a).y_part, mod (l_new_check_nr, p_divisor)));
end if;
end;
/