-- https://oracle-base.com/articles/misc/utl_http-and-ssl
 orapki wallet create -wallet C:\app\oracle\admin\wallet -pwd Celeste14 -auto_login
 orapki wallet add -wallet C:\app\oracle\admin\wallet -trusted_cert -cert "C:\Work\DigiCert Global Root CA.crt" -pwd Celeste14
 
 
 
 SET SERVEROUTPUT ON
EXEC UTL_HTTP.set_wallet('file:C:\app\oracle\admin\wallet', 'Celeste14');
EXEC show_html_from_url('https://gb.redhat.com/');

exec dbms_network_acl_admin.drop_acl('http_https.xml')

begin
dbms_network_acl_admin.create_acl   ( acl => 'http_https.xml', description => 'Read webpages.', principal   => 'THEO', is_grant    => true,
                                      privilege   => 'connect', start_date  => null, end_date    => null);
dbms_network_acl_admin.add_privilege ( acl => 'http_https.xml', principal => 'THEO', is_grant => true, privilege => 'resolve');
dbms_network_acl_admin.assign_acl ( acl => 'http_https.xml', host => '*');
end;
/

drop type country_tab;
drop type country_row;

create or replace type country_row as object
 (id            integer,
  country       varchar2(50),
  official_name varchar2(100),
  alpha_2       varchar2(2),
  alpha_3       varchar2(3),
  numeric_code  integer,
  internet      varchar2(5));
/
  
create or replace type country_tab as table of country_row;
/

create or replace function f_country_info return country_tab pipelined
is
  l_clob     clob;
  l_start    integer;
  l_length   integer;
  l_sc_pos   integer;
  l_country  varchar(50) := '1';
  l_official_name varchar(200);
  l_alpha_2  varchar(2);
  l_alpha_3  varchar(3);
  l_numeric  integer;
  l_internet varchar(5);
  l_id       integer := 0;
  l_end_of_row integer;
begin
  utl_http.set_wallet ('file:C:\app\oracle\admin\wallet');
  l_clob:= httpuritype ('https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes').getClob();
 
  -- start processing with Afghanistan
  l_length := dbms_lob.getlength (l_clob);
  l_sc_pos := dbms_lob.instr( l_clob, 'Afghanistan');
 
  -- find country 
  while  l_country != 'Zimbabwe'
  loop
    l_sc_pos := dbms_lob.instr(l_clob, 'title=', l_sc_pos, 1);
    exit when l_sc_pos = 0;
	l_end_of_row := dbms_lob.instr (l_clob, '</tr>', l_sc_pos, 1);
	l_start  := dbms_lob.instr (l_clob, '"', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_sc_pos, 2);
	l_country := dbms_lob.substr (l_clob, l_sc_pos - l_start - 1, l_start + 1);
--
    if dbms_lob.instr (l_clob, '/wiki/ISO_3166-1_alpha-2#', l_sc_pos, 1) < l_end_of_row
	then
    l_sc_pos := dbms_lob.instr(l_clob, 'title=', l_sc_pos, 1);
	l_start  := dbms_lob.instr (l_clob, '"', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_sc_pos, 2);
--
    l_sc_pos := dbms_lob.instr(l_clob, 'title=', l_sc_pos, 1);
	l_start  := dbms_lob.instr (l_clob, '"', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_sc_pos, 2);
--	
	l_start  := dbms_lob.instr (l_clob, '>', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '<', l_start, 1);
	l_official_name := nvl (dbms_lob.substr (l_clob, l_sc_pos  - l_start - 1, l_start + 1), l_country);	
--
	l_start  := dbms_lob.instr (l_clob, '/wiki/ISO_3166-1_alpha-2#', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_start, 1);
	l_alpha_2 := dbms_lob.substr (l_clob, l_sc_pos  - l_start - 25, l_start + 25);	
--
	l_start  := dbms_lob.instr (l_clob, '/wiki/ISO_3166-1_alpha-3#', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_start, 1);
	l_alpha_3 := dbms_lob.substr (l_clob, l_sc_pos  - l_start - 25, l_start + 25);	
--
	l_start  := dbms_lob.instr (l_clob, '/wiki/ISO_3166-1_numeric#', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_start, 1);
	l_numeric := dbms_lob.substr (l_clob, l_sc_pos  - l_start - 25, l_start + 25);	
--
	l_start  := dbms_lob.instr (l_clob, 'title=".', l_sc_pos, 1);
    l_sc_pos := dbms_lob.instr (l_clob, '"', l_start, 1);
	l_internet := dbms_lob.substr (l_clob, l_sc_pos  - l_start - 3, l_start + 12);	
--
    l_id := l_id + 1;
    pipe row (country_row (l_id, l_country, l_official_name, l_alpha_2, l_alpha_3, l_numeric, l_internet));
	end if;
    l_sc_pos := l_end_of_row;
  end loop;
end;
/

select * from table(f_country_info);



create or replace procedure show_html_from_url (p_url  in  varchar2, p_username in varchar2 default null,  p_password in varchar2 default null
) as
  l_http_request   utl_http.req;
  l_http_response  utl_http.resp;
  l_debug          varchar2(100) := 'Start';
  l_buffer         varchar2(32767);
  l_content        clob;
  l_name           varchar2(256);
  l_value          varchar2(1024);
  l_request_context utl_http.request_context_key;
  l_length         integer := 0;
-- Common exception handling procedure
  procedure print_error (p_text in varchar2)
  is
  begin
    dbms_output.put_line  ('Debug:  ' || p_text);
    dbms_output.put_line  (utl_http.get_detailed_sqlcode);
    dbms_output.put_line  (utl_http.get_detailed_sqlerrm);
    utl_http.end_response (l_http_response);
	raise_application_error (-20001, 'Debug:  ' || l_debug);
  end print_error;
begin
  -- initialisation part
  dbms_lob.createtemporary(l_content, false);   
  utl_http.set_response_error_check (true);
  
  -- Set wallet if needed and begin request
  if p_url like 'https%'
  then
    utl_http.set_wallet ('file:C:\app\oracle\wallet');
	l_debug := 'After https set_wallet';
  
  -- Create the context
    l_request_context := utl_http.create_request_context (
                       wallet_path          => 'file:C:\app\oracle\admin\wallet',
                       wallet_password      => 'Celeste14', enable_cookies => true, max_cookies => 300,  max_cookies_per_site => 20);
    l_debug := 'After https create_request_context';
  
   -- make a http request and get the response.
    l_http_request  := utl_http.begin_request (p_url, method => 'POST' , http_version => utl_http.http_version_1_1, request_context => l_request_context);
    l_debug := 'After https begin_request';
  else
    l_http_request  := utl_http.begin_request (p_url, method => 'POST' , http_version => utl_http.http_version_1_1);
    l_debug := 'After http begin_request';	   
  end if;  
 
  -- Header settings. Mozilla/4.0 
  utl_http.set_header (l_http_request, 'User-Agent', 'Mozilla/4.0');
  utl_http.set_body_charset (l_http_request, 'UTF8');
  utl_http.set_header (l_http_request, 'Content-Length', l_length);
  
  --  utl_http.set_header (l_http_request, 'Content-Type',  'text/json;charset=utf-8');
  utl_http.set_header (l_http_request, 'Content-Type',  'text;charset=utf-8');
  l_debug := 'After set_header';
  
  -- use basic authentication if required.
  if p_username is not null and p_password is not null
  then
    utl_http.set_authentication (l_http_request, p_username, p_password);
	l_debug := 'After set_authentication';
  end if;

  l_http_response := utl_http.get_response (l_http_request);
  dbms_output.put_line('http response status code:   ' || l_http_response.status_code);
  if l_http_response.status_code = utl_http.http_unauthorized
  then
    dbms_output.put_line('Website requires authentication');
  end if;
  dbms_output.put_line('http response reason phrase: ' || l_http_response.reason_phrase);
  l_debug := 'After get_response';
  
  dbms_output.put_line('Headers:');
  for i in 1 .. utl_http.get_header_count(l_http_response)
  loop
    utl_http.get_header(l_http_response, i, l_name, l_value);
    dbms_output.put_line(l_name || ': ' || l_value);
	if l_name = 'Content-Length' then l_length := l_value; end if;
  end loop;
  
  dbms_output.put_line('Loop through the response');
  begin
    loop
      utl_http.read_text (l_http_response, l_buffer, 32766);
	  l_debug := 'After read_text';
	  dbms_lob.writeappend (l_content, length (l_buffer), l_buffer);
    end loop;
  exception
    when utl_http.end_of_body then
      utl_http.end_response (l_http_response);
  end;
  dbms_output.put_line('Response: ' || cast(l_content as varchar2));
  
  -- Cleanup. destroy the request context
  utl_http.destroy_request_context(l_request_context);
  dbms_lob.freetemporary (l_content);
  
exception
 when utl_http.bad_url           then print_error (l_debug || ', 1 bad_url');
 when utl_http.bad_argument      then print_error (l_debug || ', 2 bad_argument');
 when utl_http.http_client_error then print_error (l_debug || ', 3 http_client_error');
 when utl_http.http_server_error then print_error (l_debug || ', 4 http_server_error');
 when utl_http.illegal_call      then print_error (l_debug || ', 5 illegal_call');
 when utl_http.init_failed       then print_error (l_debug || ', 6 init_failed');
 when utl_http.protocol_error    then print_error (l_debug || ', 7 protocol_error');
 when utl_http.request_failed    then print_error (l_debug || ', 8 request_failed');
 when others then print_error (l_debug || ', 9 other error');
end show_html_from_url;
/

exec show_html_from_url('http://dollyentheo:8080/index.html')
exec show_html_from_url('https://nu.nl')
exec show_html_from_url('https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes')
exec show_html_from_url('https://en.wikipedia.org')
exec show_html_from_url('http://dba-oracle.com')
exec show_html_from_url('http://www.w3.org')
exec show_html_from_url('https://www.iban.com/country-codes')

https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes

create or replace view countries_vw as select code, name from table(countries.get_countries);

orapki wallet create -wallet C:\app\oracle\wallet -pwd Celeste14 -auto_login
orapki wallet add -wallet C:\app\oracle\wallet -trusted_cert -cert "C:\Work\iso-codes.cer" -pwd Celeste14
orapki wallet add -wallet C:\app\oracle\wallet -trusted_cert -cert "C:\Work\wike.cer" -pwd Celeste14
orapki wallet add -wallet C:\app\oracle\wallet -trusted_cert -cert "C:\Work\nu.cer" -pwd Celeste14
orapki wallet add -wallet C:\app\oracle\wallet -trusted_cert -cert "C:\Work\iban.cer" -pwd Celeste14
orapki wallet add -wallet C:\app\oracle\wallet -trusted_cert -cert "C:\Work\digicert.cer" -pwd Celeste14


To remove all wallet entries:
orapki wallet remove -wallet C:\app\oracle\wallet -trusted_cert_all -pwd Celeste14

To create a signed certificate for testing purposes, use the following command:
orapki cert create [-wallet wallet_location] -request certificate_request_location -cert certificate_location -validity number_of_days [-summary]

To view an Oracle wallet, use the orapki wallet display command.
orapki wallet display -wallet C:\app\oracle\wallet

exec utl_http.set_wallet('file:C:\app\oracle\wallet', 'Celeste14')


set serverout on
declare
l_url            varchar2(100) := 'https://nl.wikipedia.org/wiki/Lijst_van_Nederlandse_plaatsen';
l_req   utl_http.req;
l_resp  utl_http.resp;
l_text           varchar2(32767);
begin
  utl_http.set_wallet ('file:C:\app\oracle\admin\wallet', 'Celeste14');
  l_req  := utl_http.begin_request(l_url);
  l_resp := utl_http.get_response(l_req);
  -- loop through the data coming back
  begin
    loop
      utl_http.read_text(l_resp, l_text, 32766);
      dbms_output.put_line(l_text);
    end loop;
  exception
    when utl_http.end_of_body then
      utl_http.end_response(l_resp);
 end;
 end;
 /