create table author_weakenings ( id int unsigned auto_increment primary key, eId varchar(11), firstname varchar(255), lastname varchar(255), weakened_first varchar(255), weakened_last varchar(255) );
alter table author_weakenings add index( firstname(128), lastname(128) );
alter table author_weakenings add index( weakened_first(128), weakened_last(128) );
create table author_weakenings_1 ( id int unsigned auto_increment primary key, eId text, firstname varchar(128), lastname varchar(128), weakened_first varchar(128), weakened_last varchar(128) ) character set utf8;
alter table author_weakenings_1 add index( firstname(128), lastname(128) );
alter table author_weakenings_1 add index( weakened_first(128), weakened_last(128) );

