/*

col username for a30
col name for a30
set lines 120
select 'alter session set container = ' || p.name || ';' || chr(10)  || 'drop user MUREX_EXPIMP cascade;'  || chr(10)  || '@sys.sql'  stmt from cdb_users U, v$pdbs p
where u.username = 'MUREX_EXPIMP'
and u.con_id = p.con_id; 

select * from dba_errors where owner='C##MUREX_EXPIMP' and attribute = 'ERROR';
SELECT text from dba_source where name = 'DATA_LOAD_UNLOAD'and line = 25;
select username, machine, terminal, osuser from v$session;

*/

-- connect C##MUREX_EXPIMP/murex_expimp_123@srv0AMU8101
-- sqlplus C##MUREX_EXPIMP/murex_expimp_123@uatcl302-scan:39000/srv0tmu9001

create table C##MUREX_EXPIMP.error_log 
( ID            number(10,0), 
  LOG_TIME           date, 
  ACTION        varchar2(30 byte), 
  ERROR                      varchar2(400 byte)) tablespace USERS;

create table C##MUREX_EXPIMP.EXPORT_IMPORT_LOG 
( START_TIME date, 
  END_TIME date, 
  OPERATION varchar2(10 byte), 
  SCHEMA varchar2(30 byte), 
  FILE_NAME varchar2(100 byte), 
  STATUS varchar2(100 byte)) tablespace USERS;

create table C##MUREX_EXPIMP.monitor_data_load_unload
( id            number(10)
, log_time      date
, username      varchar2(30)
, machine       varchar2(30)
, osuser        varchar2(30)
, action        varchar2(100));

create sequence  C##MUREX_EXPIMP.monitor_data_load_unload_seq;
create sequence  C##MUREX_EXPIMP.error_seq;

drop type log_table;
drop type log_format;

create or replace type log_format as object
( id           number (5),
  text         varchar2 (32767));
/

create or replace type log_table as table of log_format;
/

create or replace package data_load_unload authid current_user
as
/* Self explanatory. */
procedure log_error (p_action in varchar2, p_error in varchar2);

/* Auditing */
procedure log_usage (p_action in varchar2); 

/* Procedure to recompile invalid objects. To be used after a datapump import. */
procedure recompile_schema (p_schema_name in varchar2);

procedure stop_datapump_job (p_schema_name in varchar2, p_jobname in varchar2);

/* Checks if a file exists in an Oracle directories. Returns 1 if exists; 0 if not exists */
function  exists_dump_file (p_dumpfilename in varchar2, p_directory_name in varchar2) return number;

/* Overloaded function. Returns TRUE or FALSE */
function  exists_dump_file (p_dumpfilename in varchar2, p_directory_name in varchar2) return boolean;

/* Datapump import. Check the example below. */
procedure import_schema (p_dumpfilename in varchar2, p_remap_from in varchar2, p_remap_to in varchar2,
                          p_directory_name in varchar2 default 'MUREX_BEST', p_parallel in number default 4);

/* Datapump export. Comment will be used as part of the dumpfile name. Check the example below. */                                                                             
 procedure export_schema (p_schema_name in varchar2, p_directory_name in varchar2 default 'MUREX_BEST',
                          p_parallel in number default 4, p_comment  in varchar2 default null);

/* Deletes a file from the filesystem. Example at the end. */
procedure remove_file (p_filename in varchar2, p_directory_name in varchar2 default 'MUREX_BEST');

/* Deletes multiple files from the filesystem. Wildcards '%' and '_' are allowed. */
procedure remove_files (p_filename in varchar2, p_directory_name in varchar2 default 'MUREX_BEST');

procedure print_invalid_objects (p_schema_name in varchar2);

/* Copy files from one database host to another over a database link. */
procedure copy_file_from_database (p_dumpfilename in varchar2, p_source_database in varchar2,
             p_from_dir in varchar2 default 'MUREX_BEST', p_to_dir in varchar2 default 'MUREX_BEST');

procedure copy_file (p_dumpfilename in varchar2, p_from_dir in varchar2 default 'MUREX_BEST', p_to_dir in varchar2 default 'MUREX_DUMPS');

/* Functionality to view the output from the export and import log 
    set linesize 999 pagesize 0
    col text for a100 wrap
    select * from table (data_load_unload.show_logfile('<fn>');
    To show only the last 20 lines (tail -20):
    select * from table (data_load_unload.show_logfile('mxtest15_ALL_ALL_4367025-180404-1709-3086221_20180720_FULL_For_Taimour_20July.exp.log'))
    order by id desc fetch first 20 rows only
*/
function  show_logfile (p_file_name in varchar2, p_directory in varchar2 default 'MUREX_BEST') return log_table pipelined;

/* Recalcualte statistics after a dumpfile has been loaded */
procedure calculate_stats (p_schema_name in varchar2, p_degree in number default 4);

procedure rename_file (p_before in varchar2, p_after in varchar2, p_directory in varchar2 default 'MUREX_BEST');

g_time    number(10);
g_proc    varchar2(100);

end data_load_unload;
/

create or replace package body data_load_unload
as
procedure log_error (p_action in varchar2, p_error  in varchar2)
is
begin
  dbms_output.put_line (dbms_utility.format_error_backtrace);
  dbms_output.put_line (p_action || ' : ' || p_error);
  insert into error_log (id, log_time, action, error) values (error_seq.nextval, sysdate,
                         substr (p_action, 1,  30), substr (p_error, 1,  400));
  commit;
  
exception when others
then raise;         
end log_error; 

/*********************************************************************************************************/ 

procedure log_usage (p_action in varchar2)
is
l_username  sys.v_$session.username%type;
l_machine   sys.v_$session.machine%type;
l_osuser    sys.v_$session.osuser%type;
begin
  select username, machine, osuser into l_username, l_machine, l_osuser from v$session where audsid = userenv('sessionid');

  insert into monitor_data_load_unload (id, log_time, username, machine, osuser, action)
    values (monitor_data_load_unload_seq.nextval, sysdate, l_username, l_machine, l_osuser, p_action);
  commit;

exception when others then
  log_error ('procedure log_usage', sqlerrm);
end log_usage;

/*********************************************************************************************************/ 
 
procedure start_timing (p_reason in varchar2)
is
begin
  g_time := dbms_utility.get_time;
  g_proc := p_reason;

exception when others then
  log_error ('procedure start_timing', sqlerrm);
end start_timing;

/*********************************************************************************************************/

procedure end_timing
is
begin
  dbms_output.put_line (rpad (g_proc, 40) || ':  ' || to_char ((dbms_utility.get_time  - g_time) / 100, '999G990D99'));

exception when others then
  log_error ('procedure end_timing', sqlerrm);
end end_timing;

/*********************************************************************************************************/

procedure recompile_schema (p_schema_name in varchar2)
as
begin
  start_timing ('Recompile schema ' || p_schema_name);
  log_usage ('recompile_schema: ' || p_schema_name);
  dbms_utility.compile_schema (schema => p_schema_name, compile_all => FALSE);
  end_timing;

exception when others then
  log_error ('procedure recompile_schema', sqlerrm);
end recompile_schema;

/*********************************************************************************************************/ 

function exists_dump_file (p_dumpfilename in varchar2, p_directory_name in varchar2) return number
is
  l_file_loc bfile := bfilename (p_directory_name, p_dumpfilename);
begin
    log_usage ('exists_dump_file1: ' || p_directory_name || ' : ' || p_dumpfilename);
  return dbms_lob.fileexists (l_file_loc);

exception when others then
  log_error ('function exists_dump_file return number', sqlerrm);
  raise;
end exists_dump_file;  

/*********************************************************************************************************/ 

function exists_dump_file (p_dumpfilename in varchar2, p_directory_name in varchar2) return boolean
is
  l_file_loc bfile := bfilename (p_directory_name, p_dumpfilename);
begin
   log_usage ('exists_dump_file2: ' || p_directory_name || ' : ' || p_dumpfilename);
  return dbms_lob.fileexists (l_file_loc) = 1;

exception when others then
  log_error ('function exists_dump_file return boolean', sqlerrm);
  raise;
end exists_dump_file;

/*********************************************************************************************************/ 

procedure import_schema (p_dumpfilename in varchar2, p_remap_from in varchar2, p_remap_to in varchar2,
                         p_directory_name in varchar2 default 'MUREX_BEST', p_parallel in number default 4)
is
  l_dp_handle     number;        -- data pump job handle
  l_job_state     varchar2 (30)  := 'undefined';
  l_status        ku$_status;    -- data pump status
  l_job_name      varchar2(100)  := 'MX_IMPORT_' || p_remap_to || '_' || to_char(sysdate, 'YYYYMMDDHH24MISS');
  l_logfile       varchar2(100)  := replace (replace (p_dumpfilename,'.dmp'),'_%U') || '.log';
  l_start_time    date           := sysdate;
begin
  start_timing ('Import schema: ' || p_remap_to);
  log_usage ('import_schema: ' || p_dumpfilename || ' : ' || p_remap_to);
  -- job_mode : 'FULL', 'SCHEMA', 'TABLE'
  l_dp_handle := dbms_datapump.open (operation => 'IMPORT', job_mode => 'SCHEMA', job_name => l_job_name);
  dbms_datapump.add_file (l_dp_handle, p_dumpfilename, p_directory_name );
  dbms_output.put_line (rpad('Import logfile', 40) || ':  ' || l_logfile);
  dbms_datapump.add_file (l_dp_handle, l_logfile, p_directory_name, null, dbms_datapump.ku$_file_type_log_file);
  dbms_datapump.metadata_filter (l_dp_handle, 'EXCLUDE_PATH_EXPR', 'IN (''STATISTICS'')');
  dbms_datapump.set_parallel (handle => l_dp_handle, degree => p_parallel);      
  dbms_datapump.metadata_remap (l_dp_handle, name => 'REMAP_SCHEMA', old_value => p_remap_from, value => p_remap_to);

  dbms_datapump.start_job (l_dp_handle);

  while l_job_state not in ('COMPLETED','STOPPED')
  loop
    l_status := dbms_datapump.get_status (handle => l_dp_handle, mask => dbms_datapump.ku$_status_job_error + dbms_datapump.ku$_status_job_status + dbms_datapump.ku$_status_wip, timeout => -1);
    l_job_state := l_status.job_status.state;
    sys.dbms_lock.sleep (5);
  end loop;

  delete export_import_log where end_time < sysdate - 366; -- Keep 1 year history
  insert into export_import_log (start_time, end_time, operation, schema, file_name, status) values (l_start_time, sysdate, 'IMPORT', p_remap_to, p_dumpfilename, l_job_state);
  commit;
  end_timing;

exception when others then
  log_error ('import_schema', sqlerrm);
end import_schema;

/*********************************************************************************************************/ 

procedure print_invalid_objects (p_schema_name in varchar2)
as
  l_count       number (6);
begin
  start_timing ('Print invalid objects ');
  log_usage ('print_invalid_objects: ' || p_schema_name);
  select count(*) into l_count from dba_objects where status <> 'VALID' and owner = p_schema_name;
  dbms_output.put_line (rpad ('Invalid objects for user ' || p_schema_name , 40) || ':  ' || to_char (l_count, '999G990'));
  end_timing;

exception when others then
  log_error ('print_invalid_objects', sqlerrm);
end print_invalid_objects;

/*********************************************************************************************************/ 

procedure export_schema (p_schema_name in varchar2, p_directory_name in varchar2 default 'MUREX_BEST',
                         p_parallel in number default 4, p_comment  in varchar2 default null)
is
l_dp_handle      number;
l_start_time     date          := sysdate;
l_dumpfile       varchar2(100) := p_schema_name || '_' || to_char (sysdate,'yyyymmddhh24mi') || trim (p_comment) || '_%U';
l_logfile        varchar2(100) := p_schema_name || '_' || to_char (sysdate,'yyyymmddhh24mi') || trim (p_comment) || '.log';
l_job_name       varchar2(60)  := 'MX_EXPORT_' || p_schema_name || '_' || to_char (sysdate, 'YYYYMMDDHH24MISS');
l_status         varchar2(100);
begin
  start_timing ('Export schema ' || p_schema_name);
  log_usage ('export_schema: ' || p_schema_name);
  dbms_output.put_line (rpad('Export logfile', 40) || ':  ' || l_logfile);
  l_dp_handle := dbms_datapump.open (operation => 'EXPORT', job_mode => 'SCHEMA', remote_link => null, job_name => l_job_name, version => 'LATEST');

  dbms_datapump.add_file (handle => l_dp_handle, filename => l_dumpfile, directory => p_directory_name);
  dbms_datapump.add_file (handle => l_dp_handle, filename => l_logfile,  directory => p_directory_name, filetype => dbms_datapump.ku$_file_type_log_file);

  dbms_datapump.set_parallel (handle => l_dp_handle, degree => p_parallel);      
  dbms_datapump.metadata_filter (handle => l_dp_handle, name => 'schema_expr', value => 'in (''' || upper(p_schema_name) || ''')');
-- flashback_time=systimestamp
  dbms_datapump.set_parameter (handle => l_dp_handle, NAME => 'FLASHBACK_SCN', value => timestamp_to_scn (systimestamp)); 
  -- exclude=TABLE:\like '%TMP'\
  dbms_datapump.metadata_filter (handle => l_dp_handle, name=>'NAME_EXPR',  value => 'NOT LIKE (''%TMP'')', object_type => 'TABLE');
-- EXCLUDE=OBJECT_GRANT
  dbms_datapump.metadata_filter (l_dp_handle, 'EXCLUDE_PATH_EXPR', '=''OBJECT_GRANT''');
  dbms_datapump.metadata_filter (handle=> l_dp_handle, name => 'EXCLUDE_PATH_EXPR', value => '=''TABLE_STATISTICS''');
  dbms_datapump.metadata_filter (handle=> l_dp_handle, name => 'EXCLUDE_PATH_EXPR', value => '=''INDEX_STATISTICS''');

  dbms_datapump.start_job (l_dp_handle);
  dbms_datapump.wait_for_job (handle => l_dp_handle, job_state => l_status);
  dbms_datapump.detach (l_dp_handle);

  delete export_import_log where end_time < sysdate - 366; -- Keep 1 year history
  insert into export_import_log (start_time, end_time, operation, schema, file_name, status) values (l_start_time, sysdate, 'EXPORT', p_schema_name, l_dumpfile, l_status);
  commit;
  end_timing;

exception when others then
  log_error ('procedure export_schema', sqlerrm);
  dbms_datapump.stop_job (l_dp_handle);
  raise;
end export_schema;

/*********************************************************************************************************/ 

procedure remove_file (p_filename in varchar2, p_directory_name in varchar2 default 'MUREX_BEST')
is
begin
  start_timing('Remove file ' || p_filename);
  log_usage ('remove_file: ' || p_directory_name || ' : ' || p_filename);
  utl_file.fremove (p_directory_name, p_filename);
  end_timing;

exception when others
then log_error ('procedure remove_file: ' || p_filename, sqlerrm);
end remove_file;

/*********************************************************************************************************/ 

procedure remove_files (p_filename in varchar2, p_directory_name in varchar2 default 'MUREX_BEST')
is
begin
log_usage ('remove_files: ' || p_directory_name || ' : ' || p_filename);
for j in (select file_name from show_exports where file_name like p_filename)
loop
  log_usage ('remove_files. Removed: ' || p_directory_name || ' : ' || j.file_name);
  utl_file.fremove (p_directory_name, j.file_name);
end loop;

exception when others
then log_error ('procedure remove_files: ' || p_filename, sqlerrm);
end remove_files;

/*********************************************************************************************************/ 

procedure stop_datapump_job (p_schema_name in varchar2, p_jobname in varchar2)
as
  l_dummy      number;
begin
  start_timing ('Stop job ' || p_schema_name || '.' || p_jobname);
  log_usage ('stop_datapump_job: ' || p_schema_name || ' : ' || p_jobname);
  -- format: dbms_datapump.attach ('[job_name]','[owner_name]');
  l_dummy := dbms_datapump.attach (p_jobname, p_schema_name);
  dbms_datapump.stop_job (l_dummy, 1, 0);
  end_timing;

exception when others
then log_error ('procedure stop_datapump_job', sqlerrm);
end stop_datapump_job;

/*********************************************************************************************************/ 

-- Needs to be run from the target database. There must be a database link to the origin / source database
procedure copy_file_from_database (p_dumpfilename in varchar2, p_source_database in varchar2,
     p_from_dir in varchar2 default 'MUREX_BEST', p_to_dir in varchar2 default 'MUREX_BEST')
is
begin
  start_timing ('Copy file ' || p_dumpfilename);
  log_usage ('copy_file_from_database: ' || p_dumpfilename || ' : ' || p_from_dir || ' : ' || p_to_dir);
  dbms_file_transfer.get_file (
      source_directory_object      => p_from_dir,
      source_file_name             => p_dumpfilename,
      source_database              => p_source_database,
      destination_directory_object => p_to_dir,
      destination_file_name        => p_dumpfilename);
  end_timing;

exception when others
then log_error ('procedure copy_file_from_database', sqlerrm);
end copy_file_from_database;

/*********************************************************************************************************/ 

procedure copy_file (p_dumpfilename in varchar2, p_from_dir in varchar2 default 'MUREX_BEST', p_to_dir in varchar2 default 'MUREX_DUMPS')
is
l_filRef  bfile     := bfilename (p_from_dir, p_dumpfilename);
begin
log_usage ('copy_file: ' || p_dumpfilename || ' : ' || p_from_dir || ' : ' || p_to_dir);
if dbms_lob.fileexists(l_filRef) = 1
then
  start_timing ('Copy file' || p_dumpfilename);  
  utl_file.fcopy (p_from_dir, p_dumpfilename, p_to_dir, p_dumpfilename);
  end_timing;
else
  raise_application_error(-20001, 'File ' || p_dumpfilename || ' does not exist');
end if;

exception when others
then log_error ('procedure copy_file', sqlerrm);
end copy_file;

/*********************************************************************************************************/ 

function show_logfile (p_file_name in varchar2, p_directory in varchar2 default 'MUREX_BEST') return log_table pipelined
is
l_file    utl_file.file_type;
l_buffer  varchar2(32767);
l_filRef  bfile     := bfilename (p_directory, p_file_name);
l_line    number(6) := 0;
l_errm    varchar2(400);
begin
if dbms_lob.fileexists(l_filRef) = 1
then
  l_file := utl_file.fopen (p_directory, p_file_name,'R');
  if utl_file.is_open (l_file)
  then
  loop
    begin
      utl_file.get_line (l_file, l_buffer);
                l_line := l_line + 1;
                pipe row (log_format(l_line, l_buffer));
    exception when no_data_found then exit;
    end;
  end loop;
  utl_file.fclose(l_file);
  end if;
else
  pipe row (log_format (0, 'File ' || p_file_name || ' does not exist'));
end if;

exception when others
then
  l_errm := substr(sqlerrm, 1, 350);
  pipe row (log_format(0, l_errm));
end show_logfile;

/*********************************************************************************************************/ 

procedure calculate_stats (p_schema_name in varchar2, p_degree in number default 4)
is
begin
  start_timing ('Calculate stats for ' || p_schema_name);
  log_usage ('calculate_stats: ' || p_schema_name || ' : ' || p_degree);
  dbms_stats.gather_schema_stats (ownname => p_schema_name, degree => p_degree);
  end_timing;

exception when others
then log_error ('procedure calculate_stats', sqlerrm);
end calculate_stats;

/*********************************************************************************************************/ 

procedure rename_file (p_before in varchar2, p_after in varchar2, p_directory in varchar2 default 'MUREX_BEST')
is
l_filRef  bfile     := bfilename (p_directory, p_before);
begin
log_usage ('rename_file: ' || p_before || ' : ' || p_after || ' : ' || p_directory);
if dbms_lob.fileexists(l_filRef) = 1
then
  utl_file.frename (p_directory, p_before, p_directory, p_after);
else
  raise_application_error(-20001, 'File ' || p_before || ' does not exist');
end if; 

exception when others
then log_error ('rename_file', sqlerrm);
end rename_file;

end data_load_unload;
/

