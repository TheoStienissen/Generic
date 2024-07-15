
-- Columns formatted output
with datag as (select json_dataguide (json_clob) dg from gmn_json_data where name like 'MetricsAcuteTrainingLoad_20230511_20230819_113255650.json')
select j.jpath, j.jtype, j.jlength
from datag d, json_table (d.dg,  '$[*]'
COLUMNS (
jpath varchar path '$."o:path"',
jtype varchar path '$."type"',
jlength varchar path '$."o:length"')) j

with datag as (select json_dataguide (json_clob) dg from gmn_json_data where name like 'customer.json')
select rpad(substr (j.jpath, instr (j.jpath, '$') + 2), 40) || ' ' ||
rpad(case j.jtype when 'string' then 'varchar2' when 'boolean' then 'number' when 'null' then 'varchar2' else j.jtype end ||  ' (' || j.jlength || ')', 20) ||
' path ''' || j.jpath || ''',' col_mapping
from datag d, json_table (d.dg,  '$[*]'
COLUMNS (
jpath varchar path '$."o:path"',
jtype varchar path '$."type"',
jlength varchar path '$."o:length"')) j
where substr (j.jpath, instr (j.jpath, '$') + 2) is not null and jtype not like '%array%'  and jtype not like '%object%';


-- Resulting working query
select jc.* from gmn_json_data t, 
json_table (t.json_clob,  '$[*]'
COLUMNS (
id                                       varchar2 (4)         path '$.id',
type                                     varchar2 (4)         path '$.type',
active                                   number (4)           path '$.active',
gender                                   varchar2 (4)         path '$.gender',
locale                                   varchar2 (8)         path '$.locale',
version                                  number (2)           path '$.version',
fullName                                 varchar2 (16)        path '$.fullName',
lastName                                 varchar2 (16)        path '$.lastName',
username                                 varchar2 (32)        path '$.username',
firstName                                varchar2 (4)         path '$.firstName',
loginInfo                                varchar2 (4)         path '$.loginInfo',
middleName                               varchar2 (4)         path '$.middleName',
namePrefix                               varchar2 (4)         path '$.namePrefix',
nameSuffix                               varchar2 (4)         path '$.nameSuffix',
toBePurged                               number (8)           path '$.toBePurged',
companyName                              varchar2 (4)         path '$.companyName',
createdDate                              varchar2 (32)        path '$.createdDate',
displayName                              varchar2 (4)         path '$.displayName',
legacyAccount                            number (8)           path '$.legacyAccount',
primaryAddress                           varchar2 (4)         path '$.primaryAddress',
accountVerified                          number (8)           path '$.accountVerified',
customerLocation_verified                number (4)           path '$.customerLocation.verified',
customerLocation_countryCode             varchar2 (2)         path '$.customerLocation.countryCode',
customerLocation_verifiedTimestamp       varchar2 (32)        path '$.customerLocation.verifiedTimestamp',
lastUpdateDateTime                       varchar2 (32)        path '$.lastUpdateDateTime',
nextPurgeCheckDate                       varchar2 (4)         path '$.nextPurgeCheckDate',
primaryPhoneNumber                       varchar2 (4)         path '$.primaryPhoneNumber',
primaryEmailAddress_type                 varchar2 (4)         path '$.primaryEmailAddress.type',
primaryEmailAddress_primary              number (4)           path '$.primaryEmailAddress.primary',
primaryEmailAddress_emailAddress         varchar2 (32)        path '$.primaryEmailAddress.emailAddress',
primaryEmailAddress_emailVerified        number (8)           path '$.primaryEmailAddress.emailVerified',
primaryEmailAddress_emailAddressId       varchar2 (4)         path '$.primaryEmailAddress.emailAddressId',
primaryEmailAddress_emailVerificationTim varchar2 (4)         path '$.primaryEmailAddress.emailVerificationTimestamp',
accountVerificationDate                  varchar2 (4)         path '$.accountVerificationDate')) as jc
where name like 'customer.json';


-- Resulting view
create or replace view v_gmn_json_customer
as
select t.person_id, jc.* from gmn_json_data t, 
json_table (t.json_clob,  '$[*]'
COLUMNS (
id                                       varchar2 (4)         path '$.id',
type                                     varchar2 (4)         path '$.type',
active                                   number (4)           path '$.active',
gender                                   varchar2 (4)         path '$.gender',
locale                                   varchar2 (8)         path '$.locale',
version                                  number (2)           path '$.version',
fullName                                 varchar2 (16)        path '$.fullName',
lastName                                 varchar2 (16)        path '$.lastName',
username                                 varchar2 (32)        path '$.username',
firstName                                varchar2 (4)         path '$.firstName',
loginInfo                                varchar2 (4)         path '$.loginInfo',
middleName                               varchar2 (4)         path '$.middleName',
namePrefix                               varchar2 (4)         path '$.namePrefix',
nameSuffix                               varchar2 (4)         path '$.nameSuffix',
toBePurged                               number (8)           path '$.toBePurged',
companyName                              varchar2 (4)         path '$.companyName',
createdDate                              varchar2 (32)        path '$.createdDate',
displayName                              varchar2 (4)         path '$.displayName',
legacyAccount                            number (8)           path '$.legacyAccount',
primaryAddress                           varchar2 (4)         path '$.primaryAddress',
accountVerified                          number (8)           path '$.accountVerified',
customerLocation_verified                number (4)           path '$.customerLocation.verified',
customerLocation_countryCode             varchar2 (2)         path '$.customerLocation.countryCode',
customerLocation_verifiedTimestamp       varchar2 (32)        path '$.customerLocation.verifiedTimestamp',
lastUpdateDateTime                       varchar2 (32)        path '$.lastUpdateDateTime',
nextPurgeCheckDate                       varchar2 (4)         path '$.nextPurgeCheckDate',
primaryPhoneNumber                       varchar2 (4)         path '$.primaryPhoneNumber',
primaryEmailAddress_type                 varchar2 (4)         path '$.primaryEmailAddress.type',
primaryEmailAddress_primary              number (4)           path '$.primaryEmailAddress.primary',
primaryEmailAddress_emailAddress         varchar2 (32)        path '$.primaryEmailAddress.emailAddress',
primaryEmailAddress_emailVerified        number (8)           path '$.primaryEmailAddress.emailVerified',
primaryEmailAddress_emailAddressId       varchar2 (4)         path '$.primaryEmailAddress.emailAddressId',
primaryEmailAddress_emailVerificationTim varchar2 (4)         path '$.primaryEmailAddress.emailVerificationTimestamp',
accountVerificationDate                  varchar2 (4)         path '$.accountVerificationDate')) as jc
where name like 'customer.json';

-- Update records + run block
update gmn_json_data set view_name =  'v_gmn_json_customer'  where name like 'customer.json' and view_name is null;
commit;


-- Add code to the repository