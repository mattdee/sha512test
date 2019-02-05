create database test;
use test;

create table sha512test (hash longtext, indate timestamp, shard key(hash), key (hash,indate) using clustered columnstore );

delimiter //
create or replace procedure fastHash(count longtext) as
declare
    arr ARRAY(RECORD(x longtext, y longtext)) = CREATE_ARRAY(count);
    qry QUERY(x longtext, y longtext) = select sha2(rand(), 512), now();
    newSha ARRAY(RECORD(x longtext, y longtext));
    x INT;

begin
for i in 0..(count-1) loop
    newSha = COLLECT(qry);
    arr[i] = newSha[0];
end loop;

x = INSERT_ALL("sha512test", arr);

end //
delimiter ; 


DELIMITER //
create or replace procedure hashMe() as
	declare
	qry QUERY(a longtext) = select sha2(rand(), 512);
	newSha longtext;

	begin

	newSha = scalar(qry);

	start transaction;
	insert into test.sha512test(hash)
		values
		(newSha);
	commit;

	end;
//
DELIMITER ;

call hashMe();


delimiter //
create or replace procedure makeData(howMuch int) as 

	begin
		for i in 0..howMuch loop
		call hashMe();
		end loop;
	end;
//
delimiter ;

call makeData(1000);


SET sql_mode = 'PIPES_AS_CONCAT';
DELIMITER //
create or replace procedure getHash(hash longtext)
	as 
	declare
	sqlstr longtext;
	begin
	sqlstr = '
	  	echo select 
  		* from sha512test where hash = ' 
  		||hash;
  	 execute immediate sqlstr;
  	 end;
 //
 DELIMITER ;

SET sql_mode = 'PIPES_AS_CONCAT';
delimiter //
create or replace procedure countIt(dbname text, tblname text) as
  declare
  sqlstr text;
  begin
  sqlstr = '
  echo select 
  format(count(*),0) as Count from '
  ||dbname
  ||'.'
  ||tblname;
  execute immediate sqlstr;
  end;
// 
delimiter ;

