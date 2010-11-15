create table notes( id int unsigned auto_increment primary key, uId int, eId varchar(10), body text, created timestamp );
ALTER TABLE notes ADD FULLTEXT(body);
alter table notes change column created created datetime;
alter table notes add column modified timestamp;
