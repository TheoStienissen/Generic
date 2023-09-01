/*

Error handling:
Goto Application properties
errorhandling_pkg.error_handling

*/
create table constraint_lookup
( id        number(6) generated always as identity
, constraint_name varchar2(30)
, message     varchar2(100));

alter table  constraint_lookup add constraint constraint_lookup_pk primary key(constraint_name) using index;

create or replace function apex_error_handling (p_error in apex_error.t_error ) return apex_error.t_error_result
is
  l_result          apex_error.t_error_result;
  l_reference_id    number;
  l_constraint_name varchar2(255);
begin
    l_result := apex_error.init_error_result (p_error => p_error );
 
    -- If it's an internal error raised by APEX, like an invalid statement or
    -- code which cannot be executed, the error text might contain security sensitive
    -- information. To avoid this security problem rewrite the error to
    -- a generic error message and log the original error message for further
    -- investigation by the help desk.
    if p_error.is_internal_error then
        -- Access Denied errors raised by application or page authorization should
        -- still show up with the original error message
        if    p_error.apex_error_code <> 'APEX.AUTHORIZATION.ACCESS_DENIED' and p_error.apex_error_code not like 'APEX.SESSION_STATE.%' then
            -- log error for example with an autonomous transaction and return
            -- l_reference_id as reference#
            -- l_reference_id := log_error (
            --                       p_error => p_error );
            --
            
            -- Change the message to the generic error message which is not exposed
            -- any sensitive information.
            l_result.message         := 'An unexpected internal application error has occurred. '||
                                        'Please get in contact with support team and provide '||
                                        'reference# '||to_char(l_reference_id, '999G999G999G990')||
                                        ' for further investigation.';
            l_result.additional_info := null;
        end if;
    else
        -- Always show the error as inline error
        -- Note: If you have created manual tabular forms (using the package
        --       apex_item/htmldb_item in the SQL statement) you should still
        --       use "On error page" on that pages to avoid loosing entered data
        l_result.display_location := case
                                       when l_result.display_location = apex_error.c_on_error_page then apex_error.c_inline_in_notification
                                       else l_result.display_location
                                     end;
 
        -- If it's a constraint violation like
        --
        --   -) ORA-00001: unique constraint violated
        --   -) ORA-02091: transaction rolled back (-> can hide a deferred constraint)
        --   -) ORA-02290: check constraint violated
        --   -) ORA-02291: integrity constraint violated - parent key not found
        --   -) ORA-02292: integrity constraint violated - child record found
        --
        -- try to get a friendly error message from our constraint lookup configuration.
        -- If the constraint in our lookup table is not found, fallback to
        -- the original ORA error message.
        if p_error.ora_sqlcode in (-1, -2091, -2290, -2291, -2292) then
           l_constraint_name := apex_error.extract_constraint_name (
                                     p_error => p_error );
        
            begin
                select message
                  into l_result.message
                  from constraint_lookup
                 where constraint_name = l_constraint_name;
            exception when no_data_found then null; -- not every constraint has to be in our lookup table
            end;
        end if;
        
        -- If an ORA error has been raised, for example a raise_application_error(-20xxx, '...')
        -- in a table trigger or in a PL/SQL package called by a process and the 
        -- error has not been found in the lookup table, then display
        -- the actual error text and not the full error stack with all the ORA error numbers.
        if p_error.ora_sqlcode is not null and l_result.message = p_error.message then
            l_result.message := apex_error.get_first_ora_error_text (
                                    p_error => p_error );
        end if;
 
        -- If no associated page item/tabular form column has been set, use
        -- apex_error.auto_set_associated_item to automatically guess the affected
        -- error field by examine the ORA error for constraint names or column names.
        if l_result.page_item_name is null and l_result.column_alias is null then
            apex_error.auto_set_associated_item (
                p_error        => p_error,
                p_error_result => l_result );
        end if;
    end if;
 
    return l_result;
end apex_error_handling;
/

create or replace function unique_person_check( p_error in apex_error.t_error ) return apex_error.t_error_result
is
    l_result          apex_error.t_error_result;
    l_reference_id    number;
    l_constraint_name varchar2(255);
begin
    l_result := apex_error.init_error_result (
                    p_error => p_error );
 
    IF p_error.ora_sqlcode = -1 THEN --unique constraint
    
        if apex_error.extract_constraint_name(p_error) = 'UNIQUE_PEOPLE_UK1' THEN
        
            l_result.message := 'Person already exists. Please choose another';

        END IF;
    
    END IF;
    
    --fallback incase our testcase doesn't match anything
    
    if p_error.ora_sqlcode is not null and l_result.message = p_error.message then --no new message yet assigned. Must mean we haven't met the conditions above
    l_result.message := apex_error.get_first_ora_error_text(
            p_error => p_error);
    
    end if;
 
    return l_result;
end unique_person_check;?
/
