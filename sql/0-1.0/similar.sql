create table relations ( type varchar(20), eId1 varchar(11), eId2 varchar(11) ) character set utf8;
alter table relations add index(type,eId1);
