https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=533525992020243&parent=EXTERNAL_SEARCH&sourceId=HOWTO&id=2299484.1&_afrWindowMode=0&_adf.ctrl-state=4ya7uryht_4


File Watcher needs the database JVM Installed and working:
select comp_name, status from dba_registry where comp_name like '%JAVA%';

-- Credentials
begin
  dbms_scheduler.create_credential (credential_name => 'WIN_CREDENTIAL', username => 'THEO', password => 'Celeste14');
end;
/

select credential_name, username, comments from user_scheduler_credentials;

begin
  dbms_scheduler.drop_credential(credential_name => 'WIN_CREDENTIAL', force => true);
end;
/

-- Update Credentials:
exec dbms_scheduler.set_attribute (name=>'WIN_CREDENTIAL', attribute=>'username', value=>'THEO');
exec dbms_scheduler.set_attribute (name=>'WIN_CREDENTIAL', attribute=>'password', value=>'Wacht');


-- File watcher
begin
dbms_scheduler.create_file_watcher (file_watcher_name => 'Garmin',
    directory_path  => 'C:\Work\garmin',
    file_name       => '*.fit',
    credential_name => 'WIN_CREDENTIAL',
    destination     => null,       -- NULL destination = local host
    enabled         => false);
end;
/

select enabled, directory_path, file_name, credential_name, comments from user_scheduler_file_watchers;

begin
 dbms_scheduler.drop_job(job_name => 'Garmin', defer => false, force => false);
end;
/

-- Create program
begin
  dbms_scheduler.create_program (program_name   => 'LOAD_GARMIN', program_type   => 'stored_procedure', program_action => 'LOAD_GARMIN_PROC', number_of_arguments => 1, enabled => false);
end;
/

select program_type, program_name, program_action, number_of_arguments, enabled from user_scheduler_programs where program_name = 'LOAD_GARMIN'
/

--  Table
create table gmn_incoming_files (destination varchar2(4000), directory_path varchar2(4000), actual_file_name varchar2(4000),
    file_size number, file_timestamp timestamp with time zone)
/   

create or replace procedure Load_garmin_proc (i_result sys.scheduler_filewatcher_result)
as
begin
    insert into gmn_incoming_files( 
        destination, 
        directory_path, 
        actual_file_name, 
        file_size, 
        file_timestamp)
    values(
        i_result.destination,
        i_result.directory_path,
        i_result.actual_file_name,
        i_result.file_size,
        i_result.file_timestamp);
commit;
end;
/

begin
dbms_scheduler.create_job (job_name => 'GARMIN_JOB', program_name => 'LOAD_GARMIN', event_condition => null,
    queue_spec => 'Garmin',  -- name of the file watcher
    auto_drop => false, enabled => false);
end;
/

select program_name, job_name, schedule_type, file_watcher_name, enabled from user_scheduler_jobs;
select program_type, program_name, program_action, number_of_arguments, enabled from user_scheduler_programs;

begin
dbms_scheduler.define_metadata_argument(
    program_name       => 'Load_Garmin',
    metadata_attribute => 'event_message',
    argument_position  => 1);
end;
/

begin
  dbms_scheduler.set_attribute ('GARMIN_JOB','parallel_instances',true);
end;
/

-- Run as SYS
begin
  dbms_scheduler.set_attribute ('FILE_WATCHER_SCHEDULE','repeat_interval','freq=minutely; interval=5');
end;
/

select repeat_interval
from dba_scheduler_schedules
where schedule_name = 'FILE_WATCHER_SCHEDULE';

-- Enable thejobs:
exec dbms_scheduler.enable('Garmin');
exec dbms_scheduler.enable('Load_Garmin');
exec dbms_scheduler.enable('Garmin_job');

select 'Watcher' origin, file_watcher_name as scheduler_object, enabled from user_scheduler_file_watchers
union all
select 'Program', program_name, enabled from user_scheduler_programs
union all
select 'Job', job_name, enabled from user_scheduler_jobs
/

-- Debugging and error handling:
select owner, job_name, status, error#, credential_owner, credential_name, destination_owner, destination, additional_info
  from dba_scheduler_job_run_details
  where job_name = 'GARMIN_JOB'
 order by actual_start_date desc;
 
 select owner, name, queue_table, qid, enqueue_enabled, dequeue_enabled from dba_queues; 
 
-- Cleanup:
exec dbms_scheduler.drop_job         ('GARMIN_JOB');
exec dbms_scheduler.drop_program     ('LOAD_GARMIN');
exec dbms_scheduler.drop_file_watcher('Garmin');
exec dbms_scheduler.drop_credential  ('WIN_CREDENTIAL');
exec dbms_scheduler.purge_log(job_name => 'GARMIN_JOB' );
drop procedure Load_garmin_proc;
drop table gmn_incoming_files;