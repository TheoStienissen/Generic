Doc

  Author   :  Theo Stienissen
  Date     :  2021 / 2022 / 2023
  Purpose  :  Types declarations
  Contact  :  theo.stienissen@gmail.com
  Script   :  @C:\Users\Theo\OneDrive\Theo\Project\Generic\constants_pkg.sql

#

set serveroutput on size unlimited

alter session set plsql_warnings = 'ENABLE:ALL'; 

create or replace package constants_pkg
as
-- Complex numbers. Dihedron matrices.
D1 constant types_pkg.matrix_Q_ty := matrix_Q_pkg.to_matrix_2D (1, 0, 0, 1);
DI constant types_pkg.matrix_Q_ty := matrix_Q_pkg.to_matrix_2D (0, 1,-1, 0);
DJ constant types_pkg.matrix_Q_ty := matrix_Q_pkg.to_matrix_2D (0, 1, 1, 0);
DK constant types_pkg.matrix_Q_ty := matrix_Q_pkg.to_matrix_2D (1, 0, 0,-1);

-- Quaternion matrices
Q1 constant types_pkg.matrix_Q_ty := matrix_Q_pkg.load_matrix ('Quaternion 1');
QI constant types_pkg.matrix_Q_ty := matrix_Q_pkg.load_matrix ('Quaternion I');
QJ constant types_pkg.matrix_Q_ty := matrix_Q_pkg.load_matrix ('Quaternion J');
QK constant types_pkg.matrix_Q_ty := matrix_Q_pkg.load_matrix ('Quaternion K');

empty_fraction types_pkg.fraction_ty;
empty_vector   types_pkg.vector_Q_ty;
empty_matrix   types_pkg.matrix_Q_ty;
empty_point_2D types_pkg.point_Q_ty_2D;
empty_point_3D types_pkg.point_Q_ty_3D;
empty_array    utl_nla_array_int;

-- Fractions 
zero constant    types_pkg.fraction_ty := fractions_pkg.to_fraction (0);
one  constant    types_pkg.fraction_ty := fractions_pkg.to_fraction (1);

-- Eulers constant
g_e  constant number := 2.7182818284590452353602874713526624977;

-- Pi constant
g_pi constant number := 3.1415926535897932384626433832795028841;
end constants_pkg;
/

show error
