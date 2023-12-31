DOC
  Author   :  Unknown
  Date     :  2023
  Purpose  :  list filenames from a directory in sql or sqlplus
  Status   :  Ready
  Contact  :  theo.stienissen@gmail.com
  @C:\Users\Theo\OneDrive\Theo\Project\Generic\get_file_name.sql
  
Installation instructions: Must be installed in the SYS schema

Dependencies:
1. util package

#

create or replace type file_name_ty is table of varchar2(400);
/
create or replace type file_name_tab is table of file_name_ty;
/

create or replace function get_file_name (p_directory in varchar2, p_file_type in varchar2 default 'jpg') return file_name_tab pipelined
is
 ns          varchar2(1024);
 v_directory varchar2(1024);
begin
  v_directory := p_directory;
  sys.dbms_backup_restore.searchfiles(v_directory, ns);
  for each_file in (select fname_krbmsft AS name FROM sys.v_file_names where fname_krbmsft like '%' || p_file_type)
  loop
      pipe row (file_name_ty(each_file.name));
  end loop;
  
exception
when no_data_needed then null;
when others
then
  util.show_error('Error in fuction get_file_name! Value: ' || p_directory , sqlerrm, p_raise => true);
end get_file_name;

-- Replace <user> to the username that needs to be able to run this function
grant execute on get_file_name to <user>;
create public synonym get_file_name for sys.get_file_name;

