create table author_aliases( id int unsigned auto_increment primary key, name varchar(128), alias varchar(128), to_display tinyint(1), is_dead tinyint(1), is_strengthening tinyint(1) ) character set utf8;
alter table author_aliases add index( name );
alter table author_aliases add index( alias );

