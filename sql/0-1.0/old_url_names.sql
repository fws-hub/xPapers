create table old_url_names( id integer auto_increment primary key, cId integer, uName varchar(200) );
alter table old_url_names add index(uName);

