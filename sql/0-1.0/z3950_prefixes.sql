create table z3950_prefixes( id int unsigned auto_increment primary key, prefix varchar(16), lastSuccess datetime,created timestamp );
alter table z3950_prefixes add unique index( prefix );

