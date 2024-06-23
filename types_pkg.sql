Doc

  Author   :  Theo Stienissen
  Date     :  2021 / 2022 / 2023
  Purpose  :  Types declarations
  Contact  :  theo.stienissen@gmail.com
  Script   :  @C:\Users\Theo\OneDrive\Theo\Project\Generic\types_pkg.sql

#

set serveroutput on size unlimited

alter session set plsql_warnings = 'ENABLE:ALL'; 

create or replace package types_pkg
as
-- Fractions package
subtype numerator_ty     is integer (38);
subtype denominator_ty   is integer (38) not null;
type    fraction_ty      is record (numerator numerator_ty, denominator denominator_ty default 1);
type    fraction_row_ty  is table of fraction_ty index by pls_integer;
subtype integer_ty       is integer (36);

subtype point_ty         is types_pkg.fraction_ty;
type vector_ty           is table of point_ty  index by pls_integer;
type matrix_ty           is table of vector_ty index by pls_integer;
type point_ty_2D         is record (x_c point_ty, y_c point_ty);
type point_ty_3D         is record (x_c point_ty, y_c point_ty, z_c point_ty);

-- Matrix_Q_pkg
type vector_Q_ty         is table of types_pkg.fraction_ty index by pls_integer;
type matrix_Q_ty         is table of vector_Q_ty index by pls_integer;
type matrix_Q_tab        is table of vector_Q_ty index by pls_integer;
type point_Q_ty_2D       is record (x_c types_pkg.fraction_ty, y_c types_pkg.fraction_ty);
type point_Q_ty_3D       is record (x_c types_pkg.fraction_ty, y_c types_pkg.fraction_ty, z_c types_pkg.fraction_ty);

-- Complex package
type complexN_ty         is record (re integer (36), im integer (36));
type complexQ_ty         is record (re fraction_ty , im fraction_ty);
type complex_ty          is record (re number      , im number);

type polar_ty            is record (radius number, angle number);

type HamiltonianN_ty     is record (r integer (36), i integer (36), j integer (36), k integer (36));
type HamiltonianQ_ty     is record (r fraction_ty, i fraction_ty, j fraction_ty, k fraction_ty);
type Hamiltonian_ty      is record (r number     , i number     , j number     , k number);

-- Fast_int package
type fast_int_ty         is table of integer (38) index by binary_integer;
type fast_int_array_ty   is table of fast_int_ty index by binary_integer;

type rowid_array_ty      is table of rowid index by binary_integer;
g_rowid_aray             rowid_array_ty;

type int_array_ty        is table of integer index by binary_integer;
type pls_int_array_ty    is table of pls_integer index by pls_integer;
type string_array        is table of varchar2 (50) index by pls_integer;

g_int_array              int_array_ty;
g_int_array              int_array_ty;
g_fraction1              types_pkg.fraction_ty;
g_fraction2              types_pkg.fraction_ty;

end types_pkg;
/

show error

alter package types_pkg compile;
select status from user_objects where object_name =  'TYPES_PKG';