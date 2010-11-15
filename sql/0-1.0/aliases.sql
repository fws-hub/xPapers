create table aliases ( id int unsigned auto_increment primary key, uId int(11), firstname varchar(128), lastname varchar(128) ) charset=utf8;
alter table aliases add index(uId,firstname,lastname);
alter table aliases add name varchar(255);
update aliases set name = concat( ifnull( lastname, '' ), ', ', ifnull( firstname, '' ) );
alter table aliases add index(name);

