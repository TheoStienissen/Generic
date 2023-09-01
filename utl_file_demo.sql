-- Simple PLSQL to open a file,
-- write two lines into the file,
-- and close the file
declare
  fhandle  utl_file.file_type;
begin
  fhandle := utl_file.fopen(
                'UTL_DIR'     -- File location
              , 'test_file.txt' -- File name
              , 'w' -- Open mode: w = write. 
                  );

  utl_file.put(fhandle, 'Hello world!' || CHR(10));
  utl_file.put(fhandle, 'Hello again!');

  utl_file.fclose(fhandle);
exception
  when others then
    dbms_output.put_line('ERROR: ' || SQLCODE 
                      || ' - ' || SQLERRM);
    raise;
end;
/
-- UTL_FILE.FOPEN('/user/dm', 'hello.txt', 'w');

Different modes used in fopen() are,
• w:-  write mode
• r:-  read mode
• a:-  append mode
• rb:- read byte mode
• wb:- write byte mode
• ab:- append byte mode

declare
    fp utl_file.file_type;
    -- declare a buffer variable
    z varchar2(200);
begin
    -- open file in read mode
    fp := utl_file.fopen('abc', 'file1.txt', 'r');
    -- fetch data from file
    utl_file.get_line(fp, z);
    -- display output
    dbms_output.put_line(z);
    -- close the file
    utl_file.fclose(fp);
end;
/

declare
    fp utl_file.file_type;
    -- declare a buffer variable
    z varchar2(200);
begin
    -- open file in read mode
    fp := utl_file.fopen('abc', 'file4.txt', 'r');
    -- fetch data from file
    loop
        utl_file.get_line(fp, z);
        -- display each line
        dbms_output.put_line(z);
    end loop;
    -- exception section
exception
    when no_data_found then
    -- close the file
    utl_file.fclose(fp);
end;
/

exception
when utl_file.invalid_mode then raise_application_error (-20051, 'Invalid Mode Parameter');
when utl_file.invalid_path then raise_application_error (-20052, 'Invalid File Location');
when utl_file.invalid_filehandle then raise_application_error (-20053, 'Invalid Filehandle');
when utl_file.invalid_operation then raise_application_error (-20054, 'Invalid Operation');
when utl_file.write_error then raise_application_error (-20055, 'Write Error');
when utl_file.internal_error then raise_application_error (-20057, 'Internal Error');
when utl_file.charsetmismatch then raise_application_error (-20058, 'Opened With FOPEN_NCHAR But Later I/O Inconsistent');
when utl_file.file_open then raise_application_error (-20059, 'File Already Opened');
when utl_file.invalid_maxlinesize then raise_application_error (-20060, 'Line Size Exceeds 32K');
when utl_file.invalid_filename then raise_application_error (-20061, 'Invalid File Name');
when utl_file.access_denied then raise_application_error (-20062, 'File Access Denied By');
when utl_file.invalid_offset then raise_application_error (-20063, 'FSEEK Param Less Than 0');
when others then raise_application_error (-20099, 'Unknown UTL_FILE Error'||sqlerrm);


set serveroutput on size 1000000
declare
  l_file         utl_file.file_type;
  l_location     varchar2(100) := 'my_docs';
  l_filename     varchar2(100) := 'temp';
  l_exists       boolean;
  l_file_length  number;
  l_blocksize    number;
  l_text         varchar2(32767);
begin
  utl_file.fgetattr(l_location, l_filename, l_exists, l_file_length, l_blocksize);

  if l_exists then
    -- Open file.
    l_file := utl_file.fopen(l_location, l_filename, 'r', 32767);
    
    -- Read and output first line.
    UTL_FILE.get_line(l_file, l_text, 32767);
    DBMS_OUTPUT.put_line('First Line: |' || l_text || '|');
    UTL_FILE.FSEEK (l_file, l_file_length-1);
  
    -- step backwards through the file until we reach the start of the last line.
    for i in reverse 0 .. l_file_length-2 loop
      utl_file.fseek (l_file, null, -2);
      utl_file.get_line(l_file, l_text, 1);
      exit when l_text is null;
    end loop;
    
    -- read and output the last line.
    utl_file.get_line(l_file, l_text, 32767);
    dbms_output.put_line('last line : |' || l_text || '|');
  
    -- close the file.
    utl_file.fclose(l_file);
  end if;
end;
/

-- Copy
BEGIN
UTL_FILE.FCOPY ('MY_DOC',
'emp.pdf',
'MY_DOC',
'emp2.pdf');
END;
/

-- Move
BEGIN
UTL_FILE.FRENAME ('SOURCE_FILE_DIR',
'1_text_file.csv',
'TARGET_FILE_DIR',
'new_1_text_file.csv',
TRUE);
END;

function f_open_tag (p_tag in varchar2) return varchar2 
is 
begin 
  return '<' || p_tag || '>';
end f_open_tag;

function f_close_tag (p_tag in varchar2) return varchar2 
is 
begin 
  return '</' || p_tag || '>';
end f_close_tag;


declare 
l_file         utl_file.file_type;
l_file_length  integer(5)    := 32767;
l_file_name    varchar2(200) := 'test.xml';
l_directory    varchar2(10)  :=  'MY_DIR';
l_exists       boolean;
l_blocksize    integer;
l_text         varchar2(32767);
--
function f_to_xml (p_text in varchar2, p_tag in varchar2) return varchar2 
is 
begin 
  return '<' || p_tag || '>' || p_text || '</' || p_tag || '>';
end f_to_xml;
--
begin 
utl_file.fgetattr(l_directory, l_filename, l_exists, l_file_length, l_blocksize);
if l_exists
then raise_application_error (-20001, 'Filename ' || l_file_name || ' already exists. Please use a different name.');
else 
  l_file := utl_file.fopen(l_directory, l_filename, 'w', l_file_length);
  for j in (select source_target from vocabulary order by id)
  loop 
    dbms_output.put_line (f_to_xml (j.source, 'source'));
    dbms_output.put_line (f_to_xml (j.target, 'target'));
  end loop; 
  utl_file.fclose(l_file);
end if;
end;
/
