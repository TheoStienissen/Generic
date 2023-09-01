https://livesql.oracle.com/apex/livesql/file/content_I3L97U5MRE0XZSTDP4SYVPR8F.html

create or replace type rectangle as object 
(length number, 
 width number, 
 member procedure display, 
 order member function measure(r rectangle) return number 
); 
/

create or replace type body rectangle as 
   member procedure display is 
   begin 
      dbms_output.put_line ('Length: '|| length); 
      dbms_output.put_line ('Width: '|| width); 
   end display;  
   order member function measure (r rectangle) return number is 
   begin 
      if    (sqrt (self.length * self.length + self.width * self.width) > sqrt (r.length*r.length + r.width*r.width)) then return  1; 
      elsif (sqrt (self.length * self.length + self.width * self.width) = sqrt (r.length*r.length + r.width*r.width)) then return  0; 
      else return -1; 
      end if; 
   end measure; 
end; 
/

declare 
   r1 rectangle; 
   r2 rectangle; 
begin 
   r1 := rectangle (23, 44); 
   r2 := rectangle (15, 17); 
   r1.display; 
   r2.display; 
   if (r1 > r2) then -- calling measure function 
      r1.display; 
   else 
      r2.display; 
   end if; 
end; 
/
